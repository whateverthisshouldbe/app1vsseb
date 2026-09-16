-- Sell Me This Pen - CLIENT. Plak dit in een LocalScript in StarterPlayer > StarterPlayerScripts.
-- AUTOMATISCH GEGENEREERD door tools/bundle.py - niet met de hand aanpassen.
-- Pas de bestanden in src/ aan en draai het script opnieuw.

local PEN = {}

PEN.Config = (function()
	--!strict
	-- Alle balans-instellingen van "Sell Me This Pen" staan hier.
	-- Wil je de game sneller/langzamer maken? Pas alleen dit bestand aan.

	local Config = {}

	Config.GameName = "Sell Me This Pen"
	Config.DataStoreKey = "PenTycoon_v1" -- ophogen = iedereen begint opnieuw

	-- Pennen die je maakt. Je maakt altijd de hoogste pen die je hebt vrijgespeeld.
	-- Vrijspelen gebeurt met rebirths (zie Config.Rebirth.penUnlockPerRebirth).
	Config.Pens = {
		{ name = "Balpen",        value = 4,     color = Color3.fromRGB(35, 35, 40) },
		{ name = "Gelpen",        value = 14,    color = Color3.fromRGB(30, 110, 220) },
		{ name = "Marker",        value = 45,    color = Color3.fromRGB(230, 90, 40) },
		{ name = "Vulpen",        value = 150,   color = Color3.fromRGB(150, 120, 60) },
		{ name = "Zilveren pen",  value = 520,   color = Color3.fromRGB(190, 195, 205) },
		{ name = "Gouden pen",    value = 1900,  color = Color3.fromRGB(235, 190, 60) },
		{ name = "Diamanten pen", value = 7200,  color = Color3.fromRGB(120, 230, 235) },
		{ name = "Sterrenpen",    value = 28000, color = Color3.fromRGB(180, 110, 240) },
	}

	-- Upgrades die je bij de kiosk koopt.
	-- prijs = basePrice * (growth ^ (level - 1))
	Config.Upgrades = {
		{
			key = "capacity",
			name = "Grotere tas",
			info = "Meer pennen tegelijk dragen",
			basePrice = 60,
			growth = 1.28,
			maxLevel = 40,
			-- level 1 = 12 pennen, elke level +6
			value = function(level: number): number
				return 6 + level * 6
			end,
			format = function(v: number): string
				return string.format("%d pennen", v)
			end,
		},
		{
			key = "speed",
			name = "Snellere pers",
			info = "Sneller pennen maken",
			basePrice = 90,
			growth = 1.33,
			maxLevel = 40,
			-- seconden per pen, van 1.0s naar minimaal ~0.08s
			value = function(level: number): number
				return math.max(0.08, 1.0 * (0.92 ^ (level - 1)))
			end,
			format = function(v: number): string
				return string.format("%.2fs per pen", v)
			end,
		},
		{
			key = "charm",
			name = "Verkooppraatje",
			info = "Klanten betalen meer",
			basePrice = 140,
			growth = 1.40,
			maxLevel = 40,
			-- verkoop-multiplier: level 1 = 1.0, daarna +12% per level
			value = function(level: number): number
				return 1 + (level - 1) * 0.12
			end,
			format = function(v: number): string
				return string.format("x%.2f prijs", v)
			end,
		},
		{
			key = "legs",
			name = "Snellere schoenen",
			info = "Je loopt harder",
			basePrice = 200,
			growth = 1.55,
			maxLevel = 20,
			value = function(level: number): number
				return math.min(60, 16 + level * 2)
			end,
			format = function(v: number): string
				return string.format("%d snelheid", v)
			end,
		},
	}

	Config.Rebirth = {
		basePrice = 15000,
		growth = 4.2,          -- prijs = basePrice * growth ^ rebirths
		cashMultiplier = 0.75, -- +75% verkoopprijs per rebirth
		penUnlockPerRebirth = 1,
	}

	Config.Production = {
		padCooldownGrace = 0.05,
	}

	Config.Customer = {
		rotateSeconds = 26,    -- hoe lang een klant blijft staan
		minMultiplier = 0.8,
		maxMultiplier = 2.4,
		names = {
			"Karel", "Wendy", "Mo", "Sanne", "Dirk", "Priya", "Bram", "Lisa",
			"Youssef", "Femke", "Ravi", "Joost", "Nina", "Tom", "Ayla",
		},
		lines = {
			"Sell me this pen!",
			"Overtuig me eens...",
			"Ik schrijf nog met potlood, hoezo pen?",
			"Wat maakt jouw pen bijzonder?",
			"Ik heb er al drie. Waarom nog een?",
			"Snel, ik heb een vergadering!",
			"Doe maar een dure.",
		},
	}

	function Config.getPen(index: number)
		local i = math.clamp(index, 1, #Config.Pens)
		return Config.Pens[i]
	end

	function Config.unlockedPenIndex(rebirths: number): number
		return math.clamp(1 + rebirths * Config.Rebirth.penUnlockPerRebirth, 1, #Config.Pens)
	end

	function Config.getUpgrade(key: string)
		for _, up in Config.Upgrades do
			if up.key == key then
				return up
			end
		end
		return nil
	end

	function Config.upgradePrice(up, level: number): number
		return math.floor(up.basePrice * (up.growth ^ (level - 1)) + 0.5)
	end

	function Config.rebirthPrice(rebirths: number): number
		return math.floor(Config.Rebirth.basePrice * (Config.Rebirth.growth ^ rebirths) + 0.5)
	end

	function Config.rebirthMultiplier(rebirths: number): number
		return 1 + rebirths * Config.Rebirth.cashMultiplier
	end

	-- 1234567 -> "1.23M"
	function Config.short(n: number): string
		local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
		local i = 1
		local v = math.abs(n)
		while v >= 1000 and i < #units do
			v /= 1000
			i += 1
		end
		local sign = n < 0 and "-" or ""
		if i == 1 then
			return sign .. tostring(math.floor(v))
		end
		return string.format("%s%.2f%s", sign, v, units[i])
	end

	return Config
end)()

PEN.Net = (function()
	--!strict
	-- Maakt en vindt de RemoteEvents. Server maakt ze, client wacht erop.

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local Net = {}

	local EVENT_NAMES = {
		"StateChanged", -- server -> client: hele spelerstatus
		"Notify",       -- server -> client: toastje (tekst, kleur)
		"BuyUpgrade",   -- client -> server: upgrade-key
		"Rebirth",      -- client -> server
		"CustomerChanged", -- server -> alle clients: huidige klant
	}

	local folder: Folder

	local function ensureFolder(): Folder
		if folder and folder.Parent then
			return folder
		end
		if RunService:IsServer() then
			local existing = ReplicatedStorage:FindFirstChild("PenNet")
			if existing then
				folder = existing :: Folder
			else
				local f = Instance.new("Folder")
				f.Name = "PenNet"
				f.Parent = ReplicatedStorage
				folder = f
			end
			for _, name in EVENT_NAMES do
				if not folder:FindFirstChild(name) then
					local ev = Instance.new("RemoteEvent")
					ev.Name = name
					ev.Parent = folder
				end
			end
		else
			folder = ReplicatedStorage:WaitForChild("PenNet") :: Folder
		end
		return folder
	end

	function Net.event(name: string): RemoteEvent
		local f = ensureFolder()
		if RunService:IsServer() then
			return f:FindFirstChild(name) :: RemoteEvent
		end
		return f:WaitForChild(name) :: RemoteEvent
	end

	function Net.init()
		ensureFolder()
	end

	return Net
end)()

-- ---- startpunt ----
--!strict
-- De hele interface: statusbalk, winkel, klantbalk en meldingen.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = PEN.Config
local Net = PEN.Net

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DARK = Color3.fromRGB(20, 22, 30)
local ACCENT = Color3.fromRGB(90, 190, 255)
local GOLD = Color3.fromRGB(255, 220, 120)
local GREEN = Color3.fromRGB(120, 255, 150)
local PURPLE = Color3.fromRGB(200, 120, 255)

local state: any = nil
local customer: any = nil

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = 0.4
	s.Parent = parent
end

local function text(parent: Instance, name: string, size: UDim2, pos: UDim2, txt: string, textSize: number, color: Color3?): TextLabel
	local tl = Instance.new("TextLabel")
	tl.Name = name
	tl.Size = size
	tl.Position = pos
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = textSize
	tl.TextColor3 = color or Color3.new(1, 1, 1)
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.RichText = true
	tl.Text = txt
	tl.Parent = parent
	return tl
end

local screen = Instance.new("ScreenGui")
screen.Name = "PenUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

-- ---------- statusbalk ----------
local status = Instance.new("Frame")
status.Name = "Status"
status.Size = UDim2.new(0, 290, 0, 132)
status.Position = UDim2.new(0, 16, 0, 16)
status.BackgroundColor3 = DARK
status.BackgroundTransparency = 0.15
status.Parent = screen
corner(status, 14)
stroke(status, ACCENT, 1.5)

local cashLabel = text(status, "Cash", UDim2.new(1, -24, 0, 34), UDim2.new(0, 14, 0, 8), "$0", 28, GOLD)
local bagLabel = text(status, "Bag", UDim2.new(1, -24, 0, 24), UDim2.new(0, 14, 0, 44), "", 18)
local penLabel = text(status, "Pen", UDim2.new(1, -24, 0, 22), UDim2.new(0, 14, 0, 70), "", 16, ACCENT)
local rebirthLabel = text(status, "Rebirth", UDim2.new(1, -24, 0, 22), UDim2.new(0, 14, 0, 94), "", 16, PURPLE)

-- ---------- klantbalk ----------
local customerBar = Instance.new("Frame")
customerBar.Name = "Customer"
customerBar.Size = UDim2.new(0, 420, 0, 58)
customerBar.Position = UDim2.new(0.5, -210, 0, 16)
customerBar.BackgroundColor3 = DARK
customerBar.BackgroundTransparency = 0.15
customerBar.Parent = screen
corner(customerBar, 14)
stroke(customerBar, GREEN, 1.5)

local customerLabel = text(customerBar, "Text", UDim2.new(1, -24, 1, -8), UDim2.new(0, 14, 0, 4),
	"Er komt zo een klant...", 17)
customerLabel.TextYAlignment = Enum.TextYAlignment.Center

-- ---------- winkel ----------
local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Size = UDim2.new(0, 640, 0, 118)
shop.Position = UDim2.new(0.5, -320, 1, -134)
shop.BackgroundTransparency = 1
shop.Parent = screen

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = shop

local buttons: { [string]: { button: TextButton, title: TextLabel, sub: TextLabel, price: TextLabel } } = {}

for i, up in Config.Upgrades do
	local btn = Instance.new("TextButton")
	btn.Name = up.key
	btn.LayoutOrder = i
	btn.Size = UDim2.new(0, 150, 1, 0)
	btn.BackgroundColor3 = DARK
	btn.BackgroundTransparency = 0.15
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.Parent = shop
	corner(btn, 14)
	stroke(btn, GOLD, 1.5)

	local title = text(btn, "Title", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 8), up.name, 16, GOLD)
	local sub = text(btn, "Sub", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 32), up.info, 13)
	sub.TextWrapped = true
	sub.Font = Enum.Font.Gotham
	local price = text(btn, "Price", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 1, -32), "", 17, GREEN)

	btn.Activated:Connect(function()
		Net.event("BuyUpgrade"):FireServer(up.key)
	end)

	buttons[up.key] = { button = btn, title = title, sub = sub, price = price }
end

local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Name = "Rebirth"
rebirthBtn.Size = UDim2.new(0, 220, 0, 48)
rebirthBtn.Position = UDim2.new(1, -236, 1, -190)
rebirthBtn.BackgroundColor3 = DARK
rebirthBtn.BackgroundTransparency = 0.15
rebirthBtn.Font = Enum.Font.GothamBold
rebirthBtn.TextSize = 17
rebirthBtn.TextColor3 = PURPLE
rebirthBtn.Text = "Rebirth"
rebirthBtn.Parent = screen
corner(rebirthBtn, 14)
stroke(rebirthBtn, PURPLE, 1.5)
rebirthBtn.Activated:Connect(function()
	Net.event("Rebirth"):FireServer()
end)

-- ---------- meldingen ----------
local toasts = Instance.new("Frame")
toasts.Name = "Toasts"
toasts.Size = UDim2.new(0, 340, 0, 240)
toasts.Position = UDim2.new(1, -356, 0, 16)
toasts.BackgroundTransparency = 1
toasts.Parent = screen

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toasts

local toastOrder = 0

local function showToast(message: string, color: Color3)
	toastOrder += 1
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 44)
	frame.LayoutOrder = toastOrder
	frame.BackgroundColor3 = DARK
	frame.BackgroundTransparency = 0.1
	frame.Parent = toasts
	corner(frame, 12)
	stroke(frame, color, 1.5)

	local tl = text(frame, "Text", UDim2.new(1, -20, 1, -8), UDim2.new(0, 10, 0, 4), message, 15, color)
	tl.Font = Enum.Font.GothamMedium
	tl.TextWrapped = true
	tl.TextYAlignment = Enum.TextYAlignment.Center

	task.delay(3.2, function()
		local tween = TweenService:Create(frame, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		TweenService:Create(tl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		tween:Play()
		tween.Completed:Wait()
		frame:Destroy()
	end)
end

-- ---------- bijwerken ----------
local function render()
	if not state then
		return
	end
	cashLabel.Text = "$" .. Config.short(state.cash)

	local full = state.pens >= state.capacity
	bagLabel.Text = string.format(
		'Tas: <font color="%s">%d/%d</font>  ->  $%s',
		full and "rgb(255,150,150)" or "rgb(255,255,255)",
		state.pens, state.capacity, Config.short(state.bagValue)
	)
	penLabel.Text = string.format("Pen: %s ($%s)  x%.2f", state.penName, Config.short(state.penValue), state.sellMultiplier)
	rebirthLabel.Text = string.format("Rebirths: %d  |  verkocht: %s", state.rebirths, Config.short(state.totalSold))

	for _, info in state.upgrades do
		local ui = buttons[info.key]
		if ui then
			ui.title.Text = string.format("%s <font color='rgb(160,160,175)'>lv%d</font>", info.name, info.level)
			ui.sub.Text = info.maxed and info.display or string.format("%s  ->  %s", info.display, info.nextDisplay)
			if info.maxed then
				ui.price.Text = "MAX"
				ui.price.TextColor3 = GOLD
			else
				ui.price.Text = "$" .. Config.short(info.price)
				ui.price.TextColor3 = state.cash >= info.price and GREEN or Color3.fromRGB(255, 150, 150)
			end
		end
	end

	if state.rebirths >= #Config.Pens - 1 then
		rebirthBtn.Text = "Alle pennen vrijgespeeld"
	else
		rebirthBtn.Text = string.format("Rebirth $%s  ->  %s", Config.short(state.rebirthPrice), state.nextPenName)
	end
	rebirthBtn.BackgroundColor3 = state.canRebirth and Color3.fromRGB(56, 30, 78) or DARK
end

local function renderCustomer()
	if not customer then
		customerLabel.Text = "Er komt zo een klant..."
		return
	end
	local color = customer.multiplier >= 1.6 and "rgb(120,255,150)"
		or (customer.multiplier >= 1.1 and "rgb(255,220,120)" or "rgb(255,150,150)")
	customerLabel.Text = string.format(
		'<b>%s</b>: "%s"   <font color="%s">betaalt x%.2f</font>',
		customer.name, customer.line, color, customer.multiplier
	)
end

Net.event("StateChanged").OnClientEvent:Connect(function(newState)
	state = newState
	render()
end)

Net.event("CustomerChanged").OnClientEvent:Connect(function(newCustomer)
	customer = newCustomer
	renderCustomer()
	render()
end)

Net.event("Notify").OnClientEvent:Connect(function(message, color)
	showToast(message, color or Color3.new(1, 1, 1))
end)

renderCustomer()
