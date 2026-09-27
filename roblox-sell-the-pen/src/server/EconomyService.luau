-- Money: multipliers, passive income, the shop, IPOs, leaderstats,
-- player titles and the pen every player carries.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Visitors = require(ReplicatedStorage.Shared.Visitors)
local Tutorial = require(ReplicatedStorage.Shared.Tutorial)
local DataService = require(script.Parent.DataService)

local Remotes = ReplicatedStorage.Remotes

local EconomyService = {}

EconomyService.Ranks = Config.Ranks

function EconomyService.notify(player, text, kind)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

function EconomyService.notifyAll(text, kind)
	Remotes.Notify:FireAllClients(text, kind or "info")
end

function EconomyService.getRank(lifetime)
	local best = EconomyService.Ranks[1]
	for _, rank in EconomyService.Ranks do
		if lifetime >= rank.min then
			best = rank
		end
	end
	return best
end

function EconomyService.ipoMult(profile)
	return 1 + profile.ipos * Config.IPO.multPerIPO
end

function EconomyService.passiveIncome(profile)
	local income = 0
	local phone = Config.findById(Config.Phones, profile.phone)
	if phone then
		income += phone.income
	end
	for _, visitorId in profile.brokers do
		local visitor = Visitors.byId[visitorId]
		if visitor then
			income += Config.brokerIncome(visitor.rarity)
		end
	end
	return income * EconomyService.ipoMult(profile) * EconomyService.boostMult(profile)
end

-- The tutorial reward: temporary x2 money.
function EconomyService.boostMult(profile)
	return (profile.boostUntil or 0) > os.time() and Tutorial.RewardMult or 1
end

function EconomyService.indexCount(profile)
	local count = 0
	for id in profile.index do
		if Visitors.byId[id] then
			count += 1
		end
	end
	return count
end

function EconomyService.indexMult(profile)
	return 1 + EconomyService.indexCount(profile) * Config.IndexBonusPerVisitor
end

-- Everything that boosts a single sale, as one number plus a breakdown.
function EconomyService.saleMult(player, profile)
	local mult = EconomyService.ipoMult(profile) * EconomyService.indexMult(profile) * EconomyService.boostMult(profile)
	local suit = Config.findById(Config.Suits, profile.suit)
	if suit then
		mult *= suit.cashMult
	end
	if Workspace:GetAttribute("SpeechActive") then
		mult *= Config.Speech.mult
	end
	if (player:GetAttribute("HumUntil") or 0) > os.clock() then
		local humming = 0
		for _, other in Players:GetPlayers() do
			if (other:GetAttribute("HumUntil") or 0) > os.clock() then
				humming += 1
			end
		end
		mult *= humming >= Config.Hum.crowdSize and Config.Hum.crowdMult or Config.Hum.mult
	end
	return mult
end

local function sync(player, profile)
	Remotes.DataSync:FireClient(player, {
		profile = profile,
		income = EconomyService.passiveIncome(profile),
		ipoMult = EconomyService.ipoMult(profile),
		nextIpoMult = 1 + (profile.ipos + 1) * Config.IPO.multPerIPO,
		rebirthCost = Config.rebirthCost(profile.ipos),
		indexCount = EconomyService.indexCount(profile),
		indexMult = EconomyService.indexMult(profile),
	})

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.cash(profile.cash)
		stats["Pens Sold"].Value = profile.pensSold
		stats.Rebirths.Value = profile.ipos
	end

	local rank = EconomyService.getRank(profile.lifetime)
	if player:GetAttribute("Rank") ~= rank.title then
		player:SetAttribute("Rank", rank.title)
		EconomyService.updateTitle(player)
	end
end

local function createLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local sold = Instance.new("IntValue")
	sold.Name = "Pens Sold"
	sold.Parent = stats
	local ipos = Instance.new("IntValue")
	ipos.Name = "Rebirths"
	ipos.Parent = stats
	stats.Parent = player
end

-- Overhead title: rank + IPO count.
function EconomyService.updateTitle(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local profile = DataService.get(player)
	if not head or not profile then
		return
	end
	local rank = EconomyService.getRank(profile.lifetime)
	local gui = head:FindFirstChild("RankTitle")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "RankTitle"
		gui.Size = UDim2.fromOffset(200, 50)
		gui.StudsOffset = Vector3.new(0, 2.6, 0)
		gui.MaxDistance = 80
		gui.AlwaysOnTop = false
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
		gui.Parent = head
	end
	local text = rank.title
	if profile.ipos > 0 then
		text ..= string.format("  ·  Rebirth %d", profile.ipos)
	end
	gui.Label.Text = text
	gui.Label.TextColor3 = rank.color
end

-- Every player holds their current pen.
function EconomyService.givePen(player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local pen = Config.findById(Config.Pens, profile.pen)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	for _, container in { backpack, player.Character } do
		if container then
			local old = container:FindFirstChild("SalesPen")
			if old then
				old:Destroy()
			end
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = "SalesPen"
	tool.ToolTip = pen.name
	tool.CanBeDropped = false
	tool.GripPos = Vector3.new(0, -0.1, 0)
	tool.GripForward = Vector3.new(0, 0, -1)
	tool.GripUp = Vector3.new(0, 1, 0)
	tool:SetAttribute("PenName", pen.name)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.18, 1.4, 0.18)
	handle.Color = pen.color
	handle.Material = pen.id == "diamond" and Enum.Material.Glass or Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent = handle
	handle.Parent = tool

	local cap = Instance.new("Part")
	cap.Name = "Cap"
	cap.Size = Vector3.new(0.22, 0.4, 0.22)
	cap.Color = pen.id == "gold" and Color3.fromRGB(255, 230, 140) or Color3.fromRGB(230, 200, 90)
	cap.Material = Enum.Material.Metal
	cap.CanCollide = false
	cap.Massless = true
	cap.CFrame = handle.CFrame * CFrame.new(0, 0.55, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = cap
	weld.Parent = cap
	cap.Parent = tool

	if pen.id == "wolf" or pen.id == "diamond" then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = pen.color
		sparkle.Parent = handle
	end

	tool.Parent = backpack
end

local CATEGORY_LISTS = {
	pen = Config.Pens,
	suit = Config.Suits,
	phone = Config.Phones,
}

function EconomyService.purchase(player, category, id)
	local profile = DataService.get(player)
	if not profile or type(category) ~= "string" or type(id) ~= "string" then
		return false, "Not ready yet."
	end

	if CATEGORY_LISTS[category] then
		local list = CATEGORY_LISTS[category]
		local item, index = Config.findById(list, id)
		local _, currentIndex = Config.findById(list, profile[category])
		if not item then
			return false, "Unknown item."
		end
		if index <= (currentIndex or 0) then
			return false, "You already own something better."
		end
		if profile.cash < item.cost then
			return false, "Not enough cash. Go sell some pens!"
		end
		profile.cash -= item.cost
		profile[category] = id
		DataService.changed(player)
		if category == "pen" then
			EconomyService.givePen(player)
		end
		return true, "Bought " .. item.name .. "!"
	end
	return false, "Unknown category."
end

local function teleportTo(player, position)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(position)
	end
end

function EconomyService.teleport(player, zoneId)
	local profile = DataService.get(player)
	local zone = type(zoneId) == "string" and Config.getZone(zoneId)
	if not profile or not zone then
		return false, "Unknown zone."
	end
	if player:GetAttribute("InPitch") then
		return false, "Finish your pitch first."
	end
	if not Config.zoneUnlocked(profile, zone.id) then
		return false, string.format("%s needs %d rebirths.", zone.name, zone.rebirths)
	end
	teleportTo(player, zone.tp)
	return true, "Welcome to " .. zone.name .. "."
end

local function rebirth(player)
	local profile = DataService.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	local cost = Config.rebirthCost(profile.ipos)
	if profile.cash < cost then
		return false, "You need " .. Format.cash(cost) .. " to rebirth."
	end
	local before = {}
	for _, zone in Config.Zones do
		before[zone.id] = Config.zoneUnlocked(profile, zone.id)
	end

	profile.ipos += 1
	profile.cash = Config.StartingCash
	profile.pen = "bic"
	profile.suit = "thrift"
	profile.phone = "none"
	DataService.changed(player)
	EconomyService.givePen(player)
	EconomyService.updateTitle(player)

	EconomyService.notifyAll(
		string.format("%s just took the firm public! (Rebirth %d)", player.DisplayName, profile.ipos),
		"big"
	)
	-- New zone? Take them straight there.
	for _, zone in Config.Zones do
		if not before[zone.id] and Config.zoneUnlocked(profile, zone.id) then
			teleportTo(player, zone.tp)
			task.delay(1, EconomyService.notify, player, "NEW ZONE UNLOCKED: " .. zone.name .. "!", "big")
		end
	end
	return true, string.format("Rebirth complete! Permanent x%.1f multiplier.", EconomyService.ipoMult(profile))
end

-- A visitor joins your firm. When the firm is full the weakest broker is
-- replaced (only if the new one earns more).
function EconomyService.recruit(player, visitorId)
	local profile = DataService.get(player)
	local visitor = Visitors.byId[visitorId]
	if not profile or not visitor then
		return false
	end
	if #profile.brokers >= Config.MaxBrokers then
		local weakestIndex, weakestIncome = nil, math.huge
		for index, id in profile.brokers do
			local other = Visitors.byId[id]
			local income = other and Config.brokerIncome(other.rarity) or 0
			if income < weakestIncome then
				weakestIndex, weakestIncome = index, income
			end
		end
		if not weakestIndex or weakestIncome >= Config.brokerIncome(visitor.rarity) then
			return false
		end
		table.remove(profile.brokers, weakestIndex)
	end
	table.insert(profile.brokers, visitorId)
	DataService.changed(player)
	return true
end

-- The weakest broker a new recruit would replace, if the firm is full.
function EconomyService.weakestBroker(profile)
	if #profile.brokers < Config.MaxBrokers then
		return nil
	end
	local weakest, weakestIncome = nil, math.huge
	for _, id in profile.brokers do
		local visitor = Visitors.byId[id]
		local income = visitor and Config.brokerIncome(visitor.rarity) or 0
		if income < weakestIncome then
			weakest, weakestIncome = visitor, income
		end
	end
	return weakest
end

local function fireBroker(player, slot)
	local profile = DataService.get(player)
	slot = tonumber(slot)
	if not profile or not slot or not profile.brokers[slot] then
		return false, "No broker in that seat."
	end
	local visitor = Visitors.byId[profile.brokers[slot]]
	table.remove(profile.brokers, slot)
	DataService.changed(player)
	return true, (visitor and visitor.name or "Broker") .. " cleared out their desk."
end

-- Tutorial progress. The client reports each finished step in order; the
-- server saves it and pays the reward at the end.
local function onTutorial(player, stepId)
	local profile = DataService.get(player)
	if not profile or profile.tutorialDone or type(stepId) ~= "string" then
		return
	end
	if stepId == "reset" then
		-- A pitch fell through before the deal: start the pitch part again.
		if profile.tutorialStep < Tutorial.byId.deal.index then
			profile.tutorialStep = 0
			DataService.changed(player)
		end
		return
	end
	local step = Tutorial.byId[stepId]
	if not step or step.index ~= profile.tutorialStep + 1 then
		return
	end
	if step.id == "shop" and profile.pen == "bic" then
		return
	end
	profile.tutorialStep = step.index

	local nextStep = Tutorial.Steps[step.index + 1]
	if nextStep and nextStep.id == "shop" and profile.pen == "bic" then
		-- Make sure they can afford the pen the tutorial asks for.
		local pen = Config.findById(Config.Pens, Tutorial.ShopTarget)
		if profile.cash < pen.cost then
			profile.cash = pen.cost
		end
	end
	if step.index == #Tutorial.Steps then
		profile.tutorialDone = true
		profile.boostUntil = os.time() + Tutorial.RewardDuration
		EconomyService.notify(
			player,
			string.format("TUTORIAL COMPLETE! x%d money for %d minutes. Go get rich.", Tutorial.RewardMult, Tutorial.RewardDuration / 60),
			"big"
		)
	end
	DataService.changed(player)
end

function EconomyService.onPlayerLoaded(player, profile)
	createLeaderstats(player)

	-- Offline earnings from phones and brokers.
	if profile.lastOnline > 0 then
		local away = math.clamp(os.time() - profile.lastOnline, 0, Config.OfflineEarningsCap)
		local earned = math.floor(EconomyService.passiveIncome(profile) * away * Config.OfflineEarningsRate)
		if earned > 0 then
			DataService.addCash(player, earned)
			task.delay(3, EconomyService.notify, player, "Your brokers made " .. Format.cash(earned) .. " while you were away.", "big")
		end
	end

	-- Daily bonus.
	if os.time() - profile.lastDaily >= Config.DailyBonusCooldown then
		profile.lastDaily = os.time()
		local bonus = math.max(250, math.floor(EconomyService.passiveIncome(profile) * 300))
		DataService.addCash(player, bonus)
		task.delay(5, EconomyService.notify, player, "Daily bonus: " .. Format.cash(bonus) .. ". Rise and grind.", "big")
	end

	sync(player, profile)

	local function onCharacter(character)
		character:WaitForChild("Head")
		task.wait(0.2)
		EconomyService.givePen(player)
		EconomyService.updateTitle(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

function EconomyService.start()
	DataService.onChanged(sync)

	Remotes.Purchase.OnServerInvoke = function(player, category, id)
		local ok, message = EconomyService.purchase(player, category, id)
		return ok, message
	end
	Remotes.IPO.OnServerInvoke = rebirth
	Remotes.Teleport.OnServerInvoke = EconomyService.teleport
	Remotes.FireBroker.OnServerInvoke = fireBroker
	Remotes.Tutorial.OnServerEvent:Connect(onTutorial)
	-- The client asks for a snapshot once its UI is listening.
	Remotes.DataSync.OnServerEvent:Connect(function(player)
		local profile = DataService.get(player)
		if profile then
			sync(player, profile)
		end
	end)

	-- Passive income tick.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local profile = DataService.get(player)
				if profile then
					local income = EconomyService.passiveIncome(profile)
					if income > 0 then
						DataService.addCash(player, income)
					end
				end
			end
		end
	end)
end

return EconomyService
