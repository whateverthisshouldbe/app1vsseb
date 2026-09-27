-- Your firm (brokers), the visitor Index and the teleporter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Visitors = require(ReplicatedStorage.Shared.Visitors)
local Theme = require(script.Parent.Theme)
local Modal = require(script.Parent.Modal)
local Notifier = require(script.Parent.Notifier)
local Store = require(script.Parent.Parent.Store)

local Remotes = ReplicatedStorage.Remotes
local Colors = Theme.Colors

local Collection = {}

local firmModal, indexModal, tpModal

local function scroller(parent, layout)
	local frame = Theme.create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	layout.Parent = frame
	return frame
end

local function clear(frame)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function rarityGradient(rarity, parent)
	if rarity.id == "ultra" or rarity.id == "exotic" then
		Theme.create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 90)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 200, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 220)),
			}),
			Rotation = 20,
			Parent = parent,
		})
	end
end

-- Firm ---------------------------------------------------------------------------

local firmList, firmHeader

local function renderFirm()
	local profile = Store.profile()
	if not profile or not firmList then
		return
	end
	clear(firmList)
	local total = 0
	for slot = 1, Config.MaxBrokers do
		local visitor = Visitors.byId[profile.brokers[slot] or ""]
		local row = Theme.create("Frame", {
			LayoutOrder = slot,
			Size = UDim2.new(1, -8, 0, 58),
			BackgroundColor3 = Colors.panel,
			Parent = firmList,
		}, { Theme.corner(10) })
		if visitor then
			local rarity = Config.getRarity(visitor.rarity)
			local perSecond = Config.brokerIncome(visitor.rarity)
			total += perSecond
			Theme.stroke(rarity.color, 1.5).Parent = row
			local tag = Theme.label({
				Position = UDim2.fromOffset(12, 6),
				Size = UDim2.new(0.6, 0, 0, 18),
				Font = Theme.FontBlack,
				Text = string.upper(rarity.name),
				TextColor3 = rarity.color,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			rarityGradient(rarity, tag)
			Theme.label({
				Position = UDim2.fromOffset(12, 26),
				Size = UDim2.new(1, -150, 0, 24),
				Text = visitor.name,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			Theme.label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -100, 0, 8),
				Size = UDim2.fromOffset(170, 42),
				Font = Theme.FontBold,
				Text = string.format("%s/day\n%s/s", Format.cash(rarity.daily), Format.rate(perSecond)),
				TextColor3 = Colors.money,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
			local fire = Theme.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(80, 38),
				BackgroundColor3 = Color3.fromRGB(110, 40, 40),
				Font = Theme.FontBlack,
				Text = "FIRE",
				Parent = row,
			}, function()
				local ok, message = Remotes.FireBroker:InvokeServer(slot)
				Notifier.show(message, ok and "info" or "error")
			end)
			Theme.corner(8).Parent = fire
		else
			Theme.stroke(Colors.stroke, 1).Parent = row
			Theme.label({
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Font = Theme.Font,
				Text = "Empty desk. Close a sale and choose RECRUIT to fill it.",
				TextColor3 = Colors.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
		end
	end
	local data = Store.data
	firmHeader.Text = string.format(
		"%d/%d brokers  ·  %s/s  (x%.1f rebirth = %s/s)  ·  offline x%.1f",
		#profile.brokers,
		Config.MaxBrokers,
		Format.rate(total),
		data.ipoMult,
		Format.rate(total * data.ipoMult),
		Config.OfflineEarningsRate
	)
end

local function buildFirm(screen)
	firmModal = Modal.new(screen, "YOUR FIRM", Colors.firm, Vector2.new(640, 640))
	firmModal.key = "firm"
	firmHeader = Theme.label({
		Size = UDim2.new(1, 0, 0, 24),
		Font = Theme.FontBold,
		TextColor3 = Colors.money,
		Parent = firmModal.content,
	})
	local holder = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundTransparency = 1,
		Parent = firmModal.content,
	})
	firmList = scroller(holder, Theme.create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }))
	firmModal.onOpen = renderFirm
end

-- Index ----------------------------------------------------------------------------

local indexGrid, indexHeader, indexSignature
local viewports = {} -- [visitorId] = { viewport, sold } for the cards on screen
local previews = {} -- [visitorId] = preview model from the server
local loading = false

-- Put a visitor's model in their card: full color if you've sold to them,
-- a black silhouette if not.
local function showPreview(visitorId, model)
	local entry = viewports[visitorId]
	if not entry or entry.viewport:FindFirstChild("Model") then
		return
	end
	local copy = model:Clone()
	copy.Name = "Model"
	for _, descendant in copy:GetDescendants() do
		if descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		elseif not entry.sold then
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.new(0, 0, 0)
				descendant.Material = Enum.Material.SmoothPlastic
				descendant.Reflectance = 0
				if descendant:IsA("MeshPart") then
					descendant.TextureID = ""
				end
			elseif descendant:IsA("SpecialMesh") then
				descendant.TextureId = ""
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") or descendant:IsA("SurfaceAppearance") then
				descendant:Destroy()
			end
		end
	end
	copy.Parent = entry.viewport
	local camera = entry.viewport:FindFirstChildOfClass("Camera") or Instance.new("Camera")
	camera.FieldOfView = 32
	camera.CFrame = CFrame.lookAt(Vector3.new(2.2, 1.4, -10), Vector3.new(0, 0.3, 0))
	camera.Parent = entry.viewport
	entry.viewport.CurrentCamera = camera
end

-- Fetch previews one at a time in the background (the server builds them on demand).
local function loadPreviews()
	if loading then
		return
	end
	loading = true
	task.spawn(function()
		for _, visitor in ipairs(Visitors) do
			if not indexModal.frame.Visible then
				break
			end
			if not previews[visitor.id] then
				local ok, model = pcall(function()
					return Remotes.GetPreview:InvokeServer(visitor.id)
				end)
				if ok and model then
					previews[visitor.id] = model
				end
			end
			if previews[visitor.id] then
				showPreview(visitor.id, previews[visitor.id])
			end
		end
		loading = false
	end)
end

local function renderIndex(force)
	local data = Store.data
	if not data or not indexGrid then
		return
	end
	local profile = data.profile
	local signature = tostring(data.indexCount)
	for id, count in profile.index do
		signature ..= id .. count
	end
	if signature == indexSignature and not force then
		return
	end
	indexSignature = signature

	local counts = {}
	for id in profile.index do
		local visitor = Visitors.byId[id]
		if visitor then
			counts[visitor.rarity] = (counts[visitor.rarity] or 0) + 1
		end
	end
	local parts = {}
	for _, rarity in Config.Rarities do
		table.insert(parts, string.format('<font color="#%s">%s %d/%d</font>', rarity.color:ToHex(), rarity.name, counts[rarity.id] or 0, #(Visitors.byRarity[rarity.id] or {})))
	end
	indexHeader.Text = string.format(
		"<b>%d/%d collected  ·  +%.1f%% sales</b>\n%s",
		data.indexCount,
		#Visitors,
		(data.indexMult - 1) * 100,
		table.concat(parts, "  ")
	)

	clear(indexGrid)
	table.clear(viewports)
	for order, visitor in ipairs(Visitors) do
		local rarity = Config.getRarity(visitor.rarity)
		local sold = profile.index[visitor.id]
		local card = Theme.create("Frame", {
			LayoutOrder = order,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = indexGrid,
		}, { Theme.corner(12), Theme.stroke(sold and rarity.color or Colors.stroke, sold and 3 or 2) })
		Theme.fill(card, sold and { rarity.color:Lerp(Color3.new(1, 1, 1), 0.25), rarity.color:Lerp(Color3.new(0, 0, 0), 0.45) } or "navy")
		local viewport = Theme.create("ViewportFrame", {
			Position = UDim2.fromOffset(4, 22),
			Size = UDim2.new(1, -8, 0, 118),
			BackgroundTransparency = 1,
			Ambient = sold and Color3.fromRGB(200, 200, 200) or Color3.new(0, 0, 0),
			LightColor = sold and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
			LightDirection = Vector3.new(-0.4, -0.6, 0.7),
			Parent = card,
		})
		viewports[visitor.id] = { viewport = viewport, sold = sold ~= nil }
		local tag = Theme.label({
			Position = UDim2.fromOffset(6, 4),
			Size = UDim2.new(1, -12, 0, 18),
			Font = Theme.FontBlack,
			Text = string.format("#%d  %s", visitor.number, string.upper(rarity.name)),
			TextColor3 = sold and Colors.text or rarity.color,
			Outline = 2,
			Parent = card,
		})
		rarityGradient(rarity, tag)
		Theme.label({
			Position = UDim2.new(0, 6, 1, -48),
			Size = UDim2.new(1, -12, 0, 26),
			Font = Theme.FontBlack,
			Text = sold and visitor.name or "???",
			TextWrapped = true,
			Outline = 2,
			Parent = card,
		})
		Theme.label({
			Position = UDim2.new(0, 6, 1, -21),
			Size = UDim2.new(1, -12, 0, 16),
			Font = Theme.FontBold,
			Text = sold and string.format("sold x%d  ·  x%s", sold, Format.short(rarity.mult)) or ("1 in " .. Format.commas(rarity.odds)),
			TextColor3 = sold and Colors.gold or Colors.muted,
			Outline = 1.5,
			Parent = card,
		})
		local cached = previews[visitor.id]
		if cached then
			showPreview(visitor.id, cached)
		end
	end
	loadPreviews()
end

local function buildIndex(screen)
	indexModal = Modal.new(screen, "VISITOR INDEX", Colors.gold, Vector2.new(820, 620))
	indexModal.key = "index"
	indexHeader = Theme.label({
		Size = UDim2.new(1, 0, 0, 46),
		Font = Theme.Font,
		TextScaled = false,
		TextSize = 15,
		TextWrapped = true,
		RichText = true,
		TextColor3 = Colors.text,
		Parent = indexModal.content,
	})
	local holder = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		Parent = indexModal.content,
	})
	indexGrid = scroller(holder, Theme.create("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 196),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}))
	indexModal.onOpen = function()
		renderIndex(true)
	end
end

-- Teleport ------------------------------------------------------------------------

local tpList

local function renderTeleport()
	local profile = Store.profile()
	if not profile or not tpList then
		return
	end
	clear(tpList)
	for order, zone in Config.Zones do
		local unlocked = Config.zoneUnlocked(profile, zone.id)
		local row = Theme.create("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, -8, 0, 64),
			BackgroundColor3 = Colors.panel,
			Parent = tpList,
		}, { Theme.corner(10), Theme.stroke(unlocked and Colors.gold or Colors.stroke, 1.5) })
		Theme.label({
			Position = UDim2.fromOffset(14, 6),
			Size = UDim2.new(1, -170, 0, 26),
			Font = Theme.FontBlack,
			Text = zone.name,
			TextColor3 = unlocked and Colors.gold or Colors.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		Theme.label({
			Position = UDim2.fromOffset(14, 34),
			Size = UDim2.new(1, -170, 0, 20),
			Font = Theme.Font,
			Text = string.format("Rebirths %s  ·  pays x%s  ·  luck x%.2g  ·  %s", Config.zoneRange(zone), Format.short(zone.budgetMult), zone.luck, zone.subtitle),
			TextColor3 = Colors.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local go = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(140, 46),
			BackgroundColor3 = unlocked and Color3.fromRGB(40, 150, 80) or Colors.panelLight,
			Font = Theme.FontBlack,
			Text = unlocked and "TELEPORT" or string.format("%d REBIRTHS", zone.rebirths),
			Parent = row,
		}, function()
			if not unlocked then
				return
			end
			local ok, message = Remotes.Teleport:InvokeServer(zone.id)
			Notifier.show(message, ok and "success" or "error")
			if ok then
				tpModal:close()
			end
		end)
		Theme.corner(10).Parent = go
	end
end

local function buildTeleport(screen)
	tpModal = Modal.new(screen, "TELEPORT", Colors.blue, Vector2.new(640, 560))
	tpModal.key = "teleport"
	tpList = scroller(tpModal.content, Theme.create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }))
	tpModal.onOpen = renderTeleport
end

function Collection.mount(screen)
	buildFirm(screen)
	buildIndex(screen)
	buildTeleport(screen)
	local lastBrokers
	Store.Changed:Connect(function(data)
		local brokers = table.concat(data.profile.brokers, ",") .. data.ipoMult
		if firmModal.frame.Visible and brokers ~= lastBrokers then
			renderFirm()
		end
		lastBrokers = brokers
		if indexModal.frame.Visible then
			renderIndex()
		end
	end)
end

function Collection.toggleFirm()
	firmModal:toggle()
end

function Collection.toggleIndex()
	indexModal:toggle()
end

function Collection.toggleTeleport()
	tpModal:toggle()
end

return Collection
