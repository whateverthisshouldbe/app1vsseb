--!strict
-- De mascotte: een pennetje dat om je heen zweeft en je boost geeft.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

local Pets = {}

local active: { [Player]: Model } = {}

local function build(pet): Model
	local m = Instance.new("Model")
	m.Name = "Pet_" .. pet.key

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(0.5, 3, 0.5)
	body.Color = pet.color
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = m

	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Anchored = true
	tip.CanCollide = false
	tip.Size = Vector3.new(0.5, 0.7, 0.5)
	tip.Shape = Enum.PartType.Ball
	tip.Color = Color3.fromRGB(30, 30, 35)
	tip.Material = Enum.Material.Metal
	tip.Parent = m

	m.PrimaryPart = body

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(4.5, 1.1)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 35
	gui.Adornee = body
	gui.Parent = body

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 12
	tl.TextColor3 = pet.color
	tl.TextStrokeTransparency = 0.4
	tl.Text = pet.name
	tl.Parent = gui

	return m
end

function Pets.equip(player: Player, petKey: string?)
	local existing = active[player]
	if existing then
		existing:Destroy()
		active[player] = nil
	end
	local pet = Config.getPet(petKey)
	if not pet then
		return
	end
	local m = build(pet)
	m.Parent = workspace
	active[player] = m
end

function Pets.start()
	Players.PlayerRemoving:Connect(function(player)
		local m = active[player]
		if m then
			m:Destroy()
		end
		active[player] = nil
	end)

	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for player, model in active do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local body = model.PrimaryPart
			local tip = model:FindFirstChild("Tip")
			if root and root:IsA("BasePart") and body and tip and tip:IsA("BasePart") then
				local angle = t * 1.6
				local offset = Vector3.new(math.cos(angle) * 4, 3.5 + math.sin(t * 2) * 0.4, math.sin(angle) * 4)
				local cf = CFrame.new(root.Position + offset) * CFrame.Angles(0, -angle, math.rad(25))
				body.CFrame = cf
				tip.CFrame = cf * CFrame.new(0, -1.7, 0)
			end
		end
	end)
end

return Pets
