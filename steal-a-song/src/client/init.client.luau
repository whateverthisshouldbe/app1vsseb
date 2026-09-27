--!strict
-- Opstarten van de client: interface bouwen en de server-berichten koppelen.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Store = require(script.Store)
local UI = require(script.UI)
local Hud = require(script.Hud)
local Windows = require(script.Windows)
local World = require(script.World)

local player = Players.LocalPlayer

local screen = UI.new("ScreenGui", {
	Name = "StealASongUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Eén schaal voor alles: het root-frame wordt 1/s groot en dan met s
-- verkleind, zodat het precies het scherm vult op elke telefoon of monitor.
local root = UI.new("Frame", {
	Name = "Root",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = screen,
})
local rootScale = UI.new("UIScale", { Parent = root })

local function rescale()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	local s = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.5, 1.2)
	rootScale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
end
rescale()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

Hud.build(root, Windows.open)
Windows.build(root, Hud.toast)
World.init()

Store.onChange(function(state)
	Hud.setState(state)
	Windows.setState(state)
end)

Store.remote("State").OnClientEvent:Connect(Store.set)
Store.remote("Toast").OnClientEvent:Connect(function(info)
	Hud.toast(info.text, info.kind)
end)
Store.remote("Announce").OnClientEvent:Connect(function(info)
	Hud.announce(info.text, info.color, info.big)
end)
Store.remote("Collected").OnClientEvent:Connect(World.collected)
Store.remote("Knockback").OnClientEvent:Connect(World.knockback)
Store.remote("StealAlert").OnClientEvent:Connect(Hud.setAlarm)
Store.remote("Carry").OnClientEvent:Connect(function(info)
	Hud.setCarry(info)
	World.setCarry(info)
end)
Store.remote("EventState").OnClientEvent:Connect(function(info)
	Store.event = info
end)
Store.remote("Popup").OnClientEvent:Connect(function(info)
	if info.kind == "offline" then
		Windows.showOffline(info.amount, info.seconds)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	Hud.update(dt)
	World.update(dt)
end)

task.spawn(function()
	while true do
		task.wait(1)
		Windows.tick()
	end
end)

-- Dagelijkse beloning één keer vanzelf laten zien
local dailyShown = false
Store.onChange(function(state)
	if dailyShown or not (state.daily and state.daily.canClaim) then
		return
	end
	dailyShown = true
	task.delay(2.5, function()
		if not Windows.isOpen() then
			Windows.open("Daily")
		end
	end)
end)

Store.call("Ready")
