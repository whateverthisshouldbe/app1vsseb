--!strict
-- Alles wat altijd in beeld is: geld, inkomen, het event, de menuknoppen,
-- meldingen, aankondigingen, tips en het alarm als iemand jou besteelt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))

local Store = require(script.Parent.Store)
local UI = require(script.Parent.UI)

local Hud = {}

local refs: any = { badges = {} }
local displayedCash = 0
local lastCash: number? = nil
local lastRebirths: number? = nil
local carry: any = nil
local alarm: any = nil
local alarmSoundAt = 0
local announceToken = 0
local toastCount = 0
local badgeTimer = 0
local eventTimer = 0

local KIND_COLORS = {
	good = UI.colors.green,
	bad = UI.colors.red,
	info = UI.colors.blue,
	buy = UI.colors.yellow,
	rare = UI.colors.accent,
}

local function escapeRich(text: string): string
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	return text
end

local function chat(text: string, color: Color3)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if general and general:IsA("TextChannel") then
		pcall(function()
			general:DisplaySystemMessage(string.format('<font color="#%s">%s</font>', color:ToHex(), escapeRich(text)))
		end)
	end
end

local function menuButton(parent: Instance, name: string, icon: string, caption: string, color: Color3, onClick: () -> ())
	local button = UI.button({
		Name = name,
		Size = UDim2.fromOffset(78, 78),
		color = color,
		radius = 18,
		Parent = parent,
	}, onClick)
	UI.text({ Text = icon, Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.fromScale(0, 0.06), Parent = button })
	UI.text({ Text = caption, Size = UDim2.new(1, -8, 0.24, 0), Position = UDim2.new(0, 4, 0.7, 0), Parent = button })
	local badge = UI.new("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = UI.colors.red,
		Visible = false,
		ZIndex = 3,
		Parent = button,
	}, { UI.round(), UI.border(UI.colors.text, 2) })
	local label = UI.text({ Text = "!", ZIndex = 4, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Parent = badge })
	refs.badges[name] = { frame = badge, label = label }
end

local function setBadge(name: string, value: number | string | nil)
	local badge = refs.badges[name]
	if not badge then
		return
	end
	local show = value ~= nil and value ~= 0
	badge.frame.Visible = show
	if show then
		badge.label.Text = tostring(value)
	end
end

local function edge(parent: Instance, size: UDim2, position: UDim2, rotation: number): Frame
	return UI.new("Frame", {
		Size = size,
		Position = position,
		BackgroundColor3 = UI.colors.red,
		BorderSizePixel = 0,
		Parent = parent,
	}, {
		UI.new("UIGradient", {
			Rotation = rotation,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
end

function Hud.build(screen: GuiObject, openWindow: (string) -> ())
	-- Geld en inkomen, bovenin het midden
	local cashPanel = UI.new("Frame", {
		Name = "CashPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(330, 88),
		BackgroundColor3 = UI.colors.bg,
		BackgroundTransparency = 0.15,
		Parent = screen,
	}, { UI.corner(20), UI.border(UI.colors.green, 3) })
	refs.cashScale = UI.new("UIScale", { Parent = cashPanel })
	refs.cash = UI.text({
		Text = "$0",
		TextColor3 = UI.colors.green,
		Size = UDim2.new(1, -24, 0.6, 0),
		Position = UDim2.fromOffset(12, 4),
		strokeThickness = 3,
		Parent = cashPanel,
	})
	refs.income = UI.text({
		Text = "+$0/s",
		Size = UDim2.new(0.58, 0, 0.3, 0),
		Position = UDim2.new(0.04, 0, 0.64, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = cashPanel,
	})
	refs.boostPanel = UI.new("Frame", {
		Name = "Boosts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 142),
		Size = UDim2.fromOffset(260, 150),
		BackgroundColor3 = UI.colors.bg,
		BackgroundTransparency = 0.1,
		Visible = false,
		ZIndex = 5,
		Parent = screen,
	}, { UI.corner(14), UI.border(UI.colors.accent, 2), UI.padding(8) })
	refs.boostText = UI.text({
		Text = "",
		RichText = true,
		ZIndex = 6,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextScaled = false,
		TextSize = 20,
		Parent = refs.boostPanel,
	})
	refs.multiplier = UI.button({
		Text = "x1",
		Size = UDim2.new(0.3, 0, 0.3, 0),
		Position = UDim2.new(0.66, 0, 0.63, 0),
		color = UI.colors.accent,
		radius = 8,
		Parent = cashPanel,
	}, function()
		refs.boostPanel.Visible = not refs.boostPanel.Visible
	end)

	-- Eventbalk onder het geld
	local eventBar = UI.new("Frame", {
		Name = "EventBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100),
		Size = UDim2.fromOffset(420, 34),
		BackgroundColor3 = UI.colors.bg,
		BackgroundTransparency = 0.2,
		Parent = screen,
	}, { UI.corner(12) })
	refs.eventStroke = UI.border(UI.colors.muted, 2)
	refs.eventStroke.Parent = eventBar
	refs.eventLabel = UI.text({
		Text = "",
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.fromOffset(8, 3),
		Parent = eventBar,
	})

	-- Menuknoppen links
	local menu = UI.new("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(84, 540),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local buttons: { { any } } = {
		{ "Gifts", "🎁", "Gifts", UI.colors.yellow },
		{ "Upgrades", "⚡", "Upgrades", UI.colors.blue },
		{ "Rebirth", "🔁", "Rebirth", UI.colors.green },
		{ "Index", "📖", "Index", UI.colors.purple },
		{ "Daily", "📅", "Daily", UI.colors.accent },
	}
	local hasPasses = false
	for _, pass in Config.GamePasses do
		if pass.id ~= 0 then
			hasPasses = true
		end
	end
	if hasPasses then
		local store: { any } = { "Store", "💎", "Store", Color3.fromRGB(255, 120, 200) }
		table.insert(buttons, store)
	end
	for i, b in buttons do
		menuButton(menu, b[1], b[2], b[3], b[4], function()
			openWindow(b[1])
		end)
		refs.badges[b[1]].frame.Parent.LayoutOrder = i
	end

	-- Meldingen
	refs.toasts = UI.new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 142),
		Size = UDim2.fromOffset(560, 260),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	refs.announce = UI.text({
		Name = "Announcement",
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.34, 0),
		Size = UDim2.new(0.8, 0, 0, 56),
		Visible = false,
		strokeThickness = 4,
		Parent = screen,
	})
	refs.announceScale = UI.new("UIScale", { Parent = refs.announce })

	-- Tip onderin, boven de toolbar
	refs.hint = UI.new("Frame", {
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(620, 46),
		BackgroundColor3 = UI.colors.bg,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = screen,
	}, { UI.corner(14) })
	refs.hintStroke = UI.border(UI.colors.yellow, 2.5)
	refs.hintStroke.Parent = refs.hint
	refs.hintLabel = UI.text({
		Text = "",
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		Parent = refs.hint,
	})
	refs.hintScale = UI.new("UIScale", { Parent = refs.hint })

	-- Alarm: rode randen en een banner
	refs.alarm = UI.new("Frame", {
		Name = "Alarm",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screen,
	})
	refs.alarmEdges = {
		edge(refs.alarm, UDim2.fromScale(1, 0.2), UDim2.fromScale(0, 0), 90),
		edge(refs.alarm, UDim2.fromScale(1, 0.2), UDim2.fromScale(0, 0.8), 270),
		edge(refs.alarm, UDim2.fromScale(0.12, 1), UDim2.fromScale(0, 0), 0),
		edge(refs.alarm, UDim2.fromScale(0.12, 1), UDim2.fromScale(0.88, 0), 180),
	}
	refs.alarmBanner = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -156),
		Size = UDim2.fromOffset(640, 52),
		BackgroundColor3 = UI.colors.red,
		Parent = refs.alarm,
	}, { UI.corner(14), UI.border(UI.colors.text, 3) })
	refs.alarmLabel = UI.text({
		Text = "",
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		Parent = refs.alarmBanner,
	})
end

function Hud.toast(text: string, kind: string?)
	local color = KIND_COLORS[kind or "info"] or UI.colors.blue
	toastCount += 1
	local frame = UI.new("Frame", {
		Size = UDim2.fromOffset(540, 40),
		BackgroundColor3 = UI.colors.bg,
		BackgroundTransparency = 0.1,
		LayoutOrder = toastCount,
		Parent = refs.toasts,
	}, { UI.corner(12) })
	local stroke = UI.border(color, 2.5)
	stroke.Parent = frame
	local label = UI.text({
		Text = text,
		TextColor3 = if kind == "info" then UI.colors.text else color,
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		Parent = frame,
	})
	local scale = UI.new("UIScale", { Parent = frame })
	UI.pop(scale, 0.15)

	if kind == "buy" then
		UI.sound("Buy", 1.2)
	elseif kind == "rare" then
		UI.sound("Announce", 1.4)
	elseif kind == "bad" then
		UI.sound("Click", 0.6)
	end

	-- Oudste weg als er te veel staan
	local frames = {}
	for _, child in refs.toasts:GetChildren() do
		if child:IsA("Frame") then
			table.insert(frames, child)
		end
	end
	if #frames > 5 then
		table.sort(frames, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		frames[1]:Destroy()
	end

	task.delay(3.5, function()
		if not frame.Parent then
			return
		end
		UI.tween(frame, 0.4, { BackgroundTransparency = 1 })
		UI.tween(label, 0.4, { TextTransparency = 1 })
		UI.tween(stroke, 0.4, { Transparency = 1 })
		local textStroke = label:FindFirstChildOfClass("UIStroke")
		if textStroke then
			UI.tween(textStroke, 0.4, { Transparency = 1 })
		end
		task.wait(0.45)
		frame:Destroy()
	end)
end

function Hud.announce(text: string, color: { number }?, big: boolean?)
	local c = if color then UI.rgb(color) else UI.colors.text
	if color and color[1] < 60 and color[2] < 60 and color[3] < 60 then
		c = Color3.fromRGB(230, 230, 245) -- Secret is bijna zwart, dat lees je niet
	end
	local label = refs.announce
	label.Text = text
	label.TextColor3 = c
	label.TextTransparency = 0
	label.Size = UDim2.new(0.8, 0, 0, if big then 70 else 48)
	label.Visible = true
	UI.pop(refs.announceScale, if big then 0.35 else 0.2)
	UI.sound("Announce", if big then 0.8 else 1)
	chat(text, c)

	announceToken += 1
	local token = announceToken
	task.delay(if big then 5 else 3.5, function()
		if token ~= announceToken then
			return
		end
		UI.tween(label, 0.5, { TextTransparency = 1 })
		task.wait(0.5)
		if token == announceToken then
			label.Visible = false
		end
	end)
end

function Hud.setCarry(info: any)
	carry = if info and info.active then info else nil
end

function Hud.setAlarm(info: any)
	if info and info.active then
		alarm = info
		refs.alarmLabel.Text = "🚨 " .. tostring(info.thief) .. " is stealing " .. tostring(info.song) .. "! Smack them with your guitar! 🎸"
		refs.alarm.Visible = true
		alarmSoundAt = 0
	else
		alarm = nil
		refs.alarm.Visible = false
	end
end

local function refreshBoosts(state: any)
	local b = state.boosts or {}
	local lines = {
		string.format("🔁 Rebirth <b>%s</b>", Format.multiplier(b.rebirth or 1)),
		string.format("📖 Index <b>%s</b>", Format.multiplier(b.index or 1)),
		string.format("👯 Friends <b>%s</b>", Format.multiplier(b.friends or 1)),
		string.format("💎 Passes <b>%s</b>", Format.multiplier(b.pass or 1)),
		string.format("🎉 Event <b>%s</b>", Format.multiplier(b.event or 1)),
	}
	refs.boostText.Text = table.concat(lines, "\n")
end

local function refreshBadges(state: any)
	local claimable = 0
	local minutes = Store.playMinutes()
	for i, gift in Config.Gifts do
		if not (state.giftsClaimed and state.giftsClaimed[i]) and minutes >= (gift.minutes or 0) then
			claimable += 1
		end
	end
	setBadge("Gifts", claimable)
	setBadge("Daily", if state.daily and state.daily.canClaim then "!" else nil)
	setBadge("Rebirth", if state.cash >= state.rebirthCost then "!" else nil)
	local affordable = 0
	for _, upgrade in Config.Upgrades do
		local cost = Economy.upgradeCost(upgrade.id, state.upgrades[upgrade.id] or 0)
		if cost and state.cash >= cost then
			affordable += 1
		end
	end
	setBadge("Upgrades", affordable)
end

local function currentHint(state: any): (string?, Color3)
	if carry then
		return "🏃 Bring " .. tostring(carry.song) .. " to YOUR studio! Don't get hit!", UI.colors.green
	end
	if not state then
		return nil, UI.colors.yellow
	end
	if state.songCount == 0 then
		return "👉 Buy your first song on the red carpet! Walk up to it and press E", UI.colors.yellow
	end
	if (state.uncollected or 0) >= math.max(25, state.income * 15) then
		return "💰 Walk over the green pads in your studio to collect " .. Format.cash(state.uncollected), UI.colors.green
	end
	if state.freeSlots == 0 then
		return "📦 Studio full! Sell a song (hold F) or Rebirth for more room", UI.colors.accent
	end
	return nil, UI.colors.yellow
end

function Hud.setState(state: any)
	if lastCash and state.cash > lastCash + 0.5 then
		UI.pop(refs.cashScale, 0.08)
	end
	if lastCash == nil then
		displayedCash = state.cash
		refs.cash.Text = Format.cash(displayedCash)
	end
	lastCash = state.cash

	if lastRebirths and state.rebirths > lastRebirths then
		UI.sound("Rebirth")
		Hud.announce("🔁 REBIRTH " .. state.rebirths .. "!", { 120, 255, 200 }, true)
	end
	lastRebirths = state.rebirths

	refs.income.Text = "+" .. Format.perSecond(state.income or 0)
	refs.multiplier.Text = "🚀 " .. Format.multiplier(state.multiplier or 1)
	refreshBoosts(state)
	refreshBadges(state)
end

function Hud.update(dt: number)
	local state = Store.state
	if state then
		local target = state.cash
		if displayedCash ~= target then
			local diff = target - displayedCash
			if math.abs(diff) < 1 or math.abs(diff) < math.abs(target) * 0.0005 then
				displayedCash = target
			else
				displayedCash += diff * math.min(1, dt * 8)
			end
			refs.cash.Text = Format.cash(displayedCash)
		end

		badgeTimer += dt
		if badgeTimer >= 1 then
			badgeTimer = 0
			refreshBadges(state)
		end
	end

	-- Hint
	local hint, color = currentHint(state)
	refs.hint.Visible = hint ~= nil
	if hint then
		if refs.hintLabel.Text ~= hint then
			refs.hintLabel.Text = hint
			UI.pop(refs.hintScale, 0.1)
		end
		refs.hintLabel.TextColor3 = color
		refs.hintStroke.Color = color
		if carry then
			refs.hintScale.Scale = 1 + math.sin(os.clock() * 8) * 0.03
		end
	end

	-- Event-aftelling, vier keer per seconde is genoeg
	eventTimer += dt
	if eventTimer >= 0.25 then
		eventTimer = 0
		local info = Store.event
		local now = Workspace:GetServerTimeNow()
		if info and info.current then
			local e = info.current
			refs.eventLabel.Text = e.icon .. " " .. string.upper(e.name) .. " · " .. e.desc .. " · " .. Format.time(e.endsAt - now)
			local c = UI.rgb(e.color)
			refs.eventLabel.TextColor3 = c
			refs.eventStroke.Color = c
		elseif info then
			refs.eventLabel.Text = "⏳ Next event in " .. Format.time(info.nextAt - now)
			refs.eventLabel.TextColor3 = UI.colors.muted
			refs.eventStroke.Color = UI.colors.muted
		end
	end

	-- Alarm laten knipperen en piepen
	if alarm then
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * 10)
		for _, frame in refs.alarmEdges do
			frame.BackgroundTransparency = 0.1 + pulse * 0.5
		end
		refs.alarmBanner.BackgroundTransparency = pulse * 0.3
		if os.clock() - alarmSoundAt > 0.7 then
			alarmSoundAt = os.clock()
			UI.sound("Alarm", 0.6, 0.7)
		end
	end
end

return Hud
