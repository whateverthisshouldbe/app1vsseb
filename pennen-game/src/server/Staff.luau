--!strict
-- Personeel: bezoekers die je al getrade hebt kun je in dienst nemen. Ze maken
-- pennen voor je, raken vermoeid van doorwerken en willen elke dag loon.
-- Betaal je niet op tijd, dan nemen ze ontslag - maar ze blijven in je index,
-- dus je kunt ze later opnieuw inhuren.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

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
