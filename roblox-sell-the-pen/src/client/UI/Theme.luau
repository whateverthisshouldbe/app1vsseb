-- Colors, fonts and tiny helpers for building UI in code.

local TweenService = game:GetService("TweenService")

local Theme = {}

-- Bright, chunky "simulator" style: saturated gradients, thick black
-- outlines and a cartoon font with outlined text.
Theme.Colors = {
	bg = Color3.fromRGB(28, 36, 78),
	panel = Color3.fromRGB(42, 54, 110),
	panelLight = Color3.fromRGB(62, 78, 150),
	stroke = Color3.fromRGB(15, 15, 25),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(185, 200, 240),
	money = Color3.fromRGB(110, 255, 120),
	gold = Color3.fromRGB(255, 210, 60),
	red = Color3.fromRGB(255, 70, 70),
	blue = Color3.fromRGB(70, 180, 255),
	purple = Color3.fromRGB(200, 110, 255),
	pen = Color3.fromRGB(110, 190, 255),
	you = Color3.fromRGB(255, 170, 70),
	firm = Color3.fromRGB(190, 130, 255),
}

Theme.TagColors = {
	rapport = Color3.fromRGB(255, 150, 180),
	question = Color3.fromRGB(110, 200, 255),
	product = Color3.fromRGB(120, 230, 150),
	urgency = Color3.fromRGB(255, 170, 60),
	authority = Color3.fromRGB(190, 140, 255),
	hype = Color3.fromRGB(255, 90, 200),
	pressure = Color3.fromRGB(255, 80, 80),
	honest = Color3.fromRGB(220, 220, 220),
	napkin = Color3.fromRGB(255, 215, 60),
}

Theme.Font = Enum.Font.FredokaOne
Theme.FontBold = Enum.Font.FredokaOne
Theme.FontBlack = Enum.Font.LuckiestGuy
Theme.FontMono = Enum.Font.Code

-- Gradients for the big buttons, top to bottom.
Theme.Gradients = {
	orange = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 110, 20) },
	green = { Color3.fromRGB(120, 240, 90), Color3.fromRGB(30, 160, 60) },
	red = { Color3.fromRGB(255, 110, 90), Color3.fromRGB(200, 30, 50) },
	purple = { Color3.fromRGB(230, 120, 255), Color3.fromRGB(130, 40, 220) },
	blue = { Color3.fromRGB(110, 210, 255), Color3.fromRGB(30, 110, 230) },
	gold = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(240, 160, 20) },
	gray = { Color3.fromRGB(215, 220, 235), Color3.fromRGB(140, 150, 175) },
	navy = { Color3.fromRGB(60, 80, 170), Color3.fromRGB(25, 32, 80) },
}

-- Rainbow used on the rarest things.
Theme.Rainbow = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 50)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 255, 110)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 90, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 200)),
})

-- create("Frame", { Size = ..., Parent = ... }, { children })
function Theme.create(className, props, children)
	local instance = Instance.new(className)
	local parent
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Theme.corner(radius)
	return Theme.create("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Theme.stroke(color, thickness, transparency)
	return Theme.create("UIStroke", {
		Color = color or Theme.Colors.stroke,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(all)
	local p = UDim.new(0, all)
	return Theme.create("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

function Theme.gradient(a, b, rotation)
	return Theme.create("UIGradient", {
		Color = ColorSequence.new(a, b),
		Rotation = rotation or 90,
	})
end

function Theme.label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextColor3 = Theme.Colors.text,
		TextScaled = true,
		Text = "",
	}
	for key, value in props do
		defaults[key] = value
	end
	local children = defaults.Children
	local outline = defaults.Outline
	defaults.Children = nil
	defaults.Outline = nil
	local label = Theme.create("TextLabel", defaults, children)
	Theme.outline(label, outline)
	return label
end

-- Black text outline (the chunky cartoon look). Pass false to skip, or a thickness.
function Theme.outline(textObject, thickness)
	if thickness == false then
		return
	end
	Theme.create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Color = Color3.fromRGB(10, 10, 20),
		Thickness = type(thickness) == "number" and thickness or 2,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = textObject,
	})
end

-- A vertical gradient fill from Theme.Gradients (or two colors).
function Theme.fill(parent, gradient, rotation)
	local colors = type(gradient) == "string" and Theme.Gradients[gradient] or gradient
	return Theme.create("UIGradient", {
		Color = ColorSequence.new(colors[1], colors[2]),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

function Theme.button(props, onClick)
	local defaults = {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Colors.panelLight,
		Font = Theme.FontBold,
		TextColor3 = Theme.Colors.text,
		TextScaled = true,
		Text = "",
	}
	for key, value in props do
		defaults[key] = value
	end
	local children = defaults.Children
	local outline = defaults.Outline
	defaults.Children = nil
	defaults.Outline = nil
	local button = Theme.create("TextButton", defaults, children)
	-- Buttons usually get a border UIStroke too, so outline the text the classic way.
	if outline ~= false then
		button.TextStrokeTransparency = 0
		button.TextStrokeColor3 = Color3.fromRGB(10, 10, 20)
	end
	local scale = Theme.create("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		Theme.tween(scale, 0.12, { Scale = 1.05 })
	end)
	button.MouseLeave:Connect(function()
		Theme.tween(scale, 0.12, { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		Theme.tween(scale, 0.06, { Scale = 0.95 })
	end)
	button.MouseButton1Up:Connect(function()
		Theme.tween(scale, 0.1, { Scale = 1.05 })
	end)
	if onClick then
		button.Activated:Connect(onClick)
	end
	return button
end

function Theme.tween(instance, duration, goal, style, direction)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

-- Pop in from small.
function Theme.pop(instance, duration)
	local scale = instance:FindFirstChildOfClass("UIScale") or Theme.create("UIScale", { Parent = instance })
	scale.Scale = 0.6
	Theme.tween(scale, duration or 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

return Theme
