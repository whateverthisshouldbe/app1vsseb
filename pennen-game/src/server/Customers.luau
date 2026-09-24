--!strict
-- De klanten aan de toonbank. Elke klant heeft een type ("heeft haast",
-- "houdt van luxe", ...) waar je pitch bij moet passen.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))
local Net = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Net"))

local Customers = {}

export type Customer = {
	station: string,
	name: string,
	line: string,
	typeKey: string,
	typeLabel: string,
	multiplier: number,
}

local current: { [string]: Customer } = {}
local models: { [string]: Model } = {}
local bubbles: { [string]: TextLabel } = {}

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

local function buildModel(stationKey: string, spot: BasePart): Model
	local m = Instance.new("Model")
	m.Name = "Customer_" .. stationKey

	local skin = Color3.fromRGB(235, 200, 160)
	local suit = Color3.fromRGB(40, 44, 60)
	-- de plek zelf wijst al de goede kant op (naar de speler toe)
	local facing = spot.CFrame

	local torso = bodyPart("Torso", Vector3.new(2, 2, 1), facing * CFrame.new(0, 3, 0), suit, m)
	bodyPart("Head", Vector3.new(1.4, 1.4, 1.4), facing * CFrame.new(0, 4.6, 0), skin, m)
	bodyPart("Tie", Vector3.new(0.35, 1.4, 0.2), facing * CFrame.new(0, 3.1, -0.55), Color3.fromRGB(200, 60, 70), m)
	bodyPart("ArmL", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(-1.4, 3, 0), suit, m)
	bodyPart("ArmR", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(1.4, 3, 0), suit, m)
	bodyPart("LegL", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(-0.55, 1, 0), Color3.fromRGB(30, 32, 44), m)
	bodyPart("LegR", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(0.55, 1, 0), Color3.fromRGB(30, 32, 44), m)

	m.PrimaryPart = torso

	local gui = Instance.new("BillboardGui")
	gui.Name = "Bubble"
	gui.Size = UDim2.fromScale(13, 3.8)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 180
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

	bubbles[stationKey] = tl
	return m
end

local function refreshBubble(stationKey: string)
	local c = current[stationKey]
	local tl = bubbles[stationKey]
	if not c or not tl then
		return
	end
	local t = Config.getCustomerType(c.typeKey)
	local col = t.color
	tl.Text = string.format(
		'<b>%s</b>: "%s"\n<font color="rgb(%d,%d,%d)">%s</font>  ·  x%.2f',
		c.name, c.line,
		math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255),
		t.label, c.multiplier
	)
end

local function roll(stationKey: string)
	local cfg = Config.Customer
	local t = Config.CustomerTypes[math.random(#Config.CustomerTypes)]
	local mult = 0.85 + math.random() * 0.75
	current[stationKey] = {
		station = stationKey,
		name = cfg.names[math.random(#cfg.names)],
		line = cfg.lines[math.random(#cfg.lines)],
		typeKey = t.key,
		typeLabel = t.label,
		multiplier = math.floor(mult * 100 + 0.5) / 100,
	}
	refreshBubble(stationKey)
	Net.event("CustomerChanged"):FireAllClients(current[stationKey])
end

function Customers.get(stationKey: string): Customer?
	return current[stationKey]
end

function Customers.all(): { [string]: Customer }
	return current
end

function Customers.serve(stationKey: string)
	roll(stationKey)
end

function Customers.start(spots: { [string]: BasePart })
	for stationKey, spot in spots do
		local m = buildModel(stationKey, spot)
		m.Parent = spot.Parent
		models[stationKey] = m
		roll(stationKey)
	end

	task.spawn(function()
		while true do
			task.wait(Config.Customer.rotateSeconds)
			for stationKey in current do
				roll(stationKey)
			end
		end
	end)
end

return Customers
