--!strict
-- De klant achter de balie. Elke klant heeft een eigen vraagprijs-multiplier,
-- dus timing is belangrijk: wachten op een goede klant loont.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))
local Net = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Net"))

local Customers = {}

export type Customer = {
	name: string,
	line: string,
	multiplier: number,
	expiresAt: number,
}

local current: Customer? = nil
local model: Model? = nil
local bubbleText: TextLabel? = nil

local function bodyPart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function buildModel(spot: BasePart): Model
	local m = Instance.new("Model")
	m.Name = "Customer"

	local skin = Color3.fromRGB(235, 200, 160)
	local shirt = Color3.fromHSV(math.random(), 0.55, 0.85)
	local pants = Color3.fromRGB(45, 50, 70)
	local base = spot.CFrame * CFrame.new(0, 0, 0)
	local facing = CFrame.new(base.Position, base.Position + Vector3.new(0, 0, 14))

	local torso = bodyPart("Torso", Vector3.new(2, 2, 1), facing * CFrame.new(0, 3, 0), shirt, m)
	bodyPart("Head", Vector3.new(1.4, 1.4, 1.4), facing * CFrame.new(0, 4.6, 0), skin, m)
	bodyPart("ArmL", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(-1.4, 3, 0), skin, m)
	bodyPart("ArmR", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(1.4, 3, 0), skin, m)
	bodyPart("LegL", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(-0.55, 1, 0), pants, m)
	bodyPart("LegR", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(0.55, 1, 0), pants, m)

	m.PrimaryPart = torso

	local gui = Instance.new("BillboardGui")
	gui.Name = "Bubble"
	gui.Size = UDim2.fromScale(12, 3.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	gui.Adornee = torso
	gui.Parent = torso

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	frame.BackgroundTransparency = 0.25
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local tl = Instance.new("TextLabel")
	tl.Name = "Text"
	tl.Size = UDim2.new(1, -12, 1, -8)
	tl.Position = UDim2.new(0, 6, 0, 4)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamMedium
	tl.TextSize = 20
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextWrapped = true
	tl.RichText = true
	tl.Text = ""
	tl.Parent = frame

	bubbleText = tl
	return m
end

local function refreshBubble()
	local c = current
	if not c or not bubbleText then
		return
	end
	local color = c.multiplier >= 1.6 and "rgb(120,255,150)"
		or (c.multiplier >= 1.1 and "rgb(255,220,120)" or "rgb(255,150,150)")
	bubbleText.Text = string.format(
		'<b>%s</b>: "%s"\n<font color="%s">betaalt x%.2f</font>',
		c.name, c.line, color, c.multiplier
	)
end

function Customers.current(): Customer?
	return current
end

local function newCustomer()
	local cfg = Config.Customer
	local mult = cfg.minMultiplier + math.random() * (cfg.maxMultiplier - cfg.minMultiplier)
	current = {
		name = cfg.names[math.random(#cfg.names)],
		line = cfg.lines[math.random(#cfg.lines)],
		multiplier = math.floor(mult * 100 + 0.5) / 100,
		expiresAt = os.clock() + cfg.rotateSeconds,
	}
	if model then
		local torso = model.PrimaryPart
		if torso then
			torso.Color = Color3.fromHSV(math.random(), 0.55, 0.85)
		end
	end
	refreshBubble()
	Net.event("CustomerChanged"):FireAllClients(current)
end

function Customers.start(spot: BasePart)
	model = buildModel(spot)
	model.Parent = spot.Parent
	newCustomer()

	task.spawn(function()
		while true do
			task.wait(Config.Customer.rotateSeconds)
			newCustomer()
		end
	end)
end

-- Na een verkoop gaat de klant tevreden weg en komt er een nieuwe.
function Customers.serve()
	newCustomer()
end

return Customers
