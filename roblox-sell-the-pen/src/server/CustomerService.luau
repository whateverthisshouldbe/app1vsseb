-- Spawns the customers that wander each zone, and gives each of them a
-- "Sell Me This Pen" prompt. PitchService takes over when one is pitched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PitchData = require(ReplicatedStorage.Shared.PitchData)
local Visitors = require(ReplicatedStorage.Shared.Visitors)
local Animations = require(ReplicatedStorage.Shared.Animations)
local AnimationService = require(script.Parent.AnimationService)

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

local function weld(model, anchorName, part, offset)
	local anchor = model:FindFirstChild(anchorName)
	if not anchor then
		return
	end
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = anchor.CFrame * offset
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = anchor
	constraint.Part1 = part
	constraint.Parent = part
	part.Parent = model
end

-- Rarer visitors look the part: hats, gold, auras.
local function decorate(model, rarity)
	local head = model:FindFirstChild("Head")
	if not head then
		return
	end
	local id = rarity.id
	if id == "epic" or id == "mythic" then
		local brim = Instance.new("Part")
		brim.Size = Vector3.new(1.9, 0.12, 1.9)
		brim.Color = Color3.fromRGB(20, 20, 20)
		weld(model, "Head", brim, CFrame.new(0, head.Size.Y / 2 + 0.05, 0))
		local top = Instance.new("Part")
		top.Size = Vector3.new(1.2, 1.2, 1.2)
		top.Color = id == "mythic" and rarity.color or Color3.fromRGB(20, 20, 20)
		weld(model, "Head", top, CFrame.new(0, head.Size.Y / 2 + 0.7, 0))
	end
	if id == "mythic" or id == "legendary" or id == "exotic" or id == "ultra" then
		local chain = Instance.new("Part")
		chain.Size = Vector3.new(1.3, 0.25, 0.12)
		chain.Color = Color3.fromRGB(255, 210, 60)
		chain.Material = Enum.Material.Foil
		local torso = model:FindFirstChild("UpperTorso")
		if torso then
			weld(model, "UpperTorso", chain, CFrame.new(0, 0.35, -torso.Size.Z / 2 - 0.05))
		end
	end
	if id == "legendary" or id == "exotic" or id == "ultra" then
		local crown = Instance.new("Part")
		crown.Size = Vector3.new(1.3, 0.6, 1.3)
		crown.Color = id == "exotic" and rarity.color or Color3.fromRGB(255, 205, 50)
		crown.Material = Enum.Material.Foil
		weld(model, "Head", crown, CFrame.new(0, head.Size.Y / 2 + 0.3, 0))
	end
	if id ~= "common" and id ~= "rare" then
		local root = model:FindFirstChild("HumanoidRootPart")
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "Aura"
		aura.Color = ColorSequence.new(rarity.color)
		aura.LightEmission = 0.8
		aura.Size = NumberSequence.new(0.35, 0)
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(0.5, 1.5)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Rate = ({ superrare = 6, epic = 12, mythic = 20, legendary = 30, exotic = 45, ultra = 80 })[id] or 5
		aura.Parent = root
		if id == "legendary" or id == "exotic" or id == "ultra" then
			local glow = Instance.new("PointLight")
			glow.Color = id == "ultra" and Color3.fromRGB(255, 230, 150) or rarity.color
			glow.Brightness = 2
			glow.Range = 14
			glow.Parent = root
		end
	end
	if id == "ultra" then
		-- Beldan Jolfort: the full golden treatment.
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part.Name ~= "Head" and part.Name ~= "HumanoidRootPart" and not part.Name:find("Hand") then
				if part.Name:find("Torso") or part.Name:find("Arm") or part.Name:find("Leg") or part.Name:find("Foot") then
					part.Color = Color3.fromRGB(25, 25, 25)
				end
			end
		end
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 215, 80)
		sparkles.Parent = model:FindFirstChild("HumanoidRootPart")
	end
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
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = torso
	constraint.Part1 = tie
	constraint.Parent = tie
	tie.Parent = model
end

local TIE_COLORS = {
	Color3.fromRGB(200, 30, 40),
	Color3.fromRGB(230, 180, 40),
	Color3.fromRGB(40, 60, 160),
	Color3.fromRGB(20, 20, 20),
}

local SKIN_TONES = {
	Color3.fromRGB(255, 220, 190),
	Color3.fromRGB(240, 195, 160),
	Color3.fromRGB(215, 160, 120),
	Color3.fromRGB(175, 120, 85),
	Color3.fromRGB(130, 85, 60),
	Color3.fromRGB(95, 60, 45),
}

local function vary(color, seeded, amount)
	local function channel(value)
		return math.clamp(value + seeded:NextNumber(-amount, amount), 0, 1)
	end
	return Color3.new(channel(color.R), channel(color.G), channel(color.B))
end

local slotOwners = {} -- door zones: [zoneId] = { [slot] = state }

local function buildCustomer(visitor, zone)
	local archetypeKey = visitor.archetype
	local archetype = PitchData.Archetypes[archetypeKey]
	local rarity = Config.getRarity(visitor.rarity)
	-- The same visitor always looks the same.
	local seeded = Random.new(visitor.number * 7919)
	local skin = SKIN_TONES[seeded:NextInteger(1, #SKIN_TONES)]
	local shirt = vary(archetype.shirt, seeded, 0.12)
	local pants = vary(archetype.pants, seeded, 0.08)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = skin
	description.LeftArmColor = shirt
	description.RightArmColor = shirt
	description.TorsoColor = shirt
	description.LeftLegColor = pants
	description.RightLegColor = pants
	description.HeightScale = seeded:NextNumber(0.92, 1.08)
	description.WidthScale = seeded:NextNumber(0.9, 1.15)

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[CustomerService] could not build customer:", model)
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
	-- Hands are the arm color by default; keep them skin colored.
	for _, name in { "LeftHand", "RightHand" } do
		local hand = model:FindFirstChild(name)
		if hand then
			hand.Color = skin
		end
	end
	if archetypeKey ~= "tourist" and archetypeKey ~= "plumber" and archetypeKey ~= "mom" and archetypeKey ~= "crypto" then
		addTie(model, TIE_COLORS[seeded:NextInteger(1, #TIE_COLORS)])
	end
	makeNameTag(head, visitor, rarity)
	makeSpeechBubble(head)
	decorate(model, rarity)

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
	local spawnAt = zone.mode == "door" and (zone.door + Vector3.new(rng:NextNumber(-2, 2), 3, 0)) or randomPoint(zone.area)
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
		return state
	end

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
	local rarity = Config.rollRarity(zone.luck, rng)
	local visitor = pick(Visitors.byRarity[rarity.id])
	local state = buildCustomer(visitor, zone)
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
function CustomerService.replace(state, delaySeconds)
	state.busy = true
	state.prompt.Enabled = false
	customers[state.model] = nil
	if state.slot and slotOwners[state.zone.id] then
		slotOwners[state.zone.id][state.slot] = nil
	end
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
