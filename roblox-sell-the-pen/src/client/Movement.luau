-- Sprint (hold Left Shift, or the RUN button on touch screens) and the
-- occasional flip when you jump. Flips are visual only: they rotate the
-- root joint, so physics and collisions are untouched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent.UI.Theme)
local Store = require(script.Parent.Store)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local Movement = {}

local WALK_SPEED = 16
local SPRINT_SPEED = 28
local FLIP_CHANCE = 0.35
local FLIP_TIME = 0.5

local FLIPS = {
	back = function(t)
		return CFrame.Angles(t * math.pi * 2, 0, 0)
	end,
	front = function(t)
		return CFrame.Angles(-t * math.pi * 2, 0, 0)
	end,
	side = function(t)
		return CFrame.Angles(0, 0, t * math.pi * 2)
	end,
	spin = function(t)
		-- A corkscrew: a full twist while flipping backwards.
		return CFrame.Angles(t * math.pi * 2, t * math.pi * 2, 0)
	end,
}
local FLIP_KINDS = { "back", "back", "front", "side", "spin" }

local sprintHeld = false
local sprintToggled = false

local function rootJoint(character)
	local lowerTorso = character:FindFirstChild("LowerTorso")
	local joint = lowerTorso and lowerTorso:FindFirstChild("Root")
	if not joint then
		local root = character:FindFirstChild("HumanoidRootPart")
		joint = root and root:FindFirstChild("RootJoint")
	end
	return joint
end

-- Spin the character around its middle by rotating the root joint's C0.
function Movement.flip(character, kind)
	local joint = character and rootJoint(character)
	local curve = FLIPS[kind]
	if not joint or not curve or character:GetAttribute("Flipping") then
		return
	end
	character:SetAttribute("Flipping", true)
	local original = joint.C0
	local pivot = CFrame.new(0, 1, 0) -- rotate around the torso, not the hips
	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = math.min(1, (os.clock() - started) / FLIP_TIME)
		local eased = 1 - (1 - t) ^ 2
		if not joint.Parent then
			connection:Disconnect()
			return
		end
		joint.C0 = original * pivot * curve(eased) * pivot:Inverse()
		if t >= 1 then
			connection:Disconnect()
			joint.C0 = original
			character:SetAttribute("Flipping", nil)
		end
	end)
end

local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.StateChanged:Connect(function(_, new)
		if new ~= Enum.HumanoidStateType.Jumping or Store.inPitch then
			return
		end
		if math.random() < FLIP_CHANCE then
			local kind = FLIP_KINDS[math.random(1, #FLIP_KINDS)]
			-- Wait until we're actually off the ground.
			task.delay(0.08, function()
				Movement.flip(character, kind)
				Remotes.Flip:FireServer(kind)
			end)
		end
	end)
end

local function buildSprintButton(screen)
	if not UserInputService.TouchEnabled then
		return
	end
	local button = Theme.button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -110, 1, -150),
		Size = UDim2.fromOffset(70, 70),
		BackgroundColor3 = Theme.Colors.panel,
		BackgroundTransparency = 0.25,
		Font = Theme.FontBlack,
		Text = "RUN",
		TextColor3 = Theme.Colors.text,
		Parent = screen,
	}, function()
		sprintToggled = not sprintToggled
	end)
	Theme.corner(35).Parent = button
	local stroke = Theme.stroke(Theme.Colors.gold, 2)
	stroke.Parent = button
	RunService.Heartbeat:Connect(function()
		button.TextColor3 = sprintToggled and Theme.Colors.gold or Theme.Colors.text
	end)
end

function Movement.start(screen)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- Other players' flips.
	Remotes.Flip.OnClientEvent:Connect(function(other, kind)
		if typeof(other) == "Instance" and other:IsA("Player") and other.Character then
			Movement.flip(other.Character, kind)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift and not processed then
			sprintHeld = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprintHeld = false
		end
	end)
	buildSprintButton(screen)

	local fov = 70
	RunService.RenderStepped:Connect(function(dt)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		-- The pitch screen plants your feet and runs its own camera.
		if not humanoid or Store.inPitch then
			return
		end
		local sprinting = (sprintHeld or sprintToggled) and humanoid.MoveDirection.Magnitude > 0.1
		humanoid.WalkSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
		local camera = Workspace.CurrentCamera
		if camera.CameraType == Enum.CameraType.Custom then
			fov += ((sprinting and 80 or 70) - fov) * math.min(1, dt * 6)
			camera.FieldOfView = fov
		end
	end)
end

return Movement
