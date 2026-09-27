--!strict
-- Stelen: een dief pakt een song van een pedestal, draagt hem boven zijn hoofd
-- (langzamer lopend) en moet zijn eigen studio halen. Wordt hij geraakt, gaat
-- hij dood, duurt het te lang of gaat de studio op slot terwijl hij binnen
-- staat, dan vliegt de song terug naar de eigenaar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)
local SongModel = require(script.Parent.SongModel)

type Theft = {
	owner: Player,
	plot: Plots.Plot,
	slotIndex: number,
	song: Economy.Song,
	carried: Model,
	startedAt: number,
}

local Stealing = {}

local thefts: { [Player]: Theft } = {}

local function songName(song: Economy.Song): string
	return Songs.byId[song.id].name
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function finish(thief: Player, theft: Theft)
	thefts[thief] = nil
	thief:SetAttribute("Carrying", nil)
	if theft.carried.Parent then
		theft.carried:Destroy()
	end
	local humanoid = humanoidOf(thief)
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = PlayerData.walkSpeed(thief)
	end
	Remotes.fire("Carry", thief, { active = false })
end

function Stealing.isCarrying(player: Player): boolean
	return thefts[player] ~= nil
end

-- De song gaat terug naar de eigenaar
function Stealing.fail(thief: Player, reason: string?)
	local theft = thefts[thief]
	if not theft then
		return
	end
	finish(thief, theft)
	local plot = theft.plot
	local slot = plot.slots[theft.slotIndex]
	if plot.owner == theft.owner and slot.song == theft.song then
		Plots.setStolen(plot, theft.slotIndex, nil)
	end
	local name = songName(theft.song)
	if thief.Parent then
		Remotes.toast(thief, reason or ("You dropped " .. name .. "!"), "bad")
	end
	if theft.owner.Parent then
		Remotes.fire("StealAlert", theft.owner, { active = false, saved = true, song = name })
		Remotes.toast(theft.owner, "🛡️ " .. name .. " is back in your studio!", "good")
	end
end

local function succeed(thief: Player)
	local theft = thefts[thief]
	if not theft then
		return
	end
	finish(thief, theft)
	local song = theft.song
	local name = songName(song)
	local plot = theft.plot
	local slot = plot.slots[theft.slotIndex]
	if plot.owner ~= theft.owner or slot.song ~= song then
		return
	end

	local root = rootOf(thief)
	Plots.removeSong(plot, theft.slotIndex)
	local placed = Plots.place(thief, song, if root then root.Position else nil)
	if not placed then
		-- Studio intussen vol: de dief krijgt de verkoopwaarde
		local value = Economy.sellPrice(song)
		PlayerData.addCash(thief, value, false)
		Remotes.toast(thief, "Your studio was full, so you sold " .. name .. " for " .. Format.cash(value), "info")
	end

	local data = PlayerData.get(thief)
	if data then
		data.steals += 1
	end
	local isNew = PlayerData.discover(thief, song)
	Remotes.toast(thief, "😈 You stole " .. name .. "!" .. (if isNew then "  📖 NEW IN INDEX" else ""), "rare")
	if theft.owner.Parent then
		Remotes.fire("StealAlert", theft.owner, { active = false, saved = false, song = name, thief = thief.DisplayName })
		Remotes.toast(theft.owner, "💔 " .. thief.DisplayName .. " stole " .. name .. "! Steal it back!", "bad")
	end

	local def = Songs.byId[song.id]
	local rarity = Economy.rarity(def.rarity)
	if rarity.announce then
		Remotes.announce(
			"🚨 " .. thief.DisplayName .. " stole " .. string.upper(def.rarity) .. " " .. name .. " from " .. theft.owner.DisplayName .. "!",
			rarity.color,
			false
		)
	end
end

local function begin(thief: Player, plot: Plots.Plot, slotIndex: number, song: Economy.Song)
	local owner = plot.owner
	local slot = plot.slots[slotIndex]
	if not owner or owner == thief or slot.song ~= song or slot.thief then
		return
	end
	if thefts[thief] then
		Remotes.toast(thief, "You're already carrying a song!", "bad")
		return
	end
	if Plots.isLocked(plot) then
		Remotes.toast(thief, "🔒 This studio is locked!", "bad")
		return
	end
	local thiefPlot = Plots.get(thief)
	if not thiefPlot then
		Remotes.toast(thief, "You need a studio to steal!", "bad")
		return
	end
	if not Plots.freeSlot(thiefPlot) then
		Remotes.toast(thief, "Your studio is full! Make room before stealing.", "bad")
		return
	end
	local humanoid = humanoidOf(thief)
	local root = rootOf(thief)
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	Plots.setStolen(plot, slotIndex, thief)

	local carried = SongModel.build(song, { scale = 0.55, carried = true })
	local carriedRoot = carried.PrimaryPart :: BasePart
	carried.Name = "CarriedSong"
	carried:PivotTo(root.CFrame * CFrame.new(0, 4.2, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = carriedRoot
	weld.Parent = carriedRoot
	carried.Parent = thief.Character

	humanoid.WalkSpeed = PlayerData.walkSpeed(thief) * Config.CarrySpeedMultiplier
	thief:SetAttribute("Carrying", true)

	thefts[thief] = {
		owner = owner,
		plot = plot,
		slotIndex = slotIndex,
		song = song,
		carried = carried,
		startedAt = os.clock(),
	}

	local name = songName(song)
	Remotes.fire("Carry", thief, { active = true, song = name, plotIndex = thiefPlot.index })
	Remotes.toast(thief, "Run! Bring " .. name .. " to your studio!", "rare")
	Remotes.fire("StealAlert", owner, { active = true, song = name, thief = thief.DisplayName })
end

-- Door een gitaar geraakt
function Stealing.onHit(victim: Player, attacker: Player)
	local theft = thefts[victim]
	if theft then
		Stealing.fail(victim, "💥 " .. attacker.DisplayName .. " made you drop " .. songName(theft.song) .. "!")
		if attacker ~= theft.owner then
			Remotes.toast(attacker, "You made " .. victim.DisplayName .. " drop their loot!", "good")
		else
			Remotes.toast(attacker, "💥 Got it back!", "good")
		end
	end
end

function Stealing.onPlayerRemoving(player: Player)
	if thefts[player] then
		Stealing.fail(player)
	end
	for thief, theft in thefts do
		if theft.owner == player then
			Stealing.fail(thief, "The owner left, the song vanished!")
		end
	end
end

-- Laat een dief vallen als de studio waar hij in staat op slot gaat
local function onEjected(plot: Plots.Plot, player: Player)
	local theft = thefts[player]
	if theft and theft.plot == plot then
		Stealing.fail(player, "🔒 The laser lock made you drop it!")
	end
end

function Stealing.hasActiveTheftOf(owner: Player): boolean
	for _, theft in thefts do
		if theft.owner == owner then
			return true
		end
	end
	return false
end

function Stealing.init()
	Plots.onSteal = begin
	Plots.onEjected = onEjected

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		for thief, theft in thefts do
			local humanoid = humanoidOf(thief)
			local root = rootOf(thief)
			local home = Plots.get(thief)
			if not thief.Parent or not humanoid or humanoid.Health <= 0 or not root or not theft.carried.Parent then
				Stealing.fail(thief)
			elseif os.clock() - theft.startedAt > Config.StealTimeout then
				Stealing.fail(thief, "Too slow! The song went back home.")
			elseif home and Plots.isInside(home, root.Position) then
				succeed(thief)
			end
		end
	end)
end

return Stealing
