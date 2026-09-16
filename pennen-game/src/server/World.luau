--!strict
-- Bouwt de hele map met code: een straat met een zaak per rebirth, plus het
-- plein met de kiosk, de rebirth-plaat, de pennenbak en de scoreborden.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

local World = {}

World.STATION_SPACING = 140
World.FIRST_STATION_Z = -70

-- per station een eigen vorm, zodat de straat niet één rij dozen wordt
local SHAPES: { [string]: { size: Vector3, material: Enum.Material, roof: boolean } } = {
	kraam      = { size = Vector3.new(22, 8, 12),  material = Enum.Material.WoodPlanks, roof = true },
	winkel     = { size = Vector3.new(30, 14, 16), material = Enum.Material.Brick,      roof = true },
	fabriek    = { size = Vector3.new(44, 18, 24), material = Enum.Material.Metal,      roof = false },
	groothandel= { size = Vector3.new(52, 20, 30), material = Enum.Material.Concrete,   roof = false },
	toren      = { size = Vector3.new(30, 70, 30), material = Enum.Material.Glass,      roof = false },
	penthouse  = { size = Vector3.new(38, 26, 28), material = Enum.Material.Marble,     roof = true },
	jacht      = { size = Vector3.new(58, 14, 20), material = Enum.Material.Plastic,    roof = true },
	orbit      = { size = Vector3.new(40, 16, 40), material = Enum.Material.Neon,       roof = false },
}

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function label(parent: BasePart, name: string, text: string, offsetY: number, size: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromScale(14, 3.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 260
	gui.Parent = parent

	local tl = Instance.new("TextLabel")
	tl.Name = "Text"
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
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
	}, parent)
	label(p, "Label", text, size.Y / 2 + 3, 22)
	return p
end

local function board(name: string, cf: CFrame, title: string, parent: Instance): TextLabel
	local stand = part({
		Name = name,
		Size = Vector3.new(24, 20, 1.5),
		CFrame = cf,
		Color = Color3.fromRGB(26, 28, 38),
	}, parent)

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Screen"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(480, 400)
	surface.LightInfluence = 0
	surface.Parent = stand

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 34
	header.TextColor3 = Color3.fromRGB(255, 220, 120)
	header.Text = title
	header.Parent = surface

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -24, 1, -64)
	body.Position = UDim2.new(0, 12, 0, 58)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 24
	body.TextColor3 = Color3.new(1, 1, 1)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.RichText = true
	body.Text = "laden..."
	body.Parent = surface

	return body
end

local function buildStation(root: Folder, index: number, station)
	local z = World.FIRST_STATION_Z - (index - 1) * World.STATION_SPACING
	local shape = SHAPES[station.key] or { size = Vector3.new(30, 14, 16), material = Enum.Material.Concrete, roof = false }

	local folder = Instance.new("Folder")
	folder.Name = "Station_" .. station.key
	folder.Parent = root

	-- grondvlak
	part({
		Name = "Plot",
		Size = Vector3.new(110, 1, 110),
		CFrame = CFrame.new(0, 0.5, z),
		Color = station.color:Lerp(Color3.new(0, 0, 0), 0.6),
		Material = Enum.Material.Concrete,
	}, folder)

	-- gebouw
	local building = part({
		Name = "Building",
		Size = shape.size,
		CFrame = CFrame.new(0, 1 + shape.size.Y / 2, z - 34),
		Color = station.color,
		Material = shape.material,
		Transparency = station.key == "toren" and 0.25 or 0,
	}, folder)

	if shape.roof then
		part({
			Name = "Roof",
			Size = Vector3.new(shape.size.X + 6, 1, shape.size.Z + 6),
			CFrame = CFrame.new(0, 1 + shape.size.Y + 0.5, z - 34),
			Color = Color3.fromRGB(220, 80, 80),
		}, folder)
	end

	local unlockText = station.unlockRebirth == 0 and "vanaf het begin"
		or string.format('<font color="rgb(200,120,255)">rebirth %d nodig</font>', station.unlockRebirth)
	label(building, "Sign", string.format("<b>%s</b>\n%s\n%s", station.name, station.tagline, unlockText),
		shape.size.Y / 2 + 5, 26)

	-- werkplek: pennen maken
	pad("Press_" .. station.key, CFrame.new(-26, 1.35, z - 6), Vector3.new(18, 0.7, 16),
		Color3.fromRGB(90, 190, 255), "Pennen maken", folder)

	-- toonbank: verkopen
	local desk = part({
		Name = "Desk_" .. station.key,
		Size = Vector3.new(22, 5, 6),
		CFrame = CFrame.new(28, 3.5, z - 16),
		Color = Color3.fromRGB(120, 86, 56),
		Material = Enum.Material.Wood,
	}, folder)
	label(desk, "Label", "<b>TOONBANK</b>", 4.5, 24)

	pad("Sell_" .. station.key, CFrame.new(28, 1.35, z - 6), Vector3.new(22, 0.7, 14),
		Color3.fromRGB(120, 255, 150), "Verkopen", folder)

	part({
		Name = "Spot_" .. station.key,
		Size = Vector3.new(4, 0.4, 4),
		CFrame = CFrame.new(28, 1.2, z - 22),
		Transparency = 1,
		CanCollide = false,
	}, folder)
end

function World.build(): Folder
	local existing = Workspace:FindFirstChild("PenWorld")
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "PenWorld"
	root.Parent = Workspace

	Lighting.Ambient = Color3.fromRGB(105, 105, 118)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 152)
	Lighting.Brightness = 2.6

	local streetLength = #Config.Stations * World.STATION_SPACING + 260

	part({
		Name = "Ground",
		Size = Vector3.new(400, 2, streetLength),
		CFrame = CFrame.new(0, -1, World.FIRST_STATION_Z - (#Config.Stations - 1) * World.STATION_SPACING / 2),
		Color = Color3.fromRGB(52, 56, 66),
		Material = Enum.Material.Concrete,
	}, root)

	part({
		Name = "Street",
		Size = Vector3.new(24, 0.3, streetLength),
		CFrame = CFrame.new(0, 0.2, World.FIRST_STATION_Z - (#Config.Stations - 1) * World.STATION_SPACING / 2),
		Color = Color3.fromRGB(38, 40, 50),
		Material = Enum.Material.Asphalt,
	}, root)

	-- ------------------------------------------------------------- plein ---
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = root

	part({
		Name = "PlazaFloor",
		Size = Vector3.new(160, 1, 120),
		CFrame = CFrame.new(0, 0.5, 40),
		Color = Color3.fromRGB(70, 76, 92),
	}, plaza)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PenSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 1.5, 30)
	spawn.Color = Color3.fromRGB(80, 200, 140)
	spawn.Duration = 0
	spawn.Parent = plaza

	-- upgrade-kiosk
	local spacing = 20
	local startX = -((#Config.Upgrades - 1) * spacing) / 2
	for i, up in Config.Upgrades do
		local x = startX + (i - 1) * spacing
		local stand = part({
			Name = "KioskBody_" .. up.key,
			Size = Vector3.new(9, 6, 4),
			CFrame = CFrame.new(x, 4, 78),
			Color = Color3.fromRGB(46, 52, 66),
		}, plaza)
		label(stand, "Label", string.format("<b>%s</b>\n%s", up.name, up.info), 5, 20)
		pad("UpgradePad_" .. up.key, CFrame.new(x, 1.35, 68), Vector3.new(12, 0.7, 10),
			Color3.fromRGB(255, 200, 90), up.name, plaza)
	end

	-- rebirth
	local rebirthBody = part({
		Name = "RebirthBody",
		Size = Vector3.new(12, 16, 12),
		CFrame = CFrame.new(-52, 9, 40),
		Color = Color3.fromRGB(120, 60, 180),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
	}, plaza)
	label(rebirthBody, "Label", "<b>REBIRTH</b>\nopent je volgende zaak", 10, 26)
	pad("RebirthPad", CFrame.new(-52, 1.35, 28), Vector3.new(14, 0.7, 12),
		Color3.fromRGB(200, 120, 255), "2 sec blijven staan", plaza)

	-- pennenbak (huisdieren)
	local petBody = part({
		Name = "PetBody",
		Size = Vector3.new(12, 10, 8),
		CFrame = CFrame.new(52, 6, 40),
		Color = Color3.fromRGB(60, 120, 110),
		Material = Enum.Material.Metal,
	}, plaza)
	label(petBody, "Label", "<b>PENNENBAK</b>\nmascottes kopen", 7, 26)
	pad("PetPad", CFrame.new(52, 1.35, 28), Vector3.new(14, 0.7, 12),
		Color3.fromRGB(120, 230, 220), "Mascottes", plaza)

	-- scoreborden
	board("Board_cash", CFrame.new(-40, 12, 92) * CFrame.Angles(0, math.pi, 0), "RIJKSTE VERKOPERS", plaza)
	board("Board_rebirths", CFrame.new(40, 12, 92) * CFrame.Angles(0, math.pi, 0), "MEESTE REBIRTHS", plaza)

	-- ---------------------------------------------------------- stations ---
	for i, station in Config.Stations do
		buildStation(root, i, station)
	end

	return root
end

function World.find(root: Instance, name: string): BasePart?
	local p = root:FindFirstChild(name, true)
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

function World.boardBody(root: Instance, name: string): TextLabel?
	local stand = root:FindFirstChild(name, true)
	if not stand then
		return nil
	end
	local screen = stand:FindFirstChild("Screen")
	local body = screen and screen:FindFirstChild("Body")
	if body and body:IsA("TextLabel") then
		return body
	end
	return nil
end

return World
