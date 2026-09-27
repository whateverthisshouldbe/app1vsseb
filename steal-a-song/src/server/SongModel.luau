--!strict
-- Bouwt het 3D-model van een song: een vinylplaat met een zwevende muzieknoot
-- en een label erboven met naam, zeldzaamheid, streams en inkomen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local SongModel = {}

export type Options = {
	scale: number?,
	physics: boolean?, -- los, beweegt via constraints (de loper)
	carried: boolean?, -- vastgelast aan een speler
	price: boolean?, -- prijs tonen (de loper)
}

local FONT = Enum.Font.FredokaOne
local DISC_TURN = CFrame.Angles(0, math.pi / 2, 0)

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function newPart(model: Model, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Shape" then
			(p :: any)[key] = value
		end
	end
	p.Parent = model
	return p
end

local function label(parent: Instance, name: string, text: string, color: Color3, height: number, order: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, height)
	l.Font = FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.LayoutOrder = order
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(15, 8, 25)
	stroke.Parent = l
	l.Parent = parent
	return l
end

local function rainbowGradient(parent: Instance)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 255, 110)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 90, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200)),
	})
	gradient:AddTag("RainbowGradient")
	gradient.Parent = parent
end

function SongModel.build(song: Economy.Song, options: Options?): Model
	local opts: Options = options or {}
	local s = opts.scale or 1
	local def = Songs.byId[song.id]
	local rarity = Economy.rarity(def.rarity)
	local rarityRank = Economy.rarityIndex(def.rarity)
	local mutation = Economy.mutation(song.mut)
	local rarityColor = rgb(rarity.color)

	local model = Instance.new("Model")
	model.Name = def.name
	model:SetAttribute("SongId", def.id)

	local root = newPart(model, {
		Name = "Root",
		Size = Vector3.new(1, 1, 1) * s,
		Transparency = 1,
		CFrame = CFrame.new(),
	})
	model.PrimaryPart = root

	-- De plaat zelf
	local discColor = Color3.fromRGB(22, 20, 26)
	local discMaterial = Enum.Material.SmoothPlastic
	local discTransparency = 0
	if mutation then
		discColor = rgb(mutation.color)
		if mutation.name == "Gold" then
			discMaterial = Enum.Material.Foil
		elseif mutation.name == "Platinum" then
			discMaterial = Enum.Material.Metal
		elseif mutation.name == "Diamond" then
			discMaterial = Enum.Material.Glass
			discTransparency = 0.2
		else
			discMaterial = Enum.Material.Neon
		end
	end
	local disc = newPart(model, {
		Name = "Disc",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.45, 4.4, 4.4) * s,
		CFrame = DISC_TURN,
		Color = discColor,
		Material = discMaterial,
		Transparency = discTransparency,
		Reflectance = if mutation then 0.1 else 0.25,
	})
	if mutation and mutation.rainbow then
		disc:AddTag("Rainbow")
	end
	newPart(model, {
		Name = "Grooves",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 3.3, 3.3) * s,
		CFrame = DISC_TURN,
		Color = discColor:Lerp(Color3.new(0, 0, 0), 0.35),
		Material = discMaterial,
		Transparency = discTransparency,
	})
	newPart(model, {
		Name = "Label",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.56, 1.8, 1.8) * s,
		CFrame = DISC_TURN,
		Color = rgb(def.color),
		Material = if rarityRank >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
	})
	newPart(model, {
		Name = "Hole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 0.35, 0.35) * s,
		CFrame = DISC_TURN,
		Color = Color3.fromRGB(10, 10, 10),
	})

	-- Zwevende muzieknoot in de kleur van de zeldzaamheid
	local noteColor = if def.rarity == "Secret" then Color3.fromRGB(245, 245, 255) else rarityColor
	local notes = {
		newPart(model, {
			Name = "NoteHead",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1) * s,
			CFrame = CFrame.new(Vector3.new(-0.45, 3.4, 0) * s),
			Color = noteColor,
			Material = Enum.Material.Neon,
		}),
		newPart(model, {
			Name = "NoteStem",
			Size = Vector3.new(0.22, 1.9, 0.22) * s,
			CFrame = CFrame.new(Vector3.new(0.1, 4.3, 0) * s),
			Color = noteColor,
			Material = Enum.Material.Neon,
		}),
		newPart(model, {
			Name = "NoteFlag",
			Size = Vector3.new(0.9, 0.3, 0.22) * s,
			CFrame = CFrame.new(Vector3.new(0.5, 5.05, 0) * s) * CFrame.Angles(0, 0, -0.35),
			Color = noteColor,
			Material = Enum.Material.Neon,
		}),
	}
	if rarity.rainbow then
		for _, note in notes do
			note:AddTag("Rainbow")
		end
	end

	-- Licht en glitters voor de betere songs
	if rarityRank >= 3 then
		local light = Instance.new("PointLight")
		light.Color = noteColor
		light.Range = 6 + rarityRank * 2
		light.Brightness = 1.5
		light.Shadows = false
		light.Parent = root
	end
	if rarityRank >= 4 or mutation then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(if mutation then rgb(mutation.color) else noteColor)
		sparkles.LightEmission = 1
		sparkles.Rate = 4 + rarityRank * 2
		sparkles.Lifetime = NumberRange.new(0.8, 1.6)
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5 * s),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkles.Parent = root
	end

	-- Label boven de song
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = if opts.price then 110 else 75
	if opts.carried then
		gui.Size = UDim2.fromScale(6, 1.2)
		gui.StudsOffset = Vector3.new(0, 3.2, 0)
		local name = label(gui, "Name", def.name, rarityColor, 1, 1)
		if rarity.rainbow then
			rainbowGradient(name)
		end
	else
		local lines = 4 + (if mutation then 1 else 0) + (if opts.price then 1 else 0)
		gui.Size = UDim2.fromScale(10, lines * 0.95)
		gui.StudsOffset = Vector3.new(0, 5.6 * s + lines * 0.5, 0)
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.Parent = gui
		local h = 1 / lines
		if mutation then
			local mutLabel = label(gui, "Mutation", string.upper(mutation.name), rgb(mutation.color), h, 1)
			if mutation.rainbow then
				mutLabel.TextColor3 = Color3.new(1, 1, 1)
				rainbowGradient(mutLabel)
			end
		end
		label(gui, "Name", def.name, Color3.new(1, 1, 1), h * 1.1, 2)
		local rarityLabel = label(gui, "Rarity", def.rarity, rarityColor, h * 0.9, 3)
		if rarity.rainbow then
			rainbowGradient(rarityLabel)
		elseif def.rarity == "Secret" then
			rarityLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
			local stroke = rarityLabel:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Color3.fromRGB(0, 0, 0)
				stroke.Thickness = 3
			end
		end
		label(gui, "Streams", "🎧 " .. Format.streams(song.streams), Color3.fromRGB(170, 225, 255), h, 4)
		label(gui, "Income", Format.perSecond(Economy.income(song.streams)), Color3.fromRGB(110, 255, 130), h, 5)
		if opts.price then
			label(gui, "Price", Format.cash(Economy.price(song)), Color3.fromRGB(255, 225, 80), h * 1.1, 6)
		end
	end
	gui.Parent = root

	local attachment = Instance.new("Attachment")
	attachment.Name = "PromptAttachment"
	attachment.Parent = root

	if opts.physics or opts.carried then
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") then
				child.Anchored = false
				if child ~= root then
					child.Massless = true
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = root
					weld.Part1 = child
					weld.Parent = child
				end
			end
		end
		if opts.carried then
			root.Massless = true
		end
	end

	return model
end

-- Werkt streams en inkomen in het label bij. multiplier is die van de eigenaar.
function SongModel.updateLabels(model: Model, song: Economy.Song, multiplier: number, peaked: boolean?)
	local root = model.PrimaryPart
	local gui = root and root:FindFirstChild("Info")
	if not gui then
		return
	end
	local streams = gui:FindFirstChild("Streams")
	if streams and streams:IsA("TextLabel") then
		local text = "🎧 " .. Format.streams(song.streams) .. (if peaked then " 🔥" else "")
		if streams.Text ~= text then
			streams.Text = text
		end
	end
	local income = gui:FindFirstChild("Income")
	if income and income:IsA("TextLabel") then
		local text = Format.perSecond(Economy.income(song.streams) * multiplier)
		if income.Text ~= text then
			income.Text = text
		end
	end
end

return SongModel
