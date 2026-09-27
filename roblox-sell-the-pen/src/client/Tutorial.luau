-- The playthrough tutorial: a quest card that walks new players through
-- everything, with a guide line to the nearest customer and a bouncing
-- arrow on the button you need. Finishing it pays x2 money for a while.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local TutorialData = require(ReplicatedStorage.Shared.Tutorial)
local Theme = require(script.Parent.UI.Theme)
local Hud = require(script.Parent.UI.Hud)
local Modal = require(script.Parent.UI.Modal)
local PitchUI = require(script.Parent.UI.PitchUI)
local Movement = require(script.Parent.Movement)
local Store = require(script.Parent.Store)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local Colors = Theme.Colors
local Steps = TutorialData.Steps

local Tutorial = {}

local completed -- number of finished steps (local, so the card reacts instantly)
local done = false
local card, cardTitle, cardText, cardBar, cardCount
local arrow
local beam, beamStart, beamEnd, marker
local linesPicked = 0
local sprinted, flipped = false, false

local function current()
	return completed and Steps[completed + 1]
end

local function render()
	local step = current()
	if done or not step then
		card.Visible = false
		arrow.Visible = false
		return
	end
	card.Visible = true
	cardCount.Text = string.format("TUTORIAL %d/%d", step.index, #Steps)
	cardTitle.Text = step.title
	cardText.Text = step.text
	Theme.tween(cardBar, 0.3, { Size = UDim2.fromScale((step.index - 1) / #Steps, 1) })
	Theme.pop(card, 0.3)
	sprinted, flipped = false, false
	local profile = Store.profile()
	if step.id == "shop" and profile and profile.pen ~= "bic" then
		-- Already upgraded: nothing to teach here.
		task.defer(function()
			Tutorial.complete("shop")
		end)
	end
end

function Tutorial.complete(stepId)
	local step = current()
	if done or not step or step.id ~= stepId then
		return
	end
	completed = step.index
	Remotes.Tutorial:FireServer(step.id)
	if completed >= #Steps then
		done = true
	end
	render()
end

-- A pitch fell through before the deal: back to "find a customer".
local function resetPitchPart()
	local step = current()
	if step and step.index <= TutorialData.byId.deal.index and step.index > 1 then
		completed = 0
		linesPicked = 0
		Remotes.Tutorial:FireServer("reset")
		render()
	end
end

-- Guide line to the nearest customer you're allowed to pitch.
local function nearestCustomer()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local folder = Workspace:FindFirstChild("Customers")
	local profile = Store.profile()
	if not root or not folder or not profile then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, model in folder:GetChildren() do
		local zoneId = model:GetAttribute("Zone")
		local customerRoot = model:FindFirstChild("HumanoidRootPart")
		local prompt = customerRoot and customerRoot:FindFirstChild("PitchPrompt")
		if customerRoot and prompt and prompt.Enabled and zoneId and Config.zoneUnlocked(profile, zoneId) then
			local distance = (customerRoot.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = model, distance
			end
		end
	end
	return best
end

local function buildGuides(screen)
	beamStart = Instance.new("Attachment")
	beamStart.Name = "TutorialStart"
	beamEnd = Instance.new("Attachment")
	beamEnd.Name = "TutorialEnd"
	beam = Instance.new("Beam")
	beam.Name = "TutorialGuide"
	beam.Color = ColorSequence.new(Colors.gold)
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.Segments = 1
	beam.Transparency = NumberSequence.new(0.2)
	beam.Attachment0 = beamStart
	beam.Attachment1 = beamEnd
	beam.Enabled = false
	beam.Parent = Workspace.Terrain
	beamStart.Parent = Workspace.Terrain
	beamEnd.Parent = Workspace.Terrain

	marker = Theme.create("BillboardGui", {
		Name = "TutorialMarker",
		Size = UDim2.fromOffset(140, 70),
		StudsOffset = Vector3.new(0, 5.5, 0),
		AlwaysOnTop = true,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	Theme.label({
		Size = UDim2.fromScale(1, 1),
		Font = Theme.FontBlack,
		Text = "PITCH ME!\n▼",
		TextColor3 = Colors.gold,
		Outline = 3,
		Parent = marker,
	})

	arrow = Theme.label({
		Name = "TutorialArrow",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(60, 60),
		Font = Theme.Font,
		Text = "👈",
		Visible = false,
		ZIndex = 20,
		Outline = false,
		Parent = screen,
	})
end

local function buildCard(screen)
	card = Theme.create("Frame", {
		Name = "TutorialCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.new(0.9, 0, 0, 118),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		Parent = screen,
	}, {
		Theme.corner(16),
		Theme.stroke(Colors.stroke, 3.5),
		Theme.create("UISizeConstraint", { MaxSize = Vector2.new(520, 118) }),
	})
	Theme.fill(card, "blue")
	cardCount = Theme.label({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(0.5, 0, 0, 22),
		Font = Theme.FontBlack,
		TextColor3 = Colors.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 2,
		Parent = card,
	})
	Theme.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 6),
		Size = UDim2.new(0.5, -14, 0, 22),
		Font = Theme.FontBlack,
		Text = string.format("REWARD: x%d MONEY %dMIN", TutorialData.RewardMult, TutorialData.RewardDuration / 60),
		TextColor3 = Colors.money,
		TextXAlignment = Enum.TextXAlignment.Right,
		Outline = 2,
		Parent = card,
	})
	cardTitle = Theme.label({
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -28, 0, 30),
		Font = Theme.FontBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 2.5,
		Parent = card,
	})
	cardText = Theme.label({
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 0, 36),
		Font = Theme.FontBold,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Outline = 1.5,
		Parent = card,
	})
	local track = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -28, 0, 10),
		BackgroundColor3 = Color3.fromRGB(20, 30, 70),
		Parent = card,
	}, { Theme.corner(5), Theme.stroke(Colors.stroke, 2) })
	cardBar = Theme.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Colors.gold,
		Parent = track,
	}, { Theme.corner(5) })
end

local function screenWidth()
	return Workspace.CurrentCamera.ViewportSize.X
end

-- Per-frame: move the guide line, marker and arrow for the current step.
local function updateGuides()
	local step = current()
	local target = step and not done and step.target
	local showBeam = target == "customer" and not Store.inPitch
	local customer = showBeam and nearestCustomer()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if customer and root then
		beam.Enabled = true
		beamStart.WorldPosition = root.Position - Vector3.new(0, 2.5, 0)
		beamEnd.WorldPosition = customer.HumanoidRootPart.Position - Vector3.new(0, 2.5, 0)
		marker.Adornee = customer:FindFirstChild("Head")
		marker.Enabled = true
		marker.StudsOffset = Vector3.new(0, 5 + math.sin(os.clock() * 5) * 0.4, 0)
	else
		beam.Enabled = false
		marker.Enabled = false
	end

	local button = target and Hud.buttons[target]
	if button and button.Visible and not Store.inPitch then
		arrow.Visible = true
		local position = button.AbsolutePosition
		local size = button.AbsoluteSize
		local bounce = math.sin(os.clock() * 8) * 8
		if position.X > screenWidth() / 2 then
			-- Button on the right: point at it from the left.
			arrow.Text = "👉"
			arrow.Position = UDim2.fromOffset(position.X - 66 - bounce, position.Y + size.Y / 2)
		else
			arrow.Text = "👈"
			arrow.Position = UDim2.fromOffset(position.X + size.X + 6 + bounce, position.Y + size.Y / 2)
		end
	else
		arrow.Visible = false
	end
	-- Keep the card out of the way of the pitch screen.
	card.Position = Store.inPitch and UDim2.new(0.5, 0, 0.3, 0) or UDim2.new(0.5, 0, 0, 86)
end

function Tutorial.start(screen)
	buildCard(screen)
	buildGuides(screen)

	-- Wait for the saved progress.
	task.spawn(function()
		repeat
			task.wait(0.25)
		until Store.profile()
		local profile = Store.profile()
		done = profile.tutorialDone == true
		completed = profile.tutorialStep or 0
		render()
	end)

	PitchUI.Event:Connect(function(event)
		if event == "start" then
			Tutorial.complete("talk")
		elseif event == "line" then
			Tutorial.complete("line")
		elseif event == "tonality" then
			linesPicked += 1
			Tutorial.complete("tonality")
			if linesPicked >= 2 then
				Tutorial.complete("meters")
			end
		elseif event == "close" then
			-- Closing early skips straight past the meters lesson.
			Tutorial.complete("meters")
			Tutorial.complete("close")
		elseif event == "deal" then
			Tutorial.complete("close")
		elseif event == "done" then
			Tutorial.complete("deal")
		elseif event == "failed" then
			resetPitchPart()
		end
	end)
	Modal.Opened:Connect(function(key)
		if key == "firm" or key == "index" or key == "teleport" or key == "rebirth" then
			Tutorial.complete(key)
		end
	end)
	Movement.Event:Connect(function(event)
		local step = current()
		if not step or step.id ~= "move" then
			return
		end
		if event == "sprint" then
			sprinted = true
		elseif event == "flip" then
			flipped = true
		end
		if sprinted and flipped then
			Tutorial.complete("move")
		end
	end)
	Store.Changed:Connect(function(data)
		if data.profile.pen ~= "bic" then
			Tutorial.complete("shop")
		end
		if data.profile.tutorialDone and not done then
			done = true
			render()
		end
	end)

	RunService.RenderStepped:Connect(updateGuides)
end

return Tutorial
