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
local PitchUI = require(script.Parent.UI.PitchUI)
local World = require(script.Parent.World)

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
	openIPO = Shop.openIPO,
	openHelp = Shop.openHelp,
})
Shop.mount(screen)
PitchUI.mount(screen)
World.start()

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or Store.inPitch then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		Shop.toggleShop()
	elseif input.KeyCode == Enum.KeyCode.H then
		hum()
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

-- First time here? Show how to play.
task.spawn(function()
	repeat
		task.wait(0.5)
	until Store.profile()
	if Store.profile().pensSold == 0 then
		task.wait(2)
		Shop.openHelp()
		Notifier.show("Walk up to anyone in the parking lot and press E. Sell them a pen.", "big")
	end
end)
