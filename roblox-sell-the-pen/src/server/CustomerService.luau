-- Spawns the customers that wander each zone, and gives each of them a
-- "Sell Me This Pen" prompt. PitchService takes over when one is pitched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PitchData = require(ReplicatedStorage.Shared.PitchData)

local CustomerService = {}

local customers = {} -- [Model] = state
local folder
local promptCallback

local rng = Random.new()

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function randomPoint(area)
	return Vector3.new(rng:NextNumber(area.minX, area.maxX), area.y + 3, rng:NextNumber(area.minZ, area.maxZ))
end

local function makeSpeechBubble(head)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Speech"
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, 4.2, 0)
	gui.MaxDistance = 60
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(20, 20, 20)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = frame
	gui.Parent = head
end

local function makeNameTag(head, archetype)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(180, 40)
	gui.StudsOffset = Vector3.new(0, 2.3, 0)
	gui.MaxDistance = 45

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = archetype.name
	label.TextColor3 = archetype.special == "fbi" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 235, 170)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = head
end

local function addTie(model, color)
	local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	if not torso then
		return
	end
	local tie = Instance.new("Part")
	tie.Name = "Tie"
	tie.Size = Vector3.new(0.35, 1.1, 0.1)
	tie.Color = color
	tie.Material = Enum.Material.Fabric
	tie.CanCollide = false
	tie.CanQuery = false
	tie.Massless = true
	tie.CFrame = torso.CFrame * CFrame.new(0, 0.05, -torso.Size.Z / 2 - 0.04)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = tie
	weld.Parent = tie
	tie.Parent = model
end

local TIE_COLORS = {
	Color3.fromRGB(200, 30, 40),
	Color3.fromRGB(230, 180, 40),
	Color3.fromRGB(40, 60, 160),
	Color3.fromRGB(20, 20, 20),
}

local function buildCustomer(archetypeKey, zone)
	local archetype = PitchData.Archetypes[archetypeKey]
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = archetype.skin
	description.LeftArmColor = archetype.shirt
	description.RightArmColor = archetype.shirt
	description.TorsoColor = archetype.shirt
	description.LeftLegColor = archetype.pants
	description.RightLegColor = archetype.pants
	description.HeightScale = rng:NextNumber(0.92, 1.08)
	description.WidthScale = rng:NextNumber(0.9, 1.15)

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[CustomerService] could not build customer:", model)
		return nil
	end

	model.Name = archetype.name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = rng:NextNumber(6, 10)
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge

	local head = model:WaitForChild("Head")
	-- Hands are the arm color by default; keep them skin colored.
	for _, name in { "LeftHand", "RightHand" } do
		local hand = model:FindFirstChild(name)
		if hand then
			hand.Color = archetype.skin
		end
	end
	if archetypeKey ~= "tourist" and archetypeKey ~= "plumber" and archetypeKey ~= "mom" then
		addTie(model, pick(TIE_COLORS))
	end
	makeNameTag(head, archetype)
	makeSpeechBubble(head)

	local root = model:WaitForChild("HumanoidRootPart")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PitchPrompt"
	prompt.ActionText = "Sell Me This Pen"
	prompt.ObjectText = archetype.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt:SetAttribute("Zone", zone.id)
	prompt.Parent = root

	model:SetAttribute("Zone", zone.id)
	model:SetAttribute("Archetype", archetypeKey)
	model:PivotTo(CFrame.new(randomPoint(zone.area)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local state = {
		model = model,
		humanoid = humanoid,
		root = root,
		prompt = prompt,
		zone = zone,
		archetypeKey = archetypeKey,
		busy = false,
		cooldowns = {}, -- [Player] = os.clock() until they'll listen again
	}
	customers[model] = state

	prompt.Triggered:Connect(function(player)
		if promptCallback then
			promptCallback(player, state)
		end
	end)

	-- Wander.
	task.spawn(function()
		while model.Parent do
			if not state.busy then
				humanoid:MoveTo(randomPoint(zone.area))
				local finished = false
				local connection = humanoid.MoveToFinished:Once(function()
					finished = true
				end)
				local started = os.clock()
				while not finished and not state.busy and os.clock() - started < 9 and model.Parent do
					task.wait(0.25)
				end
				connection:Disconnect()
				if not state.busy then
					humanoid:MoveTo(root.Position)
					task.wait(rng:NextNumber(1.5, 6))
				end
			else
				task.wait(0.5)
			end
			-- Fell off the map somehow: put them back.
			if root.Position.Y < zone.area.y - 30 then
				model:PivotTo(CFrame.new(randomPoint(zone.area)))
			end
		end
	end)

	return state
end

local function spawnFor(zone)
	local archetypeKey = pick(zone.archetypes)
	-- FBI agents are rare.
	if archetypeKey == "fbi" and rng:NextNumber() > 0.35 then
		repeat
			archetypeKey = pick(zone.archetypes)
		until archetypeKey ~= "fbi"
	end
	return buildCustomer(archetypeKey, zone)
end

function CustomerService.say(state, text, duration)
	local head = state.model:FindFirstChild("Head")
	local bubble = head and head:FindFirstChild("Speech")
	if not bubble then
		return
	end
	bubble.Frame.Text.Text = text
	bubble.Enabled = true
	local token = {}
	state.speechToken = token
	task.delay(duration or 3.5, function()
		if state.speechToken == token and bubble.Parent then
			bubble.Enabled = false
		end
	end)
end

function CustomerService.setBusy(state, busy, facePlayer)
	state.busy = busy
	state.prompt.Enabled = not busy
	if busy then
		state.humanoid:MoveTo(state.root.Position)
		local character = facePlayer and facePlayer.Character
		local other = character and character:FindFirstChild("HumanoidRootPart")
		if other then
			local look = Vector3.new(other.Position.X, state.root.Position.Y, other.Position.Z)
			if (look - state.root.Position).Magnitude > 0.1 then
				state.root.CFrame = CFrame.lookAt(state.root.Position, look)
			end
		end
	end
end

-- The customer bought (or got arrested): they leave and someone new shows up.
function CustomerService.replace(state, delaySeconds)
	state.busy = true
	state.prompt.Enabled = false
	customers[state.model] = nil
	task.delay(delaySeconds or 3, function()
		if state.model.Parent then
			state.model:Destroy()
		end
		task.wait(rng:NextNumber(2, 5))
		spawnFor(state.zone)
	end)
end

function CustomerService.start(onPrompt)
	promptCallback = onPrompt

	folder = Instance.new("Folder")
	folder.Name = "Customers"
	folder.Parent = Workspace

	for _, zone in Config.Zones do
		for _ = 1, zone.customers do
			task.spawn(spawnFor, zone)
			task.wait(0.05)
		end
	end
end

return CustomerService
