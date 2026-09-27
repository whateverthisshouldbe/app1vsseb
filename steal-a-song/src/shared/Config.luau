--!strict
-- Alle getallen waar je aan wilt draaien staan hier. Kleuren zijn {r, g, b}
-- zodat deze module ook buiten Roblox (in de tests) te laden is.

-- Beloningen en events hebben niet allemaal dezelfde velden
export type Reward = {
	kind: string,
	minutes: number?,
	incomeSeconds: number?,
	min: number?,
	rarity: string?,
}

export type EventDef = {
	id: string,
	name: string,
	icon: string,
	desc: string,
	color: { number },
	mutationMult: number?,
	spawnMult: number?,
	luck: number?,
	incomeMult: number?,
	night: boolean?,
}

export type Rarity = {
	name: string,
	color: { number },
	weight: number,
	pricePerStream: number,
	announce: boolean?,
	rainbow: boolean?,
}

export type Mutation = {
	name: string,
	mult: number,
	chance: number,
	color: { number },
	rainbow: boolean?,
}

local Config = {}

Config.GameName = "Steal A Song"

-- Economie. Een song verdient per seconde IncomePerStream per stream, dus een
-- song met 1M streams brengt $1K/s op. Meer streams = betere song.
Config.StartingCash = 100
Config.IncomePerStream = 0.001
Config.SellFraction = 0.5
Config.TickSeconds = 1

-- Streams groeien zolang een song in je studio staat, tot een plafond
Config.GrowthPerSecond = 0.0005 -- deel van de start-streams per seconde (3% per minuut)
Config.MaxGrowth = 3 -- zonder upgrades groeit een song tot 3x zijn start-streams

-- Speler
Config.WalkSpeed = 20
Config.CarrySpeedMultiplier = 0.8

-- Studio
Config.StartSlots = 8
Config.SlotsPerRebirth = 2
Config.MaxSlots = 20
Config.LockSeconds = 60

-- Rode loper
Config.SpawnInterval = 2.2
Config.ConveyorSpeed = 7

-- Stelen en slaan
Config.StealHoldSeconds = 0.6
Config.SellHoldSeconds = 2
Config.StealTimeout = 90
Config.HitCooldown = 0.8
Config.HitRange = 9
Config.HitStunSeconds = 1.2

-- Rebirth
Config.RebirthBaseCost = 1_000_000
Config.RebirthCostGrowth = 8
Config.RebirthIncomeBonus = 0.5

-- Boosts
Config.FriendBoostPer = 0.1
Config.FriendBoostMax = 0.5
Config.IndexBonusPerRarity = 0.1

-- Geld dat je songs verdienen terwijl je offline bent
Config.OfflineRate = 0.2
Config.OfflineMaxSeconds = 4 * 3600

-- Zeldzaamheid. weight bepaalt hoe vaak hij op de loper komt, pricePerStream
-- hoe duur hij is (prijs / inkomen = terugverdientijd in seconden).
local rarities: { Rarity } = {
	{ name = "Common", color = { 200, 200, 200 }, weight = 55, pricePerStream = 0.02 },
	{ name = "Rare", color = { 70, 160, 255 }, weight = 28, pricePerStream = 0.03 },
	{ name = "Epic", color = { 180, 90, 255 }, weight = 12, pricePerStream = 0.045 },
	{ name = "Legendary", color = { 255, 196, 40 }, weight = 4, pricePerStream = 0.06, announce = true },
	{ name = "Mythic", color = { 255, 60, 90 }, weight = 0.85, pricePerStream = 0.08, announce = true },
	{
		name = "Chart God",
		color = { 255, 255, 255 },
		weight = 0.14,
		pricePerStream = 0.1,
		announce = true,
		rainbow = true,
	},
	{ name = "Secret", color = { 30, 30, 36 }, weight = 0.012, pricePerStream = 0.15, announce = true },
}
Config.Rarities = rarities

-- Luck-boosts gelden vanaf deze zeldzaamheid
Config.LuckFromRarity = "Epic"

-- Mutaties vermenigvuldigen de streams (en dus inkomen en prijs)
local mutations: { Mutation } = {
	{ name = "Gold", mult = 2, chance = 0.06, color = { 255, 200, 50 } },
	{ name = "Platinum", mult = 3, chance = 0.025, color = { 225, 235, 250 } },
	{ name = "Diamond", mult = 5, chance = 0.01, color = { 110, 235, 255 } },
	{ name = "Viral", mult = 10, chance = 0.003, color = { 255, 90, 210 }, rainbow = true },
}
Config.Mutations = mutations

-- Upgrades blijven na een rebirth
Config.Upgrades = {
	{
		id = "Speed",
		name = "Sneakers",
		icon = "👟",
		desc = "+2 walk speed per level",
		per = 2,
		costs = { 1_000, 15_000, 200_000, 3_000_000, 40_000_000 },
	},
	{
		id = "Lock",
		name = "Laser Lock",
		icon = "🔒",
		desc = "+10s studio lock per level",
		per = 10,
		costs = { 2_500, 30_000, 400_000, 5_000_000, 60_000_000 },
	},
	{
		id = "Hype",
		name = "Promo Team",
		icon = "📣",
		desc = "Songs gain streams 25% faster and peak 0.5x higher",
		per = 0.25,
		costs = { 5_000, 75_000, 1_000_000, 12_000_000, 150_000_000 },
	},
}

-- Cadeaus voor speeltijd in deze sessie
local gifts: { Reward } = {
	{ minutes = 1, kind = "cash", incomeSeconds = 30, min = 150 },
	{ minutes = 3, kind = "cash", incomeSeconds = 60, min = 400 },
	{ minutes = 5, kind = "song", rarity = "Rare" },
	{ minutes = 10, kind = "cash", incomeSeconds = 120, min = 2_500 },
	{ minutes = 15, kind = "song", rarity = "Epic" },
	{ minutes = 25, kind = "cash", incomeSeconds = 300, min = 15_000 },
	{ minutes = 40, kind = "song", rarity = "Legendary" },
	{ minutes = 60, kind = "song", rarity = "Mythic" },
}
Config.Gifts = gifts

-- Dagelijkse beloning, 7 dagen op rij en dan weer van voren af aan
local daily: { Reward } = {
	{ kind = "cash", incomeSeconds = 60, min = 500 },
	{ kind = "cash", incomeSeconds = 120, min = 1_500 },
	{ kind = "song", rarity = "Rare" },
	{ kind = "cash", incomeSeconds = 300, min = 5_000 },
	{ kind = "song", rarity = "Epic" },
	{ kind = "cash", incomeSeconds = 600, min = 25_000 },
	{ kind = "song", rarity = "Legendary" },
}
Config.Daily = daily

-- Server-events die om de paar minuten beginnen
Config.EventMinGap = 6 * 60
Config.EventMaxGap = 9 * 60
Config.EventDuration = 150
local events: { EventDef } = {
	{
		id = "ConcertNight",
		name = "Concert Night",
		icon = "🌙",
		desc = "Mutations are 4x more likely!",
		mutationMult = 4,
		night = true,
		color = { 150, 90, 255 },
	},
	{
		id = "LabelFrenzy",
		name = "Label Frenzy",
		icon = "💿",
		desc = "Songs drop 2x faster!",
		spawnMult = 2,
		color = { 60, 200, 255 },
	},
	{
		id = "ViralHour",
		name = "Viral Hour",
		icon = "🔥",
		desc = "Epic+ songs are 3x more likely!",
		luck = 3,
		color = { 255, 120, 40 },
	},
	{
		id = "DoubleRoyalties",
		name = "Double Royalties",
		icon = "💸",
		desc = "Every studio earns 2x!",
		incomeMult = 2,
		color = { 80, 230, 120 },
	},
}
Config.Events = events

-- Accentkleur per studio
Config.StudioColors = {
	{ 255, 80, 170 },
	{ 60, 200, 255 },
	{ 140, 230, 60 },
	{ 255, 150, 40 },
	{ 170, 100, 255 },
	{ 255, 220, 60 },
	{ 60, 120, 255 },
	{ 255, 70, 70 },
}

-- Ingebouwde Roblox-geluiden. Vervang ze gerust door rbxassetid://... uit de
-- Creator Store; een geluid dat niet laadt geeft alleen een waarschuwing.
Config.Sounds = {
	Click = "rbxasset://sounds/clickfast.wav",
	Buy = "rbxasset://sounds/electronicpingshort.wav",
	Collect = "rbxasset://sounds/electronicpingshort.wav",
	Swing = "rbxasset://sounds/swordslash.wav",
	Hit = "rbxasset://sounds/collide.wav",
	Alarm = "rbxasset://sounds/electronicpingshort.wav",
	Rebirth = "rbxasset://sounds/victory.wav",
	Announce = "rbxasset://sounds/electronicpingshort.wav",
}

-- Achtergrondmuziek: zet hier een rbxassetid://... van een track met licentie
-- (Creator Store, filter op Music). Leeg = geen muziek.
Config.MusicId = ""

-- Game passes: vul het ID in nadat je de pass op create.roblox.com hebt
-- aangemaakt. 0 = uit, dan verschijnt hij ook niet in de winkel.
Config.GamePasses = {
	{ id = 0, key = "DoubleCash", name = "2x Royalties", icon = "💰", desc = "Earn double royalties forever" },
	{ id = 0, key = "VIP", name = "VIP", icon = "⭐", desc = "+50% royalties and +4 walk speed" },
}

return Config
