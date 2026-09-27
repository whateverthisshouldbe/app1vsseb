--!strict
-- Alle rekenregels op één plek, zonder Roblox-afhankelijkheden, zodat server
-- en client hetzelfde rekenen en de tests ze los kunnen draaien.

local Config = require(script.Parent.Config)
local Songs = require(script.Parent.Songs)

export type Song = {
	id: string,
	mut: string?,
	base: number, -- streams bij het droppen, inclusief mutatie
	streams: number,
	slot: number?,
}

type Rng = () -> number

local Economy = {}

local rarityIndex: { [string]: number } = {}
local rarityByName: { [string]: any } = {}
for i, rarity in Config.Rarities do
	rarityIndex[rarity.name] = i
	rarityByName[rarity.name] = rarity
end

local mutationByName: { [string]: any } = {}
for _, mutation in Config.Mutations do
	mutationByName[mutation.name] = mutation
end

local upgradeById: { [string]: any } = {}
for _, upgrade in Config.Upgrades do
	upgradeById[upgrade.id] = upgrade
end

local function defaultRng(): number
	return math.random()
end

function Economy.rarityIndex(name: string): number
	return rarityIndex[name] or 1
end

function Economy.rarity(name: string): any
	return rarityByName[name] or Config.Rarities[1]
end

function Economy.mutation(name: string?): any
	return if name then mutationByName[name] else nil
end

function Economy.def(song: Song): Songs.SongDef
	return Songs.byId[song.id]
end

function Economy.isValidSong(song: any): boolean
	return type(song) == "table"
		and type(song.id) == "string"
		and Songs.byId[song.id] ~= nil
		and type(song.base) == "number"
		and type(song.streams) == "number"
		and (song.mut == nil or mutationByName[song.mut] ~= nil)
end

-- Inkomen per seconde, vóór multipliers
function Economy.income(streams: number): number
	return streams * Config.IncomePerStream
end

function Economy.price(song: Song): number
	local def = Songs.byId[song.id]
	local rarity = Economy.rarity(def.rarity)
	return math.max(1, math.floor(song.streams * rarity.pricePerStream + 0.5))
end

function Economy.sellPrice(song: Song): number
	return math.floor(Economy.price(song) * Config.SellFraction)
end

function Economy.rebirthCost(rebirths: number): number
	return Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths
end

function Economy.rebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Config.RebirthIncomeBonus
end

function Economy.slotCount(rebirths: number): number
	return math.min(Config.MaxSlots, Config.StartSlots + rebirths * Config.SlotsPerRebirth)
end

function Economy.upgrade(id: string): any
	return upgradeById[id]
end

-- nil als de upgrade al op het maximum staat
function Economy.upgradeCost(id: string, level: number): number?
	local upgrade = upgradeById[id]
	if not upgrade then
		return nil
	end
	return upgrade.costs[level + 1]
end

function Economy.walkSpeed(speedLevel: number, vip: boolean): number
	return Config.WalkSpeed + speedLevel * upgradeById.Speed.per + (if vip then 4 else 0)
end

function Economy.lockSeconds(lockLevel: number): number
	return Config.LockSeconds + lockLevel * upgradeById.Lock.per
end

function Economy.growthRate(hypeLevel: number): number
	return Config.GrowthPerSecond * (1 + hypeLevel * upgradeById.Hype.per)
end

function Economy.maxGrowth(hypeLevel: number): number
	return Config.MaxGrowth + hypeLevel * 0.5
end

-- Laat een song in een studio doorgroeien; geeft true als hij net zijn piek haalt
function Economy.grow(song: Song, dt: number, hypeLevel: number): boolean
	local cap = song.base * Economy.maxGrowth(hypeLevel)
	if song.streams >= cap then
		return false
	end
	song.streams = math.min(cap, song.streams + song.base * Economy.growthRate(hypeLevel) * dt)
	return song.streams >= cap
end

function Economy.atPeak(song: Song, hypeLevel: number): boolean
	return song.streams >= song.base * Economy.maxGrowth(hypeLevel)
end

function Economy.rollRarity(luck: number?, rng: Rng?): string
	local roll = rng or defaultRng
	local luckFrom = rarityIndex[Config.LuckFromRarity]
	local weights = {}
	local total = 0
	for i, rarity in Config.Rarities do
		local w = rarity.weight
		if luck and i >= luckFrom then
			w *= luck
		end
		weights[i] = w
		total += w
	end
	local pick = roll() * total
	for i, rarity in Config.Rarities do
		pick -= weights[i]
		if pick < 0 then
			return rarity.name
		end
	end
	return Config.Rarities[1].name
end

function Economy.rollDef(rarityName: string, rng: Rng?): Songs.SongDef
	local roll = rng or defaultRng
	local group: { Songs.SongDef } = Songs.byRarity[rarityName] or Songs.byRarity[Config.Rarities[1].name]
	local i = math.clamp(math.floor(roll() * #group) + 1, 1, #group)
	return group[i]
end

function Economy.rollMutation(mult: number?, rng: Rng?): string?
	local roll = rng or defaultRng
	local pick = roll()
	for _, mutation in Config.Mutations do
		pick -= mutation.chance * (mult or 1)
		if pick < 0 then
			return mutation.name
		end
	end
	return nil
end

-- Log-uniform tussen min en max, zodat hoge aantallen zeldzamer zijn
function Economy.rollStreams(def: Songs.SongDef, rng: Rng?): number
	local roll = rng or defaultRng
	local lo, hi = math.log(def.min), math.log(def.max)
	return math.floor(math.exp(lo + (hi - lo) * roll()) + 0.5)
end

function Economy.makeSong(def: Songs.SongDef, mut: string?, rng: Rng?): Song
	local streams = Economy.rollStreams(def, rng)
	local mutation = Economy.mutation(mut)
	if mutation then
		streams *= mutation.mult
	end
	return { id = def.id, mut = mut, base = streams, streams = streams }
end

function Economy.rollSong(luck: number?, mutationMult: number?, rng: Rng?): Song
	local rarity = Economy.rollRarity(luck, rng)
	local def = Economy.rollDef(rarity, rng)
	return Economy.makeSong(def, Economy.rollMutation(mutationMult, rng), rng)
end

-- Hoeveel songs per zeldzaamheid ontdekt zijn, en de bonus voor volle rijen
function Economy.indexProgress(discovered: { [string]: boolean }): ({ [string]: { found: number, total: number } }, number)
	local progress = {}
	local complete = 0
	for _, rarity in Config.Rarities do
		local group: { Songs.SongDef } = Songs.byRarity[rarity.name] or {}
		local found = 0
		for _, def in group do
			if discovered[def.id] then
				found += 1
			end
		end
		progress[rarity.name] = { found = found, total = #group }
		if #group > 0 and found == #group then
			complete += 1
		end
	end
	return progress, complete * Config.IndexBonusPerRarity
end

function Economy.rewardCash(income: number, reward: any): number
	return math.floor(math.max(reward.min or 0, income * (reward.incomeSeconds or 0)))
end

function Economy.friendBoost(friends: number): number
	return math.min(Config.FriendBoostMax, friends * Config.FriendBoostPer)
end

return Economy
