-- Always-on HUD, in the style of the big Roblox simulators:
--   left:          2x2 grid of chunky menu buttons
--   bottom left:   brokers, cash and rebirths
--   bottom center: income + level bar
--   top center:    a goal hint
--   top right:     square icon buttons (teleport, hum)
--   right:         active boosts (x2 money, Wolf Speech)

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
Hud.buttons = {} -- name -> button, so the tutorial can point at them

local root
local displayedCash = 0

-- Building blocks ---------------------------------------------------------------

local function bigButton(name, icon, label, gradient, onClick)
	local button = Theme.button({
		Name = name,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		AutoButtonColor = false,
	}, onClick)
	Theme.corner(18).Parent = button
	Theme.stroke(Colors.stroke, 3.5).Parent = button
	Theme.fill(button, gradient)
	-- Glossy top half.
	Theme.create("Frame", {
		Position = UDim2.fromScale(0.06, 0.05),
		Size = UDim2.fromScale(0.88, 0.38),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.78,
		Parent = button,
	}, { Theme.corner(14) })
	Theme.label({
		Name = "Icon",
		Position = UDim2.fromScale(0.1, 0.02),
		Size = UDim2.fromScale(0.8, 0.66),
		Font = Theme.Font,
		Text = icon,
		Outline = false,
		Parent = button,
	})
	Theme.label({
		Name = "Label",
		Position = UDim2.fromScale(0.02, 0.66),
		Size = UDim2.fromScale(0.96, 0.3),
		Font = Theme.FontBlack,
		Text = label,
		Outline = 2.5,
		Parent = button,
	})
	Hud.buttons[name] = button
	return button
end

local function iconButton(name, icon, onClick)
	local button = Theme.button({
		Name = name,
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
	}, onClick)
	Theme.corner(12).Parent = button
	Theme.stroke(Colors.stroke, 3).Parent = button
	Theme.fill(button, "gray")
	Theme.label({
		Name = "Icon",
		Position = UDim2.fromScale(0.12, 0.08),
		Size = UDim2.fromScale(0.76, 0.76),
		Font = Theme.Font,
		Text = icon,
		Outline = false,
		Parent = button,
	})
	local badge = Theme.label({
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 12),
		Size = UDim2.fromOffset(72, 20),
		Font = Theme.FontBlack,
		Text = "",
		Parent = button,
	})
	Hud.buttons[name] = button
	return button, badge
end

local function statPill(parent, order, icon)
	local pill = Theme.create("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(250, 56),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Parent = parent,
	}, { Theme.corner(28) })
	Theme.create("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		Parent = pill,
	})
	Theme.label({
		Position = UDim2.fromOffset(4, 2),
		Size = UDim2.fromOffset(52, 52),
		Font = Theme.Font,
		Text = icon,
		Outline = false,
		Parent = pill,
	})
	return Theme.label({
		Position = UDim2.fromOffset(62, 6),
		Size = UDim2.new(1, -66, 1, -12),
		Font = Theme.FontBlack,
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 3,
		Parent = pill,
	})
end

local function boostCard(parent, order, gradient, title)
	local card = Theme.create("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(170, 64),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		Parent = parent,
	}, { Theme.corner(14), Theme.stroke(Colors.stroke, 3) })
	Theme.fill(card, gradient)
	Theme.label({
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(1, -16, 0, 32),
		Font = Theme.FontBlack,
		Text = title,
		Outline = 2.5,
		Parent = card,
	})
	local sub = Theme.label({
		Position = UDim2.fromOffset(8, 36),
		Size = UDim2.new(1, -16, 0, 22),
		Font = Theme.FontBlack,
		Text = "",
		TextColor3 = Colors.gold,
		Outline = 2,
		Parent = card,
	})
	return card, sub
end

-- Effects --------------------------------------------------------------------

function Hud.floatText(text, color)
	if not root then
		return
	end
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-80, 80), 0.62, 0),
		Size = UDim2.fromOffset(320, 48),
		Font = Theme.FontBlack,
		Text = text,
		TextColor3 = color or Colors.money,
		Outline = 3,
		ZIndex = 5,
		Parent = root,
	})
	Theme.pop(label, 0.25)
	Theme.tween(label, 1.4, { Position = label.Position - UDim2.fromOffset(0, 90), TextTransparency = 1 })
	task.delay(1.5, function()
		label:Destroy()
	end)
end

-- Big title card in the middle of the screen (zones, the Wolf Speech).
function Hud.zoneCard(zone)
	if not root then
		return
	end
	local card = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.2, 0),
		Size = UDim2.fromOffset(640, 120),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local title = Theme.label({
		Size = UDim2.new(1, 0, 0.6, 0),
		Font = Theme.FontBlack,
		Text = string.upper(zone.name),
		TextColor3 = Colors.gold,
		TextTransparency = 1,
		Outline = 4,
		Parent = card,
	})
	local subtitle = Theme.label({
		Position = UDim2.new(0, 0, 0.62, 0),
		Size = UDim2.new(1, 0, 0.3, 0),
		Font = Theme.FontBold,
		Text = zone.subtitle,
		TextTransparency = 1,
		Outline = 2.5,
		Parent = card,
	})
	Theme.pop(card, 0.4)
	Theme.tween(title, 0.4, { TextTransparency = 0 })
	Theme.tween(subtitle, 0.7, { TextTransparency = 0 })
	task.delay(3, function()
		Theme.tween(title, 0.5, { TextTransparency = 1 })
		Theme.tween(subtitle, 0.5, { TextTransparency = 1 })
		task.wait(0.55)
		card:Destroy()
	end)
end

-- Mount ------------------------------------------------------------------------------

function Hud.mount(screen, actions)
	root = screen

	-- Menu grid (left) ------------------------------------------------------------
	local grid = Theme.create("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.42, 0),
		Size = UDim2.fromOffset(222, 222),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(106, 106),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local items = {
		{ "shop", "🛒", "Shop", "orange", actions.openShop },
		{ "firm", "💼", "Firm", "green", actions.openFirm },
		{ "index", "📖", "Index", "red", actions.openIndex },
		{ "rebirth", "🔄", "Rebirth", "purple", actions.openIPO },
	}
	for order, item in items do
		local button = bigButton(item[1], item[2], item[3], item[4], item[5])
		button.LayoutOrder = order
		button.Parent = grid
	end
	-- Rainbow ring on Rebirth when you can afford it.
	local rebirthRing = Theme.create("UIStroke", {
		Thickness = 5,
		Color = Color3.new(1, 1, 1),
		Enabled = false,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	Theme.create("Frame", {
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.fromOffset(-4, -4),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Parent = Hud.buttons.rebirth,
	}, { Theme.corner(20), rebirthRing })
	local rainbow = Theme.create("UIGradient", { Color = Theme.Rainbow, Parent = rebirthRing })
	local ready = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(70, 26),
		Rotation = 20,
		Font = Theme.FontBlack,
		Text = "READY!",
		TextColor3 = Colors.money,
		Visible = false,
		ZIndex = 3,
		Outline = 2.5,
		Parent = Hud.buttons.rebirth,
	})

	-- Stats (bottom left) ---------------------------------------------------------
	local stats = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -14),
		Size = UDim2.fromOffset(260, 184),
		BackgroundTransparency = 1,
		Parent = screen,
	}, { Theme.create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }) })
	local brokersLabel = statPill(stats, 1, "💼")
	local cashLabel = statPill(stats, 2, "💰")
	cashLabel.TextColor3 = Colors.money
	local rebirthLabel = statPill(stats, 3, "🔄")
	rebirthLabel.TextColor3 = Color3.fromRGB(220, 170, 255)

	-- Income + level bar (bottom center) -----------------------------------------------
	local bottom = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.5, 0, 0, 92),
		BackgroundTransparency = 1,
		Parent = screen,
	}, { Theme.create("UISizeConstraint", { MaxSize = Vector2.new(660, 92), MinSize = Vector2.new(320, 92) }) })
	local incomeLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.FontBlack,
		Text = "Income: +$0/s",
		TextColor3 = Colors.blue,
		Outline = 2.5,
		Parent = bottom,
	})
	local bar = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(40, 30, 20),
		Parent = bottom,
	}, { Theme.corner(10), Theme.stroke(Colors.stroke, 4) })
	local barFill = Theme.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = bar,
	}, { Theme.corner(8) })
	Theme.create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 150, 20), Color3.fromRGB(255, 235, 60)),
		Parent = barFill,
	})
	local levelLabel = Theme.label({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(0.55, 0, 1, -12),
		Font = Theme.FontBlack,
		Text = "Lv.1",
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 3,
		ZIndex = 2,
		Parent = bar,
	})
	local progressLabel = Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 6),
		Size = UDim2.new(0.42, 0, 1, -12),
		Font = Theme.FontBlack,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		Outline = 3,
		ZIndex = 2,
		Parent = bar,
	})

	-- Goal hint (top center) --------------------------------------------------------------
	local hint = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(560, 40),
		Font = Theme.FontBlack,
		Text = "",
		Outline = 3,
		Parent = screen,
	})
	local multLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.fromOffset(460, 22),
		Font = Theme.FontBold,
		Text = "",
		TextColor3 = Colors.gold,
		Outline = 2,
		Parent = screen,
	})

	-- Icon buttons (top right) ----------------------------------------------------------------
	local icons = Theme.create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(140, 62),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local tp = iconButton("teleport", "🗺️", actions.openTeleport)
	tp.LayoutOrder = 1
	tp.Parent = icons
	local hum, humBadge = iconButton("hum", "🥁", actions.hum)
	hum.LayoutOrder = 2
	hum.Parent = icons

	-- Boosts (right) -------------------------------------------------------------------------------
	local boosts = Theme.create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0.6, 0),
		Size = UDim2.fromOffset(170, 220),
		BackgroundTransparency = 1,
		Parent = screen,
	}, { Theme.create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
	local moneyCard, moneySub = boostCard(boosts, 1, "gold", "x2 MONEY")
	local speechCard, speechSub = boostCard(boosts, 2, "red", string.format("WOLF x%.1f", Config.Speech.mult))
	local humCard, humSub = boostCard(boosts, 3, "purple", "HUMMING")

	-- Live updates ---------------------------------------------------------------------------------
	-- Everything that steps aside while you're pitching.
	local hideInPitch = { grid, stats, bottom, hint, multLabel, icons }
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		for _, element in hideInPitch do
			element.Visible = not Store.inPitch
		end
		rainbow.Rotation = (t * 120) % 360
		local data = Store.data
		if not data then
			return
		end
		local profile = data.profile
		local target = profile.cash
		displayedCash += (target - displayedCash) * math.min(1, dt * 8)
		if math.abs(target - displayedCash) < 1 then
			displayedCash = target
		end
		cashLabel.Text = Format.cash(displayedCash)

		local now = os.time()
		moneyCard.Visible = (profile.boostUntil or 0) > now
		if moneyCard.Visible then
			moneySub.Text = Format.time(profile.boostUntil - now)
		end
		speechCard.Visible = Workspace:GetAttribute("SpeechActive") == true
		if speechCard.Visible then
			speechSub.Text = "SPEECH! " .. Format.time((Workspace:GetAttribute("SpeechEndsAt") or now) - now)
		end
		local readyAt = player:GetAttribute("HumReadyAt") or 0
		humBadge.Text = readyAt > now and Format.time(readyAt - now) or ""
		humCard.Visible = readyAt - now > Config.Hum.cooldown - Config.Hum.duration
		if humCard.Visible then
			humSub.Text = string.format("x%.1f  %s", Config.Hum.mult, Format.time(readyAt - now - (Config.Hum.cooldown - Config.Hum.duration)))
		end

		local canRebirth = profile.cash >= data.rebirthCost
		rebirthRing.Enabled = canRebirth
		ready.Visible = canRebirth
		if speechCard.Visible then
			hint.Text = "THE WOLF IS SPEAKING! SELL SELL SELL!"
			hint.TextColor3 = Colors.gold
		elseif canRebirth then
			hint.Text = "Rebirth to earn even more!"
			hint.TextColor3 = Color3.fromRGB(220, 170, 255)
		else
			hint.Text = "Sell pens. Get rich."
			hint.TextColor3 = Colors.text
		end
	end)

	Store.Changed:Connect(function(data, previous)
		local profile = data.profile
		incomeLabel.Text = "Income: +" .. Format.rate(data.income) .. "/s"
		brokersLabel.Text = string.format("%d/%d", #profile.brokers, Config.MaxBrokers)
		rebirthLabel.Text = tostring(profile.ipos)
		local pen = Config.findById(Config.Pens, profile.pen)
		multLabel.Text = string.format("🖊️ %s   ·   x%.1f rebirth   ·   x%.2f index", pen and pen.name or "?", data.ipoMult, data.indexMult)

		local level, progress, nextAt = Config.levelFor(profile.lifetime)
		local rank = Config.rankFor(profile.lifetime)
		levelLabel.Text = string.format("Lv.%d  %s", level, rank.title)
		levelLabel.TextColor3 = Color3.new(1, 1, 1)
		progressLabel.Text = Format.short(profile.lifetime) .. " / " .. Format.short(nextAt)
		Theme.tween(barFill, 0.3, { Size = UDim2.fromScale(math.max(0.02, progress), 1) })
		if not previous then
			displayedCash = profile.cash
		end
	end)
end

return Hud
