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
