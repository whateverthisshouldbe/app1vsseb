--!strict
-- De acht zones. Elke zone staat op zijn eigen plek in de wereld, heeft zijn
-- eigen architectuur en zijn eigen licht (dat zet de client). De werkplek, de
-- toonbank, de bezoekersplekken en de kiosk staan in elke zone op dezelfde
-- plaats ten opzichte van het middelpunt, zodat spelen overal hetzelfde voelt.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))
local Scenery = require(script.Parent.Scenery)

local Zones = {}

local P = Scenery.Palette
local part = Scenery.part
local decor = Scenery.decor

-- vaste plekken binnen een zone
Zones.PRESS = Vector3.new(-46, 0, 26)
Zones.SELL = Vector3.new(40, 0, 26)
Zones.COUNTER = Vector3.new(52, 0, 26)
Zones.SPOT = Vector3.new(62, 0, 26)
Zones.VISITORS = { Vector3.new(-14, 0, -18), Vector3.new(6, 0, -24), Vector3.new(26, 0, -14) }
Zones.KIOSK_Z = -76
Zones.REBIRTH = Vector3.new(0, 0, -112)
Zones.PET = Vector3.new(74, 0, -76)
Zones.BOARDS = { Vector3.new(-52, 16, -124), Vector3.new(52, 16, -124) }

local function at(origin: Vector3, offset: Vector3, yawDeg: number?): CFrame
	local cf = CFrame.new(origin + offset)
	if yawDeg then
		cf = cf * CFrame.Angles(0, math.rad(yawDeg), 0)
	end
	return cf
end

local function pad(name: string, cf: CFrame, size: Vector3, color: Color3, label: string,
	labelSize: number, distance: number, parent: Instance): Part
	local p = part({
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	}, parent)
	if label ~= "" then
		Scenery.floatingText(p, label, size.Y / 2 + 3.5, labelSize, distance)
	end
	return p
end

-- ---------------------------------------------------------- vaste inrichting

-- Werkbank, toonbank, bezoekersplekken: in elke zone hetzelfde, maar in de
-- kleuren en materialen van die zone.
function Zones.fixtures(folder: Folder, station, style: { bench: Color3, wood: Color3, metal: Color3 })
	local o = station.origin

	-- werkplek
	local bench = decor({
		Name = "WorkBench",
		Size = Vector3.new(16, 5, 11),
		CFrame = at(o, Zones.PRESS + Vector3.new(-12, 3.9, 0)),
		Color = style.bench,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	decor({
		Name = "PressArm",
		Size = Vector3.new(4, 9, 4),
		CFrame = at(o, Zones.PRESS + Vector3.new(-16, 10.9, 0)),
		Color = style.metal,
		Material = Enum.Material.Metal,
	}, folder)
	decor({
		Name = "PressHead",
		Size = Vector3.new(7, 2.4, 7),
		CFrame = at(o, Zones.PRESS + Vector3.new(-14, 7.5, 0)),
		Color = station.pen.color,
		Material = Enum.Material.Metal,
	}, folder)
	Scenery.floatingText(bench, "<b>PENNEN MAKEN</b>", 6, 15, 60)

	pad("Press_" .. station.key, at(o, Zones.PRESS + Vector3.new(0, 2, 0)), Vector3.new(16, 0.6, 14),
		Color3.fromRGB(90, 190, 255), "ga hierop staan", 13, 42, folder)

	-- toonbank
	local counter = decor({
		Name = "Counter",
		Size = Vector3.new(7, 5, 20),
		CFrame = at(o, Zones.COUNTER + Vector3.new(0, 3.9, 0)),
		Color = style.wood,
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	}, folder)
	decor({
		Name = "CounterTop",
		Size = Vector3.new(9, 0.6, 22),
		CFrame = at(o, Zones.COUNTER + Vector3.new(0, 6.5, 0)),
		Color = style.metal,
		Material = Enum.Material.Metal,
	}, folder)
	Scenery.floatingText(counter, "<b>TOONBANK</b>", 6, 15, 60)

	pad("Sell_" .. station.key, at(o, Zones.SELL + Vector3.new(0, 2, 0)), Vector3.new(14, 0.6, 20),
		Color3.fromRGB(120, 255, 150), "verkopen", 13, 42, folder)

	part({
		Name = "Spot_" .. station.key,
		Size = Vector3.new(4, 0.4, 4),
		CFrame = at(o, Zones.SPOT + Vector3.new(0, 1.6, 0), -90),
		Transparency = 1,
		CanCollide = false,
	}, folder)

	-- uitstalrek naast de toonbank
	decor({
		Name = "DisplayRack",
		Size = Vector3.new(4, 9, 12),
		CFrame = at(o, Zones.COUNTER + Vector3.new(6, 5.9, -16)),
		Color = style.wood,
		Material = Enum.Material.Wood,
		CanCollide = true,
	}, folder)
	for i = 1, 6 do
		Scenery.cylinder({
			Name = "RackPen",
			Size = Vector3.new(6, 0.9, 0.9),
			CFrame = at(o, Zones.COUNTER + Vector3.new(4, 7 + (i % 2) * 3, -21 + i * 1.6))
				* CFrame.Angles(0, 0, math.rad(80)),
			Color = i % 3 == 0 and P.neonPink or (i % 3 == 1 and P.gold or P.neonCyan),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
	end

	-- bezoekersplekken
	for slot, offset in Zones.VISITORS do
		part({
			Name = string.format("VisitorSpot%d_%s", slot, station.key),
			Size = Vector3.new(4, 0.4, 4),
			CFrame = at(o, offset + Vector3.new(0, 1.6, 0), 180),
			Transparency = 1,
			CanCollide = false,
		}, folder)
	end
end

-- Kiosk met upgrades, rebirth en mascottes: elke zone heeft zijn eigen set,
-- zodat je nooit hoeft terug te reizen voor een upgrade.
function Zones.services(folder: Folder, station, style: { stand: Color3, accent: Color3 })
	local o = station.origin
	local spacing = 24
	local startX = -((#Config.Upgrades - 1) * spacing) / 2

	for i, up in Config.Upgrades do
		local x = startX + (i - 1) * spacing
		decor({
			Name = "KioskBody_" .. up.key,
			Size = Vector3.new(10, 7, 6),
			CFrame = at(o, Vector3.new(x, 4.9, Zones.KIOSK_Z - 10)),
			Color = style.stand,
			Material = Enum.Material.Metal,
			CanCollide = true,
		}, folder)
		Scenery.wallText(at(o, Vector3.new(x, 10, Zones.KIOSK_Z - 13.2), 180), 12, 4, up.name, style.accent, folder)
		pad("UpgradePad_" .. up.key, at(o, Vector3.new(x, 2, Zones.KIOSK_Z)), Vector3.new(12, 0.6, 12),
			P.gold, string.format("<b>%s</b>\n%s", up.name, up.info), 14, 50, folder)
	end

	-- rebirth
	for _, dx in { -13, 13 } do
		decor({
			Name = "PortalLeg",
			Size = Vector3.new(5, 30, 5),
			CFrame = at(o, Zones.REBIRTH + Vector3.new(dx, 16, -12)),
			Color = Color3.fromRGB(64, 40, 92),
			Material = Enum.Material.Marble,
			CanCollide = true,
		}, folder)
	end
	decor({
		Name = "PortalTop",
		Size = Vector3.new(31, 5, 5),
		CFrame = at(o, Zones.REBIRTH + Vector3.new(0, 33, -12)),
		Color = Color3.fromRGB(64, 40, 92),
		Material = Enum.Material.Marble,
	}, folder)
	local veil = decor({
		Name = "PortalVeil",
		Size = Vector3.new(21, 28, 1),
		CFrame = at(o, Zones.REBIRTH + Vector3.new(0, 16, -12)),
		Color = Color3.fromRGB(184, 108, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
	}, folder)
	Scenery.sparkle(veil, Color3.fromRGB(214, 160, 255))
	Scenery.wallText(at(o, Zones.REBIRTH + Vector3.new(0, 37, -12), 180), 28, 6, "REBIRTH",
		Color3.fromRGB(214, 160, 255), folder)
	pad("RebirthPad", at(o, Zones.REBIRTH + Vector3.new(0, 2, 0)), Vector3.new(16, 0.6, 12),
		Color3.fromRGB(200, 120, 255), "<b>REBIRTH</b>\n2 seconden blijven staan", 15, 55, folder)

	-- mascottes
	decor({
		Name = "PetStand",
		Size = Vector3.new(12, 7, 18),
		CFrame = at(o, Zones.PET + Vector3.new(14, 4.9, 0)),
		Color = P.teal,
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, folder)
	decor({
		Name = "PetTank",
		Size = Vector3.new(10, 8, 16),
		CFrame = at(o, Zones.PET + Vector3.new(14, 12.4, 0)),
		Color = P.glass,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Reflectance = 0.25,
	}, folder)
	Scenery.wallText(at(o, Zones.PET + Vector3.new(14, 20, 0), 180), 14, 4, "PENNENBAK", P.neonCyan, folder)
	pad("PetPad", at(o, Zones.PET + Vector3.new(0, 2, 0)), Vector3.new(12, 0.6, 14),
		P.neonCyan, "<b>MASCOTTES</b>", 14, 50, folder)

	-- scoreborden
	local titles = { "RIJKSTE VERKOPERS", "MEESTE REBIRTHS" }
	local names = { "Board_cash", "Board_rebirths" }
	for i, offset in Zones.BOARDS do
		Zones.board(folder, names[i], at(o, offset, 180), titles[i], style.accent)
	end
end

function Zones.board(parent: Instance, name: string, cf: CFrame, title: string, accent: Color3)
	for _, dx in { -11, 11 } do
		decor({
			Name = "BoardLeg",
			Size = Vector3.new(2, 14, 2),
			CFrame = cf * CFrame.new(dx, -17, 0),
			Color = P.metalDark,
			Material = Enum.Material.Metal,
		}, parent)
	end
	local stand = decor({
		Name = name,
		Size = Vector3.new(26, 20, 1.6),
		CFrame = cf,
		Color = Color3.fromRGB(22, 24, 32),
	}, parent)
	decor({
		Name = "BoardEdge",
		Size = Vector3.new(27.5, 21.5, 1),
		CFrame = cf * CFrame.new(0, 0, -0.4),
		Color = accent,
		Material = Enum.Material.Neon,
	}, parent)

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Screen"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(520, 400)
	surface.LightInfluence = 0
	surface.MaxDistance = 160
	surface.Parent = stand

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 36
	header.TextColor3 = accent
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

-- Bouwput voor een zone die je nog niet hebt vrijgespeeld.
function Zones.construction(folder: Folder, station)
	local o = station.origin
	local site = Instance.new("Folder")
	site.Name = "Construction"
	site.Parent = folder

	Scenery.fence(at(o, Vector3.new(0, 1, 150)), 300, site)
	Scenery.fence(at(o, Vector3.new(-150, 1, 0), 90), 300, site)
	Scenery.fence(at(o, Vector3.new(150, 1, 0), 90), 300, site)
	Scenery.crane(at(o, Vector3.new(-100, 0, -60)), 80, site)
	Scenery.crane(at(o, Vector3.new(110, 0, 80)), 62, site)
	Scenery.scaffold(at(o, Vector3.new(0, 0, -150), 180), 120, 60, site)

	for i = 1, 10 do
		Scenery.cone(at(o, Vector3.new(-120 + i * 26, 0, 140)), site)
	end
	decor({
		Name = "SiteHut",
		Size = Vector3.new(14, 9, 22),
		CFrame = at(o, Vector3.new(-120, 6.4, 120)),
		Color = Color3.fromRGB(216, 176, 60),
		Material = Enum.Material.Metal,
		CanCollide = true,
	}, site)
	Scenery.wallText(at(o, Vector3.new(0, 22, 148), 180), 40, 14,
		string.format("IN AANBOUW\n<font size=\"34\">%s opent na rebirth %d</font>",
			station.name, station.unlockRebirth), Color3.fromRGB(255, 200, 80), site)
end

return Zones
