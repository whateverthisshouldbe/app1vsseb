--!strict
-- De spelregels: pennen maken, pitchen, verkopen, upgraden, rebirthen,
-- passief verdienen, mascottes, dagbeloning en codes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PenShared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Data = require(script.Parent.Data)
local World = require(script.Parent.World)
local Customers = require(script.Parent.Customers)
local Passes = require(script.Parent.Passes)
local Pets = require(script.Parent.Pets)
local Leaderboards = require(script.Parent.Leaderboards)
local Visitors = require(script.Parent.Visitors)
local Staff = require(script.Parent.Staff)

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
