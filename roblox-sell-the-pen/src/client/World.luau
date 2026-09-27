-- Client-side world polish: gates that open for you once unlocked, the
-- customer prompt, zone title cards, stock tickers and speech confetti.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(script.Parent.UI.Theme)
local Hud = require(script.Parent.UI.Hud)
local Store = require(script.Parent.Store)

local Colors = Theme.Colors
local player = Players.LocalPlayer
local map = Workspace:WaitForChild("Map")

local World = {}

-- Gates ----------------------------------------------------------------------

local gateSigns = {}

local function signOn(gate, face)
	local gui = Theme.create("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 20,
		LightInfluence = 0,
		Brightness = 1.5,
		Parent = gate,
	})
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.8, 0.35),
		Font = Theme.FontBlack,
		TextColor3 = Colors.gold,
		TextStrokeTransparency = 0.2,
		Parent = gui,
	})
	return gui, label
end

local function setupGates()
	local gates = map:WaitForChild("Gates", 10)
	if not gates then
		return
	end
	for _, zone in Config.Zones do
		local gate = zone.gate and gates:WaitForChild(zone.gate, 10)
		if gate then
			local text = string.format("LOCKED\n%s\n%d REBIRTH%s", string.upper(zone.name), zone.rebirths, zone.rebirths == 1 and "" or "S")
			local signs = {}
			for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
				local gui, label = signOn(gate, face)
				label.Text = text
				table.insert(signs, gui)
			end
			gateSigns[zone.id] = { gate = gate, signs = signs, transparency = gate.Transparency }
		end
	end
end

local function refreshGates()
	local profile = Store.profile()
	if not profile then
		return
	end
	for zoneId, entry in gateSigns do
		local open = Config.zoneUnlocked(profile, zoneId)
		entry.gate.CanCollide = not open
		entry.gate.Transparency = open and 1 or entry.transparency
		for _, sign in entry.signs do
			sign.Enabled = not open
		end
	end
end

-- Customer prompt ------------------------------------------------------------------

local function promptGui(prompt)
	local profile = Store.profile()
	local zoneId = prompt:GetAttribute("Zone")
	local locked = profile and zoneId and not Config.zoneUnlocked(profile, zoneId)
	local rarity = Config.getRarity(prompt:GetAttribute("Rarity") or "common")
	local gui = Theme.create("BillboardGui", {
		Name = "PromptUI",
		Size = UDim2.fromOffset(230, 64),
		StudsOffset = Vector3.new(0, 3.2, 0),
		AlwaysOnTop = true,
		Adornee = prompt.Parent,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local frame = Theme.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Colors.bg,
		BackgroundTransparency = 0.1,
		Parent = gui,
	}, { Theme.corner(14), Theme.stroke(locked and Colors.red or rarity.color, 2.5) })
	local key = Theme.create("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = locked and Colors.red or Colors.gold,
		Parent = frame,
	}, { Theme.corner(10) })
	Theme.label({
		Size = UDim2.fromScale(1, 1),
		Font = Theme.FontBlack,
		Text = locked and "!" or "E",
		TextColor3 = Colors.bg,
		Parent = key,
	})
	Theme.label({
		Position = UDim2.fromOffset(64, 8),
		Size = UDim2.new(1, -72, 0, 26),
		Font = Theme.FontBlack,
		Text = locked and "ZONE LOCKED" or "SELL ME THIS PEN",
		TextColor3 = locked and Colors.red or Colors.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Theme.label({
		Position = UDim2.fromOffset(64, 36),
		Size = UDim2.new(1, -72, 0, 18),
		Font = Theme.Font,
		Text = prompt.ObjectText,
		TextColor3 = Colors.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Theme.pop(frame, 0.25)

	-- Tap to pitch on touch screens.
	local button = Theme.create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = frame,
	})
	gui.Active = true
	button.Activated:Connect(function()
		prompt:InputHoldBegin()
		task.wait()
		prompt:InputHoldEnd()
	end)
	return gui
end

local function setupPrompts()
	local shown = {}
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		if Store.inPitch then
			return
		end
		shown[prompt] = promptGui(prompt)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local gui = shown[prompt]
		if gui then
			gui:Destroy()
			shown[prompt] = nil
		end
	end)
	-- Hide every prompt while a pitch is on screen.
	RunService.Heartbeat:Connect(function()
		if Store.inPitch then
			for prompt, gui in shown do
				gui:Destroy()
				shown[prompt] = nil
			end
		end
	end)
end

-- Zones --------------------------------------------------------------------------

local function zoneAt(position)
	for _, zone in Config.Zones do
		local a = zone.area
		if position.X >= a.minX - 8 and position.X <= a.maxX + 8 and position.Z >= a.minZ - 8 and position.Z <= a.maxZ + 8 and math.abs(position.Y - a.y) < 25 then
			return zone
		end
	end
	return nil
end

local function trackZones()
	local current
	while true do
		task.wait(0.5)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local zone = zoneAt(root.Position)
			if zone and zone ~= current then
				Hud.zoneCard(zone)
			end
			if zone then
				current = zone
			end
		end
	end
end

-- Tickers ------------------------------------------------------------------------

local SYMBOLS = { "PEN", "INK", "BIC", "NIB", "QUIL", "GEL", "CLIK", "CAP", "STRT", "OAK", "WOLF", "NAPK" }

local function tickerText()
	local parts = {}
	for _, symbol in SYMBOLS do
		local change = (math.random() - 0.35) * 12
		local color = change >= 0 and "#5AEB82" or "#F04646"
		table.insert(parts, string.format('<font color="#FFFFFF">%s</font> <font color="%s">%s%.2f%%</font>', symbol, color, change >= 0 and "▲" or "▼", math.abs(change)))
	end
	return table.concat(parts, "     ")
end

local function setupTickers()
	local tickers = {}
	for _, part in map:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "TickerBoard" then
			local gui = Theme.create("SurfaceGui", {
				Face = Enum.NormalId.Front,
				SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
				PixelsPerStud = 24,
				LightInfluence = 0,
				Brightness = 2,
				ClipsDescendants = true,
				Parent = part,
			})
			Theme.create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = gui })
			local label = Theme.label({
				Size = UDim2.new(4, 0, 1, 0),
				Font = Theme.FontMono,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tickerText(),
				Parent = gui,
			})
			table.insert(tickers, { label = label, offset = math.random() })
		end
	end
	RunService.RenderStepped:Connect(function(dt)
		for _, ticker in tickers do
			ticker.offset += dt * 0.025
			if ticker.offset >= 1 then
				ticker.offset = 0
				ticker.label.Text = tickerText()
			end
			ticker.label.Position = UDim2.fromScale(1 - ticker.offset * 5, 0)
		end
	end)
end

-- Speech confetti ------------------------------------------------------------------

local function setupSpeech()
	local function apply()
		local active = Workspace:GetAttribute("SpeechActive") == true
		for _, emitter in map:GetDescendants() do
			if emitter:IsA("ParticleEmitter") and emitter.Name == "Confetti" then
				emitter.Enabled = active
			end
		end
		if active then
			local line = Workspace:GetAttribute("SpeechLine")
			if line then
				Hud.zoneCard({ name = "THE WOLF SPEAKS", subtitle = '"' .. line .. '"' })
			end
		end
	end
	Workspace:GetAttributeChangedSignal("SpeechActive"):Connect(apply)
	apply()
end

-- Traffic -----------------------------------------------------------------------------

-- Cars in Map.Traffic drive along the avenue. Each client moves them
-- locally (smooth, and they never collide with anything).
local function setupTraffic()
	local folder = map:WaitForChild("Traffic", 10)
	if not folder then
		return
	end
	local cars = {}
	for _, model in folder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("Speed") then
			table.insert(cars, {
				model = model,
				base = model:GetPivot(),
				startX = model:GetPivot().Position.X,
				offset = 0,
				speed = model:GetAttribute("Speed"),
				direction = model:GetAttribute("Direction") or 1,
				minX = model:GetAttribute("MinX") or -100,
				maxX = model:GetAttribute("MaxX") or 200,
			})
		end
	end
	RunService.Heartbeat:Connect(function(dt)
		for _, car in cars do
			car.offset += car.speed * car.direction * dt
			local x = car.startX + car.offset
			local span = car.maxX - car.minX
			-- Wrap around at the end of the avenue.
			if x > car.maxX then
				car.offset -= span
			elseif x < car.minX then
				car.offset += span
			end
			car.model:PivotTo(car.base + Vector3.new(car.offset, 0, 0))
		end
	end)
end

function World.start()
	task.spawn(function()
		setupGates()
		refreshGates()
	end)
	Store.Changed:Connect(refreshGates)
	setupPrompts()
	setupTickers()
	setupSpeech()
	task.spawn(setupTraffic)
	task.spawn(trackZones)
end

return World
