-- Server entry point.

local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local PitchService = require(script.Parent.PitchService)
local WorldService = require(script.Parent.WorldService)
local AnimationService = require(script.Parent.AnimationService)
local OutfitService = require(script.Parent.OutfitService)

DataService.start()
EconomyService.start()
PitchService.start()
WorldService.start()
AnimationService.start()
OutfitService.start(function(player)
	local profile = DataService.get(player)
	return profile and profile.suit or "thrift"
end)
-- Buying a suit (or rebirthing out of one) changes what you wear.
DataService.onChanged(function(player, profile)
	OutfitService.suitChanged(player, profile.suit)
end)

local function onPlayerAdded(player)
	local profile = DataService.load(player)
	if profile then
		EconomyService.onPlayerLoaded(player, profile)
		AnimationService.refresh(player)
		OutfitService.suitChanged(player, profile.suit)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	DataService.release(player)
end)
