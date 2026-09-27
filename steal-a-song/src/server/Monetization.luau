--!strict
-- Game passes uit Config.GamePasses. Een pass met id 0 staat uit.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlayerData = require(script.Parent.PlayerData)
local Progression = require(script.Parent.Progression)
local Remotes = require(script.Parent.Remotes)

local Monetization = {}

local function passById(id: number): any
	for _, pass in Config.GamePasses do
		if pass.id == id and id ~= 0 then
			return pass
		end
	end
	return nil
end

function Monetization.onJoin(player: Player)
	for _, pass in Config.GamePasses do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				PlayerData.setPass(player, pass.key, true)
			end
		end
	end
end

function Monetization.init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passById(passId)
		if purchased and pass and player.Parent == Players then
			PlayerData.setPass(player, pass.key, true)
			Progression.applySpeed(player)
			Remotes.toast(player, pass.icon .. " Thanks! " .. pass.name .. " is active!", "rare")
		end
	end)
end

return Monetization
