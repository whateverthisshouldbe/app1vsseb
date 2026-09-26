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
		bag: { [string]: number },   -- pennen per soort zaak
		rebirths: number,
		totalSold: number,
		upgrades: { [string]: number },
		pets: { [string]: boolean },
		equippedPet: string?,
		dailyStreak: number,
		lastDailyAt: number,
		redeemed: { [string]: boolean },
		index: { [string]: number },          -- bezoekers die je getrade hebt
		staff: { { key: string, stamina: number, lastPaidAt: number } },
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
			bag = {},
			rebirths = 0,
			totalSold = 0,
			upgrades = upgrades,
			pets = {},
			equippedPet = nil,
			dailyStreak = 0,
			lastDailyAt = 0,
			redeemed = {},
			index = {},
			staff = {},
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
		if typeof(raw.bag) == "table" then
			for _, station in Config.Stations do
				local amount = math.floor(tonumber(raw.bag[station.key]) or 0)
				if amount > 0 then
					p.bag[station.key] = amount
				end
			end
		elseif tonumber(raw.pens) then
			-- opslag van voor de bezoekers-update: alles telt als pennen van de kraam
			local amount = math.max(0, math.floor(tonumber(raw.pens) or 0))
			if amount > 0 then
				p.bag[Config.Stations[1].key] = amount
			end
		end
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
		if typeof(raw.index) == "table" then
			for _, visitor in Config.Visitors do
				local traded = math.floor(tonumber(raw.index[visitor.key]) or 0)
				if traded > 0 then
					p.index[visitor.key] = traded
				end
			end
		end
		if typeof(raw.staff) == "table" then
			for _, entry in raw.staff do
				if typeof(entry) == "table" and typeof(entry.key) == "string"
					and Config.getVisitor(entry.key) and p.index[entry.key] then
					table.insert(p.staff, {
						key = entry.key,
						stamina = math.clamp(tonumber(entry.stamina) or 100, 0, 1000),
						lastPaidAt = math.max(0, math.floor(tonumber(entry.lastPaidAt) or 0)),
					})
				end
			end
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
			bag = profile.bag,
			rebirths = profile.rebirths,
			totalSold = profile.totalSold,
			upgrades = profile.upgrades,
			pets = profile.pets,
			equippedPet = profile.equippedPet,
			dailyStreak = profile.dailyStreak,
			lastDailyAt = profile.lastDailyAt,
			redeemed = profile.redeemed,
			index = profile.index,
			staff = profile.staff,
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

PEN.Scenery = (function()
	--!strict
	-- Bouwstenen voor de aankleding: gevels met ramen, lantaarns, bomen, banken,
	-- luifels, fonteinen, neonborden. Alles met code, geen assets nodig.

	local Scenery = {}

	Scenery.Palette = {
		asphalt      = Color3.fromRGB(56, 56, 64),
		asphaltLine  = Color3.fromRGB(222, 206, 140),
		sidewalk     = Color3.fromRGB(196, 190, 178),
		curb         = Color3.fromRGB(162, 156, 146),
		grass        = Color3.fromRGB(94, 138, 74),
		brick        = Color3.fromRGB(150, 82, 64),
		plaster      = Color3.fromRGB(232, 216, 190),
		plasterWarm  = Color3.fromRGB(216, 176, 132),
		wood         = Color3.fromRGB(140, 96, 58),
		woodDark     = Color3.fromRGB(96, 64, 40),
		metal        = Color3.fromRGB(148, 152, 160),
		metalDark    = Color3.fromRGB(78, 84, 96),
		glass        = Color3.fromRGB(150, 200, 220),
		windowLit    = Color3.fromRGB(255, 226, 158),
		windowDark   = Color3.fromRGB(70, 92, 112),
		awningA      = Color3.fromRGB(196, 62, 58),
		awningB      = Color3.fromRGB(244, 234, 214),
		teal         = Color3.fromRGB(46, 138, 134),
		neonPink     = Color3.fromRGB(255, 92, 150),
		neonCyan     = Color3.fromRGB(96, 226, 255),
		gold         = Color3.fromRGB(240, 196, 96),
		foliage      = Color3.fromRGB(74, 124, 64),
		foliageLight = Color3.fromRGB(104, 152, 78),
		water        = Color3.fromRGB(64, 156, 196),
		skylineFar   = Color3.fromRGB(104, 112, 134),
	}

	local P = Scenery.Palette

	-- ------------------------------------------------------------- basisdelen --

	function Scenery.part(props: { [string]: any }, parent: Instance): Part
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

	function Scenery.decor(props: { [string]: any }, parent: Instance): Part
		props.CanCollide = props.CanCollide == nil and false or props.CanCollide
		return Scenery.part(props, parent)
	end

	function Scenery.wedge(props: { [string]: any }, parent: Instance): WedgePart
		local p = Instance.new("WedgePart")
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		for k, v in props do
			(p :: any)[k] = v
		end
		p.Parent = parent
		return p
	end

	function Scenery.cylinder(props: { [string]: any }, parent: Instance): Part
		props.Shape = Enum.PartType.Cylinder
		return Scenery.part(props, parent)
	end

	function Scenery.ball(props: { [string]: any }, parent: Instance): Part
		props.Shape = Enum.PartType.Ball
		return Scenery.part(props, parent)
	end

	-- --------------------------------------------------------------- teksten ---

	-- Tekst plat op een muur (blijft leesbaar van veraf, kost geen assets).
	function Scenery.wallText(cf: CFrame, width: number, height: number, message: string,
		color: Color3, parent: Instance): Part
		local plate = Scenery.decor({
			Name = "SignPlate",
			Size = Vector3.new(width, height, 0.4),
			CFrame = cf,
			Color = Color3.fromRGB(24, 26, 34),
			Material = Enum.Material.SmoothPlastic,
		}, parent)

		local surface = Instance.new("SurfaceGui")
		surface.Name = "Sign"
		surface.Face = Enum.NormalId.Front
		surface.CanvasSize = Vector2.new(math.floor(width * 20), math.floor(height * 20))
		surface.LightInfluence = 0
		surface.MaxDistance = 200
		surface.Parent = plate

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextColor3 = color
		tl.RichText = true
		tl.Text = message
		tl.Parent = surface

		-- randje neon eromheen
		Scenery.decor({
			Name = "SignEdge",
			Size = Vector3.new(width + 0.8, height + 0.8, 0.2),
			CFrame = cf * CFrame.new(0, 0, 0.2),
			Color = color,
			Material = Enum.Material.Neon,
		}, parent)

		return plate
	end

	function Scenery.floatingText(adornee: BasePart, message: string, offsetY: number, size: number, distance: number?)
		local gui = Instance.new("BillboardGui")
		gui.Name = "Label"
		gui.Size = UDim2.fromScale(11, 2.8)
		gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
		-- niet meer door muren heen, en pas leesbaar als je in de buurt staat
		gui.AlwaysOnTop = false
		gui.MaxDistance = distance or 55
		gui.Parent = adornee

		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = size
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextStrokeTransparency = 0.3
		tl.TextStrokeColor3 = Color3.new(0, 0, 0)
		tl.RichText = true
		tl.Text = message
		tl.Parent = gui
		return tl
	end

	-- ----------------------------------------------------------------- gevels --

	-- Ramen op een muur. `cf` staat midden op de muur en kijkt naar buiten (+Z).
	function Scenery.windows(cf: CFrame, width: number, height: number, cols: number, rows: number,
		litChance: number, parent: Instance)
		local marginX = width / (cols + 1)
		local marginY = height / (rows + 1)
		local paneW = math.min(marginX * 0.78, 6)
		local paneH = math.min(marginY * 0.72, 5)

		for col = 1, cols do
			for row = 1, rows do
				local x = -width / 2 + marginX * col
				local y = -height / 2 + marginY * row
				local lit = math.random() < litChance
				Scenery.decor({
					Name = "Window",
					Size = Vector3.new(paneW, paneH, 0.4),
					CFrame = cf * CFrame.new(x, y, 0.3),
					Color = lit and P.windowLit or P.windowDark,
					Material = lit and Enum.Material.Neon or Enum.Material.Glass,
					Transparency = lit and 0 or 0.35,
					Reflectance = lit and 0 or 0.25,
				}, parent)
				-- kozijn
				Scenery.decor({
					Name = "Frame",
					Size = Vector3.new(paneW + 0.7, paneH + 0.7, 0.25),
					CFrame = cf * CFrame.new(x, y, 0.15),
					Color = P.plaster:Lerp(Color3.new(0, 0, 0), 0.35),
				}, parent)
			end
		end
	end

	-- Winkelpui: grote ruit met deur in het midden.
	function Scenery.storefront(cf: CFrame, width: number, height: number, parent: Instance)
		Scenery.decor({
			Name = "Glass",
			Size = Vector3.new(width, height, 0.4),
			CFrame = cf * CFrame.new(0, height / 2, 0.2),
			Color = P.glass,
			Material = Enum.Material.Glass,
			Transparency = 0.55,
			Reflectance = 0.3,
		}, parent)
		Scenery.decor({
			Name = "Door",
			Size = Vector3.new(6, height * 0.72, 0.5),
			CFrame = cf * CFrame.new(0, height * 0.36, 0.35),
			Color = P.woodDark,
			Material = Enum.Material.Wood,
		}, parent)
		Scenery.decor({
			Name = "DoorHandle",
			Size = Vector3.new(0.3, 2.4, 0.3),
			CFrame = cf * CFrame.new(1.8, height * 0.36, 0.7),
			Color = P.gold,
			Material = Enum.Material.Metal,
		}, parent)
		-- stijlen
		for _, x in { -width / 2 + 0.4, width / 2 - 0.4 } do
			Scenery.decor({
				Name = "Mullion",
				Size = Vector3.new(0.8, height, 0.8),
				CFrame = cf * CFrame.new(x, height / 2, 0.3),
				Color = P.metalDark,
				Material = Enum.Material.Metal,
			}, parent)
		end
	end

	-- Gestreepte luifel boven een pui.
	function Scenery.awning(cf: CFrame, width: number, depth: number, colorA: Color3, colorB: Color3, parent: Instance)
		local stripes = math.max(4, math.floor(width / 3))
		local stripeW = width / stripes
		for i = 1, stripes do
			local x = -width / 2 + stripeW * (i - 0.5)
			Scenery.decor({
				Name = "Awning",
				Size = Vector3.new(stripeW, 0.4, depth),
				CFrame = cf * CFrame.new(x, 0, depth / 2) * CFrame.Angles(math.rad(-18), 0, 0),
				Color = (i % 2 == 0) and colorA or colorB,
				Material = Enum.Material.Fabric,
			}, parent)
		end
		-- afhangende rand
		Scenery.decor({
			Name = "AwningTrim",
			Size = Vector3.new(width, 1.4, 0.3),
			CFrame = cf * CFrame.new(0, -depth * 0.32, depth),
			Color = colorA,
			Material = Enum.Material.Fabric,
		}, parent)
	end

	-- ------------------------------------------------------------ straatmeubel --

	function Scenery.lamppost(cf: CFrame, parent: Instance)
		Scenery.decor({
			Name = "LampBase",
			Size = Vector3.new(2.2, 1.2, 2.2),
			CFrame = cf * CFrame.new(0, 0.6, 0),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
		Scenery.decor({
			Name = "LampPole",
			Size = Vector3.new(0.8, 16, 0.8),
			CFrame = cf * CFrame.new(0, 8, 0),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
		Scenery.decor({
			Name = "LampArm",
			Size = Vector3.new(4, 0.6, 0.6),
			CFrame = cf * CFrame.new(1.6, 15.6, 0),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
		local head = Scenery.decor({
			Name = "LampHead",
			Size = Vector3.new(3, 1.2, 2),
			CFrame = cf * CFrame.new(3.2, 15, 0),
			Color = P.windowLit,
			Material = Enum.Material.Neon,
		}, parent)
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 26
		light.Color = Color3.fromRGB(255, 226, 170)
		light.Parent = head
	end

	function Scenery.tree(cf: CFrame, scale: number, parent: Instance)
		Scenery.decor({
			Name = "Trunk",
			Size = Vector3.new(1.8 * scale, 9 * scale, 1.8 * scale),
			CFrame = cf * CFrame.new(0, 4.5 * scale, 0),
			Color = P.woodDark,
			Material = Enum.Material.Wood,
		}, parent)
		local tops = {
			{ offset = Vector3.new(0, 11 * scale, 0), size = 9 * scale, color = P.foliage },
			{ offset = Vector3.new(2.4 * scale, 9 * scale, 1.2 * scale), size = 6.5 * scale, color = P.foliageLight },
			{ offset = Vector3.new(-2.2 * scale, 9.5 * scale, -1.4 * scale), size = 6 * scale, color = P.foliage },
		}
		for _, top in tops do
			Scenery.ball({
				Name = "Leaves",
				Size = Vector3.new(top.size, top.size, top.size),
				CFrame = cf * CFrame.new(top.offset),
				Color = top.color,
				Material = Enum.Material.Grass,
			}, parent)
		end
	end

	function Scenery.bench(cf: CFrame, parent: Instance)
		Scenery.decor({
			Name = "BenchSeat",
			Size = Vector3.new(10, 0.6, 3),
			CFrame = cf * CFrame.new(0, 2.4, 0),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
		}, parent)
		Scenery.decor({
			Name = "BenchBack",
			Size = Vector3.new(10, 3, 0.6),
			CFrame = cf * CFrame.new(0, 3.9, -1.2),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
		}, parent)
		for _, x in { -4.2, 4.2 } do
			Scenery.decor({
				Name = "BenchLeg",
				Size = Vector3.new(0.5, 2.4, 2.8),
				CFrame = cf * CFrame.new(x, 1.2, 0),
				Color = P.metalDark,
				Material = Enum.Material.Metal,
			}, parent)
		end
	end

	function Scenery.planter(cf: CFrame, parent: Instance)
		Scenery.decor({
			Name = "PlanterBox",
			Size = Vector3.new(7, 3, 7),
			CFrame = cf * CFrame.new(0, 1.5, 0),
			Color = P.plasterWarm,
			Material = Enum.Material.Concrete,
		}, parent)
		Scenery.decor({
			Name = "PlanterSoil",
			Size = Vector3.new(6, 0.6, 6),
			CFrame = cf * CFrame.new(0, 3.1, 0),
			Color = Color3.fromRGB(78, 58, 44),
		}, parent)
		for i = 1, 4 do
			local angle = (i / 4) * math.pi * 2
			Scenery.ball({
				Name = "Bush",
				Size = Vector3.new(3.4, 3.4, 3.4),
				CFrame = cf * CFrame.new(math.cos(angle) * 1.6, 4, math.sin(angle) * 1.6),
				Color = i % 2 == 0 and P.foliage or P.foliageLight,
				Material = Enum.Material.Grass,
			}, parent)
		end
	end

	function Scenery.crate(cf: CFrame, size: number, parent: Instance)
		Scenery.decor({
			Name = "Crate",
			Size = Vector3.new(size, size, size),
			CFrame = cf * CFrame.new(0, size / 2, 0),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, parent)
		Scenery.decor({
			Name = "CrateBand",
			Size = Vector3.new(size + 0.2, 0.5, size + 0.2),
			CFrame = cf * CFrame.new(0, size * 0.75, 0),
			Color = P.woodDark,
		}, parent)
	end

	function Scenery.trashcan(cf: CFrame, parent: Instance)
		Scenery.cylinder({
			Name = "Bin",
			Size = Vector3.new(4.5, 3.2, 3.2),
			CFrame = cf * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
	end

	function Scenery.hedge(cf: CFrame, width: number, parent: Instance)
		Scenery.decor({
			Name = "Hedge",
			Size = Vector3.new(width, 4, 3),
			CFrame = cf * CFrame.new(0, 2, 0),
			Color = P.foliage,
			Material = Enum.Material.Grass,
		}, parent)
	end

	function Scenery.fountain(cf: CFrame, parent: Instance)
		Scenery.cylinder({
			Name = "FountainBasin",
			Size = Vector3.new(3.5, 34, 34),
			CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.plaster,
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, parent)
		Scenery.cylinder({
			Name = "FountainWater",
			Size = Vector3.new(0.8, 31, 31),
			CFrame = cf * CFrame.new(0, 2.9, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.water,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
		}, parent)
		Scenery.cylinder({
			Name = "FountainStem",
			Size = Vector3.new(9, 5, 5),
			CFrame = cf * CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.plaster,
			Material = Enum.Material.Marble,
		}, parent)
		Scenery.cylinder({
			Name = "FountainBowl",
			Size = Vector3.new(1.4, 14, 14),
			CFrame = cf * CFrame.new(0, 10, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.plaster,
			Material = Enum.Material.Marble,
		}, parent)
		-- een reuzenpen als middelpunt
		Scenery.cylinder({
			Name = "GiantPenBody",
			Size = Vector3.new(26, 4.5, 4.5),
			CFrame = cf * CFrame.new(0, 24, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.neonCyan,
			Material = Enum.Material.Metal,
		}, parent)
		Scenery.decor({
			Name = "GiantPenTip",
			Size = Vector3.new(3.4, 6, 3.4),
			CFrame = cf * CFrame.new(0, 9.5, 0),
			Color = Color3.fromRGB(40, 40, 46),
			Material = Enum.Material.Metal,
		}, parent)
		Scenery.decor({
			Name = "GiantPenClip",
			Size = Vector3.new(0.9, 9, 0.9),
			CFrame = cf * CFrame.new(2.4, 31, 0),
			Color = P.gold,
			Material = Enum.Material.Metal,
		}, parent)
	end

	-- ------------------------------------------------------------- achtergrond --

	-- Stadsblokken op de achtergrond: geven de straat diepte zonder dat je er
	-- kunt komen. `opts` regelt hoogte en kleur, zodat de blokken dicht bij de
	-- straat laag en warm zijn en ver weg hoog en koel.
	function Scenery.skyline(origin: Vector3, spacing: number, count: number, facing: number,
		parent: Instance, opts: { minHeight: number, maxHeight: number, cool: number, jitter: number, axis: string? }?)
		local o = opts or { minHeight = 40, maxHeight = 90, cool = 0.2, jitter = 12, axis = "z" }
		local alongX = o.axis == "x"
		local tints = { P.brick, P.plaster, P.plasterWarm, P.teal, P.metalDark, Color3.fromRGB(148, 120, 150) }

		for i = 1, count do
			local height = o.minHeight + math.random() * (o.maxHeight - o.minHeight)
			local width = 30 + math.random() * 24
			local depth = 30 + math.random() * 20
			local step = (i - 1) * spacing
			local x = origin.X + (alongX and step or 0) + math.random(-o.jitter, o.jitter)
			local z = origin.Z - (alongX and 0 or step) + math.random(-o.jitter, o.jitter)
			local tint = tints[math.random(#tints)]
			local color = tint:Lerp(P.skylineFar, o.cool)

			local block = Scenery.decor({
				Name = "CityBlock",
				Size = Vector3.new(width, height, depth),
				CFrame = CFrame.new(x, height / 2, z),
				Color = color,
				Material = Enum.Material.Brick,
				CanCollide = true,
			}, parent)
			Scenery.windows(
				block.CFrame * CFrame.Angles(0, math.rad(facing), 0) * CFrame.new(0, 0, depth / 2),
				width * 0.8, height * 0.8,
				math.max(2, math.floor(width / 11)), math.max(2, math.floor(height / 13)),
				0.4, parent
			)
			-- dakrand en een opbouwtje
			Scenery.decor({
				Name = "Cornice",
				Size = Vector3.new(width + 2, 1.6, depth + 2),
				CFrame = CFrame.new(x, height, z),
				Color = color:Lerp(Color3.new(0, 0, 0), 0.25),
			}, parent)
			Scenery.decor({
				Name = "RoofBox",
				Size = Vector3.new(width * 0.28, 5 + math.random() * 7, depth * 0.28),
				CFrame = CFrame.new(x + math.random(-6, 6), height + 4, z + math.random(-6, 6)),
				Color = P.metalDark,
			}, parent)
		end
	end

	-- ------------------------------------------------------------- bouwplaats --

	function Scenery.fence(cf: CFrame, length: number, parent: Instance)
		local panels = math.max(1, math.floor(length / 10))
		local panelW = length / panels
		for i = 1, panels do
			local x = -length / 2 + panelW * (i - 0.5)
			Scenery.decor({
				Name = "FencePanel",
				Size = Vector3.new(panelW - 0.6, 9, 0.4),
				CFrame = cf * CFrame.new(x, 4.6, 0),
				Color = Color3.fromRGB(216, 176, 60),
				Material = Enum.Material.Metal,
				Transparency = 0.15,
				CanCollide = true,
			}, parent)
			Scenery.decor({
				Name = "FenceFoot",
				Size = Vector3.new(2.4, 1, 3),
				CFrame = cf * CFrame.new(x - panelW / 2 + 0.6, 0.5, 0),
				Color = Color3.fromRGB(56, 58, 66),
			}, parent)
		end
	end

	function Scenery.crane(cf: CFrame, height: number, parent: Instance)
		Scenery.decor({
			Name = "CraneBase",
			Size = Vector3.new(10, 2, 10),
			CFrame = cf * CFrame.new(0, 1, 0),
			Color = P.metalDark,
			CanCollide = true,
		}, parent)
		Scenery.decor({
			Name = "CraneMast",
			Size = Vector3.new(4, height, 4),
			CFrame = cf * CFrame.new(0, height / 2 + 2, 0),
			Color = Color3.fromRGB(226, 150, 40),
			Material = Enum.Material.Metal,
		}, parent)
		Scenery.decor({
			Name = "CraneJib",
			Size = Vector3.new(52, 2.4, 2.4),
			CFrame = cf * CFrame.new(16, height + 3, 0),
			Color = Color3.fromRGB(226, 150, 40),
			Material = Enum.Material.Metal,
		}, parent)
		Scenery.decor({
			Name = "CraneCounter",
			Size = Vector3.new(8, 4, 4),
			CFrame = cf * CFrame.new(-12, height + 3, 0),
			Color = P.metalDark,
		}, parent)
		Scenery.decor({
			Name = "CraneCable",
			Size = Vector3.new(0.4, height * 0.5, 0.4),
			CFrame = cf * CFrame.new(32, height + 3 - height * 0.25, 0),
			Color = Color3.fromRGB(40, 40, 46),
		}, parent)
		Scenery.decor({
			Name = "CraneHook",
			Size = Vector3.new(4, 3, 4),
			CFrame = cf * CFrame.new(32, height + 3 - height * 0.5, 0),
			Color = P.metal,
			Material = Enum.Material.Metal,
		}, parent)
	end

	function Scenery.scaffold(cf: CFrame, width: number, height: number, parent: Instance)
		local levels = math.max(2, math.floor(height / 9))
		for level = 1, levels do
			Scenery.decor({
				Name = "ScaffoldDeck",
				Size = Vector3.new(width, 0.5, 4),
				CFrame = cf * CFrame.new(0, level * 9, 0),
				Color = P.wood,
				Material = Enum.Material.WoodPlanks,
			}, parent)
			Scenery.decor({
				Name = "ScaffoldRail",
				Size = Vector3.new(width, 0.4, 0.4),
				CFrame = cf * CFrame.new(0, level * 9 + 3, 1.8),
				Color = P.metal,
				Material = Enum.Material.Metal,
			}, parent)
		end
		local posts = math.max(2, math.floor(width / 10))
		for i = 0, posts do
			Scenery.decor({
				Name = "ScaffoldPost",
				Size = Vector3.new(0.5, levels * 9 + 2, 0.5),
				CFrame = cf * CFrame.new(-width / 2 + (width / posts) * i, (levels * 9) / 2 + 1, 0),
				Color = P.metal,
				Material = Enum.Material.Metal,
			}, parent)
		end
	end

	function Scenery.cone(cf: CFrame, parent: Instance)
		Scenery.decor({
			Name = "ConeBase",
			Size = Vector3.new(2.4, 0.4, 2.4),
			CFrame = cf * CFrame.new(0, 0.2, 0),
			Color = Color3.fromRGB(240, 110, 40),
		}, parent)
		Scenery.decor({
			Name = "ConeBody",
			Size = Vector3.new(1.2, 3, 1.2),
			CFrame = cf * CFrame.new(0, 1.7, 0),
			Color = Color3.fromRGB(240, 110, 40),
		}, parent)
	end

	-- --------------------------------------------------------------- voertuig --

	function Scenery.car(cf: CFrame, color: Color3, long: boolean, parent: Instance)
		local length = long and 30 or 17
		Scenery.decor({
			Name = "CarBody",
			Size = Vector3.new(7, 3.4, length),
			CFrame = cf * CFrame.new(0, 2.6, 0),
			Color = color,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, parent)
		Scenery.decor({
			Name = "CarCabin",
			Size = Vector3.new(6.4, 3, length * 0.42),
			CFrame = cf * CFrame.new(0, 5.6, long and -2 or 0),
			Color = Color3.fromRGB(40, 44, 56),
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			Reflectance = 0.3,
		}, parent)
		for _, dz in { length / 2 - 3.5, -(length / 2 - 3.5) } do
			for _, dx in { -3.4, 3.4 } do
				Scenery.cylinder({
					Name = "CarWheel",
					Size = Vector3.new(1.6, 3.2, 3.2),
					CFrame = cf * CFrame.new(dx, 1.6, dz) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(28, 28, 32),
				}, parent)
			end
		end
		Scenery.decor({
			Name = "CarLight",
			Size = Vector3.new(5, 0.8, 0.4),
			CFrame = cf * CFrame.new(0, 3, length / 2),
			Color = Color3.fromRGB(255, 240, 190),
			Material = Enum.Material.Neon,
		}, parent)
	end

	function Scenery.palm(cf: CFrame, parent: Instance)
		for i = 1, 6 do
			Scenery.decor({
				Name = "PalmTrunk",
				Size = Vector3.new(1.6, 3, 1.6),
				CFrame = cf * CFrame.new(i * 0.25, i * 3 - 1.5, 0),
				Color = Color3.fromRGB(150, 122, 86),
			}, parent)
		end
		for i = 1, 6 do
			local angle = (i / 6) * math.pi * 2
			Scenery.decor({
				Name = "PalmLeaf",
				Size = Vector3.new(10, 0.4, 3),
				CFrame = cf * CFrame.new(1.5 + math.cos(angle) * 4, 18, math.sin(angle) * 4)
					* CFrame.Angles(0, -angle, math.rad(-12)),
				Color = Color3.fromRGB(78, 148, 78),
			}, parent)
		end
	end

	function Scenery.redCarpet(cf: CFrame, length: number, parent: Instance)
		Scenery.decor({
			Name = "Carpet",
			Size = Vector3.new(14, 0.25, length),
			CFrame = cf * CFrame.new(0, 0.15, 0),
			Color = Color3.fromRGB(150, 28, 40),
			Material = Enum.Material.Fabric,
		}, parent)
		local posts = math.max(2, math.floor(length / 14))
		for i = 0, posts do
			for _, dx in { -8, 8 } do
				Scenery.decor({
					Name = "RopePost",
					Size = Vector3.new(1, 5, 1),
					CFrame = cf * CFrame.new(dx, 2.5, -length / 2 + (length / posts) * i),
					Color = P.gold,
					Material = Enum.Material.Metal,
				}, parent)
			end
		end
	end

	function Scenery.smoke(attachTo: BasePart, size: number, color: Color3)
		local attachment = Instance.new("Attachment")
		attachment.Parent = attachTo

		local smoke = Instance.new("ParticleEmitter")
		smoke.Name = "Smoke"
		smoke.Rate = 6
		smoke.Lifetime = NumberRange.new(4, 7)
		smoke.Speed = NumberRange.new(4, 7)
		smoke.Size = NumberSequence.new(size)
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		smoke.Color = ColorSequence.new(color)
		smoke.Acceleration = Vector3.new(1, 3, 0)
		smoke.Parent = attachment
	end

	function Scenery.sparkle(attachTo: BasePart, color: Color3)
		local attachment = Instance.new("Attachment")
		attachment.Parent = attachTo

		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkle"
		sparkles.Rate = 14
		sparkles.Lifetime = NumberRange.new(1, 2)
		sparkles.Speed = NumberRange.new(3, 7)
		sparkles.Size = NumberSequence.new(1.2)
		sparkles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkles.Color = ColorSequence.new(color)
		sparkles.Acceleration = Vector3.new(0, 6, 0)
		sparkles.Parent = attachment
	end

	return Scenery
end)()

PEN.World = (function()
	--!strict
	-- Bouwt Pen Street: een plein met fontein, een straat met stoepen, lantaarns
	-- en bomen, en per rebirth een eigen zaak langs die straat. Alles met code.

	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	local Config = PEN.Config
	local Scenery = PEN.Scenery

	local World = {}

	local P = Scenery.Palette
	local part = Scenery.part
	local decor = Scenery.decor

	World.BLOCK_SPACING = 120
	World.FIRST_BLOCK_Z = -80

	local ROAD_HALF = 15
	local WALK_OUTER = 32
	local PLOT_X = 70 -- midden van het terrein aan de rechterkant

	-- Vier wijken langs de straat: van marktstraat naar penthouse-wijk. Elke twee
	-- zaken schuif je een wijk op, en de omgeving wordt navenant rijker.
	local DISTRICTS = {
		{
			name = "Marktstraat",
			palette = { P.brick, P.plasterWarm, P.plaster, P.teal },
			minHeight = 24, maxHeight = 46,
			material = Enum.Material.Brick,
			awnings = true,
			greenery = "tree",
			carColor = Color3.fromRGB(108, 132, 168),
			limo = false,
		},
		{
			name = "Handelswijk",
			palette = { Color3.fromRGB(150, 152, 158), P.brick, Color3.fromRGB(122, 128, 140), P.metalDark },
			minHeight = 30, maxHeight = 62,
			material = Enum.Material.Concrete,
			awnings = false,
			greenery = "none",
			carColor = Color3.fromRGB(196, 196, 200),
			limo = false,
		},
		{
			name = "Pen Street",
			palette = { Color3.fromRGB(206, 200, 186), Color3.fromRGB(120, 140, 172), Color3.fromRGB(96, 104, 126), P.plaster },
			minHeight = 60, maxHeight = 120,
			material = Enum.Material.Marble,
			awnings = false,
			greenery = "hedge",
			carColor = Color3.fromRGB(236, 196, 60),
			limo = false,
		},
		{
			name = "Penthousewijk",
			palette = { Color3.fromRGB(96, 124, 150), Color3.fromRGB(70, 86, 116), Color3.fromRGB(206, 178, 110), Color3.fromRGB(58, 68, 96) },
			minHeight = 90, maxHeight = 190,
			material = Enum.Material.Glass,
			awnings = false,
			greenery = "palm",
			carColor = Color3.fromRGB(22, 22, 26),
			limo = true,
		},
	}

	local function districtOf(index: number)
		return DISTRICTS[math.clamp(math.ceil(index / 2), 1, #DISTRICTS)]
	end

	local function wall(x: number, y: number, z: number, yawDeg: number): CFrame
		return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yawDeg), 0)
	end

	local function blockZ(index: number): number
		return World.FIRST_BLOCK_Z - (index - 1) * World.BLOCK_SPACING
	end

	-- ------------------------------------------------------------------ licht --

	local function setupLighting()
		pcall(function()
			Lighting.Technology = Enum.Technology.Future
		end)
		Lighting.ClockTime = 16.2
		Lighting.GeographicLatitude = 24
		Lighting.Brightness = 2.4
		Lighting.Ambient = Color3.fromRGB(88, 90, 100)
		Lighting.OutdoorAmbient = Color3.fromRGB(132, 134, 144)
		Lighting.EnvironmentDiffuseScale = 0.55
		Lighting.EnvironmentSpecularScale = 0.45
		Lighting.ExposureCompensation = 0.15
		Lighting.GlobalShadows = true
		Lighting.FogEnd = 1400

		for _, old in Lighting:GetChildren() do
			if old:IsA("Atmosphere") or old:IsA("BloomEffect") or old:IsA("ColorCorrectionEffect")
				or old:IsA("SunRaysEffect") or old:IsA("Sky") then
				old:Destroy()
			end
		end

		local sky = Instance.new("Sky")
		sky.Name = "PenSky"
		sky.SunAngularSize = 14
		sky.Parent = Lighting

		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.32
		atmosphere.Offset = 0.15
		atmosphere.Color = Color3.fromRGB(202, 199, 194)
		atmosphere.Decay = Color3.fromRGB(106, 112, 125)
		atmosphere.Glare = 0.3
		atmosphere.Haze = 1.7
		atmosphere.Parent = Lighting

		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.5
		bloom.Size = 24
		bloom.Threshold = 1.05
		bloom.Parent = Lighting

		local grade = Instance.new("ColorCorrectionEffect")
		grade.Saturation = 0.14
		grade.Contrast = 0.09
		grade.TintColor = Color3.fromRGB(255, 249, 240)
		grade.Parent = Lighting

		local rays = Instance.new("SunRaysEffect")
		rays.Intensity = 0.06
		rays.Spread = 0.9
		rays.Parent = Lighting
	end

	-- ----------------------------------------------------------- straat/stoep --

	local function buildStreet(root: Folder, totalLength: number, centerZ: number)
		decor({
			Name = "Ground",
			Size = Vector3.new(660, 2, totalLength + 260),
			CFrame = CFrame.new(35, -1, centerZ),
			Color = Color3.fromRGB(96, 100, 108),
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, root)

		-- groenstroken langs de stoepen, zodat het niet één grijze vlakte is
		for _, side in { -1, 1 } do
			decor({
				Name = "Verge",
				Size = Vector3.new(7, 1.3, totalLength + 260),
				CFrame = CFrame.new(side * (WALK_OUTER + 3.5), 0.65, centerZ),
				Color = P.grass,
				Material = Enum.Material.Grass,
				CanCollide = true,
			}, root)
		end

		decor({
			Name = "Road",
			Size = Vector3.new(ROAD_HALF * 2, 0.6, totalLength + 300),
			CFrame = CFrame.new(0, 0.3, centerZ),
			Color = P.asphalt,
			Material = Enum.Material.Asphalt,
			CanCollide = true,
		}, root)

		for _, side in { -1, 1 } do
			decor({
				Name = "Sidewalk",
				Size = Vector3.new(WALK_OUTER - ROAD_HALF, 1.2, totalLength + 300),
				CFrame = CFrame.new(side * (ROAD_HALF + (WALK_OUTER - ROAD_HALF) / 2), 0.6, centerZ),
				Color = P.sidewalk,
				Material = Enum.Material.Concrete,
				CanCollide = true,
			}, root)
			decor({
				Name = "Curb",
				Size = Vector3.new(1.4, 1.6, totalLength + 300),
				CFrame = CFrame.new(side * ROAD_HALF, 0.8, centerZ),
				Color = P.curb,
				Material = Enum.Material.Concrete,
				CanCollide = true,
			}, root)
		end

		-- middenstreep
		local stripes = math.floor((totalLength + 300) / 24)
		for i = 0, stripes do
			decor({
				Name = "Line",
				Size = Vector3.new(1.2, 0.2, 10),
				CFrame = CFrame.new(0, 0.7, centerZ + (totalLength + 300) / 2 - i * 24),
				Color = P.asphaltLine,
				Material = Enum.Material.Concrete,
			}, root)
		end
	end

	local function streetFurniture(root: Folder, fromZ: number, toZ: number, district)
		local z = fromZ
		local flip = false
		while z > toZ do
			for _, side in { -1, 1 } do
				Scenery.lamppost(wall(side * (WALK_OUTER - 5), 1.2, z, side > 0 and 180 or 0), root)
			end

			if district.greenery == "tree" then
				Scenery.tree(CFrame.new((flip and -1 or 1) * (WALK_OUTER - 18), 1.2, z - 22), flip and 1.1 or 1, root)
			elseif district.greenery == "hedge" then
				Scenery.hedge(wall((flip and -1 or 1) * (WALK_OUTER - 19), 1.2, z - 22, 90), 16, root)
			elseif district.greenery == "palm" then
				Scenery.palm(CFrame.new((flip and -1 or 1) * (WALK_OUTER - 18), 1.2, z - 22), root)
			end

			if flip then
				Scenery.bench(CFrame.new(WALK_OUTER - 20, 1.2, z - 30), root)
			else
				Scenery.trashcan(CFrame.new(-(WALK_OUTER - 19), 1.2, z - 12), root)
			end
			flip = not flip
			z -= 46
		end
	end

	-- Auto's langs de stoeprand, per wijk anders: bestelbus, taxi, limousine.
	local function parkedCars(root: Folder, fromZ: number, toZ: number, district)
		local z = fromZ - 20
		local side = 1
		while z > toZ + 20 do
			Scenery.car(wall(side * (ROAD_HALF - 5), 1, z, 0), district.carColor, district.limo, root)
			side = -side
			z -= 74
		end
	end

	-- Aan de overkant van de straat: gevels waar je niet in kunt, voor de sfeer.
	local function facadeRow(root: Folder, fromZ: number, toZ: number, district)
		local z = fromZ
		local i = 0
		while z > toZ do
			i += 1
			local depth = 34
			local width = 34 + math.random(0, 14)
			local height = district.minHeight + math.random(0, district.maxHeight - district.minHeight)
			local color = district.palette[(i % #district.palette) + 1]
			local body = decor({
				Name = "Facade",
				Size = Vector3.new(depth, height, width),
				CFrame = CFrame.new(-(WALK_OUTER + depth / 2), height / 2, z - width / 2),
				Color = color,
				Material = district.material,
				Transparency = district.material == Enum.Material.Glass and 0.15 or 0,
				Reflectance = district.material == Enum.Material.Glass and 0.3 or 0,
				CanCollide = true,
			}, root)
			Scenery.windows(
				body.CFrame * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 2, depth / 2),
				width * 0.8, height * 0.7,
				math.max(2, math.floor(width / 11)), math.max(2, math.floor(height / 12)),
				0.4, root
			)
			decor({
				Name = "FacadeCornice",
				Size = Vector3.new(depth + 2, 2, width + 2),
				CFrame = CFrame.new(-(WALK_OUTER + depth / 2), height, z - width / 2),
				Color = color:Lerp(Color3.new(0, 0, 0), 0.3),
			}, root)

			Scenery.storefront(wall(-(WALK_OUTER + 0.4), 1.2, z - width / 2, 90), width * 0.6, 11, root)
			if district.awnings then
				Scenery.awning(wall(-(WALK_OUTER + 1), 13.5, z - width / 2, 90), width * 0.62, 6,
					district.palette[((i + 2) % #district.palette) + 1], P.awningB, root)
			else
				-- strak afdakje in plaats van een markt-luifel
				decor({
					Name = "Canopy",
					Size = Vector3.new(7, 1, width * 0.64),
					CFrame = CFrame.new(-(WALK_OUTER + 2.5), 14.5, z - width / 2),
					Color = P.metalDark,
					Material = Enum.Material.Metal,
				}, root)
			end
			z -= width + 6
		end
	end

	-- Kenmerken die alleen in een bepaalde wijk staan.
	local function districtProps(root: Folder, centerZ: number, district, index: number)
		if district.name == "Marktstraat" then
			for _, dz in { -30, 10 } do
				local counter = decor({
					Name = "MarketStall",
					Size = Vector3.new(8, 5, 14),
					CFrame = CFrame.new(-(WALK_OUTER - 9), 3.9, centerZ + dz),
					Color = P.wood,
					Material = Enum.Material.WoodPlanks,
					CanCollide = true,
				}, root)
				Scenery.awning(wall(-(WALK_OUTER - 13), 12, centerZ + dz, 90), 14, 6, P.awningA, P.awningB, root)
				Scenery.crate(CFrame.new(-(WALK_OUTER - 6), 1.2, centerZ + dz + 10), 3.5, root)
				counter.Name = "MarketStall"
			end
		elseif district.name == "Handelswijk" then
			for i = 1, 5 do
				Scenery.crate(CFrame.new(-(WALK_OUTER - 8) + (i % 2) * 5, 1.2, centerZ - 30 + i * 9), 4.5, root)
			end
			decor({
				Name = "WaterTower",
				Size = Vector3.new(14, 16, 14),
				CFrame = CFrame.new(-(WALK_OUTER + 20), 58, centerZ - 10),
				Color = P.woodDark,
				Material = Enum.Material.WoodPlanks,
			}, root)
			for _, dx in { -5, 5 } do
				for _, dz in { -5, 5 } do
					decor({
						Name = "TowerLeg",
						Size = Vector3.new(1.4, 14, 1.4),
						CFrame = CFrame.new(-(WALK_OUTER + 20) + dx, 43, centerZ - 10 + dz),
						Color = P.woodDark,
					}, root)
				end
			end
		elseif district.name == "Pen Street" then
			-- beurszuil met koersen
			local pillar = decor({
				Name = "TickerPillar",
				Size = Vector3.new(6, 26, 6),
				CFrame = CFrame.new(-(WALK_OUTER - 8), 14, centerZ),
				Color = Color3.fromRGB(32, 34, 44),
				Material = Enum.Material.Metal,
				CanCollide = true,
			}, root)
			Scenery.wallText(wall(-(WALK_OUTER - 11.2), 20, centerZ, 90), 12, 5,
				"PEN  +12.4%", Color3.fromRGB(120, 255, 150), root)
			pillar.Name = "TickerPillar"
			for _, dz in { -26, 26 } do
				decor({
					Name = "Column",
					Size = Vector3.new(5, 26, 5),
					CFrame = CFrame.new(-(WALK_OUTER + 4), 14, centerZ + dz),
					Color = P.plaster,
					Material = Enum.Material.Marble,
					CanCollide = true,
				}, root)
			end
		else
			-- penthousewijk: rode loper, gouden paaltjes, palmen
			Scenery.redCarpet(CFrame.new(-(WALK_OUTER - 8), 1.2, centerZ), 46, root)
			Scenery.palm(CFrame.new(-(WALK_OUTER - 24), 1.2, centerZ + 26), root)
			Scenery.palm(CFrame.new(-(WALK_OUTER - 24), 1.2, centerZ - 26), root)
			decor({
				Name = "Helipad",
				Size = Vector3.new(30, 1.2, 30),
				CFrame = CFrame.new(-(WALK_OUTER + 40), 120 + index * 4, centerZ),
				Color = Color3.fromRGB(38, 40, 50),
			}, root)
			decor({
				Name = "HelipadRing",
				Size = Vector3.new(22, 1.4, 22),
				CFrame = CFrame.new(-(WALK_OUTER + 40), 120 + index * 4, centerZ),
				Color = P.gold,
				Material = Enum.Material.Neon,
				Transparency = 0.3,
			}, root)
		end
	end

	local function dressBlock(root: Folder, fromZ: number, toZ: number, district, index: number)
		facadeRow(root, fromZ, toZ, district)
		streetFurniture(root, fromZ, toZ, district)
		parkedCars(root, fromZ, toZ, district)
		districtProps(root, (fromZ + toZ) / 2, district, index)
	end

	-- ------------------------------------------------------------------ plein --

	local function buildPlaza(root: Folder): Folder
		local plaza = Instance.new("Folder")
		plaza.Name = "Plaza"
		plaza.Parent = root

		decor({
			Name = "PlazaFloor",
			Size = Vector3.new(150, 1.4, 120),
			CFrame = CFrame.new(0, 0.7, 66),
			Color = P.sidewalk,
			Material = Enum.Material.Pebble,
			CanCollide = true,
		}, plaza)

		-- geblokte bestrating: vier tinten door elkaar, scheelt een dode vlakte
		local tile = 15
		for gx = -4, 4 do
			for gz = 0, 7 do
				local shade = ((gx + gz) % 2 == 0) and 0.06 or 0.16
				decor({
					Name = "Tile",
					Size = Vector3.new(tile - 1, 0.2, tile - 1),
					CFrame = CFrame.new(gx * tile, 1.45, 18 + gz * tile),
					Color = P.sidewalk:Lerp(P.plasterWarm, shade),
					Material = Enum.Material.Pebble,
				}, plaza)
			end
		end

		decor({
			Name = "PlazaInlay",
			Size = Vector3.new(46, 0.25, 46),
			CFrame = CFrame.new(0, 1.5, 62),
			Color = P.plasterWarm,
			Material = Enum.Material.Marble,
		}, plaza)

		Scenery.fountain(CFrame.new(0, 1.5, 62), plaza)

		-- welkomstboog over de straat
		for _, x in { -20, 20 } do
			decor({
				Name = "ArchLeg",
				Size = Vector3.new(4, 26, 4),
				CFrame = CFrame.new(x, 13, 8),
				Color = P.metalDark,
				Material = Enum.Material.Metal,
				CanCollide = true,
			}, plaza)
		end
		decor({
			Name = "ArchTop",
			Size = Vector3.new(48, 4, 4),
			CFrame = CFrame.new(0, 27, 8),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, plaza)
		Scenery.wallText(wall(0, 31, 8, 180), 42, 8, "PEN STREET", P.neonPink, plaza)

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PenSpawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(16, 1, 16)
		spawn.CFrame = CFrame.new(0, 1.9, 26)
		spawn.Color = Color3.fromRGB(120, 200, 150)
		spawn.Material = Enum.Material.Marble
		spawn.Duration = 0
		spawn.Parent = plaza

		-- groen en zitjes
		for _, spot in { Vector3.new(-34, 1.5, 34), Vector3.new(34, 1.5, 34),
			Vector3.new(-34, 1.5, 92), Vector3.new(34, 1.5, 92) } do
			Scenery.tree(CFrame.new(spot), 1.25, plaza)
		end
		Scenery.bench(CFrame.new(-22, 1.5, 44), plaza)
		Scenery.bench(CFrame.new(22, 1.5, 44), plaza)
		Scenery.bench(CFrame.new(-22, 1.5, 82), plaza)
		Scenery.bench(CFrame.new(22, 1.5, 82), plaza)
		Scenery.planter(CFrame.new(-30, 1.5, 62), plaza)
		Scenery.planter(CFrame.new(30, 1.5, 62), plaza)
		Scenery.trashcan(CFrame.new(-14, 1.5, 30), plaza)
		Scenery.trashcan(CFrame.new(14, 1.5, 100), plaza)
		for _, x in { -64, 64 } do
			for _, z in { 30, 62, 94 } do
				Scenery.lamppost(wall(x, 1.5, z, x > 0 and 180 or 0), plaza)
			end
		end

		-- bankjes rond de fontein, kijkend naar het water
		for _, spot in { { 0, 44, 0 }, { 0, 80, 180 }, { -22, 62, -90 }, { 22, 62, 90 } } do
			Scenery.bench(wall(spot[1], 1.5, spot[2], spot[3]), plaza)
		end

		-- klokzuil als herkenningspunt bij de ingang
		local clock = decor({
			Name = "ClockPillar",
			Size = Vector3.new(5, 30, 5),
			CFrame = CFrame.new(-30, 16, 20),
			Color = P.plaster,
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, plaza)
		decor({
			Name = "ClockFace",
			Size = Vector3.new(7, 7, 1),
			CFrame = CFrame.new(-30, 28, 17.4),
			Color = P.windowLit,
			Material = Enum.Material.Neon,
		}, plaza)
		decor({
			Name = "ClockTop",
			Size = Vector3.new(7, 2, 7),
			CFrame = CFrame.new(-30, 32, 20),
			Color = P.metalDark,
		}, plaza)
		clock.Name = "ClockPillar"

		-- pennenkarretje
		decor({
			Name = "CartBody",
			Size = Vector3.new(12, 6, 7),
			CFrame = CFrame.new(28, 4.5, 26),
			Color = P.neonPink,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, plaza)
		Scenery.awning(wall(28, 11.5, 22.6, 180), 12, 5, P.awningB, P.neonPink, plaza)
		for _, dx in { -4, 4 } do
			Scenery.cylinder({
				Name = "CartWheel",
				Size = Vector3.new(1.2, 4, 4),
				CFrame = CFrame.new(28 + dx, 2, 29) * CFrame.Angles(0, 0, math.rad(90)),
				Color = P.woodDark,
			}, plaza)
		end

		-- fietsenrek
		for i = 0, 3 do
			decor({
				Name = "BikeRack",
				Size = Vector3.new(0.6, 3, 5),
				CFrame = CFrame.new(-46, 3, 116 + i * 4),
				Color = P.metal,
				Material = Enum.Material.Metal,
			}, plaza)
		end

		return plaza
	end

	local function buildKiosks(plaza: Folder)
		-- marktkraampjes voor de upgrades, netjes op een rij langs het plein
		local startZ = 26
		local spacing = 22
		for i, up in Config.Upgrades do
			local z = startZ + (i - 1) * spacing
			local x = -56

			decor({
				Name = "KioskCounter_" .. up.key,
				Size = Vector3.new(10, 5, 16),
				CFrame = CFrame.new(x, 3.9, z),
				Color = P.wood,
				Material = Enum.Material.WoodPlanks,
				CanCollide = true,
			}, plaza)
			for _, dz in { -7, 7 } do
				decor({
					Name = "KioskPost",
					Size = Vector3.new(0.8, 12, 0.8),
					CFrame = CFrame.new(x - 3, 7.4, z + dz),
					Color = P.woodDark,
					Material = Enum.Material.Wood,
				}, plaza)
			end
			Scenery.awning(wall(x - 3, 13.4, z, 90), 16, 7, P.awningA, P.awningB, plaza)
			Scenery.wallText(wall(x + 5.3, 9, z, 90), 14, 4, up.name, P.gold, plaza)
			Scenery.crate(CFrame.new(x - 4, 1.4, z + 10), 3.5, plaza)

			local pad = part({
				Name = "UpgradePad_" .. up.key,
				Size = Vector3.new(12, 0.6, 14),
				CFrame = CFrame.new(x + 11, 1.7, z),
				Color = P.gold,
				Material = Enum.Material.Neon,
				Transparency = 0.3,
				CanCollide = false,
			}, plaza)
			Scenery.floatingText(pad, string.format("<b>%s</b>\n%s", up.name, up.info), 4.5, 14, 50)
		end
	end

	local function buildRebirthPortal(plaza: Folder)
		local z = 112
		for _, x in { -13, 13 } do
			decor({
				Name = "PortalLeg",
				Size = Vector3.new(5, 30, 5),
				CFrame = CFrame.new(x, 16, z),
				Color = Color3.fromRGB(64, 40, 92),
				Material = Enum.Material.Marble,
				CanCollide = true,
			}, plaza)
		end
		decor({
			Name = "PortalTop",
			Size = Vector3.new(31, 5, 5),
			CFrame = CFrame.new(0, 33, z),
			Color = Color3.fromRGB(64, 40, 92),
			Material = Enum.Material.Marble,
		}, plaza)
		local veil = decor({
			Name = "PortalVeil",
			Size = Vector3.new(21, 28, 1),
			CFrame = CFrame.new(0, 16, z),
			Color = Color3.fromRGB(184, 108, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.45,
		}, plaza)
		Scenery.sparkle(veil, Color3.fromRGB(214, 160, 255))
		Scenery.wallText(wall(0, 37, z, 180), 30, 7, "REBIRTH", Color3.fromRGB(214, 160, 255), plaza)

		local pad = part({
			Name = "RebirthPad",
			Size = Vector3.new(16, 0.6, 12),
			CFrame = CFrame.new(0, 1.7, z - 12),
			Color = Color3.fromRGB(200, 120, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			CanCollide = false,
		}, plaza)
		Scenery.floatingText(pad, "<b>REBIRTH</b>\n2 seconden blijven staan", 4.5, 15, 55)
	end

	local function buildPetStand(plaza: Folder)
		local x, z = 56, 40
		decor({
			Name = "PetStand",
			Size = Vector3.new(12, 7, 18),
			CFrame = CFrame.new(x, 4.9, z),
			Color = P.teal,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, plaza)
		decor({
			Name = "PetTank",
			Size = Vector3.new(10, 8, 16),
			CFrame = CFrame.new(x, 12.4, z),
			Color = P.glass,
			Material = Enum.Material.Glass,
			Transparency = 0.5,
			Reflectance = 0.25,
		}, plaza)
		for i = 1, 4 do
			Scenery.cylinder({
				Name = "TankPen",
				Size = Vector3.new(5, 1, 1),
				CFrame = CFrame.new(x - 3 + i * 1.6, 11 + (i % 2) * 2.5, z - 4 + i * 2)
					* CFrame.Angles(0, 0, math.rad(70 + i * 8)),
				Color = i % 2 == 0 and P.neonCyan or P.neonPink,
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, plaza)
		end
		Scenery.wallText(wall(x - 6.3, 20, z, -90), 16, 5, "PENNENBAK", P.neonCyan, plaza)

		local pad = part({
			Name = "PetPad",
			Size = Vector3.new(12, 0.6, 14),
			CFrame = CFrame.new(x - 12, 1.7, z),
			Color = P.neonCyan,
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			CanCollide = false,
		}, plaza)
		Scenery.floatingText(pad, "<b>MASCOTTES</b>", 4.5, 14, 50)
	end

	local function buildBoard(plaza: Folder, name: string, cf: CFrame, title: string)
		for _, dx in { -11, 11 } do
			decor({
				Name = "BoardLeg",
				Size = Vector3.new(2, 14, 2),
				CFrame = cf * CFrame.new(dx, -17, 0),
				Color = P.metalDark,
				Material = Enum.Material.Metal,
			}, plaza)
		end
		local stand = decor({
			Name = name,
			Size = Vector3.new(26, 20, 1.6),
			CFrame = cf,
			Color = Color3.fromRGB(22, 24, 32),
			Material = Enum.Material.SmoothPlastic,
		}, plaza)
		decor({
			Name = "BoardEdge",
			Size = Vector3.new(27.5, 21.5, 1),
			CFrame = cf * CFrame.new(0, 0, -0.4),
			Color = P.gold,
			Material = Enum.Material.Neon,
		}, plaza)

		local surface = Instance.new("SurfaceGui")
		surface.Name = "Screen"
		surface.Face = Enum.NormalId.Front
		surface.CanvasSize = Vector2.new(520, 400)
		surface.LightInfluence = 0
		surface.MaxDistance = 160
		surface.Parent = stand

		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 56)
		header.BackgroundTransparency = 1
		header.Font = Enum.Font.GothamBlack
		header.TextSize = 36
		header.TextColor3 = P.gold
		header.Text = title
		header.Parent = surface

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.Size = UDim2.new(1, -28, 1, -66)
		body.Position = UDim2.new(0, 14, 0, 60)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.GothamMedium
		body.TextSize = 24
		body.TextColor3 = Color3.new(1, 1, 1)
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.RichText = true
		body.Text = "laden..."
		body.Parent = surface
	end

	-- --------------------------------------------------------------- stations --

	local function stationShell(root: Folder, station, index: number): (Folder, number)
		local folder = Instance.new("Folder")
		folder.Name = "Station_" .. station.key
		folder.Parent = root

		local zc = blockZ(index)

		-- voorterrein met bestrating in blokken
		decor({
			Name = "Plot",
			Size = Vector3.new(92, 1.4, 112),
			CFrame = CFrame.new(PLOT_X + 8, 0.7, zc),
			Color = P.curb,
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, folder)
		for gx = 0, 5 do
			for gz = 0, 6 do
				local shade = ((gx + gz) % 2 == 0) and 0.1 or 0.26
				decor({
					Name = "PlotTile",
					Size = Vector3.new(14, 0.2, 15),
					CFrame = CFrame.new(34 + gx * 15, 1.45, zc - 48 + gz * 16),
					Color = P.sidewalk:Lerp(P.plasterWarm, shade),
					Material = Enum.Material.Pebble,
				}, folder)
			end
		end

		-- oprit naar de stoep
		decor({
			Name = "Apron",
			Size = Vector3.new(14, 1.4, 34),
			CFrame = CFrame.new(WALK_OUTER + 5, 0.7, zc),
			Color = P.sidewalk,
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, folder)

		-- hek langs de randen, met een opening naar de straat toe
		for _, dz in { -56, 56 } do
			Scenery.hedge(CFrame.new(PLOT_X + 8, 1.4, zc + dz), 90, folder)
		end
		for _, dz in { -40, 40 } do
			Scenery.hedge(wall(26, 1.4, zc + dz, 90), 28, folder)
		end

		-- toegangspoortje vanaf de stoep
		for _, dz in { -13, 13 } do
			decor({
				Name = "GatePost",
				Size = Vector3.new(3, 12, 3),
				CFrame = CFrame.new(28, 7, zc + dz),
				Color = P.metalDark,
				Material = Enum.Material.Metal,
				CanCollide = true,
			}, folder)
		end
		decor({
			Name = "GateBeam",
			Size = Vector3.new(3, 2, 29),
			CFrame = CFrame.new(28, 14, zc),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)

		-- wat groen en een bankje op het terrein
		Scenery.planter(CFrame.new(38, 1.4, zc + 44), folder)
		Scenery.planter(CFrame.new(38, 1.4, zc - 44), folder)
		Scenery.bench(wall(36, 1.4, zc, 90), folder)
		Scenery.lamppost(wall(34, 1.4, zc + 30, -90), folder)
		Scenery.lamppost(wall(34, 1.4, zc - 30, -90), folder)

		return folder, zc
	end

	local function stationProps(folder: Folder, station, zc: number, unlockColor: Color3)
		-- werkbank met de pers
		local bench = decor({
			Name = "WorkBench",
			Size = Vector3.new(16, 5, 10),
			CFrame = CFrame.new(52, 3.9, zc + 22),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		decor({
			Name = "PressArm",
			Size = Vector3.new(4, 9, 4),
			CFrame = CFrame.new(56, 10.9, zc + 22),
			Color = P.metal,
			Material = Enum.Material.Metal,
		}, folder)
		decor({
			Name = "PressHead",
			Size = Vector3.new(7, 2.4, 7),
			CFrame = CFrame.new(54, 7.5, zc + 22),
			Color = station.color,
			Material = Enum.Material.Metal,
		}, folder)
		Scenery.floatingText(bench, "<b>PENNEN MAKEN</b>", 6, 15, 60)

		local pressPad = part({
			Name = "Press_" .. station.key,
			Size = Vector3.new(16, 0.6, 14),
			CFrame = CFrame.new(40, 2, zc + 22),
			Color = Color3.fromRGB(90, 190, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			CanCollide = false,
		}, folder)
		Scenery.floatingText(pressPad, "ga hierop staan", 3.5, 13, 42)

		Scenery.crate(CFrame.new(64, 1.4, zc + 32), 5, folder)
		Scenery.crate(CFrame.new(64, 1.4, zc + 38), 4, folder)
		Scenery.crate(CFrame.new(69, 1.4, zc + 33), 4, folder)

		-- toonbank
		local counter = decor({
			Name = "Counter",
			Size = Vector3.new(6, 5, 20),
			CFrame = CFrame.new(54, 3.9, zc - 22),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, folder)
		decor({
			Name = "CounterTop",
			Size = Vector3.new(8, 0.6, 22),
			CFrame = CFrame.new(54, 6.5, zc - 22),
			Color = P.woodDark,
			Material = Enum.Material.Wood,
		}, folder)
		Scenery.floatingText(counter, "<b>TOONBANK</b>", 6, 15, 60)

		local sellPad = part({
			Name = "Sell_" .. station.key,
			Size = Vector3.new(14, 0.6, 20),
			CFrame = CFrame.new(42, 2, zc - 22),
			Color = Color3.fromRGB(120, 255, 150),
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			CanCollide = false,
		}, folder)
		Scenery.floatingText(sellPad, "verkopen", 3.5, 13, 42)

		-- uitstalrek met pennen naast de toonbank
		decor({
			Name = "DisplayRack",
			Size = Vector3.new(4, 9, 12),
			CFrame = CFrame.new(58, 5.9, zc - 36),
			Color = P.woodDark,
			Material = Enum.Material.Wood,
			CanCollide = true,
		}, folder)
		for i = 1, 6 do
			Scenery.cylinder({
				Name = "RackPen",
				Size = Vector3.new(6, 0.9, 0.9),
				CFrame = CFrame.new(56, 7 + (i % 2) * 3, zc - 41 + i * 1.6) * CFrame.Angles(0, 0, math.rad(80)),
				Color = i % 3 == 0 and P.neonPink or (i % 3 == 1 and P.gold or P.neonCyan),
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
		end

		-- parasol boven de wachtplek
		decor({
			Name = "UmbrellaPole",
			Size = Vector3.new(0.7, 14, 0.7),
			CFrame = CFrame.new(40, 8, zc + 2),
			Color = P.woodDark,
		}, folder)
		Scenery.cylinder({
			Name = "UmbrellaTop",
			Size = Vector3.new(1, 18, 18),
			CFrame = CFrame.new(40, 15, zc + 2) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.awningA,
			Material = Enum.Material.Fabric,
			CanCollide = false,
		}, folder)

		-- plekken waar de bezoekers komen staan (de client zet de poppetjes neer)
		for slot, dz in { -4, 8, 20 } do
			part({
				Name = string.format("VisitorSpot%d_%s", slot, station.key),
				Size = Vector3.new(4, 0.4, 4),
				CFrame = wall(36, 1.6, zc + dz, -90),
				Transparency = 1,
				CanCollide = false,
			}, folder)
		end

		-- de klant staat achter de toonbank en kijkt naar de speler toe (-X)
		part({
			Name = "Spot_" .. station.key,
			Size = Vector3.new(4, 0.4, 4),
			CFrame = wall(62, 1.6, zc - 22, -90),
			Transparency = 1,
			CanCollide = false,
		}, folder)

		-- bord bij de stoep met de naam van de zaak
		local sign = decor({
			Name = "PlotSign",
			Size = Vector3.new(1.6, 16, 1.6),
			CFrame = CFrame.new(34, 9, zc + 44),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)
		local unlockText = station.unlockRebirth == 0 and "open"
			or string.format("rebirth %d", station.unlockRebirth)
		Scenery.wallText(wall(34, 20, zc + 44, -90), 20, 9,
			string.format("%s\n<font size=\"28\">%s</font>", station.name, unlockText), unlockColor, folder)
		sign.Name = "PlotSign"
	end

	-- ------------------------------------------------------ gebouw per zaak ----

	local function buildKraam(folder: Folder, zc: number)
		-- houten marktkraam met luifel
		decor({
			Name = "StallFloor",
			Size = Vector3.new(30, 0.6, 40),
			CFrame = CFrame.new(84, 1.7, zc),
			Color = P.woodDark,
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, folder)
		for _, offset in { Vector3.new(-13, 0, -18), Vector3.new(-13, 0, 18), Vector3.new(13, 0, -18), Vector3.new(13, 0, 18) } do
			decor({
				Name = "StallPost",
				Size = Vector3.new(1.4, 16, 1.4),
				CFrame = CFrame.new(84 + offset.X, 10, zc + offset.Z),
				Color = P.wood,
				Material = Enum.Material.Wood,
			}, folder)
		end
		-- achterwand zodat de kraam niet in het niets staat
		local backWall = decor({
			Name = "StallBack",
			Size = Vector3.new(3, 26, 52),
			CFrame = CFrame.new(103, 14, zc),
			Color = P.brick,
			Material = Enum.Material.Brick,
			CanCollide = true,
		}, folder)
		decor({
			Name = "StallBackTop",
			Size = Vector3.new(5, 2, 54),
			CFrame = CFrame.new(103, 27, zc),
			Color = P.brick:Lerp(Color3.new(0, 0, 0), 0.3),
		}, folder)
		Scenery.windows(backWall.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 4, 1.6),
			40, 12, 3, 1, 0.5, folder)

		Scenery.awning(wall(72, 18.5, zc, 90), 40, 14, P.awningA, P.awningB, folder)
		Scenery.wallText(wall(98, 12, zc, -90), 22, 6, "PENNENKRAAM", P.gold, folder)
		Scenery.crate(CFrame.new(92, 2, zc - 12), 4, folder)
		Scenery.crate(CFrame.new(92, 2, zc + 12), 4, folder)
		Scenery.tree(CFrame.new(106, 1.4, zc + 30), 1.2, folder)
		Scenery.hedge(CFrame.new(100, 1.4, zc - 34), 30, folder)
	end

	local function buildWinkel(folder: Folder, zc: number)
		local body = decor({
			Name = "ShopBody",
			Size = Vector3.new(34, 32, 54),
			CFrame = CFrame.new(90, 17, zc),
			Color = P.plaster,
			Material = Enum.Material.Brick,
			CanCollide = true,
		}, folder)
		decor({
			Name = "ShopBase",
			Size = Vector3.new(35, 8, 55),
			CFrame = CFrame.new(90, 5, zc),
			Color = P.brick,
			Material = Enum.Material.Brick,
		}, folder)
		Scenery.storefront(wall(72.9, 1.4, zc, -90), 40, 13, folder)
		Scenery.awning(wall(72, 16, zc, -90), 42, 8, P.teal, P.awningB, folder)
		Scenery.windows(body.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 6, 17), 42, 14, 4, 2, 0.6, folder)
		Scenery.wallText(wall(72.4, 26, zc, -90), 30, 7, "PENNENWINKEL", P.neonPink, folder)
		decor({
			Name = "ShopRoof",
			Size = Vector3.new(37, 2, 57),
			CFrame = CFrame.new(90, 34, zc),
			Color = P.woodDark,
		}, folder)
		Scenery.planter(CFrame.new(76, 1.4, zc + 26), folder)
		Scenery.planter(CFrame.new(76, 1.4, zc - 26), folder)
	end

	local function buildFabriek(folder: Folder, zc: number)
		local body = decor({
			Name = "FactoryBody",
			Size = Vector3.new(44, 30, 76),
			CFrame = CFrame.new(96, 16, zc),
			Color = P.brick,
			Material = Enum.Material.Brick,
			CanCollide = true,
		}, folder)
		Scenery.windows(body.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 3, 22), 62, 18, 6, 2, 0.75, folder)
		Scenery.wallText(wall(73.6, 27, zc, -90), 34, 7, "PENNENFABRIEK", P.neonCyan, folder)

		-- rolluik
		decor({
			Name = "RollDoor",
			Size = Vector3.new(1, 16, 20),
			CFrame = CFrame.new(73.6, 9, zc - 4),
			Color = P.metal,
			Material = Enum.Material.DiamondPlate,
		}, folder)

		-- schoorstenen met rook
		for i, dz in { -22, 14 } do
			local stack = decor({
				Name = "Chimney",
				Size = Vector3.new(7, 34, 7),
				CFrame = CFrame.new(104, 45, zc + dz),
				Color = P.brick:Lerp(Color3.new(0, 0, 0), 0.2),
				Material = Enum.Material.Brick,
			}, folder)
			Scenery.smoke(stack, 10 + i * 2, Color3.fromRGB(210, 210, 214))
		end

		-- silo's
		for _, dz in { 30, 40 } do
			Scenery.cylinder({
				Name = "Silo",
				Size = Vector3.new(26, 14, 14),
				CFrame = CFrame.new(112, 14, zc + dz) * CFrame.Angles(0, 0, math.rad(90)),
				Color = P.metal,
				Material = Enum.Material.Metal,
				CanCollide = true,
			}, folder)
		end

		-- lopende band naar buiten
		decor({
			Name = "Conveyor",
			Size = Vector3.new(28, 1.2, 8),
			CFrame = CFrame.new(64, 6, zc + 6),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)
		for i = 1, 6 do
			Scenery.cylinder({
				Name = "ConveyorPen",
				Size = Vector3.new(6, 0.8, 0.8),
				CFrame = CFrame.new(54 + i * 4, 7, zc + 6) * CFrame.Angles(0, math.rad(90), math.rad(90)),
				Color = i % 2 == 0 and P.neonPink or P.gold,
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
		end
	end

	local function buildGroothandel(folder: Folder, zc: number)
		local body = decor({
			Name = "WarehouseBody",
			Size = Vector3.new(50, 34, 96),
			CFrame = CFrame.new(100, 18, zc),
			Color = Color3.fromRGB(176, 180, 188),
			Material = Enum.Material.DiamondPlate,
			CanCollide = true,
		}, folder)
		decor({
			Name = "WarehouseStripe",
			Size = Vector3.new(51, 5, 97),
			CFrame = CFrame.new(100, 26, zc),
			Color = P.teal,
		}, folder)
		Scenery.wallText(wall(74.6, 30, zc, -90), 40, 8, "GROOTHANDEL", P.gold, folder)
		for _, dz in { -30, 0, 30 } do
			decor({
				Name = "DockDoor",
				Size = Vector3.new(1.2, 18, 22),
				CFrame = CFrame.new(74.6, 10, zc + dz),
				Color = P.metalDark,
				Material = Enum.Material.DiamondPlate,
			}, folder)
			decor({
				Name = "DockRamp",
				Size = Vector3.new(12, 1.2, 22),
				CFrame = CFrame.new(68, 2.2, zc + dz),
				Color = P.curb,
				Material = Enum.Material.Concrete,
				CanCollide = true,
			}, folder)
		end
		for i = 1, 6 do
			Scenery.crate(CFrame.new(62 + (i % 3) * 7, 1.4, zc - 46 + i * 5), 5, folder)
		end
		-- vrachtwagen
		decor({
			Name = "TruckBox",
			Size = Vector3.new(14, 14, 34),
			CFrame = CFrame.new(50, 9, zc + 48),
			Color = P.plaster,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		decor({
			Name = "TruckCab",
			Size = Vector3.new(13, 11, 12),
			CFrame = CFrame.new(50, 7.5, zc + 70),
			Color = P.awningA,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		for _, dz in { 38, 46, 64 } do
			Scenery.cylinder({
				Name = "Wheel",
				Size = Vector3.new(15, 6, 6),
				CFrame = CFrame.new(50, 3, zc + dz) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(90), 0),
				Color = Color3.fromRGB(32, 32, 36),
			}, folder)
		end
	end

	local function buildToren(folder: Folder, zc: number)
		local height = 150
		local body = decor({
			Name = "TowerBody",
			Size = Vector3.new(44, height, 56),
			CFrame = CFrame.new(98, height / 2, zc),
			Color = Color3.fromRGB(96, 124, 150),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
			Reflectance = 0.35,
			CanCollide = true,
		}, folder)
		for _, face in { { yaw = -90, w = 56, d = 22 }, { yaw = 90, w = 56, d = 22 },
			{ yaw = 0, w = 44, d = 28 }, { yaw = 180, w = 44, d = 28 } } do
			Scenery.windows(
				body.CFrame * CFrame.Angles(0, math.rad(face.yaw), 0) * CFrame.new(0, 0, face.d),
				face.w - 6, height - 20, math.max(3, math.floor(face.w / 10)), 12, 0.55, folder
			)
		end
		decor({
			Name = "TowerCrown",
			Size = Vector3.new(30, 16, 38),
			CFrame = CFrame.new(98, height + 8, zc),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)
		decor({
			Name = "TowerAntenna",
			Size = Vector3.new(1.6, 26, 1.6),
			CFrame = CFrame.new(98, height + 29, zc),
			Color = P.neonPink,
			Material = Enum.Material.Neon,
		}, folder)
		-- luifel boven de ingang
		decor({
			Name = "Canopy",
			Size = Vector3.new(16, 1.2, 34),
			CFrame = CFrame.new(68, 16, zc),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)
		Scenery.wallText(wall(75.6, 26, zc, -90), 34, 8, "PEN STREET TOREN", P.neonCyan, folder)
		Scenery.storefront(wall(75.9, 1.4, zc, -90), 30, 14, folder)
		for _, dz in { -22, 22 } do
			decor({
				Name = "Flagpole",
				Size = Vector3.new(0.8, 22, 0.8),
				CFrame = CFrame.new(70, 12, zc + dz),
				Color = P.metal,
				Material = Enum.Material.Metal,
			}, folder)
			decor({
				Name = "Flag",
				Size = Vector3.new(0.3, 7, 11),
				CFrame = CFrame.new(70, 19, zc + dz + 5.5),
				Color = P.neonPink,
				Material = Enum.Material.Fabric,
			}, folder)
		end
		Scenery.hedge(CFrame.new(64, 1.4, zc + 40), 28, folder)
		Scenery.hedge(CFrame.new(64, 1.4, zc - 40), 28, folder)
	end

	local function buildPenthouse(folder: Folder, zc: number)
		-- terras op kolommen
		for _, offset in { Vector3.new(-20, 0, -30), Vector3.new(-20, 0, 30), Vector3.new(24, 0, -30), Vector3.new(24, 0, 30) } do
			decor({
				Name = "Column",
				Size = Vector3.new(6, 26, 6),
				CFrame = CFrame.new(96 + offset.X, 14, zc + offset.Z),
				Color = P.plaster,
				Material = Enum.Material.Marble,
				CanCollide = true,
			}, folder)
		end
		decor({
			Name = "Terrace",
			Size = Vector3.new(60, 2, 78),
			CFrame = CFrame.new(98, 28, zc),
			Color = P.plaster,
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, folder)
		-- zwembad
		decor({
			Name = "PoolWall",
			Size = Vector3.new(26, 3, 34),
			CFrame = CFrame.new(104, 30.5, zc),
			Color = P.plaster,
			Material = Enum.Material.Marble,
		}, folder)
		decor({
			Name = "PoolWater",
			Size = Vector3.new(22, 2.4, 30),
			CFrame = CFrame.new(104, 30.8, zc),
			Color = P.water,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
		}, folder)
		-- glazen balustrade
		for _, dz in { -39, 39 } do
			decor({
				Name = "Railing",
				Size = Vector3.new(60, 7, 0.6),
				CFrame = CFrame.new(98, 32.5, zc + dz),
				Color = P.glass,
				Material = Enum.Material.Glass,
				Transparency = 0.6,
				Reflectance = 0.3,
			}, folder)
		end
		decor({
			Name = "RailingFront",
			Size = Vector3.new(0.6, 7, 78),
			CFrame = CFrame.new(68, 32.5, zc),
			Color = P.glass,
			Material = Enum.Material.Glass,
			Transparency = 0.6,
			Reflectance = 0.3,
		}, folder)
		-- ligbedden en parasol
		for _, dz in { -14, -6 } do
			decor({
				Name = "Lounger",
				Size = Vector3.new(11, 1.2, 4),
				CFrame = CFrame.new(84, 30, zc + dz),
				Color = P.awningB,
				Material = Enum.Material.Fabric,
			}, folder)
		end
		decor({
			Name = "Parasol",
			Size = Vector3.new(0.6, 12, 0.6),
			CFrame = CFrame.new(84, 36, zc + 4),
			Color = P.woodDark,
		}, folder)
		Scenery.cylinder({
			Name = "ParasolTop",
			Size = Vector3.new(1, 16, 16),
			CFrame = CFrame.new(84, 42, zc + 4) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.awningA,
			Material = Enum.Material.Fabric,
		}, folder)
		Scenery.wallText(wall(68, 42, zc, -90), 30, 7, "PENTHOUSE", P.gold, folder)
		-- trap naar beneden
		for i = 1, 9 do
			decor({
				Name = "Step",
				Size = Vector3.new(6, 3, 18),
				CFrame = CFrame.new(64 - i * 2, 28 - i * 3, zc),
				Color = P.plaster,
				Material = Enum.Material.Marble,
				CanCollide = true,
			}, folder)
		end
	end

	local function buildJacht(folder: Folder, zc: number)
		-- haven met water
		decor({
			Name = "Harbour",
			Size = Vector3.new(120, 1, 120),
			CFrame = CFrame.new(112, 1.2, zc),
			Color = P.water,
			Material = Enum.Material.Glass,
			Transparency = 0.25,
			CanCollide = true,
		}, folder)
		decor({
			Name = "Quay",
			Size = Vector3.new(18, 3, 120),
			CFrame = CFrame.new(60, 2.2, zc),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, folder)
		-- romp
		decor({
			Name = "Hull",
			Size = Vector3.new(34, 12, 86),
			CFrame = CFrame.new(96, 6, zc),
			Color = P.plaster,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = true,
		}, folder)
		Scenery.wedge({
			Name = "Bow",
			Size = Vector3.new(34, 12, 22),
			CFrame = CFrame.new(96, 6, zc - 54) * CFrame.Angles(0, math.rad(180), 0),
			Color = P.plaster,
			Anchored = true,
		}, folder)
		decor({
			Name = "Deck",
			Size = Vector3.new(34, 1.2, 86),
			CFrame = CFrame.new(96, 12.5, zc),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, folder)
		decor({
			Name = "Cabin",
			Size = Vector3.new(24, 13, 34),
			CFrame = CFrame.new(96, 19, zc + 12),
			Color = P.plaster,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = true,
		}, folder)
		Scenery.windows(
			CFrame.new(96, 20, zc - 5.2) * CFrame.Angles(0, math.rad(180), 0),
			20, 8, 3, 1, 1, folder
		)
		decor({
			Name = "Bridge",
			Size = Vector3.new(16, 8, 20),
			CFrame = CFrame.new(96, 29, zc + 16),
			Color = P.plaster,
		}, folder)
		decor({
			Name = "Mast",
			Size = Vector3.new(1, 26, 1),
			CFrame = CFrame.new(96, 45, zc + 16),
			Color = P.metal,
			Material = Enum.Material.Metal,
		}, folder)
		Scenery.wallText(wall(78.5, 20, zc - 20, -90), 26, 6, "PENJACHT", P.neonCyan, folder)
		for _, dz in { -30, 0, 30 } do
			decor({
				Name = "Bollard",
				Size = Vector3.new(2.4, 4, 2.4),
				CFrame = CFrame.new(66, 5, zc + dz),
				Color = P.metalDark,
				Material = Enum.Material.Metal,
			}, folder)
		end
	end

	local function buildOrbit(folder: Folder, zc: number)
		decor({
			Name = "Platform",
			Size = Vector3.new(70, 3, 90),
			CFrame = CFrame.new(100, 30, zc),
			Color = Color3.fromRGB(46, 50, 72),
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		decor({
			Name = "PlatformGlow",
			Size = Vector3.new(72, 0.8, 92),
			CFrame = CFrame.new(100, 28.4, zc),
			Color = Color3.fromRGB(150, 110, 240),
			Material = Enum.Material.Neon,
		}, folder)
		for i = 1, 3 do
			Scenery.cylinder({
				Name = "Ring",
				Size = Vector3.new(2, 44 + i * 16, 44 + i * 16),
				CFrame = CFrame.new(100, 52 + i * 6, zc) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(18 * i), 0, 0),
				Color = i % 2 == 0 and P.neonCyan or Color3.fromRGB(180, 110, 240),
				Material = Enum.Material.Neon,
				Transparency = 0.25,
				CanCollide = false,
			}, folder)
		end
		for i = 1, 22 do
			Scenery.ball({
				Name = "Star",
				Size = Vector3.new(1.6, 1.6, 1.6),
				CFrame = CFrame.new(70 + math.random(0, 80), 40 + math.random(0, 70), zc - 50 + math.random(0, 100)),
				Color = Color3.fromRGB(255, 255, 240),
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
		end
		-- lift omhoog vanaf het terrein
		for i = 1, 14 do
			decor({
				Name = "FloatStep",
				Size = Vector3.new(10, 1, 10),
				CFrame = CFrame.new(60 + i * 1.5, 3 + i * 2, zc - 30 + i * 2),
				Color = Color3.fromRGB(150, 110, 240),
				Material = Enum.Material.Neon,
				Transparency = 0.2,
				CanCollide = true,
			}, folder)
		end
		Scenery.wallText(wall(64, 46, zc, -90), 30, 7, "PEN ORBIT", Color3.fromRGB(190, 140, 255), folder)
	end

	-- Een zaak die je nog niet hebt vrijgespeeld is een bouwput: hekken, steigers,
	-- een kraan en een bord. De client haalt dit weg zodra jij hem opent, dus je
	-- ziet de stad meegroeien met je rebirths.
	local function buildConstruction(folder: Folder, station, zc: number)
		local site = Instance.new("Folder")
		site.Name = "Construction"
		site.Parent = folder

		-- hekken rond het terrein, met de opening naar de straat dicht
		Scenery.fence(wall(30, 1.4, zc, 0), 108, site)
		Scenery.fence(wall(PLOT_X + 8, 1.4, zc + 56, 90), 92, site)
		Scenery.fence(wall(PLOT_X + 8, 1.4, zc - 56, 90), 92, site)

		Scenery.crane(CFrame.new(PLOT_X + 34, 1.4, zc + 34), 70, site)
		Scenery.scaffold(wall(74, 1.4, zc, -90), 50, 40, site)

		for i = 1, 6 do
			Scenery.cone(CFrame.new(33, 1.4, zc - 30 + i * 10), site)
		end
		Scenery.crate(CFrame.new(50, 1.4, zc + 44), 5, site)
		Scenery.crate(CFrame.new(56, 1.4, zc + 44), 4, site)

		decor({
			Name = "SiteHut",
			Size = Vector3.new(12, 9, 20),
			CFrame = CFrame.new(46, 6.4, zc - 44),
			Color = Color3.fromRGB(216, 176, 60),
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, site)

		Scenery.wallText(wall(29, 18, zc, -90), 26, 10,
			string.format("IN AANBOUW\n<font size=\"30\">%s opent na rebirth %d</font>",
				station.name, station.unlockRebirth), Color3.fromRGB(255, 200, 80), site)
	end

	local BUILDERS: { [string]: (Folder, number) -> () } = {
		kraam = buildKraam,
		winkel = buildWinkel,
		fabriek = buildFabriek,
		groothandel = buildGroothandel,
		toren = buildToren,
		penthouse = buildPenthouse,
		jacht = buildJacht,
		orbit = buildOrbit,
	}

	-- ------------------------------------------------------------------ bouw ---

	function World.build(): Folder
		local existing = Workspace:FindFirstChild("PenWorld")
		if existing then
			existing:Destroy()
		end

		local root = Instance.new("Folder")
		root.Name = "PenWorld"
		root.Parent = Workspace

		setupLighting()

		local lastZ = blockZ(#Config.Stations)
		local totalLength = math.abs(lastZ) + 260
		buildStreet(root, totalLength, (140 + lastZ - 80) / 2)

		local plaza = buildPlaza(root)
		buildKiosks(plaza)
		buildRebirthPortal(plaza)
		buildPetStand(plaza)
		buildBoard(plaza, "Board_cash", wall(60, 30, 78, -90), "RIJKSTE VERKOPERS")
		buildBoard(plaza, "Board_rebirths", wall(60, 30, 110, -90), "MEESTE REBIRTHS")

		-- lage panden die het plein omsluiten, zodat het geen losse vlakte is
		for _, side in { -1, 1 } do
			local z = 18
			while z < 140 do
				local height = 22 + math.random(0, 12)
				local depth = 34
				local width = 26 + math.random(0, 10)
				local body = decor({
					Name = "PlazaShop",
					Size = Vector3.new(depth, height, width),
					CFrame = CFrame.new(side * 99, height / 2, z + width / 2),
					Color = ({ P.brick, P.plaster, P.plasterWarm, P.teal })[math.random(4)],
					Material = Enum.Material.Brick,
					CanCollide = true,
				}, root)
				Scenery.windows(
					body.CFrame * CFrame.Angles(0, math.rad(side > 0 and 90 or -90), 0) * CFrame.new(0, 4, depth / 2),
					width * 0.8, height * 0.55, 3, 2, 0.5, root
				)
				Scenery.storefront(wall(side * 82.2, 1.4, z + width / 2, side > 0 and 90 or -90), width * 0.6, 11, root)
				Scenery.awning(wall(side * 81.3, 13.6, z + width / 2, side > 0 and 90 or -90), width * 0.62, 6,
					({ P.awningA, P.teal, P.neonPink })[math.random(3)], P.awningB, root)
				z += width + 4
			end
		end

		-- het stuk tussen het plein en de eerste zaak
		dressBlock(root, 6, World.FIRST_BLOCK_Z + 60, DISTRICTS[1], 0)

		for index, station in Config.Stations do
			local folder, zc = stationShell(root, station, index)
			local builder = BUILDERS[station.key]
			if builder then
				builder(folder, zc)
			end
			stationProps(folder, station, zc,
				station.unlockRebirth == 0 and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(200, 120, 255))

			local district = districtOf(index)
			dressBlock(root, zc + 59, zc - 61, district, index)
			if station.unlockRebirth > 0 then
				buildConstruction(folder, station, zc)
			end
		end

		-- stad eromheen: eerst een dichte band vlak achter de gevels, daarachter
		-- lagere blokken in de verte. Zo kijk je nooit uit op een leeg veld.
		local near = { minHeight = 34, maxHeight = 78, cool = 0.15, jitter = 8 }
		local far = { minHeight = 80, maxHeight = 190, cool = 0.55, jitter = 16 }
		local rows = math.max(6, math.floor((math.abs(lastZ) + 260) / 62))
		Scenery.skyline(Vector3.new(-152, 0, 120), 62, rows, 90, root, near)
		Scenery.skyline(Vector3.new(-250, 0, 140), 92, math.floor(rows * 0.6), 90, root, far)
		Scenery.skyline(Vector3.new(214, 0, 120), 64, rows, -90, root, near)
		Scenery.skyline(Vector3.new(320, 0, 140), 92, math.floor(rows * 0.6), -90, root, far)
		-- afsluiting aan beide uiteinden van de straat (rij loopt over de X-as)
		local endCap = { minHeight = 70, maxHeight = 160, cool = 0.5, jitter = 12, axis = "x" }
		Scenery.skyline(Vector3.new(-180, 0, lastZ - 170), 86, 6, 0, root, endCap)
		Scenery.skyline(Vector3.new(-180, 0, 250), 86, 6, 180, root, endCap)

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
		-- de plek zelf wijst al de goede kant op (naar de speler toe)
		local facing = spot.CFrame

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
		gui.Size = UDim2.fromScale(9, 2.7)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 60
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
		tl.TextSize = 15
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

PEN.Visitors = (function()
	--!strict
	-- Bezoekers: los van de gewone klanten lopen er mensen je terrein op met een
	-- bestelling voor een bepaald soort pen. Hoe zeldzamer, hoe meer ze betalen.
	-- Wie je getrade hebt komt in je index en kun je daarna inhuren als personeel.
	--
	-- De bezoekers zijn persoonlijk: iedereen heeft zijn eigen kansen. De server
	-- houdt alleen de gegevens bij; de client zet de poppetjes neer.

	local Config = PEN.Config

	local Visitors = {}

	export type Visit = {
		id: number,
		visitor: string,
		rarity: string,
		station: string,
		amount: number,
		slot: number,
		expiresAt: number,
	}

	local active: { [Player]: { Visit } } = {}
	local nextRoll: { [Player]: { number } } = {}
	local counter = 0

	local function luckOf(profile): number
		return math.min(Config.Visit.maxLuck, 1 + profile.rebirths * Config.Visit.luckPerRebirth)
	end

	local function rollRarity(luck: number)
		local total = 0
		local weights = {}
		for i, r in Config.Rarities do
			-- alleen de zeldzame kant profiteert van geluk
			local weight = r.weight < 100 and r.weight * luck or r.weight
			weights[i] = weight
			total += weight
		end
		local pick = math.random() * total
		for i, r in Config.Rarities do
			pick -= weights[i]
			if pick <= 0 then
				return r
			end
		end
		return Config.Rarities[1]
	end

	-- Zeldzame bezoekers willen pennen uit je duurdere zaken.
	local function pickStation(profile, rarityKey: string): string
		local unlocked = {}
		for _, station in Config.Stations do
			if profile.rebirths >= station.unlockRebirth then
				table.insert(unlocked, station)
			end
		end
		if #unlocked == 0 then
			return Config.Stations[1].key
		end
		local rarityIndex = Config.rarityIndex(rarityKey)
		local lowest = math.clamp(
			math.ceil(#unlocked * (rarityIndex - 1) / #Config.Rarities),
			1, #unlocked
		)
		return unlocked[math.random(lowest, #unlocked)].key
	end

	function Visitors.init(player: Player)
		active[player] = {}
		nextRoll[player] = {}
		for slot = 1, Config.Visit.slots do
			-- de eerste bezoeker laat niet de volle wachttijd op zich wachten
			nextRoll[player][slot] = os.clock() + 8 + slot * 12
		end
	end

	function Visitors.clear(player: Player)
		active[player] = nil
		nextRoll[player] = nil
	end

	function Visitors.list(player: Player): { Visit }
		return active[player] or {}
	end

	local function slotTaken(player: Player, slot: number): boolean
		for _, visit in Visitors.list(player) do
			if visit.slot == slot then
				return true
			end
		end
		return false
	end

	-- Laat bezoekers vertrekken en probeer lege plekken te vullen.
	-- Geeft terug wie er nieuw is aangekomen.
	function Visitors.tick(player: Player, profile, now: number, capacity: number): { Visit }
		local list = active[player]
		local rolls = nextRoll[player]
		if not list or not rolls then
			return {}
		end

		for i = #list, 1, -1 do
			if now >= list[i].expiresAt then
				table.remove(list, i)
			end
		end

		local arrived = {}
		for slot = 1, Config.Visit.slots do
			if now >= (rolls[slot] or 0) and not slotTaken(player, slot) then
				rolls[slot] = now + Config.Visit.spawnSeconds
				if math.random() <= Config.Visit.spawnChance then
					local rarity = rollRarity(luckOf(profile))
					local options = Config.visitorsOfRarity(rarity.key)
					if #options > 0 then
						counter += 1
						local stationKey = pickStation(profile, rarity.key)
						local wanted = math.random(rarity.orderMin, rarity.orderMax)
						local visit: Visit = {
							id = counter,
							visitor = options[math.random(#options)].key,
							rarity = rarity.key,
							station = stationKey,
							-- nooit meer dan er in je tas past
							amount = math.clamp(wanted, 1, math.max(1, capacity)),
							slot = slot,
							expiresAt = now + Config.Visit.staySeconds,
						}
						table.insert(list, visit)
						table.insert(arrived, visit)
					end
				end
			end
		end
		return arrived
	end

	function Visitors.find(player: Player, id: number): Visit?
		for _, visit in Visitors.list(player) do
			if visit.id == id then
				return visit
			end
		end
		return nil
	end

	function Visitors.remove(player: Player, id: number)
		local list = active[player]
		if not list then
			return
		end
		for i, visit in list do
			if visit.id == id then
				table.remove(list, i)
				return
			end
		end
	end

	-- Wat een bezoeker oplevert, nog zonder de multipliers van de speler.
	function Visitors.basePayout(visit: Visit): number
		local station = Config.getStation(visit.station)
		local rarity = Config.getRarity(visit.rarity)
		if not station then
			return 0
		end
		return visit.amount * station.pen.value * rarity.payout
	end

	function Visitors.describe(visit: Visit)
		local visitor = Config.getVisitor(visit.visitor)
		local rarity = Config.getRarity(visit.rarity)
		local station = Config.getStation(visit.station)
		return {
			id = visit.id,
			slot = visit.slot,
			name = visitor and visitor.name or visit.visitor,
			line = visitor and visitor.line or "",
			rarityKey = rarity.key,
			rarityName = rarity.name,
			rarityColor = rarity.color,
			station = visit.station,
			penName = station and station.pen.name or "",
			amount = visit.amount,
			basePayout = Visitors.basePayout(visit),
			expiresAt = visit.expiresAt,
		}
	end

	return Visitors
end)()

PEN.Staff = (function()
	--!strict
	-- Personeel: bezoekers die je al getrade hebt kun je in dienst nemen. Ze maken
	-- pennen voor je, raken vermoeid van doorwerken en willen elke dag loon.
	-- Betaal je niet op tijd, dan nemen ze ontslag - maar ze blijven in je index,
	-- dus je kunt ze later opnieuw inhuren.

	local Config = PEN.Config

	local Staff = {}

	export type Member = {
		key: string,
		stamina: number,
		lastPaidAt: number,
		resting: boolean?,
	}

	function Staff.slots(profile): number
		local slots = Config.Staff.baseSlots + math.floor(profile.rebirths * Config.Staff.slotsPerRebirth)
		return math.min(Config.Staff.maxSlots, slots)
	end

	function Staff.find(profile, key: string): Member?
		for _, member in profile.staff do
			if member.key == key then
				return member
			end
		end
		return nil
	end

	function Staff.rarityOf(key: string)
		local visitor = Config.getVisitor(key)
		return Config.getRarity(visitor and visitor.rarity or "common")
	end

	function Staff.wage(key: string): number
		return Staff.rarityOf(key).wage
	end

	function Staff.hireCost(key: string): number
		return math.floor(Staff.wage(key) * Config.Staff.hireCostFactor)
	end

	function Staff.canHire(profile, key: string): (boolean, string)
		if not Config.getVisitor(key) then
			return false, "Die kennen we niet."
		end
		if not profile.index[key] then
			return false, "Je hebt nog niet met hem getrade."
		end
		if Staff.find(profile, key) then
			return false, "Die werkt al voor je."
		end
		if #profile.staff >= Staff.slots(profile) then
			return false, "Je hebt geen plek meer - rebirth geeft er meer."
		end
		return true, ""
	end

	function Staff.hire(profile, key: string, now: number)
		table.insert(profile.staff, {
			key = key,
			stamina = Staff.rarityOf(key).stamina,
			lastPaidAt = now,
			resting = false,
		})
	end

	function Staff.fire(profile, key: string)
		for i, member in profile.staff do
			if member.key == key then
				table.remove(profile.staff, i)
				return
			end
		end
	end

	function Staff.wageDueIn(member: Member, now: number): number
		return (member.lastPaidAt + Config.Staff.wagePeriod) - now
	end

	function Staff.pay(profile, key: string, now: number): number?
		local member = Staff.find(profile, key)
		if not member then
			return nil
		end
		local wage = Staff.wage(key)
		if profile.cash < wage then
			return nil
		end
		profile.cash -= wage
		member.lastPaidAt = now
		return wage
	end

	-- Pennen per seconde die het personeel op dit moment maakt.
	function Staff.workRate(profile): number
		local rate = 0
		for _, member in profile.staff do
			if member.stamina > 0 and not member.resting then
				rate += Staff.rarityOf(member.key).workRate
			end
		end
		return rate
	end

	-- Stamina bijwerken en kijken wie er weg is. Geeft de vertrekkers terug.
	function Staff.tick(profile, now: number, dt: number): { string }
		local left = {}
		for i = #profile.staff, 1, -1 do
			local member = profile.staff[i]
			local max = Staff.rarityOf(member.key).stamina

			if member.resting then
				member.stamina = math.min(max, member.stamina + Config.Staff.recoverPerSecond * dt)
				if member.stamina >= max * (Config.Staff.resumeAt / 100) then
					member.resting = false
				end
			else
				member.stamina = math.max(0, member.stamina - Config.Staff.drainPerSecond * dt)
				if member.stamina <= 0 then
					member.resting = true
				end
			end

			if Staff.wageDueIn(member, now) < -Config.Staff.graceSeconds then
				table.remove(profile.staff, i)
				table.insert(left, member.key)
			end
		end
		return left
	end

	function Staff.describe(profile, now: number)
		local out = {}
		for _, member in profile.staff do
			local visitor = Config.getVisitor(member.key)
			local rarity = Staff.rarityOf(member.key)
			table.insert(out, {
				key = member.key,
				name = visitor and visitor.name or member.key,
				rarityName = rarity.name,
				rarityColor = rarity.color,
				stamina = math.floor(member.stamina),
				maxStamina = rarity.stamina,
				resting = member.resting == true,
				workRate = rarity.workRate,
				wage = rarity.wage,
				wageDueIn = math.floor(Staff.wageDueIn(member, now)),
			})
		end
		return out
	end

	return Staff
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
		gui.Size = UDim2.fromScale(4.5, 1.1)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 35
		gui.Adornee = body
		gui.Parent = body

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 12
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
	local Visitors = PEN.Visitors
	local Staff = PEN.Staff

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

	local function announce(text: string, color: Color3)
		Net.event("Announce"):FireAllClients({ text = text, color = color })
	end

	local function notify(player: Player, text: string, color: Color3?)
		Net.event("Notify"):FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
	end

	-- ------------------------------------------------------------------ tas ---
	-- De tas houdt per soort zaak bij hoeveel pennen erin zitten, want bezoekers
	-- vragen om een bepaald soort.

	local function bagCount(profile): number
		local total = 0
		for _, amount in profile.bag do
			total += amount
		end
		return total
	end

	local function bagValue(profile): number
		local total = 0
		for key, amount in profile.bag do
			local station = Config.getStation(key)
			if station then
				total += amount * station.pen.value
			end
		end
		return total
	end

	local function bagContents(profile)
		local rows = {}
		for _, station in Config.Stations do
			local amount = profile.bag[station.key]
			if amount and amount > 0 then
				table.insert(rows, { station = station.key, name = station.pen.name, amount = amount })
			end
		end
		return rows
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
		-- personeel maakt pennen van je beste zaak
		local best = Config.stationForRebirths(profile.rebirths)
		total += Staff.workRate(profile) * best.pen.value
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

		local count = bagCount(profile)
		local visits = {}
		for _, visit in Visitors.list(player) do
			local row = Visitors.describe(visit)
			row.payout = math.floor(row.basePayout * cashMultiplier(player, profile))
			row.have = profile.bag[row.station] or 0
			row.canTrade = row.have >= row.amount
			table.insert(visits, row)
		end

		local indexRows = {}
		for _, visitor in Config.Visitors do
			local rarity = Config.getRarity(visitor.rarity)
			table.insert(indexRows, {
				key = visitor.key,
				name = visitor.name,
				rarityKey = rarity.key,
				rarityName = rarity.name,
				rarityColor = rarity.color,
				traded = profile.index[visitor.key] or 0,
				odds = math.floor(Config.rarityOdds(rarity.key,
					math.min(Config.Visit.maxLuck, 1 + profile.rebirths * Config.Visit.luckPerRebirth))),
				hired = Staff.find(profile, visitor.key) ~= nil,
				hireCost = Staff.hireCost(visitor.key),
			})
		end

		return {
			cash = profile.cash,
			pens = count,
			penValue = count > 0 and bagValue(profile) / count or 0,
			bagRows = bagContents(profile),
			capacity = capacityOf(player, profile),
			bagValue = math.floor(bagValue(profile) * cashMultiplier(player, profile)),
			visitors = visits,
			indexRows = indexRows,
			staff = Staff.describe(profile, os.time()),
			staffSlots = Staff.slots(profile),
			staffRate = Staff.workRate(profile),
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
			local cash = stats:FindFirstChild("Cash") :: StringValue?
			local pens = stats:FindFirstChild("Pennen") :: IntValue?
			local rb = stats:FindFirstChild("Rebirths") :: IntValue?
			if cash then cash.Value = "$" .. Config.short(profile.cash) end
			if pens then pens.Value = bagCount(profile) end
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
		local sold = bagCount(profile)
		local rawValue = bagValue(profile)
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
		local earned = math.floor(rawValue * cashMultiplier(player, profile) * total)

		profile.cash += earned
		profile.totalSold += sold
		profile.bag = {}
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
			pens = bagCount(profile),
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
			pens = bagCount(profile),
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
		profile.bag = {}
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

	local function tradeVisitor(player: Player, id: number)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local visit = Visitors.find(player, id)
		if not visit then
			notify(player, "Die bezoeker is al vertrokken.", Color3.fromRGB(255, 150, 150))
			return
		end
		local have = profile.bag[visit.station] or 0
		local station = Config.getStation(visit.station)
		local visitor = Config.getVisitor(visit.visitor)
		local rarity = Config.getRarity(visit.rarity)
		if not station or not visitor then
			return
		end
		if have < visit.amount then
			notify(player, string.format("%s wil %d x %s - je hebt er %d",
				visitor.name, visit.amount, station.pen.name, have), Color3.fromRGB(255, 150, 150))
			return
		end

		local earned = math.floor(Visitors.basePayout(visit) * cashMultiplier(player, profile))
		profile.bag[visit.station] = have - visit.amount
		if profile.bag[visit.station] <= 0 then
			profile.bag[visit.station] = nil
		end
		profile.cash += earned
		profile.totalSold += visit.amount
		local firstTime = (profile.index[visitor.key] or 0) == 0
		profile.index[visitor.key] = (profile.index[visitor.key] or 0) + 1
		profile.dirty = true
		Visitors.remove(player, id)

		notify(player, string.format("%s (%s) betaalde $%s voor %d x %s",
			visitor.name, rarity.name, Config.short(earned), visit.amount, station.pen.name), rarity.color)
		if firstTime then
			notify(player, string.format("Nieuw in je index: %s", visitor.name), rarity.color)
		end
		push(player)
		Data.save(player)
	end

	local function hireStaff(player: Player, key: string)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local ok, reason = Staff.canHire(profile, key)
		if not ok then
			notify(player, reason, Color3.fromRGB(255, 150, 150))
			return
		end
		local cost = Staff.hireCost(key)
		if profile.cash < cost then
			notify(player, string.format("Inhuren kost $%s", Config.short(cost)), Color3.fromRGB(255, 150, 150))
			return
		end
		profile.cash -= cost
		Staff.hire(profile, key, os.time())
		profile.dirty = true
		local visitor = Config.getVisitor(key)
		notify(player, string.format("%s komt bij je werken.", visitor and visitor.name or key),
			Color3.fromRGB(120, 255, 150))
		push(player)
	end

	local function payStaff(player: Player, key: string)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local paid = Staff.pay(profile, key, os.time())
		if not paid then
			notify(player, string.format("Je hebt $%s nodig om hem te betalen", Config.short(Staff.wage(key))),
				Color3.fromRGB(255, 150, 150))
			return
		end
		profile.dirty = true
		local visitor = Config.getVisitor(key)
		notify(player, string.format("%s is betaald ($%s)", visitor and visitor.name or key, Config.short(paid)),
			Color3.fromRGB(120, 255, 150))
		push(player)
	end

	local function fireStaff(player: Player, key: string)
		local profile = Data.get(player)
		if not profile then
			return
		end
		Staff.fire(profile, key)
		profile.dirty = true
		push(player)
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
		-- Cash is een StringValue: een IntValue loopt vast op 2.147.483.647,
		-- en dat bedrag haal je in deze game ruim voorbij.
		local cashValue = Instance.new("StringValue")
		cashValue.Name = "Cash"
		cashValue.Parent = stats
		for _, name in { "Pennen", "Rebirths" } do
			local v = Instance.new("IntValue")
			v.Name = name
			v.Parent = stats
		end
		stats.Parent = player

		nextProduce[player] = 0
		nextSell[player] = 0
		nextUpgrade[player] = 0
		nextHint[player] = 0
		Visitors.init(player)

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
		Visitors.clear(player)
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
					while now >= (nextProduce[player] or 0) and bagCount(profile) < capacity and made < 64 do
						profile.bag[station.key] = (profile.bag[station.key] or 0) + 1
						made += 1
						nextProduce[player] = math.max((nextProduce[player] or now) + interval, now - interval)
					end
					if made > 0 then
						profile.dirty = true
						push(player)
					elseif bagCount(profile) >= capacity and now >= (nextProduce[player] or 0) then
						nextProduce[player] = now + 1.5
						hint(player, now, "Je tas zit vol - ga pitchen bij de toonbank!")
					end
				end
			end

			local sellPad = pads["Sell_" .. station.key]
			if sellPad and isOnPad(root, sellPad) then
				if not stationUnlocked(profile, station) then
					hint(player, now, string.format("%s opent na rebirth %d", station.name, station.unlockRebirth))
				elseif bagCount(profile) > 0 and not pitches[player] and now >= (nextSell[player] or 0) then
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
		Net.event("TradeVisitor").OnServerEvent:Connect(function(player, id)
			if typeof(id) == "number" then
				tradeVisitor(player, math.floor(id))
			end
		end)
		Net.event("HireStaff").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				hireStaff(player, key)
			end
		end)
		Net.event("PayStaff").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				payStaff(player, key)
			end
		end)
		Net.event("FireStaff").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				fireStaff(player, key)
			end
		end)

		Net.event("Travel").OnServerEvent:Connect(function(player, key)
			if typeof(key) ~= "string" then
				return
			end
			local profile = Data.get(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not profile or not root or not root:IsA("BasePart") then
				return
			end
			for _, station in Config.Stations do
				if station.key == key then
					if not stationUnlocked(profile, station) then
						notify(player, string.format("%s opent na rebirth %d", station.name, station.unlockRebirth),
							Color3.fromRGB(255, 150, 150))
						return
					end
					local pad = pads["Press_" .. key]
					if pad then
						pitches[player] = nil
						-- met StreamingEnabled moet de omgeving er eerst zijn,
						-- anders val je door de grond bij aankomst
						pcall(function()
							player:RequestStreamAroundAsync(pad.Position, 10)
						end)
						root.CFrame = pad.CFrame * CFrame.new(0, 6, 0)
						notify(player, "Onderweg naar " .. station.name, Color3.fromRGB(150, 210, 255))
					end
					return
				end
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

		-- bezoekers laten komen en gaan, en het personeel bijhouden
		task.spawn(function()
			local last = os.clock()
			while true do
				task.wait(2)
				local now = os.clock()
				local dt = now - last
				last = now
				local stamp = os.time()

				for player, profile in Data.all() do
					local changed = false

					local arrived = Visitors.tick(player, profile, now, capacityOf(player, profile))
					for _, visit in arrived do
						local rarity = Config.getRarity(visit.rarity)
						local visitor = Config.getVisitor(visit.visitor)
						local station = Config.getStation(visit.station)
						notify(player, string.format("%s (%s) wil %d x %s",
							visitor and visitor.name or "?", rarity.name, visit.amount,
							station and station.pen.name or "pennen"), rarity.color)
						if rarity.announce then
							announce(string.format("%s kreeg bezoek van <b>%s</b> - %s!",
								player.DisplayName, visitor and visitor.name or "?", rarity.name), rarity.color)
						end
						changed = true
					end
					if #Visitors.list(player) > 0 then
						changed = true
					end

					local left = Staff.tick(profile, stamp, dt)
					for _, key in left do
						local visitor = Config.getVisitor(key)
						notify(player, string.format("%s heeft ontslag genomen - te lang niet betaald.",
							visitor and visitor.name or key), Color3.fromRGB(255, 150, 150))
						changed = true
						profile.dirty = true
					end
					if #profile.staff > 0 then
						changed = true
					end

					if changed then
						push(player)
					end
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
