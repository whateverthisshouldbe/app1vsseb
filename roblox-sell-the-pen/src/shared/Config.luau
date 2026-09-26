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

-- Brokers: stackable hires. Every hire costs a bit more than the last.
Config.BrokerCostGrowth = 1.18
Config.Brokers = {
	{ id = "diner", name = "Buddy From The Diner", cost = 1_000, income = 5, blurb = "Quit his job on the spot." },
	{ id = "rookie", name = "Rookie Broker", cost = 12_000, income = 40, blurb = "Headset on. No fear." },
	{ id = "senior", name = "Senior Broker", cost = 150_000, income = 350, blurb = "Has a boat. Wants a bigger boat." },
	{ id = "partner", name = "Founding Partner", cost = 2_000_000, income = 3_000, blurb = "Was there in the garage." },
}

-- Zones. `area` is the rectangle customers wander in (x/z), at height y.
Config.Zones = {
	{
		id = "strip",
		name = "The Strip Mall",
		subtitle = "Long Island Investor Center",
		cost = 0,
		budgetMult = 1,
		customers = 7,
		archetypes = { "tourist", "plumber", "dentist", "mom" },
		area = { minX = -375, maxX = -235, minZ = -55, maxZ = 55, y = 0 },
		gate = nil,
	},
	{
		id = "street",
		name = "Pen Street",
		subtitle = "The financial district",
		cost = 2_500,
		budgetMult = 2.2,
		customers = 9,
		archetypes = { "tourist", "accountant", "shoes", "intern", "fbi" },
		area = { minX = -95, maxX = 190, minZ = -30, maxZ = 30, y = 0 },
		gate = "Gate_PenStreet",
	},
	{
		id = "floor",
		name = "The Trading Floor",
		subtitle = "Stratton Oakpen HQ",
		cost = 60_000,
		budgetMult = 5,
		customers = 9,
		archetypes = { "bro", "accountant", "shoes", "swiss", "fbi" },
		area = { minX = 226, maxX = 338, minZ = -34, maxZ = 34, y = 0 },
		gate = "Gate_TradingFloor",
	},
	{
		id = "yacht",
		name = "The Yacht",
		subtitle = "Moored in the harbor",
		cost = 1_500_000,
		budgetMult = 14,
		customers = 7,
		archetypes = { "duchess", "oil", "swiss", "bro", "fbi" },
		area = { minX = 317, maxX = 343, minZ = 202, maxZ = 226, y = 5.4 },
		gate = "Gate_Yacht",
	},
}

-- IPO = rebirth. Reset everything, keep a permanent multiplier.
Config.IPO = {
	cashRequired = 10_000_000,
	requiresZone = "yacht",
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

-- The Wolf Speech: a server-wide boost that fires on a timer.
Config.Speech = {
	interval = 7 * 60,
	warning = 20,
	duration = 60,
	globalMult = 2,
	floorMult = 3, -- replaces globalMult for players standing on the trading floor
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

function Config.brokerCost(broker, owned)
	return math.floor(broker.cost * Config.BrokerCostGrowth ^ owned)
end

return Config
