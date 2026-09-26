-- The pitch minigame. Server-authoritative: the client only picks one of
-- the offered lines (plus how well it hit the tonality bar) or tries to close.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PitchData = require(ReplicatedStorage.Shared.PitchData)
local Format = require(ReplicatedStorage.Shared.Format)
local Visitors = require(ReplicatedStorage.Shared.Visitors)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local CustomerService = require(script.Parent.CustomerService)

local Remotes = ReplicatedStorage.Remotes

local PitchService = {}

local sessions = {} -- [Player] = session
local pendingDeals = {} -- [Player] = { amount, visitorId, token }
local rng = Random.new()

local METERS = { "pen", "you", "firm" }
local MAX = Config.Pitch.meterMax

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function contains(list, value)
	return table.find(list, value) ~= nil
end

local function closeChance(meters)
	local minimum = math.min(meters.pen, meters.you, meters.firm) / MAX
	local average = (meters.pen + meters.you + meters.firm) / (3 * MAX)
	if minimum >= 1 then
		return 1
	end
	return math.clamp(0.08 + 0.9 * (0.6 * minimum + 0.4 * average), 0.05, 0.97)
end

local function drawOptions(session)
	local options = {}
	local usedTags = {}
	local badCount = 0
	local attempts = 0
	while #options < 3 and attempts < 100 do
		attempts += 1
		local line = pick(PitchData.Lines)
		if not usedTags[line.tag] and not (line.bad and badCount >= 1) then
			usedTags[line.tag] = true
			if line.bad then
				badCount += 1
			end
			table.insert(options, line)
		end
	end
	if not session.napkinUsed and rng:NextNumber() < Config.Pitch.napkinChance then
		options[rng:NextInteger(1, #options)] = PitchData.Napkin
	end
	-- Shuffle so the napkin isn't always in the same slot.
	for i = #options, 2, -1 do
		local j = rng:NextInteger(1, i)
		options[i], options[j] = options[j], options[i]
	end
	session.options = options
end

local function payoutFor(session, profile, player)
	local pen = Config.findById(Config.Pens, profile.pen)
	local rarity = Config.getRarity(session.visitor.rarity)
	local m = session.meters
	local average = (m.pen + m.you + m.firm) / (3 * MAX)
	local quality = 0.5 + 1.5 * average
	local perfect = m.pen >= MAX and m.you >= MAX and m.firm >= MAX
	local amount = pen.value * session.zone.budgetMult * rarity.mult * quality
	if perfect then
		amount *= Config.Pitch.perfectCloseBonus
	end
	amount *= EconomyService.saleMult(player, profile)
	return math.max(1, math.floor(amount)), perfect
end

local function snapshot(session)
	local options = {}
	for _, line in session.options do
		table.insert(options, { text = line.text, tag = line.tag, napkin = line.napkin == true })
	end
	return {
		meters = session.meters,
		patience = session.patience,
		maxPatience = session.maxPatience,
		options = options,
		closeChance = closeChance(session.meters),
	}
end

local function finish(player, result, amount, line, extra)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	player:SetAttribute("InPitch", nil)
	local customer = session.customer

	local payload = {
		result = result,
		amount = amount or 0,
		line = line,
		perfect = extra and extra.perfect or false,
		napkin = extra and extra.napkin or false,
	}
	if extra and extra.deal then
		for key, value in extra.deal do
			payload[key] = value
		end
	end
	Remotes.PitchEnd:FireClient(player, payload)

	if result == "deal" or result == "busted" then
		if line then
			CustomerService.say(customer, line, 3)
		end
		CustomerService.replace(customer, 3.2)
	else
		if line then
			CustomerService.say(customer, line, 3)
		end
		customer.cooldowns[player] = os.clock() + Config.Pitch.rejectCooldown
		CustomerService.setBusy(customer, false)
	end
end

local function start(player, customer)
	local profile = DataService.get(player)
	if not profile or sessions[player] or pendingDeals[player] or customer.busy then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - customer.root.Position).Magnitude > 16 then
		return
	end
	if not Config.zoneUnlocked(profile, customer.zone.id) then
		EconomyService.notify(player, string.format("%s needs %d rebirths.", customer.zone.name, customer.zone.rebirths), "error")
		return
	end
	local cooldown = customer.cooldowns[player]
	if cooldown and cooldown > os.clock() then
		CustomerService.say(customer, "I already said no, pal.", 2)
		return
	end

	local archetype = PitchData.Archetypes[customer.archetypeKey]
	local visitor = customer.visitor
	local rarity, rarityIndex = Config.findById(Config.Rarities, visitor.rarity)
	local suit = Config.findById(Config.Suits, profile.suit)
	local meters = {}
	-- Rarer visitors are tougher to convince.
	local toughness = (rarityIndex - 1) * 0.25
	for _, key in METERS do
		local value = Config.Pitch.startMeter + suit.startBonus - toughness + rng:NextNumber(-1, 1) * Config.Pitch.startJitter
		meters[key] = math.clamp(math.floor(value * 2 + 0.5) / 2, 0, MAX)
	end

	local session = {
		player = player,
		customer = customer,
		zone = customer.zone,
		archetypeKey = customer.archetypeKey,
		visitor = visitor,
		meters = meters,
		patience = Config.Pitch.patience,
		maxPatience = Config.Pitch.patience,
		lastAction = os.clock(),
		usedTags = {},
		napkinUsed = false,
	}
	drawOptions(session)
	sessions[player] = session
	player:SetAttribute("InPitch", true)
	CustomerService.setBusy(customer, true, player)
	local greeting = pick(archetype.greeting)
	CustomerService.say(customer, greeting, 4)

	local pen = Config.findById(Config.Pens, profile.pen)
	local data = snapshot(session)
	data.customer = {
		name = visitor.name,
		personality = archetype.name,
		key = customer.archetypeKey,
		visitorId = visitor.id,
		rarity = rarity.id,
		greeting = greeting,
		likes = archetype.likes,
		dislikes = archetype.dislikes,
		budget = rarity.mult * customer.zone.budgetMult,
		zone = customer.zone.name,
	}
	data.pen = pen.name
	data.estimate = math.floor(pen.value * customer.zone.budgetMult * rarity.mult * EconomyService.saleMult(player, profile))
	data.sweetSpot = suit.sweetSpot
	data.tags = PitchData.Tags
	data.model = customer.model
	Remotes.PitchStart:FireClient(player, data)
end

local function applyLine(session, line, tonality)
	local archetype = PitchData.Archetypes[session.archetypeKey]
	local liked = contains(archetype.likes, line.tag)
	local disliked = contains(archetype.dislikes, line.tag)
	local tonalityMult = 0.4 + 1.1 * tonality
	local total = 0
	local deltas = {}
	for index, key in METERS do
		local delta = line.fx[index]
		if delta > 0 then
			if line.napkin then
				delta *= math.max(1, tonalityMult)
			elseif disliked then
				delta = -math.max(1, delta * 0.6)
			else
				delta *= tonalityMult * (liked and 1.6 or 1)
			end
		end
		delta = math.floor(delta * 2 + 0.5) / 2
		session.meters[key] = math.clamp(session.meters[key] + delta, 0, MAX)
		deltas[key] = delta
		total += delta
	end
	session.usedTags[line.tag] = true
	if line.napkin then
		session.napkinUsed = true
	end
	return deltas, total, liked, disliked
end

local function onAction(player, action)
	local session = sessions[player]
	if not session or type(action) ~= "table" then
		return
	end
	if os.clock() - session.lastAction < Config.Pitch.minTurnTime then
		return
	end
	session.lastAction = os.clock()
	local customer = session.customer
	local archetype = PitchData.Archetypes[session.archetypeKey]
	local profile = DataService.get(player)
	if not profile then
		return
	end

	if action.type == "leave" then
		finish(player, "left", 0, "Okay... bye then?")
		return
	end

	if action.type == "line" then
		if session.patience <= 0 then
			return
		end
		local line = session.options[tonumber(action.index) or 0]
		if not line then
			return
		end
		local tonality = math.clamp(tonumber(action.tonality) or 0, 0, 1)
		if tonality ~= tonality then -- NaN
			tonality = 0
		end
		local deltas, total, liked, disliked = applyLine(session, line, tonality)
		session.patience -= 1

		local reaction
		if line.napkin then
			reaction = "I... don't have a pen. Oh. OH. Supply and demand!"
		elseif total >= 4 then
			reaction = pick(PitchData.Reactions.great)
		elseif total > 0 then
			reaction = pick(PitchData.Reactions.good)
		else
			reaction = pick(PitchData.Reactions.bad)
		end
		CustomerService.say(customer, reaction, 3)
		drawOptions(session)

		local data = snapshot(session)
		data.deltas = deltas
		data.reaction = reaction
		data.liked = liked
		data.disliked = disliked
		data.napkin = line.napkin == true
		data.tonality = tonality
		if session.patience <= 0 then
			data.options = {}
			data.lastChance = true
			CustomerService.say(customer, "Last chance. Close me or I'm gone.", 4)
		end
		Remotes.PitchUpdate:FireClient(player, data)
		return
	end

	if action.type == "close" then
		local chance = closeChance(session.meters)
		if rng:NextNumber() <= chance then
			-- FBI: any hard-sell line and you're fined instead of paid.
			if archetype.special == "fbi" then
				local hardSold = session.usedTags.pressure or session.usedTags.hype or session.usedTags.urgency
				if hardSold then
					local fine = math.floor(math.min(profile.cash * 0.05, 50_000 * (profile.ipos + 1)))
					DataService.addCash(player, -fine)
					finish(player, "busted", -fine, PitchData.FBI.busted)
					return
				end
			end

			local amount, perfect = payoutFor(session, profile, player)
			if archetype.special == "fbi" then
				amount *= 3
			end
			profile.pensSold += 1
			if perfect then
				profile.perfectCloses += 1
			end
			if session.napkinUsed then
				profile.napkins += 1
			end

			-- Index.
			local visitor = session.visitor
			local isNew = profile.index[visitor.id] == nil
			profile.index[visitor.id] = (profile.index[visitor.id] or 0) + 1
			local _, rarityIndex = Config.findById(Config.Rarities, visitor.rarity)
			local best = profile.best and Visitors.byId[profile.best]
			local _, bestIndex = Config.findById(Config.Rarities, best and best.rarity or "")
			if not best or rarityIndex > (bestIndex or 0) then
				profile.best = visitor.id
			end
			DataService.changed(player)

			-- Cash or recruit? The player decides; no answer = cash.
			local weakest = EconomyService.weakestBroker(profile)
			local daily = Config.getRarity(visitor.rarity).daily
			local canRecruit = weakest == nil or Config.getRarity(weakest.rarity).daily < daily
			local token = {}
			pendingDeals[player] = { amount = amount, visitorId = visitor.id, token = token }
			task.delay(Config.DealTimeout, function()
				local deal = pendingDeals[player]
				if deal and deal.token == token then
					PitchService.resolveDeal(player, "cash")
				end
			end)

			local line = archetype.special == "fbi" and PitchData.FBI.honest or pick(PitchData.CloseSuccess)
			finish(player, "deal", amount, line, {
				perfect = perfect,
				napkin = session.napkinUsed,
				deal = {
					visitorId = visitor.id,
					daily = daily,
					isNew = isNew,
					canRecruit = canRecruit,
					replaces = weakest and weakest.id or nil,
					brokerCount = #profile.brokers,
					timeout = Config.DealTimeout,
				},
			})
			if rarityIndex >= 5 then
				EconomyService.notifyAll(
					string.format("%s closed %s (%s)!", player.DisplayName, visitor.name, Config.getRarity(visitor.rarity).name),
					"big"
				)
			end
			return
		end

		-- Failed close: lose patience, certainty drops a notch.
		if session.patience <= 0 then
			finish(player, "walked", 0, pick(PitchData.WalkAway))
			return
		end
		session.patience -= 1
		for _, key in METERS do
			session.meters[key] = math.max(0, session.meters[key] - 1)
		end
		local reaction = pick(PitchData.CloseFail)
		CustomerService.say(customer, reaction, 3)
		local data = snapshot(session)
		data.reaction = reaction
		data.closeFailed = true
		data.deltas = { pen = -1, you = -1, firm = -1 }
		if session.patience <= 0 then
			data.options = {}
			data.lastChance = true
		end
		Remotes.PitchUpdate:FireClient(player, data)
	end
end

function PitchService.resolveDeal(player, choice)
	local deal = pendingDeals[player]
	if not deal then
		return
	end
	pendingDeals[player] = nil
	local visitor = Visitors.byId[deal.visitorId]
	if choice == "recruit" and EconomyService.recruit(player, deal.visitorId) then
		Remotes.PitchEnd:FireClient(player, { result = "recruited", visitorId = deal.visitorId })
		EconomyService.notify(player, visitor.name .. " joined your firm!", "success")
		return
	end
	DataService.addCash(player, deal.amount)
	Remotes.PitchEnd:FireClient(player, { result = "sold", amount = deal.amount, visitorId = deal.visitorId })
	if deal.amount >= 1_000_000 then
		EconomyService.notifyAll(
			string.format("%s just sold a pen for %s!", player.DisplayName, Format.cash(deal.amount)),
			"big"
		)
	end
end

function PitchService.start()
	CustomerService.start(start)
	Remotes.PitchAction.OnServerEvent:Connect(onAction)
	Remotes.Deal.OnServerEvent:Connect(function(player, choice)
		PitchService.resolveDeal(player, choice == "recruit" and "recruit" or "cash")
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Leaving mid-deal still pays out.
		if pendingDeals[player] then
			PitchService.resolveDeal(player, "cash")
		end
		local session = sessions[player]
		if session then
			sessions[player] = nil
			CustomerService.setBusy(session.customer, false)
		end
	end)

	-- Walking away or dying ends the pitch.
	task.spawn(function()
		while true do
			task.wait(0.5)
			for player, session in sessions do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local gone = not root
					or not humanoid
					or humanoid.Health <= 0
					or not session.customer.model.Parent
					or (root.Position - session.customer.root.Position).Magnitude > 28
				if gone then
					finish(player, "left", 0, "Hey! Where are you going?")
				end
			end
		end
	end)
end

return PitchService
