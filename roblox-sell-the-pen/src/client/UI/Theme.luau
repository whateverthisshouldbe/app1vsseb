-- Colors, fonts and tiny helpers for building UI in code.

local TweenService = game:GetService("TweenService")

local Theme = {}

Theme.Colors = {
	bg = Color3.fromRGB(12, 16, 14),
	panel = Color3.fromRGB(20, 27, 24),
	panelLight = Color3.fromRGB(30, 40, 35),
	stroke = Color3.fromRGB(60, 80, 68),
	text = Color3.fromRGB(235, 240, 232),
	muted = Color3.fromRGB(150, 165, 155),
	money = Color3.fromRGB(90, 235, 130),
	gold = Color3.fromRGB(255, 200, 70),
	red = Color3.fromRGB(240, 70, 70),
	blue = Color3.fromRGB(90, 170, 255),
	purple = Color3.fromRGB(190, 120, 255),
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

Theme.Font = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold
Theme.FontBlack = Enum.Font.GothamBlack
Theme.FontMono = Enum.Font.Code

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
	defaults.Children = nil
	return Theme.create("TextLabel", defaults, children)
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
	defaults.Children = nil
	local button = Theme.create("TextButton", defaults, children)
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
