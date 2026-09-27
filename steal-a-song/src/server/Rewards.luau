--!strict
-- Beloningen om terug te komen en te blijven: cadeaus voor speeltijd, een
-- dagelijkse streak van 7 dagen en geld dat je songs offline verdienden.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)

local Rewards = {}

local claimedGifts: { [Player]: { [number]: boolean } } = {}

local function today(): number
	return os.time() // 86400
end

local function elapsedMinutes(player: Player): number
	local session = PlayerData.session(player)
	return if session then (os.clock() - session.joinedAt) / 60 else 0
end

-- Geeft een beloning (cash of een song) en een tekst voor de melding
local function grant(player: Player, reward: any): string
	if reward.kind == "song" then
		local def = Economy.rollDef(reward.rarity)
		local song = Economy.makeSong(def, nil)
		local plot = Plots.get(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local from = if root and root:IsA("BasePart") then root.Position else nil
		if plot and Plots.place(player, song, from) then
			PlayerData.discover(player, song)
			return string.upper(def.rarity) .. " " .. def.name .. " (" .. Format.streams(song.streams) .. ")"
		end
		local value = Economy.price(song)
		PlayerData.addCash(player, value, false)
		return Format.cash(value) .. " (studio full, " .. def.name .. " sold)"
	end
	local amount = Economy.rewardCash(PlayerData.income(player), reward)
	PlayerData.addCash(player, amount, false)
	return Format.cash(amount)
end

local function claimGift(player: Player, index: any): (boolean, string?)
	local gift = Config.Gifts[index]
	local claimed = claimedGifts[player]
	if type(index) ~= "number" or not gift or not claimed then
		return false, "Unknown gift"
	end
	if claimed[index] then
		return false, "Already claimed"
	end
	if elapsedMinutes(player) < (gift.minutes or 0) then
		return false, "Not ready yet"
	end
	claimed[index] = true
	local text = grant(player, gift)
	Remotes.toast(player, "🎁 Gift: " .. text, if gift.kind == "song" then "rare" else "good")
	PlayerData.markDirty(player)
	return true, text
end

local function dailyInfo(player: Player): (boolean, number)
	local data = PlayerData.get(player)
	if not data then
		return false, 1
	end
	local canClaim = data.dailyDay < today()
	local streak = if data.dailyDay == today() - 1 then data.dailyStreak + 1 else 1
	if not canClaim then
		streak = data.dailyStreak
	end
	return canClaim, streak
end

local function claimDaily(player: Player): (boolean, string?)
	local data = PlayerData.get(player)
	local canClaim, streak = dailyInfo(player)
	if not data or not canClaim then
		return false, "Come back tomorrow!"
	end
	data.dailyDay = today()
	data.dailyStreak = streak
	local reward = Config.Daily[(streak - 1) % #Config.Daily + 1]
	local text = grant(player, reward)
	Remotes.toast(player, "📅 Day " .. streak .. " reward: " .. text, "rare")
	PlayerData.markDirty(player)
	return true, text
end

function Rewards.onJoin(player: Player)
	claimedGifts[player] = {}

	-- Offline verdiend: een deel van het inkomen, met een maximum aan tijd
	local data = PlayerData.get(player)
	if data and data.lastSeen > 0 then
		local away = math.clamp(os.time() - data.lastSeen, 0, Config.OfflineMaxSeconds)
		local income = 0
		for _, song in data.songs do
			income += Economy.income(song.streams)
		end
		income *= Economy.rebirthMultiplier(data.rebirths)
		local amount = math.floor(income * away * Config.OfflineRate)
		if away >= 60 and amount >= 1 then
			PlayerData.addCash(player, amount, true)
			Remotes.fire("Popup", player, {
				kind = "offline",
				amount = amount,
				seconds = away,
			})
		end
	end
end

function Rewards.onLeave(player: Player)
	claimedGifts[player] = nil
end

function Rewards.init()
	Remotes.handle("ClaimGift", claimGift)
	Remotes.handle("ClaimDaily", claimDaily)

	PlayerData.addStateProvider(function(player, state)
		local claimed = claimedGifts[player] or {}
		local list = {}
		for i in Config.Gifts do
			list[i] = claimed[i] == true
		end
		state.giftsClaimed = list
		state.playMinutes = elapsedMinutes(player)
		local canClaim, streak = dailyInfo(player)
		state.daily = { canClaim = canClaim, streak = streak, nextIn = (today() + 1) * 86400 - os.time() }
	end)
end

-- Voor DevCommands
Rewards.grant = grant

return Rewards
