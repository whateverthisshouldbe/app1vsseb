--!strict
-- De rode loper: songs verschijnen bij NEW DROPS, zweven langzaam naar het
-- andere eind en verdwijnen daar. Wie er als eerste op drukt en genoeg geld
-- heeft, krijgt hem.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local Events = require(script.Parent.Events)
local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)
local SongModel = require(script.Parent.SongModel)

type Entry = {
	song: Economy.Song,
	model: Model,
	root: BasePart,
	bought: boolean,
	spawnedAt: number,
}

local Conveyor = {}

local map: MapBuilder.MapInfo
local active: { [Model]: Entry } = {}
local maxLifetime = 0

local function rarityText(rarityName: string): string
	return string.upper(rarityName)
end

function Conveyor.buy(player: Player, entry: Entry)
	if entry.bought or not entry.model.Parent then
		return
	end
	local plot = Plots.get(player)
	if not plot then
		Remotes.toast(player, "You don't have a studio yet", "bad")
		return
	end
	if not Plots.freeSlot(plot) then
		Remotes.toast(player, "Your studio is full! Sell a song (hold F) or rebirth.", "bad")
		return
	end
	local song = entry.song
	local price = Economy.price(song)
	if not PlayerData.spend(player, price) then
		local data = PlayerData.get(player)
		local short = price - (if data then data.cash else 0)
		Remotes.toast(player, "Not enough cash! You need " .. Format.cash(short) .. " more", "bad")
		return
	end

	entry.bought = true
	local from = entry.root.Position
	active[entry.model] = nil
	entry.model:Destroy()
	Plots.place(player, song, from)

	local def = Songs.byId[song.id]
	local rarity = Economy.rarity(def.rarity)
	local isNew = PlayerData.discover(player, song)
	Remotes.toast(player, "You bought " .. def.name .. "!" .. (if isNew then "  📖 NEW IN INDEX" else ""), "buy")
	if rarity.announce then
		local mutation = if song.mut then string.upper(song.mut) .. " " else ""
		Remotes.announce(
			player.DisplayName .. " bought " .. mutation .. rarityText(def.rarity) .. " " .. def.name .. "!",
			rarity.color,
			false
		)
	end
end

function Conveyor.spawn(song: Economy.Song?, startX: number?, quiet: boolean?)
	local newSong = song or Economy.rollSong(Events.luck(), Events.mutationMult())
	local def = Songs.byId[newSong.id]
	local rarity = Economy.rarity(def.rarity)

	local model = SongModel.build(newSong, { physics = true, price = true })
	local root = model.PrimaryPart :: BasePart
	model:PivotTo(CFrame.new(startX or map.songStart.X, map.songStart.Y, map.songStart.Z))

	local mover = Instance.new("Attachment")
	mover.Name = "Mover"
	mover.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = mover
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.VectorVelocity = Vector3.new(Config.ConveyorSpeed, 0, 0)
	velocity.MaxForce = math.huge
	velocity.Parent = root

	local spin = Instance.new("AngularVelocity")
	spin.Attachment0 = mover
	spin.RelativeTo = Enum.ActuatorRelativeTo.World
	spin.AngularVelocity = Vector3.new(0, 1.2, 0)
	spin.MaxTorque = math.huge
	spin.Parent = root

	local entry: Entry = {
		song = newSong,
		model = model,
		root = root,
		bought = false,
		spawnedAt = os.clock(),
	}

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. Format.cash(Economy.price(newSong))
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		Conveyor.buy(player, entry)
	end)
	prompt.Parent = root:FindFirstChild("PromptAttachment")

	model.Parent = map.conveyorFolder
	root:SetNetworkOwner(nil)
	active[model] = entry

	if rarity.announce and not quiet then
		local mutation = if newSong.mut then string.upper(newSong.mut) .. " " else ""
		Remotes.announce(
			"⚡ " .. mutation .. rarityText(def.rarity) .. " DROP: " .. def.name .. " (" .. Format.streams(newSong.streams) .. ")",
			rarity.color,
			Economy.rarityIndex(def.rarity) >= Economy.rarityIndex("Mythic")
		)
	end
end

-- Songs die aan het eind zijn (of vastlopen) opruimen
local function cleanup()
	local now = os.clock()
	for model, entry in active do
		local root = entry.root
		if not model.Parent or not root.Parent then
			active[model] = nil
		elseif root.Position.X >= map.songEnd.X or now - entry.spawnedAt > maxLifetime or root.Position.Y < -20 then
			active[model] = nil
			model:Destroy()
		end
	end
end

function Conveyor.init(mapInfo: MapBuilder.MapInfo)
	map = mapInfo
	local length = map.songEnd.X - map.songStart.X
	maxLifetime = length / Config.ConveyorSpeed * 1.5 + 10

	-- Meteen een volle loper, zodat de eerste speler niet hoeft te wachten
	local spacing = Config.SpawnInterval * Config.ConveyorSpeed
	local x = map.songEnd.X - spacing
	while x > map.songStart.X do
		Conveyor.spawn(nil, x, true)
		x -= spacing
	end

	task.spawn(function()
		while true do
			task.wait(Config.SpawnInterval / Events.spawnMult())
			xpcall(Conveyor.spawn, function(err)
				warn("[StealASong] spawn failed: " .. tostring(err))
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			cleanup()
		end
	end)
end

return Conveyor
