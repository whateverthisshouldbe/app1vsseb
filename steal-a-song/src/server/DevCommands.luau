--!strict
-- Testcommando's in de chat, alleen in Studio of voor de maker van de game:
--   !cash 1e9            geld erbij
--   !event [ConcertNight] event starten (zonder naam: willekeurig)
--   !drop legendary gold een song op de loper zetten
--   !give mythic         een song direct in je studio

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))

local Conveyor = require(script.Parent.Conveyor)
local Events = require(script.Parent.Events)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)
local Rewards = require(script.Parent.Rewards)

local DevCommands = {}

local function normalize(text: string): string
	return (string.gsub(string.lower(text), "[%s_%-]", ""))
end

local function findRarity(word: string?): string?
	if not word then
		return nil
	end
	local wanted = normalize(word)
	if wanted == "god" then
		wanted = "chartgod"
	end
	for _, rarity in Config.Rarities do
		if normalize(rarity.name) == wanted then
			return rarity.name
		end
	end
	return nil
end

local function findMutation(word: string?): string?
	if not word then
		return nil
	end
	for _, mutation in Config.Mutations do
		if normalize(mutation.name) == normalize(word) then
			return mutation.name
		end
	end
	return nil
end

local function isAllowed(player: Player): boolean
	return RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
end

local function run(player: Player, message: string)
	local words = string.split(message, " ")
	local command = string.lower(words[1] or "")
	if command == "!cash" then
		local amount = tonumber(words[2]) or 1e6
		PlayerData.addCash(player, amount, false)
		Remotes.toast(player, "Dev: +$" .. amount, "info")
	elseif command == "!event" then
		Events.start(words[2])
	elseif command == "!drop" then
		local rarity = findRarity(words[2]) or "Legendary"
		local song = Economy.makeSong(Economy.rollDef(rarity), findMutation(words[3]))
		Conveyor.spawn(song)
	elseif command == "!give" then
		local rarity = findRarity(words[2]) or "Legendary"
		Remotes.toast(player, "Dev: " .. Rewards.grant(player, { kind = "song", rarity = rarity }), "info")
	elseif command == "!help" then
		Remotes.toast(player, "!cash 1e9 · !event [id] · !drop legendary gold · !give mythic", "info")
	end
end

function DevCommands.init()
	local function hook(player: Player)
		player.Chatted:Connect(function(message)
			if string.sub(message, 1, 1) == "!" and isAllowed(player) then
				xpcall(run, function(err)
					warn("[StealASong] dev command failed: " .. tostring(err))
				end, player, message)
			end
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
end

return DevCommands
