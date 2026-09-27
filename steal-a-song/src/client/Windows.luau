--!strict
-- De vensters achter de menuknoppen: Upgrades, Rebirth, Index, Gifts, Daily,
-- Store en de welkom-terug-melding. Er is steeds maar één venster open.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local Store = require(script.Parent.Store)
local UI = require(script.Parent.UI)

type Page = { frame: Frame, title: string, color: Color3, refresh: (any) -> () }

local Windows = {}

local refs: any = {}
local pages: { [string]: Page } = {}
local current: string? = nil
local toast: (string, string?) -> () = function() end

local function card(props: { [string]: any }): Frame
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.colors.panelLight,
		BorderSizePixel = 0,
	}, { UI.corner(14), UI.border(UI.colors.dark, 2) })
	for key, value in props do
		frame[key] = value
	end
	return frame
end

local function page(name: string, title: string, color: Color3): Frame
	local frame = UI.new("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = refs.content,
	})
	pages[name] = { frame = frame, title = title, color = color, refresh = function() end }
	return frame
end

local function call(name: string, ...: any)
	local ok, message = Store.call(name, ...)
	if not ok and message then
		toast(message, "bad")
	end
end

local function setButton(button: TextButton, text: string, enabled: boolean, color: Color3?)
	button.Text = text
	button.BackgroundColor3 = if enabled then color or UI.colors.green else UI.colors.grey
end

local function rewardText(reward: any, income: number): (string, string)
	if reward.kind == "song" then
		return "💿", string.upper(reward.rarity) .. " song"
	end
	return "💵", Format.cash(Economy.rewardCash(income, reward))
end

-- Upgrades ----------------------------------------------------------------

local function buildUpgrades()
	local frame = page("Upgrades", "⚡ UPGRADES", UI.colors.blue)
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), Parent = frame })
	local rows = {}
	for i, upgrade in Config.Upgrades do
		local row = card({ Size = UDim2.new(1, 0, 0, 104), LayoutOrder = i, Parent = frame })
		UI.text({ Text = upgrade.icon, Size = UDim2.fromOffset(76, 76), Position = UDim2.fromOffset(12, 14), Parent = row })
		local name = UI.text({
			Text = upgrade.name,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -290, 0, 34),
			Position = UDim2.fromOffset(98, 12),
			Parent = row,
		})
		UI.text({
			Text = upgrade.desc,
			TextColor3 = UI.colors.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -290, 0, 40),
			Position = UDim2.fromOffset(98, 50),
			Parent = row,
		})
		local button = UI.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(170, 60),
			Parent = row,
		}, function()
			call("BuyUpgrade", upgrade.id)
		end)
		rows[upgrade.id] = { name = name, button = button }
	end
	pages.Upgrades.refresh = function(state)
		for _, upgrade in Config.Upgrades do
			local row = rows[upgrade.id]
			local level = state.upgrades[upgrade.id] or 0
			row.name.Text = upgrade.name .. "  Lv " .. level .. "/" .. #upgrade.costs
			local cost = Economy.upgradeCost(upgrade.id, level)
			if cost then
				setButton(row.button, Format.cash(cost), state.cash >= cost)
			else
				setButton(row.button, "MAX", false)
			end
		end
	end
end

-- Rebirth -----------------------------------------------------------------

local function buildRebirth()
	local frame = page("Rebirth", "🔁 REBIRTH", UI.colors.green)
	local title = UI.text({ Text = "", Size = UDim2.new(1, 0, 0, 44), Parent = frame })
	local bar = UI.new("Frame", {
		Size = UDim2.new(1, -40, 0, 34),
		Position = UDim2.fromOffset(20, 56),
		BackgroundColor3 = UI.colors.dark,
		Parent = frame,
	}, { UI.corner(12) })
	local fill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UI.colors.green,
		Parent = bar,
	}, { UI.corner(12), UI.gradient(Color3.fromRGB(150, 255, 170), UI.colors.green) })
	local barText = UI.text({ Text = "", ZIndex = 3, Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3), Parent = bar })
	local rewards = UI.text({
		Text = "",
		RichText = true,
		TextScaled = false,
		TextSize = 24,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -40, 0, 170),
		Position = UDim2.fromOffset(20, 104),
		Parent = frame,
	})
	local button = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(300, 64),
		Parent = frame,
	}, function()
		call("Rebirth")
	end)

	pages.Rebirth.refresh = function(state)
		local r = state.rebirths
		local cost = state.rebirthCost
		title.Text = "Rebirth " .. r .. "  →  " .. (r + 1)
		fill.Size = UDim2.fromScale(math.clamp(state.cash / cost, 0, 1), 1)
		barText.Text = Format.cash(state.cash) .. " / " .. Format.cash(cost)
		rewards.Text = table.concat({
			"✅ Royalties <b>" .. Format.multiplier(Economy.rebirthMultiplier(r)) .. " → " .. Format.multiplier(
				Economy.rebirthMultiplier(r + 1)
			) .. "</b> forever",
			"✅ Studio slots <b>" .. Economy.slotCount(r) .. " → " .. Economy.slotCount(r + 1) .. "</b>",
			"✅ You <b>keep your best song</b>",
			"✅ Upgrades and Index stay",
			'<font color="#ff8090">❌ Cash and your other songs reset</font>',
		}, "\n")
		if state.cash >= cost then
			setButton(button, "REBIRTH!", true)
		else
			setButton(button, "Need " .. Format.cash(cost - state.cash) .. " more", false)
		end
	end
end

-- Index -------------------------------------------------------------------

local function buildIndex()
	local frame = page("Index", "📖 SONG INDEX", UI.colors.purple)
	local summary = UI.text({ Text = "", Size = UDim2.new(1, 0, 0, 30), Parent = frame })
	local scroll = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -38),
		Position = UDim2.fromOffset(0, 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local headers = {}
	local cards = {}
	for i, rarity in Config.Rarities do
		local section = UI.new("Frame", {
			Size = UDim2.new(1, -14, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Parent = scroll,
		}, { UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
		headers[rarity.name] = UI.text({
			Text = rarity.name,
			TextColor3 = if rarity.name == "Secret" then UI.colors.text else UI.rgb(rarity.color),
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 1,
			Parent = section,
		})
		local grid = UI.new("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = section,
		}, {
			UI.new("UIGridLayout", {
				CellSize = UDim2.fromOffset(104, 122),
				CellPadding = UDim2.fromOffset(8, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		local group: { Songs.SongDef } = Songs.byRarity[rarity.name] or {}
		for j, def in group do
			local cell = card({ LayoutOrder = j, Parent = grid })
			local disc = UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 12),
				Size = UDim2.fromOffset(56, 56),
				Parent = cell,
			}, { UI.round(), UI.border(Color3.fromRGB(20, 18, 26), 8) })
			UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(10, 10),
				BackgroundColor3 = UI.colors.dark,
				Parent = disc,
			}, { UI.round() })
			local question = UI.text({ Text = "?", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), ZIndex = 3, Parent = disc })
			local name = UI.text({ Text = "???", Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 78), Parent = cell })
			local dotsFrame = UI.new("Frame", {
				Size = UDim2.new(1, 0, 0, 12),
				Position = UDim2.fromOffset(0, 104),
				BackgroundTransparency = 1,
				Parent = cell,
			}, {
				UI.new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 5),
				}),
			})
			local dots = {}
			for k, mutation in Config.Mutations do
				dots[mutation.name] = UI.new("Frame", {
					Size = UDim2.fromOffset(12, 12),
					LayoutOrder = k,
					Parent = dotsFrame,
				}, { UI.round() })
			end
			cards[def.id] = { def = def, disc = disc, question = question, name = name, dots = dots }
		end
	end

	pages.Index.refresh = function(state)
		local discovered = state.discovered or {}
		local mutations = state.discoveredMut or {}
		local progress, bonus = Economy.indexProgress(discovered)
		local found = 0
		for _, entry in cards do
			local def = entry.def
			local known = discovered[def.id] == true
			if known then
				found += 1
			end
			entry.disc.BackgroundColor3 = if known then UI.rgb(def.color) else Color3.fromRGB(70, 64, 84)
			entry.question.Visible = not known
			entry.name.Text = if known then def.name else "???"
			for _, mutation in Config.Mutations do
				local dot = entry.dots[mutation.name]
				local has = mutations[def.id .. "|" .. mutation.name] == true
				dot.BackgroundColor3 = if has then UI.rgb(mutation.color) else UI.colors.dark
				dot.BackgroundTransparency = if has then 0 else 0.5
			end
		end
		for _, rarity in Config.Rarities do
			local p = progress[rarity.name]
			local done = p.total > 0 and p.found == p.total
			headers[rarity.name].Text = string.upper(rarity.name)
				.. "  "
				.. p.found
				.. "/"
				.. p.total
				.. (if done then "  ✅ +" .. math.floor(Config.IndexBonusPerRarity * 100) .. "%" else "  (complete: +" .. math.floor(
					Config.IndexBonusPerRarity * 100
				) .. "% royalties)")
		end
		summary.Text = "Discovered " .. found .. "/" .. #Songs.list .. "  ·  Index bonus +" .. math.floor(bonus * 100 + 0.5) .. "%"
	end
end

-- Gifts -------------------------------------------------------------------

local function buildGifts()
	local frame = page("Gifts", "🎁 PLAYTIME GIFTS", UI.colors.yellow)
	UI.text({ Text = "Stay in the game to unlock free gifts!", TextColor3 = UI.colors.muted, Size = UDim2.new(1, 0, 0, 26), Parent = frame })
	local grid = UI.new("Frame", {
		Size = UDim2.new(1, 0, 1, -34),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		Parent = frame,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(132, 150),
			CellPadding = UDim2.fromOffset(10, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local cells = {}
	for i, gift in Config.Gifts do
		local cell = card({ LayoutOrder = i, Parent = grid })
		local icon = UI.text({ Text = "🎁", Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 8), Parent = cell })
		local reward = UI.text({ Text = "", Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 56), Parent = cell })
		local button = UI.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -16, 0, 46),
			Parent = cell,
		}, function()
			call("ClaimGift", i)
		end)
		cells[i] = { gift = gift, icon = icon, reward = reward, button = button }
	end
	pages.Gifts.refresh = function(state)
		local minutes = Store.playMinutes()
		for i, cell in cells do
			local gift = cell.gift
			local needed = gift.minutes or 0
			local icon, text = rewardText(gift, state.income or 0)
			cell.icon.Text = icon
			cell.reward.Text = text
			local claimed = state.giftsClaimed and state.giftsClaimed[i]
			if claimed then
				setButton(cell.button, "✓ Claimed", false)
			elseif minutes >= needed then
				setButton(cell.button, "CLAIM!", true)
			else
				setButton(cell.button, Format.time((needed - minutes) * 60), false, UI.colors.blue)
			end
		end
	end
end

-- Daily -------------------------------------------------------------------

local function buildDaily()
	local frame = page("Daily", "📅 DAILY REWARDS", UI.colors.accent)
	UI.text({ Text = "Come back every day! Day 7 is a LEGENDARY song.", TextColor3 = UI.colors.muted, Size = UDim2.new(1, 0, 0, 26), Parent = frame })
	local row = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 150),
		Position = UDim2.fromOffset(0, 40),
		BackgroundTransparency = 1,
		Parent = frame,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local cells = {}
	for i, reward in Config.Daily do
		local cell = card({ Size = UDim2.fromOffset(74, 150), LayoutOrder = i, Parent = row })
		UI.text({ Text = "Day " .. i, Size = UDim2.new(1, -8, 0, 24), Position = UDim2.fromOffset(4, 8), Parent = cell })
		local icon = UI.text({ Text = "", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 40), Parent = cell })
		local text = UI.text({ Text = "", Size = UDim2.new(1, -8, 0, 36), Position = UDim2.fromOffset(4, 88), TextWrapped = true, Parent = cell })
		local stroke = cell:FindFirstChildOfClass("UIStroke")
		cells[i] = { reward = reward, cell = cell, icon = icon, text = text, stroke = stroke }
	end
	local button = UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(320, 64),
		Parent = frame,
	}, function()
		call("ClaimDaily")
	end)

	pages.Daily.refresh = function(state)
		local daily = state.daily or { canClaim = false, streak = 0, nextIn = 0 }
		local streak = daily.streak or 0
		-- Welke dag van de week van 7 is nu aan de beurt?
		local nextDay = if daily.canClaim then streak else streak + 1
		local cycleDay = (math.max(nextDay, 1) - 1) % #Config.Daily + 1
		for i, cell in cells do
			local icon, text = rewardText(cell.reward, state.income or 0)
			cell.icon.Text = if i < cycleDay then "✅" else icon
			cell.text.Text = text
			cell.cell.BackgroundColor3 = if i == cycleDay then UI.colors.accent else UI.colors.panelLight
			if cell.stroke then
				cell.stroke.Color = if i == cycleDay then UI.colors.text else UI.colors.dark
			end
		end
		if daily.canClaim then
			setButton(button, "CLAIM DAY " .. cycleDay .. "!", true)
		else
			local waited = os.clock() - Store.receivedAt
			setButton(button, "Next in " .. Format.time((daily.nextIn or 0) - waited), false, UI.colors.blue)
		end
	end
end

-- Store -------------------------------------------------------------------

local function buildStore()
	local frame = page("Store", "💎 STORE", Color3.fromRGB(255, 120, 200))
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), Parent = frame })
	local rows = {}
	for i, pass in Config.GamePasses do
		if pass.id ~= 0 then
			local row = card({ Size = UDim2.new(1, 0, 0, 100), LayoutOrder = i, Parent = frame })
			UI.text({ Text = pass.icon, Size = UDim2.fromOffset(72, 72), Position = UDim2.fromOffset(12, 14), Parent = row })
			UI.text({
				Text = pass.name,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -280, 0, 36),
				Position = UDim2.fromOffset(96, 12),
				Parent = row,
			})
			UI.text({
				Text = pass.desc,
				TextColor3 = UI.colors.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -280, 0, 30),
				Position = UDim2.fromOffset(96, 54),
				Parent = row,
			})
			local button = UI.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(160, 58),
				Parent = row,
			}, function()
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.id)
			end)
			rows[pass.key] = button
		end
	end
	pages.Store.refresh = function(state)
		for key, button in rows do
			local owned = state.passes and state.passes[key]
			setButton(button, if owned then "Owned ✓" else "Buy", not owned, UI.colors.yellow)
		end
	end
end

-- Welkom terug ------------------------------------------------------------

local function buildOffline()
	local frame = page("Offline", "👋 WELCOME BACK!", UI.colors.green)
	refs.offlineText = UI.text({
		Text = "",
		RichText = true,
		TextWrapped = true,
		Size = UDim2.new(1, -40, 0, 180),
		Position = UDim2.fromOffset(20, 40),
		Parent = frame,
	})
	UI.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(260, 64),
		Text = "AWESOME!",
		Parent = frame,
	}, function()
		Windows.close()
	end)
end

function Windows.build(screen: GuiObject, toastFn: (string, string?) -> ())
	toast = toastFn
	local window = UI.new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromOffset(620, 460),
		BackgroundColor3 = UI.colors.panel,
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	}, { UI.corner(22), UI.border(UI.colors.dark, 4) })
	refs.window = window
	refs.scale = UI.new("UIScale", { Parent = window })

	local titleBar = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = UI.colors.accent,
		Parent = window,
	}, { UI.corner(22) })
	refs.titleBar = titleBar
	refs.title = UI.text({
		Text = "",
		Size = UDim2.new(1, -120, 1, -12),
		Position = UDim2.fromOffset(20, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		strokeThickness = 3,
		Parent = titleBar,
	})
	UI.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(46, 46),
		Text = "X",
		color = UI.colors.red,
		Parent = titleBar,
	}, function()
		Windows.close()
	end)

	refs.content = UI.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -32, 1, -84),
		Position = UDim2.fromOffset(16, 70),
		BackgroundTransparency = 1,
		Parent = window,
	})

	buildUpgrades()
	buildRebirth()
	buildIndex()
	buildGifts()
	buildDaily()
	buildStore()
	buildOffline()
end

function Windows.open(name: string)
	if current == name then
		Windows.close()
		return
	end
	local target = pages[name]
	if not target then
		return
	end
	for pageName, p in pages do
		p.frame.Visible = pageName == name
	end
	current = name
	refs.title.Text = target.title
	refs.titleBar.BackgroundColor3 = target.color
	refs.window.Visible = true
	refs.scale.Scale = 0.85
	UI.tween(refs.scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	if Store.state then
		target.refresh(Store.state)
	end
end

function Windows.close()
	current = nil
	refs.window.Visible = false
end

function Windows.isOpen(): boolean
	return current ~= nil
end

function Windows.setState(state: any)
	if current and pages[current] then
		pages[current].refresh(state)
	end
end

-- Timers in Gifts en Daily laten doorlopen
function Windows.tick()
	if (current == "Gifts" or current == "Daily") and Store.state then
		pages[current].refresh(Store.state)
	end
end

function Windows.showOffline(amount: number, seconds: number)
	refs.offlineText.Text = "While you were away for <b>"
		.. Format.duration(seconds)
		.. "</b>, your songs kept streaming!\n\n"
		.. '<font color="#6eff82"><b>+'
		.. Format.cash(amount)
		.. "</b></font>"
	Windows.open("Offline")
	UI.sound("Rebirth", 1.2, 0.5)
end

return Windows
