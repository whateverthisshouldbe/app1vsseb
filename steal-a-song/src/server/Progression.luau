--!strict
-- Upgrades kopen en rebirthen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)
local Stealing = require(script.Parent.Stealing)

local Progression = {}

function Progression.applySpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local speed = PlayerData.walkSpeed(player)
		if Stealing.isCarrying(player) then
			speed *= Config.CarrySpeedMultiplier
		end
		humanoid.WalkSpeed = speed
	end
end

local function buyUpgrade(player: Player, id: any): (boolean, string?)
	local data = PlayerData.get(player)
	if type(id) ~= "string" or not data or not Economy.upgrade(id) then
		return false, "Unknown upgrade"
	end
	local level = data.upgrades[id] or 0
	local cost = Economy.upgradeCost(id, level)
	if not cost then
		return false, "Already maxed!"
	end
	if not PlayerData.spend(player, cost) then
		return false, "Not enough cash!"
	end
	data.upgrades[id] = level + 1
	if id == "Speed" then
		Progression.applySpeed(player)
	end
	local upgrade = Economy.upgrade(id)
	Remotes.toast(player, upgrade.icon .. " " .. upgrade.name .. " is now level " .. (level + 1) .. "!", "good")
	PlayerData.markDirty(player)
	return true
end

local function rebirth(player: Player): (boolean, string?)
	local data = PlayerData.get(player)
	if not data then
		return false, "Not loaded yet"
	end
	local cost = Economy.rebirthCost(data.rebirths)
	if data.cash < cost then
		return false, "You need " .. Format.cash(cost) .. " to rebirth"
	end
	if Stealing.hasActiveTheftOf(player) then
		return false, "Someone is stealing your song! Deal with the thief first."
	end
	if Stealing.isCarrying(player) then
		return false, "Bring your stolen song home first!"
	end

	-- De beste song mag blijven
	local best: Economy.Song? = nil
	for _, song in data.songs do
		if not best or song.streams > best.streams then
			best = song
		end
	end

	data.rebirths += 1
	data.cash = Config.StartingCash
	Plots.resetForRebirth(player, best)

	local keptText = if best then " You kept " .. Songs.byId[best.id].name .. "!" else ""
	Remotes.toast(
		player,
		"🔁 REBIRTH " .. data.rebirths .. "! Royalties " .. Format.multiplier(Economy.rebirthMultiplier(data.rebirths)) .. keptText,
		"rare"
	)
	Remotes.announce("🔁 " .. player.DisplayName .. " reached Rebirth " .. data.rebirths .. "!", { 120, 255, 200 }, false)
	PlayerData.markDirty(player)
	task.spawn(PlayerData.save, player)
	return true
end

function Progression.init()
	Remotes.handle("BuyUpgrade", buyUpgrade)
	Remotes.handle("Rebirth", rebirth)
end

return Progression
