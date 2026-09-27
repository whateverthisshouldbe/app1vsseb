--!strict
-- Bouwt de hele wereld uit code: de rode loper, acht studio's, het live
-- chart-bord, het leaderboard en de belichting. Zo werkt de place zonder
-- losse modellen en kun je alles in deze module bijstellen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

export type SlotInfo = {
	index: number,
	pedestal: BasePart,
	plate: BasePart,
	pad: BasePart,
	padLabel: TextLabel,
	lockLabel: TextLabel,
	songCFrame: CFrame,
}

export type PlotInfo = {
	index: number,
	cframe: CFrame,
	model: Model,
	color: Color3,
	spawn: CFrame,
	outside: CFrame,
	barrier: BasePart,
	lockButton: BasePart,
	lockPrompt: ProximityPrompt,
	lockLabel: TextLabel,
	signLabel: TextLabel,
	slots: { SlotInfo },
}

export type MapInfo = {
	songStart: Vector3,
	songEnd: Vector3,
	conveyorFolder: Folder,
	plots: { PlotInfo },
	chartBoard: BasePart,
	leaderboard: BasePart,
}

-- Afmetingen van een studio in zijn eigen assenstelsel: de ingang ligt aan
-- de -Z kant, richting de loper.
MapBuilder.PLOT_WIDTH = 48
MapBuilder.PLOT_DEPTH = 60
local WALL_HEIGHT = 16
local FLOOR_TOP = 0.6
local PEDESTAL_TOP = 2.0
local SONG_HEIGHT = 2.6 -- hart van de plaat boven de pedestal

local PLOT_X = { -99, -33, 33, 99 }
local PLOT_Z = 50
local CARPET_LENGTH = 270
local CARPET_WIDTH = 12

local SLOT_COLUMNS = { -16.5, -5.5, 5.5, 16.5 }
local SLOT_ROWS = { -10, -1, 8, 17, 26 }

local FONT = Enum.Font.FredokaOne

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Parent" and key ~= "Shape" then
			(p :: any)[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

local function textLabel(parent: Instance, props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Size = UDim2.fromScale(1, 1)
	for key, value in props do
		(label :: any)[key] = value
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(20, 10, 30)
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function surfaceGui(target: BasePart, face: Enum.NormalId, pixelsPerStud: number?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 40
	gui.LightInfluence = 0
	gui.Parent = target
	return gui
end

local function billboard(target: Instance, size: UDim2, offset: Vector3, maxDistance: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = offset
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = target
	return gui
end

local function buildLighting()
	Lighting.ClockTime = 15.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(70, 60, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 128, 165)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true

	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 14
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(215, 185, 240)
	atmosphere.Decay = Color3.fromRGB(110, 95, 140)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Saturation = 0.2
	color.Contrast = 0.08
	color.Brightness = 0.02
	color.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.05
	rays.Spread = 0.8
	rays.Parent = Lighting
end

local function buildGround(parent: Instance)
	part({
		Name = "Ground",
		Size = Vector3.new(460, 2, 460),
		CFrame = CFrame.new(0, -1, 0),
		Color = Color3.fromRGB(98, 178, 90),
		Material = Enum.Material.Grass,
		Parent = parent,
	})

	-- Onzichtbare randen zodat niemand van de map loopt
	local bounds = { { 175, 0, 0, 2, 120, 240 }, { -175, 0, 0, 2, 120, 240 }, { 0, 0, 105, 360, 120, 2 }, { 0, 0, -105, 360, 120, 2 } }
	for _, b in bounds do
		part({
			Name = "Boundary",
			Size = Vector3.new(b[4], b[5], b[6]),
			CFrame = CFrame.new(b[1], 60, b[3]),
			Transparency = 1,
			Parent = parent,
		})
	end

	local lobbySpawn = Instance.new("SpawnLocation")
	lobbySpawn.Name = "LobbySpawn"
	lobbySpawn.Anchored = true
	lobbySpawn.Size = Vector3.new(6, 1, 6)
	lobbySpawn.CFrame = CFrame.new(0, 0.5, 14)
	lobbySpawn.Transparency = 1
	lobbySpawn.CanCollide = false
	lobbySpawn.Neutral = true
	lobbySpawn.Duration = 0
	lobbySpawn.Parent = parent
end

local function buildArch(parent: Instance, x: number, facing: number, text: string, color: Color3)
	local model = Instance.new("Model")
	model.Name = "Arch"
	for _, z in { -9, 9 } do
		part({
			Name = "Pillar",
			Size = Vector3.new(3, 22, 3),
			CFrame = CFrame.new(x, 11, z),
			Color = Color3.fromRGB(40, 30, 55),
			Parent = model,
		})
		part({
			Name = "Glow",
			Size = Vector3.new(3.2, 0.5, 3.2),
			CFrame = CFrame.new(x, 21.5, z),
			Color = color,
			Material = Enum.Material.Neon,
			Parent = model,
		})
	end
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(21, 5, 1.5),
		CFrame = CFrame.new(x, 24, 0) * CFrame.Angles(0, facing, 0),
		Color = Color3.fromRGB(25, 18, 35),
		Parent = model,
	})
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = surfaceGui(sign, face, 30)
		textLabel(gui, { Text = text, TextColor3 = color })
	end
	model.Parent = parent
end

local function buildCarpet(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "RedCarpet"
	part({
		Name = "Carpet",
		Size = Vector3.new(CARPET_LENGTH, 0.4, CARPET_WIDTH),
		CFrame = CFrame.new(0, 0.2, 0),
		Color = Color3.fromRGB(190, 20, 45),
		Material = Enum.Material.Fabric,
		Parent = model,
	})
	for _, z in { -1, 1 } do
		part({
			Name = "Rail",
			Size = Vector3.new(CARPET_LENGTH, 0.5, 0.5),
			CFrame = CFrame.new(0, 0.45, z * (CARPET_WIDTH / 2 + 0.25)),
			Color = Color3.fromRGB(255, 200, 60),
			Material = Enum.Material.Neon,
			Parent = model,
		})
	end
	-- Spots langs de loper die omhoog schijnen
	for x = -120, 120, 40 do
		for _, z in { -8.5, 8.5 } do
			local lamp = part({
				Name = "Spot",
				Size = Vector3.new(1.6, 1.2, 1.6),
				CFrame = CFrame.new(x, 0.6, z),
				Color = Color3.fromRGB(255, 240, 200),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = model,
			})
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Top
			light.Angle = 40
			light.Range = 30
			light.Brightness = 3
			light.Color = Color3.fromRGB(255, 220, 170)
			light.Parent = lamp
		end
	end
	model.Parent = parent

	buildArch(parent, -CARPET_LENGTH / 2 - 3, -math.pi / 2, "🎤 NEW DROPS", Color3.fromRGB(255, 90, 200))
	buildArch(parent, CARPET_LENGTH / 2 + 3, math.pi / 2, "📼 OLD NEWS", Color3.fromRGB(90, 200, 255))
end

local function buildBoard(parent: Instance, name: string, size: Vector3, cframe: CFrame, legs: boolean): Part
	local board = part({
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = Color3.fromRGB(18, 12, 28),
		Parent = parent,
	})
	part({
		Name = name .. "Frame",
		Size = size + Vector3.new(1, 1, -0.2),
		CFrame = cframe,
		Color = Color3.fromRGB(255, 70, 170),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	if legs then
		local bottom = cframe.Position.Y - size.Y / 2
		for _, side in { -1, 1 } do
			local offset = cframe.RightVector * side * (size.X / 2 - 2)
			part({
				Name = "Leg",
				Size = Vector3.new(1.5, bottom, 1.5),
				CFrame = CFrame.new(cframe.Position.X + offset.X, bottom / 2, cframe.Position.Z + offset.Z),
				Color = Color3.fromRGB(40, 30, 55),
				Parent = parent,
			})
		end
	end
	return board
end

local function buildHowToPlay(board: BasePart)
	local gui = surfaceGui(board, Enum.NormalId.Front, 25)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, -40, 1, -40)
	frame.Position = UDim2.fromOffset(20, 20)
	frame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local lines: { { any } } = {
		{ "🎵 HOW TO PLAY", Color3.fromRGB(255, 200, 60), 0.16 },
		{ "1. Buy songs on the red carpet", Color3.new(1, 1, 1), 0.1 },
		{ "2. More streams = more $$$ every second", Color3.new(1, 1, 1), 0.1 },
		{ "3. Walk over the green pads to collect", Color3.new(1, 1, 1), 0.1 },
		{ "4. Hold E on someone else's song to STEAL it", Color3.fromRGB(255, 110, 110), 0.1 },
		{ "5. Bring it to your studio before you get hit!", Color3.new(1, 1, 1), 0.1 },
		{ "6. Press the red button to lock your studio", Color3.new(1, 1, 1), 0.1 },
		{ "7. Smack thieves with your guitar 🎸", Color3.new(1, 1, 1), 0.1 },
	}
	for i, line in lines do
		textLabel(frame, {
			Text = line[1],
			TextColor3 = line[2],
			Size = UDim2.fromScale(1, line[3]),
			LayoutOrder = i,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
end

local function buildCenterpiece(parent: Instance): Part
	local model = Instance.new("Model")
	model.Name = "LiveChart"
	for _, z in { -11, 11 } do
		part({
			Name = "Pillar",
			Size = Vector3.new(2, 33, 2),
			CFrame = CFrame.new(0, 16.5, z),
			Color = Color3.fromRGB(40, 30, 55),
			Parent = model,
		})
	end
	part({
		Name = "Beam",
		Size = Vector3.new(2, 2, 24),
		CFrame = CFrame.new(0, 33, 0),
		Color = Color3.fromRGB(40, 30, 55),
		Parent = model,
	})
	local board = buildBoard(model, "ChartBoard", Vector3.new(34, 18, 0.8), CFrame.new(0, 22.5, 0), false)
	model.Parent = parent
	return board
end

-- Laag genoeg (7) dat je er niet vanaf over een muur van 16 kunt springen
local function buildSpeaker(parent: Instance, cframe: CFrame, color: Color3)
	part({
		Name = "Speaker",
		Size = Vector3.new(4.5, 7, 4),
		CFrame = cframe * CFrame.new(0, 3.5, 0),
		Color = Color3.fromRGB(22, 20, 28),
		Parent = parent,
	})
	for _, y in { 1.9, 5.1 } do
		part({
			Name = "Woofer",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 2.8, 2.8),
			CFrame = cframe * CFrame.new(0, y, -2.1) * CFrame.Angles(0, math.pi / 2, 0),
			Color = color,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function buildPlot(parent: Instance, index: number, cframe: CFrame): PlotInfo
	local color = rgb(Config.StudioColors[index])
	local model = Instance.new("Model")
	model.Name = "Studio" .. index
	model:SetAttribute("PlotIndex", index)

	local function at(x: number, y: number, z: number): CFrame
		return cframe * CFrame.new(x, y, z)
	end

	local w, d = MapBuilder.PLOT_WIDTH, MapBuilder.PLOT_DEPTH
	part({
		Name = "Floor",
		Size = Vector3.new(w, FLOOR_TOP, d),
		CFrame = at(0, FLOOR_TOP / 2, 0),
		Color = Color3.fromRGB(38, 34, 50),
		Parent = model,
	})
	part({
		Name = "Doormat",
		Size = Vector3.new(w, 0.1, 0.8),
		CFrame = at(0, FLOOR_TOP + 0.05, -d / 2 + 0.4),
		Color = color,
		Material = Enum.Material.Neon,
		Parent = model,
	})
	part({
		Name = "Path",
		Size = Vector3.new(14, 0.2, 14),
		CFrame = at(0, 0.1, -d / 2 - 7),
		Color = Color3.fromRGB(205, 200, 215),
		Material = Enum.Material.Concrete,
		Parent = model,
	})

	-- Muren, met de voorkant open voor de laserpoort
	local wallColor = Color3.fromRGB(58, 48, 78)
	part({ Name = "WallLeft", Size = Vector3.new(1, WALL_HEIGHT, d + 1), CFrame = at(-w / 2 - 0.5, WALL_HEIGHT / 2, 0), Color = wallColor, Parent = model })
	part({ Name = "WallRight", Size = Vector3.new(1, WALL_HEIGHT, d + 1), CFrame = at(w / 2 + 0.5, WALL_HEIGHT / 2, 0), Color = wallColor, Parent = model })
	part({ Name = "WallBack", Size = Vector3.new(w + 2, WALL_HEIGHT, 1), CFrame = at(0, WALL_HEIGHT / 2, d / 2 + 0.5), Color = wallColor, Parent = model })
	for _, x in { -w / 2 - 0.5, w / 2 + 0.5 } do
		part({
			Name = "Trim",
			Size = Vector3.new(1.2, 0.4, d + 1),
			CFrame = at(x, WALL_HEIGHT + 0.2, 0),
			Color = color,
			Material = Enum.Material.Neon,
			Parent = model,
		})
		part({
			Name = "FrontPillar",
			Size = Vector3.new(1.8, WALL_HEIGHT + 1, 1.8),
			CFrame = at(x, (WALL_HEIGHT + 1) / 2, -d / 2 - 0.5),
			Color = Color3.fromRGB(30, 26, 40),
			Parent = model,
		})
	end
	part({
		Name = "TrimBack",
		Size = Vector3.new(w + 2, 0.4, 1.2),
		CFrame = at(0, WALL_HEIGHT + 0.2, d / 2 + 0.5),
		Color = color,
		Material = Enum.Material.Neon,
		Parent = model,
	})
	part({
		Name = "Header",
		Size = Vector3.new(w + 2, 2, 1.2),
		CFrame = at(0, WALL_HEIGHT, -d / 2 - 0.5),
		Color = Color3.fromRGB(30, 26, 40),
		Parent = model,
	})

	local sign = part({
		Name = "Sign",
		Size = Vector3.new(32, 5, 1),
		CFrame = at(0, WALL_HEIGHT + 3.5, -d / 2 - 0.5),
		Color = Color3.fromRGB(20, 16, 28),
		Parent = model,
	})
	part({
		Name = "SignGlow",
		Size = Vector3.new(33, 6, 0.8),
		CFrame = at(0, WALL_HEIGHT + 3.5, -d / 2 - 0.4),
		Color = color,
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local signLabel = textLabel(surfaceGui(sign, Enum.NormalId.Front, 30), { Text = "EMPTY STUDIO", TextColor3 = color })

	local barrierHeight = WALL_HEIGHT - 1 - FLOOR_TOP
	local barrier = part({
		Name = "Barrier",
		Size = Vector3.new(w, barrierHeight, 0.6),
		CFrame = at(0, FLOOR_TOP + barrierHeight / 2, -d / 2 - 0.3),
		Color = Color3.fromRGB(255, 40, 60),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
		Parent = model,
	})

	-- Lock-knop net binnen de ingang
	local buttonBase = part({
		Name = "LockBase",
		Size = Vector3.new(3, 2.4, 3),
		CFrame = at(19, FLOOR_TOP + 1.2, -24),
		Color = Color3.fromRGB(30, 26, 40),
		Parent = model,
	})
	local lockButton = part({
		Name = "LockButton",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 2.6, 2.6),
		CFrame = buttonBase.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(255, 40, 60),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.Name = "LockPrompt"
	lockPrompt.ActionText = "Lock Studio"
	lockPrompt.ObjectText = "Laser Lock"
	lockPrompt.HoldDuration = 0
	lockPrompt.MaxActivationDistance = 10
	lockPrompt.RequiresLineOfSight = false
	lockPrompt:SetAttribute("Role", "Owner")
	lockPrompt:SetAttribute("OwnerId", 0)
	lockPrompt:AddTag("RolePrompt")
	lockPrompt.Parent = lockButton
	local lockGui = billboard(buttonBase, UDim2.fromScale(7, 2), Vector3.new(0, 4.5, 0), 80)
	local lockLabel = textLabel(lockGui, { Text = "🔓 OPEN", TextColor3 = Color3.fromRGB(120, 255, 140) })

	-- Pedestals met een ophaalpad ervoor
	local slots: { SlotInfo } = {}
	for row, z in SLOT_ROWS do
		for column, x in SLOT_COLUMNS do
			local slotIndex = (row - 1) * #SLOT_COLUMNS + column
			local pedestal = part({
				Name = "Pedestal" .. slotIndex,
				Size = Vector3.new(6, PEDESTAL_TOP - FLOOR_TOP, 6),
				CFrame = at(x, (PEDESTAL_TOP + FLOOR_TOP) / 2, z),
				Color = Color3.fromRGB(28, 24, 36),
				Parent = model,
			})
			local plate = part({
				Name = "Plate" .. slotIndex,
				Size = Vector3.new(5, 0.1, 5),
				CFrame = at(x, PEDESTAL_TOP + 0.05, z),
				Color = color,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = model,
			})
			local pad = part({
				Name = "Pad" .. slotIndex,
				Size = Vector3.new(4.5, 0.3, 2.4),
				CFrame = at(x, FLOOR_TOP + 0.15, z - 4.5),
				Color = Color3.fromRGB(40, 90, 50),
				Material = Enum.Material.Neon,
				Parent = model,
			})
			local padGui = billboard(pad, UDim2.fromScale(6, 1.4), Vector3.new(0, 1.3, 0), 60)
			local padLabel = textLabel(padGui, { Text = "", TextColor3 = Color3.fromRGB(120, 255, 140) })
			local lockGuiSlot = billboard(pedestal, UDim2.fromScale(6, 1.4), Vector3.new(0, 2, 0), 60)
			local slotLockLabel = textLabel(lockGuiSlot, { Text = "🔒 Rebirth", TextColor3 = Color3.fromRGB(200, 200, 210) })

			slots[slotIndex] = {
				index = slotIndex,
				pedestal = pedestal,
				plate = plate,
				pad = pad,
				padLabel = padLabel,
				lockLabel = slotLockLabel,
				songCFrame = at(x, PEDESTAL_TOP + SONG_HEIGHT, z),
			}
		end
	end

	for _, side in { -1, 1 } do
		buildSpeaker(model, at(side * (w / 2 + 3.5), 0, -d / 2 + 2), color)
	end

	model.Parent = parent

	return {
		index = index,
		cframe = cframe,
		model = model,
		color = color,
		spawn = at(0, FLOOR_TOP + 3, -22),
		outside = at(0, 3, -d / 2 - 8),
		barrier = barrier,
		lockButton = lockButton,
		lockPrompt = lockPrompt,
		lockLabel = lockLabel,
		signLabel = signLabel,
		slots = slots,
	}
end

function MapBuilder.build(): MapInfo
	buildLighting()

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = Workspace

	buildGround(mapFolder)
	buildCarpet(mapFolder)
	local chartBoard = buildCenterpiece(mapFolder)

	local leaderboard = buildBoard(
		mapFolder,
		"Leaderboard",
		Vector3.new(26, 22, 1),
		CFrame.new(155, 16, 0) * CFrame.Angles(0, math.pi / 2, 0),
		true
	)
	local howTo = buildBoard(
		mapFolder,
		"HowToPlay",
		Vector3.new(26, 22, 1),
		CFrame.new(-155, 16, 0) * CFrame.Angles(0, -math.pi / 2, 0),
		true
	)
	buildHowToPlay(howTo)

	local studios = Instance.new("Folder")
	studios.Name = "Studios"
	studios.Parent = Workspace

	local plots: { PlotInfo } = {}
	for i, x in PLOT_X do
		plots[i] = buildPlot(studios, i, CFrame.new(x, 0, PLOT_Z))
	end
	for i, x in PLOT_X do
		local index = #PLOT_X + i
		plots[index] = buildPlot(studios, index, CFrame.new(-x, 0, -PLOT_Z) * CFrame.Angles(0, math.pi, 0))
	end

	local conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "ConveyorSongs"
	conveyorFolder.Parent = Workspace

	local songY = 0.4 + 4.2
	return {
		songStart = Vector3.new(-CARPET_LENGTH / 2 + 5, songY, 0),
		songEnd = Vector3.new(CARPET_LENGTH / 2 - 5, songY, 0),
		conveyorFolder = conveyorFolder,
		plots = plots,
		chartBoard = chartBoard,
		leaderboard = leaderboard,
	}
end

-- Staat een wereldpositie binnen de muren van een studio?
function MapBuilder.isInside(plot: PlotInfo, position: Vector3): boolean
	local localPos = plot.cframe:PointToObjectSpace(position)
	return math.abs(localPos.X) <= MapBuilder.PLOT_WIDTH / 2
		and localPos.Z >= -MapBuilder.PLOT_DEPTH / 2
		and localPos.Z <= MapBuilder.PLOT_DEPTH / 2
		and localPos.Y > -3
		and localPos.Y < 40
end

return MapBuilder
