--!strict
-- De architectuur van elke zone. Zones.luau zet overal dezelfde werkplek,
-- toonbank en kiosk neer; dit bestand maakt de wereld eromheen.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))
local Scenery = require(script.Parent.Scenery)

local ZoneArt = {}

local P = Scenery.Palette
local decor = Scenery.decor

local function at(o: Vector3, x: number, y: number, z: number, yawDeg: number?): CFrame
	local cf = CFrame.new(o + Vector3.new(x, y, z))
	if yawDeg then
		cf = cf * CFrame.Angles(0, math.rad(yawDeg), 0)
	end
	return cf
end

local function floor(folder: Folder, o: Vector3, size: Vector3, y: number, color: Color3, material: Enum.Material)
	decor({
		Name = "Floor",
		Size = size,
		CFrame = CFrame.new(o + Vector3.new(0, y, -40)),
		Color = color,
		Material = material,
		CanCollide = true,
	}, folder)
end

-- Tegelpatroon over de vloer, voor wat leven in grote vlakken.
local function tiles(folder: Folder, o: Vector3, cols: number, rows: number, tile: number,
	y: number, a: Color3, b: Color3, material: Enum.Material)
	for gx = 0, cols - 1 do
		for gz = 0, rows - 1 do
			decor({
				Name = "Tile",
				Size = Vector3.new(tile - 0.6, 0.2, tile - 0.6),
				CFrame = CFrame.new(o + Vector3.new(
					(gx - (cols - 1) / 2) * tile,
					y,
					-40 + (gz - (rows - 1) / 2) * tile)),
				Color = (gx + gz) % 2 == 0 and a or b,
				Material = material,
			}, folder)
		end
	end
end

local function wallBlock(folder: Folder, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material): Part
	return decor({
		Name = "Wall",
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material,
		CanCollide = true,
	}, folder)
end

local function ceilingLight(folder: Folder, cf: CFrame, width: number, color: Color3)
	local strip = decor({
		Name = "CeilingLight",
		Size = Vector3.new(width, 0.6, 3),
		CFrame = cf,
		Color = color,
		Material = Enum.Material.Neon,
	}, folder)
	local light = Instance.new("PointLight")
	light.Brightness = 2.2
	light.Range = 48
	light.Color = color
	light.Parent = strip
end

-- ------------------------------------------------------------ 0. de steeg --

function ZoneArt.steeg(folder: Folder, station)
	local o = station.origin
	floor(folder, o, Vector3.new(300, 2, 360), -1, Color3.fromRGB(38, 40, 48), Enum.Material.Asphalt)

	-- natte plekken
	for i = 1, 14 do
		decor({
			Name = "Puddle",
			Size = Vector3.new(math.random(10, 26), 0.12, math.random(8, 20)),
			CFrame = at(o, math.random(-120, 120), 0.12, math.random(-160, 130)),
			Color = Color3.fromRGB(58, 66, 82),
			Material = Enum.Material.Glass,
			Reflectance = 0.45,
			Transparency = 0.25,
		}, folder)
	end

	-- de twee hoge muren van de steeg
	for _, side in { -1, 1 } do
		local wall = wallBlock(folder, at(o, side * 150, 45, -40), Vector3.new(60, 90, 360),
			side < 0 and P.brick:Lerp(Color3.new(0, 0, 0), 0.35) or Color3.fromRGB(78, 70, 66),
			Enum.Material.Brick)
		Scenery.windows(wall.CFrame * CFrame.Angles(0, math.rad(side < 0 and 90 or -90), 0) * CFrame.new(0, 10, 30),
			300, 60, 10, 5, 0.3, folder)

		-- brandtrappen
		for level = 1, 3 do
			for _, dz in { -90, 10, 100 } do
				decor({
					Name = "FireEscape",
					Size = Vector3.new(10, 0.5, 22),
					CFrame = at(o, side * 114, 14 + level * 18, -40 + dz),
					Color = Color3.fromRGB(52, 54, 62),
					Material = Enum.Material.DiamondPlate,
					CanCollide = true,
				}, folder)
				decor({
					Name = "EscapeRail",
					Size = Vector3.new(0.4, 5, 22),
					CFrame = at(o, side * 109, 17 + level * 18, -40 + dz),
					Color = Color3.fromRGB(52, 54, 62),
					Material = Enum.Material.Metal,
				}, folder)
			end
		end

		-- pijpen langs de muur
		for i = 1, 6 do
			Scenery.cylinder({
				Name = "Pipe",
				Size = Vector3.new(70, 2, 2),
				CFrame = at(o, side * 119, 40, -170 + i * 52) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(64, 62, 58),
				Material = Enum.Material.Metal,
			}, folder)
		end

		-- airco's
		for i = 1, 5 do
			decor({
				Name = "AC",
				Size = Vector3.new(7, 6, 6),
				CFrame = at(o, side * 116, 22 + (i % 3) * 20, -150 + i * 58),
				Color = Color3.fromRGB(96, 98, 104),
				Material = Enum.Material.Metal,
			}, folder)
		end
	end

	-- neonreclame
	local neons = {
		{ z = -130, color = Color3.fromRGB(255, 92, 150), text = "PEN" },
		{ z = -20, color = Color3.fromRGB(96, 226, 255), text = "INKT 24H" },
		{ z = 90, color = Color3.fromRGB(255, 196, 70), text = "OPEN" },
	}
	for i, n in neons do
		local side = i % 2 == 0 and 1 or -1
		Scenery.wallText(at(o, side * 118, 30, n.z, side < 0 and 90 or -90), 20, 7, n.text, n.color, folder)
		local glow = decor({
			Name = "NeonGlow",
			Size = Vector3.new(2, 10, 24),
			CFrame = at(o, side * 116, 30, n.z),
			Color = n.color,
			Material = Enum.Material.Neon,
			Transparency = 0.5,
		}, folder)
		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Range = 60
		light.Color = n.color
		light.Parent = glow
	end

	-- kabels met peertjes over de steeg
	for i = 1, 5 do
		local z = -160 + i * 60
		decor({
			Name = "Cable",
			Size = Vector3.new(300, 0.3, 0.3),
			CFrame = at(o, 0, 46, z),
			Color = Color3.fromRGB(24, 24, 28),
		}, folder)
		for b = 1, 7 do
			local bulb = decor({
				Name = "Bulb",
				Size = Vector3.new(1.4, 1.4, 1.4),
				CFrame = at(o, -120 + b * 34, 44.6, z),
				Color = Color3.fromRGB(255, 226, 160),
				Material = Enum.Material.Neon,
			}, folder)
			if b % 3 == 0 then
				local light = Instance.new("PointLight")
				light.Brightness = 1.6
				light.Range = 34
				light.Color = Color3.fromRGB(255, 226, 170)
				light.Parent = bulb
			end
		end
	end

	-- rommel: containers, kratten, pallets
	for i = 1, 5 do
		local side = i % 2 == 0 and 1 or -1
		decor({
			Name = "Dumpster",
			Size = Vector3.new(14, 9, 22),
			CFrame = at(o, side * 100, 5.5, -150 + i * 62),
			Color = i % 2 == 0 and Color3.fromRGB(46, 92, 72) or Color3.fromRGB(88, 62, 52),
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		decor({
			Name = "DumpsterLid",
			Size = Vector3.new(15, 1, 23),
			CFrame = at(o, side * 100, 10.4, -150 + i * 62),
			Color = Color3.fromRGB(36, 38, 44),
		}, folder)
	end
	for i = 1, 14 do
		Scenery.crate(at(o, math.random(-118, 118), 1, math.random(-160, 120)), math.random(3, 6), folder)
	end

	-- stoom uit de putdeksels
	for i = 1, 4 do
		local grate = decor({
			Name = "Grate",
			Size = Vector3.new(8, 0.3, 8),
			CFrame = at(o, math.random(-90, 90), 0.2, -140 + i * 70),
			Color = Color3.fromRGB(58, 58, 64),
			Material = Enum.Material.DiamondPlate,
		}, folder)
		Scenery.smoke(grate, 14, Color3.fromRGB(198, 202, 210))
	end

	-- regen over de hele steeg
	local rainAnchor = decor({
		Name = "RainAnchor",
		Size = Vector3.new(4, 1, 4),
		CFrame = at(o, 0, 88, -40),
		Transparency = 1,
	}, folder)
	local attachment = Instance.new("Attachment")
	attachment.Parent = rainAnchor
	local rain = Instance.new("ParticleEmitter")
	rain.Name = "Rain"
	rain.Rate = 320
	rain.Lifetime = NumberRange.new(2.4, 3)
	rain.Speed = NumberRange.new(90, 120)
	rain.SpreadAngle = Vector2.new(6, 6)
	rain.Size = NumberSequence.new(0.35)
	rain.Transparency = NumberSequence.new(0.35)
	rain.Color = ColorSequence.new(Color3.fromRGB(170, 190, 215))
	rain.Acceleration = Vector3.new(0, -60, 0)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Parent = attachment
end

-- ------------------------------------------------------ 1. winkelstraat ----

function ZoneArt.winkelstraat(folder: Folder, station)
	local o = station.origin
	floor(folder, o, Vector3.new(340, 2, 380), -1, Color3.fromRGB(126, 176, 96), Enum.Material.Grass)

	-- geplaveide boulevard
	tiles(folder, o, 12, 16, 22, 0.3, Color3.fromRGB(226, 216, 198), Color3.fromRGB(208, 196, 178),
		Enum.Material.Pebble)

	local pastels = {
		Color3.fromRGB(246, 232, 206), Color3.fromRGB(196, 228, 222),
		Color3.fromRGB(244, 206, 198), Color3.fromRGB(208, 220, 244),
		Color3.fromRGB(250, 240, 186),
	}

	-- winkeltjes aan beide kanten
	for _, side in { -1, 1 } do
		local z = -170
		local i = 0
		while z < 150 do
			i += 1
			local width = 40 + math.random(0, 14)
			local height = 26 + math.random(0, 12)
			local color = pastels[((i + (side > 0 and 2 or 0)) % #pastels) + 1]
			local body = wallBlock(folder, at(o, side * 146, height / 2, z + width / 2),
				Vector3.new(46, height, width), color, Enum.Material.Plaster)
			Scenery.windows(
				body.CFrame * CFrame.Angles(0, math.rad(side < 0 and 90 or -90), 0) * CFrame.new(0, 5, 23),
				width * 0.7, height * 0.4, 3, 2, 0.15, folder
			)
			Scenery.storefront(at(o, side * 123, 0.4, z + width / 2, side < 0 and 90 or -90), width * 0.62, 13, folder)
			Scenery.awning(at(o, side * 122, 16, z + width / 2, side < 0 and 90 or -90), width * 0.66, 8,
				pastels[((i + 3) % #pastels) + 1], Color3.fromRGB(252, 250, 244), folder)
			-- dakrand
			decor({
				Name = "Cornice",
				Size = Vector3.new(50, 2.5, width + 3),
				CFrame = at(o, side * 146, height + 1, z + width / 2),
				Color = color:Lerp(Color3.new(1, 1, 1), 0.35),
			}, folder)
			z += width + 8
		end
	end

	-- trap naar het hoger gelegen deel, zoals op de referentie
	for step = 1, 8 do
		decor({
			Name = "Step",
			Size = Vector3.new(90, 1.6, 6),
			CFrame = at(o, 0, 0.8 + (step - 1) * 1.6, -150 + step * 6),
			Color = Color3.fromRGB(196, 190, 178),
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, folder)
	end
	decor({
		Name = "UpperLawn",
		Size = Vector3.new(300, 2, 110),
		CFrame = at(o, 0, 12, -210),
		Color = Color3.fromRGB(132, 184, 100),
		Material = Enum.Material.Grass,
		CanCollide = true,
	}, folder)

	-- bomen, bankjes, lantaarns, bloembakken
	for i = 1, 8 do
		local side = i % 2 == 0 and 1 or -1
		Scenery.tree(at(o, side * 100, 0.4, -160 + i * 42), 1.3, folder)
		Scenery.lamppost(at(o, side * 88, 0.4, -140 + i * 42, side > 0 and 180 or 0), folder)
		if i % 2 == 0 then
			Scenery.bench(at(o, side * 78, 0.4, -120 + i * 38, side > 0 and 180 or 0), folder)
		else
			Scenery.planter(at(o, side * 82, 0.4, -130 + i * 40), folder)
		end
	end

	-- vlaggetjes tussen de lantaarns
	for i = 1, 7 do
		decor({
			Name = "Bunting",
			Size = Vector3.new(180, 0.25, 0.25),
			CFrame = at(o, 0, 22, -150 + i * 44),
			Color = Color3.fromRGB(240, 240, 240),
		}, folder)
		for f = 1, 9 do
			decor({
				Name = "Flag",
				Size = Vector3.new(3, 3.4, 0.2),
				CFrame = at(o, -80 + f * 20, 20, -150 + i * 44),
				Color = pastels[(f % #pastels) + 1],
				Material = Enum.Material.Fabric,
			}, folder)
		end
	end

	Scenery.fountain(at(o, 0, 0.4, 90), folder)
end

-- ------------------------------------------------------ 2. zakencentrum ----

function ZoneArt.zakencentrum(folder: Folder, station)
	local o = station.origin
	floor(folder, o, Vector3.new(340, 2, 380), -1, Color3.fromRGB(64, 66, 74), Enum.Material.Asphalt)

	-- brede stoepen
	for _, side in { -1, 1 } do
		decor({
			Name = "Sidewalk",
			Size = Vector3.new(70, 1.4, 380),
			CFrame = at(o, side * 122, 0.7, -40),
			Color = Color3.fromRGB(176, 172, 164),
			Material = Enum.Material.Concrete,
			CanCollide = true,
		}, folder)
		decor({
			Name = "Curb",
			Size = Vector3.new(1.6, 1.8, 380),
			CFrame = at(o, side * 87, 0.9, -40),
			Color = Color3.fromRGB(150, 146, 140),
		}, folder)
	end
	for i = 0, 15 do
		decor({
			Name = "RoadLine",
			Size = Vector3.new(1.4, 0.2, 12),
			CFrame = at(o, 0, 0.3, -220 + i * 26),
			Color = Color3.fromRGB(226, 218, 160),
		}, folder)
	end

	-- natuurstenen panden met balkons (linkerzijde)
	local z = -190
	local i = 0
	while z < 160 do
		i += 1
		local width = 52 + math.random(0, 16)
		local height = 66 + math.random(0, 26)
		local body = wallBlock(folder, at(o, -196, height / 2, z + width / 2),
			Vector3.new(80, height, width), Color3.fromRGB(214, 206, 188), Enum.Material.Concrete)
		Scenery.windows(
			body.CFrame * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 4, 40),
			width * 0.82, height * 0.74, math.max(3, math.floor(width / 13)), math.max(4, math.floor(height / 15)),
			0.25, folder
		)
		for level = 1, math.floor(height / 22) do
			decor({
				Name = "Balcony",
				Size = Vector3.new(3, 0.6, width * 0.8),
				CFrame = at(o, -155, level * 22, z + width / 2),
				Color = Color3.fromRGB(196, 190, 176),
			}, folder)
			decor({
				Name = "BalconyRail",
				Size = Vector3.new(0.4, 3, width * 0.8),
				CFrame = at(o, -154, level * 22 + 1.8, z + width / 2),
				Color = Color3.fromRGB(52, 54, 60),
				Material = Enum.Material.Metal,
			}, folder)
		end
		decor({
			Name = "Cornice",
			Size = Vector3.new(84, 3, width + 3),
			CFrame = at(o, -196, height + 1.5, z + width / 2),
			Color = Color3.fromRGB(196, 188, 172),
		}, folder)
		z += width + 4
	end

	-- glazen torens aan de overkant en op de achtergrond
	for i = 1, 5 do
		local height = 150 + math.random(0, 160)
		local width = 54 + math.random(0, 26)
		local body = wallBlock(folder, at(o, 200 + math.random(-20, 40), height / 2, -190 + i * 84),
			Vector3.new(width, height, width), Color3.fromRGB(104, 128, 156), Enum.Material.Glass)
		body.Transparency = 0.15
		body.Reflectance = 0.35
		Scenery.windows(body.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 0, width / 2),
			width * 0.85, height * 0.9, math.max(3, math.floor(width / 12)), math.floor(height / 14), 0.45, folder)
	end
	Scenery.skyline(o + Vector3.new(-330, 0, 120), 90, 6, 90, folder,
		{ minHeight = 120, maxHeight = 260, cool = 0.5, jitter = 20, axis = "z" })
	Scenery.skyline(o + Vector3.new(330, 0, 120), 90, 6, -90, folder,
		{ minHeight = 140, maxHeight = 280, cool = 0.55, jitter = 20, axis = "z" })

	-- straatspul: taxi's, verkeerslicht, bushalte, bomen in roosters
	for i = 1, 4 do
		Scenery.car(at(o, (i % 2 == 0 and 1 or -1) * 70, 0.4, -170 + i * 76, i % 2 == 0 and 180 or 0),
			Color3.fromRGB(236, 196, 60), false, folder)
	end
	decor({
		Name = "TrafficPole",
		Size = Vector3.new(1.2, 26, 1.2),
		CFrame = at(o, -88, 13, 60),
		Color = Color3.fromRGB(44, 46, 52),
		Material = Enum.Material.Metal,
	}, folder)
	for i, color in { Color3.fromRGB(230, 60, 60), Color3.fromRGB(240, 200, 70), Color3.fromRGB(90, 220, 120) } do
		decor({
			Name = "TrafficLight",
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = at(o, -88, 30 - i * 3, 60),
			Color = color,
			Material = Enum.Material.Neon,
		}, folder)
	end
	for i = 1, 8 do
		local side = i % 2 == 0 and 1 or -1
		Scenery.tree(at(o, side * 104, 1.4, -180 + i * 44), 0.9, folder)
		Scenery.lamppost(at(o, side * 116, 1.4, -160 + i * 44, side > 0 and 180 or 0), folder)
	end
end


-- -------------------------------------------------------- 3. beursvloer ----

function ZoneArt.beursvloer(folder: Folder, station)
	local o = station.origin
	floor(folder, o, Vector3.new(360, 2, 380), -1, Color3.fromRGB(228, 222, 210), Enum.Material.Marble)
	tiles(folder, o, 14, 16, 24, 0.25, Color3.fromRGB(236, 230, 218), Color3.fromRGB(206, 198, 184),
		Enum.Material.Marble)

	-- muren en plafond: het is binnen
	local H = 78
	for _, side in { -1, 1 } do
		wallBlock(folder, at(o, side * 178, H / 2, -40), Vector3.new(8, H, 380),
			Color3.fromRGB(214, 206, 190), Enum.Material.Marble)
	end
	wallBlock(folder, at(o, 0, H / 2, 150), Vector3.new(360, H, 8), Color3.fromRGB(214, 206, 190), Enum.Material.Marble)
	wallBlock(folder, at(o, 0, H / 2, -230), Vector3.new(360, H, 8), Color3.fromRGB(214, 206, 190), Enum.Material.Marble)
	decor({
		Name = "Ceiling",
		Size = Vector3.new(360, 4, 380),
		CFrame = at(o, 0, H, -40),
		Color = Color3.fromRGB(58, 60, 70),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	}, folder)
	-- cassetteplafond met lichtstroken
	for gx = -2, 2 do
		for gz = -3, 3 do
			decor({
				Name = "CeilingPanel",
				Size = Vector3.new(60, 2, 46),
				CFrame = at(o, gx * 66, H - 3, -40 + gz * 52),
				Color = Color3.fromRGB(72, 74, 86),
			}, folder)
		end
		ceilingLight(folder, at(o, gx * 66, H - 5, -40), 300, Color3.fromRGB(226, 238, 255))
	end

	-- zuilenrij
	for _, side in { -1, 1 } do
		for i = 1, 6 do
			Scenery.cylinder({
				Name = "Column",
				Size = Vector3.new(H, 16, 16),
				CFrame = at(o, side * 132, H / 2, -190 + i * 58) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(238, 232, 220),
				Material = Enum.Material.Marble,
				CanCollide = true,
			}, folder)
			decor({
				Name = "ColumnCap",
				Size = Vector3.new(22, 4, 22),
				CFrame = at(o, side * 132, H - 6, -190 + i * 58),
				Color = Color3.fromRGB(226, 218, 202),
				Material = Enum.Material.Marble,
			}, folder)
		end
	end

	-- koersborden tegen de achterwand
	for i = 0, 5 do
		local green = i % 2 == 0
		local board = decor({
			Name = "Ticker",
			Size = Vector3.new(52, 14, 1.4),
			CFrame = at(o, -140 + i * 56, 46, -225),
			Color = Color3.fromRGB(16, 18, 24),
		}, folder)
		Scenery.wallText(at(o, -140 + i * 56, 46, -223, 180), 48, 12,
			green and "PEN  +14.2%" or "INK  -3.8%",
			green and Color3.fromRGB(90, 250, 140) or Color3.fromRGB(255, 96, 96), folder)
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 50
		light.Color = green and Color3.fromRGB(90, 250, 140) or Color3.fromRGB(255, 96, 96)
		light.Parent = board
	end

	-- handelsbalies met schermen
	for i = 1, 6 do
		local x = -150 + i * 46
		decor({
			Name = "TradingDesk",
			Size = Vector3.new(26, 6, 14),
			CFrame = at(o, x, 3, 96),
			Color = Color3.fromRGB(64, 66, 78),
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		for m = 1, 3 do
			decor({
				Name = "Monitor",
				Size = Vector3.new(7, 5, 0.6),
				CFrame = at(o, x - 9 + m * 7, 9, 92),
				Color = m % 2 == 0 and Color3.fromRGB(70, 230, 140) or Color3.fromRGB(240, 96, 96),
				Material = Enum.Material.Neon,
				Transparency = 0.15,
			}, folder)
		end
	end

	-- mezzanine rondom
	for _, side in { -1, 1 } do
		decor({
			Name = "Mezzanine",
			Size = Vector3.new(40, 2, 380),
			CFrame = at(o, side * 154, 40, -40),
			Color = Color3.fromRGB(226, 220, 206),
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, folder)
		decor({
			Name = "MezzanineRail",
			Size = Vector3.new(1, 7, 380),
			CFrame = at(o, side * 134, 44, -40),
			Color = P.gold,
			Material = Enum.Material.Metal,
		}, folder)
	end

	-- klok boven de ingang
	decor({
		Name = "ClockFace",
		Size = Vector3.new(18, 18, 2),
		CFrame = at(o, 0, 58, 146),
		Color = Color3.fromRGB(246, 240, 226),
		Material = Enum.Material.Neon,
	}, folder)
	decor({
		Name = "ClockRing",
		Size = Vector3.new(22, 22, 1),
		CFrame = at(o, 0, 58, 147),
		Color = P.gold,
		Material = Enum.Material.Metal,
	}, folder)
end

-- ------------------------------------------------------------- 4. lobby ----

function ZoneArt.lobby(folder: Folder, station)
	local o = station.origin
	floor(folder, o, Vector3.new(360, 2, 380), -1, Color3.fromRGB(240, 236, 228), Enum.Material.Marble)
	tiles(folder, o, 18, 20, 20, 0.25, Color3.fromRGB(246, 242, 234), Color3.fromRGB(58, 56, 56),
		Enum.Material.Marble)

	local H = 86
	-- glazen voorgevel aan de zuidkant, dichte wanden verder
	decor({
		Name = "Facade",
		Size = Vector3.new(360, H, 3),
		CFrame = at(o, 0, H / 2, 150),
		Color = Color3.fromRGB(150, 190, 214),
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Reflectance = 0.3,
		CanCollide = true,
	}, folder)
	for i = -5, 5 do
		decor({
			Name = "Mullion",
			Size = Vector3.new(2, H, 4),
			CFrame = at(o, i * 32, H / 2, 150),
			Color = Color3.fromRGB(58, 60, 68),
			Material = Enum.Material.Metal,
		}, folder)
	end
	for _, side in { -1, 1 } do
		wallBlock(folder, at(o, side * 178, H / 2, -40), Vector3.new(8, H, 380),
			Color3.fromRGB(236, 230, 220), Enum.Material.Marble)
	end
	wallBlock(folder, at(o, 0, H / 2, -230), Vector3.new(360, H, 8), Color3.fromRGB(236, 230, 220), Enum.Material.Marble)
	decor({
		Name = "Ceiling",
		Size = Vector3.new(360, 4, 380),
		CFrame = at(o, 0, H, -40),
		Color = Color3.fromRGB(226, 220, 210),
		CanCollide = true,
	}, folder)
	for i = -4, 4 do
		ceilingLight(folder, at(o, i * 38, H - 3, -40), 320, Color3.fromRGB(255, 240, 216))
	end

	-- logo-wand achterin
	decor({
		Name = "LogoWall",
		Size = Vector3.new(120, 40, 3),
		CFrame = at(o, 0, 30, -224),
		Color = Color3.fromRGB(46, 44, 42),
		Material = Enum.Material.Marble,
	}, folder)
	Scenery.wallText(at(o, 0, 32, -221, 180), 100, 22, "PEN STREET", P.gold, folder)

	-- glazen liften
	for _, side in { -1, 1 } do
		for i = 1, 2 do
			local x = side * (86 + i * 26)
			decor({
				Name = "LiftShaft",
				Size = Vector3.new(22, H, 22),
				CFrame = at(o, x, H / 2, -150),
				Color = Color3.fromRGB(170, 206, 226),
				Material = Enum.Material.Glass,
				Transparency = 0.6,
				Reflectance = 0.3,
			}, folder)
			local cab = decor({
				Name = "LiftCab",
				Size = Vector3.new(18, 14, 18),
				CFrame = at(o, x, 8 + i * 18, -150),
				Color = Color3.fromRGB(226, 220, 210),
				Material = Enum.Material.Metal,
			}, folder)
			decor({
				Name = "LiftGlow",
				Size = Vector3.new(19, 1, 19),
				CFrame = at(o, x, 15 + i * 18, -150),
				Color = P.gold,
				Material = Enum.Material.Neon,
			}, folder)
			cab.Name = "LiftCab"
		end
	end

	-- balies
	for i = -1, 1 do
		decor({
			Name = "Reception",
			Size = Vector3.new(44, 7, 12),
			CFrame = at(o, i * 60, 3.5, -100),
			Color = Color3.fromRGB(58, 54, 52),
			Material = Enum.Material.Wood,
			CanCollide = true,
		}, folder)
		decor({
			Name = "ReceptionTop",
			Size = Vector3.new(48, 0.8, 14),
			CFrame = at(o, i * 60, 7.4, -100),
			Color = Color3.fromRGB(238, 234, 226),
			Material = Enum.Material.Marble,
		}, folder)
		decor({
			Name = "DeskGlow",
			Size = Vector3.new(44, 0.6, 1),
			CFrame = at(o, i * 60, 1.6, -94),
			Color = P.gold,
			Material = Enum.Material.Neon,
		}, folder)
	end

	-- zithoek en groen
	for _, spot in { Vector3.new(-120, 0, 60), Vector3.new(120, 0, 60) } do
		decor({
			Name = "Sofa",
			Size = Vector3.new(28, 4, 12),
			CFrame = at(o, spot.X, 3, spot.Z),
			Color = Color3.fromRGB(64, 70, 86),
			Material = Enum.Material.Fabric,
			CanCollide = true,
		}, folder)
		decor({
			Name = "SofaBack",
			Size = Vector3.new(28, 8, 3),
			CFrame = at(o, spot.X, 6, spot.Z - 6),
			Color = Color3.fromRGB(64, 70, 86),
			Material = Enum.Material.Fabric,
		}, folder)
		Scenery.planter(at(o, spot.X + 22, 0.4, spot.Z), folder)
	end

	-- roltrap naar de mezzanine
	for step = 1, 14 do
		decor({
			Name = "EscalatorStep",
			Size = Vector3.new(16, 2, 5),
			CFrame = at(o, 140, 1 + step * 2.4, -30 - step * 5),
			Color = Color3.fromRGB(150, 154, 162),
			Material = Enum.Material.DiamondPlate,
			CanCollide = true,
		}, folder)
	end

	-- de stad buiten het glas
	Scenery.skyline(o + Vector3.new(-160, 0, 330), 76, 5, 180, folder,
		{ minHeight = 130, maxHeight = 300, cool = 0.45, jitter = 18, axis = "x" })
end

-- --------------------------------------------------------- 5. penthouse ----

function ZoneArt.penthouse(folder: Folder, station)
	local o = station.origin

	-- het dek zelf
	decor({
		Name = "Deck",
		Size = Vector3.new(320, 6, 360),
		CFrame = at(o, 0, -3, -40),
		Color = Color3.fromRGB(198, 160, 116),
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	for i = 0, 22 do
		decor({
			Name = "DeckSeam",
			Size = Vector3.new(320, 0.2, 1),
			CFrame = at(o, 0, 0.2, -215 + i * 16),
			Color = Color3.fromRGB(168, 132, 92),
		}, folder)
	end

	-- infinity pool aan de rand
	decor({
		Name = "PoolWall",
		Size = Vector3.new(150, 8, 70),
		CFrame = at(o, 0, 1, 90),
		Color = Color3.fromRGB(232, 228, 220),
		Material = Enum.Material.Marble,
		CanCollide = true,
	}, folder)
	decor({
		Name = "PoolWater",
		Size = Vector3.new(142, 6, 62),
		CFrame = at(o, 0, 2, 90),
		Color = Color3.fromRGB(86, 196, 206),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		Reflectance = 0.25,
	}, folder)
	decor({
		Name = "PoolEdgeGlass",
		Size = Vector3.new(150, 8, 1),
		CFrame = at(o, 0, 1, 125),
		Color = Color3.fromRGB(190, 226, 232),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		Reflectance = 0.4,
	}, folder)

	-- ronde zithoek met vuurplaats, zoals op de foto
	Scenery.cylinder({
		Name = "LoungePit",
		Size = Vector3.new(4, 58, 58),
		CFrame = at(o, -96, 2, 40) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(226, 216, 196),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	}, folder)
	Scenery.cylinder({
		Name = "LoungeSeat",
		Size = Vector3.new(6, 50, 50),
		CFrame = at(o, -96, 5, 40) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(240, 234, 222),
		Material = Enum.Material.Fabric,
	}, folder)
	Scenery.cylinder({
		Name = "FirePit",
		Size = Vector3.new(4, 18, 18),
		CFrame = at(o, -96, 6, 40) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(58, 54, 50),
		Material = Enum.Material.Slate,
	}, folder)
	local fire = decor({
		Name = "Fire",
		Size = Vector3.new(10, 3, 10),
		CFrame = at(o, -96, 9, 40),
		Color = Color3.fromRGB(255, 150, 60),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
	}, folder)
	Scenery.smoke(fire, 8, Color3.fromRGB(255, 180, 110))

	-- ligbedden, parasols, pergola
	for i = 1, 4 do
		decor({
			Name = "Lounger",
			Size = Vector3.new(12, 1.4, 5),
			CFrame = at(o, 90, 1.5, 20 + i * 14),
			Color = Color3.fromRGB(244, 240, 232),
			Material = Enum.Material.Fabric,
			CanCollide = true,
		}, folder)
		decor({
			Name = "LoungerBack",
			Size = Vector3.new(6, 4, 5),
			CFrame = at(o, 95, 3.5, 20 + i * 14) * CFrame.Angles(0, 0, math.rad(-25)),
			Color = Color3.fromRGB(244, 240, 232),
			Material = Enum.Material.Fabric,
		}, folder)
	end
	for _, dx in { -150, 150 } do
		for i = 1, 5 do
			decor({
				Name = "PergolaBeam",
				Size = Vector3.new(30, 1.6, 1.6),
				CFrame = at(o, dx, 26, -170 + i * 22),
				Color = Color3.fromRGB(206, 172, 128),
				Material = Enum.Material.Wood,
			}, folder)
		end
		for _, dz in { -160, -80 } do
			decor({
				Name = "PergolaPost",
				Size = Vector3.new(2.4, 26, 2.4),
				CFrame = at(o, dx, 13, dz),
				Color = Color3.fromRGB(186, 152, 112),
				Material = Enum.Material.Wood,
				CanCollide = true,
			}, folder)
		end
	end

	-- glazen balustrade rondom
	for _, spec in { { x = 0, z = -220, w = 320, yaw = 0 }, { x = -160, z = -40, w = 360, yaw = 90 },
		{ x = 160, z = -40, w = 360, yaw = 90 } } do
		decor({
			Name = "Railing",
			Size = Vector3.new(spec.w, 9, 0.8),
			CFrame = at(o, spec.x, 4.5, spec.z, spec.yaw),
			Color = Color3.fromRGB(198, 226, 236),
			Material = Enum.Material.Glass,
			Transparency = 0.55,
			Reflectance = 0.35,
			CanCollide = true,
		}, folder)
	end

	-- buitenbar en groen
	decor({
		Name = "Bar",
		Size = Vector3.new(50, 7, 14),
		CFrame = at(o, 110, 3.5, -130),
		Color = Color3.fromRGB(52, 48, 46),
		Material = Enum.Material.Marble,
		CanCollide = true,
	}, folder)
	Scenery.wallText(at(o, 110, 14, -137, 180), 30, 6, "SKY BAR", P.gold, folder)
	for i = 1, 6 do
		Scenery.hedge(at(o, -140 + i * 18, 0.4, -200), 14, folder)
	end
	for _, dx in { -60, 60 } do
		Scenery.palm(at(o, dx, 0.4, -190), folder)
	end

	-- de stad diep beneden
	Scenery.skyline(o + Vector3.new(-420, -700, 260), 110, 7, 90, folder,
		{ minHeight = 240, maxHeight = 560, cool = 0.55, jitter = 40, axis = "z" })
	Scenery.skyline(o + Vector3.new(420, -700, 260), 110, 7, -90, folder,
		{ minHeight = 240, maxHeight = 560, cool = 0.6, jitter = 40, axis = "z" })
	Scenery.skyline(o + Vector3.new(-300, -700, 420), 120, 6, 180, folder,
		{ minHeight = 200, maxHeight = 520, cool = 0.65, jitter = 40, axis = "x" })
end

-- -------------------------------------------------------- 6. jachthaven ----

function ZoneArt.jachthaven(folder: Folder, station)
	local o = station.origin

	decor({
		Name = "Seabed",
		Size = Vector3.new(900, 4, 900),
		CFrame = at(o, 0, -26, -40),
		Color = Color3.fromRGB(38, 76, 92),
		CanCollide = true,
	}, folder)
	decor({
		Name = "Water",
		Size = Vector3.new(900, 20, 900),
		CFrame = at(o, 0, -10, -40),
		Color = Color3.fromRGB(64, 196, 196),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		Reflectance = 0.3,
	}, folder)

	-- kade en steigers
	decor({
		Name = "Quay",
		Size = Vector3.new(340, 6, 150),
		CFrame = at(o, 0, -2, -110),
		Color = Color3.fromRGB(206, 196, 178),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	}, folder)
	decor({
		Name = "MainPier",
		Size = Vector3.new(60, 4, 320),
		CFrame = at(o, 0, -1, 20),
		Color = Color3.fromRGB(196, 156, 112),
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	for i = 1, 5 do
		for _, side in { -1, 1 } do
			decor({
				Name = "Finger",
				Size = Vector3.new(120, 3, 14),
				CFrame = at(o, side * 90, -1.5, -110 + i * 62),
				Color = Color3.fromRGB(196, 156, 112),
				Material = Enum.Material.WoodPlanks,
				CanCollide = true,
			}, folder)
		end
	end

	-- jachten
	local hulls = { Color3.fromRGB(246, 244, 240), Color3.fromRGB(226, 226, 230), Color3.fromRGB(248, 250, 252) }
	for i = 1, 8 do
		local side = i % 2 == 0 and 1 or -1
		local length = 70 + math.random(0, 60)
		local x = side * (120 + math.random(0, 40))
		local z = -130 + math.random(0, 260)
		local hull = decor({
			Name = "YachtHull",
			Size = Vector3.new(26, 14, length),
			CFrame = at(o, x, 1, z),
			Color = hulls[(i % #hulls) + 1],
			Material = Enum.Material.SmoothPlastic,
			CanCollide = true,
		}, folder)
		Scenery.wedge({
			Name = "YachtBow",
			Size = Vector3.new(26, 14, 26),
			CFrame = at(o, x, 1, z - length / 2 - 13, 180),
			Color = hull.Color,
			Anchored = true,
		}, folder)
		decor({
			Name = "YachtDeck",
			Size = Vector3.new(26, 1.4, length),
			CFrame = at(o, x, 8, z),
			Color = Color3.fromRGB(206, 170, 124),
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		}, folder)
		decor({
			Name = "YachtCabin",
			Size = Vector3.new(19, 12, length * 0.4),
			CFrame = at(o, x, 14, z + length * 0.12),
			Color = hull.Color,
			CanCollide = true,
		}, folder)
		decor({
			Name = "YachtBridge",
			Size = Vector3.new(14, 8, length * 0.2),
			CFrame = at(o, x, 23, z + length * 0.2),
			Color = Color3.fromRGB(96, 130, 150),
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			Reflectance = 0.3,
		}, folder)
		decor({
			Name = "YachtMast",
			Size = Vector3.new(0.8, 26, 0.8),
			CFrame = at(o, x, 38, z + length * 0.2),
			Color = P.metal,
			Material = Enum.Material.Metal,
		}, folder)
	end

	-- havenmeester, palmen, bolders, lampen
	decor({
		Name = "HarbourOffice",
		Size = Vector3.new(60, 26, 40),
		CFrame = at(o, -130, 14, -150),
		Color = Color3.fromRGB(240, 236, 226),
		Material = Enum.Material.Plaster,
		CanCollide = true,
	}, folder)
	decor({
		Name = "OfficeRoof",
		Size = Vector3.new(66, 3, 46),
		CFrame = at(o, -130, 28, -150),
		Color = Color3.fromRGB(186, 90, 72),
	}, folder)
	Scenery.wallText(at(o, -130, 20, -129, 180), 34, 7, "MARINA", Color3.fromRGB(96, 226, 255), folder)
	for i = 1, 8 do
		Scenery.palm(at(o, -150 + i * 40, 1.4, -170), folder)
		decor({
			Name = "Bollard",
			Size = Vector3.new(3, 5, 3),
			CFrame = at(o, -30 + (i % 2) * 60, 2, -120 + i * 34),
			Color = Color3.fromRGB(56, 58, 64),
			Material = Enum.Material.Metal,
		}, folder)
	end
	for i = 1, 6 do
		Scenery.lamppost(at(o, (i % 2 == 0 and 1 or -1) * 34, 1, -140 + i * 56, 0), folder)
	end

	-- pier met vuurtoren en bergen in de verte
	decor({
		Name = "Breakwater",
		Size = Vector3.new(420, 12, 24),
		CFrame = at(o, 0, 0, 220),
		Color = Color3.fromRGB(128, 124, 116),
		Material = Enum.Material.Rock,
		CanCollide = true,
	}, folder)
	decor({
		Name = "Lighthouse",
		Size = Vector3.new(16, 54, 16),
		CFrame = at(o, 190, 30, 220),
		Color = Color3.fromRGB(244, 242, 236),
		CanCollide = true,
	}, folder)
	local beacon = decor({
		Name = "Beacon",
		Size = Vector3.new(12, 8, 12),
		CFrame = at(o, 190, 60, 220),
		Color = Color3.fromRGB(255, 120, 90),
		Material = Enum.Material.Neon,
	}, folder)
	local beaconLight = Instance.new("PointLight")
	beaconLight.Brightness = 3
	beaconLight.Range = 90
	beaconLight.Color = Color3.fromRGB(255, 140, 110)
	beaconLight.Parent = beacon

	for i = 1, 7 do
		decor({
			Name = "Mountain",
			Size = Vector3.new(220 + math.random(0, 160), 150 + math.random(0, 160), 200),
			CFrame = at(o, -600 + i * 190, 40, 520 + math.random(-60, 60)),
			Color = Color3.fromRGB(112, 118, 134):Lerp(Color3.fromRGB(196, 176, 168), math.random()),
			Material = Enum.Material.Rock,
		}, folder)
	end
end

-- ------------------------------------------------------------- 7. orbit ----

function ZoneArt.orbit(folder: Folder, station)
	local o = station.origin

	-- het platform
	decor({
		Name = "Platform",
		Size = Vector3.new(320, 6, 360),
		CFrame = at(o, 0, -3, -40),
		Color = Color3.fromRGB(46, 50, 72),
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	tiles(folder, o, 14, 16, 22, 0.3, Color3.fromRGB(54, 58, 82), Color3.fromRGB(40, 44, 64),
		Enum.Material.Metal)
	decor({
		Name = "PlatformGlow",
		Size = Vector3.new(326, 1, 366),
		CFrame = at(o, 0, -6.4, -40),
		Color = Color3.fromRGB(150, 110, 240),
		Material = Enum.Material.Neon,
		Transparency = 0.25,
	}, folder)

	-- glazen koepel
	local H = 92
	for _, side in { -1, 1 } do
		decor({
			Name = "DomeWall",
			Size = Vector3.new(3, H, 360),
			CFrame = at(o, side * 158, H / 2, -40),
			Color = Color3.fromRGB(140, 180, 220),
			Material = Enum.Material.Glass,
			Transparency = 0.72,
			Reflectance = 0.25,
			CanCollide = true,
		}, folder)
	end
	for _, spec in { { z = 150 }, { z = -230 } } do
		decor({
			Name = "DomeWall",
			Size = Vector3.new(320, H, 3),
			CFrame = at(o, 0, H / 2, spec.z),
			Color = Color3.fromRGB(140, 180, 220),
			Material = Enum.Material.Glass,
			Transparency = 0.72,
			Reflectance = 0.25,
			CanCollide = true,
		}, folder)
	end
	decor({
		Name = "DomeRoof",
		Size = Vector3.new(320, 3, 360),
		CFrame = at(o, 0, H, -40),
		Color = Color3.fromRGB(140, 180, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.8,
		Reflectance = 0.3,
		CanCollide = true,
	}, folder)
	for i = -4, 4 do
		decor({
			Name = "DomeRib",
			Size = Vector3.new(4, H + 4, 4),
			CFrame = at(o, i * 38, H / 2, 150),
			Color = Color3.fromRGB(82, 86, 120),
			Material = Enum.Material.Metal,
		}, folder)
		ceilingLight(folder, at(o, i * 38, H - 4, -40), 340, Color3.fromRGB(170, 150, 255))
	end

	-- de aarde onder het station
	Scenery.ball({
		Name = "Earth",
		Size = Vector3.new(1400, 1400, 1400),
		CFrame = at(o, 0, -1120, 220),
		Color = Color3.fromRGB(46, 104, 180),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	}, folder)
	for i = 1, 16 do
		Scenery.ball({
			Name = "Cloud",
			Size = Vector3.new(160 + math.random(0, 200), 30, 160 + math.random(0, 200)),
			CFrame = at(o, math.random(-520, 520), -460 + math.random(-120, 40), 200 + math.random(-400, 400)),
			Color = Color3.fromRGB(226, 234, 244),
			Transparency = 0.25,
			CanCollide = false,
		}, folder)
	end

	-- sterren
	for i = 1, 90 do
		Scenery.ball({
			Name = "Star",
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = at(o, math.random(-900, 900), math.random(-200, 700), math.random(-900, 900)),
			Color = Color3.fromRGB(255, 255, 240),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
	end

	-- zonnepanelen en ringen buiten de koepel
	for _, side in { -1, 1 } do
		decor({
			Name = "SolarArm",
			Size = Vector3.new(90, 3, 6),
			CFrame = at(o, side * 210, 30, -40),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, folder)
		for i = -1, 1 do
			decor({
				Name = "SolarPanel",
				Size = Vector3.new(70, 1.4, 44),
				CFrame = at(o, side * 280, 30, -40 + i * 50),
				Color = Color3.fromRGB(58, 70, 140),
				Material = Enum.Material.Neon,
				Transparency = 0.15,
			}, folder)
		end
	end
	for i = 1, 3 do
		Scenery.cylinder({
			Name = "Ring",
			Size = Vector3.new(3, 420 + i * 70, 420 + i * 70),
			CFrame = at(o, 0, 40, -40) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(14 * i), 0, 0),
			Color = i % 2 == 0 and P.neonCyan or Color3.fromRGB(180, 110, 240),
			Material = Enum.Material.Neon,
			Transparency = 0.45,
			CanCollide = false,
		}, folder)
	end

	-- hologram-consoles binnen
	for i = 1, 5 do
		local x = -120 + i * 48
		decor({
			Name = "Console",
			Size = Vector3.new(22, 6, 12),
			CFrame = at(o, x, 3, 96),
			Color = Color3.fromRGB(42, 46, 66),
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		decor({
			Name = "Hologram",
			Size = Vector3.new(18, 14, 0.4),
			CFrame = at(o, x, 13, 96),
			Color = Color3.fromRGB(120, 210, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.55,
		}, folder)
	end
	Scenery.wallText(at(o, 0, 60, -226, 180), 90, 18, "ORBIT FINANCE", Color3.fromRGB(190, 140, 255), folder)
end

return ZoneArt
