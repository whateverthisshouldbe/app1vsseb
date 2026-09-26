-- The pitch minigame screen.
--
-- Flow: pick a line (1/2/3) -> stop the tonality needle (Space/click) ->
-- the customer reacts and the certainty meters move. CLOSE (C) whenever
-- you dare. X or walking away ends the pitch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)
local Modal = require(script.Parent.Modal)
local Store = require(script.Parent.Parent.Store)

local Remotes = ReplicatedStorage.Remotes
local Colors = Theme.Colors
local player = Players.LocalPlayer

local PitchUI = {}

local METERS = {
	{ key = "pen", label = "PEN", color = Colors.pen },
	{ key = "you", label = "YOU", color = Colors.you },
	{ key = "firm", label = "FIRM", color = Colors.firm },
}

local screen
local ui = {}
local session -- current pitch data
local phase = "idle" -- idle | choose | tonality | waiting | ended
local chosenIndex
local needle = { pos = 0, dir = 1, speed = 1.3, center = 0.5 }
local revealedDislikes = {}
local cameraConnection

local function playDing(pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.PlaybackSpeed = pitch or 1
	SoundService:PlayLocalSound(sound)
	task.delay(2, function()
		sound:Destroy()
	end)
end

-- Camera ---------------------------------------------------------------------

local function startCamera(model)
	local camera = Workspace.CurrentCamera
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart")
	local head = model and model:FindFirstChild("Head")
	if not myRoot or not head then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local t = 0
	cameraConnection = RunService.RenderStepped:Connect(function(dt)
		if not head.Parent or not myRoot.Parent then
			return
		end
		t += dt
		-- Over-the-shoulder, slowly drifting like a film dolly shot.
		local toCustomer = (head.Position - myRoot.Position) * Vector3.new(1, 0, 1)
		if toCustomer.Magnitude < 0.1 then
			return
		end
		local forward = toCustomer.Unit
		local right = forward:Cross(Vector3.yAxis)
		local drift = math.sin(t * 0.35) * 0.6
		local eye = myRoot.Position - forward * 5 + right * (2.4 + drift) + Vector3.new(0, 2.6, 0)
		local target = head.Position + Vector3.new(0, -0.3, 0)
		local goal = CFrame.lookAt(eye, target)
		camera.CFrame = camera.CFrame:Lerp(goal, math.min(1, dt * 4))
		camera.FieldOfView += (48 - camera.FieldOfView) * math.min(1, dt * 3)
	end)
end

local function stopCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
end

-- Building blocks --------------------------------------------------------------

local function meterRow(parent, info, order)
	local row = Theme.create("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Theme.label({
		Size = UDim2.new(0, 60, 1, 0),
		Font = Theme.FontBlack,
		Text = info.label,
		TextColor3 = info.color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local track = Theme.create("Frame", {
		Position = UDim2.new(0, 66, 0.15, 0),
		Size = UDim2.new(1, -130, 0.7, 0),
		BackgroundColor3 = Colors.bg,
		Parent = row,
	}, { Theme.corner(8), Theme.stroke(Colors.stroke, 1) })
	local fill = Theme.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = info.color,
		Parent = track,
	}, { Theme.corner(8), Theme.gradient(info.color, info.color:Lerp(Color3.new(0, 0, 0), 0.35)) })
	-- Tick marks every 2 points.
	for i = 1, 4 do
		Theme.create("Frame", {
			Position = UDim2.new(i / 5, 0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			Parent = track,
		})
	end
	local value = Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 56, 1, 0),
		Font = Theme.FontBlack,
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	return { fill = fill, value = value, row = row, track = track }
end

local function deltaPopup(meter, delta)
	if delta == 0 then
		return
	end
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -90, 0.5, 0),
		Size = UDim2.fromOffset(60, 26),
		Font = Theme.FontBlack,
		Text = (delta > 0 and "+" or "") .. tostring(delta),
		TextColor3 = delta > 0 and Colors.money or Colors.red,
		TextStrokeTransparency = 0.3,
		ZIndex = 5,
		Parent = meter.row,
	})
	Theme.tween(label, 1, { Position = label.Position - UDim2.fromOffset(0, 26), TextTransparency = 1, TextStrokeTransparency = 1 })
	task.delay(1.1, function()
		label:Destroy()
	end)
end

local function build()
	ui.root = Theme.create("Frame", {
		Name = "Pitch",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	})

	-- Cinematic letterbox.
	ui.barTop = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = ui.root,
	})
	ui.barBottom = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = ui.root,
	})

	-- Customer card (top left).
	local card = Theme.create("Frame", {
		Position = UDim2.new(0, 16, 0, 70),
		Size = UDim2.fromOffset(360, 250),
		BackgroundColor3 = Colors.bg,
		BackgroundTransparency = 0.08,
		Parent = ui.root,
	}, { Theme.corner(14), Theme.stroke(Colors.gold, 2), Theme.padding(14) })
	ui.name = Theme.label({
		Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.FontBlack,
		TextColor3 = Colors.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	ui.zone = Theme.label({
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 18),
		Font = Theme.Font,
		TextColor3 = Colors.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local meters = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundTransparency = 1,
		Parent = card,
	}, { Theme.create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	ui.meters = {}
	for order, info in METERS do
		ui.meters[info.key] = meterRow(meters, info, order)
	end
	ui.likes = Theme.label({
		Position = UDim2.fromOffset(0, 172),
		Size = UDim2.new(1, 0, 0, 18),
		Font = Theme.FontBold,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	ui.hates = Theme.label({
		Position = UDim2.fromOffset(0, 194),
		Size = UDim2.new(1, 0, 0, 18),
		Font = Theme.FontBold,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	ui.estimate = Theme.label({
		Position = UDim2.fromOffset(0, 216),
		Size = UDim2.new(1, 0, 0, 18),
		Font = Theme.FontBold,
		TextColor3 = Colors.money,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- Patience (top right of the card).
	ui.patience = Theme.create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.fromOffset(110, 20),
		BackgroundTransparency = 1,
		Parent = card,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 4),
		}),
	})

	-- Customer speech (center top).
	ui.speech = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 66),
		Size = UDim2.new(0.5, 0, 0, 40),
		Font = Theme.FontBlack,
		TextColor3 = Colors.text,
		TextStrokeTransparency = 0.3,
		Parent = ui.root,
	})

	-- Bottom area: options, tonality, actions.
	local bottom = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0.9, 0, 0, 250),
		BackgroundTransparency = 1,
		Parent = ui.root,
	}, { Theme.create("UISizeConstraint", { MaxSize = Vector2.new(1000, 250) }) })
	ui.bottom = bottom

	ui.options = Theme.create("Frame", {
		Size = UDim2.new(1, -190, 1, 0),
		BackgroundTransparency = 1,
		Parent = bottom,
	}, { Theme.create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	-- Tonality bar (replaces options while active).
	ui.tonality = Theme.create("Frame", {
		Size = UDim2.new(1, -190, 0, 150),
		Position = UDim2.fromOffset(0, 50),
		BackgroundColor3 = Colors.bg,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = bottom,
	}, { Theme.corner(14), Theme.stroke(Colors.gold, 2) })
	Theme.label({
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -32, 0, 28),
		Font = Theme.FontBlack,
		Text = "TONALITY!  Stop the needle in the green  [SPACE / CLICK]",
		TextColor3 = Colors.gold,
		Parent = ui.tonality,
	})
	local track = Theme.create("Frame", {
		Position = UDim2.new(0, 16, 0, 56),
		Size = UDim2.new(1, -32, 0, 44),
		BackgroundColor3 = Color3.fromRGB(80, 30, 30),
		Parent = ui.tonality,
	}, { Theme.corner(10), Theme.gradient(Color3.fromRGB(120, 40, 40), Color3.fromRGB(60, 20, 20), 0) })
	ui.sweet = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.2, 1),
		BackgroundColor3 = Color3.fromRGB(60, 220, 110),
		Parent = track,
	}, { Theme.corner(8) })
	ui.sweetCore = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.25, 1),
		BackgroundColor3 = Color3.fromRGB(180, 255, 190),
		Parent = ui.sweet,
	}, { Theme.corner(6) })
	ui.needle = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0, 6, 1, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = track,
	}, { Theme.corner(3), Theme.stroke(Color3.new(0, 0, 0), 1.5) })
	ui.tonalityHint = Theme.label({
		Position = UDim2.new(0, 16, 0, 108),
		Size = UDim2.new(1, -32, 0, 26),
		Font = Theme.FontBold,
		TextColor3 = Colors.muted,
		Parent = ui.tonality,
	})
	local tonalityClick = Theme.create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = ui.tonality,
	})
	tonalityClick.Activated:Connect(function()
		PitchUI.stopNeedle()
	end)

	-- Actions (right side).
	local actions = Theme.create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 176, 1, 0),
		BackgroundTransparency = 1,
		Parent = bottom,
	})
	ui.close = Theme.button({
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundColor3 = Color3.fromRGB(210, 160, 40),
		Font = Theme.FontBlack,
		Text = "CLOSE",
		TextColor3 = Color3.fromRGB(30, 20, 5),
		Parent = actions,
	}, function()
		PitchUI.close()
	end)
	Theme.corner(16).Parent = ui.close
	Theme.stroke(Color3.fromRGB(255, 230, 140), 3).Parent = ui.close
	Theme.gradient(Color3.fromRGB(255, 215, 90), Color3.fromRGB(200, 140, 30)).Parent = ui.close
	ui.leave = Theme.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Colors.panel,
		Font = Theme.FontBold,
		Text = "Walk away [X]",
		TextColor3 = Colors.muted,
		Parent = actions,
	}, function()
		PitchUI.leave()
	end)
	Theme.corner(10).Parent = ui.leave

	-- Result stamp.
	ui.stamp = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(520, 220),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 30,
		Parent = screen,
	})
	ui.stampTitle = Theme.label({
		Size = UDim2.new(1, 0, 0.55, 0),
		Font = Theme.FontBlack,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		Rotation = -6,
		ZIndex = 30,
		Parent = ui.stamp,
	})
	ui.stampAmount = Theme.label({
		Position = UDim2.fromScale(0, 0.55),
		Size = UDim2.new(1, 0, 0.3, 0),
		Font = Theme.FontBlack,
		TextStrokeTransparency = 0.2,
		ZIndex = 30,
		Parent = ui.stamp,
	})
	ui.stampLine = Theme.label({
		Position = UDim2.fromScale(0, 0.86),
		Size = UDim2.new(1, 0, 0.14, 0),
		Font = Theme.FontBold,
		TextStrokeTransparency = 0.3,
		ZIndex = 30,
		Parent = ui.stamp,
	})
end

-- Rendering ------------------------------------------------------------------

local function tagName(tag)
	return session and session.tags and session.tags[tag] or tag
end

local function renderTags()
	local likes = {}
	for _, tag in session.customer.likes do
		table.insert(likes, string.format('<font color="#%s">%s</font>', Theme.TagColors[tag]:ToHex(), tagName(tag)))
	end
	ui.likes.Text = "Likes: " .. (#likes > 0 and table.concat(likes, ", ") or "anything")
	local hates = {}
	for _, tag in session.customer.dislikes do
		if revealedDislikes[tag] then
			table.insert(hates, string.format('<font color="#%s">%s</font>', Theme.TagColors[tag]:ToHex(), tagName(tag)))
		else
			table.insert(hates, '<font color="#777777">???</font>')
		end
	end
	ui.hates.Text = "Hates: " .. (#hates > 0 and table.concat(hates, ", ") or "nothing")
end

local function renderMeters(deltas)
	for _, info in METERS do
		local meter = ui.meters[info.key]
		local value = session.meters[info.key]
		Theme.tween(meter.fill, 0.45, { Size = UDim2.fromScale(value / 10, 1) }, Enum.EasingStyle.Back)
		meter.value.Text = (value % 1 == 0) and string.format("%d", value) or string.format("%.1f", value)
		if deltas and deltas[info.key] then
			deltaPopup(meter, deltas[info.key])
		end
	end
	for _, child in ui.patience:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i = 1, session.maxPatience do
		Theme.create("Frame", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = i <= session.patience and Colors.gold or Colors.panelLight,
			Parent = ui.patience,
		}, { Theme.corner(8) })
	end
	local chance = math.floor(session.closeChance * 100 + 0.5)
	ui.close.Text = string.format("CLOSE\n%d%%", chance)
end

local function renderOptions()
	for _, child in ui.options:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if #session.options == 0 then
		local note = Theme.button({
			Size = UDim2.new(1, 0, 0, 70),
			BackgroundColor3 = Colors.panel,
			Font = Theme.FontBlack,
			Text = "LAST CHANCE: Close now, or they walk!",
			TextColor3 = Colors.red,
			Parent = ui.options,
		})
		Theme.corner(12).Parent = note
		return
	end
	for index, option in session.options do
		local color = Theme.TagColors[option.tag] or Colors.text
		local button = Theme.button({
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 74),
			BackgroundColor3 = option.napkin and Color3.fromRGB(70, 55, 10) or Colors.panel,
			BackgroundTransparency = 0.05,
			Parent = ui.options,
		}, function()
			PitchUI.choose(index)
		end)
		Theme.corner(12).Parent = button
		Theme.stroke(color, option.napkin and 3 or 1.5).Parent = button
		Theme.label({
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.fromOffset(34, 58),
			Font = Theme.FontBlack,
			Text = tostring(index),
			TextColor3 = color,
			Parent = button,
		})
		Theme.label({
			Position = UDim2.fromOffset(54, 6),
			Size = UDim2.new(1, -66, 0, 18),
			Font = Theme.FontBlack,
			Text = string.upper(tagName(option.tag)),
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = button,
		})
		Theme.label({
			Position = UDim2.fromOffset(54, 26),
			Size = UDim2.new(1, -66, 0, 40),
			Font = Theme.FontBold,
			Text = '"' .. option.text .. '"',
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = button,
		})
	end
end

local function say(text, color)
	ui.speech.Text = text or ""
	ui.speech.TextColor3 = color or Colors.text
	Theme.pop(ui.speech, 0.25)
end

local function setPhase(newPhase)
	phase = newPhase
	ui.options.Visible = newPhase == "choose" or newPhase == "waiting"
	ui.tonality.Visible = newPhase == "tonality"
end

-- Actions ------------------------------------------------------------------------

function PitchUI.choose(index)
	if phase ~= "choose" or not session.options[index] then
		return
	end
	chosenIndex = index
	playDing(1.2)
	needle.pos = math.random()
	needle.dir = math.random() < 0.5 and -1 or 1
	needle.center = 0.2 + math.random() * 0.6
	needle.speed = 1.1 + (session.customer.budget or 1) * 0.04 + math.random() * 0.3
	ui.sweet.Position = UDim2.fromScale(needle.center, 0)
	ui.sweet.Size = UDim2.fromScale(session.sweetSpot, 1)
	ui.tonalityHint.Text = '"' .. session.options[index].text .. '"'
	setPhase("tonality")
end

function PitchUI.stopNeedle()
	if phase ~= "tonality" then
		return
	end
	local distance = math.abs(needle.pos - needle.center)
	local half = session.sweetSpot / 2
	local accuracy
	if distance <= half then
		accuracy = 1 - 0.2 * (distance / half)
	else
		accuracy = math.max(0, 0.8 - (distance - half) * 2.4)
	end
	local verdict
	if accuracy >= 0.95 then
		verdict = "PERFECT TONALITY!"
	elseif accuracy >= 0.8 then
		verdict = "Smooth."
	elseif accuracy >= 0.4 then
		verdict = "A bit shaky..."
	else
		verdict = "You mumbled it."
	end
	say(verdict, accuracy >= 0.8 and Colors.money or Colors.red)
	setPhase("waiting")
	Remotes.PitchAction:FireServer({ type = "line", index = chosenIndex, tonality = accuracy })
end

function PitchUI.close()
	if phase ~= "choose" then
		return
	end
	setPhase("waiting")
	say("...", Colors.muted)
	Remotes.PitchAction:FireServer({ type = "close" })
end

function PitchUI.leave()
	if phase == "idle" or phase == "ended" then
		return
	end
	Remotes.PitchAction:FireServer({ type = "leave" })
end

local function showStamp(title, titleColor, amount, amountColor, line)
	ui.stamp.Visible = true
	ui.stampTitle.Text = title
	ui.stampTitle.TextColor3 = titleColor
	ui.stampAmount.Text = amount or ""
	ui.stampAmount.TextColor3 = amountColor or Colors.money
	ui.stampLine.Text = line or ""
	ui.stampTitle.TextTransparency = 0
	ui.stampAmount.TextTransparency = 0
	ui.stampLine.TextTransparency = 0
	local scale = ui.stamp:FindFirstChildOfClass("UIScale") or Theme.create("UIScale", { Parent = ui.stamp })
	scale.Scale = 2.2
	Theme.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(2.6, function()
		Theme.tween(ui.stampTitle, 0.4, { TextTransparency = 1 })
		Theme.tween(ui.stampAmount, 0.4, { TextTransparency = 1 })
		Theme.tween(ui.stampLine, 0.4, { TextTransparency = 1 })
		task.wait(0.45)
		ui.stamp.Visible = false
	end)
end

local function confetti()
	for _ = 1, 40 do
		local piece = Theme.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.random(-40, 40), 0.42, 0),
			Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 24)),
			BackgroundColor3 = ({ Colors.money, Colors.gold, Color3.new(1, 1, 1) })[math.random(1, 3)],
			BorderSizePixel = 0,
			Rotation = math.random(0, 360),
			ZIndex = 29,
			Parent = screen,
		})
		Theme.tween(piece, 1.6 + math.random(), {
			Position = UDim2.new(0.5 + (math.random() - 0.5) * 1.1, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-400, 400),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(2.8, function()
			piece:Destroy()
		end)
	end
end

-- Plant your feet while pitching (Space is needed for the tonality bar).
local frozen
local function freezeCharacter(freeze)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if freeze and not frozen then
		frozen = { walk = humanoid.WalkSpeed, jump = humanoid.JumpPower, jumpHeight = humanoid.JumpHeight }
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	elseif not freeze and frozen then
		humanoid.WalkSpeed = frozen.walk
		humanoid.JumpPower = frozen.jump
		humanoid.JumpHeight = frozen.jumpHeight
		frozen = nil
	end
end

local function openUI()
	Modal.closeAll()
	freezeCharacter(true)
	ui.root.Visible = true
	Theme.tween(ui.barTop, 0.4, { Size = UDim2.new(1, 0, 0, 54) })
	Theme.tween(ui.barBottom, 0.4, { Size = UDim2.new(1, 0, 0, 54) })
	Theme.pop(ui.bottom, 0.35)
end

local function closeUI()
	phase = "ended"
	Theme.tween(ui.barTop, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
	Theme.tween(ui.barBottom, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
	task.delay(0.3, function()
		if phase == "ended" then
			ui.root.Visible = false
			phase = "idle"
		end
	end)
	stopCamera()
	freezeCharacter(false)
	Store.inPitch = false
end

-- Server events -------------------------------------------------------------------

local function onStart(data)
	session = data
	revealedDislikes = {}
	Store.inPitch = true
	ui.name.Text = data.customer.name
	ui.zone.Text = data.customer.zone .. "  ·  selling: " .. data.pen
	ui.estimate.Text = "Sale value: ~" .. Format.cash(data.estimate) .. " (more with certainty)"
	renderTags()
	renderMeters()
	renderOptions()
	say('"' .. data.customer.greeting .. '"', Colors.text)
	openUI()
	setPhase("choose")
	startCamera(data.model)
	playDing(0.8)
end

local function onUpdate(data)
	if not session then
		return
	end
	session.meters = data.meters
	session.patience = data.patience
	session.options = data.options
	session.closeChance = data.closeChance
	renderMeters(data.deltas)
	renderOptions()
	if data.napkin then
		say('"' .. data.reaction .. '"', Colors.gold)
		playDing(1.5)
	elseif data.reaction then
		say('"' .. data.reaction .. '"', (data.closeFailed or data.disliked) and Colors.red or Colors.text)
	end
	setPhase("choose")
end

local function onEnd(data)
	if not session then
		return
	end
	if data.result == "sold" then
		local title = data.perfect and "PERFECT CLOSE!" or (data.napkin and "SUPPLY & DEMAND!" or "SOLD!")
		showStamp(title, Colors.gold, "+" .. Format.cash(data.amount), Colors.money, data.line and ('"' .. data.line .. '"'))
		confetti()
		playDing(1)
		task.delay(0.15, playDing, 1.25)
		task.delay(0.3, playDing, 1.5)
	elseif data.result == "busted" then
		showStamp("BUSTED!", Colors.red, Format.cash(data.amount), Colors.red, data.line)
	elseif data.result == "walked" then
		showStamp("NO SALE", Colors.red, "", nil, data.line and ('"' .. data.line .. '"'))
	end
	session = nil
	closeUI()
end

function PitchUI.mount(screenGui)
	screen = screenGui
	build()

	Remotes.PitchStart.OnClientEvent:Connect(onStart)
	Remotes.PitchUpdate.OnClientEvent:Connect(function(data)
		-- Reveal which hated tag we just hit.
		if data.disliked and session and chosenIndex and session.options[chosenIndex] then
			revealedDislikes[session.options[chosenIndex].tag] = true
			renderTags()
		end
		onUpdate(data)
	end)
	Remotes.PitchEnd.OnClientEvent:Connect(onEnd)

	RunService.RenderStepped:Connect(function(dt)
		if phase ~= "tonality" then
			return
		end
		needle.pos += needle.dir * needle.speed * dt
		if needle.pos > 1 then
			needle.pos = 1
			needle.dir = -1
		elseif needle.pos < 0 then
			needle.pos = 0
			needle.dir = 1
		end
		ui.needle.Position = UDim2.fromScale(needle.pos, 0.5)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if phase == "idle" or phase == "ended" then
			return
		end
		local key = input.KeyCode
		if phase == "tonality" and (key == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 or key == Enum.KeyCode.ButtonA) then
			PitchUI.stopNeedle()
			return
		end
		if processed then
			return
		end
		if key == Enum.KeyCode.One then
			PitchUI.choose(1)
		elseif key == Enum.KeyCode.Two then
			PitchUI.choose(2)
		elseif key == Enum.KeyCode.Three then
			PitchUI.choose(3)
		elseif key == Enum.KeyCode.C then
			PitchUI.close()
		elseif key == Enum.KeyCode.X then
			PitchUI.leave()
		end
	end)
end

return PitchUI
