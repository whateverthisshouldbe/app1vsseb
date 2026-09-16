-- Sell Me This Pen - SERVER. Plak dit in een Script in ServerScriptService.
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

PEN.Data = (function()
	--!strict
	-- Opslaan en laden. Gebruikt DataStore, maar de game blijft speelbaar
	-- als DataStore niet beschikbaar is (bijv. Studio zonder API-toegang).

	local DataStoreService = game:GetService("DataStoreService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local Config = PEN.Config

	local Data = {}

	export type Profile = {
		cash: number,
		pens: number,
		penValue: number,
		rebirths: number,
		totalSold: number,
		upgrades: { [string]: number },
		pets: { [string]: boolean },
		equippedPet: string?,
		dailyStreak: number,
		lastDailyAt: number,
		redeemed: { [string]: boolean },
		lastSeen: number,
		-- niet opgeslagen, alleen deze sessie:
		loaded: boolean,
		dirty: boolean,
		pitchStreak: number,
	}

	local AUTOSAVE_SECONDS = 60
	local store: DataStore? = nil
	local profiles: { [Player]: Profile } = {}

	local function defaultProfile(): Profile
		local upgrades = {}
		for _, up in Config.Upgrades do
			upgrades[up.key] = 1
		end
		return {
			cash = 0,
			pens = 0,
			penValue = 0,
			rebirths = 0,
			totalSold = 0,
			upgrades = upgrades,
			pets = {},
			equippedPet = nil,
			dailyStreak = 0,
			lastDailyAt = 0,
			redeemed = {},
			lastSeen = 0,
			loaded = false,
			dirty = false,
			pitchStreak = 0,
		}
	end

	local function sanitize(raw: any): Profile
		local p = defaultProfile()
		if typeof(raw) ~= "table" then
			return p
		end
		p.cash = math.max(0, tonumber(raw.cash) or 0)
		p.pens = math.max(0, math.floor(tonumber(raw.pens) or 0))
		p.penValue = math.max(0, tonumber(raw.penValue) or 0)
		p.rebirths = math.clamp(math.floor(tonumber(raw.rebirths) or 0), 0, #Config.Stations - 1)
		p.totalSold = math.max(0, math.floor(tonumber(raw.totalSold) or 0))
		p.dailyStreak = math.clamp(math.floor(tonumber(raw.dailyStreak) or 0), 0, Config.Daily.maxStreak)
		p.lastDailyAt = math.max(0, math.floor(tonumber(raw.lastDailyAt) or 0))
		p.lastSeen = math.max(0, math.floor(tonumber(raw.lastSeen) or 0))

		if typeof(raw.upgrades) == "table" then
			for _, up in Config.Upgrades do
				local lvl = math.floor(tonumber(raw.upgrades[up.key]) or 1)
				p.upgrades[up.key] = math.clamp(lvl, 1, up.maxLevel)
			end
		end
		if typeof(raw.pets) == "table" then
			for _, pet in Config.Pets do
				if raw.pets[pet.key] == true then
					p.pets[pet.key] = true
				end
			end
		end
		if typeof(raw.equippedPet) == "string" and p.pets[raw.equippedPet] then
			p.equippedPet = raw.equippedPet
		end
		if typeof(raw.redeemed) == "table" then
			for _, entry in Config.Codes do
				if raw.redeemed[entry.code] == true then
					p.redeemed[entry.code] = true
				end
			end
		end
		return p
	end

	local function getStore(): DataStore?
		if store then
			return store
		end
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(Config.DataStoreKey)
		end)
		if ok then
			store = result
			return store
		end
		warn("[Pen] DataStore niet beschikbaar: " .. tostring(result))
		return nil
	end

	local function key(player: Player): string
		return "player_" .. player.UserId
	end

	function Data.load(player: Player): Profile
		local profile = defaultProfile()
		profiles[player] = profile

		local ds = getStore()
		if ds then
			local ok, result = pcall(function()
				return ds:GetAsync(key(player))
			end)
			if ok then
				if result ~= nil then
					local loaded = sanitize(result)
					loaded.loaded = true
					profiles[player] = loaded
					return loaded
				end
			else
				warn("[Pen] Laden mislukt voor " .. player.Name .. ": " .. tostring(result))
			end
		end

		profile.loaded = true
		return profile
	end

	function Data.get(player: Player): Profile?
		return profiles[player]
	end

	function Data.all(): { [Player]: Profile }
		return profiles
	end

	function Data.save(player: Player): boolean
		local profile = profiles[player]
		if not profile or not profile.loaded then
			return false
		end
		profile.lastSeen = os.time()
		local ds = getStore()
		if not ds then
			return false
		end
		local payload = {
			cash = profile.cash,
			pens = profile.pens,
			penValue = profile.penValue,
			rebirths = profile.rebirths,
			totalSold = profile.totalSold,
			upgrades = profile.upgrades,
			pets = profile.pets,
			equippedPet = profile.equippedPet,
			dailyStreak = profile.dailyStreak,
			lastDailyAt = profile.lastDailyAt,
			redeemed = profile.redeemed,
			lastSeen = profile.lastSeen,
		}
		local ok, err = pcall(function()
			ds:SetAsync(key(player), payload)
		end)
		if not ok then
			warn("[Pen] Opslaan mislukt voor " .. player.Name .. ": " .. tostring(err))
			return false
		end
		profile.dirty = false
		return true
	end

	function Data.release(player: Player)
		Data.save(player)
		profiles[player] = nil
	end

	function Data.start()
		task.spawn(function()
			while true do
				task.wait(AUTOSAVE_SECONDS)
				for player, profile in profiles do
					if profile.dirty then
						Data.save(player)
					end
				end
			end
		end)

		game:BindToClose(function()
			if RunService:IsStudio() then
				return
			end
			for _, player in Players:GetPlayers() do
				task.spawn(Data.save, player)
			end
			task.wait(3)
		end)
	end

	return Data
end)()

PEN.World = (function()
	--!strict
	-- Bouwt de hele map met code: een straat met een zaak per rebirth, plus het
	-- plein met de kiosk, de rebirth-plaat, de pennenbak en de scoreborden.

	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	local Config = PEN.Config

	local World = {}

	World.STATION_SPACING = 140
	World.FIRST_STATION_Z = -70

	-- per station een eigen vorm, zodat de straat niet één rij dozen wordt
	local SHAPES: { [string]: { size: Vector3, material: Enum.Material, roof: boolean } } = {
		kraam      = { size = Vector3.new(22, 8, 12),  material = Enum.Material.WoodPlanks, roof = true },
		winkel     = { size = Vector3.new(30, 14, 16), material = Enum.Material.Brick,      roof = true },
		fabriek    = { size = Vector3.new(44, 18, 24), material = Enum.Material.Metal,      roof = false },
		groothandel= { size = Vector3.new(52, 20, 30), material = Enum.Material.Concrete,   roof = false },
		toren      = { size = Vector3.new(30, 70, 30), material = Enum.Material.Glass,      roof = false },
		penthouse  = { size = Vector3.new(38, 26, 28), material = Enum.Material.Marble,     roof = true },
		jacht      = { size = Vector3.new(58, 14, 20), material = Enum.Material.Plastic,    roof = true },
		orbit      = { size = Vector3.new(40, 16, 40), material = Enum.Material.Neon,       roof = false },
	}

	local function part(props: { [string]: any }, parent: Instance): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(p :: any)[k] = v
		end
		p.Parent = parent
		return p
	end

	local function label(parent: BasePart, name: string, text: string, offsetY: number, size: number): TextLabel
		local gui = Instance.new("BillboardGui")
		gui.Name = name
		gui.Size = UDim2.fromScale(14, 3.4)
		gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 260
		gui.Parent = parent

		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = size
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextStrokeTransparency = 0.35
		tl.TextStrokeColor3 = Color3.new(0, 0, 0)
		tl.RichText = true
		tl.Text = text
		tl.Parent = gui
		return tl
	end

	local function pad(name: string, cf: CFrame, size: Vector3, color: Color3, text: string, parent: Instance): Part
		local p = part({
			Name = name,
			Size = size,
			CFrame = cf,
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.25,
		}, parent)
		label(p, "Label", text, size.Y / 2 + 3, 22)
		return p
	end

	local function board(name: string, cf: CFrame, title: string, parent: Instance): TextLabel
		local stand = part({
			Name = name,
			Size = Vector3.new(24, 20, 1.5),
			CFrame = cf,
			Color = Color3.fromRGB(26, 28, 38),
		}, parent)

		local surface = Instance.new("SurfaceGui")
		surface.Name = "Screen"
		surface.Face = Enum.NormalId.Front
		surface.CanvasSize = Vector2.new(480, 400)
		surface.LightInfluence = 0
		surface.Parent = stand

		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 54)
		header.BackgroundTransparency = 1
		header.Font = Enum.Font.GothamBold
		header.TextSize = 34
		header.TextColor3 = Color3.fromRGB(255, 220, 120)
		header.Text = title
		header.Parent = surface

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.Size = UDim2.new(1, -24, 1, -64)
		body.Position = UDim2.new(0, 12, 0, 58)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.GothamMedium
		body.TextSize = 24
		body.TextColor3 = Color3.new(1, 1, 1)
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.RichText = true
		body.Text = "laden..."
		body.Parent = surface

		return body
	end

	local function buildStation(root: Folder, index: number, station)
		local z = World.FIRST_STATION_Z - (index - 1) * World.STATION_SPACING
		local shape = SHAPES[station.key] or { size = Vector3.new(30, 14, 16), material = Enum.Material.Concrete, roof = false }

		local folder = Instance.new("Folder")
		folder.Name = "Station_" .. station.key
		folder.Parent = root

		-- grondvlak
		part({
			Name = "Plot",
			Size = Vector3.new(110, 1, 110),
			CFrame = CFrame.new(0, 0.5, z),
			Color = station.color:Lerp(Color3.new(0, 0, 0), 0.6),
			Material = Enum.Material.Concrete,
		}, folder)

		-- gebouw
		local building = part({
			Name = "Building",
			Size = shape.size,
			CFrame = CFrame.new(0, 1 + shape.size.Y / 2, z - 34),
			Color = station.color,
			Material = shape.material,
			Transparency = station.key == "toren" and 0.25 or 0,
		}, folder)

		if shape.roof then
			part({
				Name = "Roof",
				Size = Vector3.new(shape.size.X + 6, 1, shape.size.Z + 6),
				CFrame = CFrame.new(0, 1 + shape.size.Y + 0.5, z - 34),
				Color = Color3.fromRGB(220, 80, 80),
			}, folder)
		end

		local unlockText = station.unlockRebirth == 0 and "vanaf het begin"
			or string.format('<font color="rgb(200,120,255)">rebirth %d nodig</font>', station.unlockRebirth)
		label(building, "Sign", string.format("<b>%s</b>\n%s\n%s", station.name, station.tagline, unlockText),
			shape.size.Y / 2 + 5, 26)

		-- werkplek: pennen maken
		pad("Press_" .. station.key, CFrame.new(-26, 1.35, z - 6), Vector3.new(18, 0.7, 16),
			Color3.fromRGB(90, 190, 255), "Pennen maken", folder)

		-- toonbank: verkopen
		local desk = part({
			Name = "Desk_" .. station.key,
			Size = Vector3.new(22, 5, 6),
			CFrame = CFrame.new(28, 3.5, z - 16),
			Color = Color3.fromRGB(120, 86, 56),
			Material = Enum.Material.Wood,
		}, folder)
		label(desk, "Label", "<b>TOONBANK</b>", 4.5, 24)

		pad("Sell_" .. station.key, CFrame.new(28, 1.35, z - 6), Vector3.new(22, 0.7, 14),
			Color3.fromRGB(120, 255, 150), "Verkopen", folder)

		part({
			Name = "Spot_" .. station.key,
			Size = Vector3.new(4, 0.4, 4),
			CFrame = CFrame.new(28, 1.2, z - 22),
			Transparency = 1,
			CanCollide = false,
		}, folder)
	end

	function World.build(): Folder
		local existing = Workspace:FindFirstChild("PenWorld")
		if existing then
			existing:Destroy()
		end

		local root = Instance.new("Folder")
		root.Name = "PenWorld"
		root.Parent = Workspace

		Lighting.Ambient = Color3.fromRGB(105, 105, 118)
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 152)
		Lighting.Brightness = 2.6

		local streetLength = #Config.Stations * World.STATION_SPACING + 260

		part({
			Name = "Ground",
			Size = Vector3.new(400, 2, streetLength),
			CFrame = CFrame.new(0, -1, World.FIRST_STATION_Z - (#Config.Stations - 1) * World.STATION_SPACING / 2),
			Color = Color3.fromRGB(52, 56, 66),
			Material = Enum.Material.Concrete,
		}, root)

		part({
			Name = "Street",
			Size = Vector3.new(24, 0.3, streetLength),
			CFrame = CFrame.new(0, 0.2, World.FIRST_STATION_Z - (#Config.Stations - 1) * World.STATION_SPACING / 2),
			Color = Color3.fromRGB(38, 40, 50),
			Material = Enum.Material.Asphalt,
		}, root)

		-- ------------------------------------------------------------- plein ---
		local plaza = Instance.new("Folder")
		plaza.Name = "Plaza"
		plaza.Parent = root

		part({
			Name = "PlazaFloor",
			Size = Vector3.new(160, 1, 120),
			CFrame = CFrame.new(0, 0.5, 40),
			Color = Color3.fromRGB(70, 76, 92),
		}, plaza)

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PenSpawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(14, 1, 14)
		spawn.CFrame = CFrame.new(0, 1.5, 30)
		spawn.Color = Color3.fromRGB(80, 200, 140)
		spawn.Duration = 0
		spawn.Parent = plaza

		-- upgrade-kiosk
		local spacing = 20
		local startX = -((#Config.Upgrades - 1) * spacing) / 2
		for i, up in Config.Upgrades do
			local x = startX + (i - 1) * spacing
			local stand = part({
				Name = "KioskBody_" .. up.key,
				Size = Vector3.new(9, 6, 4),
				CFrame = CFrame.new(x, 4, 78),
				Color = Color3.fromRGB(46, 52, 66),
			}, plaza)
			label(stand, "Label", string.format("<b>%s</b>\n%s", up.name, up.info), 5, 20)
			pad("UpgradePad_" .. up.key, CFrame.new(x, 1.35, 68), Vector3.new(12, 0.7, 10),
				Color3.fromRGB(255, 200, 90), up.name, plaza)
		end

		-- rebirth
		local rebirthBody = part({
			Name = "RebirthBody",
			Size = Vector3.new(12, 16, 12),
			CFrame = CFrame.new(-52, 9, 40),
			Color = Color3.fromRGB(120, 60, 180),
			Material = Enum.Material.Neon,
			Transparency = 0.35,
		}, plaza)
		label(rebirthBody, "Label", "<b>REBIRTH</b>\nopent je volgende zaak", 10, 26)
		pad("RebirthPad", CFrame.new(-52, 1.35, 28), Vector3.new(14, 0.7, 12),
			Color3.fromRGB(200, 120, 255), "2 sec blijven staan", plaza)

		-- pennenbak (huisdieren)
		local petBody = part({
			Name = "PetBody",
			Size = Vector3.new(12, 10, 8),
			CFrame = CFrame.new(52, 6, 40),
			Color = Color3.fromRGB(60, 120, 110),
			Material = Enum.Material.Metal,
		}, plaza)
		label(petBody, "Label", "<b>PENNENBAK</b>\nmascottes kopen", 7, 26)
		pad("PetPad", CFrame.new(52, 1.35, 28), Vector3.new(14, 0.7, 12),
			Color3.fromRGB(120, 230, 220), "Mascottes", plaza)

		-- scoreborden
		board("Board_cash", CFrame.new(-40, 12, 92) * CFrame.Angles(0, math.pi, 0), "RIJKSTE VERKOPERS", plaza)
		board("Board_rebirths", CFrame.new(40, 12, 92) * CFrame.Angles(0, math.pi, 0), "MEESTE REBIRTHS", plaza)

		-- ---------------------------------------------------------- stations ---
		for i, station in Config.Stations do
			buildStation(root, i, station)
		end

		return root
	end

	function World.find(root: Instance, name: string): BasePart?
		local p = root:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then
			return p
		end
		return nil
	end

	function World.boardBody(root: Instance, name: string): TextLabel?
		local stand = root:FindFirstChild(name, true)
		if not stand then
			return nil
		end
		local screen = stand:FindFirstChild("Screen")
		local body = screen and screen:FindFirstChild("Body")
		if body and body:IsA("TextLabel") then
			return body
		end
		return nil
	end

	return World
end)()

PEN.Customers = (function()
	--!strict
	-- De klanten aan de toonbank. Elke klant heeft een type ("heeft haast",
	-- "houdt van luxe", ...) waar je pitch bij moet passen.

	local Config = PEN.Config
	local Net = PEN.Net

	local Customers = {}

	export type Customer = {
		station: string,
		name: string,
		line: string,
		typeKey: string,
		typeLabel: string,
		multiplier: number,
	}

	local current: { [string]: Customer } = {}
	local models: { [string]: Model } = {}
	local bubbles: { [string]: TextLabel } = {}

	local function bodyPart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	local function buildModel(stationKey: string, spot: BasePart): Model
		local m = Instance.new("Model")
		m.Name = "Customer_" .. stationKey

		local skin = Color3.fromRGB(235, 200, 160)
		local suit = Color3.fromRGB(40, 44, 60)
		local base = spot.Position
		-- kijkt naar de toonbank toe (richting +Z)
		local facing = CFrame.new(base, base + Vector3.new(0, 0, 10))

		local torso = bodyPart("Torso", Vector3.new(2, 2, 1), facing * CFrame.new(0, 3, 0), suit, m)
		bodyPart("Head", Vector3.new(1.4, 1.4, 1.4), facing * CFrame.new(0, 4.6, 0), skin, m)
		bodyPart("Tie", Vector3.new(0.35, 1.4, 0.2), facing * CFrame.new(0, 3.1, -0.55), Color3.fromRGB(200, 60, 70), m)
		bodyPart("ArmL", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(-1.4, 3, 0), suit, m)
		bodyPart("ArmR", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(1.4, 3, 0), suit, m)
		bodyPart("LegL", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(-0.55, 1, 0), Color3.fromRGB(30, 32, 44), m)
		bodyPart("LegR", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(0.55, 1, 0), Color3.fromRGB(30, 32, 44), m)

		m.PrimaryPart = torso

		local gui = Instance.new("BillboardGui")
		gui.Name = "Bubble"
		gui.Size = UDim2.fromScale(13, 3.8)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 180
		gui.Adornee = torso
		gui.Parent = torso

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
		frame.BackgroundTransparency = 0.25
		frame.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = frame

		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.new(1, -12, 1, -8)
		tl.Position = UDim2.new(0, 6, 0, 4)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamMedium
		tl.TextSize = 20
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextWrapped = true
		tl.RichText = true
		tl.Text = ""
		tl.Parent = frame

		bubbles[stationKey] = tl
		return m
	end

	local function refreshBubble(stationKey: string)
		local c = current[stationKey]
		local tl = bubbles[stationKey]
		if not c or not tl then
			return
		end
		local t = Config.getCustomerType(c.typeKey)
		local col = t.color
		tl.Text = string.format(
			'<b>%s</b>: "%s"\n<font color="rgb(%d,%d,%d)">%s</font>  ·  x%.2f',
			c.name, c.line,
			math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255),
			t.label, c.multiplier
		)
	end

	local function roll(stationKey: string)
		local cfg = Config.Customer
		local t = Config.CustomerTypes[math.random(#Config.CustomerTypes)]
		local mult = 0.85 + math.random() * 0.75
		current[stationKey] = {
			station = stationKey,
			name = cfg.names[math.random(#cfg.names)],
			line = cfg.lines[math.random(#cfg.lines)],
			typeKey = t.key,
			typeLabel = t.label,
			multiplier = math.floor(mult * 100 + 0.5) / 100,
		}
		refreshBubble(stationKey)
		Net.event("CustomerChanged"):FireAllClients(current[stationKey])
	end

	function Customers.get(stationKey: string): Customer?
		return current[stationKey]
	end

	function Customers.all(): { [string]: Customer }
		return current
	end

	function Customers.serve(stationKey: string)
		roll(stationKey)
	end

	function Customers.start(spots: { [string]: BasePart })
		for stationKey, spot in spots do
			local m = buildModel(stationKey, spot)
			m.Parent = spot.Parent
			models[stationKey] = m
			roll(stationKey)
		end

		task.spawn(function()
			while true do
				task.wait(Config.Customer.rotateSeconds)
				for stationKey in current do
					roll(stationKey)
				end
			end
		end)
	end

	return Customers
end)()

PEN.Passes = (function()
	--!strict
	-- Gamepasses. Zolang een ID nog 0 is in Config, is die pass simpelweg uit.

	local MarketplaceService = game:GetService("MarketplaceService")
	local Players = game:GetService("Players")

	local Config = PEN.Config

	local Passes = {}

	local cache: { [Player]: { [string]: boolean } } = {}

	local function check(player: Player, key: string): boolean
		local pass = Config.Gamepasses[key]
		if not pass or pass.id == 0 then
			return false
		end
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
		end)
		if not ok then
			warn("[Pen] Gamepass-check mislukt: " .. tostring(owns))
			return false
		end
		return owns == true
	end

	function Passes.refresh(player: Player)
		local owned = {}
		for key in Config.Gamepasses do
			owned[key] = check(player, key)
		end
		cache[player] = owned
	end

	function Passes.owns(player: Player, key: string): boolean
		local owned = cache[player]
		return owned ~= nil and owned[key] == true
	end

	function Passes.owned(player: Player): { [string]: boolean }
		return cache[player] or {}
	end

	function Passes.prompt(player: Player, key: string)
		local pass = Config.Gamepasses[key]
		if not pass or pass.id == 0 then
			return
		end
		local ok, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		end)
		if not ok then
			warn("[Pen] Kon gamepass niet tonen: " .. tostring(err))
		end
	end

	function Passes.start(onChanged: (Player) -> ())
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _passId, purchased)
			if purchased then
				Passes.refresh(player)
				onChanged(player)
			end
		end)
		Players.PlayerRemoving:Connect(function(player)
			cache[player] = nil
		end)
	end

	return Passes
end)()

PEN.Pets = (function()
	--!strict
	-- De mascotte: een pennetje dat om je heen zweeft en je boost geeft.

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local Config = PEN.Config

	local Pets = {}

	local active: { [Player]: Model } = {}

	local function build(pet): Model
		local m = Instance.new("Model")
		m.Name = "Pet_" .. pet.key

		local body = Instance.new("Part")
		body.Name = "Body"
		body.Anchored = true
		body.CanCollide = false
		body.Size = Vector3.new(0.5, 3, 0.5)
		body.Color = pet.color
		body.Material = Enum.Material.SmoothPlastic
		body.Parent = m

		local tip = Instance.new("Part")
		tip.Name = "Tip"
		tip.Anchored = true
		tip.CanCollide = false
		tip.Size = Vector3.new(0.5, 0.7, 0.5)
		tip.Shape = Enum.PartType.Ball
		tip.Color = Color3.fromRGB(30, 30, 35)
		tip.Material = Enum.Material.Metal
		tip.Parent = m

		m.PrimaryPart = body

		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(6, 1.4)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 90
		gui.Adornee = body
		gui.Parent = body

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 16
		tl.TextColor3 = pet.color
		tl.TextStrokeTransparency = 0.4
		tl.Text = pet.name
		tl.Parent = gui

		return m
	end

	function Pets.equip(player: Player, petKey: string?)
		local existing = active[player]
		if existing then
			existing:Destroy()
			active[player] = nil
		end
		local pet = Config.getPet(petKey)
		if not pet then
			return
		end
		local m = build(pet)
		m.Parent = workspace
		active[player] = m
	end

	function Pets.start()
		Players.PlayerRemoving:Connect(function(player)
			local m = active[player]
			if m then
				m:Destroy()
			end
			active[player] = nil
		end)

		RunService.Heartbeat:Connect(function()
			local t = os.clock()
			for player, model in active do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local body = model.PrimaryPart
				local tip = model:FindFirstChild("Tip")
				if root and root:IsA("BasePart") and body and tip and tip:IsA("BasePart") then
					local angle = t * 1.6
					local offset = Vector3.new(math.cos(angle) * 4, 3.5 + math.sin(t * 2) * 0.4, math.sin(angle) * 4)
					local cf = CFrame.new(root.Position + offset) * CFrame.Angles(0, -angle, math.rad(25))
					body.CFrame = cf
					tip.CFrame = cf * CFrame.new(0, -1.7, 0)
				end
			end
		end)
	end

	return Pets
end)()

PEN.Leaderboards = (function()
	--!strict
	-- De twee borden op het plein: rijkste verkopers en meeste rebirths.

	local DataStoreService = game:GetService("DataStoreService")
	local Players = game:GetService("Players")

	local Config = PEN.Config

	local Leaderboards = {}

	local REFRESH_SECONDS = 120
	local MAX_VALUE = 1e15

	local stores: { [string]: OrderedDataStore } = {}
	local labels: { [string]: TextLabel } = {}
	local nameCache: { [number]: string } = {}

	local function getStore(kind: string): OrderedDataStore?
		if stores[kind] then
			return stores[kind]
		end
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.DataStoreKey .. "_" .. kind)
		end)
		if not ok then
			return nil
		end
		stores[kind] = result
		return result
	end

	local function nameFor(userId: number): string
		local cached = nameCache[userId]
		if cached then
			return cached
		end
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		local resolved = ok and name or ("Speler " .. userId)
		nameCache[userId] = resolved
		return resolved
	end

	function Leaderboards.submit(player: Player, cash: number, rebirths: number)
		task.spawn(function()
			local cashStore = getStore("cash")
			if cashStore then
				pcall(function()
					cashStore:SetAsync(tostring(player.UserId), math.clamp(math.floor(cash), 0, MAX_VALUE))
				end)
			end
			local rebirthStore = getStore("rebirths")
			if rebirthStore then
				pcall(function()
					rebirthStore:SetAsync(tostring(player.UserId), math.clamp(math.floor(rebirths), 0, MAX_VALUE))
				end)
			end
		end)
	end

	local function render(kind: string, formatValue: (number) -> string)
		local label = labels[kind]
		if not label then
			return
		end
		local store = getStore(kind)
		if not store then
			label.Text = "Scorebord werkt pas in een gepubliceerde game."
			return
		end
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, 10)
		end)
		if not ok then
			label.Text = "Even geen verbinding met het scorebord."
			return
		end
		local rows = {}
		local place = 1
		for _, entry in (pages :: DataStorePages):GetCurrentPage() do
			local userId = tonumber(entry.key)
			if userId then
				table.insert(rows, string.format("%d. %s  -  %s", place, nameFor(userId), formatValue(entry.value)))
				place += 1
			end
		end
		if #rows == 0 then
			label.Text = "Nog niemand. Wees de eerste!"
		else
			label.Text = table.concat(rows, "\n")
		end
	end

	function Leaderboards.start(cashLabel: TextLabel?, rebirthLabel: TextLabel?)
		if cashLabel then
			labels.cash = cashLabel
		end
		if rebirthLabel then
			labels.rebirths = rebirthLabel
		end

		task.spawn(function()
			while true do
				render("cash", function(v)
					return "$" .. Config.short(v)
				end)
				render("rebirths", function(v)
					return string.format("%d rebirths", v)
				end)
				task.wait(REFRESH_SECONDS)
			end
		end)
	end

	return Leaderboards
end)()

PEN.Game = (function()
	--!strict
	-- De spelregels: pennen maken, pitchen, verkopen, upgraden, rebirthen,
	-- passief verdienen, mascottes, dagbeloning en codes.

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local Config = PEN.Config
	local Net = PEN.Net
	local Data = PEN.Data
	local World = PEN.World
	local Customers = PEN.Customers
	local Passes = PEN.Passes
	local Pets = PEN.Pets
	local Leaderboards = PEN.Leaderboards

	local Game = {}

	local TICK = 0.1
	local UPGRADE_PAD_COOLDOWN = 0.5
	local SELL_COOLDOWN = 0.4
	local REBIRTH_HOLD = 2
	local HINT_COOLDOWN = 12

	local pads: { [string]: BasePart } = {}
	local nextProduce: { [Player]: number } = {}
	local nextSell: { [Player]: number } = {}
	local nextUpgrade: { [Player]: number } = {}
	local nextHint: { [Player]: number } = {}
	local rebirthHeldSince: { [Player]: number? } = {}

	type Pitch = {
		id: number,
		station: string,
		options: { any },
		customerType: string,
		pens: number,
		expires: number,
	}
	local pitches: { [Player]: Pitch } = {}
	local pitchCounter = 0

	-- ------------------------------------------------------------- hulpjes ----

	local function notify(player: Player, text: string, color: Color3?)
		Net.event("Notify"):FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
	end

	local function upgradeValue(profile, key: string): number
		local up = Config.getUpgrade(key)
		return up and up.value(profile.upgrades[key] or 1) or 0
	end

	local function petOf(profile)
		return Config.getPet(profile.equippedPet)
	end

	local function capacityOf(player: Player, profile): number
		local base = upgradeValue(profile, "capacity")
		if Passes.owns(player, "vipBag") then
			base *= Config.Perks.vipBagMultiplier
		end
		return math.floor(base)
	end

	local function produceInterval(profile): number
		local pet = petOf(profile)
		local speed = upgradeValue(profile, "speed")
		return speed / (1 + (pet and pet.produce or 0))
	end

	local function cashMultiplier(player: Player, profile): number
		local pet = petOf(profile)
		local mult = upgradeValue(profile, "charm")
			* Config.rebirthMultiplier(profile.rebirths)
			* (1 + (pet and pet.value or 0))
		if Passes.owns(player, "doubleCash") then
			mult *= Config.Perks.doubleCashMultiplier
		end
		return mult
	end

	local function passivePerSecond(player: Player, profile): number
		local total = 0
		for _, station in Config.Stations do
			if profile.rebirths >= station.unlockRebirth then
				total += station.autoPerSecond * station.pen.value
			end
		end
		local pet = petOf(profile)
		total *= upgradeValue(profile, "auto")
			* Config.rebirthMultiplier(profile.rebirths)
			* (1 + (pet and pet.produce or 0) * 0.5)
		if Passes.owns(player, "doubleCash") then
			total *= Config.Perks.doubleCashMultiplier
		end
		return total
	end

	local function stationUnlocked(profile, station): boolean
		return profile.rebirths >= station.unlockRebirth
	end

	local function nextStation(profile)
		for _, station in Config.Stations do
			if station.unlockRebirth == profile.rebirths + 1 then
				return station
			end
		end
		return nil
	end

	local function dailyStatus(profile)
		local now = os.time()
		local since = now - profile.lastDailyAt
		local ready = profile.lastDailyAt == 0 or since >= Config.Daily.cooldownSeconds
		return {
			ready = ready,
			streak = profile.dailyStreak,
			secondsLeft = ready and 0 or math.max(0, Config.Daily.cooldownSeconds - since),
			reward = math.floor(Config.Daily.baseReward
				* (1 + math.max(0, math.min(profile.dailyStreak, Config.Daily.maxStreak - 1)) * Config.Daily.streakBonus)),
		}
	end

	-- --------------------------------------------------------------- status ---

	local function buildState(player: Player, profile)
		local upgrades = {}
		for _, up in Config.Upgrades do
			local level = profile.upgrades[up.key] or 1
			local maxed = level >= up.maxLevel
			table.insert(upgrades, {
				key = up.key,
				name = up.name,
				info = up.info,
				level = level,
				maxed = maxed,
				price = maxed and 0 or Config.upgradePrice(up, level),
				display = up.format(up.value(level)),
				nextDisplay = maxed and "" or up.format(up.value(level + 1)),
			})
		end

		local stations = {}
		for i, station in Config.Stations do
			table.insert(stations, {
				key = station.key,
				name = station.name,
				tagline = station.tagline,
				index = i,
				unlocked = stationUnlocked(profile, station),
				unlockRebirth = station.unlockRebirth,
				penName = station.pen.name,
				penValue = station.pen.value,
			})
		end

		local pets = {}
		for _, pet in Config.Pets do
			table.insert(pets, {
				key = pet.key,
				name = pet.name,
				price = pet.price,
				produce = pet.produce,
				value = pet.value,
				owned = profile.pets[pet.key] == true,
				equipped = profile.equippedPet == pet.key,
			})
		end

		local passes = {}
		for key, pass in Config.Gamepasses do
			table.insert(passes, {
				key = key,
				name = pass.name,
				info = pass.info,
				configured = pass.id ~= 0,
				owned = Passes.owns(player, key),
			})
		end

		local upcoming = nextStation(profile)

		return {
			cash = profile.cash,
			pens = profile.pens,
			penValue = profile.penValue,
			capacity = capacityOf(player, profile),
			bagValue = math.floor(profile.pens * profile.penValue * cashMultiplier(player, profile)),
			rebirths = profile.rebirths,
			totalSold = profile.totalSold,
			multiplier = cashMultiplier(player, profile),
			passivePerSecond = passivePerSecond(player, profile),
			pitchStreak = profile.pitchStreak,
			rebirthPrice = Config.rebirthPrice(profile.rebirths),
			canRebirth = upcoming ~= nil and profile.cash >= Config.rebirthPrice(profile.rebirths),
			nextStationName = upcoming and upcoming.name or "",
			nextPenName = upcoming and upcoming.pen.name or "",
			stations = stations,
			upgrades = upgrades,
			pets = pets,
			passes = passes,
			daily = dailyStatus(profile),
		}
	end

	local function push(player: Player)
		local profile = Data.get(player)
		if not profile then
			return
		end
		Net.event("StateChanged"):FireClient(player, buildState(player, profile))

		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local cash = stats:FindFirstChild("Cash") :: IntValue?
			local pens = stats:FindFirstChild("Pennen") :: IntValue?
			local rb = stats:FindFirstChild("Rebirths") :: IntValue?
			if cash then cash.Value = math.floor(math.min(profile.cash, 2 ^ 31 - 1)) end
			if pens then pens.Value = profile.pens end
			if rb then rb.Value = profile.rebirths end
		end
	end

	local function applyWalkSpeed(player: Player)
		local profile = Data.get(player)
		local character = player.Character
		if not profile or not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = upgradeValue(profile, "legs")
		end
	end

	-- ---------------------------------------------------------------- pitch ---

	local function pickOptions(customerType: string)
		local perfect, half, miss = {}, {}, {}
		for _, arg in Config.PitchArguments do
			if table.find(arg.good, customerType) then
				table.insert(perfect, arg)
			elseif table.find(arg.ok, customerType) then
				table.insert(half, arg)
			else
				table.insert(miss, arg)
			end
		end
		local chosen = {}
		if #perfect > 0 then
			table.insert(chosen, perfect[math.random(#perfect)])
		end
		if #half > 0 then
			table.insert(chosen, half[math.random(#half)])
		end
		while #chosen < Config.Pitch.optionCount and #miss > 0 do
			local pick = table.remove(miss, math.random(#miss))
			if pick then
				table.insert(chosen, pick)
			end
		end
		-- husselen zodat het goede antwoord niet altijd bovenaan staat
		for i = #chosen, 2, -1 do
			local j = math.random(i)
			chosen[i], chosen[j] = chosen[j], chosen[i]
		end
		return chosen
	end

	local function finishPitch(player: Player, profile, pitch: Pitch, choiceIndex: number?)
		pitches[player] = nil

		local customer = Customers.get(pitch.station)
		local sold = math.min(profile.pens, pitch.pens)
		if sold <= 0 then
			Net.event("PitchEnd"):FireClient(player, { ok = false, text = "Je tas was leeg." })
			return
		end

		local quality: string
		local pitchMult: number
		local chosen = choiceIndex and pitch.options[choiceIndex]
		if not chosen then
			if Passes.owns(player, "autoSell") then
				quality = "auto"
				pitchMult = Config.Pitch.okMultiplier
			else
				quality = "timeout"
				pitchMult = Config.Pitch.timeoutMultiplier
			end
		elseif table.find(chosen.good, pitch.customerType) then
			quality = "perfect"
			pitchMult = Config.Pitch.perfectMultiplier
		elseif table.find(chosen.ok, pitch.customerType) then
			quality = "ok"
			pitchMult = Config.Pitch.okMultiplier
		else
			quality = "miss"
			pitchMult = Config.Pitch.missMultiplier
		end

		if quality == "perfect" then
			profile.pitchStreak += 1
		elseif quality ~= "auto" then
			profile.pitchStreak = 0
		end
		local streakBonus = math.min(profile.pitchStreak * Config.Pitch.streakStep, Config.Pitch.streakMax)

		local customerMult = customer and customer.multiplier or 1
		local total = pitchMult * (1 + streakBonus) * customerMult
		local earned = math.floor(sold * profile.penValue * cashMultiplier(player, profile) * total)

		profile.cash += earned
		profile.totalSold += sold
		profile.pens -= sold
		if profile.pens <= 0 then
			profile.pens = 0
			profile.penValue = 0
		end
		profile.dirty = true

		Customers.serve(pitch.station)

		local resultText = ({
			perfect = "Verkocht! Precies wat de klant wilde horen.",
			ok = "Verkocht, maar hij twijfelde nog even.",
			miss = "Hij kocht hem, maar je praatje sloeg niet aan.",
			timeout = "Te lang getwijfeld - de klant koos zelf.",
			auto = "Auto-verkoop deed het praatje voor je.",
		})[quality] or "Verkocht."

		Net.event("PitchEnd"):FireClient(player, {
			ok = true,
			quality = quality,
			text = resultText,
			earned = earned,
			sold = sold,
			multiplier = total,
			streak = profile.pitchStreak,
		})
		push(player)
	end

	local function startPitch(player: Player, profile, stationKey: string)
		local customer = Customers.get(stationKey)
		if not customer then
			return
		end
		pitchCounter += 1
		local options = pickOptions(customer.typeKey)
		local pitch: Pitch = {
			id = pitchCounter,
			station = stationKey,
			options = options,
			customerType = customer.typeKey,
			pens = profile.pens,
			expires = os.clock() + Config.Pitch.seconds,
		}
		pitches[player] = pitch

		local texts = {}
		for _, arg in options do
			table.insert(texts, arg.text)
		end

		local typeInfo = Config.getCustomerType(customer.typeKey)
		Net.event("PitchStart"):FireClient(player, {
			id = pitch.id,
			customerName = customer.name,
			line = customer.line,
			typeLabel = typeInfo.label,
			typeColor = typeInfo.color,
			customerMultiplier = customer.multiplier,
			pens = profile.pens,
			seconds = Config.Pitch.seconds,
			options = texts,
		})
	end

	-- -------------------------------------------------------------- acties ----

	local function buyUpgrade(player: Player, key: string, silent: boolean?)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local up = Config.getUpgrade(key)
		if not up then
			return
		end
		local level = profile.upgrades[key] or 1
		if level >= up.maxLevel then
			if not silent then
				notify(player, up.name .. " is al maximaal", Color3.fromRGB(255, 220, 120))
			end
			return
		end
		local price = Config.upgradePrice(up, level)
		if profile.cash < price then
			if not silent then
				notify(player, string.format("Je hebt $%s nodig voor %s", Config.short(price), up.name),
					Color3.fromRGB(255, 150, 150))
			end
			return
		end
		profile.cash -= price
		profile.upgrades[key] = level + 1
		profile.dirty = true

		notify(player, string.format("%s -> level %d (%s)", up.name, level + 1, up.format(up.value(level + 1))),
			Color3.fromRGB(255, 220, 120))

		if key == "legs" then
			applyWalkSpeed(player)
		end
		if key == "capacity" then
			profile.pens = math.min(profile.pens, capacityOf(player, profile))
		end
		push(player)
	end

	local function rebirth(player: Player)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local upcoming = nextStation(profile)
		if not upcoming then
			notify(player, "Je hebt alle zaken al geopend!", Color3.fromRGB(255, 220, 120))
			return
		end
		local price = Config.rebirthPrice(profile.rebirths)
		if profile.cash < price then
			notify(player, string.format("Rebirth kost $%s", Config.short(price)), Color3.fromRGB(255, 150, 150))
			return
		end
		-- rebirth zet je geld en upgrades terug op nul, maar je zaken blijven
		-- open en blijven passief geld opleveren.
		profile.cash = 0
		profile.rebirths += 1
		profile.pens = 0
		profile.penValue = 0
		profile.pitchStreak = 0
		for _, up in Config.Upgrades do
			profile.upgrades[up.key] = 1
		end
		profile.dirty = true
		applyWalkSpeed(player)

		notify(player, string.format("REBIRTH %d! %s is open - je maakt nu %s (x%.2f op alles).",
			profile.rebirths, upcoming.name, upcoming.pen.name, Config.rebirthMultiplier(profile.rebirths)),
			Color3.fromRGB(200, 120, 255))
		push(player)
		Data.save(player)
		Leaderboards.submit(player, profile.cash, profile.rebirths)
	end

	local function buyPet(player: Player, petKey: string)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local pet = Config.getPet(petKey)
		if not pet then
			return
		end
		if profile.pets[pet.key] then
			profile.equippedPet = pet.key
			profile.dirty = true
			Pets.equip(player, pet.key)
			push(player)
			return
		end
		if profile.cash < pet.price then
			notify(player, string.format("%s kost $%s", pet.name, Config.short(pet.price)), Color3.fromRGB(255, 150, 150))
			return
		end
		profile.cash -= pet.price
		profile.pets[pet.key] = true
		profile.equippedPet = pet.key
		profile.dirty = true
		Pets.equip(player, pet.key)
		notify(player, string.format("%s is van jou! (+%d%% maken, +%d%% waarde)",
			pet.name, math.floor(pet.produce * 100), math.floor(pet.value * 100)), Color3.fromRGB(120, 230, 220))
		push(player)
	end

	local function equipPet(player: Player, petKey: string?)
		local profile = Data.get(player)
		if not profile then
			return
		end
		if petKey == nil or petKey == "" then
			profile.equippedPet = nil
		elseif profile.pets[petKey] then
			profile.equippedPet = petKey
		else
			return
		end
		profile.dirty = true
		Pets.equip(player, profile.equippedPet)
		push(player)
	end

	local function claimDaily(player: Player)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local status = dailyStatus(profile)
		if not status.ready then
			local hours = math.floor(status.secondsLeft / 3600)
			local minutes = math.floor((status.secondsLeft % 3600) / 60)
			notify(player, string.format("Volgende beloning over %du %dm", hours, minutes), Color3.fromRGB(255, 220, 120))
			return
		end
		local now = os.time()
		if profile.lastDailyAt > 0 and (now - profile.lastDailyAt) > Config.Daily.resetSeconds then
			profile.dailyStreak = 0
		end
		local reward = status.reward
		profile.cash += reward
		profile.dailyStreak = math.min(profile.dailyStreak + 1, Config.Daily.maxStreak)
		profile.lastDailyAt = now
		profile.dirty = true
		notify(player, string.format("Dagbeloning: $%s (dag %d op rij)", Config.short(reward), profile.dailyStreak),
			Color3.fromRGB(120, 255, 150))
		push(player)
	end

	local function redeemCode(player: Player, raw: string)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local code = string.upper((string.gsub(raw, "%s", "")))
		for _, entry in Config.Codes do
			if entry.code == code then
				if profile.redeemed[entry.code] then
					notify(player, "Die code heb je al gebruikt.", Color3.fromRGB(255, 220, 120))
					return
				end
				profile.redeemed[entry.code] = true
				if entry.cash > 0 then
					profile.cash += entry.cash
				end
				if entry.pet then
					local pet = Config.getPet(entry.pet)
					if pet then
						profile.pets[pet.key] = true
						profile.equippedPet = pet.key
						Pets.equip(player, pet.key)
					end
				end
				profile.dirty = true
				notify(player, string.format("Code '%s' ingewisseld!", entry.code), Color3.fromRGB(120, 255, 150))
				push(player)
				return
			end
		end
		notify(player, "Die code kennen we niet.", Color3.fromRGB(255, 150, 150))
	end

	-- ------------------------------------------------------------ spelers -----

	local function onCharacter(player: Player, character: Model)
		character:WaitForChild("Humanoid")
		task.wait(0.1)
		applyWalkSpeed(player)
	end

	local function grantOffline(player: Player, profile)
		if profile.lastSeen <= 0 then
			return
		end
		local away = os.time() - profile.lastSeen
		if away < 60 then
			return
		end
		local capHours = Passes.owns(player, "vipBag") and Config.Idle.offlineCapHoursVip or Config.Idle.offlineCapHours
		local capped = math.min(away, capHours * 3600)
		local earned = math.floor(passivePerSecond(player, profile) * capped * 0.5)
		if earned <= 0 then
			return
		end
		profile.cash += earned
		profile.dirty = true
		Net.event("OfflineEarnings"):FireClient(player, {
			earned = earned,
			seconds = capped,
			capped = away > capped,
			capHours = capHours,
		})
	end

	local function onPlayerAdded(player: Player)
		local profile = Data.load(player)
		Passes.refresh(player)

		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		for _, name in { "Cash", "Pennen", "Rebirths" } do
			local v = Instance.new("IntValue")
			v.Name = name
			v.Parent = stats
		end
		stats.Parent = player

		nextProduce[player] = 0
		nextSell[player] = 0
		nextUpgrade[player] = 0
		nextHint[player] = 0

		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end

		if profile.equippedPet then
			Pets.equip(player, profile.equippedPet)
		end

		grantOffline(player, profile)
		push(player)

		for _, customer in Customers.all() do
			Net.event("CustomerChanged"):FireClient(player, customer)
		end

		local station = Config.stationForRebirths(profile.rebirths)
		notify(player, string.format("Welkom bij je %s. Maak %ss en pitch ze!", station.name, station.pen.name),
			Color3.fromRGB(150, 210, 255))
	end

	local function onPlayerRemoving(player: Player)
		local profile = Data.get(player)
		if profile then
			Leaderboards.submit(player, profile.cash, profile.rebirths)
		end
		nextProduce[player] = nil
		nextSell[player] = nil
		nextUpgrade[player] = nil
		nextHint[player] = nil
		rebirthHeldSince[player] = nil
		pitches[player] = nil
		Data.release(player)
	end

	-- ----------------------------------------------------------------- lus ----

	local function isOnPad(root: BasePart, padPart: BasePart): boolean
		local offset = padPart.CFrame:PointToObjectSpace(root.Position)
		local half = padPart.Size / 2
		return math.abs(offset.X) <= half.X + 1
			and math.abs(offset.Z) <= half.Z + 1
			and offset.Y >= -2
			and offset.Y <= 8
	end

	local function hint(player: Player, now: number, text: string)
		if now >= (nextHint[player] or 0) then
			nextHint[player] = now + HINT_COOLDOWN
			notify(player, text, Color3.fromRGB(255, 220, 120))
		end
	end

	local function stepPlayer(player: Player, now: number)
		local profile = Data.get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not profile or not root then
			return
		end

		-- lopende pitch aflopen?
		local pitch = pitches[player]
		if pitch and now >= pitch.expires then
			finishPitch(player, profile, pitch, nil)
		end

		local capacity = capacityOf(player, profile)

		for _, station in Config.Stations do
			local pressPad = pads["Press_" .. station.key]
			if pressPad and isOnPad(root, pressPad) then
				if not stationUnlocked(profile, station) then
					hint(player, now, string.format("%s opent na rebirth %d", station.name, station.unlockRebirth))
				else
					local interval = produceInterval(profile)
					local made = 0
					while now >= (nextProduce[player] or 0) and profile.pens < capacity and made < 64 do
						local totalValue = profile.pens * profile.penValue + station.pen.value
						profile.pens += 1
						profile.penValue = totalValue / profile.pens
						made += 1
						nextProduce[player] = math.max((nextProduce[player] or now) + interval, now - interval)
					end
					if made > 0 then
						profile.dirty = true
						push(player)
					elseif profile.pens >= capacity and now >= (nextProduce[player] or 0) then
						nextProduce[player] = now + 1.5
						hint(player, now, "Je tas zit vol - ga pitchen bij de toonbank!")
					end
				end
			end

			local sellPad = pads["Sell_" .. station.key]
			if sellPad and isOnPad(root, sellPad) then
				if not stationUnlocked(profile, station) then
					hint(player, now, string.format("%s opent na rebirth %d", station.name, station.unlockRebirth))
				elseif profile.pens > 0 and not pitches[player] and now >= (nextSell[player] or 0) then
					nextSell[player] = now + SELL_COOLDOWN
					startPitch(player, profile, station.key)
				end
			end
		end

		-- upgrades op de plaat
		if now >= (nextUpgrade[player] or 0) then
			for _, up in Config.Upgrades do
				local padPart = pads["UpgradePad_" .. up.key]
				if padPart and isOnPad(root, padPart) then
					nextUpgrade[player] = now + UPGRADE_PAD_COOLDOWN
					buyUpgrade(player, up.key, true)
					break
				end
			end
		end

		local petPad = pads.PetPad
		if petPad and isOnPad(root, petPad) then
			hint(player, now, "Open 'Mascottes' rechtsonder om er een te kopen.")
		end

		-- rebirth: even blijven staan
		local rebirthPad = pads.RebirthPad
		if rebirthPad and isOnPad(root, rebirthPad) then
			local since = rebirthHeldSince[player]
			if not since then
				rebirthHeldSince[player] = now
			elseif now - since >= REBIRTH_HOLD then
				rebirthHeldSince[player] = nil
				rebirth(player)
			end
		else
			rebirthHeldSince[player] = nil
		end
	end

	-- --------------------------------------------------------------- start ----

	function Game.start()
		Net.init()

		local root = World.build()
		pads.RebirthPad = World.find(root, "RebirthPad") :: BasePart
		pads.PetPad = World.find(root, "PetPad") :: BasePart
		for _, up in Config.Upgrades do
			local p = World.find(root, "UpgradePad_" .. up.key)
			if p then
				pads["UpgradePad_" .. up.key] = p
			end
		end

		local spots: { [string]: BasePart } = {}
		for _, station in Config.Stations do
			local press = World.find(root, "Press_" .. station.key)
			local sell = World.find(root, "Sell_" .. station.key)
			local spot = World.find(root, "Spot_" .. station.key)
			if press then
				pads["Press_" .. station.key] = press
			end
			if sell then
				pads["Sell_" .. station.key] = sell
			end
			if spot then
				spots[station.key] = spot
			end
		end

		Customers.start(spots)
		Pets.start()
		Passes.start(function(player)
			push(player)
		end)
		Leaderboards.start(World.boardBody(root, "Board_cash"), World.boardBody(root, "Board_rebirths"))

		Net.event("BuyUpgrade").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				buyUpgrade(player, key)
			end
		end)
		Net.event("Rebirth").OnServerEvent:Connect(function(player)
			rebirth(player)
		end)
		Net.event("PitchAnswer").OnServerEvent:Connect(function(player, id, index)
			local profile = Data.get(player)
			local pitch = pitches[player]
			if not profile or not pitch then
				return
			end
			if typeof(id) ~= "number" or id ~= pitch.id then
				return
			end
			if typeof(index) ~= "number" then
				return
			end
			index = math.floor(index)
			if index < 1 or index > #pitch.options then
				return
			end
			finishPitch(player, profile, pitch, index)
		end)
		Net.event("BuyPet").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				buyPet(player, key)
			end
		end)
		Net.event("EquipPet").OnServerEvent:Connect(function(player, key)
			if key == nil or typeof(key) == "string" then
				equipPet(player, key)
			end
		end)
		Net.event("ClaimDaily").OnServerEvent:Connect(function(player)
			claimDaily(player)
		end)
		Net.event("RedeemCode").OnServerEvent:Connect(function(player, code)
			if typeof(code) == "string" and #code <= 40 then
				redeemCode(player, code)
			end
		end)
		Net.event("PromptPass").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				Passes.prompt(player, key)
			end
		end)

		Players.PlayerAdded:Connect(onPlayerAdded)
		Players.PlayerRemoving:Connect(onPlayerRemoving)
		for _, player in Players:GetPlayers() do
			task.spawn(onPlayerAdded, player)
		end

		Data.start()

		-- passief inkomen
		task.spawn(function()
			while true do
				task.wait(Config.Idle.payoutSeconds)
				for player, profile in Data.all() do
					local earned = passivePerSecond(player, profile) * Config.Idle.payoutSeconds
					if earned > 0 then
						profile.cash += earned
						profile.dirty = true
					end
					push(player)
				end
			end
		end)

		local acc = 0
		RunService.Heartbeat:Connect(function(dt)
			acc += dt
			if acc >= TICK then
				acc = 0
				local now = os.clock()
				for _, player in Players:GetPlayers() do
					stepPlayer(player, now)
				end
			end
		end)
	end

	return Game
end)()

-- ---- startpunt ----
--!strict
-- Startpunt op de server.
local Game = PEN.Game
Game.start()
