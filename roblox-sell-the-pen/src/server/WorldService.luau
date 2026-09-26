-- The living world: harbor water, zone gates, the Wolf Speech event,
-- the chest-thump hum and the global leaderboard board.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local Remotes = ReplicatedStorage.Remotes

local WorldService = {}

local map = Workspace:WaitForChild("Map")

local function fillWater()
	local terrain = Workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(25, 70, 90)
	terrain.WaterTransparency = 0.35
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 8
	-- East river + harbor + the sound around Long Island, in chunks.
	for x = -760, 760, 190 do
		for z = -560, 760, 190 do
			terrain:FillBlock(CFrame.new(x, -18, z), Vector3.new(190, 30, 190), Enum.Material.Water)
			terrain:FillBlock(CFrame.new(x, -36, z), Vector3.new(190, 6, 190), Enum.Material.Sand)
		end
		task.wait()
	end
end

-- Parts named "Elevator_<zoneId>" take you to that zone.
local function setupElevators()
	for _, part in map:GetDescendants() do
		local zoneId = part:IsA("BasePart") and string.match(part.Name, "^Elevator_(%w+)$")
		local zone = zoneId and Config.getZone(zoneId)
		if zone then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ElevatorPrompt"
			prompt.ActionText = "Ride elevator"
			prompt.ObjectText = zone.name .. (zone.rebirths > 0 and string.format(" (%d rebirths)", zone.rebirths) or "")
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = part
			prompt.Triggered:Connect(function(player)
				local ok, message = EconomyService.teleport(player, zone.id)
				EconomyService.notify(player, message, ok and "success" or "error")
			end)
		end
	end
end

-- The Wolf Speech ---------------------------------------------------------

local function setStage(active)
	local stage = map:FindFirstChild("SpeechStage", true)
	if not stage then
		return
	end
	for _, descendant in stage:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "StageLight" then
			descendant.Color = active and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 190, 60)
		elseif descendant:IsA("SpotLight") or descendant:IsA("PointLight") then
			descendant.Brightness = active and 6 or 2
		end
	end
end

local SPEECH_LINES = {
	"Let me tell you something. There's no nobility in poverty!",
	"I'm not leaving! The show goes on!",
	"Pick up the phone and start dialing!",
	"The only thing standing between you and your goal is the story you keep telling yourself!",
	"Are you behind a desk right now? Then SELL SOMETHING!",
}

local function runSpeechLoop()
	while true do
		local startsAt = os.time() + Config.Speech.interval
		Workspace:SetAttribute("SpeechAt", startsAt)
		task.wait(Config.Speech.interval - Config.Speech.warning)
		EconomyService.notifyAll(
			"The Wolf takes the stage in " .. Config.Speech.warning .. "s! Get to the Trading Floor for x"
				.. Config.Speech.floorMult .. " sales!",
			"event"
		)
		task.wait(Config.Speech.warning)

		Workspace:SetAttribute("SpeechActive", true)
		Workspace:SetAttribute("SpeechEndsAt", os.time() + Config.Speech.duration)
		Workspace:SetAttribute("SpeechLine", SPEECH_LINES[math.random(1, #SPEECH_LINES)])
		setStage(true)
		task.wait(Config.Speech.duration)
		Workspace:SetAttribute("SpeechActive", false)
		setStage(false)
		EconomyService.notifyAll("The speech is over. Back to the phones!", "info")
	end
end

-- The hum -----------------------------------------------------------------

local humCooldowns = {}

local function showHum(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("HumBubble")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "HumBubble"
	gui.Size = UDim2.fromOffset(170, 40)
	gui.StudsOffset = Vector3.new(0, 4.4, 0)
	gui.MaxDistance = 90
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = "mm-MM-mm-MM"
	label.TextColor3 = Color3.fromRGB(255, 220, 90)
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = head
	task.delay(Config.Hum.duration, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

local function onHum(player)
	local now = os.clock()
	if (humCooldowns[player] or 0) > now then
		return
	end
	humCooldowns[player] = now + Config.Hum.cooldown
	player:SetAttribute("HumUntil", now + Config.Hum.duration)
	player:SetAttribute("HumReadyAt", os.time() + Config.Hum.cooldown)
	showHum(player)

	local humming = 0
	for _, other in Players:GetPlayers() do
		if (other:GetAttribute("HumUntil") or 0) > now then
			humming += 1
		end
	end
	if humming >= Config.Hum.crowdSize then
		EconomyService.notifyAll(
			string.format("%d wolves are humming! Sales x%.2f for everyone humming.", humming, Config.Hum.crowdMult),
			"event"
		)
	else
		EconomyService.notify(player, string.format("You're humming. Sales x%.1f for %ds.", Config.Hum.mult, Config.Hum.duration), "success")
	end
end

-- Leaderboard -------------------------------------------------------------

local function buildBoard(part)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Board"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Brightness = 1.4

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(8, 14, 12)
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.14, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Text = "RICHEST WOLVES (ALL-TIME)"
	title.TextColor3 = Color3.fromRGB(255, 205, 70)
	title.Parent = bg

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Position = UDim2.fromScale(0.04, 0.16)
	list.Size = UDim2.fromScale(0.92, 0.82)
	list.BackgroundTransparency = 1
	list.Parent = bg
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = list

	gui.Parent = part
	return list
end

local function refreshBoard(list)
	local top = DataService.getTopEarners(10)
	if #top == 0 then
		-- No DataStores (Studio): show the players in this server instead.
		for _, player in Players:GetPlayers() do
			local profile = DataService.get(player)
			if profile then
				table.insert(top, { name = player.DisplayName, value = profile.lifetime })
			end
		end
		table.sort(top, function(a, b)
			return a.value > b.value
		end)
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for rank = 1, math.min(10, #top) do
		local entry = top[rank]
		local row = Instance.new("TextLabel")
		row.LayoutOrder = rank
		row.Size = UDim2.new(1, 0, 0.09, 0)
		row.BackgroundTransparency = rank % 2 == 0 and 1 or 0.85
		row.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
		row.Font = Enum.Font.Code
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = rank == 1 and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(120, 255, 160)
		row.Text = string.format(" #%-2d %-18s %s", rank, string.sub(entry.name, 1, 18), Format.cash(entry.value))
		row.Parent = list
	end
end

function WorldService.start()
	task.spawn(fillWater)
	setupElevators()
	setStage(false)
	task.spawn(runSpeechLoop)

	Remotes.Hum.OnServerEvent:Connect(onHum)
	Players.PlayerRemoving:Connect(function(player)
		humCooldowns[player] = nil
	end)

	local boardPart = map:FindFirstChild("LeaderboardBoard", true)
	if boardPart then
		local list = buildBoard(boardPart)
		task.spawn(function()
			task.wait(5)
			while true do
				refreshBoard(list)
				task.wait(60)
			end
		end)
	end
end

return WorldService
