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

	-- ------------------------------------------------------------- bezoekers --
	-- Visitors komen los van de gewone klanten je terrein op. Hoe zeldzamer, hoe
	-- groter de bestelling en hoe veel meer ze betalen. Wie je getrade hebt komt
	-- in je index te staan en kun je daarna inhuren als personeel.

	Config.Rarities = {
		{
			key = "common", name = "Common", color = Color3.fromRGB(180, 186, 198),
			weight = 1000, payout = 3, orderMin = 8, orderMax = 16,
			wage = 250, workRate = 0.30, stamina = 100, announce = false,
		},
		{
			key = "rare", name = "Rare", color = Color3.fromRGB(90, 170, 255),
			weight = 380, payout = 7, orderMin = 14, orderMax = 26,
			wage = 1200, workRate = 0.55, stamina = 120, announce = false,
		},
		{
			key = "superrare", name = "Super Rare", color = Color3.fromRGB(60, 220, 200),
			weight = 140, payout = 15, orderMin = 22, orderMax = 40,
			wage = 6000, workRate = 0.95, stamina = 140, announce = false,
		},
		{
			key = "epic", name = "Epic", color = Color3.fromRGB(190, 110, 255),
			weight = 42, payout = 34, orderMin = 34, orderMax = 60,
			wage = 32000, workRate = 1.7, stamina = 170, announce = false,
		},
		{
			key = "mythic", name = "Mythic", color = Color3.fromRGB(255, 120, 190),
			weight = 11, payout = 85, orderMin = 50, orderMax = 90,
			wage = 180000, workRate = 3.0, stamina = 200, announce = false,
		},
		{
			key = "legendary", name = "Legendary", color = Color3.fromRGB(255, 196, 70),
			weight = 2.6, payout = 220, orderMin = 75, orderMax = 130,
			wage = 1100000, workRate = 5.5, stamina = 240, announce = true,
		},
		{
			key = "exotic", name = "Exotic", color = Color3.fromRGB(255, 96, 72),
			weight = 0.42, payout = 650, orderMin = 110, orderMax = 190,
			wage = 7500000, workRate = 10, stamina = 300, announce = true,
		},
		{
			key = "ultra", name = "Ultra Exotic", color = Color3.fromRGB(255, 240, 150),
			weight = 0.032, payout = 6000, orderMin = 160, orderMax = 260,
			wage = 90000000, workRate = 22, stamina = 400, announce = true,
		},
	}

	-- Kans per bezoeker: gewicht gedeeld door de som (ruim 1576).
	-- Ultra Exotic staat daarmee op ongeveer 1 op de 49.000 bezoekers.
	Config.Visit = {
		slots = 3,             -- hoeveel bezoekers er tegelijk kunnen staan
		spawnSeconds = 75,     -- hoe vaak een lege plek opnieuw geprobeerd wordt
		spawnChance = 0.55,    -- kans dat er dan echt iemand komt
		staySeconds = 260,     -- hoe lang een bezoeker blijft wachten
		luckPerRebirth = 0.04, -- elke rebirth maakt zeldzame bezoekers iets waarschijnlijker
		maxLuck = 2.5,
	}

	Config.Visitors = {
		-- common
		{ key = "joris",   name = "Joris Bakker",    rarity = "common", line = "Doe mij er maar een paar voor kantoor." },
		{ key = "aisha",   name = "Aisha Demir",     rarity = "common", line = "Mijn oude pen is op." },
		{ key = "stefan",  name = "Stefan de Wit",   rarity = "common", line = "Heb je er toevallig een stapel?" },
		{ key = "lotte",   name = "Lotte Prins",     rarity = "common", line = "Voor de hele klas, graag." },
		{ key = "hakim",   name = "Hakim Osei",      rarity = "common", line = "Snel wat schrijfwerk te doen." },
		-- rare
		{ key = "viktor",  name = "Viktor Halm",     rarity = "rare", line = "Ik teken vandaag een contract." },
		{ key = "noor",    name = "Noor Vermeer",    rarity = "rare", line = "Iets beters dan de kantoorpennen." },
		{ key = "dmitri",  name = "Dmitri Lasko",    rarity = "rare", line = "Voor mijn hele afdeling." },
		{ key = "sasha",   name = "Sasha Brandt",    rarity = "rare", line = "Ik betaal graag voor kwaliteit." },
		-- super rare
		{ key = "margot",  name = "Margot Feyn",     rarity = "superrare", line = "Mijn notulen verdienen beter." },
		{ key = "ren",     name = "Ren Takahara",    rarity = "superrare", line = "Vakmanschap herken ik meteen." },
		{ key = "olivier", name = "Olivier Sand",    rarity = "superrare", line = "Ik verzamel schrijfgerei." },
		-- epic
		{ key = "cassia",  name = "Cassia Moreau",   rarity = "epic", line = "Ik koop in bulk, of niet." },
		{ key = "theo",    name = "Theo Vandergriff", rarity = "epic", line = "Mijn galerie opent volgende week." },
		{ key = "iris",    name = "Iris Halvorsen",  rarity = "epic", line = "Alleen het bijzondere interesseert me." },
		-- mythic
		{ key = "dorian",  name = "Dorian Vex",      rarity = "mythic", line = "Ik betaal contant, en veel." },
		{ key = "solene",  name = "Solene Ward",     rarity = "mythic", line = "Verras me, dan verras ik jou." },
		-- legendary
		{ key = "augusta", name = "Augusta Kane",    rarity = "legendary", line = "Ik teken alleen met het beste." },
		{ key = "rafael",  name = "Rafael Quist",    rarity = "legendary", line = "Mijn handtekening is miljoenen waard." },
		-- exotic
		{ key = "veyra",   name = "Veyra Solheim",   rarity = "exotic", line = "Ik kom zelden de deur uit." },
		{ key = "orson",   name = "Orson Vale",      rarity = "exotic", line = "Noem je prijs. Ik betaal hem." },
		-- ultra exotic
		{ key = "beldan",  name = "Beldan Jolfort",  rarity = "ultra",
		  line = "Ik heb elke pen ter wereld gehad, op de jouwe na." },
	}

	-- ------------------------------------------------------------- personeel --
	Config.Staff = {
		baseSlots = 1,            -- hoeveel personeel je aan het begin kunt hebben
		slotsPerRebirth = 0.5,    -- elke twee rebirths een plek erbij
		maxSlots = 6,
		wagePeriod = 24 * 60 * 60, -- elke 24 uur wil iemand loon
		graceSeconds = 12 * 60 * 60, -- zo lang blijft hij nog na de vervaldag
		drainPerSecond = 0.035,   -- ongeveer 48 minuten werken op volle stamina
		recoverPerSecond = 0.05,
		resumeAt = 45,            -- uitgerust tot dit percentage, dan weer aan het werk
		hireCostFactor = 4,       -- inhuren kost dit maal het dagloon
	}

	function Config.getRarity(key: string)
		for _, r in Config.Rarities do
			if r.key == key then
				return r
			end
		end
		return Config.Rarities[1]
	end

	function Config.getVisitor(key: string)
		for _, v in Config.Visitors do
			if v.key == key then
				return v
			end
		end
		return nil
	end

	function Config.visitorsOfRarity(rarityKey: string)
		local out = {}
		for _, v in Config.Visitors do
			if v.rarity == rarityKey then
				table.insert(out, v)
			end
		end
		return out
	end

	-- Kans van 1 op hoeveel, voor in de index en de README.
	function Config.rarityOdds(rarityKey: string, luck: number): number
		local total = 0
		local mine = 0
		for _, r in Config.Rarities do
			local weight = r.weight
			if r.weight < 100 then
				weight *= luck
			end
			total += weight
			if r.key == rarityKey then
				mine = weight
			end
		end
		if mine <= 0 then
			return math.huge
		end
		return total / mine
	end

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

	function Config.getStation(key: string)
		for _, station in Config.Stations do
			if station.key == key then
				return station
			end
		end
		return nil
	end

	function Config.stationIndex(key: string): number
		for i, station in Config.Stations do
			if station.key == key then
				return i
			end
		end
		return 1
	end

	function Config.rarityIndex(key: string): number
		for i, r in Config.Rarities do
			if r.key == key then
				return i
			end
		end
		return 1
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
		local units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
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
		"Travel",
		"TradeVisitor",
		"HireStaff",
		"PayStaff",
		"FireStaff",
		-- server -> iedereen
		"Announce",
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
	b.TextSize = 13
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
status.Size = UDim2.new(0, 232, 0, 118)
status.Position = UDim2.new(0, 12, 0, 12)
status.BackgroundColor3 = DARK
status.BackgroundTransparency = 0.12
status.Parent = screen
corner(status, 14)
stroke(status, ACCENT, 1.5)

local cashLabel = text(status, "Cash", UDim2.new(1, -20, 0, 28), UDim2.new(0, 11, 0, 6), "$0", 22, GOLD)
local bagLabel = text(status, "Bag", UDim2.new(1, -20, 0, 18), UDim2.new(0, 11, 0, 34), "", 13)
local penLabel = text(status, "Pen", UDim2.new(1, -20, 0, 16), UDim2.new(0, 11, 0, 54), "", 12, ACCENT)
local passiveLabel = text(status, "Passive", UDim2.new(1, -20, 0, 16), UDim2.new(0, 11, 0, 72), "", 12, TEAL)
local metaLabel = text(status, "Meta", UDim2.new(1, -20, 0, 16), UDim2.new(0, 11, 0, 90), "", 12, PURPLE)

-- ------------------------------------------------------------ upgraderij ---

local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Size = UDim2.new(0, 600, 0, 88)
shop.Position = UDim2.new(0.5, -300, 1, -98)
shop.BackgroundTransparency = 1
shop.Parent = screen

local shopLayout = Instance.new("UIListLayout")
shopLayout.FillDirection = Enum.FillDirection.Horizontal
shopLayout.Padding = UDim.new(0, 6)
shopLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shop

local upgradeButtons: { [string]: { title: TextLabel, sub: TextLabel, price: TextLabel } } = {}

for i, up in Config.Upgrades do
	local btn = Instance.new("TextButton")
	btn.Name = up.key
	btn.LayoutOrder = i
	btn.Size = UDim2.new(0, 116, 1, 0)
	btn.BackgroundColor3 = DARK
	btn.BackgroundTransparency = 0.12
	btn.Text = ""
	btn.Parent = shop
	corner(btn, 14)
	stroke(btn, GOLD, 1.5)

	local title = text(btn, "Title", UDim2.new(1, -12, 0, 16), UDim2.new(0, 6, 0, 6), up.name, 12, GOLD)
	local sub = text(btn, "Sub", UDim2.new(1, -12, 0, 36), UDim2.new(0, 6, 0, 24), up.info, 11)
	sub.Font = Enum.Font.Gotham
	sub.TextWrapped = true
	local price = text(btn, "Price", UDim2.new(1, -12, 0, 18), UDim2.new(0, 6, 1, -22), "", 13, GREEN)

	btn.Activated:Connect(function()
		Net.event("BuyUpgrade"):FireServer(up.key)
	end)
	upgradeButtons[up.key] = { title = title, sub = sub, price = price }
end

-- ------------------------------------------------------------- knoppenrij --

local sideBar = Instance.new("Frame")
sideBar.Name = "SideBar"
sideBar.Size = UDim2.new(0, 148, 0, 232)
sideBar.Position = UDim2.new(1, -160, 1, -286)
sideBar.BackgroundTransparency = 1
sideBar.Parent = screen

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 5)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = sideBar

local rebirthBtn = button(sideBar, "Rebirth", UDim2.new(1, 0, 0, 50), UDim2.new(), "Rebirth", PURPLE)
rebirthBtn.LayoutOrder = 1
rebirthBtn.TextWrapped = true
rebirthBtn.RichText = true
rebirthBtn.TextSize = 11
local dailyBtn = button(sideBar, "Daily", UDim2.new(1, 0, 0, 30), UDim2.new(), "Dagbeloning", GREEN)
dailyBtn.LayoutOrder = 2
dailyBtn.TextSize = 11

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.Size = UDim2.new(1, 0, 0, 138)
menu.BackgroundTransparency = 1
menu.LayoutOrder = 3
menu.Parent = sideBar

local menuGrid = Instance.new("UIGridLayout")
menuGrid.CellSize = UDim2.new(0, 71, 0, 30)
menuGrid.CellPadding = UDim2.new(0, 6, 0, 5)
menuGrid.SortOrder = Enum.SortOrder.LayoutOrder
menuGrid.Parent = menu

local function menuButton(name: string, label: string, color: Color3, order: number): TextButton
	local b = button(menu, name, UDim2.new(0, 71, 0, 30), UDim2.new(), label, color)
	b.LayoutOrder = order
	b.TextSize = 11
	b.TextWrapped = true
	return b
end

local visitorBtn = menuButton("Visitors", "Bezoekers", Color3.fromRGB(255, 196, 70), 1)
local indexBtn = menuButton("Index", "Index", Color3.fromRGB(190, 110, 255), 2)
local staffBtn = menuButton("Staff", "Personeel", Color3.fromRGB(120, 230, 160), 3)
local petBtn = menuButton("Pets", "Mascottes", TEAL, 4)
local codeBtn = menuButton("Codes", "Codes", GOLD, 5)
local passBtn = menuButton("Passes", "Extra's", ACCENT, 6)
local travelBtn = menuButton("Travel", "Reizen", Color3.fromRGB(160, 200, 255), 7)

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
	holder.Size = UDim2.new(0, 372, 0, height)
	holder.Position = UDim2.new(0.5, -186, 0.5, -height / 2)
	holder.BackgroundColor3 = DARK
	holder.BackgroundTransparency = 0.05
	holder.Visible = false
	holder.ZIndex = 5
	holder.Parent = screen
	corner(holder, 16)
	stroke(holder, ACCENT, 1.5)

	local header = text(holder, "Header", UDim2.new(1, -52, 0, 28), UDim2.new(0, 13, 0, 8), title, 18, WHITE)
	header.ZIndex = 6

	local close = button(holder, "Close", UDim2.new(0, 28, 0, 28), UDim2.new(1, -38, 0, 8), "X", RED)
	close.ZIndex = 6
	close.Activated:Connect(function()
		holder.Visible = false
	end)

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -20, 1, -48)
	body.Position = UDim2.new(0, 10, 0, 42)
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

local petPanel, petBody = makePanel("Mascottes", 340)
local travelPanel, travelBody = makePanel("Reizen", 340)
local visitorPanel, visitorBody = makePanel("Bezoekers", 360)
local indexPanel, indexBody = makePanel("Bezoekersindex", 400)
local staffPanel, staffBody = makePanel("Personeel", 360)
local codePanel, codeBody = makePanel("Codes", 208)
local passPanel, passBody = makePanel("Extra's", 280)

local function toggle(panel: Frame)
	local wasVisible = panel.Visible
	petPanel.Visible = false
	codePanel.Visible = false
	passPanel.Visible = false
	travelPanel.Visible = false
	visitorPanel.Visible = false
	indexPanel.Visible = false
	staffPanel.Visible = false
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
travelBtn.Activated:Connect(function()
	toggle(travelPanel)
end)
visitorBtn.Activated:Connect(function()
	toggle(visitorPanel)
end)
indexBtn.Activated:Connect(function()
	toggle(indexPanel)
end)
staffBtn.Activated:Connect(function()
	toggle(staffPanel)
end)

-- codes-paneel
local codeBox = Instance.new("TextBox")
codeBox.Name = "Input"
codeBox.Size = UDim2.new(1, -10, 0, 36)
codeBox.BackgroundColor3 = PANEL
codeBox.Font = Enum.Font.GothamBold
codeBox.TextSize = 14
codeBox.TextColor3 = WHITE
codeBox.PlaceholderText = "typ hier je code"
codeBox.Text = ""
codeBox.ClearTextOnFocus = false
codeBox.ZIndex = 6
codeBox.LayoutOrder = 1
codeBox.Parent = codeBody
corner(codeBox, 12)
stroke(codeBox, GOLD, 1.5)

local codeSubmit = button(codeBody, "Submit", UDim2.new(1, -10, 0, 34), UDim2.new(), "Inwisselen", GREEN)
codeSubmit.LayoutOrder = 2
codeSubmit.ZIndex = 6
local codeHint = text(codeBody, "Hint", UDim2.new(1, -10, 0, 52), UDim2.new(),
	"Codes deel je zelf uit, bijvoorbeeld in de beschrijving van de game of op je socials.", 12, Color3.fromRGB(170, 175, 190))
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
toasts.Size = UDim2.new(0, 252, 0, 240)
toasts.Position = UDim2.new(1, -264, 0, 12)
toasts.BackgroundTransparency = 1
toasts.Parent = screen

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toasts

local toastOrder = 0

local function showToast(message: string, color: Color3)
	toastOrder += 1
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 38)
	frame.LayoutOrder = toastOrder
	frame.BackgroundColor3 = DARK
	frame.BackgroundTransparency = 0.1
	frame.Parent = toasts
	corner(frame, 12)
	stroke(frame, color, 1.5)

	local tl = text(frame, "Text", UDim2.new(1, -16, 1, -6), UDim2.new(0, 8, 0, 3), message, 12, color)
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

-- --------------------------------------------------------- aankondiging ---

local banner = Instance.new("Frame")
banner.Name = "Announce"
banner.Size = UDim2.new(0, 620, 0, 66)
banner.Position = UDim2.new(0.5, -310, 0, -80)
banner.BackgroundColor3 = DARK
banner.BackgroundTransparency = 0.05
banner.Visible = false
banner.ZIndex = 20
banner.Parent = screen
corner(banner, 14)
local bannerStroke = stroke(banner, GOLD, 2.5)

local bannerText = text(banner, "Text", UDim2.new(1, -24, 1, -10), UDim2.new(0, 12, 0, 5), "", 20, WHITE)
bannerText.TextXAlignment = Enum.TextXAlignment.Center
bannerText.TextYAlignment = Enum.TextYAlignment.Center
bannerText.TextWrapped = true
bannerText.ZIndex = 21

local bannerToken = 0

local function showBanner(message: string, color: Color3)
	bannerToken += 1
	local token = bannerToken
	bannerText.Text = message
	bannerText.TextColor3 = color
	bannerStroke.Color = color
	banner.Visible = true
	banner.Position = UDim2.new(0.5, -310, 0, -80)
	TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -310, 0, 16),
	}):Play()
	task.delay(6, function()
		if bannerToken ~= token then
			return
		end
		local out = TweenService:Create(banner, TweenInfo.new(0.4), { Position = UDim2.new(0.5, -310, 0, -90) })
		out:Play()
		out.Completed:Wait()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

Net.event("Announce").OnClientEvent:Connect(function(info)
	showBanner(info.text, info.color or GOLD)
end)

-- ----------------------------------------------------------------- pitch ---

local pitchFrame = Instance.new("Frame")
pitchFrame.Name = "Pitch"
pitchFrame.Size = UDim2.new(0, 496, 0, 244)
pitchFrame.Position = UDim2.new(0.5, -248, 0.5, -140)
pitchFrame.BackgroundColor3 = DARK
pitchFrame.BackgroundTransparency = 0.05
pitchFrame.Visible = false
pitchFrame.ZIndex = 8
pitchFrame.Parent = screen
corner(pitchFrame, 16)
local pitchStroke = stroke(pitchFrame, GREEN, 2)

local pitchWho = text(pitchFrame, "Who", UDim2.new(1, -26, 0, 22), UDim2.new(0, 13, 0, 10), "", 16, GOLD)
pitchWho.ZIndex = 9
local pitchLine = text(pitchFrame, "Line", UDim2.new(1, -26, 0, 26), UDim2.new(0, 13, 0, 32), "", 18, WHITE)
pitchLine.ZIndex = 9
local pitchInfo = text(pitchFrame, "Info", UDim2.new(1, -26, 0, 18), UDim2.new(0, 13, 0, 60), "", 12, TEAL)
pitchInfo.ZIndex = 9

local timerBack = Instance.new("Frame")
timerBack.Size = UDim2.new(1, -26, 0, 6)
timerBack.Position = UDim2.new(0, 13, 0, 82)
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
optionHolder.Size = UDim2.new(1, -26, 0, 136)
optionHolder.Position = UDim2.new(0, 13, 0, 96)
optionHolder.BackgroundTransparency = 1
optionHolder.ZIndex = 9
optionHolder.Parent = pitchFrame

local optionLayout = Instance.new("UIListLayout")
optionLayout.Padding = UDim.new(0, 6)
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
		local btn = button(optionHolder, "Option" .. index, UDim2.new(1, 0, 0, 38), UDim2.new(), option, WHITE)
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
	local panel, body = makePanel("Terwijl je weg was", 200)
	local hours = math.floor(info.seconds / 3600)
	local minutes = math.floor((info.seconds % 3600) / 60)
	local line = text(body, "Line", UDim2.new(1, -10, 0, 76), UDim2.new(),
		string.format("Je zaken draaiden %du %dm door.\n\n<font color=\"rgb(120,255,150)\">+$%s</font>",
			hours, minutes, Config.short(info.earned)), 16, WHITE)
	line.TextWrapped = true
	line.LayoutOrder = 1
	line.ZIndex = 6
	if info.capped then
		local capLine = text(body, "Cap", UDim2.new(1, -10, 0, 50), UDim2.new(),
			string.format("Offline verdienen telt tot %d uur.", info.capHours), 12, GOLD)
		capLine.TextWrapped = true
		capLine.LayoutOrder = 2
		capLine.ZIndex = 6
	end
	panel.Visible = true
end)

-- ------------------------------------------------- bezoekers in de wereld --
-- De bezoekers zijn persoonlijk, dus de client zet ze zelf neer. Andere
-- spelers zien jouw bezoekers niet.

local visitorFolder = Instance.new("Folder")
visitorFolder.Name = "PenVisitors"
visitorFolder.Parent = workspace

local visitorModels: { [number]: Model } = {}

local function findSpot(station: string, slot: number): BasePart?
	local world = workspace:FindFirstChild("PenWorld")
	if not world then
		return nil
	end
	local spot = world:FindFirstChild(string.format("VisitorSpot%d_%s", slot, station), true)
	if spot and spot:IsA("BasePart") then
		return spot
	end
	return nil
end

local function limb(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function buildVisitor(info, spot: BasePart): Model
	local model = Instance.new("Model")
	model.Name = "Visitor_" .. info.name

	local rarityColor = info.rarityColor or WHITE
	local facing = spot.CFrame
	local skin = Color3.fromRGB(236, 202, 160)

	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), facing * CFrame.new(0, 3, 0), rarityColor)
	limb(model, "Head", Vector3.new(1.4, 1.4, 1.4), facing * CFrame.new(0, 4.6, 0), skin)
	limb(model, "ArmL", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(-1.4, 3, 0), skin)
	limb(model, "ArmR", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(1.4, 3, 0), skin)
	limb(model, "LegL", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(-0.55, 1, 0), Color3.fromRGB(34, 36, 48))
	limb(model, "LegR", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(0.55, 1, 0), Color3.fromRGB(34, 36, 48))

	-- ring op de grond in de kleur van de zeldzaamheid
	local ring = limb(model, "Ring", Vector3.new(6, 0.2, 6), facing * CFrame.new(0, 0.1, 0), rarityColor)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.35

	model.PrimaryPart = torso

	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromScale(11, 3.6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 70
	gui.Adornee = torso
	gui.Parent = torso

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = DARK
	frame.BackgroundTransparency = 0.25
	frame.Parent = gui
	corner(frame, 10)
	stroke(frame, rarityColor, 2)

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, -10, 1, -6)
	label.Position = UDim2.new(0, 5, 0, 3)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = WHITE
	label.RichText = true
	label.TextWrapped = true
	label.Text = ""
	label.Parent = frame

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Trade"
	prompt.ActionText = "Traden"
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso
	prompt.Triggered:Connect(function()
		Net.event("TradeVisitor"):FireServer(info.id)
	end)

	return model
end

local function visitorText(info): string
	local col = info.rarityColor or WHITE
	local rgb = string.format("rgb(%d,%d,%d)", math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255))
	local statusColor = info.canTrade and "rgb(120,255,150)" or "rgb(255,170,170)"
	return string.format(
		'<b>%s</b>  <font color="%s">%s</font>\nwil %d x %s  ·  <font color="%s">jij hebt %d</font>\n$%s',
		info.name, rgb, info.rarityName, info.amount, info.penName, statusColor, info.have,
		Config.short(info.payout)
	)
end

local function syncVisitors()
	if not state then
		return
	end
	local wanted = {}
	for _, info in state.visitors do
		wanted[info.id] = info
	end
	for id, model in visitorModels do
		if not wanted[id] then
			model:Destroy()
			visitorModels[id] = nil
		end
	end
	for id, info in wanted do
		local model = visitorModels[id]
		if not model then
			local spot = findSpot(info.station, info.slot)
			if spot then
				model = buildVisitor(info, spot)
				model.Parent = visitorFolder
				visitorModels[id] = model
			end
		end
		if model then
			local torso = model.PrimaryPart
			local gui = torso and torso:FindFirstChild("Info")
			local frame = gui and gui:FindFirstChildOfClass("Frame")
			local label = frame and frame:FindFirstChild("Text")
			if label and label:IsA("TextLabel") then
				label.Text = visitorText(info)
			end
		end
	end
end

-- ------------------------------------------------------- bouwputten weg ---
-- Zaken die jij nog niet hebt vrijgespeeld staan in de steigers. Zodra jij ze
-- opent haalt de client de bouwput weg - alleen voor jou, want rebirths zijn
-- persoonlijk en de wereld is gedeeld.

local hiddenSites: { [string]: { folder: Instance, parent: Instance } } = {}

local function syncConstruction()
	if not state then
		return
	end
	local world = workspace:FindFirstChild("PenWorld")
	if not world then
		return
	end
	for _, station in state.stations do
		local stationFolder = world:FindFirstChild("Station_" .. station.key)
		if stationFolder then
			if station.unlocked then
				local site = stationFolder:FindFirstChild("Construction")
				if site then
					hiddenSites[station.key] = { folder = site, parent = stationFolder }
					site.Parent = nil
				end
			else
				local hidden = hiddenSites[station.key]
				if hidden and not hidden.folder.Parent then
					hidden.folder.Parent = hidden.parent
					hiddenSites[station.key] = nil
				end
			end
		end
	end
end

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
		row.Size = UDim2.new(1, -10, 0, 50)
		row.LayoutOrder = index
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = petBody
		corner(row, 12)
		stroke(row, pet.equipped and GREEN or TEAL, 1.5)

		local title = text(row, "Title", UDim2.new(1, -112, 0, 18), UDim2.new(0, 10, 0, 6), pet.name, 14, TEAL)
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -112, 0, 16), UDim2.new(0, 10, 0, 26),
			string.format("+%d%% maken  ·  +%d%% waarde", math.floor(pet.produce * 100), math.floor(pet.value * 100)),
			12, Color3.fromRGB(180, 185, 200))
		sub.Font = Enum.Font.Gotham
		sub.ZIndex = 7

		local label = pet.equipped and "Gedragen" or (pet.owned and "Dragen" or ("$" .. Config.short(pet.price)))
		local color = pet.equipped and GREEN or (pet.owned and GOLD or (state.cash >= pet.price and GREEN or RED))
		local act = button(row, "Act", UDim2.new(0, 94, 0, 32), UDim2.new(1, -104, 0, 9), label, color)
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

local function renderTravel()
	if not state then
		return
	end
	for _, child in travelBody:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for index, station in state.stations do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 46)
		row.LayoutOrder = index
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = travelBody
		corner(row, 12)
		stroke(row, station.unlocked and GREEN or Color3.fromRGB(110, 115, 130), 1.5)

		local title = text(row, "Title", UDim2.new(1, -106, 0, 18), UDim2.new(0, 10, 0, 6),
			string.format("%d. %s", station.index, station.name), 14,
			station.unlocked and WHITE or Color3.fromRGB(150, 155, 170))
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -106, 0, 16), UDim2.new(0, 10, 0, 25),
			station.unlocked and string.format("%s - $%s per pen", station.penName, Config.short(station.penValue))
				or string.format("opent na rebirth %d", station.unlockRebirth),
			12, Color3.fromRGB(180, 185, 200))
		sub.Font = Enum.Font.Gotham
		sub.ZIndex = 7

		if station.unlocked then
			local go = button(row, "Go", UDim2.new(0, 88, 0, 32), UDim2.new(1, -98, 0, 7), "Ga erheen", GREEN)
			go.ZIndex = 7
			go.Activated:Connect(function()
				Net.event("Travel"):FireServer(station.key)
				travelPanel.Visible = false
			end)
		end
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
		row.Size = UDim2.new(1, -10, 0, 56)
		row.LayoutOrder = index
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = passBody
		corner(row, 12)
		stroke(row, ACCENT, 1.5)

		local title = text(row, "Title", UDim2.new(1, -112, 0, 18), UDim2.new(0, 10, 0, 8), pass.name, 14, ACCENT)
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -112, 0, 24), UDim2.new(0, 10, 0, 26), pass.info, 12,
			Color3.fromRGB(180, 185, 200))
		sub.Font = Enum.Font.Gotham
		sub.TextWrapped = true
		sub.ZIndex = 7

		local label = pass.owned and "In bezit" or (pass.configured and "Kopen" or "Nog niet ingesteld")
		local color = pass.owned and GREEN or (pass.configured and GOLD or Color3.fromRGB(150, 155, 170))
		local act = button(row, "Act", UDim2.new(0, 94, 0, 34), UDim2.new(1, -104, 0, 11), label, color)
		act.ZIndex = 7
		act.TextWrapped = true
		act.Activated:Connect(function()
			if not pass.owned and pass.configured then
				Net.event("PromptPass"):FireServer(pass.key)
			end
		end)
	end
end

local function clearBody(body: Instance)
	for _, child in body:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function rarityRGB(color: Color3): string
	return string.format("rgb(%d,%d,%d)", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function renderVisitors()
	if not state then
		return
	end
	clearBody(visitorBody)
	if #state.visitors == 0 then
		local leeg = text(visitorBody, "Leeg", UDim2.new(1, -10, 0, 60), UDim2.new(),
			"Er staat nu niemand op je terrein.\nEr komt vanzelf weer iemand langs.", 13,
			Color3.fromRGB(170, 175, 190))
		leeg.TextWrapped = true
		leeg.ZIndex = 6
		return
	end
	for order, info in state.visitors do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 62)
		row.LayoutOrder = order
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = visitorBody
		corner(row, 12)
		stroke(row, info.rarityColor or WHITE, 2)

		local title = text(row, "Title", UDim2.new(1, -108, 0, 18), UDim2.new(0, 10, 0, 6),
			string.format('%s  <font color="%s">%s</font>', info.name, rarityRGB(info.rarityColor or WHITE),
				info.rarityName), 13, WHITE)
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -108, 0, 32), UDim2.new(0, 10, 0, 24),
			string.format("wil %d x %s (jij hebt %d)\nbetaalt $%s", info.amount, info.penName, info.have,
				Config.short(info.payout)), 12, Color3.fromRGB(190, 195, 210))
		sub.Font = Enum.Font.Gotham
		sub.ZIndex = 7

		local act = button(row, "Act", UDim2.new(0, 88, 0, 34), UDim2.new(1, -98, 0, 14),
			info.canTrade and "Traden" or "Te weinig", info.canTrade and GREEN or RED)
		act.ZIndex = 7
		act.Activated:Connect(function()
			Net.event("TradeVisitor"):FireServer(info.id)
		end)
	end
end

local function renderIndex()
	if not state then
		return
	end
	clearBody(indexBody)
	local unlocked = 0
	for _, row in state.indexRows do
		if row.traded > 0 then
			unlocked += 1
		end
	end
	local head = text(indexBody, "Head", UDim2.new(1, -10, 0, 22), UDim2.new(),
		string.format("%d van de %d bezoekers gevonden", unlocked, #state.indexRows), 13, GOLD)
	head.LayoutOrder = 0
	head.ZIndex = 6

	for order, info in state.indexRows do
		local known = info.traded > 0
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 44)
		row.LayoutOrder = order
		row.BackgroundColor3 = PANEL
		row.BackgroundTransparency = known and 0 or 0.45
		row.ZIndex = 6
		row.Parent = indexBody
		corner(row, 10)
		stroke(row, info.rarityColor or WHITE, known and 1.8 or 1)

		local title = text(row, "Title", UDim2.new(1, -104, 0, 17), UDim2.new(0, 10, 0, 5),
			known and info.name or "???", 13, known and WHITE or Color3.fromRGB(130, 135, 150))
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -104, 0, 16), UDim2.new(0, 10, 0, 22),
			string.format('<font color="%s">%s</font>  ·  1 op %s%s', rarityRGB(info.rarityColor or WHITE),
				info.rarityName, Config.short(info.odds),
				known and string.format("  ·  %dx getrade", info.traded) or ""),
			11, Color3.fromRGB(180, 185, 200))
		sub.Font = Enum.Font.Gotham
		sub.ZIndex = 7

		if known and not info.hired then
			local hire = button(row, "Hire", UDim2.new(0, 84, 0, 28), UDim2.new(1, -94, 0, 8),
				"$" .. Config.short(info.hireCost), state.cash >= info.hireCost and GREEN or RED)
			hire.ZIndex = 7
			hire.Activated:Connect(function()
				Net.event("HireStaff"):FireServer(info.key)
			end)
		elseif known then
			local badge = text(row, "Badge", UDim2.new(0, 84, 0, 28), UDim2.new(1, -94, 0, 10), "in dienst", 12, GREEN)
			badge.TextXAlignment = Enum.TextXAlignment.Center
			badge.ZIndex = 7
		end
	end
end

local function renderStaff()
	if not state then
		return
	end
	clearBody(staffBody)
	local head = text(staffBody, "Head", UDim2.new(1, -10, 0, 36), UDim2.new(),
		string.format("%d van de %d plekken bezet  ·  samen %.1f pennen/sec\nInhuren doe je in de index.",
			#state.staff, state.staffSlots, state.staffRate), 12, TEAL)
	head.LayoutOrder = 0
	head.TextWrapped = true
	head.ZIndex = 6

	if #state.staff == 0 then
		local leeg = text(staffBody, "Leeg", UDim2.new(1, -10, 0, 50), UDim2.new(),
			"Nog niemand in dienst. Trade met een bezoeker en huur hem daarna in via de index.",
			12, Color3.fromRGB(170, 175, 190))
		leeg.LayoutOrder = 1
		leeg.TextWrapped = true
		leeg.ZIndex = 6
		return
	end

	for order, member in state.staff do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 66)
		row.LayoutOrder = order
		row.BackgroundColor3 = PANEL
		row.ZIndex = 6
		row.Parent = staffBody
		corner(row, 12)
		stroke(row, member.rarityColor or WHITE, 1.8)

		local hours = math.floor(math.max(0, member.wageDueIn) / 3600)
		local minutes = math.floor((math.max(0, member.wageDueIn) % 3600) / 60)
		local loonTekst = member.wageDueIn <= 0
			and '<font color="rgb(255,150,150)">loon te laat!</font>'
			or string.format("loon over %du %dm", hours, minutes)

		local title = text(row, "Title", UDim2.new(1, -104, 0, 17), UDim2.new(0, 10, 0, 6),
			string.format('%s  <font color="%s">%s</font>', member.name,
				rarityRGB(member.rarityColor or WHITE), member.rarityName), 13, WHITE)
		title.ZIndex = 7
		local sub = text(row, "Sub", UDim2.new(1, -104, 0, 38), UDim2.new(0, 10, 0, 24),
			string.format("%s  ·  %.1f pennen/sec\nstamina %d/%d  ·  %s",
				member.resting and "rust uit" or "aan het werk", member.workRate,
				member.stamina, member.maxStamina, loonTekst), 11, Color3.fromRGB(190, 195, 210))
		sub.Font = Enum.Font.Gotham
		sub.ZIndex = 7

		local pay = button(row, "Pay", UDim2.new(0, 88, 0, 28), UDim2.new(1, -98, 0, 6),
			"Loon $" .. Config.short(member.wage), state.cash >= member.wage and GREEN or RED)
		pay.ZIndex = 7
		pay.Activated:Connect(function()
			Net.event("PayStaff"):FireServer(member.key)
		end)

		local fire = button(row, "Fire", UDim2.new(0, 88, 0, 24), UDim2.new(1, -98, 0, 36), "Ontslaan", RED)
		fire.ZIndex = 7
		fire.Activated:Connect(function()
			Net.event("FireStaff"):FireServer(member.key)
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
	metaLabel.Text = string.format("Rebirths: %d  ·  streak: %d  ·  bezoekers: %d",
		state.rebirths, state.pitchStreak, #state.visitors)
	visitorBtn.Text = #state.visitors > 0 and string.format("Bezoekers (%d)", #state.visitors) or "Bezoekers"

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
	if travelPanel.Visible then
		renderTravel()
	end
	if visitorPanel.Visible then
		renderVisitors()
	end
	if indexPanel.Visible then
		renderIndex()
	end
	if staffPanel.Visible then
		renderStaff()
	end
end

petBtn.Activated:Connect(renderPets)
passBtn.Activated:Connect(renderPasses)
travelBtn.Activated:Connect(renderTravel)
visitorBtn.Activated:Connect(renderVisitors)
indexBtn.Activated:Connect(renderIndex)
staffBtn.Activated:Connect(renderStaff)

Net.event("StateChanged").OnClientEvent:Connect(function(newState)
	state = newState
	render()
	syncVisitors()
	syncConstruction()
end)

Net.event("Notify").OnClientEvent:Connect(function(message, color)
	showToast(message, color or WHITE)
end)

-- de wereld kan later inladen (StreamingEnabled), dus blijven kijken
task.spawn(function()
	while true do
		task.wait(4)
		syncConstruction()
	end
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
