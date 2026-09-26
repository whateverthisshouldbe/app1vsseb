--!strict
-- Zet de acht zones neer. Elke zone krijgt zijn eigen architectuur (ZoneArt),
-- daarbovenop overal dezelfde werkplek, toonbank en kiosk (Zones), en een
-- bouwput als je hem nog niet hebt vrijgespeeld.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))
local Scenery = require(script.Parent.Scenery)
local Zones = require(script.Parent.Zones)
local ZoneArt = require(script.Parent.ZoneArt)

local World = {}

local P = Scenery.Palette

-- kleuren van de vaste inrichting, per zone
local STYLES: { [string]: any } = {
	steeg        = { bench = Color3.fromRGB(64, 68, 78), wood = Color3.fromRGB(104, 74, 48), metal = Color3.fromRGB(120, 124, 132), stand = Color3.fromRGB(58, 60, 70), accent = P.neonPink },
	winkelstraat = { bench = Color3.fromRGB(196, 214, 210), wood = Color3.fromRGB(176, 128, 82), metal = Color3.fromRGB(226, 226, 230), stand = Color3.fromRGB(226, 216, 198), accent = Color3.fromRGB(236, 132, 96) },
	zakencentrum = { bench = Color3.fromRGB(96, 102, 116), wood = Color3.fromRGB(120, 96, 72), metal = Color3.fromRGB(176, 180, 190), stand = Color3.fromRGB(150, 156, 168), accent = Color3.fromRGB(96, 226, 255) },
	beursvloer   = { bench = Color3.fromRGB(72, 76, 92), wood = Color3.fromRGB(96, 70, 52), metal = P.gold, stand = Color3.fromRGB(226, 220, 206), accent = P.gold },
	lobby        = { bench = Color3.fromRGB(58, 56, 56), wood = Color3.fromRGB(70, 56, 48), metal = P.gold, stand = Color3.fromRGB(238, 234, 226), accent = P.gold },
	penthouse    = { bench = Color3.fromRGB(206, 172, 128), wood = Color3.fromRGB(186, 146, 104), metal = Color3.fromRGB(236, 230, 220), stand = Color3.fromRGB(226, 216, 196), accent = Color3.fromRGB(255, 196, 120) },
	jachthaven   = { bench = Color3.fromRGB(226, 226, 226), wood = Color3.fromRGB(196, 156, 112), metal = Color3.fromRGB(236, 240, 244), stand = Color3.fromRGB(240, 236, 226), accent = P.neonCyan },
	orbit        = { bench = Color3.fromRGB(52, 56, 80), wood = Color3.fromRGB(64, 60, 86), metal = Color3.fromRGB(150, 110, 240), stand = Color3.fromRGB(46, 50, 72), accent = Color3.fromRGB(190, 140, 255) },
}

-- Basisinstelling; de client past per zone de sfeer aan.
local function setupLighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.ClockTime = 16
	Lighting.GeographicLatitude = 24
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(88, 90, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(132, 134, 144)
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.45
	Lighting.ExposureCompensation = 0.15
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 1200

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
	atmosphere.Name = "PenAtmosphere"
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(202, 199, 194)
	atmosphere.Decay = Color3.fromRGB(106, 112, 125)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.7
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "PenBloom"
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.05
	bloom.Parent = Lighting

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "PenGrade"
	grade.Saturation = 0.12
	grade.Contrast = 0.08
	grade.TintColor = Color3.fromRGB(255, 249, 240)
	grade.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "PenRays"
	rays.Intensity = 0.06
	rays.Spread = 0.9
	rays.Parent = Lighting
end

function World.build(): Folder
	local existing = Workspace:FindFirstChild("PenWorld")
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "PenWorld"
	root.Parent = Workspace

	setupLighting()

	for _, station in Config.Stations do
		local folder = Instance.new("Folder")
		folder.Name = "Station_" .. station.key
		folder.Parent = root

		local builder = (ZoneArt :: any)[station.key]
		if builder then
			builder(folder, station)
		end

		local style = STYLES[station.key] or STYLES.steeg
		Zones.fixtures(folder, station, style)
		Zones.services(folder, station, style)

		if station.unlockRebirth > 0 then
			Zones.construction(folder, station)
		end
	end

	-- je begint in de steeg
	local first = Config.Stations[1]
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PenSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(first.origin + Vector3.new(0, 1.5, 70))
	spawn.Color = Color3.fromRGB(120, 200, 150)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.4
	spawn.Duration = 0
	spawn.Parent = root

	return root
end

-- Alle onderdelen met deze naam: elke zone heeft zijn eigen set platen.
function World.findAll(root: Instance, name: string): { BasePart }
	local out = {}
	for _, item in root:GetDescendants() do
		if item.Name == name and item:IsA("BasePart") then
			table.insert(out, item)
		end
	end
	return out
end

function World.find(root: Instance, name: string): BasePart?
	local all = World.findAll(root, name)
	return all[1]
end

function World.boardBodies(root: Instance, name: string): { TextLabel }
	local out = {}
	for _, item in root:GetDescendants() do
		if item.Name == name then
			local screen = item:FindFirstChild("Screen")
			local body = screen and screen:FindFirstChild("Body")
			if body and body:IsA("TextLabel") then
				table.insert(out, body)
			end
		end
	end
	return out
end

return World
