-- Spawns the customers that wander each zone, and gives each of them a
-- "Sell Me This Pen" prompt. PitchService takes over when one is pitched.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Visitors = require(ReplicatedStorage.Shared.Visitors)
local Animations = require(ReplicatedStorage.Shared.Animations)
local AnimationService = require(script.Parent.AnimationService)
local OutfitService = require(script.Parent.OutfitService)

local Remotes = ReplicatedStorage.Remotes

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

-- A point on the rim of the area: where visitors walk in from and out to.
local function edgePoint(area)
	local side = rng:NextInteger(1, 4)
	local x = rng:NextNumber(area.minX, area.maxX)
	local z = rng:NextNumber(area.minZ, area.maxZ)
	if side == 1 then
		x = area.minX
	elseif side == 2 then
		x = area.maxX
	elseif side == 3 then
		z = area.minZ
	else
		z = area.maxZ
	end
	return Vector3.new(x, area.y + 3, z)
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

local function makeNameTag(head, visitor, rarity)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(220, 56)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = rarity.odds >= 143 and 250 or 60

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Size = UDim2.fromScale(1, 0.42)
	rarityLabel.Font = Enum.Font.GothamBlack
	rarityLabel.Text = string.upper(rarity.name)
	rarityLabel.TextColor3 = rarity.color
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.TextScaled = true
	rarityLabel.Parent = gui

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, 0.42)
	label.Size = UDim2.fromScale(1, 0.58)
	label.Font = Enum.Font.GothamBold
	label.Text = visitor.name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = gui

	if rarity.id == "ultra" or rarity.id == "exotic" then
		-- Cycle the rarity label through the rainbow.
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 220)),
		})
		gradient.Parent = rarityLabel
		task.spawn(function()
			while gui.Parent do
				gradient.Offset = Vector2.new(math.sin(os.clock() * 2) * 0.5, 0)
				task.wait(0.05)
			end
		end)
	end
	gui.Parent = head
end

local slotOwners = {} -- door zones: [zoneId] = { [slot] = state }

local function buildCustomer(visitor, zone, fromEdge)
	local archetypeKey = visitor.archetype
	local rarity = Config.getRarity(visitor.rarity)
	local model = OutfitService.buildVisitor(visitor)
	if not model then
		return nil
	end

	model.Name = visitor.name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = rng:NextNumber(6, 10)
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge

	local head = model:WaitForChild("Head")
	makeNameTag(head, visitor, rarity)
	makeSpeechBubble(head)

	local root = model:WaitForChild("HumanoidRootPart")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PitchPrompt"
	prompt.ActionText = "Sell Me This Pen"
	prompt.ObjectText = string.format("%s  ·  %s", visitor.name, rarity.name)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt:SetAttribute("Zone", zone.id)
	prompt.Parent = root

	model:SetAttribute("Zone", zone.id)
	model:SetAttribute("Archetype", archetypeKey)
	model:SetAttribute("Rarity", rarity.id)
	prompt:SetAttribute("Rarity", rarity.id)
	local spawnAt
	if zone.mode == "door" then
		spawnAt = zone.door + Vector3.new(rng:NextNumber(-2, 2), 3, 0)
	elseif fromEdge then
		spawnAt = edgePoint(zone.area)
	else
		spawnAt = randomPoint(zone.area)
	end
	model:PivotTo(CFrame.new(spawnAt) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model.Parent = folder
	-- Animations can only load once the rig is in the workspace.
	AnimationService.animateNpc(humanoid, Animations.ByRarity[rarity.id] or Animations.ByArchetype[archetypeKey])
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
		visitor = visitor,
		busy = false,
		leaving = false,
		-- Visitors don't hang around forever: after a while they move on.
		expiresAt = os.clock() + rng:NextNumber(Config.VisitorStay.min, Config.VisitorStay.max),
		cooldowns = {}, -- [Player] = os.clock() until they'll listen again
	}
	customers[model] = state

	prompt.Triggered:Connect(function(player)
		if promptCallback then
			promptCallback(player, state)
		end
	end)

	if zone.mode == "door" then
		-- Walk in from the elevator, take a free spot in the queue and wait.
		slotOwners[zone.id] = slotOwners[zone.id] or {}
		local owners = slotOwners[zone.id]
		for slot, position in zone.queue do
			if not owners[slot] then
				owners[slot] = state
				state.slot = slot
				task.delay(0.5, function()
					-- Through the front door first, then to the spot.
					if zone.entry then
						humanoid:MoveTo(zone.entry)
						humanoid.MoveToFinished:Wait()
					end
					humanoid:MoveTo(position)
					humanoid.MoveToFinished:Wait()
					if model.Parent and not state.busy then
						local face = Vector3.new(position.X, root.Position.Y, position.Z + 5)
						root.CFrame = CFrame.lookAt(root.Position, face)
						CustomerService.say(state, "*ding dong*  You wanted to see me?", 3)
					end
				end)
				break
			end
		end
		-- Leave once their time is up (unless someone is pitching them).
		task.spawn(function()
			while model.Parent and not state.leaving do
				task.wait(1)
				if not state.busy and os.clock() > state.expiresAt then
					CustomerService.leave(state, 0)
				end
			end
		end)
		return state
	end

	-- Wander.
	task.spawn(function()
		while model.Parent and not state.leaving do
			if not state.busy and os.clock() > state.expiresAt then
				CustomerService.leave(state, 0)
				break
			end
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

local function spawnFor(zone, fromEdge)
	local rarity = Config.rollRarity(zone.luck, rng)
	local visitor = pick(Visitors.byRarity[rarity.id])
	local state = buildCustomer(visitor, zone, fromEdge)
	local _, rarityIndex = Config.findById(Config.Rarities, rarity.id)
	local _, announceIndex = Config.findById(Config.Rarities, Config.AnnounceRarity)
	if state and rarityIndex >= announceIndex then
		Remotes.Notify:FireAllClients(
			string.format("A %s visitor appeared at %s: %s!", string.upper(rarity.name), zone.name, visitor.name),
			"event"
		)
	end
	return state
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
-- The visitor walks off (to the rim of the zone, or back out the front
-- door), fades away, and someone new walks in a moment later.
function CustomerService.leave(state, delaySeconds)
	if state.leaving then
		return
	end
	state.leaving = true
	state.busy = true
	state.prompt.Enabled = false
	customers[state.model] = nil
	if state.slot and slotOwners[state.zone.id] then
		slotOwners[state.zone.id][state.slot] = nil
	end
	task.delay(delaySeconds or 0, function()
		local model, humanoid, zone = state.model, state.humanoid, state.zone
		if model.Parent and humanoid.Parent then
			local route = zone.mode == "door" and { zone.entry, zone.door } or { edgePoint(zone.area) }
			for _, point in route do
				if point then
					humanoid:MoveTo(point)
					local finished = false
					local connection = humanoid.MoveToFinished:Once(function()
						finished = true
					end)
					local started = os.clock()
					while not finished and os.clock() - started < 8 and model.Parent do
						task.wait(0.2)
					end
					connection:Disconnect()
				end
			end
			-- Fade out.
			for _, gui in model:GetDescendants() do
				if gui:IsA("BillboardGui") then
					gui.Enabled = false
				end
			end
			for step = 1, 10 do
				for _, part in model:GetDescendants() do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = math.max(part.Transparency, step / 10)
					elseif part:IsA("Decal") then
						part.Transparency = step / 10
					end
				end
				task.wait(0.05)
			end
			model:Destroy()
		end
		task.wait(rng:NextNumber(1, 3))
		spawnFor(zone, true)
	end)
end

-- Kept for callers: a sale or a bust sends the visitor on their way.
function CustomerService.replace(state, delaySeconds)
	CustomerService.leave(state, delaySeconds or 3)
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
