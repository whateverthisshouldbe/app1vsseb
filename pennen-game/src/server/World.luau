--!strict
-- Bouwt Pen Street: een plein met fontein, een straat met stoepen, lantaarns
-- en bomen, en per rebirth een eigen zaak langs die straat. Alles met code.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))
local Scenery = require(script.Parent.Scenery)

local World = {}

local P = Scenery.Palette
local part = Scenery.part
local decor = Scenery.decor

World.BLOCK_SPACING = 120
World.FIRST_BLOCK_Z = -80

local ROAD_HALF = 15
local WALK_OUTER = 32
local PLOT_X = 70 -- midden van het terrein aan de rechterkant

local function wall(x: number, y: number, z: number, yawDeg: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yawDeg), 0)
end

local function blockZ(index: number): number
	return World.FIRST_BLOCK_Z - (index - 1) * World.BLOCK_SPACING
end

-- ------------------------------------------------------------------ licht --

local function setupLighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.ClockTime = 16.2
	Lighting.GeographicLatitude = 24
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(88, 90, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(132, 134, 144)
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.45
	Lighting.ExposureCompensation = 0.15
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 1400

	for _, old in Lighting:GetChildren() do
		if old:IsA("Atmosphere") or old:IsA("BloomEffect") or old:IsA("ColorCorrectionEffect")
			or old:IsA("SunRaysEffect") or old:IsA("Sky") then
			old:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.Name = "PenSky"
	sky.SunAngularSize = 14
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(202, 199, 194)
	atmosphere.Decay = Color3.fromRGB(106, 112, 125)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.7
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.05
	bloom.Parent = Lighting

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.14
	grade.Contrast = 0.09
	grade.TintColor = Color3.fromRGB(255, 249, 240)
	grade.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Spread = 0.9
	rays.Parent = Lighting
end

-- ----------------------------------------------------------- straat/stoep --

local function buildStreet(root: Folder, totalLength: number, centerZ: number)
	decor({
		Name = "Ground",
		Size = Vector3.new(660, 2, totalLength + 260),
		CFrame = CFrame.new(35, -1, centerZ),
		Color = Color3.fromRGB(96, 100, 108),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	}, root)

	-- groenstroken langs de stoepen, zodat het niet één grijze vlakte is
	for _, side in { -1, 1 } do
		decor({
			Name = "Verge",
			Size = Vector3.new(7, 1.3, totalLength + 260),
			CFrame = CFrame.new(side * (WALK_OUTER + 3.5), 0.65, centerZ),
			Color = P.grass,
			Material = Enum.Material.Grass,
			CanCollide = true,
		}, root)
	end

	decor({
		Name = "Road",
		Size = Vector3.new(ROAD_HALF * 2, 0.6, totalLength + 300),
		CFrame = CFrame.new(0, 0.3, centerZ),
		Color = P.asphalt,
		Material = Enum.Material.Asphalt,
		CanCollide = true,
	}, root)

	for _, side in { -1, 1 } do
		decor({
			Name = "Sidewalk",
			Size = Vector3.new(WALK_OUTER - ROAD_HALF, 1.2, totalLength + 300),
			CFrame = CFrame.new(side * (ROAD_HALF + (WALK_OUTER - ROAD_HALF) / 2), 0.6, centerZ),
			Color = P.sidewalk,
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, root)
		decor({
			Name = "Curb",
			Size = Vector3.new(1.4, 1.6, totalLength + 300),
			CFrame = CFrame.new(side * ROAD_HALF, 0.8, centerZ),
			Color = P.curb,
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, root)
	end

	-- middenstreep
	local stripes = math.floor((totalLength + 300) / 24)
	for i = 0, stripes do
		decor({
			Name = "Line",
			Size = Vector3.new(1.2, 0.2, 10),
			CFrame = CFrame.new(0, 0.7, centerZ + (totalLength + 300) / 2 - i * 24),
			Color = P.asphaltLine,
			Material = Enum.Material.Concrete,
		}, root)
	end
end

local function streetFurniture(root: Folder, fromZ: number, toZ: number)
	local z = fromZ
	local flip = false
	while z > toZ do
		for _, side in { -1, 1 } do
			Scenery.lamppost(wall(side * (WALK_OUTER - 5), 1.2, z, side > 0 and 180 or 0), root)
		end
		if flip then
			Scenery.tree(CFrame.new(-(WALK_OUTER - 18), 1.2, z - 22), 1.1, root)
			Scenery.bench(CFrame.new(WALK_OUTER - 20, 1.2, z - 30), root)
		else
			Scenery.tree(CFrame.new(WALK_OUTER - 18, 1.2, z - 24), 1, root)
			Scenery.trashcan(CFrame.new(-(WALK_OUTER - 19), 1.2, z - 12), root)
		end
		flip = not flip
		z -= 46
	end
end

-- Aan de overkant van de straat: gevels waar je niet in kunt, voor de sfeer.
local function facadeRow(root: Folder, fromZ: number, toZ: number)
	local palette = { P.brick, P.plaster, P.plasterWarm, P.teal, Color3.fromRGB(118, 128, 150) }
	local z = fromZ
	local i = 0
	while z > toZ do
		i += 1
		local depth = 34
		local width = 36 + math.random(0, 14)
		local height = 28 + math.random(0, 46)
		local color = palette[(i % #palette) + 1]
		local body = decor({
			Name = "Facade",
			Size = Vector3.new(depth, height, width),
			CFrame = CFrame.new(-(WALK_OUTER + depth / 2), height / 2, z - width / 2),
			Color = color,
			Material = Enum.Material.Brick,
			CanCollide = true,
		}, root)
		Scenery.windows(
			body.CFrame * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 2, depth / 2),
			width * 0.8, height * 0.7,
			math.max(2, math.floor(width / 11)), math.max(2, math.floor(height / 12)),
			0.4, root
		)
		-- winkelpui op de begane grond
		Scenery.storefront(wall(-(WALK_OUTER + 0.4), 1.2, z - width / 2, 90), width * 0.6, 11, root)
		Scenery.awning(wall(-(WALK_OUTER + 1), 13.5, z - width / 2, 90), width * 0.62, 6,
			palette[((i + 2) % #palette) + 1], P.awningB, root)
		z -= width + 6
	end
end

-- ------------------------------------------------------------------ plein --

local function buildPlaza(root: Folder): Folder
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = root

	decor({
		Name = "PlazaFloor",
		Size = Vector3.new(150, 1.4, 120),
		CFrame = CFrame.new(0, 0.7, 66),
		Color = P.sidewalk,
		Material = Enum.Material.Pebble,
		CanCollide = true,
	}, plaza)

	-- geblokte bestrating: vier tinten door elkaar, scheelt een dode vlakte
	local tile = 15
	for gx = -4, 4 do
		for gz = 0, 7 do
			local shade = ((gx + gz) % 2 == 0) and 0.06 or 0.16
			decor({
				Name = "Tile",
				Size = Vector3.new(tile - 1, 0.2, tile - 1),
				CFrame = CFrame.new(gx * tile, 1.45, 18 + gz * tile),
				Color = P.sidewalk:Lerp(P.plasterWarm, shade),
				Material = Enum.Material.Pebble,
			}, plaza)
		end
	end

	decor({
		Name = "PlazaInlay",
		Size = Vector3.new(46, 0.25, 46),
		CFrame = CFrame.new(0, 1.5, 62),
		Color = P.plasterWarm,
		Material = Enum.Material.Marble,
	}, plaza)

	Scenery.fountain(CFrame.new(0, 1.5, 62), plaza)

	-- welkomstboog over de straat
	for _, x in { -20, 20 } do
		decor({
			Name = "ArchLeg",
			Size = Vector3.new(4, 26, 4),
			CFrame = CFrame.new(x, 13, 8),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, plaza)
	end
	decor({
		Name = "ArchTop",
		Size = Vector3.new(48, 4, 4),
		CFrame = CFrame.new(0, 27, 8),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, plaza)
	Scenery.wallText(wall(0, 31, 8, 180), 42, 8, "PEN STREET", P.neonPink, plaza)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PenSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 1.9, 26)
	spawn.Color = Color3.fromRGB(120, 200, 150)
	spawn.Material = Enum.Material.Marble
	spawn.Duration = 0
	spawn.Parent = plaza

	-- groen en zitjes
	for _, spot in { Vector3.new(-34, 1.5, 34), Vector3.new(34, 1.5, 34),
		Vector3.new(-34, 1.5, 92), Vector3.new(34, 1.5, 92) } do
		Scenery.tree(CFrame.new(spot), 1.25, plaza)
	end
	Scenery.bench(CFrame.new(-22, 1.5, 44), plaza)
	Scenery.bench(CFrame.new(22, 1.5, 44), plaza)
	Scenery.bench(CFrame.new(-22, 1.5, 82), plaza)
	Scenery.bench(CFrame.new(22, 1.5, 82), plaza)
	Scenery.planter(CFrame.new(-30, 1.5, 62), plaza)
	Scenery.planter(CFrame.new(30, 1.5, 62), plaza)
	Scenery.trashcan(CFrame.new(-14, 1.5, 30), plaza)
	Scenery.trashcan(CFrame.new(14, 1.5, 100), plaza)
	for _, x in { -64, 64 } do
		for _, z in { 30, 62, 94 } do
			Scenery.lamppost(wall(x, 1.5, z, x > 0 and 180 or 0), plaza)
		end
	end

	-- bankjes rond de fontein, kijkend naar het water
	for _, spot in { { 0, 44, 0 }, { 0, 80, 180 }, { -22, 62, -90 }, { 22, 62, 90 } } do
		Scenery.bench(wall(spot[1], 1.5, spot[2], spot[3]), plaza)
	end

	-- klokzuil als herkenningspunt bij de ingang
	local clock = decor({
		Name = "ClockPillar",
		Size = Vector3.new(5, 30, 5),
		CFrame = CFrame.new(-30, 16, 20),
		Color = P.plaster,
		Material = Enum.Material.Marble,
		CanCollide = true,
	}, plaza)
	decor({
		Name = "ClockFace",
		Size = Vector3.new(7, 7, 1),
		CFrame = CFrame.new(-30, 28, 17.4),
		Color = P.windowLit,
		Material = Enum.Material.Neon,
	}, plaza)
	decor({
		Name = "ClockTop",
		Size = Vector3.new(7, 2, 7),
		CFrame = CFrame.new(-30, 32, 20),
		Color = P.metalDark,
	}, plaza)
	clock.Name = "ClockPillar"

	-- pennenkarretje
	decor({
		Name = "CartBody",
		Size = Vector3.new(12, 6, 7),
		CFrame = CFrame.new(28, 4.5, 26),
		Color = P.neonPink,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, plaza)
	Scenery.awning(wall(28, 11.5, 22.6, 180), 12, 5, P.awningB, P.neonPink, plaza)
	for _, dx in { -4, 4 } do
		Scenery.cylinder({
			Name = "CartWheel",
			Size = Vector3.new(1.2, 4, 4),
			CFrame = CFrame.new(28 + dx, 2, 29) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.woodDark,
		}, plaza)
	end

	-- fietsenrek
	for i = 0, 3 do
		decor({
			Name = "BikeRack",
			Size = Vector3.new(0.6, 3, 5),
			CFrame = CFrame.new(-46, 3, 116 + i * 4),
			Color = P.metal,
			Material = Enum.Material.Metal,
		}, plaza)
	end

	return plaza
end

local function buildKiosks(plaza: Folder)
	-- marktkraampjes voor de upgrades, netjes op een rij langs het plein
	local startZ = 26
	local spacing = 22
	for i, up in Config.Upgrades do
		local z = startZ + (i - 1) * spacing
		local x = -56

		decor({
			Name = "KioskCounter_" .. up.key,
			Size = Vector3.new(10, 5, 16),
			CFrame = CFrame.new(x, 3.9, z),
			Color = P.wood,
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, plaza)
		for _, dz in { -7, 7 } do
			decor({
				Name = "KioskPost",
				Size = Vector3.new(0.8, 12, 0.8),
				CFrame = CFrame.new(x - 3, 7.4, z + dz),
				Color = P.woodDark,
				Material = Enum.Material.Wood,
			}, plaza)
		end
		Scenery.awning(wall(x - 3, 13.4, z, 90), 16, 7, P.awningA, P.awningB, plaza)
		Scenery.wallText(wall(x + 5.3, 9, z, 90), 14, 4, up.name, P.gold, plaza)
		Scenery.crate(CFrame.new(x - 4, 1.4, z + 10), 3.5, plaza)

		local pad = part({
			Name = "UpgradePad_" .. up.key,
			Size = Vector3.new(12, 0.6, 14),
			CFrame = CFrame.new(x + 11, 1.7, z),
			Color = P.gold,
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			CanCollide = false,
		}, plaza)
		Scenery.floatingText(pad, string.format("<b>%s</b>\n%s", up.name, up.info), 5, 20, 120)
	end
end

local function buildRebirthPortal(plaza: Folder)
	local z = 112
	for _, x in { -13, 13 } do
		decor({
			Name = "PortalLeg",
			Size = Vector3.new(5, 30, 5),
			CFrame = CFrame.new(x, 16, z),
			Color = Color3.fromRGB(64, 40, 92),
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, plaza)
	end
	decor({
		Name = "PortalTop",
		Size = Vector3.new(31, 5, 5),
		CFrame = CFrame.new(0, 33, z),
		Color = Color3.fromRGB(64, 40, 92),
		Material = Enum.Material.Marble,
	}, plaza)
	local veil = decor({
		Name = "PortalVeil",
		Size = Vector3.new(21, 28, 1),
		CFrame = CFrame.new(0, 16, z),
		Color = Color3.fromRGB(184, 108, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
	}, plaza)
	Scenery.sparkle(veil, Color3.fromRGB(214, 160, 255))
	Scenery.wallText(wall(0, 37, z, 180), 30, 7, "REBIRTH", Color3.fromRGB(214, 160, 255), plaza)

	local pad = part({
		Name = "RebirthPad",
		Size = Vector3.new(16, 0.6, 12),
		CFrame = CFrame.new(0, 1.7, z - 12),
		Color = Color3.fromRGB(200, 120, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	}, plaza)
	Scenery.floatingText(pad, "<b>REBIRTH</b>\n2 seconden blijven staan", 5, 22, 140)
end

local function buildPetStand(plaza: Folder)
	local x, z = 56, 40
	decor({
		Name = "PetStand",
		Size = Vector3.new(12, 7, 18),
		CFrame = CFrame.new(x, 4.9, z),
		Color = P.teal,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, plaza)
	decor({
		Name = "PetTank",
		Size = Vector3.new(10, 8, 16),
		CFrame = CFrame.new(x, 12.4, z),
		Color = P.glass,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Reflectance = 0.25,
	}, plaza)
	for i = 1, 4 do
		Scenery.cylinder({
			Name = "TankPen",
			Size = Vector3.new(5, 1, 1),
			CFrame = CFrame.new(x - 3 + i * 1.6, 11 + (i % 2) * 2.5, z - 4 + i * 2)
				* CFrame.Angles(0, 0, math.rad(70 + i * 8)),
			Color = i % 2 == 0 and P.neonCyan or P.neonPink,
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, plaza)
	end
	Scenery.wallText(wall(x - 6.3, 20, z, -90), 16, 5, "PENNENBAK", P.neonCyan, plaza)

	local pad = part({
		Name = "PetPad",
		Size = Vector3.new(12, 0.6, 14),
		CFrame = CFrame.new(x - 12, 1.7, z),
		Color = P.neonCyan,
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	}, plaza)
	Scenery.floatingText(pad, "<b>MASCOTTES</b>", 5, 20, 120)
end

local function buildBoard(plaza: Folder, name: string, cf: CFrame, title: string)
	for _, dx in { -11, 11 } do
		decor({
			Name = "BoardLeg",
			Size = Vector3.new(2, 14, 2),
			CFrame = cf * CFrame.new(dx, -17, 0),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, plaza)
	end
	local stand = decor({
		Name = name,
		Size = Vector3.new(26, 20, 1.6),
		CFrame = cf,
		Color = Color3.fromRGB(22, 24, 32),
		Material = Enum.Material.SmoothPlastic,
	}, plaza)
	decor({
		Name = "BoardEdge",
		Size = Vector3.new(27.5, 21.5, 1),
		CFrame = cf * CFrame.new(0, 0, -0.4),
		Color = P.gold,
		Material = Enum.Material.Neon,
	}, plaza)

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Screen"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(520, 400)
	surface.LightInfluence = 0
	surface.Parent = stand

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 36
	header.TextColor3 = P.gold
	header.Text = title
	header.Parent = surface

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -28, 1, -66)
	body.Position = UDim2.new(0, 14, 0, 60)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 24
	body.TextColor3 = Color3.new(1, 1, 1)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.RichText = true
	body.Text = "laden..."
	body.Parent = surface
end

-- --------------------------------------------------------------- stations --

local function stationShell(root: Folder, station, index: number): (Folder, number)
	local folder = Instance.new("Folder")
	folder.Name = "Station_" .. station.key
	folder.Parent = root

	local zc = blockZ(index)

	-- voorterrein met bestrating in blokken
	decor({
		Name = "Plot",
		Size = Vector3.new(92, 1.4, 112),
		CFrame = CFrame.new(PLOT_X + 8, 0.7, zc),
		Color = P.curb,
		Material = Enum.Material.Concrete,
		CanCollide = true,
	}, folder)
	for gx = 0, 5 do
		for gz = 0, 6 do
			local shade = ((gx + gz) % 2 == 0) and 0.1 or 0.26
			decor({
				Name = "PlotTile",
				Size = Vector3.new(14, 0.2, 15),
				CFrame = CFrame.new(34 + gx * 15, 1.45, zc - 48 + gz * 16),
				Color = P.sidewalk:Lerp(P.plasterWarm, shade),
				Material = Enum.Material.Pebble,
			}, folder)
		end
	end

	-- oprit naar de stoep
	decor({
		Name = "Apron",
		Size = Vector3.new(14, 1.4, 34),
		CFrame = CFrame.new(WALK_OUTER + 5, 0.7, zc),
		Color = P.sidewalk,
		Material = Enum.Material.Concrete,
		CanCollide = true,
	}, folder)

	-- hek langs de randen, met een opening naar de straat toe
	for _, dz in { -56, 56 } do
		Scenery.hedge(CFrame.new(PLOT_X + 8, 1.4, zc + dz), 90, folder)
	end
	for _, dz in { -40, 40 } do
		Scenery.hedge(wall(26, 1.4, zc + dz, 90), 28, folder)
	end

	-- toegangspoortje vanaf de stoep
	for _, dz in { -13, 13 } do
		decor({
			Name = "GatePost",
			Size = Vector3.new(3, 12, 3),
			CFrame = CFrame.new(28, 7, zc + dz),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
	end
	decor({
		Name = "GateBeam",
		Size = Vector3.new(3, 2, 29),
		CFrame = CFrame.new(28, 14, zc),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, folder)

	-- wat groen en een bankje op het terrein
	Scenery.planter(CFrame.new(38, 1.4, zc + 44), folder)
	Scenery.planter(CFrame.new(38, 1.4, zc - 44), folder)
	Scenery.bench(wall(36, 1.4, zc, 90), folder)
	Scenery.lamppost(wall(34, 1.4, zc + 30, -90), folder)
	Scenery.lamppost(wall(34, 1.4, zc - 30, -90), folder)

	return folder, zc
end

local function stationProps(folder: Folder, station, zc: number, unlockColor: Color3)
	-- werkbank met de pers
	local bench = decor({
		Name = "WorkBench",
		Size = Vector3.new(16, 5, 10),
		CFrame = CFrame.new(52, 3.9, zc + 22),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	decor({
		Name = "PressArm",
		Size = Vector3.new(4, 9, 4),
		CFrame = CFrame.new(56, 10.9, zc + 22),
		Color = P.metal,
		Material = Enum.Material.Metal,
	}, folder)
	decor({
		Name = "PressHead",
		Size = Vector3.new(7, 2.4, 7),
		CFrame = CFrame.new(54, 7.5, zc + 22),
		Color = station.color,
		Material = Enum.Material.Metal,
	}, folder)
	Scenery.floatingText(bench, "<b>PENNEN MAKEN</b>", 6, 22, 150)

	local pressPad = part({
		Name = "Press_" .. station.key,
		Size = Vector3.new(16, 0.6, 14),
		CFrame = CFrame.new(40, 2, zc + 22),
		Color = Color3.fromRGB(90, 190, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	}, folder)
	Scenery.floatingText(pressPad, "ga hierop staan", 4, 18, 110)

	Scenery.crate(CFrame.new(64, 1.4, zc + 32), 5, folder)
	Scenery.crate(CFrame.new(64, 1.4, zc + 38), 4, folder)
	Scenery.crate(CFrame.new(69, 1.4, zc + 33), 4, folder)

	-- toonbank
	local counter = decor({
		Name = "Counter",
		Size = Vector3.new(6, 5, 20),
		CFrame = CFrame.new(54, 3.9, zc - 22),
		Color = P.wood,
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	decor({
		Name = "CounterTop",
		Size = Vector3.new(8, 0.6, 22),
		CFrame = CFrame.new(54, 6.5, zc - 22),
		Color = P.woodDark,
		Material = Enum.Material.Wood,
	}, folder)
	Scenery.floatingText(counter, "<b>TOONBANK</b>", 6, 22, 150)

	local sellPad = part({
		Name = "Sell_" .. station.key,
		Size = Vector3.new(14, 0.6, 20),
		CFrame = CFrame.new(42, 2, zc - 22),
		Color = Color3.fromRGB(120, 255, 150),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	}, folder)
	Scenery.floatingText(sellPad, "verkopen", 4, 18, 110)

	-- uitstalrek met pennen naast de toonbank
	decor({
		Name = "DisplayRack",
		Size = Vector3.new(4, 9, 12),
		CFrame = CFrame.new(58, 5.9, zc - 36),
		Color = P.woodDark,
		Material = Enum.Material.Wood,
		CanCollide = true,
	}, folder)
	for i = 1, 6 do
		Scenery.cylinder({
			Name = "RackPen",
			Size = Vector3.new(6, 0.9, 0.9),
			CFrame = CFrame.new(56, 7 + (i % 2) * 3, zc - 41 + i * 1.6) * CFrame.Angles(0, 0, math.rad(80)),
			Color = i % 3 == 0 and P.neonPink or (i % 3 == 1 and P.gold or P.neonCyan),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
	end

	-- parasol boven de wachtplek
	decor({
		Name = "UmbrellaPole",
		Size = Vector3.new(0.7, 14, 0.7),
		CFrame = CFrame.new(40, 8, zc + 2),
		Color = P.woodDark,
	}, folder)
	Scenery.cylinder({
		Name = "UmbrellaTop",
		Size = Vector3.new(1, 18, 18),
		CFrame = CFrame.new(40, 15, zc + 2) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.awningA,
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, folder)

	-- de klant staat achter de toonbank en kijkt naar de speler toe (-X)
	part({
		Name = "Spot_" .. station.key,
		Size = Vector3.new(4, 0.4, 4),
		CFrame = wall(62, 1.6, zc - 22, -90),
		Transparency = 1,
		CanCollide = false,
	}, folder)

	-- bord bij de stoep met de naam van de zaak
	local sign = decor({
		Name = "PlotSign",
		Size = Vector3.new(1.6, 16, 1.6),
		CFrame = CFrame.new(34, 9, zc + 44),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, folder)
	local unlockText = station.unlockRebirth == 0 and "open"
		or string.format("rebirth %d", station.unlockRebirth)
	Scenery.wallText(wall(34, 20, zc + 44, -90), 20, 9,
		string.format("%s\n<font size=\"28\">%s</font>", station.name, unlockText), unlockColor, folder)
	sign.Name = "PlotSign"
end

-- ------------------------------------------------------ gebouw per zaak ----

local function buildKraam(folder: Folder, zc: number)
	-- houten marktkraam met luifel
	decor({
		Name = "StallFloor",
		Size = Vector3.new(30, 0.6, 40),
		CFrame = CFrame.new(84, 1.7, zc),
		Color = P.woodDark,
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	for _, offset in { Vector3.new(-13, 0, -18), Vector3.new(-13, 0, 18), Vector3.new(13, 0, -18), Vector3.new(13, 0, 18) } do
		decor({
			Name = "StallPost",
			Size = Vector3.new(1.4, 16, 1.4),
			CFrame = CFrame.new(84 + offset.X, 10, zc + offset.Z),
			Color = P.wood,
			Material = Enum.Material.Wood,
		}, folder)
	end
	-- achterwand zodat de kraam niet in het niets staat
	local backWall = decor({
		Name = "StallBack",
		Size = Vector3.new(3, 26, 52),
		CFrame = CFrame.new(103, 14, zc),
		Color = P.brick,
		Material = Enum.Material.Brick,
		CanCollide = true,
	}, folder)
	decor({
		Name = "StallBackTop",
		Size = Vector3.new(5, 2, 54),
		CFrame = CFrame.new(103, 27, zc),
		Color = P.brick:Lerp(Color3.new(0, 0, 0), 0.3),
	}, folder)
	Scenery.windows(backWall.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 4, 1.6),
		40, 12, 3, 1, 0.5, folder)

	Scenery.awning(wall(72, 18.5, zc, 90), 40, 14, P.awningA, P.awningB, folder)
	Scenery.wallText(wall(98, 12, zc, -90), 22, 6, "PENNENKRAAM", P.gold, folder)
	Scenery.crate(CFrame.new(92, 2, zc - 12), 4, folder)
	Scenery.crate(CFrame.new(92, 2, zc + 12), 4, folder)
	Scenery.tree(CFrame.new(106, 1.4, zc + 30), 1.2, folder)
	Scenery.hedge(CFrame.new(100, 1.4, zc - 34), 30, folder)
end

local function buildWinkel(folder: Folder, zc: number)
	local body = decor({
		Name = "ShopBody",
		Size = Vector3.new(34, 32, 54),
		CFrame = CFrame.new(90, 17, zc),
		Color = P.plaster,
		Material = Enum.Material.Brick,
		CanCollide = true,
	}, folder)
	decor({
		Name = "ShopBase",
		Size = Vector3.new(35, 8, 55),
		CFrame = CFrame.new(90, 5, zc),
		Color = P.brick,
		Material = Enum.Material.Brick,
	}, folder)
	Scenery.storefront(wall(72.9, 1.4, zc, -90), 40, 13, folder)
	Scenery.awning(wall(72, 16, zc, -90), 42, 8, P.teal, P.awningB, folder)
	Scenery.windows(body.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 6, 17), 42, 14, 4, 2, 0.6, folder)
	Scenery.wallText(wall(72.4, 26, zc, -90), 30, 7, "PENNENWINKEL", P.neonPink, folder)
	decor({
		Name = "ShopRoof",
		Size = Vector3.new(37, 2, 57),
		CFrame = CFrame.new(90, 34, zc),
		Color = P.woodDark,
	}, folder)
	Scenery.planter(CFrame.new(76, 1.4, zc + 26), folder)
	Scenery.planter(CFrame.new(76, 1.4, zc - 26), folder)
end

local function buildFabriek(folder: Folder, zc: number)
	local body = decor({
		Name = "FactoryBody",
		Size = Vector3.new(44, 30, 76),
		CFrame = CFrame.new(96, 16, zc),
		Color = P.brick,
		Material = Enum.Material.Brick,
		CanCollide = true,
	}, folder)
	Scenery.windows(body.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 3, 22), 62, 18, 6, 2, 0.75, folder)
	Scenery.wallText(wall(73.6, 27, zc, -90), 34, 7, "PENNENFABRIEK", P.neonCyan, folder)

	-- rolluik
	decor({
		Name = "RollDoor",
		Size = Vector3.new(1, 16, 20),
		CFrame = CFrame.new(73.6, 9, zc - 4),
		Color = P.metal,
		Material = Enum.Material.DiamondPlate,
	}, folder)

	-- schoorstenen met rook
	for i, dz in { -22, 14 } do
		local stack = decor({
			Name = "Chimney",
			Size = Vector3.new(7, 34, 7),
			CFrame = CFrame.new(104, 45, zc + dz),
			Color = P.brick:Lerp(Color3.new(0, 0, 0), 0.2),
			Material = Enum.Material.Brick,
		}, folder)
		Scenery.smoke(stack, 10 + i * 2, Color3.fromRGB(210, 210, 214))
	end

	-- silo's
	for _, dz in { 30, 40 } do
		Scenery.cylinder({
			Name = "Silo",
			Size = Vector3.new(26, 14, 14),
			CFrame = CFrame.new(112, 14, zc + dz) * CFrame.Angles(0, 0, math.rad(90)),
			Color = P.metal,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
	end

	-- lopende band naar buiten
	decor({
		Name = "Conveyor",
		Size = Vector3.new(28, 1.2, 8),
		CFrame = CFrame.new(64, 6, zc + 6),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, folder)
	for i = 1, 6 do
		Scenery.cylinder({
			Name = "ConveyorPen",
			Size = Vector3.new(6, 0.8, 0.8),
			CFrame = CFrame.new(54 + i * 4, 7, zc + 6) * CFrame.Angles(0, math.rad(90), math.rad(90)),
			Color = i % 2 == 0 and P.neonPink or P.gold,
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
	end
end

local function buildGroothandel(folder: Folder, zc: number)
	local body = decor({
		Name = "WarehouseBody",
		Size = Vector3.new(50, 34, 96),
		CFrame = CFrame.new(100, 18, zc),
		Color = Color3.fromRGB(176, 180, 188),
		Material = Enum.Material.DiamondPlate,
		CanCollide = true,
	}, folder)
	decor({
		Name = "WarehouseStripe",
		Size = Vector3.new(51, 5, 97),
		CFrame = CFrame.new(100, 26, zc),
		Color = P.teal,
	}, folder)
	Scenery.wallText(wall(74.6, 30, zc, -90), 40, 8, "GROOTHANDEL", P.gold, folder)
	for _, dz in { -30, 0, 30 } do
		decor({
			Name = "DockDoor",
			Size = Vector3.new(1.2, 18, 22),
			CFrame = CFrame.new(74.6, 10, zc + dz),
			Color = P.metalDark,
			Material = Enum.Material.DiamondPlate,
		}, folder)
		decor({
			Name = "DockRamp",
			Size = Vector3.new(12, 1.2, 22),
			CFrame = CFrame.new(68, 2.2, zc + dz),
			Color = P.curb,
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, folder)
	end
	for i = 1, 6 do
		Scenery.crate(CFrame.new(62 + (i % 3) * 7, 1.4, zc - 46 + i * 5), 5, folder)
	end
	-- vrachtwagen
	decor({
		Name = "TruckBox",
		Size = Vector3.new(14, 14, 34),
		CFrame = CFrame.new(50, 9, zc + 48),
		Color = P.plaster,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	decor({
		Name = "TruckCab",
		Size = Vector3.new(13, 11, 12),
		CFrame = CFrame.new(50, 7.5, zc + 70),
		Color = P.awningA,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	for _, dz in { 38, 46, 64 } do
		Scenery.cylinder({
			Name = "Wheel",
			Size = Vector3.new(15, 6, 6),
			CFrame = CFrame.new(50, 3, zc + dz) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(32, 32, 36),
		}, folder)
	end
end

local function buildToren(folder: Folder, zc: number)
	local height = 150
	local body = decor({
		Name = "TowerBody",
		Size = Vector3.new(44, height, 56),
		CFrame = CFrame.new(98, height / 2, zc),
		Color = Color3.fromRGB(96, 124, 150),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		Reflectance = 0.35,
		CanCollide = true,
	}, folder)
	for _, face in { { yaw = -90, w = 56, d = 22 }, { yaw = 90, w = 56, d = 22 },
		{ yaw = 0, w = 44, d = 28 }, { yaw = 180, w = 44, d = 28 } } do
		Scenery.windows(
			body.CFrame * CFrame.Angles(0, math.rad(face.yaw), 0) * CFrame.new(0, 0, face.d),
			face.w - 6, height - 20, math.max(3, math.floor(face.w / 10)), 12, 0.55, folder
		)
	end
	decor({
		Name = "TowerCrown",
		Size = Vector3.new(30, 16, 38),
		CFrame = CFrame.new(98, height + 8, zc),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, folder)
	decor({
		Name = "TowerAntenna",
		Size = Vector3.new(1.6, 26, 1.6),
		CFrame = CFrame.new(98, height + 29, zc),
		Color = P.neonPink,
		Material = Enum.Material.Neon,
	}, folder)
	-- luifel boven de ingang
	decor({
		Name = "Canopy",
		Size = Vector3.new(16, 1.2, 34),
		CFrame = CFrame.new(68, 16, zc),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, folder)
	Scenery.wallText(wall(75.6, 26, zc, -90), 34, 8, "PEN STREET TOREN", P.neonCyan, folder)
	Scenery.storefront(wall(75.9, 1.4, zc, -90), 30, 14, folder)
	for _, dz in { -22, 22 } do
		decor({
			Name = "Flagpole",
			Size = Vector3.new(0.8, 22, 0.8),
			CFrame = CFrame.new(70, 12, zc + dz),
			Color = P.metal,
			Material = Enum.Material.Metal,
		}, folder)
		decor({
			Name = "Flag",
			Size = Vector3.new(0.3, 7, 11),
			CFrame = CFrame.new(70, 19, zc + dz + 5.5),
			Color = P.neonPink,
			Material = Enum.Material.Fabric,
		}, folder)
	end
	Scenery.hedge(CFrame.new(64, 1.4, zc + 40), 28, folder)
	Scenery.hedge(CFrame.new(64, 1.4, zc - 40), 28, folder)
end

local function buildPenthouse(folder: Folder, zc: number)
	-- terras op kolommen
	for _, offset in { Vector3.new(-20, 0, -30), Vector3.new(-20, 0, 30), Vector3.new(24, 0, -30), Vector3.new(24, 0, 30) } do
		decor({
			Name = "Column",
			Size = Vector3.new(6, 26, 6),
			CFrame = CFrame.new(96 + offset.X, 14, zc + offset.Z),
			Color = P.plaster,
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, folder)
	end
	decor({
		Name = "Terrace",
		Size = Vector3.new(60, 2, 78),
		CFrame = CFrame.new(98, 28, zc),
		Color = P.plaster,
		Material = Enum.Material.Marble,
		CanCollide = true,
	}, folder)
	-- zwembad
	decor({
		Name = "PoolWall",
		Size = Vector3.new(26, 3, 34),
		CFrame = CFrame.new(104, 30.5, zc),
		Color = P.plaster,
		Material = Enum.Material.Marble,
	}, folder)
	decor({
		Name = "PoolWater",
		Size = Vector3.new(22, 2.4, 30),
		CFrame = CFrame.new(104, 30.8, zc),
		Color = P.water,
		Material = Enum.Material.Glass,
		Transparency = 0.35,
	}, folder)
	-- glazen balustrade
	for _, dz in { -39, 39 } do
		decor({
			Name = "Railing",
			Size = Vector3.new(60, 7, 0.6),
			CFrame = CFrame.new(98, 32.5, zc + dz),
			Color = P.glass,
			Material = Enum.Material.Glass,
			Transparency = 0.6,
			Reflectance = 0.3,
		}, folder)
	end
	decor({
		Name = "RailingFront",
		Size = Vector3.new(0.6, 7, 78),
		CFrame = CFrame.new(68, 32.5, zc),
		Color = P.glass,
		Material = Enum.Material.Glass,
		Transparency = 0.6,
		Reflectance = 0.3,
	}, folder)
	-- ligbedden en parasol
	for _, dz in { -14, -6 } do
		decor({
			Name = "Lounger",
			Size = Vector3.new(11, 1.2, 4),
			CFrame = CFrame.new(84, 30, zc + dz),
			Color = P.awningB,
			Material = Enum.Material.Fabric,
		}, folder)
	end
	decor({
		Name = "Parasol",
		Size = Vector3.new(0.6, 12, 0.6),
		CFrame = CFrame.new(84, 36, zc + 4),
		Color = P.woodDark,
	}, folder)
	Scenery.cylinder({
		Name = "ParasolTop",
		Size = Vector3.new(1, 16, 16),
		CFrame = CFrame.new(84, 42, zc + 4) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.awningA,
		Material = Enum.Material.Fabric,
	}, folder)
	Scenery.wallText(wall(68, 42, zc, -90), 30, 7, "PENTHOUSE", P.gold, folder)
	-- trap naar beneden
	for i = 1, 9 do
		decor({
			Name = "Step",
			Size = Vector3.new(6, 3, 18),
			CFrame = CFrame.new(64 - i * 2, 28 - i * 3, zc),
			Color = P.plaster,
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, folder)
	end
end

local function buildJacht(folder: Folder, zc: number)
	-- haven met water
	decor({
		Name = "Harbour",
		Size = Vector3.new(120, 1, 120),
		CFrame = CFrame.new(112, 1.2, zc),
		Color = P.water,
		Material = Enum.Material.Glass,
		Transparency = 0.25,
		CanCollide = true,
	}, folder)
	decor({
		Name = "Quay",
		Size = Vector3.new(18, 3, 120),
		CFrame = CFrame.new(60, 2.2, zc),
		Color = P.wood,
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	-- romp
	decor({
		Name = "Hull",
		Size = Vector3.new(34, 12, 86),
		CFrame = CFrame.new(96, 6, zc),
		Color = P.plaster,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
	}, folder)
	Scenery.wedge({
		Name = "Bow",
		Size = Vector3.new(34, 12, 22),
		CFrame = CFrame.new(96, 6, zc - 54) * CFrame.Angles(0, math.rad(180), 0),
		Color = P.plaster,
		Anchored = true,
	}, folder)
	decor({
		Name = "Deck",
		Size = Vector3.new(34, 1.2, 86),
		CFrame = CFrame.new(96, 12.5, zc),
		Color = P.wood,
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	decor({
		Name = "Cabin",
		Size = Vector3.new(24, 13, 34),
		CFrame = CFrame.new(96, 19, zc + 12),
		Color = P.plaster,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
	}, folder)
	Scenery.windows(
		CFrame.new(96, 20, zc - 5.2) * CFrame.Angles(0, math.rad(180), 0),
		20, 8, 3, 1, 1, folder
	)
	decor({
		Name = "Bridge",
		Size = Vector3.new(16, 8, 20),
		CFrame = CFrame.new(96, 29, zc + 16),
		Color = P.plaster,
	}, folder)
	decor({
		Name = "Mast",
		Size = Vector3.new(1, 26, 1),
		CFrame = CFrame.new(96, 45, zc + 16),
		Color = P.metal,
		Material = Enum.Material.Metal,
	}, folder)
	Scenery.wallText(wall(78.5, 20, zc - 20, -90), 26, 6, "PENJACHT", P.neonCyan, folder)
	for _, dz in { -30, 0, 30 } do
		decor({
			Name = "Bollard",
			Size = Vector3.new(2.4, 4, 2.4),
			CFrame = CFrame.new(66, 5, zc + dz),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)
	end
end

local function buildOrbit(folder: Folder, zc: number)
	decor({
		Name = "Platform",
		Size = Vector3.new(70, 3, 90),
		CFrame = CFrame.new(100, 30, zc),
		Color = Color3.fromRGB(46, 50, 72),
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	decor({
		Name = "PlatformGlow",
		Size = Vector3.new(72, 0.8, 92),
		CFrame = CFrame.new(100, 28.4, zc),
		Color = Color3.fromRGB(150, 110, 240),
		Material = Enum.Material.Neon,
	}, folder)
	for i = 1, 3 do
		Scenery.cylinder({
			Name = "Ring",
			Size = Vector3.new(2, 44 + i * 16, 44 + i * 16),
			CFrame = CFrame.new(100, 52 + i * 6, zc) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(18 * i), 0, 0),
			Color = i % 2 == 0 and P.neonCyan or Color3.fromRGB(180, 110, 240),
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			CanCollide = false,
		}, folder)
	end
	for i = 1, 22 do
		Scenery.ball({
			Name = "Star",
			Size = Vector3.new(1.6, 1.6, 1.6),
			CFrame = CFrame.new(70 + math.random(0, 80), 40 + math.random(0, 70), zc - 50 + math.random(0, 100)),
			Color = Color3.fromRGB(255, 255, 240),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
	end
	-- lift omhoog vanaf het terrein
	for i = 1, 14 do
		decor({
			Name = "FloatStep",
			Size = Vector3.new(10, 1, 10),
			CFrame = CFrame.new(60 + i * 1.5, 3 + i * 2, zc - 30 + i * 2),
			Color = Color3.fromRGB(150, 110, 240),
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			CanCollide = true,
		}, folder)
	end
	Scenery.wallText(wall(64, 46, zc, -90), 30, 7, "PEN ORBIT", Color3.fromRGB(190, 140, 255), folder)
end

local BUILDERS: { [string]: (Folder, number) -> () } = {
	kraam = buildKraam,
	winkel = buildWinkel,
	fabriek = buildFabriek,
	groothandel = buildGroothandel,
	toren = buildToren,
	penthouse = buildPenthouse,
	jacht = buildJacht,
	orbit = buildOrbit,
}

-- ------------------------------------------------------------------ bouw ---

function World.build(): Folder
	local existing = Workspace:FindFirstChild("PenWorld")
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "PenWorld"
	root.Parent = Workspace

	setupLighting()

	local lastZ = blockZ(#Config.Stations)
	local totalLength = math.abs(lastZ) + 260
	buildStreet(root, totalLength, (140 + lastZ - 80) / 2)

	local plaza = buildPlaza(root)
	buildKiosks(plaza)
	buildRebirthPortal(plaza)
	buildPetStand(plaza)
	buildBoard(plaza, "Board_cash", wall(60, 30, 78, -90), "RIJKSTE VERKOPERS")
	buildBoard(plaza, "Board_rebirths", wall(60, 30, 110, -90), "MEESTE REBIRTHS")

	-- lage panden die het plein omsluiten, zodat het geen losse vlakte is
	for _, side in { -1, 1 } do
		local z = 18
		while z < 140 do
			local height = 22 + math.random(0, 12)
			local depth = 34
			local width = 26 + math.random(0, 10)
			local body = decor({
				Name = "PlazaShop",
				Size = Vector3.new(depth, height, width),
				CFrame = CFrame.new(side * 99, height / 2, z + width / 2),
				Color = ({ P.brick, P.plaster, P.plasterWarm, P.teal })[math.random(4)],
				Material = Enum.Material.Brick,
				CanCollide = true,
			}, root)
			Scenery.windows(
				body.CFrame * CFrame.Angles(0, math.rad(side > 0 and 90 or -90), 0) * CFrame.new(0, 4, depth / 2),
				width * 0.8, height * 0.55, 3, 2, 0.5, root
			)
			Scenery.storefront(wall(side * 82.2, 1.4, z + width / 2, side > 0 and 90 or -90), width * 0.6, 11, root)
			Scenery.awning(wall(side * 81.3, 13.6, z + width / 2, side > 0 and 90 or -90), width * 0.62, 6,
				({ P.awningA, P.teal, P.neonPink })[math.random(3)], P.awningB, root)
			z += width + 4
		end
	end

	streetFurniture(root, 4, lastZ - 90)
	facadeRow(root, 10, lastZ - 90)

	for index, station in Config.Stations do
		local folder, zc = stationShell(root, station, index)
		local builder = BUILDERS[station.key]
		if builder then
			builder(folder, zc)
		end
		stationProps(folder, station, zc,
			station.unlockRebirth == 0 and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(200, 120, 255))
	end

	-- stad eromheen: eerst een dichte band vlak achter de gevels, daarachter
	-- lagere blokken in de verte. Zo kijk je nooit uit op een leeg veld.
	local near = { minHeight = 34, maxHeight = 78, cool = 0.15, jitter = 8 }
	local far = { minHeight = 80, maxHeight = 190, cool = 0.55, jitter = 16 }
	local rows = math.max(6, math.floor((math.abs(lastZ) + 260) / 62))
	Scenery.skyline(Vector3.new(-152, 0, 120), 62, rows, 90, root, near)
	Scenery.skyline(Vector3.new(-250, 0, 140), 92, math.floor(rows * 0.6), 90, root, far)
	Scenery.skyline(Vector3.new(214, 0, 120), 64, rows, -90, root, near)
	Scenery.skyline(Vector3.new(320, 0, 140), 92, math.floor(rows * 0.6), -90, root, far)
	-- afsluiting aan beide uiteinden van de straat (rij loopt over de X-as)
	local endCap = { minHeight = 70, maxHeight = 160, cool = 0.5, jitter = 12, axis = "x" }
	Scenery.skyline(Vector3.new(-180, 0, lastZ - 170), 86, 6, 0, root, endCap)
	Scenery.skyline(Vector3.new(-180, 0, 250), 86, 6, 180, root, endCap)

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
