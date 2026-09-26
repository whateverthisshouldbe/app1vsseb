-- Server entry point.

local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local PitchService = require(script.Parent.PitchService)
local WorldService = require(script.Parent.WorldService)
local AnimationService = require(script.Parent.AnimationService)

DataService.start()
EconomyService.start()
PitchService.start()
WorldService.start()
AnimationService.start()

local function onPlayerAdded(player)
	local profile = DataService.load(player)
	if profile then
		EconomyService.onPlayerLoaded(player, profile)
		AnimationService.refresh(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	DataService.release(player)
end)
