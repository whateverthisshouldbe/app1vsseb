--!strict
-- Kleine bouwstenen voor de interface, zodat HUD en vensters dezelfde stijl
-- hebben: ronde hoeken, dikke randen en het FredokaOne-lettertype.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local UI = {}

UI.FONT = Enum.Font.FredokaOne

UI.colors = {
	bg = Color3.fromRGB(22, 14, 36),
	panel = Color3.fromRGB(38, 26, 60),
	panelLight = Color3.fromRGB(56, 40, 86),
	accent = Color3.fromRGB(255, 80, 170),
	green = Color3.fromRGB(80, 220, 110),
	yellow = Color3.fromRGB(255, 205, 60),
	red = Color3.fromRGB(255, 70, 90),
	blue = Color3.fromRGB(70, 170, 255),
	purple = Color3.fromRGB(170, 100, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 178, 220),
	dark = Color3.fromRGB(12, 6, 22),
	grey = Color3.fromRGB(90, 84, 104),
}

function UI.rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Maakt een instance met eigenschappen; Parent wordt als laatste gezet
function UI.new(className: string, props: { [string]: any }?, children: { any }?): any
	local inst: any = Instance.new(className)
	local parent = nil
	local properties: { [string]: any } = props or {}
	local childList: { any } = children or {}
	for key, value in properties do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	for _, child in childList do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(radius: number?): any
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function UI.round(): any
	return UI.new("UICorner", { CornerRadius = UDim.new(1, 0) })
end

function UI.border(color: Color3?, thickness: number?): any
	return UI.new("UIStroke", {
		Color = color or UI.colors.dark,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.textStroke(thickness: number?): any
	return UI.new("UIStroke", {
		Color = UI.colors.dark,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	})
end

function UI.gradient(top: Color3, bottom: Color3): any
	return UI.new("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = 90,
	})
end

function UI.padding(pixels: number): any
	local p = UDim.new(0, pixels)
	return UI.new("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

-- Eigen opties die geen Roblox-eigenschap zijn
local CUSTOM_KEYS = { Parent = true, color = true, radius = true, strokeThickness = true }

function UI.text(props: { [string]: any }): TextLabel
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = UI.FONT,
		TextScaled = true,
		TextColor3 = UI.colors.text,
		Size = UDim2.fromScale(1, 1),
	})
	for key, value in props do
		if not CUSTOM_KEYS[key] then
			label[key] = value
		end
	end
	UI.textStroke(props.strokeThickness).Parent = label
	label.Parent = props.Parent
	return label
end

local soundCache: { [string]: Sound } = {}

function UI.sound(name: string, speed: number?, volume: number?)
	local id = (Config.Sounds :: any)[name]
	if not id or id == "" then
		return
	end
	local template = soundCache[name]
	if not template then
		template = UI.new("Sound", { SoundId = id, Volume = 0.5, Name = name })
		soundCache[name] = template
	end
	local sound = template:Clone()
	sound.PlaybackSpeed = speed or 1
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	sound:Play()
	task.delay(4, function()
		sound:Destroy()
	end)
end

function UI.tween(inst: Instance, seconds: number, props: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

-- Kort opveren, voor knoppen en het geldbedrag
function UI.pop(scale: UIScale, amount: number?)
	scale.Scale = 1 + (amount or 0.12)
	UI.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Knop met hover- en klik-effect
function UI.button(props: { [string]: any }, onClick: () -> ()): TextButton
	local color = props.color or UI.colors.green
	local button = UI.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Font = UI.FONT,
		TextScaled = true,
		TextColor3 = UI.colors.text,
		Text = "",
	})
	for key, value in props do
		if not CUSTOM_KEYS[key] then
			button[key] = value
		end
	end
	UI.corner(props.radius or 12).Parent = button
	UI.border(UI.colors.dark, 3).Parent = button
	UI.gradient(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)).Parent = button
	UI.textStroke(2).Parent = button
	local scale = UI.new("UIScale", { Parent = button })

	button.MouseEnter:Connect(function()
		UI.tween(scale, 0.12, { Scale = 1.06 })
	end)
	button.MouseLeave:Connect(function()
		UI.tween(scale, 0.12, { Scale = 1 })
	end)
	button.Activated:Connect(function()
		UI.pop(scale, -0.08)
		UI.sound("Click", 1.1, 0.4)
		onClick()
	end)
	button.Parent = props.Parent
	return button
end

return UI
