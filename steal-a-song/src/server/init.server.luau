--!strict
-- Opstarten van de server: wereld bouwen, modules starten en spelers
-- door hun levenscyclus leiden (laden, studio krijgen, spawnen, opslaan).

local Players = game:GetService("Players")

local Remotes = require(script.Remotes)
Remotes.init()

local MapBuilder = require(script.MapBuilder)
local map = MapBuilder.build()

local PlayerData = require(script.PlayerData)
local Events = require(script.Events)
local Plots = require(script.Plots)
local Conveyor = require(script.Conveyor)
local Stealing = require(script.Stealing)
local Combat = require(script.Combat)
local Progression = require(script.Progression)
local Rewards = require(script.Rewards)
local Boards = require(script.Boards)
local Monetization = require(script.Monetization)
local DevCommands = require(script.DevCommands)

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

PlayerData.init()
Events.init()
Plots.init(map)
Conveyor.init(map)
Stealing.init()
Combat.init()
Progression.init()
Rewards.init()
Boards.init(map)
Monetization.init()
DevCommands.init()

Remotes.handle("Ready", function(player)
	PlayerData.markDirty(player)
	Remotes.fire("EventState", player, Events.state())
	return true
end)

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.WalkSpeed = PlayerData.walkSpeed(player)
	task.spawn(Combat.giveTool, player)
	Plots.onCharacter(player, character)
end

local function onPlayerAdded(player: Player)
	PlayerData.load(player)
	if player.Parent ~= Players then
		PlayerData.release(player)
		return
	end
	Monetization.onJoin(player)
	local plot = Plots.assign(player)
	if not plot then
		Remotes.toast(player, "No free studio in this server, sorry!", "bad")
	end
	Rewards.onJoin(player)
	task.spawn(PlayerData.refreshFriends, player)

	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end

	if not PlayerData.canSave(player) then
		Remotes.toast(player, "⚠ Saving is off (enable API access in Studio to save progress)", "info")
	end
	PlayerData.markDirty(player)
end

local function onPlayerRemoving(player: Player)
	Stealing.onPlayerRemoving(player)
	Plots.release(player)
	Rewards.onLeave(player)
	PlayerData.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- De economie tikt één keer per seconde
task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(Config.TickSeconds)
		local now = os.clock()
		local dt = math.min(now - last, 5)
		last = now
		xpcall(Plots.tick, function(err)
			warn("[StealASong] tick failed: " .. tostring(err))
		end, dt)
	end
end)
