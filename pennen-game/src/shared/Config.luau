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
