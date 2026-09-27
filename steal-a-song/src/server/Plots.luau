--!strict
-- De studio's: toewijzen aan spelers, songs op pedestals zetten, inkomen en
-- streams laten oplopen, geld ophalen via de pads, verkopen en op slot doen.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)
local SongModel = require(script.Parent.SongModel)

export type Slot = {
	index: number,
	info: MapBuilder.SlotInfo,
	song: Economy.Song?,
	model: Model?,
	pending: number,
	thief: Player?,
	lastCollect: number,
}

export type Plot = {
	index: number,
	info: MapBuilder.PlotInfo,
	owner: Player?,
	slots: { Slot },
	unlocked: number,
	lockedUntil: number,
}

local Plots = {}

-- Worden ingevuld door Stealing, zo hoeven de modules elkaar niet in een
-- kringetje te requiren.
Plots.onSteal = nil :: ((Player, Plot, number, Economy.Song) -> ())?
Plots.onEjected = nil :: ((Plot, Player) -> ())?

local plots: { Plot } = {}
local byPlayer: { [Player]: Plot } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}

local hiddenFolder = Instance.new("Folder")
hiddenFolder.Name = "SongsBeingStolen"
hiddenFolder.Parent = ServerStorage

local GREEN = Color3.fromRGB(110, 255, 130)
local RED = Color3.fromRGB(255, 80, 90)
local DIM_PAD = Color3.fromRGB(40, 90, 50)
local BRIGHT_PAD = Color3.fromRGB(70, 255, 110)
local LOCKED_PLATE = Color3.fromRGB(70, 66, 80)

local function songName(song: Economy.Song): string
	return Songs.byId[song.id].name
end

local function ownerGroup(plot: Plot): string
	return "Owner" .. plot.index
end

local function barrierGroup(plot: Plot): string
	return "Barrier" .. plot.index
end

local function registerGroup(name: string)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

local function setCharacterGroup(character: Model, group: string)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end
end

local function updatePad(slot: Slot)
	local label = slot.info.padLabel
	local pad = slot.info.pad
	local text, color, padColor
	if slot.thief then
		text, color, padColor = "⚠ STOLEN!", RED, Color3.fromRGB(150, 30, 40)
	elseif slot.pending >= 1 then
		text, color, padColor = Format.cash(slot.pending), GREEN, BRIGHT_PAD
	else
		text, color, padColor = "", GREEN, DIM_PAD
	end
	if label.Text ~= text then
		label.Text = text
	end
	label.TextColor3 = color
	pad.Color = padColor
end

local function refreshVisuals(plot: Plot)
	local owned = plot.owner ~= nil
	for i, slot in plot.slots do
		local open = owned and i <= plot.unlocked
		slot.info.plate.Color = if open then plot.info.color else LOCKED_PLATE
		slot.info.plate.Transparency = if open then 0 else 0.5
		slot.info.pad.Transparency = if open then 0 else 0.8
		slot.info.lockLabel.Text = if owned and not open then "🔒 Rebirth" else ""
		updatePad(slot)
	end
end

local function setBarrier(plot: Plot, locked: boolean)
	local barrier = plot.info.barrier
	barrier.CanCollide = locked
	barrier.Transparency = if locked then 0.35 else 1
end

local function updateLockLabel(plot: Plot)
	local label = plot.info.lockLabel
	local remaining = plot.lockedUntil - os.clock()
	if not plot.owner then
		label.Text = ""
	elseif remaining > 0 then
		label.Text = "🔒 LOCKED " .. math.ceil(remaining) .. "s"
		label.TextColor3 = RED
	else
		label.Text = "🔓 OPEN - PRESS TO LOCK"
		label.TextColor3 = GREEN
	end
end

function Plots.get(player: Player): Plot?
	return byPlayer[player]
end

function Plots.all(): { Plot }
	return plots
end

function Plots.isLocked(plot: Plot): boolean
	return plot.lockedUntil > os.clock()
end

function Plots.isInside(plot: Plot, position: Vector3): boolean
	return MapBuilder.isInside(plot.info, position)
end

function Plots.freeSlot(plot: Plot): number?
	for i = 1, plot.unlocked do
		local slot = plot.slots[i]
		if not slot.song and not slot.thief then
			return i
		end
	end
	return nil
end

function Plots.collect(plot: Plot, slot: Slot)
	local owner = plot.owner
	if not owner or slot.pending < 1 then
		return
	end
	local t = os.clock()
	if t - slot.lastCollect < 0.2 then
		return
	end
	slot.lastCollect = t
	local amount = math.floor(slot.pending)
	slot.pending -= amount
	PlayerData.addCash(owner, amount, true)
	Remotes.fire("Collected", owner, { amount = amount, position = slot.info.pad.Position })
	updatePad(slot)
end

local function buildPlacedModel(plot: Plot, slot: Slot, song: Economy.Song, flyFrom: Vector3?): Model
	local owner = plot.owner :: Player
	local model = SongModel.build(song, {})
	model:PivotTo(slot.info.songCFrame)
	model:SetAttribute("OwnerId", owner.UserId)
	if flyFrom then
		model:SetAttribute("FlyFrom", flyFrom)
		model:SetAttribute("FlyAt", Workspace:GetServerTimeNow())
	end
	model:AddTag("SpinSong")

	local attachment = (model.PrimaryPart :: BasePart):FindFirstChild("PromptAttachment")
	local name = songName(song)

	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Steal"
	steal.ObjectText = name
	steal.HoldDuration = Config.StealHoldSeconds
	steal.MaxActivationDistance = 10
	steal.RequiresLineOfSight = false
	steal:SetAttribute("Role", "Other")
	steal:SetAttribute("OwnerId", owner.UserId)
	steal:AddTag("RolePrompt")
	steal.Triggered:Connect(function(thief)
		if Plots.onSteal and slot.song == song then
			Plots.onSteal(thief, plot, slot.index, song)
		end
	end)
	steal.Parent = attachment

	local sell = Instance.new("ProximityPrompt")
	sell.Name = "SellPrompt"
	sell.ActionText = "Sell " .. Format.cash(Economy.sellPrice(song))
	sell.ObjectText = name
	sell.HoldDuration = Config.SellHoldSeconds
	sell.MaxActivationDistance = 8
	sell.KeyboardKeyCode = Enum.KeyCode.F
	sell.GamepadKeyCode = Enum.KeyCode.ButtonY
	sell.RequiresLineOfSight = false
	sell:SetAttribute("Role", "Owner")
	sell:SetAttribute("OwnerId", owner.UserId)
	sell:AddTag("RolePrompt")
	sell.Triggered:Connect(function(player)
		Plots.sell(player, plot, slot.index, song)
	end)
	sell.Parent = attachment

	local mult = PlayerData.multiplier(owner)
	SongModel.updateLabels(model, song, mult)
	model.Parent = plot.info.model
	return model
end

-- Zet een song in een studio. Zonder slotIndex kiest hij de eerste vrije plek.
-- flyFrom laat de song vanaf die plek naar binnen vliegen.
function Plots.place(player: Player, song: Economy.Song, flyFrom: Vector3?, slotIndex: number?): boolean
	local plot = byPlayer[player]
	local data = PlayerData.get(player)
	if not plot or not data then
		return false
	end
	local index = slotIndex or Plots.freeSlot(plot)
	if not index then
		return false
	end
	local slot = plot.slots[index]
	if slot.song or slot.thief then
		return false
	end
	song.slot = index
	slot.song = song
	if not table.find(data.songs, song) then
		table.insert(data.songs, song)
	end
	slot.model = buildPlacedModel(plot, slot, song, flyFrom)
	updatePad(slot)
	PlayerData.markDirty(player)
	return true
end

-- Haalt een song uit een studio (en uit de data van de eigenaar)
function Plots.removeSong(plot: Plot, index: number): Economy.Song?
	local slot = plot.slots[index]
	local song = slot.song
	if slot.model then
		slot.model:Destroy()
	end
	slot.model = nil
	slot.song = nil
	slot.thief = nil
	if song and plot.owner then
		local data = PlayerData.get(plot.owner)
		if data then
			local at = table.find(data.songs, song)
			if at then
				table.remove(data.songs, at)
			end
		end
		song.slot = nil
		PlayerData.markDirty(plot.owner)
	end
	updatePad(slot)
	return song
end

-- Verbergt de song op de pedestal zolang een dief hem draagt, of zet hem terug
function Plots.setStolen(plot: Plot, index: number, thief: Player?)
	local slot = plot.slots[index]
	slot.thief = thief
	if slot.model then
		slot.model.Parent = if thief then hiddenFolder else plot.info.model
	end
	updatePad(slot)
end

function Plots.sell(player: Player, plot: Plot, index: number, song: Economy.Song)
	local slot = plot.slots[index]
	if plot.owner ~= player or slot.song ~= song or slot.thief then
		return
	end
	local price = Economy.sellPrice(song)
	Plots.removeSong(plot, index)
	PlayerData.addCash(player, price, false)
	Remotes.toast(player, "Sold " .. songName(song) .. " for " .. Format.cash(price), "buy")
end

function Plots.lock(player: Player, plot: Plot)
	if plot.owner ~= player then
		return
	end
	if Plots.isLocked(plot) then
		Remotes.toast(player, "Your studio is already locked", "info")
		return
	end
	local data = PlayerData.get(player)
	local seconds = Economy.lockSeconds(if data then data.upgrades.Lock or 0 else 0)
	plot.lockedUntil = os.clock() + seconds
	setBarrier(plot, true)
	updateLockLabel(plot)
	Remotes.toast(player, "🔒 Studio locked for " .. seconds .. "s", "good")

	-- Wie nog binnen staat wordt eruit gezet, en een dief laat zijn buit vallen
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local character = other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if character and root and root:IsA("BasePart") and Plots.isInside(plot, root.Position) then
				if Plots.onEjected then
					Plots.onEjected(plot, other)
				end
				character:PivotTo(plot.info.outside)
				Remotes.toast(other, "The laser lock kicked you out!", "bad")
			end
		end
	end
end

function Plots.assign(player: Player): Plot?
	if byPlayer[player] then
		return byPlayer[player]
	end
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			byPlayer[player] = plot
			plot.unlocked = Economy.slotCount(data.rebirths)
			plot.lockedUntil = 0
			setBarrier(plot, false)
			plot.info.signLabel.Text = string.upper(player.DisplayName) .. "'S STUDIO"
			plot.info.lockPrompt:SetAttribute("OwnerId", player.UserId)
			player:SetAttribute("PlotIndex", plot.index)

			-- Opgeslagen songs terugzetten op hun eigen plek
			local saved = data.songs
			data.songs = {}
			table.sort(saved, function(a, b)
				return (a.slot or 99) < (b.slot or 99)
			end)
			local overflow = 0
			for _, song in saved do
				local index = song.slot
				if
					type(index) ~= "number"
					or index < 1
					or index % 1 ~= 0
					or index > plot.unlocked
					or plot.slots[index].song
				then
					index = Plots.freeSlot(plot)
				end
				if not index or not Plots.place(player, song, nil, index) then
					overflow += Economy.sellPrice(song)
				end
			end
			if overflow > 0 then
				PlayerData.addCash(player, overflow, false)
			end

			refreshVisuals(plot)
			updateLockLabel(plot)
			return plot
		end
	end
	return nil
end

function Plots.release(player: Player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	local total = 0
	for _, slot in plot.slots do
		total += slot.pending
		slot.pending = 0
		if slot.model then
			slot.model:Destroy()
		end
		slot.model = nil
		slot.song = nil
		slot.thief = nil
	end
	if total >= 1 then
		PlayerData.addCash(player, math.floor(total), true)
	end
	plot.owner = nil
	plot.lockedUntil = 0
	byPlayer[player] = nil
	setBarrier(plot, false)
	plot.info.signLabel.Text = "EMPTY STUDIO"
	plot.info.lockPrompt:SetAttribute("OwnerId", 0)
	refreshVisuals(plot)
	updateLockLabel(plot)
	local connection = characterConnections[player]
	if connection then
		connection:Disconnect()
		characterConnections[player] = nil
	end
end

-- Na een rebirth: meer plekken, en alle songs weg behalve keep
function Plots.resetForRebirth(player: Player, keep: Economy.Song?)
	local plot = byPlayer[player]
	local data = PlayerData.get(player)
	if not plot or not data then
		return
	end
	for index, slot in plot.slots do
		slot.pending = 0
		if slot.song and slot.song ~= keep then
			Plots.removeSong(plot, index)
		end
	end
	plot.unlocked = Economy.slotCount(data.rebirths)
	refreshVisuals(plot)
end

function Plots.refreshSlots(player: Player)
	local plot = byPlayer[player]
	local data = PlayerData.get(player)
	if plot and data then
		plot.unlocked = Economy.slotCount(data.rebirths)
		refreshVisuals(plot)
	end
end

function Plots.onCharacter(player: Player, character: Model)
	local plot = byPlayer[player]
	local group = if plot then ownerGroup(plot) else "Default"
	setCharacterGroup(character, group)
	local old = characterConnections[player]
	if old then
		old:Disconnect()
	end
	characterConnections[player] = character.DescendantAdded:Connect(function(descendant)
		local current = byPlayer[player]
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = if current then ownerGroup(current) else "Default"
		end
	end)

	if plot then
		local started = os.clock()
		while not character:IsDescendantOf(Workspace) and os.clock() - started < 5 do
			task.wait()
		end
		task.wait(0.1)
		if character.Parent and byPlayer[player] == plot then
			character:PivotTo(plot.info.spawn)
		end
	end
end

-- Eén tik van de economie: streams groeien, inkomen loopt op de pads op
function Plots.tick(dt: number)
	for _, plot in plots do
		local owner = plot.owner
		local data = owner and PlayerData.get(owner)
		if owner and data then
			local mult = PlayerData.multiplier(owner)
			local hype = data.upgrades.Hype or 0
			local total = 0
			for _, slot in plot.slots do
				local song = slot.song
				if song and not slot.thief then
					local justPeaked = Economy.grow(song, dt, hype)
					local income = Economy.income(song.streams) * mult
					slot.pending += income * dt
					total += income
					local model = slot.model
					if model then
						SongModel.updateLabels(model, song, mult, Economy.atPeak(song, hype))
						local root = model.PrimaryPart
						local attachment = root and root:FindFirstChild("PromptAttachment")
						local sell = attachment and attachment:FindFirstChild("SellPrompt")
						if sell and sell:IsA("ProximityPrompt") then
							local text = "Sell " .. Format.cash(Economy.sellPrice(song))
							if sell.ActionText ~= text then
								sell.ActionText = text
							end
						end
					end
					if justPeaked then
						Remotes.toast(owner, "🔥 " .. songName(song) .. " peaked at " .. Format.streams(song.streams) .. "!", "rare")
					end
				end
				updatePad(slot)
			end
			PlayerData.setIncome(owner, total)
		end
		if plot.lockedUntil > 0 and not Plots.isLocked(plot) then
			plot.lockedUntil = 0
			setBarrier(plot, false)
			if owner then
				Remotes.toast(owner, "🔓 Your studio is open again!", "bad")
			end
		end
		updateLockLabel(plot)
	end
end

function Plots.init(map: MapBuilder.MapInfo)
	for i, info in map.plots do
		local plot: Plot = {
			index = i,
			info = info,
			owner = nil,
			slots = {},
			unlocked = 0,
			lockedUntil = 0,
		}
		for index, slotInfo in info.slots do
			local slot: Slot = {
				index = index,
				info = slotInfo,
				song = nil,
				model = nil,
				pending = 0,
				thief = nil,
				lastCollect = 0,
			}
			plot.slots[index] = slot
			slotInfo.pad.Touched:Connect(function(hit)
				local owner = plot.owner
				local character = owner and owner.Character
				if character and hit:IsDescendantOf(character) then
					Plots.collect(plot, slot)
				end
			end)
		end

		registerGroup(ownerGroup(plot))
		registerGroup(barrierGroup(plot))
		PhysicsService:CollisionGroupSetCollidable(ownerGroup(plot), barrierGroup(plot), false)
		info.barrier.CollisionGroup = barrierGroup(plot)

		info.lockPrompt.Triggered:Connect(function(player)
			Plots.lock(player, plot)
		end)

		plots[i] = plot
		refreshVisuals(plot)
		updateLockLabel(plot)
	end

	PlayerData.addStateProvider(function(player, state)
		local plot = byPlayer[player]
		state.plotIndex = if plot then plot.index else nil
		local uncollected = 0
		local free = 0
		if plot then
			for i, slot in plot.slots do
				uncollected += slot.pending
				if i <= plot.unlocked and not slot.song and not slot.thief then
					free += 1
				end
			end
		end
		state.uncollected = uncollected
		state.freeSlots = free
	end)
end

return Plots
