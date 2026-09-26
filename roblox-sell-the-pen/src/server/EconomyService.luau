-- Money: multipliers, passive income, the shop, IPOs, leaderstats,
-- player titles and the pen every player carries.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)

local Remotes = ReplicatedStorage.Remotes

local EconomyService = {}

EconomyService.Ranks = {
	{ min = 0, title = "Pen Pusher", color = Color3.fromRGB(200, 200, 200) },
	{ min = 1_000, title = "Cold Caller", color = Color3.fromRGB(140, 220, 140) },
	{ min = 25_000, title = "Stockbroker", color = Color3.fromRGB(110, 190, 255) },
	{ min = 500_000, title = "Big Swinging Pen", color = Color3.fromRGB(200, 140, 255) },
	{ min = 10_000_000, title = "The Wolf", color = Color3.fromRGB(255, 200, 60) },
	{ min = 1_000_000_000, title = "Wolf of Pen Street", color = Color3.fromRGB(255, 110, 40) },
}

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
	for _, broker in Config.Brokers do
		income += (profile.brokers[broker.id] or 0) * broker.income
	end
	return income * EconomyService.ipoMult(profile)
end

local function isOnTradingFloor(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local area = Config.getZone("floor").area
	local p = root.Position
	return p.X >= area.minX - 10 and p.X <= area.maxX + 10 and p.Z >= area.minZ - 10 and p.Z <= area.maxZ + 10
end

-- Everything that boosts a single sale, as one number plus a breakdown.
function EconomyService.saleMult(player, profile)
	local mult = EconomyService.ipoMult(profile)
	local suit = Config.findById(Config.Suits, profile.suit)
	if suit then
		mult *= suit.cashMult
	end
	if Workspace:GetAttribute("SpeechActive") then
		mult *= isOnTradingFloor(player) and Config.Speech.floorMult or Config.Speech.globalMult
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
	})

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.cash(profile.cash)
		stats["Pens Sold"].Value = profile.pensSold
		stats.IPOs.Value = profile.ipos
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
	ipos.Name = "IPOs"
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
		text ..= string.format("  ·  IPO x%d", profile.ipos)
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
	elseif category == "broker" then
		local broker = Config.findById(Config.Brokers, id)
		if not broker then
			return false, "Unknown broker."
		end
		local owned = profile.brokers[id] or 0
		local cost = Config.brokerCost(broker, owned)
		if profile.cash < cost then
			return false, "Not enough cash to hire."
		end
		profile.cash -= cost
		profile.brokers[id] = owned + 1
		DataService.changed(player)
		return true, "Hired " .. broker.name .. "!"
	elseif category == "zone" then
		local zone = Config.getZone(id)
		if not zone then
			return false, "Unknown zone."
		end
		if profile.zones[id] then
			return false, "Already unlocked."
		end
		for index, other in Config.Zones do
			if other.id == id and index > 1 and not profile.zones[Config.Zones[index - 1].id] then
				return false, "Unlock " .. Config.Zones[index - 1].name .. " first."
			end
		end
		if profile.cash < zone.cost then
			return false, "You need " .. Format.cash(zone.cost) .. " to unlock " .. zone.name .. "."
		end
		profile.cash -= zone.cost
		profile.zones[id] = true
		DataService.changed(player)
		EconomyService.notifyAll(player.DisplayName .. " just unlocked " .. zone.name .. "!", "big")
		return true, "Welcome to " .. zone.name .. "!"
	end
	return false, "Unknown category."
end

local function ipo(player)
	local profile = DataService.get(player)
	if not profile then
		return false, "Not ready yet."
	end
	if not profile.zones[Config.IPO.requiresZone] then
		return false, "Unlock the Yacht before going public."
	end
	if profile.cash < Config.IPO.cashRequired then
		return false, "You need " .. Format.cash(Config.IPO.cashRequired) .. " to IPO."
	end
	profile.ipos += 1
	profile.cash = Config.StartingCash
	profile.pen = "bic"
	profile.suit = "thrift"
	profile.phone = "none"
	profile.brokers = {}
	profile.zones = { strip = true }
	DataService.changed(player)
	EconomyService.givePen(player)
	EconomyService.updateTitle(player)

	-- Back to the strip mall where it all began.
	local spawn = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Spawn", true)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if spawn and root then
		root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
	end
	EconomyService.notifyAll(
		string.format("%s just took the firm public! (IPO #%d)", player.DisplayName, profile.ipos),
		"big"
	)
	return true, string.format("IPO complete! Permanent x%.1f multiplier.", EconomyService.ipoMult(profile))
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
	Remotes.IPO.OnServerInvoke = ipo
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
