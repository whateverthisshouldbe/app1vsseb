-- Sell Me This Pen - CLIENT. Plak dit in een LocalScript in StarterPlayer > StarterPlayerScripts.
-- AUTOMATISCH GEGENEREERD door tools/bundle.py - niet met de hand aanpassen.
-- Pas de bestanden in src/ aan en draai het script opnieuw.

local PEN = {}

PEN.Config = (function()
	--!strict
	-- Alle balans en inhoud van "Sell Me This Pen" staat hier.
	-- Wil je de game sneller, duurder of langer maken? Pas alleen dit bestand aan
	-- en draai daarna `python3 tools/bundle.py`.

	local Config = {}

	Config.GameName = "Sell Me This Pen"
	Config.DataStoreKey = "PenTycoon_v2" -- naam veranderen = iedereen begint opnieuw

	-- ---------------------------------------------------------------- stations --
	-- Elke rebirth opent een nieuwe zaak. De oude blijft gewoon open en blijft
	-- passief geld opleveren, ook als je offline bent.
	Config.Stations = {
		{
			key = "kraam",
			name = "Pennenkraam",
			tagline = "Eerste pen, eerste klant",
			unlockRebirth = 0,
			pen = { name = "Balpen", value = 4, color = Color3.fromRGB(35, 35, 40) },
			autoPerSecond = 0.30,
			color = Color3.fromRGB(120, 160, 90),
		},
		{
			key = "winkel",
			name = "Pennenwinkel",
			tagline = "Een echte toonbank",
			unlockRebirth = 1,
			pen = { name = "Gelpen", value = 18, color = Color3.fromRGB(30, 110, 220) },
			autoPerSecond = 0.34,
			color = Color3.fromRGB(70, 130, 200),
		},
		{
			key = "fabriek",
			name = "Pennenfabriek",
			tagline = "Lopende banden vol inkt",
			unlockRebirth = 2,
			pen = { name = "Marker", value = 75, color = Color3.fromRGB(230, 90, 40) },
			autoPerSecond = 0.38,
			color = Color3.fromRGB(190, 110, 60),
		},
		{
			key = "groothandel",
			name = "Groothandel",
			tagline = "Pallets in plaats van doosjes",
			unlockRebirth = 3,
			pen = { name = "Vulpen", value = 290, color = Color3.fromRGB(150, 120, 60) },
			autoPerSecond = 0.42,
			color = Color3.fromRGB(150, 150, 160),
		},
		{
			key = "toren",
			name = "Pen Street Toren",
			tagline = "Handelaren in pak, telefoons roodgloeiend",
			unlockRebirth = 4,
			pen = { name = "Zilveren pen", value = 1100, color = Color3.fromRGB(190, 195, 205) },
			autoPerSecond = 0.46,
			color = Color3.fromRGB(90, 110, 150),
		},
		{
			key = "penthouse",
			name = "Penthouse",
			tagline = "Onderhandelen met uitzicht",
			unlockRebirth = 5,
			pen = { name = "Gouden pen", value = 4200, color = Color3.fromRGB(235, 190, 60) },
			autoPerSecond = 0.50,
			color = Color3.fromRGB(210, 170, 70),
		},
		{
			key = "jacht",
			name = "Penjacht",
			tagline = "De deal sluiten op open zee",
			unlockRebirth = 6,
			pen = { name = "Diamanten pen", value = 16000, color = Color3.fromRGB(120, 230, 235) },
			autoPerSecond = 0.55,
			color = Color3.fromRGB(80, 200, 220),
		},
		{
			key = "orbit",
			name = "Pen Orbit",
			tagline = "Pennen die ook in nul zwaartekracht schrijven",
			unlockRebirth = 7,
			pen = { name = "Sterrenpen", value = 62000, color = Color3.fromRGB(180, 110, 240) },
			autoPerSecond = 0.60,
			color = Color3.fromRGB(150, 100, 230),
		},
	}

	-- ---------------------------------------------------------------- upgrades --
	-- prijs = basePrice * (growth ^ (level - 1))
	Config.Upgrades = {
		{
			key = "capacity",
			name = "Grotere tas",
			info = "Meer pennen dragen",
			basePrice = 45,
			growth = 1.24,
			maxLevel = 50,
			value = function(level: number): number
				return 6 + level * 6
			end,
			format = function(v: number): string
				return string.format("%d pennen", math.floor(v))
			end,
		},
		{
			key = "speed",
			name = "Snellere handen",
			info = "Sneller pennen maken",
			basePrice = 70,
			growth = 1.27,
			maxLevel = 50,
			value = function(level: number): number
				return math.max(0.06, 0.9 * (0.9 ^ (level - 1)))
			end,
			format = function(v: number): string
				return string.format("%.2fs per pen", v)
			end,
		},
		{
			key = "charm",
			name = "Verkooppraatje",
			info = "Klanten betalen meer",
			basePrice = 110,
			growth = 1.33,
			maxLevel = 50,
			value = function(level: number): number
				return 1 + (level - 1) * 0.15
			end,
			format = function(v: number): string
				return string.format("x%.2f prijs", v)
			end,
		},
		{
			key = "auto",
			name = "Personeel",
			info = "Je zaken verdienen passief meer",
			basePrice = 150,
			growth = 1.36,
			maxLevel = 50,
			value = function(level: number): number
				return 1 + (level - 1) * 0.2
			end,
			format = function(v: number): string
				return string.format("x%.2f passief", v)
			end,
		},
		{
			key = "legs",
			name = "Snellere schoenen",
			info = "Je loopt harder",
			basePrice = 180,
			growth = 1.5,
			maxLevel = 25,
			value = function(level: number): number
				return math.min(70, 16 + level * 2)
			end,
			format = function(v: number): string
				return string.format("%d snelheid", math.floor(v))
			end,
		},
	}

	-- ---------------------------------------------------------------- rebirth ---
	Config.Rebirth = {
		basePrice = 2500,
		growth = 20,           -- prijs = basePrice * growth ^ rebirths
		cashMultiplier = 0.9,  -- +90% op alles per rebirth
	}

	-- ------------------------------------------------------------------ pitch ---
	-- De "sell me this pen"-minigame. Elke klant heeft een type; elk argument
	-- werkt goed bij bepaalde types. Raak je het goed, dan betaalt de klant fors meer.
	Config.Pitch = {
		seconds = 7,
		optionCount = 3,
		perfectMultiplier = 2.0,
		okMultiplier = 1.15,
		missMultiplier = 0.7,
		timeoutMultiplier = 0.6,
		streakStep = 0.1,   -- elke goede pitch op rij: +0.1
		streakMax = 1.0,
	}

	Config.CustomerTypes = {
		{ key = "haast",    label = "heeft haast",        color = Color3.fromRGB(255, 160, 90) },
		{ key = "luxe",     label = "houdt van luxe",     color = Color3.fromRGB(235, 190, 60) },
		{ key = "zuinig",   label = "let op de prijs",    color = Color3.fromRGB(120, 255, 150) },
		{ key = "sceptisch",label = "gelooft er niets van",color = Color3.fromRGB(255, 130, 130) },
		{ key = "nerd",     label = "wil de details",     color = Color3.fromRGB(130, 190, 255) },
		{ key = "cadeau",   label = "zoekt een cadeau",   color = Color3.fromRGB(215, 140, 255) },
	}

	-- `good` = perfecte match, `ok` = half raak, de rest is mis.
	Config.PitchArguments = {
		{ text = "Eén handtekening en je bent klaar.",            good = { "haast" },      ok = { "zuinig" } },
		{ text = "Handgeslepen punt, schrijft als boter.",        good = { "luxe" },       ok = { "nerd" } },
		{ text = "Twee voor de prijs van één, vandaag.",          good = { "zuinig" },     ok = { "cadeau" } },
		{ text = "Probeer hem zelf, ik wacht wel.",               good = { "sceptisch" },  ok = { "nerd" } },
		{ text = "Inktdruk van 0.7 bar, lekt nooit.",             good = { "nerd" },       ok = { "sceptisch" } },
		{ text = "Komt in een doosje met lint eromheen.",         good = { "cadeau" },     ok = { "luxe" } },
		{ text = "Iedereen op kantoor heeft er al een.",          good = { "cadeau" },     ok = { "haast" } },
		{ text = "Levenslange garantie, zwart op wit.",           good = { "sceptisch" },  ok = { "zuinig" } },
		{ text = "Schrijft onder water en op de kop.",            good = { "nerd" },       ok = { "luxe" } },
		{ text = "Je hebt hem nu nodig, geen tijd te verliezen.", good = { "haast" },      ok = { "sceptisch" } },
		{ text = "Massief afgewerkt, voelt meteen duur.",         good = { "luxe" },       ok = { "cadeau" } },
		{ text = "Kost minder dan je koffie van vanochtend.",     good = { "zuinig" },     ok = { "haast" } },
	}

	Config.Customer = {
		rotateSeconds = 30,
		names = {
			"Karel", "Wendy", "Mo", "Sanne", "Dirk", "Priya", "Bram", "Lisa",
			"Youssef", "Femke", "Ravi", "Joost", "Nina", "Tom", "Ayla", "Sem",
		},
		lines = {
			"Sell me this pen!",
			"Overtuig me eens...",
			"Waarom jouw pen?",
			"Ik heb er al drie.",
			"Snel, ik moet door.",
			"Doe maar een dure.",
			"Wat kan hij wat andere niet kunnen?",
		},
	}

	-- ------------------------------------------------------------------ idle ----
	Config.Idle = {
		offlineCapHours = 2,     -- zonder VIP
		offlineCapHoursVip = 8,  -- met de VIP-gamepass
		payoutSeconds = 5,       -- hoe vaak passief geld binnenkomt
	}

	-- ------------------------------------------------------------------- pets ---
	-- Mascottes die je koopt bij de pennenbak. Boost telt op bij je upgrades.
	Config.Pets = {
		{ key = "clip",   name = "Clippie",      price = 1500,    produce = 0.10, value = 0.05, color = Color3.fromRGB(200, 205, 215) },
		{ key = "inkt",   name = "Inktdruppel",  price = 12000,   produce = 0.20, value = 0.10, color = Color3.fromRGB(70, 120, 235) },
		{ key = "stift",  name = "Stiftje",      price = 90000,   produce = 0.35, value = 0.18, color = Color3.fromRGB(240, 110, 60) },
		{ key = "goud",   name = "Gouden Punt",  price = 750000,  produce = 0.55, value = 0.30, color = Color3.fromRGB(240, 195, 70) },
		{ key = "ster",   name = "Sterrenstift", price = 6000000, produce = 0.85, value = 0.50, color = Color3.fromRGB(185, 115, 245) },
	}

	-- ------------------------------------------------------------ dagbeloning ---
	Config.Daily = {
		cooldownSeconds = 20 * 60 * 60, -- na 20 uur mag je weer
		resetSeconds = 48 * 60 * 60,    -- langer weg = streak terug naar 1
		baseReward = 750,
		streakBonus = 0.5,              -- +50% per dag op rij
		maxStreak = 7,
	}

	-- ------------------------------------------------------------------ codes ---
	-- Deel deze codes zelf uit. Nieuwe code? Regel erbij zetten en opnieuw bundelen.
	Config.Codes = {
		{ code = "PENSTART",  cash = 500,   pet = nil },
		{ code = "SELLMETHIS", cash = 2500,  pet = nil },
		{ code = "CLIPPIE",   cash = 0,     pet = "clip" },
		{ code = "INKT",      cash = 10000, pet = nil },
	}

	-- ------------------------------------------------------------- gamepasses ---
	-- Zet hier de ID's neer die je op create.roblox.com aanmaakt. 0 = uitgeschakeld.
	Config.Gamepasses = {
		doubleCash = { id = 0, name = "x2 Geld",   info = "Alles wat je verdient telt dubbel" },
		vipBag     = { id = 0, name = "VIP-tas",   info = "Dubbele tas + 8 uur offline verdienen" },
		autoSell   = { id = 0, name = "Auto-verkoop", info = "Volle tas verkoopt zichzelf aan de balie" },
	}

	Config.Perks = {
		doubleCashMultiplier = 2,
		vipBagMultiplier = 2,
	}

	-- ------------------------------------------------------------------ hulp ----
	function Config.stationForRebirths(rebirths: number)
		local best = Config.Stations[1]
		for _, station in Config.Stations do
			if rebirths >= station.unlockRebirth then
				best = station
			end
		end
		return best
	end

	function Config.unlockedStationCount(rebirths: number): number
		local count = 0
		for _, station in Config.Stations do
			if rebirths >= station.unlockRebirth then
				count += 1
			end
		end
		return math.max(1, count)
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

	function Config.getPet(key: string?)
		if not key then
			return nil
		end
		for _, pet in Config.Pets do
			if pet.key == key then
				return pet
			end
		end
		return nil
	end

	function Config.getCustomerType(key: string)
		for _, t in Config.CustomerTypes do
			if t.key == key then
				return t
			end
		end
		return Config.CustomerTypes[1]
	end

	-- 1234567 -> "1.23M"
	function Config.short(n: number): string
		local units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
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
		-- server -> client
		"StateChanged",    -- hele spelerstatus
		"Notify",          -- toastje (tekst, kleur)
		"CustomerChanged", -- klant bij een station
		"PitchStart",      -- start van de sell-me-this-pen minigame
		"PitchEnd",        -- uitslag van de pitch
		"OfflineEarnings", -- wat je zaken verdienden terwijl je weg was
		"Leaderboard",     -- top 10
		-- client -> server
		"BuyUpgrade",
		"Rebirth",
		"PitchAnswer",
		"BuyPet",
		"EquipPet",
		"ClaimDaily",
		"RedeemCode",
		"PromptPass",
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
-- De hele interface: statusbalk, winkel, pitch-minigame, panelen en meldingen.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = PEN.Config
local Net = PEN.Net

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DARK = Color3.fromRGB(18, 20, 28)
local PANEL = Color3.fromRGB(26, 29, 40)
local WHITE = Color3.new(1, 1, 1)
local ACCENT = Color3.fromRGB(90, 190, 255)
local GOLD = Color3.fromRGB(255, 214, 110)
local GREEN = Color3.fromRGB(120, 255, 150)
local RED = Color3.fromRGB(255, 140, 140)
local PURPLE = Color3.fromRGB(200, 120, 255)
local TEAL = Color3.fromRGB(120, 230, 220)

local state: any = nil

-- ------------------------------------------------------------- bouwstenen --

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
	return s
end

local function text(parent: Instance, name: string, size: UDim2, pos: UDim2, txt: string, textSize: number, color: Color3?): TextLabel
	local tl = Instance.new("TextLabel")
	tl.Name = name
	tl.Size = size
	tl.Position = pos
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = textSize
	tl.TextColor3 = color or WHITE
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.RichText = true
	tl.Text = txt
	tl.Parent = parent
	return tl
end

local function button(parent: Instance, name: string, size: UDim2, pos: UDim2, txt: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = PANEL
	b.AutoButtonColor = true
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextColor3 = color
	b.Text = txt
	b.Parent = parent
	corner(b, 12)
	stroke(b, color, 1.5)
	return b
end

local screen = Instance.new("ScreenGui")
screen.Name = "PenUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

-- ------------------------------------------------------------- statusbalk --

local status = Instance.new("Frame")
status.Name = "Status"
status.Size = UDim2.new(0, 300, 0, 150)
status.Position = UDim2.new(0, 16, 0, 16)
status.BackgroundColor3 = DARK
status.BackgroundTransparency = 0.12
status.Parent = screen
corner(status, 14)
stroke(status, ACCENT, 1.5)

local cashLabel = text(status, "Cash", UDim2.new(1, -24, 0, 34), UDim2.new(0, 14, 0, 8), "$0", 28, GOLD)
local bagLabel = text(status, "Bag", UDim2.new(1, -24, 0, 22), UDim2.new(0, 14, 0, 44), "", 17)
local penLabel = text(status, "Pen", UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 0, 68), "", 15, ACCENT)
local passiveLabel = text(status, "Passive", UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 0, 90), "", 15, TEAL)
local metaLabel = text(status, "Meta", UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 0, 112), "", 15, PURPLE)

-- ------------------------------------------------------------ upgraderij ---

local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Size = UDim2.new(0, 780, 0, 112)
shop.Position = UDim2.new(0.5, -390, 1, -126)
shop.BackgroundTransparency = 1
shop.Parent = screen

local shopLayout = Instance.new("UIListLayout")
shopLayout.FillDirection = Enum.FillDirection.Horizontal
shopLayout.Padding = UDim.new(0, 8)
shopLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shop

local upgradeButtons: { [string]: { title: TextLabel, sub: TextLabel, price: TextLabel } } = {}

for i, up in Config.Upgrades do
	local btn = Instance.new("TextButton")
	btn.Name = up.key
	btn.LayoutOrder = i
	btn.Size = UDim2.new(0, 148, 1, 0)
	btn.BackgroundColor3 = DARK
	btn.BackgroundTransparency = 0.12
	btn.Text = ""
	btn.Parent = shop
	corner(btn, 14)
	stroke(btn, GOLD, 1.5)

	local title = text(btn, "Title", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 8), up.name, 15, GOLD)
	local sub = text(btn, "Sub", UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 0, 30), up.info, 13)
	sub.Font = Enum.Font.Gotham
	sub.TextWrapped = true
	local price = text(btn, "Price", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 1, -30), "", 16, GREEN)

	btn.Activated:Connect(function()
		Net.event("BuyUpgrade"):FireServer(up.key)
	end)
	upgradeButtons[up.key] = { title = title, sub = sub, price = price }
end

-- ------------------------------------------------------------- knoppenrij --

local sideBar = Instance.new("Frame")
sideBar.Name = "SideBar"
sideBar.Size = UDim2.new(0, 190, 0, 260)
sideBar.Position = UDim2.new(1, -206, 1, -320)
sideBar.BackgroundTransparency = 1
sideBar.Parent = screen

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 8)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = sideBar

local rebirthBtn = button(sideBar, "Rebirth", UDim2.new(1, 0, 0, 62), UDim2.new(), "Rebirth", PURPLE)
rebirthBtn.LayoutOrder = 1
rebirthBtn.TextWrapped = true
rebirthBtn.RichText = true
rebirthBtn.TextSize = 14
local petBtn = button(sideBar, "Pets", UDim2.new(1, 0, 0, 40), UDim2.new(), "Mascottes", TEAL)
petBtn.LayoutOrder = 2
local dailyBtn = button(sideBar, "Daily", UDim2.new(1, 0, 0, 40), UDim2.new(), "Dagbeloning", GREEN)
dailyBtn.LayoutOrder = 3
local codeBtn = button(sideBar, "Codes", UDim2.new(1, 0, 0, 40), UDim2.new(), "Codes", GOLD)
codeBtn.LayoutOrder = 4
local passBtn = button(sideBar, "Passes", UDim2.new(1, 0, 0, 40), UDim2.new(), "Extra's", ACCENT)
passBtn.LayoutOrder = 5

rebirthBtn.Activated:Connect(function()
	Net.event("Rebirth"):FireServer()
end)
dailyBtn.Activated:Connect(function()
	Net.event("ClaimDaily"):FireServer()
end)

-- ---------------------------------------------------------------- panelen --

local function makePanel(title: string, height: number): (Frame, Frame)
	local holder = Instance.new("Frame")
	holder.Name = title
	holder.Size = UDim2.new(0, 460, 0, height)
	holder.Position = UDim2.new(0.5, -230, 0.5, -height / 2)
	holder.BackgroundColor3 = DARK
	holder.BackgroundTransparency = 0.05
	holder.Visible = false
	holder.ZIndex = 5
	holder.Parent = screen
	corner(holder, 16)
	stroke(holder, ACCENT, 1.5)

	local header = text(holder, "Header", UDim2.new(1, -60, 0, 34), UDim2.new(0, 16, 0, 10), title, 22, WHITE)
	header.ZIndex = 6

	local close = button(holder, "Close", UDim2.new(0, 34, 0, 34), UDim2.new(1, -46, 0, 10), "X", RED)
	close.ZIndex = 6
	close.Activated:Connect(function()
		holder.Visible = false
	end)

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -24, 1, -60)
	body.Position = UDim2.new(0, 12, 0, 50)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 6
	body.CanvasSize = UDim2.new()
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ZIndex = 6
	body.Parent = holder

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	return holder, body
end

local petPanel, petBody = makePanel("Mascottes", 420)
local codePanel, codeBody = makePanel("Codes", 260)
local passPanel, passBody = makePanel("Extra's", 340)

local function toggle(panel: Frame)
	local wasVisible = panel.Visible
	petPanel.Visible = false
	codePanel.Visible = false
	passPanel.Visible = false
	panel.Visible = not wasVisible
end

petBtn.Activated:Connect(function()
	toggle(petPanel)
end)
codeBtn.Activated:Connect(function()
	toggle(codePanel)
end)
passBtn.Activated:Connect(function()
	toggle(passPanel)
end)

-- codes-paneel
local codeBox = Instance.new("TextBox")
codeBox.Name = "Input"
codeBox.Size = UDim2.new(1, -12, 0, 44)
codeBox.BackgroundColor3 = PANEL
codeBox.Font = Enum.Font.GothamBold
codeBox.TextSize = 18
codeBox.TextColor3 = WHITE
codeBox.PlaceholderText = "typ hier je code"
codeBox.Text = ""
codeBox.ClearTextOnFocus = false
codeBox.ZIndex = 6
codeBox.LayoutOrder = 1
codeBox.Parent = codeBody
corner(codeBox, 12)
stroke(codeBox, GOLD, 1.5)

local codeSubmit = button(codeBody, "Submit", UDim2.new(1, -12, 0, 40), UDim2.new(), "Inwisselen", GREEN)
codeSubmit.LayoutOrder = 2
codeSubmit.ZIndex = 6
local codeHint = text(codeBody, "Hint", UDim2.new(1, -12, 0, 60), UDim2.new(),
	"Codes deel je zelf uit, bijvoorbeeld in de beschrijving van de game of op je socials.", 14, Color3.fromRGB(170, 175, 190))
codeHint.LayoutOrder = 3
codeHint.TextWrapped = true
codeHint.ZIndex = 6

local function submitCode()
	local value = codeBox.Text
	if value ~= "" then
		Net.event("RedeemCode"):FireServer(value)
		codeBox.Text = ""
	end
end
codeSubmit.Activated:Connect(submitCode)
codeBox.FocusLost:Connect(function(enter)
	if enter then
		submitCode()
	end
end)

-- ---------------------------------------------------------------- toasts ---

local toasts = Instance.new("Frame")
toasts.Name = "Toasts"
toasts.Size = UDim2.new(0, 330, 0, 300)
toasts.Position = UDim2.new(1, -346, 0, 16)
toasts.BackgroundTransparency = 1
toasts.Parent = screen

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toasts

local toastOrder = 0

local function showToast(message: string, color: Color3)
	toastOrder += 1
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 46)
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

	task.delay(3.4, function()
		TweenService:Create(tl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		local tween = TweenService:Create(frame, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		frame:Destroy()
	end)
end

-- ----------------------------------------------------------------- pitch ---

local pitchFrame = Instance.new("Frame")
pitchFrame.Name = "Pitch"
pitchFrame.Size = UDim2.new(0, 620, 0, 300)
pitchFrame.Position = UDim2.new(0.5, -310, 0.5, -170)
pitchFrame.BackgroundColor3 = DARK
pitchFrame.BackgroundTransparency = 0.05
pitchFrame.Visible = false
pitchFrame.ZIndex = 8
pitchFrame.Parent = screen
corner(pitchFrame, 16)
local pitchStroke = stroke(pitchFrame, GREEN, 2)

local pitchWho = text(pitchFrame, "Who", UDim2.new(1, -32, 0, 26), UDim2.new(0, 16, 0, 12), "", 20, GOLD)
pitchWho.ZIndex = 9
local pitchLine = text(pitchFrame, "Line", UDim2.new(1, -32, 0, 30), UDim2.new(0, 16, 0, 40), "", 22, WHITE)
pitchLine.ZIndex = 9
local pitchInfo = text(pitchFrame, "Info", UDim2.new(1, -32, 0, 22), UDim2.new(0, 16, 0, 72), "", 15, TEAL)
pitchInfo.ZIndex = 9

local timerBack = Instance.new("Frame")
timerBack.Size = UDim2.new(1, -32, 0, 8)
timerBack.Position = UDim2.new(0, 16, 0, 98)
timerBack.BackgroundColor3 = Color3.fromRGB(45, 50, 64)
timerBack.BorderSizePixel = 0
timerBack.ZIndex = 9
timerBack.Parent = pitchFrame
corner(timerBack, 4)

local timerFill = Instance.new("Frame")
timerFill.Size = UDim2.new(1, 0, 1, 0)
timerFill.BackgroundColor3 = GREEN
timerFill.BorderSizePixel = 0
timerFill.ZIndex = 10
timerFill.Parent = timerBack
corner(timerFill, 4)

local optionHolder = Instance.new("Frame")
optionHolder.Size = UDim2.new(1, -32, 0, 160)
optionHolder.Position = UDim2.new(0, 16, 0, 118)
optionHolder.BackgroundTransparency = 1
optionHolder.ZIndex = 9
optionHolder.Parent = pitchFrame

local optionLayout = Instance.new("UIListLayout")
optionLayout.Padding = UDim.new(0, 8)
optionLayout.SortOrder = Enum.SortOrder.LayoutOrder
optionLayout.Parent = optionHolder

local activePitchId: number? = nil
local pitchDeadline = 0
local pitchSeconds = 1

local function clearOptions()
	for _, child in optionHolder:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function closePitch()
	activePitchId = nil
	pitchFrame.Visible = false
	clearOptions()
end

Net.event("PitchStart").OnClientEvent:Connect(function(info)
	activePitchId = info.id
	pitchSeconds = info.seconds
	pitchDeadline = os.clock() + info.seconds
	pitchFrame.Visible = true
	pitchWho.Text = string.format("%s wil overtuigd worden", info.customerName)
	pitchLine.Text = string.format('"%s"', info.line)
	pitchInfo.Text = string.format("%s  ·  betaalt x%.2f  ·  %d pennen in je tas",
		info.typeLabel, info.customerMultiplier, info.pens)
	pitchInfo.TextColor3 = info.typeColor or TEAL
	pitchStroke.Color = info.typeColor or GREEN

	clearOptions()
	for index, option in info.options do
		local btn = button(optionHolder, "Option" .. index, UDim2.new(1, 0, 0, 44), UDim2.new(), option, WHITE)
		btn.LayoutOrder = index
		btn.TextWrapped = true
		btn.ZIndex = 10
		btn.Activated:Connect(function()
			if activePitchId then
				Net.event("PitchAnswer"):FireServer(activePitchId, index)
				closePitch()
			end
		end)
	end
end)

Net.event("PitchEnd").OnClientEvent:Connect(function(result)
	closePitch()
	if not result.ok then
		showToast(result.text, RED)
		return
	end
	local color = result.quality == "perfect" and GREEN
		or (result.quality == "miss" or result.quality == "timeout") and RED
		or GOLD
	showToast(string.format("%s  +$%s (x%.2f)", result.text, Config.short(result.earned), result.multiplier), color)
	if result.quality == "perfect" and result.streak > 1 then
		showToast(string.format("%d perfecte pitches op rij!", result.streak), GREEN)
	end
end)

-- ------------------------------------------------------- offline-opbrengst -

Net.event("OfflineEarnings").OnClientEvent:Connect(function(info)
	local panel, body = makePanel("Terwijl je weg was", 240)
	local hours = math.floor(info.seconds / 3600)
	local minutes = math.floor((info.seconds % 3600) / 60)
	local line = text(body, "Line", UDim2.new(1, -12, 0, 90), UDim2.new(),
		string.format("Je zaken draaiden %du %dm door.\n\n<font color=\"rgb(120,255,150)\">+$%s</font>",
			hours, minutes, Config.short(info.earned)), 20, WHITE)
	line.TextWrapped = true
	line.LayoutOrder = 1
	line.ZIndex = 6
	if info.capped then
		local capLine = text(body, "Cap", UDim2.new(1, -12, 0, 60), UDim2.new(),
			string.format("Offline verdienen telt tot %d uur.", info.capHours), 15, GOLD)
		capLine.TextWrapped = true
		capLine.LayoutOrder = 2
		capLine.ZIndex = 6
	end
	panel.Visible = true
end)

-- ---------------------------------------------------------------- tekenen --

local function renderPets()
	if not state then
		return
	end
	for _, child in petBody:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for index, pet in state.pets do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 62)
		row.LayoutOrder = index
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = petBody
		corner(row, 12)
		stroke(row, pet.equipped and GREEN or TEAL, 1.5)

		local title = text(row, "Title", UDim2.new(1, -140, 0, 22), UDim2.new(0, 12, 0, 8), pet.name, 17, TEAL)
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -140, 0, 20), UDim2.new(0, 12, 0, 32),
			string.format("+%d%% maken  ·  +%d%% waarde", math.floor(pet.produce * 100), math.floor(pet.value * 100)),
			14, Color3.fromRGB(180, 185, 200))
		sub.Font = Enum.Font.Gotham
		sub.ZIndex = 7

		local label = pet.equipped and "Gedragen" or (pet.owned and "Dragen" or ("$" .. Config.short(pet.price)))
		local color = pet.equipped and GREEN or (pet.owned and GOLD or (state.cash >= pet.price and GREEN or RED))
		local act = button(row, "Act", UDim2.new(0, 116, 0, 38), UDim2.new(1, -128, 0, 12), label, color)
		act.ZIndex = 7
		act.Activated:Connect(function()
			if pet.equipped then
				Net.event("EquipPet"):FireServer("")
			elseif pet.owned then
				Net.event("EquipPet"):FireServer(pet.key)
			else
				Net.event("BuyPet"):FireServer(pet.key)
			end
		end)
	end
end

local function renderPasses()
	if not state then
		return
	end
	for _, child in passBody:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for index, pass in state.passes do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 68)
		row.LayoutOrder = index
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = passBody
		corner(row, 12)
		stroke(row, ACCENT, 1.5)

		local title = text(row, "Title", UDim2.new(1, -140, 0, 22), UDim2.new(0, 12, 0, 10), pass.name, 17, ACCENT)
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -140, 0, 28), UDim2.new(0, 12, 0, 32), pass.info, 14,
			Color3.fromRGB(180, 185, 200))
		sub.Font = Enum.Font.Gotham
		sub.TextWrapped = true
		sub.ZIndex = 7

		local label = pass.owned and "In bezit" or (pass.configured and "Kopen" or "Nog niet ingesteld")
		local color = pass.owned and GREEN or (pass.configured and GOLD or Color3.fromRGB(150, 155, 170))
		local act = button(row, "Act", UDim2.new(0, 116, 0, 40), UDim2.new(1, -128, 0, 14), label, color)
		act.ZIndex = 7
		act.TextWrapped = true
		act.Activated:Connect(function()
			if not pass.owned and pass.configured then
				Net.event("PromptPass"):FireServer(pass.key)
			end
		end)
	end
end

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
	penLabel.Text = string.format("Pen: $%s per stuk  ·  x%.2f", Config.short(state.penValue), state.multiplier)
	passiveLabel.Text = string.format("Passief: $%s per minuut", Config.short(state.passivePerSecond * 60))
	metaLabel.Text = string.format("Rebirths: %d  ·  streak: %d  ·  verkocht: %s",
		state.rebirths, state.pitchStreak, Config.short(state.totalSold))

	for _, info in state.upgrades do
		local ui = upgradeButtons[info.key]
		if ui then
			ui.title.Text = string.format("%s <font color='rgb(160,160,175)'>lv%d</font>", info.name, info.level)
			ui.sub.Text = info.maxed and info.display or string.format("%s  ->  %s", info.display, info.nextDisplay)
			if info.maxed then
				ui.price.Text = "MAX"
				ui.price.TextColor3 = GOLD
			else
				ui.price.Text = "$" .. Config.short(info.price)
				ui.price.TextColor3 = state.cash >= info.price and GREEN or RED
			end
		end
	end

	if state.nextStationName == "" then
		rebirthBtn.Text = "Alle zaken geopend"
	else
		rebirthBtn.Text = string.format("Rebirth $%s\nopent %s\n<font color='rgb(160,160,175)'>geld + upgrades op 0</font>",
			Config.short(state.rebirthPrice), state.nextStationName)
	end
	rebirthBtn.BackgroundColor3 = state.canRebirth and Color3.fromRGB(56, 30, 78) or PANEL

	if state.daily.ready then
		dailyBtn.Text = string.format("Dagbeloning: $%s", Config.short(state.daily.reward))
		dailyBtn.TextColor3 = GREEN
	else
		local hours = math.floor(state.daily.secondsLeft / 3600)
		local minutes = math.floor((state.daily.secondsLeft % 3600) / 60)
		dailyBtn.Text = string.format("Dagbeloning over %du %dm", hours, minutes)
		dailyBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
	end

	if petPanel.Visible then
		renderPets()
	end
	if passPanel.Visible then
		renderPasses()
	end
end

petBtn.Activated:Connect(renderPets)
passBtn.Activated:Connect(renderPasses)

Net.event("StateChanged").OnClientEvent:Connect(function(newState)
	state = newState
	render()
end)

Net.event("Notify").OnClientEvent:Connect(function(message, color)
	showToast(message, color or WHITE)
end)

-- pitch-timer
task.spawn(function()
	while true do
		task.wait(0.05)
		if activePitchId then
			local left = math.max(0, pitchDeadline - os.clock())
			timerFill.Size = UDim2.new(left / pitchSeconds, 0, 1, 0)
			timerFill.BackgroundColor3 = left < pitchSeconds * 0.3 and RED or GREEN
			if left <= 0 then
				closePitch()
			end
		end
	end
end)
