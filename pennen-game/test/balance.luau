-- Schat hoe lang een speler doet over zijn eerste rebirths, met normaal spel:
-- tas vollopen, naar de toonbank lopen, perfect pitchen, upgrades kopen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = PEN.Config
local net = ReplicatedStorage:FindFirstChild("PenNet")

local WALK_SECONDS = 4 -- heen en weer tussen pers en toonbank

local function remote(name)
	return net:FindFirstChild(name)
end

local function lastPayload(name)
	local data = rawget(remote(name), "_data")
	return data._last and data._last[1]
end

local function advance(seconds)
	local steps = math.max(1, math.floor(seconds / 0.1))
	local slice = seconds / steps
	for _ = 1, steps do
		FAKE_CLOCK += slice
		RunService.Heartbeat:Fire(slice)
	end
end

local player = Instance.new("Player")
player.Name = "Balanstest"
player.UserId = 7
local character = Instance.new("Model")
local humanoid = Instance.new("Humanoid")
humanoid.Parent = character
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Parent = character
player.Character = character
table.insert(rawget(Players, "_data")._list, player)
Players.PlayerAdded:Fire(player)

local profile = PEN.Data.get(player)
local world = workspace:FindFirstChild("PenWorld")

local function standOn(padName)
	local pad = world:FindFirstChild(padName, true)
	root.Position = pad.CFrame.Position + Vector3.new(0, 3, 0)
end

local elapsed = 0

local function station()
	return Config.stationForRebirths(profile.rebirths)
end

-- passief inkomen handmatig bijtellen (die lus slaapt in de test)
local function passive(seconds)
	local total = 0
	for _, s in Config.Stations do
		if profile.rebirths >= s.unlockRebirth then
			total += s.autoPerSecond * s.pen.value
		end
	end
	local up = Config.getUpgrade("auto")
	total *= up.value(profile.upgrades.auto) * Config.rebirthMultiplier(profile.rebirths)
	profile.cash += total * seconds
end

local function tick(seconds)
	advance(seconds)
	passive(seconds)
	elapsed += seconds
end

local function perfectIndex(info)
	local customerType = PEN.Customers.get(station().key).typeKey
	for index, optionText in info.options do
		for _, arg in Config.PitchArguments do
			if arg.text == optionText and table.find(arg.good, customerType) then
				return index
			end
		end
	end
	return 1
end

local function buyUpgrades()
	-- houd wat geld achter de hand voor de rebirth
	for _, key in { "capacity", "speed", "charm", "auto" } do
		local up = Config.getUpgrade(key)
		local level = profile.upgrades[key]
		local price = Config.upgradePrice(up, level)
		if level < up.maxLevel and profile.cash >= price * 2 then
			remote("BuyUpgrade").OnServerEvent:Fire(player, key)
		end
	end
end

local function trip()
	standOn("Press_" .. station().key)
	local guard = 0
	while profile.pens < math.floor(Config.getUpgrade("capacity").value(profile.upgrades.capacity)) and guard < 400 do
		tick(0.5)
		guard += 1
	end
	tick(WALK_SECONDS / 2)
	standOn("Sell_" .. station().key)
	tick(0.3)
	local info = lastPayload("PitchStart")
	if info then
		remote("PitchAnswer").OnServerEvent:Fire(player, info.id, perfectIndex(info))
	end
	tick(WALK_SECONDS / 2)
	buyUpgrades()
end

print("rebirth   speeltijd tot dan   zaak")
for target = 1, 5 do
	local price = Config.rebirthPrice(profile.rebirths)
	local guard = 0
	while profile.cash < price and guard < 4000 do
		trip()
		guard += 1
	end
	if profile.cash < price then
		print(string.format("  %d: niet gehaald binnen de test", target))
		break
	end
	remote("Rebirth").OnServerEvent:Fire(player)
	print(string.format("  %d       %5.1f minuten        %s",
		profile.rebirths, elapsed / 60, station().name))
end

print(string.format("\nTotaal gesimuleerd: %.1f minuten spelen", elapsed / 60))
