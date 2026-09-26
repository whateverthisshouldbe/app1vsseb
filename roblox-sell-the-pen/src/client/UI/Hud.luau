-- Always-on HUD: cash, income, multipliers, side buttons, the speech
-- countdown and zone title cards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)
local Store = require(script.Parent.Parent.Store)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local Hud = {}

local cashLabel, incomeLabel, multLabel, soldLabel, speechLabel, humButton
local displayedCash = 0
local root

local function sideButton(text, subtitle, color, order, onClick)
	local button = Theme.button({
		LayoutOrder = order,
		Size = UDim2.fromOffset(84, 62),
		BackgroundColor3 = Colors.panel,
		Text = "",
	}, onClick)
	Theme.corner(14).Parent = button
	Theme.stroke(color, 2).Parent = button
	Theme.label({
		Size = UDim2.new(1, -8, 0.55, 0),
		Position = UDim2.new(0, 4, 0.1, 0),
		Font = Theme.FontBlack,
		Text = text,
		TextColor3 = color,
		Parent = button,
	})
	local sub = Theme.label({
		Name = "Sub",
		Size = UDim2.new(1, -8, 0.25, 0),
		Position = UDim2.new(0, 4, 0.65, 0),
		Font = Theme.Font,
		Text = subtitle,
		TextColor3 = Colors.muted,
		Parent = button,
	})
	return button, sub
end

function Hud.floatText(text, color)
	if not root then
		return
	end
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-60, 60), 0, 118),
		Size = UDim2.fromOffset(300, 40),
		Font = Theme.FontBlack,
		Text = text,
		TextColor3 = color or Colors.money,
		TextStrokeTransparency = 0.3,
		Parent = root,
	})
	Theme.tween(label, 1.4, { Position = label.Position - UDim2.fromOffset(0, 70), TextTransparency = 1, TextStrokeTransparency = 1 })
	task.delay(1.5, function()
		label:Destroy()
	end)
end

function Hud.zoneCard(zone)
	if not root then
		return
	end
	local card = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.2, 0),
		Size = UDim2.fromOffset(560, 110),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local title = Theme.label({
		Size = UDim2.new(1, 0, 0.6, 0),
		Font = Theme.FontBlack,
		Text = string.upper(zone.name),
		TextColor3 = Colors.gold,
		TextStrokeTransparency = 0.2,
		TextTransparency = 1,
		Parent = card,
	})
	local subtitle = Theme.label({
		Position = UDim2.new(0, 0, 0.62, 0),
		Size = UDim2.new(1, 0, 0.3, 0),
		Font = Theme.FontBold,
		Text = zone.subtitle,
		TextColor3 = Colors.text,
		TextStrokeTransparency = 0.4,
		TextTransparency = 1,
		Parent = card,
	})
	Theme.tween(title, 0.5, { TextTransparency = 0 })
	Theme.tween(subtitle, 0.8, { TextTransparency = 0 })
	task.delay(2.8, function()
		Theme.tween(title, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 })
		Theme.tween(subtitle, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 })
		task.wait(0.7)
		card:Destroy()
	end)
end

function Hud.mount(screen, actions)
	root = screen

	-- Cash panel ----------------------------------------------------------
	local panel = Theme.create("Frame", {
		Name = "CashPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(360, 86),
		BackgroundColor3 = Colors.panel,
		BackgroundTransparency = 0.05,
		Parent = screen,
	}, {
		Theme.corner(16),
		Theme.stroke(Colors.money, 2),
		Theme.gradient(Color3.fromRGB(26, 40, 32), Color3.fromRGB(12, 18, 15)),
	})
	cashLabel = Theme.label({
		Position = UDim2.new(0, 12, 0, 6),
		Size = UDim2.new(1, -24, 0, 46),
		Font = Theme.FontBlack,
		Text = "$0",
		TextColor3 = Colors.money,
		Parent = panel,
	})
	incomeLabel = Theme.label({
		Position = UDim2.new(0, 12, 0, 54),
		Size = UDim2.new(0.5, -12, 0, 22),
		Font = Theme.FontBold,
		Text = "+$0/s",
		TextColor3 = Colors.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	multLabel = Theme.label({
		Position = UDim2.new(0.5, 0, 0, 54),
		Size = UDim2.new(0.5, -12, 0, 22),
		Font = Theme.FontBold,
		Text = "x1.0",
		TextColor3 = Colors.gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})

	soldLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100),
		Size = UDim2.fromOffset(360, 20),
		Font = Theme.Font,
		Text = "",
		TextColor3 = Colors.muted,
		TextStrokeTransparency = 0.6,
		Parent = screen,
	})

	-- Side buttons ----------------------------------------------------------
	local side = Theme.create("Frame", {
		Name = "Side",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(176, 280),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(84, 62),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	sideButton("SHOP", "[B]", Colors.money, 1, actions.openShop).Parent = side
	sideButton("FIRM", "[F] brokers", Colors.firm, 2, actions.openFirm).Parent = side
	sideButton("INDEX", "[I]", Colors.gold, 3, actions.openIndex).Parent = side
	sideButton("TP", "[T] zones", Colors.blue, 4, actions.openTeleport).Parent = side
	local hum, humSub = sideButton("HUM", "[H]", Colors.gold, 5, actions.hum)
	hum.Parent = side
	humButton = { button = hum, sub = humSub }
	sideButton("REBIRTH", "IPO", Colors.purple, 6, actions.openIPO).Parent = side
	sideButton("HOW?", "Tutorial", Colors.blue, 7, actions.openHelp).Parent = side

	-- Speech countdown --------------------------------------------------------
	local speech = Theme.create("Frame", {
		Name = "Speech",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(460, 40),
		BackgroundColor3 = Colors.panel,
		BackgroundTransparency = 0.15,
		Parent = screen,
	}, {
		Theme.corner(20),
		Theme.stroke(Colors.purple, 1.5),
	})
	speechLabel = Theme.label({
		Position = UDim2.new(0, 14, 0.15, 0),
		Size = UDim2.new(1, -28, 0.7, 0),
		Font = Theme.FontBold,
		Text = "",
		TextColor3 = Colors.text,
		Parent = speech,
	})

	-- Live updates ------------------------------------------------------------
	RunService.RenderStepped:Connect(function(dt)
		local profile = Store.profile()
		if not profile then
			return
		end
		local target = profile.cash
		displayedCash += (target - displayedCash) * math.min(1, dt * 8)
		if math.abs(target - displayedCash) < 1 then
			displayedCash = target
		end
		cashLabel.Text = "$" .. Format.commas(displayedCash)

		local now = os.time()
		if Workspace:GetAttribute("SpeechActive") then
			local left = (Workspace:GetAttribute("SpeechEndsAt") or now) - now
			speechLabel.Text = string.format("THE WOLF IS SPEAKING  ·  x%d sales on the floor  ·  %s", Config.Speech.floorMult, Format.time(left))
			speechLabel.TextColor3 = Colors.gold
		else
			local at = Workspace:GetAttribute("SpeechAt")
			if at then
				speechLabel.Text = "Wolf Speech in " .. Format.time(at - now) .. "  ·  Trading Floor"
			else
				speechLabel.Text = "Sell pens. Get rich."
			end
			speechLabel.TextColor3 = Colors.text
		end

		local readyAt = player:GetAttribute("HumReadyAt") or 0
		if readyAt > now then
			humButton.sub.Text = Format.time(readyAt - now)
			humButton.button.BackgroundColor3 = Colors.bg
		else
			humButton.sub.Text = "[H] boost"
			humButton.button.BackgroundColor3 = Colors.panel
		end
	end)

	Store.Changed:Connect(function(data, previous)
		local profile = data.profile
		incomeLabel.Text = "+" .. Format.rate(data.income) .. "/s"
		multLabel.Text = string.format("x%.1f rebirth  ·  x%.2f index", data.ipoMult, data.indexMult)
		local pen = Config.findById(Config.Pens, profile.pen)
		soldLabel.Text = string.format("%s pens sold  ·  holding: %s", Format.commas(profile.pensSold), pen and pen.name or "?")
		if not previous then
			displayedCash = profile.cash
		end
	end)
end

return Hud
