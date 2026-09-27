-- Client entry point: builds the UI and wires up keybinds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Format = require(ReplicatedStorage.Shared.Format)
local Store = require(script.Parent.Store)
local Theme = require(script.Parent.UI.Theme)
local Notifier = require(script.Parent.UI.Notifier)
local Hud = require(script.Parent.UI.Hud)
local Shop = require(script.Parent.UI.Shop)
local Collection = require(script.Parent.UI.Collection)
local PitchUI = require(script.Parent.UI.PitchUI)
local World = require(script.Parent.World)
local Movement = require(script.Parent.Movement)
local Tutorial = require(script.Parent.Tutorial)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local screen = Theme.create("ScreenGui", {
	Name = "SellMeThisPen",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local function hum()
	Remotes.Hum:FireServer()
end

Notifier.mount(screen)
Hud.mount(screen, {
	openShop = function()
		Shop.toggleShop()
	end,
	hum = hum,
	openFirm = Collection.toggleFirm,
	openIndex = Collection.toggleIndex,
	openTeleport = Collection.toggleTeleport,
	openIPO = Shop.openIPO,
})
Shop.mount(screen)
Collection.mount(screen)
PitchUI.mount(screen)
World.start()
Movement.start(screen)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	-- The HUD owns the top-right corner (like the big simulators).
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or Store.inPitch then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		Shop.toggleShop()
	elseif input.KeyCode == Enum.KeyCode.H then
		hum()
	elseif input.KeyCode == Enum.KeyCode.F then
		Collection.toggleFirm()
	elseif input.KeyCode == Enum.KeyCode.I then
		Collection.toggleIndex()
	elseif input.KeyCode == Enum.KeyCode.T then
		Collection.toggleTeleport()
	end
end)

-- Earnings popups whenever cash jumps.
Store.Changed:Connect(function(data, previous)
	if not previous then
		return
	end
	local delta = data.profile.cash - previous.profile.cash
	-- Passive ticks are small and constant; only celebrate real sales.
	if delta > data.income * 1.5 + 1 then
		Hud.floatText("+" .. Format.cash(delta), Theme.Colors.money)
	elseif delta < -1 and data.profile.pensSold == previous.profile.pensSold then
		Hud.floatText("-" .. Format.cash(-delta), Theme.Colors.red)
	end
end)

-- New players get the playthrough tutorial.
Tutorial.start(screen)
