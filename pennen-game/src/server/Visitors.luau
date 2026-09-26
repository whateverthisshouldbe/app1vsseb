--!strict
-- Bezoekers: los van de gewone klanten lopen er mensen je terrein op met een
-- bestelling voor een bepaald soort pen. Hoe zeldzamer, hoe meer ze betalen.
-- Wie je getrade hebt komt in je index en kun je daarna inhuren als personeel.
--
-- De bezoekers zijn persoonlijk: iedereen heeft zijn eigen kansen. De server
-- houdt alleen de gegevens bij; de client zet de poppetjes neer.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

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
