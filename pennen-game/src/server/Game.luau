--!strict
-- De spelregels: pennen maken, verkopen, upgraden, rebirthen.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PenShared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Data = require(script.Parent.Data)
local World = require(script.Parent.World)
local Customers = require(script.Parent.Customers)

local Game = {}

local TICK = 0.1
local UPGRADE_PAD_COOLDOWN = 0.55
local SELL_COOLDOWN = 0.25
local REBIRTH_HOLD = 2

local pads: { [string]: BasePart } = {}
local nextProduce: { [Player]: number } = {}
local nextSell: { [Player]: number } = {}
local nextUpgrade: { [Player]: number } = {}
local rebirthHeldSince: { [Player]: number? } = {}

local function notify(player: Player, text: string, color: Color3?)
	Net.event("Notify"):FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
end

local function upgradeValue(profile, key: string): number
	local up = Config.getUpgrade(key)
	if not up then
		return 0
	end
	return up.value(profile.upgrades[key] or 1)
end

local function capacityOf(profile): number
	return math.floor(upgradeValue(profile, "capacity"))
end

local function sellMultiplier(profile): number
	return upgradeValue(profile, "charm") * Config.rebirthMultiplier(profile.rebirths)
end

local function currentPen(profile)
	return Config.getPen(Config.unlockedPenIndex(profile.rebirths))
end

local function buildState(player: Player, profile)
	local pen = currentPen(profile)
	local customer = Customers.current()
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
	return {
		cash = profile.cash,
		pens = profile.pens,
		capacity = capacityOf(profile),
		rebirths = profile.rebirths,
		totalSold = profile.totalSold,
		penName = pen.name,
		penValue = pen.value,
		penColor = pen.color,
		sellMultiplier = sellMultiplier(profile),
		bagValue = math.floor(profile.pens * pen.value * sellMultiplier(profile) * (customer and customer.multiplier or 1)),
		rebirthPrice = Config.rebirthPrice(profile.rebirths),
		canRebirth = profile.cash >= Config.rebirthPrice(profile.rebirths)
			and Config.unlockedPenIndex(profile.rebirths) < #Config.Pens,
		nextPenName = Config.getPen(Config.unlockedPenIndex(profile.rebirths) + 1).name,
		upgrades = upgrades,
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

local function isOnPad(root: BasePart, padPart: BasePart): boolean
	local offset = padPart.CFrame:PointToObjectSpace(root.Position)
	local half = padPart.Size / 2
	return math.abs(offset.X) <= half.X + 1
		and math.abs(offset.Z) <= half.Z + 1
		and offset.Y >= -2
		and offset.Y <= 8
end

local function sell(player: Player, profile)
	if profile.pens <= 0 then
		return
	end
	local pen = currentPen(profile)
	local customer = Customers.current()
	local customerMult = customer and customer.multiplier or 1
	local earned = math.floor(profile.pens * pen.value * sellMultiplier(profile) * customerMult)

	local sold = profile.pens
	profile.cash += earned
	profile.totalSold += sold
	profile.pens = 0
	profile.dirty = true

	notify(player, string.format(
		"%s kocht %d x %s voor %s (x%.2f)",
		customer and customer.name or "Klant", sold, pen.name, Config.short(earned), customerMult
	), Color3.fromRGB(120, 255, 150))

	Customers.serve()
	push(player)
end

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
			notify(player, string.format("Je hebt %s nodig voor %s", Config.short(price), up.name),
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
		profile.pens = math.min(profile.pens, capacityOf(profile))
	end
	push(player)
end

local function rebirth(player: Player)
	local profile = Data.get(player)
	if not profile then
		return
	end
	if Config.unlockedPenIndex(profile.rebirths) >= #Config.Pens then
		notify(player, "Je hebt alle pennen al vrijgespeeld!", Color3.fromRGB(255, 220, 120))
		return
	end
	local price = Config.rebirthPrice(profile.rebirths)
	if profile.cash < price then
		notify(player, string.format("Rebirth kost %s", Config.short(price)), Color3.fromRGB(255, 150, 150))
		return
	end
	profile.cash -= price
	profile.rebirths += 1
	profile.pens = 0
	profile.dirty = true

	local pen = currentPen(profile)
	notify(player, string.format("REBIRTH %d! Je maakt nu %s (x%.2f prijs)",
		profile.rebirths, pen.name, Config.rebirthMultiplier(profile.rebirths)),
		Color3.fromRGB(200, 120, 255))
	push(player)
	Data.save(player)
end

local function onCharacter(player: Player, character: Model)
	character:WaitForChild("Humanoid")
	task.wait(0.1)
	applyWalkSpeed(player)
end

local function onPlayerAdded(player: Player)
	local profile = Data.load(player)

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

	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end

	push(player)
	notify(player, string.format("Welkom! Je maakt %s.", currentPen(profile).name), Color3.fromRGB(150, 210, 255))
end

local function onPlayerRemoving(player: Player)
	nextProduce[player] = nil
	nextSell[player] = nil
	nextUpgrade[player] = nil
	rebirthHeldSince[player] = nil
	Data.release(player)
end

local function step()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local profile = Data.get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not profile or not root then
			continue
		end

		-- pennen maken
		local pressPad = pads.PenPress
		if pressPad and isOnPad(root, pressPad) then
			local capacity = capacityOf(profile)
			local interval = upgradeValue(profile, "speed")
			local made = 0
			-- bij hoge snelheid passen er meerdere pennen in een tick
			while now >= (nextProduce[player] or 0) and profile.pens < capacity and made < 64 do
				profile.pens += 1
				made += 1
				nextProduce[player] = math.max((nextProduce[player] or now) + interval, now - interval)
			end
			if made > 0 then
				profile.dirty = true
				push(player)
			elseif profile.pens >= capacity and now >= (nextProduce[player] or 0) then
				nextProduce[player] = now + 1
				notify(player, "Je tas zit vol - ga verkopen!", Color3.fromRGB(255, 220, 120))
			end
		else
			nextProduce[player] = math.max(nextProduce[player] or 0, now)
		end

		-- verkopen
		local sellPad = pads.SellDesk
		if sellPad and isOnPad(root, sellPad) and profile.pens > 0 and now >= (nextSell[player] or 0) then
			nextSell[player] = now + SELL_COOLDOWN
			sell(player, profile)
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
end

function Game.start()
	Net.init()

	local root = World.build()
	for _, name in { "PenPress", "SellDesk", "RebirthPad" } do
		local p = World.findPad(root, name)
		if p then
			pads[name] = p
		end
	end
	for _, up in Config.Upgrades do
		local p = World.findPad(root, "UpgradePad_" .. up.key)
		if p then
			pads["UpgradePad_" .. up.key] = p
		end
	end

	local spot = root:FindFirstChild("CustomerSpot")
	if spot and spot:IsA("BasePart") then
		Customers.start(spot)
	end

	Net.event("BuyUpgrade").OnServerEvent:Connect(function(player, key)
		if typeof(key) == "string" then
			buyUpgrade(player, key)
		end
	end)
	Net.event("Rebirth").OnServerEvent:Connect(function(player)
		rebirth(player)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Data.start()

	-- klantwissel: prijzen in de UI bijwerken
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				push(player)
			end
		end
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= TICK then
			acc = 0
			step()
		end
	end)
end

return Game
