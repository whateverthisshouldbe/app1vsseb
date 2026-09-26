-- The shop (pens, suits, phones), the rebirth screen and the how-to-play
-- screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Animations = require(ReplicatedStorage.Shared.Animations)
local Theme = require(script.Parent.Theme)
local Modal = require(script.Parent.Modal)
local Notifier = require(script.Parent.Notifier)
local Store = require(script.Parent.Parent.Store)

local Remotes = ReplicatedStorage.Remotes
local Colors = Theme.Colors

local Shop = {}

local TABS = {
	{ id = "pen", name = "Pens", color = Colors.pen },
	{ id = "suit", name = "Suits", color = Colors.you },
	{ id = "phone", name = "Phones", color = Colors.money },
}

local shopModal, ipoModal, helpModal
local list
local currentTab = "pen"
local tabButtons = {}

local function buy(category, id)
	local ok, message = Remotes.Purchase:InvokeServer(category, id)
	Notifier.show(message, ok and "success" or "error")
end

-- Returns rows: { title, detail, cost, state = "owned"|"buy"|"locked", action }
local function rowsFor(tab, profile)
	local rows = {}
	if tab == "pen" or tab == "suit" or tab == "phone" then
		local items = tab == "pen" and Config.Pens or (tab == "suit" and Config.Suits or Config.Phones)
		local _, ownedIndex = Config.findById(items, profile[tab])
		for index, item in items do
			local detail
			if tab == "pen" then
				detail = string.format("Base sale %s  ·  %s", Format.cash(item.value), item.blurb)
			elseif tab == "suit" then
				detail = string.format("+%.1f certainty  ·  %d%% sweet spot  ·  x%.2f cash  ·  %s walk", item.startBonus, item.sweetSpot * 100, item.cashMult, Animations.BySuit[item.id] or "?")
			else
				detail = item.income > 0 and string.format("Cold calls earn %s/s while you play (and half offline)", Format.cash(item.income)) or "Silence."
			end
			local state = index <= (ownedIndex or 0) and "owned" or "buy"
			table.insert(rows, {
				title = item.name,
				detail = detail,
				cost = item.cost,
				state = state,
				color = item.color,
				action = function()
					buy(tab, item.id)
				end,
			})
		end
	end
	return rows
end

local lastSignature

local function render(force)
	local profile = Store.profile()
	if not profile or not list then
		return
	end
	local rows = rowsFor(currentTab, profile)
	-- Passive income syncs every second; only rebuild when something visible changed.
	local signature = currentTab
	for _, row in rows do
		signature ..= "|" .. row.title .. row.state .. tostring(profile.cash >= row.cost)
	end
	if signature == lastSignature and force ~= true then
		return
	end
	lastSignature = signature

	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for id, button in tabButtons do
		button.BackgroundColor3 = id == currentTab and Colors.panelLight or Colors.panel
	end

	for order, row in rows do
		local affordable = profile.cash >= row.cost
		local frame = Theme.create("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, -8, 0, 64),
			BackgroundColor3 = Colors.panel,
			Parent = list,
		}, {
			Theme.corner(10),
			Theme.stroke(row.state == "owned" and Colors.money or Colors.stroke, 1),
		})
		if row.color then
			Theme.create("Frame", {
				Position = UDim2.fromOffset(10, 12),
				Size = UDim2.fromOffset(40, 40),
				BackgroundColor3 = row.color,
				Parent = frame,
			}, { Theme.corner(20), Theme.stroke(Color3.new(1, 1, 1), 1, 0.6) })
		end
		local textX = row.color and 60 or 14
		Theme.label({
			Position = UDim2.fromOffset(textX, 6),
			Size = UDim2.new(1, -textX - 150, 0, 26),
			Font = Theme.FontBlack,
			Text = row.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})
		Theme.label({
			Position = UDim2.fromOffset(textX, 34),
			Size = UDim2.new(1, -textX - 150, 0, 22),
			Font = Theme.Font,
			Text = row.detail,
			TextColor3 = Colors.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})

		local buttonText, buttonColor
		if row.state == "owned" then
			buttonText, buttonColor = "OWNED", Colors.panelLight
		elseif row.state == "locked" then
			buttonText, buttonColor = "LOCKED", Colors.panelLight
		else
			buttonText = (row.buyText or "BUY") .. "\n" .. (row.cost == 0 and "FREE" or Format.cash(row.cost))
			buttonColor = affordable and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(90, 45, 45)
		end
		local button = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(130, 48),
			BackgroundColor3 = buttonColor,
			Font = Theme.FontBlack,
			Text = buttonText,
			Parent = frame,
		}, function()
			if row.state == "buy" then
				row.action()
			end
		end)
		Theme.corner(10).Parent = button
	end
end

local function buildShop(screen)
	shopModal = Modal.new(screen, "PEN STREET SUPPLY CO.", Colors.money, Vector2.new(720, 500))
	local content = shopModal.content

	local tabs = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = content,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
		}),
	})
	for _, tab in TABS do
		local button = Theme.button({
			Size = UDim2.new(1 / #TABS, -7, 1, 0),
			BackgroundColor3 = Colors.panel,
			Font = Theme.FontBlack,
			Text = tab.name,
			TextColor3 = tab.color,
			Parent = tabs,
		}, function()
			currentTab = tab.id
			render(true)
		end)
		Theme.corner(10).Parent = button
		tabButtons[tab.id] = button
	end

	list = Theme.create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	shopModal.onOpen = function()
		render(true)
	end
end

local ipoInfo, ipoButton
local function renderIPO()
	local data = Store.data
	if not data or not ipoInfo then
		return
	end
	local profile = data.profile
	local hasCash = profile.cash >= data.rebirthCost
	local nextZone
	for _, zone in Config.Zones do
		if zone.rebirths == profile.ipos + 1 then
			nextZone = zone
		end
	end
	ipoInfo.Text = string.format(
		"Take Stratton Oakpen public (rebirth %d).\n\nYou LOSE: cash, pen, suit and phone.\nYou KEEP: your brokers, your Index and a permanent x%.1f multiplier (now x%.1f).%s\n\n%s  Have %s cash (you have %s)",
		profile.ipos + 1,
		data.nextIpoMult,
		data.ipoMult,
		nextZone and ("\nUNLOCKS: " .. nextZone.name .. "!") or "",
		hasCash and "[OK]" or "[  ]",
		Format.cash(data.rebirthCost),
		Format.cash(profile.cash)
	)
	ipoButton.BackgroundColor3 = hasCash and Color3.fromRGB(140, 70, 220) or Colors.panelLight
end

local function buildIPO(screen)
	ipoModal = Modal.new(screen, "REBIRTH: RING THE BELL", Colors.purple, Vector2.new(560, 420))
	ipoInfo = Theme.label({
		Size = UDim2.new(1, 0, 1, -80),
		Font = Theme.FontBold,
		TextScaled = false,
		TextSize = 19,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = ipoModal.content,
	})
	ipoButton = Theme.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0.7, 0, 0, 60),
		Font = Theme.FontBlack,
		Text = "REBIRTH",
		Parent = ipoModal.content,
	}, function()
		local ok, message = Remotes.IPO:InvokeServer()
		Notifier.show(message, ok and "big" or "error")
		if ok then
			ipoModal:close()
		end
	end)
	Theme.corner(12).Parent = ipoButton
	ipoModal.onOpen = renderIPO
end

local HELP_TEXT = [[<b><font color="#FFC846">1. Find a customer.</font></b> Walk up to anyone and press <b>E</b> to pitch.

<b><font color="#FFC846">2. Build certainty.</font></b> Every buyer needs to be sure about three things: the <font color="#6EBEFF">PEN</font>, <font color="#FFAA46">YOU</font> and your <font color="#BE82FF">FIRM</font>. Pick a line, then stop the tonality needle in the green zone. Better timing = bigger effect.

<b><font color="#FFC846">3. Read the room.</font></b> Customers like and hate certain kinds of lines. Hedge fund bros love pressure; duchesses do not. The Undercover FBI Agent only trusts honesty.

<b><font color="#FFC846">4. Close.</font></b> Hit CLOSE whenever you like. Higher certainty = better odds and a bigger sale. Max all three bars for a PERFECT CLOSE.

<b><font color="#FFC846">5. Rarities.</font></b> Every visitor has a rarity, from Common (x3) to the one and only Ultra Exotic <b>Beldan Jolfort</b> (x6000). Rarer visitors pay far more, but are harder to convince. Fancier zones attract rarer visitors.

<b><font color="#FFC846">6. Cash or recruit?</font></b> After every sale you choose: take the money, or recruit the visitor as a broker. You can have 8 brokers; they earn their daily wage all the time (half while you're offline).

<b><font color="#FFC846">7. Index.</font></b> 150 unique visitors to collect. Every one you sell to adds +0.5% to all your sales.

<b><font color="#FFC846">8. Rebirth.</font></b> Buy better pens, suits and phones, then rebirth. New zones open at 1, 3, 5, 8, 10 and 14 rebirths. Use TP to travel.

<b><font color="#FFC846">Moving.</font></b> Hold <b>Left Shift</b> to sprint (RUN button on mobile). Better suits give you a cooler walk. Jump often: sometimes you'll pull off a flip.

<b><font color="#FFC846">Secrets.</font></b> Sometimes a mysterious napkin line appears. Use it. Hum (H) with other players for a crowd boost. Be on the Trading Floor when the Wolf gives his speech.]]

local function buildHelp(screen)
	helpModal = Modal.new(screen, "HOW TO SELL A PEN", Colors.blue, Vector2.new(640, 520))
	local scroll = Theme.create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = helpModal.content,
	})
	Theme.label({
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.Font,
		TextScaled = false,
		TextSize = 18,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = HELP_TEXT,
		Parent = scroll,
	})
end

function Shop.mount(screen)
	buildShop(screen)
	buildIPO(screen)
	buildHelp(screen)
	Store.Changed:Connect(function()
		if shopModal.frame.Visible then
			render()
		end
		if ipoModal.frame.Visible then
			renderIPO()
		end
	end)
end

function Shop.toggleShop(tab)
	if tab then
		currentTab = tab
	end
	shopModal:toggle()
end

function Shop.openIPO()
	ipoModal:toggle()
end

function Shop.openHelp()
	helpModal:toggle()
end

return Shop
