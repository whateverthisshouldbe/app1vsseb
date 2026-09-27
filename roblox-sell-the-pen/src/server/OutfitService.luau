-- Dresses people. Visitors get a look built from their personality and
-- rarity (the same visitor always looks the same, in the world and in the
-- Index preview), and players wear the suit they bought.
--
-- Outfits are built from welded parts so they always work. A few real
-- catalog items (verified ids) are layered on top; if one ever fails to
-- load, the visitor is simply built without it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Visitors = require(ReplicatedStorage.Shared.Visitors)

local Remotes = ReplicatedStorage.Remotes

local OutfitService = {}

-- Real catalog items, ids verified by hand.
local CATALOG = {
	palHair = 63690008, -- "Pal Hair", the famous bacon hair
	manFace = 86487700, -- "Man Face"
}

local SKIN_TONES = {
	Color3.fromRGB(255, 220, 190),
	Color3.fromRGB(240, 195, 160),
	Color3.fromRGB(215, 160, 120),
	Color3.fromRGB(175, 120, 85),
	Color3.fromRGB(130, 85, 60),
	Color3.fromRGB(95, 60, 45),
}
local HAIR_COLORS = {
	Color3.fromRGB(30, 22, 18),
	Color3.fromRGB(70, 45, 25),
	Color3.fromRGB(120, 75, 35),
	Color3.fromRGB(215, 175, 95),
	Color3.fromRGB(160, 60, 30),
	Color3.fromRGB(200, 200, 205),
}
local GOLD = Color3.fromRGB(255, 200, 60)
local WHITE = Color3.fromRGB(245, 245, 240)
local BLACK = Color3.fromRGB(20, 20, 22)

-- Personality looks. jacket = torso/arm color, pants = legs, extras = the
-- welded pieces added on top.
local LOOKS = {
	tourist = { jackets = { Color3.fromRGB(255, 120, 170), Color3.fromRGB(80, 200, 220), Color3.fromRGB(255, 190, 60) }, pants = { Color3.fromRGB(90, 150, 220), Color3.fromRGB(200, 180, 140) }, hair = { "short", "pal", "cap" }, extras = { "camera", "shades" }, shorts = true },
	plumber = { jackets = { Color3.fromRGB(40, 80, 170) }, pants = { Color3.fromRGB(40, 80, 170) }, hair = { "cap" }, hatColor = Color3.fromRGB(200, 40, 40), extras = { "toolbelt", "mustache" } },
	dentist = { jackets = { WHITE }, pants = { Color3.fromRGB(90, 110, 130) }, hair = { "side", "bald", "short" }, extras = { "coat", "headmirror", "glasses" } },
	mom = { jackets = { Color3.fromRGB(120, 200, 180), Color3.fromRGB(230, 150, 160), Color3.fromRGB(180, 150, 220) }, pants = { Color3.fromRGB(60, 60, 90) }, hair = { "long", "bun" }, extras = { "purse", "pearls" } },
	intern = { jackets = { WHITE }, pants = { Color3.fromRGB(40, 40, 60), Color3.fromRGB(80, 70, 60) }, hair = { "pal", "messy", "short" }, extras = { "looseTie", "lanyard", "coffee" } },
	accountant = { jackets = { Color3.fromRGB(110, 110, 115), Color3.fromRGB(80, 75, 70) }, pants = { Color3.fromRGB(80, 80, 85) }, hair = { "side", "bald" }, extras = { "suit", "glasses", "briefcase" } },
	shoes = { jackets = { Color3.fromRGB(150, 50, 200), Color3.fromRGB(230, 60, 120), Color3.fromRGB(40, 180, 160) }, pants = { BLACK }, hair = { "slick", "mohawk" }, extras = { "suit", "shades", "platforms" } },
	bro = { jackets = { Color3.fromRGB(25, 35, 70), Color3.fromRGB(35, 35, 40) }, pants = { Color3.fromRGB(25, 30, 55) }, hair = { "slick", "spiky" }, extras = { "suit", "aviators", "watch" } },
	swiss = { jackets = { Color3.fromRGB(20, 20, 25) }, pants = { Color3.fromRGB(20, 20, 25) }, hair = { "side", "slick" }, extras = { "suit", "monocle", "briefcase" } },
	duchess = { jackets = { Color3.fromRGB(200, 170, 230), Color3.fromRGB(240, 200, 210), Color3.fromRGB(170, 220, 200) }, pants = nil, hair = { "updo" }, extras = { "dress", "bigHat", "pearls" } },
	oil = { jackets = { Color3.fromRGB(215, 190, 150) }, pants = { Color3.fromRGB(120, 90, 60) }, hair = { "cowboy" }, extras = { "suit", "bolo", "watch", "mustache" } },
	fbi = { jackets = { BLACK }, pants = { BLACK }, hair = { "short", "side" }, extras = { "suit", "shades", "earpiece" } },
	crypto = { jackets = { Color3.fromRGB(35, 35, 40), Color3.fromRGB(60, 60, 70) }, pants = { Color3.fromRGB(90, 90, 100) }, hair = { "beanie" }, extras = { "hood", "neonShades", "chain" } },
	influencer = { jackets = { Color3.fromRGB(255, 170, 210), Color3.fromRGB(255, 240, 150) }, pants = { WHITE }, hair = { "long", "bun" }, extras = { "phone", "shades" } },
	rockstar = { jackets = { BLACK }, pants = { Color3.fromRGB(30, 30, 60) }, hair = { "mohawk", "long" }, extras = { "leather", "guitar", "chain" } },
	prince = { jackets = { Color3.fromRGB(120, 30, 60), Color3.fromRGB(30, 50, 120) }, pants = { Color3.fromRGB(240, 235, 220) }, hair = { "side", "short" }, extras = { "cape", "sash" } },
	wolf = { jackets = { BLACK }, pants = { BLACK }, hair = { "slick" }, extras = { "wolfsuit", "aviators", "watch", "chain" } },
}

-- Player suits (see Config.Suits). The thrift suit leaves your own avatar alone.
OutfitService.SuitStyles = {
	rack = { jacket = Color3.fromRGB(110, 110, 118), pants = Color3.fromRGB(95, 95, 102), shirt = WHITE, tie = Color3.fromRGB(40, 60, 140) },
	tailored = { jacket = Color3.fromRGB(28, 38, 80), pants = Color3.fromRGB(26, 34, 72), shirt = Color3.fromRGB(190, 215, 245), tie = Color3.fromRGB(190, 30, 40), pocket = WHITE },
	silk = { jacket = Color3.fromRGB(22, 22, 26), pants = Color3.fromRGB(22, 22, 26), shirt = Color3.fromRGB(35, 35, 40), tie = GOLD, pocket = GOLD, sheen = true },
	wolfsuit = { jacket = Color3.fromRGB(12, 12, 14), pants = Color3.fromRGB(12, 12, 14), shirt = WHITE, bowtie = BLACK, lapelTrim = GOLD, pocket = GOLD, extras = { "watch", "chain", "aviators" } },
}

-- Building blocks -------------------------------------------------------------

local function piece(model, anchorName, size, offset, color, material, shape)
	local anchor = model:FindFirstChild(anchorName)
	if not anchor then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = "Outfit"
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = anchor.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	part.Parent = model:FindFirstChild("OutfitPieces") or model
	return part
end

local function dims(model, name)
	local part = model:FindFirstChild(name)
	return part and part.Size or Vector3.new(1, 1, 1)
end

local function front(model, name, inset)
	return -dims(model, name).Z / 2 - (inset or 0.03)
end

local function tie(model, color, loose)
	local t = dims(model, "UpperTorso")
	piece(model, "UpperTorso", Vector3.new(0.28, 0.2, 0.08), CFrame.new(0, t.Y * 0.36, front(model, "UpperTorso", 0.05)), color)
	piece(model, "UpperTorso", Vector3.new(0.3, t.Y * 0.62, 0.06), CFrame.new(loose and 0.06 or 0, t.Y * 0.02, front(model, "UpperTorso", 0.05)) * CFrame.Angles(0, 0, loose and 0.15 or 0), color, Enum.Material.Fabric)
end

local function suit(model, style)
	local t = dims(model, "UpperTorso")
	local z = front(model, "UpperTorso", 0.02)
	-- Shirt showing through the jacket, then the two lapels forming a V.
	piece(model, "UpperTorso", Vector3.new(t.X * 0.34, t.Y * 0.9, 0.04), CFrame.new(0, t.Y * 0.05, z), style.shirt or WHITE)
	for side = -1, 1, 2 do
		piece(model, "UpperTorso", Vector3.new(t.X * 0.16, t.Y * 0.62, 0.06), CFrame.new(side * t.X * 0.15, t.Y * 0.18, z - 0.02) * CFrame.Angles(0, 0, side * -0.32), style.lapelTrim or style.jacket)
		piece(model, "UpperTorso", Vector3.new(0.14, 0.14, 0.05), CFrame.new(side * 0.05, -t.Y * 0.28, z - 0.02), style.lapelTrim and GOLD or BLACK, Enum.Material.Metal, Enum.PartType.Ball)
	end
	if style.bowtie then
		for side = -1, 1, 2 do
			piece(model, "UpperTorso", Vector3.new(0.3, 0.22, 0.08), CFrame.new(side * 0.14, t.Y * 0.36, z - 0.06) * CFrame.Angles(0, 0, side * 0.3), style.bowtie)
		end
	elseif style.tie then
		tie(model, style.tie)
	end
	if style.pocket then
		piece(model, "UpperTorso", Vector3.new(0.28, 0.12, 0.05), CFrame.new(-t.X * 0.3, t.Y * 0.2, z - 0.03), style.pocket)
	end
end

local function hair(model, style, color)
	local h = dims(model, "Head")
	local top = h.Y / 2
	if style == "bald" then
		return
	elseif style == "short" or style == "side" or style == "messy" then
		piece(model, "Head", Vector3.new(h.X * 1.04, h.Y * 0.22, h.Z * 1.06), CFrame.new(0, top - h.Y * 0.04, 0.02), color)
		piece(model, "Head", Vector3.new(h.X * 1.04, h.Y * 0.5, h.Z * 0.2), CFrame.new(0, top - h.Y * 0.28, h.Z * 0.46), color)
		if style == "side" then
			piece(model, "Head", Vector3.new(h.X * 0.5, h.Y * 0.12, h.Z * 0.4), CFrame.new(h.X * 0.22, top + h.Y * 0.06, -h.Z * 0.28), color)
		elseif style == "messy" then
			for i = -1, 1 do
				piece(model, "Head", Vector3.new(0.25, 0.3, 0.25), CFrame.new(i * 0.3, top + 0.12, i * 0.1) * CFrame.Angles(0.4 * i, 0, 0.5 * i), color)
			end
		end
	elseif style == "slick" then
		piece(model, "Head", Vector3.new(h.X * 1.05, h.Y * 0.2, h.Z * 1.08), CFrame.new(0, top - h.Y * 0.02, 0.04), color, Enum.Material.Glass)
		piece(model, "Head", Vector3.new(h.X * 1.05, h.Y * 0.55, h.Z * 0.22), CFrame.new(0, top - h.Y * 0.3, h.Z * 0.46), color, Enum.Material.Glass)
		piece(model, "Head", Vector3.new(h.X * 0.9, h.Y * 0.14, h.Z * 0.5), CFrame.new(0, top + h.Y * 0.08, -h.Z * 0.2) * CFrame.Angles(-0.25, 0, 0), color, Enum.Material.Glass)
	elseif style == "spiky" then
		piece(model, "Head", Vector3.new(h.X * 1.04, h.Y * 0.18, h.Z * 1.04), CFrame.new(0, top - h.Y * 0.02, 0.02), color)
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			piece(model, "Head", Vector3.new(0.22, 0.45, 0.22), CFrame.new(math.cos(a) * 0.3, top + 0.15, math.sin(a) * 0.3) * CFrame.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), color)
		end
	elseif style == "mohawk" then
		piece(model, "Head", Vector3.new(0.22, 0.55, h.Z * 1.05), CFrame.new(0, top + 0.18, 0.05), color, Enum.Material.Neon)
	elseif style == "long" then
		piece(model, "Head", Vector3.new(h.X * 1.06, h.Y * 0.22, h.Z * 1.08), CFrame.new(0, top - h.Y * 0.03, 0.03), color)
		piece(model, "Head", Vector3.new(h.X * 1.1, h.Y * 1.5, h.Z * 0.25), CFrame.new(0, -h.Y * 0.15, h.Z * 0.5), color)
		for side = -1, 1, 2 do
			piece(model, "Head", Vector3.new(0.18, h.Y * 1.1, h.Z * 0.6), CFrame.new(side * h.X * 0.54, -h.Y * 0.05, h.Z * 0.15), color)
		end
	elseif style == "bun" or style == "updo" then
		piece(model, "Head", Vector3.new(h.X * 1.05, h.Y * 0.24, h.Z * 1.07), CFrame.new(0, top - h.Y * 0.03, 0.03), color)
		piece(model, "Head", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, top + (style == "updo" and 0.3 or 0.05), h.Z * 0.35), color, nil, Enum.PartType.Ball)
	elseif style == "cap" then
		piece(model, "Head", Vector3.new(h.X * 1.08, h.Y * 0.32, h.Z * 1.08), CFrame.new(0, top - h.Y * 0.02, 0), color)
		piece(model, "Head", Vector3.new(h.X * 0.9, 0.08, h.Z * 0.55), CFrame.new(0, top - h.Y * 0.15, -h.Z * 0.7), color)
	elseif style == "beanie" then
		piece(model, "Head", Vector3.new(h.X * 1.1, h.Y * 0.45, h.Z * 1.1), CFrame.new(0, top - h.Y * 0.06, 0), color, Enum.Material.Fabric)
		piece(model, "Head", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, top + h.Y * 0.2, 0), WHITE, Enum.Material.Fabric, Enum.PartType.Ball)
	elseif style == "cowboy" then
		piece(model, "Head", Vector3.new(0.12, h.X * 2, h.X * 2), CFrame.new(0, top + 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.Material.Fabric, Enum.PartType.Cylinder)
		piece(model, "Head", Vector3.new(h.X * 0.95, h.Y * 0.45, h.Z * 0.95), CFrame.new(0, top + h.Y * 0.22, 0), color, Enum.Material.Fabric)
		piece(model, "Head", Vector3.new(h.X * 0.97, 0.1, h.Z * 0.97), CFrame.new(0, top + 0.08, 0), Color3.fromRGB(60, 40, 25))
	end
end

local function extra(model, name, look)
	local h = dims(model, "Head")
	local t = dims(model, "UpperTorso")
	local faceZ = front(model, "Head", 0.02)
	if name == "shades" or name == "aviators" or name == "neonShades" then
		local lens = name == "neonShades" and Color3.fromRGB(0, 255, 200) or BLACK
		local material = name == "neonShades" and Enum.Material.Neon or Enum.Material.Glass
		for side = -1, 1, 2 do
			piece(model, "Head", Vector3.new(0.4, name == "aviators" and 0.3 or 0.22, 0.06), CFrame.new(side * 0.24, h.Y * 0.1, faceZ), lens, material)
		end
		piece(model, "Head", Vector3.new(0.9, 0.05, 0.05), CFrame.new(0, h.Y * 0.18, faceZ), name == "aviators" and GOLD or BLACK, Enum.Material.Metal)
	elseif name == "glasses" then
		for side = -1, 1, 2 do
			local lens = piece(model, "Head", Vector3.new(0.34, 0.26, 0.04), CFrame.new(side * 0.24, h.Y * 0.1, faceZ), Color3.fromRGB(180, 220, 240), Enum.Material.Glass)
			if lens then
				lens.Transparency = 0.4
			end
		end
		piece(model, "Head", Vector3.new(0.84, 0.05, 0.05), CFrame.new(0, h.Y * 0.2, faceZ), BLACK)
	elseif name == "monocle" then
		piece(model, "Head", Vector3.new(0.05, 0.3, 0.3), CFrame.new(0.24, h.Y * 0.1, faceZ) * CFrame.Angles(0, math.pi / 2, 0), GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
	elseif name == "headmirror" then
		piece(model, "Head", Vector3.new(0.06, 0.45, 0.45), CFrame.new(0, h.Y * 0.38, faceZ) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(220, 230, 240), Enum.Material.Glass, Enum.PartType.Cylinder)
	elseif name == "mustache" then
		piece(model, "Head", Vector3.new(0.55, 0.12, 0.06), CFrame.new(0, -h.Y * 0.12, faceZ), Color3.fromRGB(60, 40, 25))
	elseif name == "earpiece" then
		piece(model, "Head", Vector3.new(0.1, 0.2, 0.1), CFrame.new(h.X * 0.52, 0, 0), BLACK)
	elseif name == "bigHat" then
		piece(model, "Head", Vector3.new(0.1, h.X * 2.4, h.X * 2.4), CFrame.new(0, h.Y * 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), look.jacket, Enum.Material.Fabric, Enum.PartType.Cylinder)
		piece(model, "Head", Vector3.new(0.4, h.X * 1.05, h.X * 1.05), CFrame.new(0, h.Y * 0.68, 0) * CFrame.Angles(0, 0, math.pi / 2), look.jacket, Enum.Material.Fabric, Enum.PartType.Cylinder)
		piece(model, "Head", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0.5, h.Y * 0.8, -0.3), Color3.fromRGB(255, 120, 150), Enum.Material.Fabric, Enum.PartType.Ball)
	elseif name == "pearls" then
		piece(model, "UpperTorso", Vector3.new(t.X * 0.5, 0.12, 0.08), CFrame.new(0, t.Y * 0.38, front(model, "UpperTorso", 0.04)), WHITE, Enum.Material.SmoothPlastic)
	elseif name == "chain" then
		piece(model, "UpperTorso", Vector3.new(t.X * 0.55, 0.14, 0.08), CFrame.new(0, t.Y * 0.3, front(model, "UpperTorso", 0.06)), GOLD, Enum.Material.Foil)
		piece(model, "UpperTorso", Vector3.new(0.26, 0.26, 0.08), CFrame.new(0, t.Y * 0.12, front(model, "UpperTorso", 0.07)), GOLD, Enum.Material.Foil, Enum.PartType.Ball)
	elseif name == "watch" then
		local hand = model:FindFirstChild("LeftLowerArm")
		if hand then
			piece(model, "LeftLowerArm", Vector3.new(hand.Size.X * 1.1, 0.2, hand.Size.Z * 1.1), CFrame.new(0, -hand.Size.Y * 0.35, 0), GOLD, Enum.Material.Foil)
		end
	elseif name == "camera" then
		piece(model, "UpperTorso", Vector3.new(0.6, 0.4, 0.3), CFrame.new(0, -t.Y * 0.1, front(model, "UpperTorso", 0.18)), BLACK)
		piece(model, "UpperTorso", Vector3.new(0.26, 0.26, 0.2), CFrame.new(0, -t.Y * 0.1, front(model, "UpperTorso", 0.38)), Color3.fromRGB(60, 60, 60), Enum.Material.Glass, Enum.PartType.Ball)
	elseif name == "toolbelt" then
		piece(model, "LowerTorso", Vector3.new(dims(model, "LowerTorso").X * 1.08, 0.25, dims(model, "LowerTorso").Z * 1.1), CFrame.new(0, 0.1, 0), Color3.fromRGB(110, 70, 35), Enum.Material.Leather)
	elseif name == "coat" then
		for side = -1, 1, 2 do
			piece(model, "LowerTorso", Vector3.new(0.9, 1.5, 0.1), CFrame.new(side * 0.5, -0.6, front(model, "LowerTorso", 0.02)), WHITE, Enum.Material.Fabric)
		end
	elseif name == "purse" or name == "briefcase" then
		local color = name == "purse" and Color3.fromRGB(180, 50, 80) or Color3.fromRGB(70, 45, 25)
		piece(model, "RightHand", Vector3.new(0.35, 0.9, 1.2), CFrame.new(0, -0.55, 0), color, Enum.Material.Leather)
		piece(model, "RightHand", Vector3.new(0.38, 0.1, 0.3), CFrame.new(0, -0.08, 0), GOLD, Enum.Material.Metal)
	elseif name == "coffee" then
		piece(model, "RightHand", Vector3.new(0.5, 0.35, 0.35), CFrame.new(0, -0.1, -0.2) * CFrame.Angles(0, 0, math.pi / 2), WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	elseif name == "phone" then
		piece(model, "RightHand", Vector3.new(0.1, 0.6, 0.35), CFrame.new(0, -0.3, -0.1), BLACK, Enum.Material.Glass)
	elseif name == "lanyard" then
		piece(model, "UpperTorso", Vector3.new(0.3, 0.38, 0.05), CFrame.new(0.35, -t.Y * 0.05, front(model, "UpperTorso", 0.05)), Color3.fromRGB(80, 150, 230))
	elseif name == "looseTie" then
		tie(model, Color3.fromRGB(200, 40, 40), true)
	elseif name == "bolo" then
		piece(model, "UpperTorso", Vector3.new(0.22, 0.22, 0.06), CFrame.new(0, t.Y * 0.28, front(model, "UpperTorso", 0.06)), Color3.fromRGB(60, 200, 190), Enum.Material.Neon, Enum.PartType.Ball)
		piece(model, "LowerTorso", Vector3.new(0.5, 0.35, 0.08), CFrame.new(0, 0.15, front(model, "LowerTorso", 0.06)), GOLD, Enum.Material.Foil)
	elseif name == "hood" then
		piece(model, "UpperTorso", Vector3.new(t.X * 0.7, t.Y * 0.5, 0.35), CFrame.new(0, t.Y * 0.5, t.Z * 0.55), look.jacket, Enum.Material.Fabric)
	elseif name == "leather" then
		for side = -1, 1, 2 do
			piece(model, "UpperTorso", Vector3.new(t.X * 0.14, t.Y * 0.7, 0.06), CFrame.new(side * t.X * 0.18, t.Y * 0.1, front(model, "UpperTorso", 0.04)) * CFrame.Angles(0, 0, side * -0.25), Color3.fromRGB(10, 10, 10), Enum.Material.Leather)
		end
		piece(model, "UpperTorso", Vector3.new(t.X * 0.3, t.Y * 0.9, 0.04), CFrame.new(0, t.Y * 0.02, front(model, "UpperTorso", 0.02)), Color3.fromRGB(200, 40, 40), Enum.Material.Fabric)
	elseif name == "guitar" then
		piece(model, "UpperTorso", Vector3.new(1.2, 2.2, 0.3), CFrame.new(0, -0.2, t.Z * 0.5 + 0.2) * CFrame.Angles(0, 0, 0.6), Color3.fromRGB(200, 30, 40))
		piece(model, "UpperTorso", Vector3.new(0.2, 1.6, 0.15), CFrame.new(0.9, 1.1, t.Z * 0.5 + 0.2) * CFrame.Angles(0, 0, 0.6), Color3.fromRGB(60, 40, 25), Enum.Material.Wood)
	elseif name == "cape" then
		piece(model, "UpperTorso", Vector3.new(t.X * 1.1, t.Y * 2.2, 0.1), CFrame.new(0, -t.Y * 0.55, t.Z * 0.56), Color3.fromRGB(170, 20, 40), Enum.Material.Fabric)
		piece(model, "UpperTorso", Vector3.new(t.X * 1.12, 0.25, t.Z * 1.2), CFrame.new(0, t.Y * 0.5, 0), WHITE, Enum.Material.Fabric)
	elseif name == "sash" then
		piece(model, "UpperTorso", Vector3.new(0.3, t.Y * 1.2, 0.06), CFrame.new(0, 0, front(model, "UpperTorso", 0.04)) * CFrame.Angles(0, 0, 0.6), Color3.fromRGB(60, 120, 220), Enum.Material.Fabric)
	elseif name == "dress" then
		local lt = dims(model, "LowerTorso")
		piece(model, "LowerTorso", Vector3.new(lt.X * 1.5, 2, lt.Z * 1.6), CFrame.new(0, -0.9, 0), look.jacket, Enum.Material.Fabric)
	elseif name == "platforms" then
		for _, foot in { "LeftFoot", "RightFoot" } do
			local size = dims(model, foot)
			piece(model, foot, Vector3.new(size.X * 1.1, 0.5, size.Z * 1.1), CFrame.new(0, -size.Y / 2 - 0.2, 0), GOLD, Enum.Material.Foil)
		end
	elseif name == "suit" then
		suit(model, { jacket = look.jacket, shirt = WHITE, tie = look.tie, pocket = look.pocket })
	elseif name == "wolfsuit" then
		suit(model, OutfitService.SuitStyles.wolfsuit)
	end
end

-- Rarer visitors get auras, crowns and glows on top of their outfit.
local function decorate(model, rarity)
	local head = model:FindFirstChild("Head")
	if not head then
		return
	end
	local id = rarity.id
	if id == "mythic" or id == "legendary" or id == "exotic" or id == "ultra" then
		extra(model, "chain", {})
	end
	if id == "legendary" or id == "exotic" then
		local h = head.Size
		local crown = piece(model, "Head", Vector3.new(h.X * 0.9, 0.45, h.Z * 0.9), CFrame.new(0, h.Y / 2 + 0.45, 0), id == "exotic" and rarity.color or GOLD, Enum.Material.Foil)
		if crown then
			for i = 0, 4 do
				local a = i / 5 * math.pi * 2
				piece(model, "Head", Vector3.new(0.15, 0.3, 0.15), CFrame.new(math.cos(a) * h.X * 0.38, h.Y / 2 + 0.8, math.sin(a) * h.Z * 0.38), GOLD, Enum.Material.Foil)
			end
		end
	end
	if id == "exotic" or id == "ultra" then
		local halo = piece(model, "Head", Vector3.new(0.12, 1.5, 1.5), CFrame.new(0, head.Size.Y / 2 + 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2), id == "ultra" and GOLD or rarity.color, Enum.Material.Neon, Enum.PartType.Cylinder)
		if halo then
			halo.Transparency = 0.2
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and id ~= "common" and id ~= "rare" then
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "Aura"
		aura.Color = ColorSequence.new(rarity.color)
		aura.LightEmission = 0.8
		aura.Size = NumberSequence.new(0.35, 0)
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(0.5, 1.5)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Rate = ({ superrare = 6, epic = 12, mythic = 20, legendary = 30, exotic = 45, ultra = 80 })[id] or 5
		aura.Parent = root
		if id == "legendary" or id == "exotic" or id == "ultra" then
			local glow = Instance.new("PointLight")
			glow.Color = id == "ultra" and Color3.fromRGB(255, 230, 150) or rarity.color
			glow.Brightness = 2
			glow.Range = 14
			glow.Parent = root
		end
		if id == "ultra" then
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = GOLD
			sparkles.Parent = root
		end
	end
end

local function pick(seeded, list)
	return list[seeded:NextInteger(1, #list)]
end

-- Everything about a visitor's look, decided by their number alone.
function OutfitService.lookFor(visitor)
	local seeded = Random.new(visitor.number * 7919)
	local base = LOOKS[visitor.archetype] or LOOKS.tourist
	local jacket = pick(seeded, base.jackets)
	local look = {
		skin = pick(seeded, SKIN_TONES),
		hairColor = pick(seeded, HAIR_COLORS),
		hair = pick(seeded, base.hair),
		jacket = jacket,
		pants = base.pants and pick(seeded, base.pants) or jacket,
		tie = pick(seeded, { Color3.fromRGB(200, 30, 40), GOLD, Color3.fromRGB(40, 70, 170), Color3.fromRGB(20, 120, 70) }),
		pocket = seeded:NextNumber() < 0.5 and WHITE or nil,
		extras = base.extras,
		shorts = base.shorts,
		hatColor = base.hatColor,
		manFace = seeded:NextNumber() < 0.4,
		height = seeded:NextNumber(0.92, 1.08),
		width = seeded:NextNumber(0.9, 1.12),
	}
	return look
end

-- Build a visitor's rig. Nothing game-specific (prompts, tags) is added.
function OutfitService.buildVisitor(visitor)
	local look = OutfitService.lookFor(visitor)
	local rarity = Config.getRarity(visitor.rarity)

	local function describe(withCatalog)
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = look.skin
		description.TorsoColor = look.jacket
		description.LeftArmColor = look.jacket
		description.RightArmColor = look.jacket
		description.LeftLegColor = look.shorts and look.skin or look.pants
		description.RightLegColor = look.shorts and look.skin or look.pants
		description.HeightScale = look.height
		description.WidthScale = look.width
		if withCatalog then
			if look.hair == "pal" then
				description.HairAccessory = tostring(CATALOG.palHair)
			end
			if look.manFace then
				description.Face = CATALOG.manFace
			end
		end
		return description
	end

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(describe(true), Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		-- A catalog item failed to load: build without them.
		ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(describe(false), Enum.HumanoidRigType.R15)
		end)
	end
	if not ok or not model then
		warn("[OutfitService] could not build", visitor.name, model)
		return nil
	end
	model.Name = visitor.name

	local pieces = Instance.new("Folder")
	pieces.Name = "OutfitPieces"
	pieces.Parent = model

	for _, name in { "LeftHand", "RightHand" } do
		local hand = model:FindFirstChild(name)
		if hand then
			hand.Color = look.skin
		end
	end
	if look.shorts then
		for _, name in { "LeftUpperLeg", "RightUpperLeg" } do
			local leg = model:FindFirstChild(name)
			if leg then
				leg.Color = look.pants
			end
		end
	end
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = model:FindFirstChild(name)
		if foot then
			foot.Color = Color3.fromRGB(30, 25, 22)
		end
	end
	if look.hair ~= "pal" or not model:FindFirstChildWhichIsA("Accessory", true) then
		hair(model, look.hair == "pal" and "messy" or look.hair, look.hatColor or look.hairColor)
	end
	for _, name in look.extras do
		extra(model, name, look)
	end
	decorate(model, rarity)
	return model
end

-- Players ------------------------------------------------------------------------

local originals = {} -- [Player] = HumanoidDescription they spawned with
local wearing = {} -- [Player] = suit id currently on the avatar

local CLOTHING_LAYERS = {
	[Enum.AccessoryType.Shirt] = true,
	[Enum.AccessoryType.TShirt] = true,
	[Enum.AccessoryType.Jacket] = true,
	[Enum.AccessoryType.Sweater] = true,
	[Enum.AccessoryType.Pants] = true,
	[Enum.AccessoryType.Shorts] = true,
	[Enum.AccessoryType.DressSkirt] = true,
}

-- Put the player's current suit on their avatar (the thrift suit = their own clothes).
function OutfitService.dressPlayer(player, suitId)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local original = originals[player]
	if not original then
		local ok, applied = pcall(function()
			return humanoid:GetAppliedDescription()
		end)
		if not ok then
			return
		end
		original = applied
		originals[player] = original
	end

	wearing[player] = suitId
	local old = character:FindFirstChild("OutfitPieces")
	if old then
		old:Destroy()
	end
	local style = OutfitService.SuitStyles[suitId]
	local description = original:Clone()
	if style then
		description.Shirt = 0
		description.Pants = 0
		description.GraphicTShirt = 0
		description.TorsoColor = style.jacket
		description.LeftArmColor = style.jacket
		description.RightArmColor = style.jacket
		description.LeftLegColor = style.pants
		description.RightLegColor = style.pants
		local ok, accessories = pcall(function()
			return description:GetAccessories(true)
		end)
		if ok then
			local kept = {}
			for _, accessory in accessories do
				if not CLOTHING_LAYERS[accessory.AccessoryType] then
					table.insert(kept, accessory)
				end
			end
			pcall(function()
				description:SetAccessories(kept, true)
			end)
		end
	end
	local applied = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	if not applied or not style then
		return
	end

	local pieces = Instance.new("Folder")
	pieces.Name = "OutfitPieces"
	pieces.Parent = character
	for _, name in { "LeftHand", "RightHand" } do
		local hand = character:FindFirstChild(name)
		if hand then
			hand.Color = original.HeadColor
		end
	end
	suit(character, style)
	for _, name in style.extras or {} do
		extra(character, name, {})
	end
	if style.sheen then
		for _, name in { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" } do
			local part = character:FindFirstChild(name)
			if part then
				part.Reflectance = 0.12
			end
		end
	end
end

-- Index previews ------------------------------------------------------------------

local previewFolder
local previewBuilding = {}

local function getPreview(_, visitorId)
	local visitor = type(visitorId) == "string" and Visitors.byId[visitorId]
	if not visitor then
		return nil
	end
	local existing = previewFolder:FindFirstChild(visitor.id)
	if existing then
		return existing
	end
	if previewBuilding[visitor.id] then
		while previewBuilding[visitor.id] do
			task.wait(0.1)
		end
		return previewFolder:FindFirstChild(visitor.id)
	end
	previewBuilding[visitor.id] = true
	local model = OutfitService.buildVisitor(visitor)
	if model then
		model.Name = visitor.id
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			elseif descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ParticleEmitter") or descendant:IsA("Sparkles") then
				descendant:Destroy()
			end
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		model:PivotTo(CFrame.new(0, 0, 0))
		model.Parent = previewFolder
	end
	previewBuilding[visitor.id] = nil
	return model
end

-- Called on every profile change; only redresses when the suit changed.
function OutfitService.suitChanged(player, suitId)
	if player.Character and wearing[player] ~= nil and wearing[player] ~= suitId then
		task.spawn(OutfitService.dressPlayer, player, suitId)
	end
end

function OutfitService.start(getSuit)
	previewFolder = Instance.new("Folder")
	previewFolder.Name = "VisitorPreviews"
	previewFolder.Parent = ReplicatedStorage
	Remotes.GetPreview.OnServerInvoke = getPreview

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			originals[player] = nil
			wearing[player] = nil
			character:WaitForChild("Humanoid")
			-- Let the avatar finish loading before we dress it.
			task.wait(1.2)
			if player.Character == character then
				OutfitService.dressPlayer(player, getSuit(player))
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		originals[player] = nil
		wearing[player] = nil
	end)
end

return OutfitService
