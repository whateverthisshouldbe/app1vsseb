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

local function notify(player: Player, text: string, color: Color3?)
	Net.event("Notify"):FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
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

	return {
		cash = profile.cash,
		pens = profile.pens,
		penValue = profile.penValue,
		capacity = capacityOf(player, profile),
		bagValue = math.floor(profile.pens * profile.penValue * cashMultiplier(player, profile)),
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
		local cash = stats:FindFirstChild("Cash") :: IntValue?
		local pens = stats:FindFirstChild("Pennen") :: IntValue?
		local rb = stats:FindFirstChild("Rebirths") :: IntValue?
		if cash then cash.Value = math.floor(math.min(profile.cash, 2 ^ 31 - 1)) end
		if pens then pens.Value = profile.pens end
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
	local sold = math.min(profile.pens, pitch.pens)
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
	local earned = math.floor(sold * profile.penValue * cashMultiplier(player, profile) * total)

	profile.cash += earned
	profile.totalSold += sold
	profile.pens -= sold
	if profile.pens <= 0 then
		profile.pens = 0
		profile.penValue = 0
	end
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
		pens = profile.pens,
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
		pens = profile.pens,
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
	if key == "capacity" then
		profile.pens = math.min(profile.pens, capacityOf(player, profile))
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
	profile.pens = 0
	profile.penValue = 0
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
	for _, name in { "Cash", "Pennen", "Rebirths" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player

	nextProduce[player] = 0
	nextSell[player] = 0
	nextUpgrade[player] = 0
	nextHint[player] = 0

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
				while now >= (nextProduce[player] or 0) and profile.pens < capacity and made < 64 do
					local totalValue = profile.pens * profile.penValue + station.pen.value
					profile.pens += 1
					profile.penValue = totalValue / profile.pens
					made += 1
					nextProduce[player] = math.max((nextProduce[player] or now) + interval, now - interval)
				end
				if made > 0 then
					profile.dirty = true
					push(player)
				elseif profile.pens >= capacity and now >= (nextProduce[player] or 0) then
					nextProduce[player] = now + 1.5
					hint(player, now, "Je tas zit vol - ga pitchen bij de toonbank!")
				end
			end
		end

		local sellPad = pads["Sell_" .. station.key]
		if sellPad and isOnPad(root, sellPad) then
			if not stationUnlocked(profile, station) then
				hint(player, now, string.format("%s opent na rebirth %d", station.name, station.unlockRebirth))
			elseif profile.pens > 0 and not pitches[player] and now >= (nextSell[player] or 0) then
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
