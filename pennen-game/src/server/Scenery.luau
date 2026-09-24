--!strict
-- Bouwstenen voor de aankleding: gevels met ramen, lantaarns, bomen, banken,
-- luifels, fonteinen, neonborden. Alles met code, geen assets nodig.

local Scenery = {}

Scenery.Palette = {
	asphalt      = Color3.fromRGB(56, 56, 64),
	asphaltLine  = Color3.fromRGB(222, 206, 140),
	sidewalk     = Color3.fromRGB(196, 190, 178),
	curb         = Color3.fromRGB(162, 156, 146),
	grass        = Color3.fromRGB(94, 138, 74),
	brick        = Color3.fromRGB(150, 82, 64),
	plaster      = Color3.fromRGB(232, 216, 190),
	plasterWarm  = Color3.fromRGB(216, 176, 132),
	wood         = Color3.fromRGB(140, 96, 58),
	woodDark     = Color3.fromRGB(96, 64, 40),
	metal        = Color3.fromRGB(148, 152, 160),
	metalDark    = Color3.fromRGB(78, 84, 96),
	glass        = Color3.fromRGB(150, 200, 220),
	windowLit    = Color3.fromRGB(255, 226, 158),
	windowDark   = Color3.fromRGB(70, 92, 112),
	awningA      = Color3.fromRGB(196, 62, 58),
	awningB      = Color3.fromRGB(244, 234, 214),
	teal         = Color3.fromRGB(46, 138, 134),
	neonPink     = Color3.fromRGB(255, 92, 150),
	neonCyan     = Color3.fromRGB(96, 226, 255),
	gold         = Color3.fromRGB(240, 196, 96),
	foliage      = Color3.fromRGB(74, 124, 64),
	foliageLight = Color3.fromRGB(104, 152, 78),
	water        = Color3.fromRGB(64, 156, 196),
	skylineFar   = Color3.fromRGB(104, 112, 134),
}

local P = Scenery.Palette

-- ------------------------------------------------------------- basisdelen --

function Scenery.part(props: { [string]: any }, parent: Instance): Part
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

function Scenery.decor(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = props.CanCollide == nil and false or props.CanCollide
	return Scenery.part(props, parent)
end

function Scenery.wedge(props: { [string]: any }, parent: Instance): WedgePart
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function Scenery.cylinder(props: { [string]: any }, parent: Instance): Part
	props.Shape = Enum.PartType.Cylinder
	return Scenery.part(props, parent)
end

function Scenery.ball(props: { [string]: any }, parent: Instance): Part
	props.Shape = Enum.PartType.Ball
	return Scenery.part(props, parent)
end

-- --------------------------------------------------------------- teksten ---

-- Tekst plat op een muur (blijft leesbaar van veraf, kost geen assets).
function Scenery.wallText(cf: CFrame, width: number, height: number, message: string,
	color: Color3, parent: Instance): Part
	local plate = Scenery.decor({
		Name = "SignPlate",
		Size = Vector3.new(width, height, 0.4),
		CFrame = cf,
		Color = Color3.fromRGB(24, 26, 34),
		Material = Enum.Material.SmoothPlastic,
	}, parent)

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Sign"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(math.floor(width * 20), math.floor(height * 20))
	surface.LightInfluence = 0
	surface.Parent = plate

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = color
	tl.RichText = true
	tl.Text = message
	tl.Parent = surface

	-- randje neon eromheen
	Scenery.decor({
		Name = "SignEdge",
		Size = Vector3.new(width + 0.8, height + 0.8, 0.2),
		CFrame = cf * CFrame.new(0, 0, 0.2),
		Color = color,
		Material = Enum.Material.Neon,
	}, parent)

	return plate
end

function Scenery.floatingText(adornee: BasePart, message: string, offsetY: number, size: number, distance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(16, 4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = distance or 260
	gui.Parent = adornee

	local tl = Instance.new("TextLabel")
	tl.Name = "Text"
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = size
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.RichText = true
	tl.Text = message
	tl.Parent = gui
	return tl
end

-- ----------------------------------------------------------------- gevels --

-- Ramen op een muur. `cf` staat midden op de muur en kijkt naar buiten (+Z).
function Scenery.windows(cf: CFrame, width: number, height: number, cols: number, rows: number,
	litChance: number, parent: Instance)
	local marginX = width / (cols + 1)
	local marginY = height / (rows + 1)
	local paneW = math.min(marginX * 0.78, 6)
	local paneH = math.min(marginY * 0.72, 5)

	for col = 1, cols do
		for row = 1, rows do
			local x = -width / 2 + marginX * col
			local y = -height / 2 + marginY * row
			local lit = math.random() < litChance
			Scenery.decor({
				Name = "Window",
				Size = Vector3.new(paneW, paneH, 0.4),
				CFrame = cf * CFrame.new(x, y, 0.3),
				Color = lit and P.windowLit or P.windowDark,
				Material = lit and Enum.Material.Neon or Enum.Material.Glass,
				Transparency = lit and 0 or 0.35,
				Reflectance = lit and 0 or 0.25,
			}, parent)
			-- kozijn
			Scenery.decor({
				Name = "Frame",
				Size = Vector3.new(paneW + 0.7, paneH + 0.7, 0.25),
				CFrame = cf * CFrame.new(x, y, 0.15),
				Color = P.plaster:Lerp(Color3.new(0, 0, 0), 0.35),
			}, parent)
		end
	end
end

-- Winkelpui: grote ruit met deur in het midden.
function Scenery.storefront(cf: CFrame, width: number, height: number, parent: Instance)
	Scenery.decor({
		Name = "Glass",
		Size = Vector3.new(width, height, 0.4),
		CFrame = cf * CFrame.new(0, height / 2, 0.2),
		Color = P.glass,
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Reflectance = 0.3,
	}, parent)
	Scenery.decor({
		Name = "Door",
		Size = Vector3.new(6, height * 0.72, 0.5),
		CFrame = cf * CFrame.new(0, height * 0.36, 0.35),
		Color = P.woodDark,
		Material = Enum.Material.Wood,
	}, parent)
	Scenery.decor({
		Name = "DoorHandle",
		Size = Vector3.new(0.3, 2.4, 0.3),
		CFrame = cf * CFrame.new(1.8, height * 0.36, 0.7),
		Color = P.gold,
		Material = Enum.Material.Metal,
	}, parent)
	-- stijlen
	for _, x in { -width / 2 + 0.4, width / 2 - 0.4 } do
		Scenery.decor({
			Name = "Mullion",
			Size = Vector3.new(0.8, height, 0.8),
			CFrame = cf * CFrame.new(x, height / 2, 0.3),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
	end
end

-- Gestreepte luifel boven een pui.
function Scenery.awning(cf: CFrame, width: number, depth: number, colorA: Color3, colorB: Color3, parent: Instance)
	local stripes = math.max(4, math.floor(width / 3))
	local stripeW = width / stripes
	for i = 1, stripes do
		local x = -width / 2 + stripeW * (i - 0.5)
		Scenery.decor({
			Name = "Awning",
			Size = Vector3.new(stripeW, 0.4, depth),
			CFrame = cf * CFrame.new(x, 0, depth / 2) * CFrame.Angles(math.rad(-18), 0, 0),
			Color = (i % 2 == 0) and colorA or colorB,
			Material = Enum.Material.Fabric,
		}, parent)
	end
	-- afhangende rand
	Scenery.decor({
		Name = "AwningTrim",
		Size = Vector3.new(width, 1.4, 0.3),
		CFrame = cf * CFrame.new(0, -depth * 0.32, depth),
		Color = colorA,
		Material = Enum.Material.Fabric,
	}, parent)
end

-- ------------------------------------------------------------ straatmeubel --

function Scenery.lamppost(cf: CFrame, parent: Instance)
	Scenery.decor({
		Name = "LampBase",
		Size = Vector3.new(2.2, 1.2, 2.2),
		CFrame = cf * CFrame.new(0, 0.6, 0),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, parent)
	Scenery.decor({
		Name = "LampPole",
		Size = Vector3.new(0.8, 16, 0.8),
		CFrame = cf * CFrame.new(0, 8, 0),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, parent)
	Scenery.decor({
		Name = "LampArm",
		Size = Vector3.new(4, 0.6, 0.6),
		CFrame = cf * CFrame.new(1.6, 15.6, 0),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, parent)
	local head = Scenery.decor({
		Name = "LampHead",
		Size = Vector3.new(3, 1.2, 2),
		CFrame = cf * CFrame.new(3.2, 15, 0),
		Color = P.windowLit,
		Material = Enum.Material.Neon,
	}, parent)
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 26
	light.Color = Color3.fromRGB(255, 226, 170)
	light.Parent = head
end

function Scenery.tree(cf: CFrame, scale: number, parent: Instance)
	Scenery.decor({
		Name = "Trunk",
		Size = Vector3.new(1.8 * scale, 9 * scale, 1.8 * scale),
		CFrame = cf * CFrame.new(0, 4.5 * scale, 0),
		Color = P.woodDark,
		Material = Enum.Material.Wood,
	}, parent)
	local tops = {
		{ offset = Vector3.new(0, 11 * scale, 0), size = 9 * scale, color = P.foliage },
		{ offset = Vector3.new(2.4 * scale, 9 * scale, 1.2 * scale), size = 6.5 * scale, color = P.foliageLight },
		{ offset = Vector3.new(-2.2 * scale, 9.5 * scale, -1.4 * scale), size = 6 * scale, color = P.foliage },
	}
	for _, top in tops do
		Scenery.ball({
			Name = "Leaves",
			Size = Vector3.new(top.size, top.size, top.size),
			CFrame = cf * CFrame.new(top.offset),
			Color = top.color,
			Material = Enum.Material.Grass,
		}, parent)
	end
end

function Scenery.bench(cf: CFrame, parent: Instance)
	Scenery.decor({
		Name = "BenchSeat",
		Size = Vector3.new(10, 0.6, 3),
		CFrame = cf * CFrame.new(0, 2.4, 0),
		Color = P.wood,
		Material = Enum.Material.WoodPlanks,
	}, parent)
	Scenery.decor({
		Name = "BenchBack",
		Size = Vector3.new(10, 3, 0.6),
		CFrame = cf * CFrame.new(0, 3.9, -1.2),
		Color = P.wood,
		Material = Enum.Material.WoodPlanks,
	}, parent)
	for _, x in { -4.2, 4.2 } do
		Scenery.decor({
			Name = "BenchLeg",
			Size = Vector3.new(0.5, 2.4, 2.8),
			CFrame = cf * CFrame.new(x, 1.2, 0),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
	end
end

function Scenery.planter(cf: CFrame, parent: Instance)
	Scenery.decor({
		Name = "PlanterBox",
		Size = Vector3.new(7, 3, 7),
		CFrame = cf * CFrame.new(0, 1.5, 0),
		Color = P.plasterWarm,
		Material = Enum.Material.Concrete,
	}, parent)
	Scenery.decor({
		Name = "PlanterSoil",
		Size = Vector3.new(6, 0.6, 6),
		CFrame = cf * CFrame.new(0, 3.1, 0),
		Color = Color3.fromRGB(78, 58, 44),
	}, parent)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		Scenery.ball({
			Name = "Bush",
			Size = Vector3.new(3.4, 3.4, 3.4),
			CFrame = cf * CFrame.new(math.cos(angle) * 1.6, 4, math.sin(angle) * 1.6),
			Color = i % 2 == 0 and P.foliage or P.foliageLight,
			Material = Enum.Material.Grass,
		}, parent)
	end
end

function Scenery.crate(cf: CFrame, size: number, parent: Instance)
	Scenery.decor({
		Name = "Crate",
		Size = Vector3.new(size, size, size),
		CFrame = cf * CFrame.new(0, size / 2, 0),
		Color = P.wood,
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, parent)
	Scenery.decor({
		Name = "CrateBand",
		Size = Vector3.new(size + 0.2, 0.5, size + 0.2),
		CFrame = cf * CFrame.new(0, size * 0.75, 0),
		Color = P.woodDark,
	}, parent)
end

function Scenery.trashcan(cf: CFrame, parent: Instance)
	Scenery.cylinder({
		Name = "Bin",
		Size = Vector3.new(4.5, 3.2, 3.2),
		CFrame = cf * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.metalDark,
		Material = Enum.Material.Metal,
	}, parent)
end

function Scenery.hedge(cf: CFrame, width: number, parent: Instance)
	Scenery.decor({
		Name = "Hedge",
		Size = Vector3.new(width, 4, 3),
		CFrame = cf * CFrame.new(0, 2, 0),
		Color = P.foliage,
		Material = Enum.Material.Grass,
	}, parent)
end

function Scenery.fountain(cf: CFrame, parent: Instance)
	Scenery.cylinder({
		Name = "FountainBasin",
		Size = Vector3.new(3.5, 34, 34),
		CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.plaster,
		Material = Enum.Material.Marble,
		CanCollide = true,
	}, parent)
	Scenery.cylinder({
		Name = "FountainWater",
		Size = Vector3.new(0.8, 31, 31),
		CFrame = cf * CFrame.new(0, 2.9, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.water,
		Material = Enum.Material.Glass,
		Transparency = 0.35,
	}, parent)
	Scenery.cylinder({
		Name = "FountainStem",
		Size = Vector3.new(9, 5, 5),
		CFrame = cf * CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.plaster,
		Material = Enum.Material.Marble,
	}, parent)
	Scenery.cylinder({
		Name = "FountainBowl",
		Size = Vector3.new(1.4, 14, 14),
		CFrame = cf * CFrame.new(0, 10, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.plaster,
		Material = Enum.Material.Marble,
	}, parent)
	-- een reuzenpen als middelpunt
	Scenery.cylinder({
		Name = "GiantPenBody",
		Size = Vector3.new(26, 4.5, 4.5),
		CFrame = cf * CFrame.new(0, 24, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = P.neonCyan,
		Material = Enum.Material.Metal,
	}, parent)
	Scenery.decor({
		Name = "GiantPenTip",
		Size = Vector3.new(3.4, 6, 3.4),
		CFrame = cf * CFrame.new(0, 9.5, 0),
		Color = Color3.fromRGB(40, 40, 46),
		Material = Enum.Material.Metal,
	}, parent)
	Scenery.decor({
		Name = "GiantPenClip",
		Size = Vector3.new(0.9, 9, 0.9),
		CFrame = cf * CFrame.new(2.4, 31, 0),
		Color = P.gold,
		Material = Enum.Material.Metal,
	}, parent)
end

-- ------------------------------------------------------------- achtergrond --

-- Stadsblokken op de achtergrond: geven de straat diepte zonder dat je er
-- kunt komen. `opts` regelt hoogte en kleur, zodat de blokken dicht bij de
-- straat laag en warm zijn en ver weg hoog en koel.
function Scenery.skyline(origin: Vector3, spacing: number, count: number, facing: number,
	parent: Instance, opts: { minHeight: number, maxHeight: number, cool: number, jitter: number, axis: string? }?)
	local o = opts or { minHeight = 40, maxHeight = 90, cool = 0.2, jitter = 12, axis = "z" }
	local alongX = o.axis == "x"
	local tints = { P.brick, P.plaster, P.plasterWarm, P.teal, P.metalDark, Color3.fromRGB(148, 120, 150) }

	for i = 1, count do
		local height = o.minHeight + math.random() * (o.maxHeight - o.minHeight)
		local width = 30 + math.random() * 24
		local depth = 30 + math.random() * 20
		local step = (i - 1) * spacing
		local x = origin.X + (alongX and step or 0) + math.random(-o.jitter, o.jitter)
		local z = origin.Z - (alongX and 0 or step) + math.random(-o.jitter, o.jitter)
		local tint = tints[math.random(#tints)]
		local color = tint:Lerp(P.skylineFar, o.cool)

		local block = Scenery.decor({
			Name = "CityBlock",
			Size = Vector3.new(width, height, depth),
			CFrame = CFrame.new(x, height / 2, z),
			Color = color,
			Material = Enum.Material.Brick,
			CanCollide = true,
		}, parent)
		Scenery.windows(
			block.CFrame * CFrame.Angles(0, math.rad(facing), 0) * CFrame.new(0, 0, depth / 2),
			width * 0.8, height * 0.8,
			math.max(2, math.floor(width / 11)), math.max(2, math.floor(height / 13)),
			0.4, parent
		)
		-- dakrand en een opbouwtje
		Scenery.decor({
			Name = "Cornice",
			Size = Vector3.new(width + 2, 1.6, depth + 2),
			CFrame = CFrame.new(x, height, z),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.25),
		}, parent)
		Scenery.decor({
			Name = "RoofBox",
			Size = Vector3.new(width * 0.28, 5 + math.random() * 7, depth * 0.28),
			CFrame = CFrame.new(x + math.random(-6, 6), height + 4, z + math.random(-6, 6)),
			Color = P.metalDark,
		}, parent)
	end
end

function Scenery.smoke(attachTo: BasePart, size: number, color: Color3)
	local attachment = Instance.new("Attachment")
	attachment.Parent = attachTo

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Rate = 6
	smoke.Lifetime = NumberRange.new(4, 7)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.Size = NumberSequence.new(size)
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Color = ColorSequence.new(color)
	smoke.Acceleration = Vector3.new(1, 3, 0)
	smoke.Parent = attachment
end

function Scenery.sparkle(attachTo: BasePart, color: Color3)
	local attachment = Instance.new("Attachment")
	attachment.Parent = attachTo

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkle"
	sparkles.Rate = 14
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Speed = NumberRange.new(3, 7)
	sparkles.Size = NumberSequence.new(1.2)
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkles.Color = ColorSequence.new(color)
	sparkles.Acceleration = Vector3.new(0, 6, 0)
	sparkles.Parent = attachment
end

return Scenery
