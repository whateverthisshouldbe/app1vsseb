-- Every tunable number in the game lives here. The map generator
-- (tools/build_map.py) uses the same zone rectangles, so keep them in sync.

local Config = {}

Config.StartingCash = 50
Config.AutosaveInterval = 90
Config.OfflineEarningsRate = 0.5 -- fraction of passive income paid while offline
Config.OfflineEarningsCap = 3 * 60 * 60 -- seconds
Config.DailyBonusCooldown = 20 * 60 * 60

-- Pens: the thing you sell. Owning a better pen raises every sale.
Config.Pens = {
	{ id = "bic", name = "Bic Stick", cost = 0, value = 15, color = Color3.fromRGB(40, 90, 200), blurb = "It's a pen. It... writes." },
	{ id = "click", name = "Clicky Pen", cost = 100, value = 45, color = Color3.fromRGB(220, 60, 60), blurb = "Click click. Satisfying." },
	{ id = "gel", name = "Gel Pen", cost = 900, value = 140, color = Color3.fromRGB(120, 220, 120), blurb = "Smooth like your pitch." },
	{ id = "fountain", name = "Fountain Pen", cost = 6_000, value = 450, color = Color3.fromRGB(20, 20, 30), blurb = "Old money energy." },
	{ id = "gold", name = "Gold Pen", cost = 40_000, value = 1_600, color = Color3.fromRGB(255, 200, 60), blurb = "Heavy. Shiny. Unnecessary." },
	{ id = "montblank", name = "Mont Blank", cost = 250_000, value = 7_000, color = Color3.fromRGB(245, 245, 245), blurb = "Definitely not a knockoff." },
	{ id = "diamond", name = "Diamond Pen", cost = 1_500_000, value = 28_000, color = Color3.fromRGB(150, 230, 255), blurb = "Writes in pure flex." },
	{ id = "wolf", name = "The Wolf's Pen", cost = 10_000_000, value = 120_000, color = Color3.fromRGB(255, 120, 0), blurb = "The pen. THE pen." },
	{ id = "platinum", name = "Platinum Pen", cost = 80_000_000, value = 600_000, color = Color3.fromRGB(225, 230, 240), blurb = "Penthouse-grade stationery." },
	{ id = "quill", name = "Golden Quill", cost = 900_000_000, value = 3_000_000, color = Color3.fromRGB(255, 215, 120), blurb = "Swiss bankers sign with nothing less." },
	{ id = "blackcard", name = "Black Card Pen", cost = 12_000_000_000, value = 20_000_000, color = Color3.fromRGB(10, 10, 12), blurb = "There is no limit." },
}

-- Suits: charisma. Start each pitch with higher certainty and a wider
-- sweet spot on the tonality bar.
Config.Suits = {
	{ id = "thrift", name = "Thrift Store Suit", cost = 0, startBonus = 0, sweetSpot = 0.16, cashMult = 1, color = Color3.fromRGB(110, 95, 80) },
	{ id = "rack", name = "Off-the-Rack Suit", cost = 500, startBonus = 0.5, sweetSpot = 0.2, cashMult = 1, color = Color3.fromRGB(70, 70, 80) },
	{ id = "tailored", name = "Tailored Suit", cost = 8_000, startBonus = 1, sweetSpot = 0.24, cashMult = 1.05, color = Color3.fromRGB(30, 35, 60) },
	{ id = "silk", name = "Italian Silk Suit", cost = 80_000, startBonus = 1.5, sweetSpot = 0.28, cashMult = 1.1, color = Color3.fromRGB(25, 25, 28) },
	{ id = "wolfsuit", name = "The Wolf Suit", cost = 1_200_000, startBonus = 2, sweetSpot = 0.34, cashMult = 1.25, color = Color3.fromRGB(15, 15, 15) },
}

-- Phones: passive cold-calling income. You own one at a time (the best one).
Config.Phones = {
	{ id = "none", name = "No Phone", cost = 0, income = 0 },
	{ id = "rotary", name = "Rotary Phone", cost = 300, income = 2 },
	{ id = "desk", name = "Desk Phone", cost = 3_000, income = 12 },
	{ id = "headset", name = "Headset", cost = 25_000, income = 60 },
	{ id = "brick", name = "Brick Cellphone", cost = 200_000, income = 300 },
	{ id = "sat", name = "Satellite Phone", cost = 2_000_000, income = 1_500 },
}

-- Rarities. Every visitor has one. `odds` is "1 in N", `mult` multiplies the
-- sale and `daily` is what they earn you per workday as a broker.
Config.Rarities = {
	{ id = "common", name = "Common", odds = 2, mult = 3, daily = 250, color = Color3.fromRGB(190, 190, 190) },
	{ id = "rare", name = "Rare", odds = 4, mult = 7, daily = 1_200, color = Color3.fromRGB(70, 150, 255) },
	{ id = "superrare", name = "Super Rare", odds = 11, mult = 15, daily = 6_000, color = Color3.fromRGB(40, 220, 210) },
	{ id = "epic", name = "Epic", odds = 38, mult = 34, daily = 32_000, color = Color3.fromRGB(170, 80, 255) },
	{ id = "mythic", name = "Mythic", odds = 143, mult = 85, daily = 180_000, color = Color3.fromRGB(255, 60, 70) },
	{ id = "legendary", name = "Legendary", odds = 606, mult = 220, daily = 1_100_000, color = Color3.fromRGB(255, 200, 40) },
	{ id = "exotic", name = "Exotic", odds = 3_753, mult = 650, daily = 7_500_000, color = Color3.fromRGB(255, 90, 200) },
	{ id = "ultra", name = "Ultra Exotic", odds = 49_252, mult = 6_000, daily = 90_000_000, color = Color3.fromRGB(255, 255, 255) },
}
-- Rarities from here up get announced to the whole server when they show up.
Config.AnnounceRarity = "mythic"

-- Brokers are visitors you recruited instead of taking their money.
Config.MaxBrokers = 8
Config.WorkdayLength = 10 * 60 -- seconds; "daily" is paid out over this
Config.DealTimeout = 25 -- seconds to choose cash or recruit before it defaults to cash
Config.IndexBonusPerVisitor = 0.005 -- +0.5% sales per unique visitor in your Index

-- Zones open by rebirth count. `area` is where customers wander (x/z at
-- height y); `tp` is where the teleporter drops you. Door zones have
-- visitors arrive at a door and queue instead of wandering.
Config.Zones = {
	{
		id = "strip",
		name = "The Strip Mall",
		subtitle = "Long Island Investor Center",
		rebirths = 0,
		budgetMult = 1,
		luck = 1,
		customers = 6,
		area = { minX = -375, maxX = -235, minZ = -55, maxZ = 55, y = 0 },
		tp = Vector3.new(-315, 4, -58),
	},
	{
		id = "street",
		name = "Pen Street",
		subtitle = "The financial district",
		rebirths = 1,
		budgetMult = 2.5,
		luck = 1.25,
		customers = 8,
		area = { minX = -95, maxX = 190, minZ = -30, maxZ = 30, y = 0 },
		gate = "Gate_PenStreet",
		tp = Vector3.new(-30, 4, 25),
	},
	{
		id = "floor",
		name = "The Trading Floor",
		subtitle = "Stratton Oakpen HQ",
		rebirths = 3,
		budgetMult = 6,
		luck = 1.6,
		customers = 8,
		area = { minX = 226, maxX = 338, minZ = -34, maxZ = 34, y = 0 },
		gate = "Gate_TradingFloor",
		tp = Vector3.new(290, 4, 0),
	},
	{
		id = "yacht",
		name = "The Yacht",
		subtitle = "Moored in the harbor",
		rebirths = 5,
		budgetMult = 15,
		luck = 2,
		customers = 6,
		area = { minX = 317, maxX = 343, minZ = 202, maxZ = 226, y = 5.4 },
		gate = "Gate_Yacht",
		tp = Vector3.new(330, 9, 214),
	},
	{
		id = "penthouse",
		name = "The Penthouse",
		subtitle = "They come to YOU now",
		rebirths = 8,
		budgetMult = 40,
		luck = 2.6,
		customers = 4,
		mode = "door",
		door = Vector3.new(-80, 152, 40),
		entry = Vector3.new(-80, 152, 50), -- just inside the front door
		queue = {
			Vector3.new(-91, 152, 53),
			Vector3.new(-85, 152, 53),
			Vector3.new(-75, 152, 53),
			Vector3.new(-69, 152, 53),
		},
		area = { minX = -103, maxX = -57, minZ = 36, maxZ = 88, y = 152 },
		tp = Vector3.new(-80, 156, 58),
	},
	{
		id = "vault",
		name = "The Swiss Vault",
		subtitle = "Banque de Pen-eve, Geneva",
		rebirths = 10,
		budgetMult = 100,
		luck = 3.2,
		customers = 6,
		area = { minX = -645, maxX = -595, minZ = 360, maxZ = 405, y = 0 },
		tp = Vector3.new(-620, 4, 352),
	},
	{
		id = "island",
		name = "Private Island",
		subtitle = "Retired. Still selling.",
		rebirths = 14,
		budgetMult = 250,
		luck = 4,
		customers = 6,
		area = { minX = 520, maxX = 600, minZ = 510, maxZ = 572, y = 0.5 },
		tp = Vector3.new(560, 5, 502),
	},
}

-- Rebirth (going public / IPO): resets cash, pen, suit and phone. Brokers
-- and the Index stay. Each rebirth adds a permanent multiplier.
Config.IPO = {
	baseCost = 25_000,
	costGrowth = 5,
	multPerIPO = 0.5,
}

-- Pitch minigame (Jordan Belfort's "Straight Line": the buyer must be
-- certain about the product, about you, and about your firm).
Config.Pitch = {
	meterMax = 10,
	startMeter = 2.5,
	startJitter = 1.5,
	patience = 5,
	minTurnTime = 0.35, -- seconds between accepted actions
	perfectCloseBonus = 1.5,
	rejectCooldown = 20, -- seconds before that customer will hear you out again
	napkinChance = 0.12,
}

-- The Wolf Speech: a surprise server-wide boost. It starts at a random
-- moment (no countdown), announced only once it begins.
Config.Speech = {
	minInterval = 60,
	maxInterval = 7 * 60,
	duration = 60,
	mult = 2.5,
}

Config.Hum = {
	duration = 20,
	cooldown = 45,
	mult = 1.1,
	crowdMult = 1.25, -- when 3+ players hum together
	crowdSize = 3,
}

function Config.getZone(id)
	for _, zone in Config.Zones do
		if zone.id == id then
			return zone
		end
	end
	return nil
end

function Config.findById(list, id)
	for index, item in list do
		if item.id == id then
			return item, index
		end
	end
	return nil, nil
end

-- Titles by lifetime earnings (shown over your head and on the level bar).
Config.Ranks = {
	{ min = 0, title = "Pen Pusher", color = Color3.fromRGB(220, 220, 220) },
	{ min = 1_000, title = "Cold Caller", color = Color3.fromRGB(140, 230, 140) },
	{ min = 25_000, title = "Stockbroker", color = Color3.fromRGB(110, 190, 255) },
	{ min = 500_000, title = "Big Swinging Pen", color = Color3.fromRGB(200, 140, 255) },
	{ min = 10_000_000, title = "The Wolf", color = Color3.fromRGB(255, 210, 60) },
	{ min = 1_000_000_000, title = "Wolf of Pen Street", color = Color3.fromRGB(255, 120, 40) },
}

function Config.rankFor(lifetime)
	local best = Config.Ranks[1]
	for _, rank in Config.Ranks do
		if lifetime >= rank.min then
			best = rank
		end
	end
	return best
end

-- Levels grow with lifetime earnings: each level needs 1.5x the last.
local LEVEL_BASE, LEVEL_GROWTH = 100, 1.5
local function levelThreshold(level)
	return LEVEL_BASE * (LEVEL_GROWTH ^ (level - 1) - 1)
end

function Config.levelFor(lifetime)
	local level = math.floor(math.log(math.max(0, lifetime) / LEVEL_BASE + 1) / math.log(LEVEL_GROWTH)) + 1
	local current, nextAt = levelThreshold(level), levelThreshold(level + 1)
	return level, math.clamp((lifetime - current) / (nextAt - current), 0, 1), nextAt
end

function Config.rebirthCost(rebirths)
	return math.floor(Config.IPO.baseCost * Config.IPO.costGrowth ^ rebirths)
end

function Config.zoneUnlocked(profile, zoneId)
	local zone = Config.getZone(zoneId)
	return zone ~= nil and profile.ipos >= zone.rebirths
end

-- "0-1", "8-10", "14+": the rebirth range a zone is meant for.
function Config.zoneRange(zone)
	local _, index = Config.findById(Config.Zones, zone.id)
	local nextZone = Config.Zones[index + 1]
	if nextZone then
		return string.format("%d-%d", zone.rebirths, nextZone.rebirths)
	end
	return zone.rebirths .. "+"
end

function Config.getRarity(id)
	return (Config.findById(Config.Rarities, id))
end

-- Pick a rarity. Zone luck multiplies the chance of everything above Common.
function Config.rollRarity(luck, rng)
	local total = 0
	local weights = {}
	for index, rarity in Config.Rarities do
		local weight = 1 / rarity.odds
		if index > 1 then
			weight *= luck
		end
		weights[index] = weight
		total += weight
	end
	local roll = rng:NextNumber() * total
	for index, rarity in Config.Rarities do
		roll -= weights[index]
		if roll <= 0 then
			return rarity
		end
	end
	return Config.Rarities[1]
end

function Config.brokerIncome(rarityId)
	local rarity = Config.getRarity(rarityId)
	return rarity and rarity.daily / Config.WorkdayLength or 0
end

return Config
