--!strict
-- Effecten in de wereld die alleen de client tekent: platen die draaien en
-- zweven, songs die je studio in vliegen, regenboogkleuren, de lichtstraal
-- naar huis als je steelt, knockback en de +$ bij het ophalen.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local UI = require(script.Parent.UI)

local World = {}

type Spinner = {
	base: CFrame,
	flyFrom: Vector3?,
	flyAt: number?,
	phase: number,
}

local player = Players.LocalPlayer
local spinners: { [Model]: Spinner } = {}
local rainbowParts: { [BasePart]: number } = {}
local rainbowGradients: { [UIGradient]: boolean } = {}
local carryBeam: { Instance } = {}

local FLY_TIME = 0.9
local SPIN_DISTANCE = 120

local function addSpinner(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local flyFrom = instance:GetAttribute("FlyFrom")
	local flyAt = instance:GetAttribute("FlyAt")
	spinners[instance] = {
		base = instance:GetPivot(),
		flyFrom = if typeof(flyFrom) == "Vector3" then flyFrom else nil,
		flyAt = if type(flyAt) == "number" then flyAt else nil,
		phase = math.random() * math.pi * 2,
	}
end

local function applyRole(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local owner = prompt:GetAttribute("OwnerId")
	local mine = owner == player.UserId
	local role = prompt:GetAttribute("Role")
	if role == "Owner" then
		prompt.Enabled = mine
	elseif role == "Other" then
		prompt.Enabled = not mine and owner ~= 0
	end
end

local function watchTag(tag: string, added: (Instance) -> (), removed: ((Instance) -> ())?)
	CollectionService:GetInstanceAddedSignal(tag):Connect(added)
	if removed then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(removed)
	end
	for _, instance in CollectionService:GetTagged(tag) do
		added(instance)
	end
end

function World.init()
	watchTag("SpinSong", addSpinner, function(instance)
		if instance:IsA("Model") then
			spinners[instance] = nil
		end
	end)
	watchTag("Rainbow", function(instance)
		if instance:IsA("BasePart") then
			rainbowParts[instance] = math.random()
		end
	end, function(instance)
		if instance:IsA("BasePart") then
			rainbowParts[instance] = nil
		end
	end)
	watchTag("RainbowGradient", function(instance)
		if instance:IsA("UIGradient") then
			rainbowGradients[instance] = true
		end
	end, function(instance)
		if instance:IsA("UIGradient") then
			rainbowGradients[instance] = nil
		end
	end)
	watchTag("RolePrompt", function(instance)
		applyRole(instance)
		instance:GetAttributeChangedSignal("OwnerId"):Connect(function()
			applyRole(instance)
		end)
	end)

	if Config.MusicId ~= "" then
		local music = Instance.new("Sound")
		music.Name = "Music"
		music.SoundId = Config.MusicId
		music.Looped = true
		music.Volume = 0.25
		music.Parent = SoundService
		music:Play()
	end
end

function World.update(_dt: number)
	local t = os.clock()
	local now = Workspace:GetServerTimeNow()
	local camera = Workspace.CurrentCamera
	local cameraPos = if camera then camera.CFrame.Position else Vector3.zero

	for model, spinner in spinners do
		if not model.Parent then
			spinners[model] = nil
			continue
		end
		local base = spinner.base
		if (base.Position - cameraPos).Magnitude > SPIN_DISTANCE then
			continue
		end
		local flyFrom, flyAt = spinner.flyFrom, spinner.flyAt
		local cframe
		if flyFrom and flyAt and now - flyAt < FLY_TIME then
			-- In een boog de studio in vliegen
			local alpha = math.clamp((now - flyAt) / FLY_TIME, 0, 1)
			local eased = 1 - (1 - alpha) ^ 3
			local position = flyFrom:Lerp(base.Position, eased) + Vector3.new(0, math.sin(alpha * math.pi) * 10, 0)
			cframe = CFrame.new(position) * base.Rotation * CFrame.Angles(0, alpha * math.pi * 6, 0)
		else
			cframe = base
				* CFrame.new(0, math.sin(t * 2 + spinner.phase) * 0.3, 0)
				* CFrame.Angles(0, t * 1.1 + spinner.phase, 0)
		end
		model:PivotTo(cframe)
	end

	for part, offset in rainbowParts do
		if part.Parent then
			part.Color = Color3.fromHSV((t * 0.3 + offset) % 1, 0.75, 1)
		else
			rainbowParts[part] = nil
		end
	end

	local slide = math.sin(t * 1.5) * 0.5
	for gradient in rainbowGradients do
		gradient.Offset = Vector2.new(slide, 0)
	end
end

local function clearBeam()
	for _, instance in carryBeam do
		instance:Destroy()
	end
	table.clear(carryBeam)
end

-- Een lichtstraal van jou naar je eigen studio zolang je een song draagt
function World.setCarry(info: any)
	clearBeam()
	if not (info and info.active) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local studios = Workspace:FindFirstChild("Studios")
	local studio = studios and studios:FindFirstChild("Studio" .. tostring(info.plotIndex))
	local floor = studio and studio:FindFirstChild("Floor")
	if not root or not floor then
		return
	end
	local from = Instance.new("Attachment")
	from.CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 1, 0), Vector3.new(-1, 0, 0))
	from.Parent = root
	local to = Instance.new("Attachment")
	to.CFrame = CFrame.fromMatrix(Vector3.new(0, 3, 0), Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
	to.Parent = floor
	local beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Color = ColorSequence.new(Color3.fromRGB(90, 255, 120), Color3.fromRGB(255, 255, 255))
	beam.Transparency = NumberSequence.new(0.25)
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Width0 = 1.4
	beam.Width1 = 2.5
	beam.CurveSize0 = 18
	beam.CurveSize1 = 18
	beam.Segments = 24
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 3
	beam.TextureSpeed = 2
	beam.Parent = floor
	carryBeam = { from, to, beam }
end

-- Geraakt door een gitaar: wegvliegen en even omvallen
function World.knockback(info: any)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = info.velocity
	UI.sound("Hit", 0.9 + math.random() * 0.3, 0.7)

	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < 0.35 do
			humanoid.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * 0.8
			task.wait()
		end
		humanoid.CameraOffset = Vector3.zero
	end)

	task.delay(info.stun or 1, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- "+$123" dat omhoog zweeft boven het pad
function World.collected(info: any)
	UI.sound("Collect", 1 + math.random() * 0.3, 0.45)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = info.position + Vector3.new(0, 2, 0)
	anchor.Parent = Workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 56)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = UI.text({
		Text = "+" .. Format.cash(info.amount),
		TextColor3 = UI.colors.green,
		strokeThickness = 3,
		Parent = gui,
	})

	UI.tween(anchor, 1.1, { Position = anchor.Position + Vector3.new(0, 5, 0) })
	task.delay(0.6, function()
		UI.tween(label, 0.5, { TextTransparency = 1 })
	end)
	Debris:AddItem(anchor, 1.3)
end

return World
