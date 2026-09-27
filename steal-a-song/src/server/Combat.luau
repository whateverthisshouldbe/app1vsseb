--!strict
-- De gitaar: iedereen krijgt er een. Een klap duwt de ander weg en een dief
-- laat zijn gestolen song vallen. Geen schade, alleen chaos.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Remotes = require(script.Parent.Remotes)
local Stealing = require(script.Parent.Stealing)

local Combat = {}

local lastSwing: { [Player]: number } = {}
local rng = Random.new()

local BONK_WORDS = { "BONK!", "SMACK!", "TWANG!", "WHAM!", "POW!" }

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function playSound(parent: Instance, soundId: string, speed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.8
	sound.PlaybackSpeed = speed or 1
	sound.RollOffMaxDistance = 80
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function weldedPart(handle: BasePart, props: { [string]: any }, offset: CFrame): Part
	local p = Instance.new("Part")
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Shape" then
			(p :: any)[key] = value
		end
	end
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = handle.Parent
	return p
end

local function buildGuitar(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Guitar"
	tool.ToolTip = "Smack thieves!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.GripPos = Vector3.new(0, 0, -1.3)
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)

	-- De hals is de Handle; de body zit aan het +Z eind, ver van de hand
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.35, 3.6)
	handle.Color = Color3.fromRGB(120, 72, 40)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	local red = Color3.fromRGB(230, 40, 80)
	weldedPart(handle, {
		Name = "BodyLower",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 2.6, 2.6),
		Color = red,
	}, CFrame.new(0, 0, 2.6))
	weldedPart(handle, {
		Name = "BodyUpper",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 2, 2),
		Color = red,
	}, CFrame.new(0, 0, 1.3))
	weldedPart(handle, {
		Name = "Pickup",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.55, 0.8, 0.8),
		Color = Color3.fromRGB(20, 20, 24),
	}, CFrame.new(0, 0, 2.2))
	weldedPart(handle, {
		Name = "Headstock",
		Size = Vector3.new(0.3, 0.6, 0.9),
		Color = Color3.fromRGB(30, 26, 34),
	}, CFrame.new(0, 0, -2.1))
	weldedPart(handle, {
		Name = "Strings",
		Size = Vector3.new(0.05, 0.12, 4.6),
		Color = Color3.fromRGB(255, 240, 200),
		Material = Enum.Material.Neon,
	}, CFrame.new(0.22, 0, 0.6))

	return tool
end

local function bonk(root: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(5, 2)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = BONK_WORDS[rng:NextInteger(1, #BONK_WORDS)]
	label.TextColor3 = Color3.fromHSV(rng:NextNumber(), 0.7, 1)
	label.Rotation = rng:NextNumber(-15, 15)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = root
	Debris:AddItem(gui, 0.8)
end

local function hit(attacker: Player, victim: Player, direction: Vector3)
	local root = rootOf(victim)
	if not root then
		return
	end
	Remotes.fire("Knockback", victim, {
		velocity = direction * 60 + Vector3.new(0, 35, 0),
		stun = Config.HitStunSeconds,
	})
	playSound(root, Config.Sounds.Hit, rng:NextNumber(0.9, 1.2))
	bonk(root)
	Stealing.onHit(victim, attacker)
end

function Combat.swing(player: Player, tool: Tool)
	local now = os.clock()
	if (lastSwing[player] or 0) + Config.HitCooldown > now then
		return
	end
	lastSwing[player] = now

	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if not root or not humanoid or humanoid.Health <= 0 or tool.Parent ~= player.Character then
		return
	end

	-- Het standaard Animate-script speelt hierop de slash-animatie af
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	Debris:AddItem(anim, 1)

	local handle = tool:FindFirstChild("Handle")
	if handle then
		playSound(handle, Config.Sounds.Swing, rng:NextNumber(0.95, 1.1))
	end

	local look = root.CFrame.LookVector
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local otherRoot = rootOf(other)
			local otherHumanoid = humanoidOf(other)
			if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
				local offset = otherRoot.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local distance = flat.Magnitude
				if distance <= Config.HitRange and math.abs(offset.Y) < 7 then
					local direction = if distance > 0.1 then flat.Unit else look
					if distance < 3 or direction:Dot(look) > 0.2 then
						hit(player, other, direction)
					end
				end
			end
		end
	end
end

function Combat.giveTool(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	local existing = backpack:FindFirstChild("Guitar")
	if existing then
		existing:Destroy()
	end
	local tool = buildGuitar()
	tool.Activated:Connect(function()
		Combat.swing(player, tool)
	end)
	tool.Parent = backpack
end

function Combat.init()
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return Combat
