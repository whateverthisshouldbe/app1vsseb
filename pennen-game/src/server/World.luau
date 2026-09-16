--!strict
-- Bouwt de hele map met code, zodat je niets met de hand hoeft te bouwen.
-- Wil je later een eigen map? Zet World.ENABLED op false en geef je eigen
-- onderdelen dezelfde namen (PenPress, SellDesk, UpgradePad_<key>, RebirthPad).

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

local World = {}

World.ENABLED = true

local FLOOR_Y = 0

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function label(parent: BasePart, text: string, offsetY: number, size: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(10, 2.6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 140
	gui.Parent = parent

	local tl = Instance.new("TextLabel")
	tl.Name = "Text"
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = false
	tl.TextSize = size
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.35
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.RichText = true
	tl.Text = text
	tl.Parent = gui
	return tl
end

local function pad(name: string, cf: CFrame, size: Vector3, color: Color3, text: string, parent: Instance): Part
	local p = part({
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
	})
	p.Parent = parent
	label(p, text, size.Y / 2 + 3, 22)
	return p
end

function World.build(): Folder
	local existing = Workspace:FindFirstChild("PenWorld")
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "PenWorld"
	root.Parent = Workspace

	Lighting.Ambient = Color3.fromRGB(110, 110, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	Lighting.Brightness = 2.4

	-- vloer
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(220, 2, 220),
		CFrame = CFrame.new(0, FLOOR_Y - 1, 0),
		Color = Color3.fromRGB(58, 62, 74),
		Material = Enum.Material.Concrete,
	})
	floor.Parent = root

	local carpet = part({
		Name = "Carpet",
		Size = Vector3.new(90, 0.2, 120),
		CFrame = CFrame.new(0, FLOOR_Y + 0.1, 0),
		Color = Color3.fromRGB(38, 92, 120),
		Material = Enum.Material.Fabric,
	})
	carpet.Parent = root

	-- spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PenSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, FLOOR_Y + 0.5, 0)
	spawn.Color = Color3.fromRGB(80, 200, 140)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Parent = root

	-- pennenpers
	local press = part({
		Name = "PressBody",
		Size = Vector3.new(14, 10, 10),
		CFrame = CFrame.new(-34, FLOOR_Y + 5, -26),
		Color = Color3.fromRGB(70, 78, 96),
		Material = Enum.Material.Metal,
	})
	press.Parent = root
	label(press, "<b>PENNENPERS</b>\nga op de plaat staan", 7, 26)

	pad("PenPress", CFrame.new(-34, FLOOR_Y + 0.35, -14), Vector3.new(16, 0.7, 12),
		Color3.fromRGB(90, 190, 255), "Pennen maken", root)

	-- verkoopbalie
	local desk = part({
		Name = "DeskBody",
		Size = Vector3.new(20, 5, 6),
		CFrame = CFrame.new(34, FLOOR_Y + 2.5, -26),
		Color = Color3.fromRGB(120, 86, 56),
		Material = Enum.Material.Wood,
	})
	desk.Parent = root
	label(desk, "<b>VERKOOPBALIE</b>", 4.5, 26)

	pad("SellDesk", CFrame.new(34, FLOOR_Y + 0.35, -17), Vector3.new(20, 0.7, 12),
		Color3.fromRGB(120, 255, 150), "Verkopen", root)

	-- plek waar de klant staat (achter de balie)
	local customerSpot = part({
		Name = "CustomerSpot",
		Size = Vector3.new(4, 0.4, 4),
		CFrame = CFrame.new(34, FLOOR_Y + 0.2, -31),
		Color = Color3.fromRGB(200, 200, 210),
		Transparency = 1,
		CanCollide = false,
	})
	customerSpot.Parent = root

	-- upgrade-kiosk
	local kioskZ = 22
	local spacing = 18
	local startX = -((#Config.Upgrades - 1) * spacing) / 2
	for i, up in Config.Upgrades do
		local x = startX + (i - 1) * spacing
		local stand = part({
			Name = "KioskBody_" .. up.key,
			Size = Vector3.new(8, 6, 4),
			CFrame = CFrame.new(x, FLOOR_Y + 3, kioskZ + 8),
			Color = Color3.fromRGB(46, 52, 66),
		})
		stand.Parent = root
		label(stand, string.format("<b>%s</b>\n%s", up.name, up.info), 5, 20)

		pad("UpgradePad_" .. up.key, CFrame.new(x, FLOOR_Y + 0.35, kioskZ), Vector3.new(10, 0.7, 10),
			Color3.fromRGB(255, 200, 90), up.name, root)
	end

	-- rebirth
	local rebirthBody = part({
		Name = "RebirthBody",
		Size = Vector3.new(10, 12, 10),
		CFrame = CFrame.new(0, FLOOR_Y + 6, -48),
		Color = Color3.fromRGB(120, 60, 180),
		Material = Enum.Material.Neon,
		Transparency = 0.4,
	})
	rebirthBody.Parent = root
	label(rebirthBody, "<b>REBIRTH</b>\nnieuwe pen + hogere prijzen", 8, 24)

	pad("RebirthPad", CFrame.new(0, FLOOR_Y + 0.35, -38), Vector3.new(12, 0.7, 10),
		Color3.fromRGB(200, 120, 255), "Rebirth", root)

	return root
end

function World.findPad(root: Instance, name: string): BasePart?
	local p = root:FindFirstChild(name, true)
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

return World
