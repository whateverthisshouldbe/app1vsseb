-- A centered window: colored header with a chunky outlined title, a navy
-- body and a big red close button.

local Theme = require(script.Parent.Theme)
local Colors = Theme.Colors

local Modal = {}
Modal.__index = Modal

local openModal

-- Fires with a modal's `key` whenever one opens (the tutorial listens).
local opened = Instance.new("BindableEvent")
Modal.Opened = opened.Event

local ACCENT_GRADIENT = {
	[Colors.money] = "green",
	[Colors.gold] = "gold",
	[Colors.purple] = "purple",
	[Colors.blue] = "blue",
	[Colors.firm] = "purple",
	[Colors.red] = "red",
}

-- `maxSize` is the size on a big screen; on phones the window shrinks to fit.
function Modal.new(screen, title, accent, maxSize)
	local self = setmetatable({}, Modal)
	maxSize = maxSize or Vector2.new(640, 460)
	accent = accent or Colors.money
	self.frame = Theme.create("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.94, 0.86),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	}, {
		Theme.corner(22),
		Theme.stroke(Colors.stroke, 4),
		Theme.create("UISizeConstraint", { MaxSize = maxSize }),
	})
	Theme.fill(self.frame, "navy")

	local bar = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = self.frame,
	}, {
		Theme.corner(22),
	})
	Theme.fill(bar, ACCENT_GRADIENT[accent] or "blue")
	-- Square off the bottom corners of the header.
	local seam = Theme.create("Frame", {
		Position = UDim2.new(0, 0, 1, -22),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = bar,
	})
	Theme.fill(seam, { (Theme.Gradients[ACCENT_GRADIENT[accent] or "blue"])[2], (Theme.Gradients[ACCENT_GRADIENT[accent] or "blue"])[2] })
	Theme.create("Frame", {
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Colors.stroke,
		BorderSizePixel = 0,
		Parent = bar,
	})
	Theme.label({
		Position = UDim2.new(0, 22, 0, 10),
		Size = UDim2.new(1, -100, 0, 44),
		Font = Theme.FontBlack,
		Text = title,
		TextColor3 = Colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 3,
		Parent = bar,
	})
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 8, 0, -8),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Font = Theme.FontBlack,
		Text = "X",
		TextColor3 = Colors.text,
		ZIndex = 12,
		Parent = self.frame,
	}, function()
		self:close()
	end)
	Theme.corner(14).Parent = close
	Theme.stroke(Colors.stroke, 3).Parent = close
	Theme.fill(close, "red")

	self.content = Theme.create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 16, 0, 74),
		Size = UDim2.new(1, -32, 1, -88),
		BackgroundTransparency = 1,
		Parent = self.frame,
	})
	return self
end

function Modal:open()
	if openModal and openModal ~= self then
		openModal:close()
	end
	openModal = self
	self.frame.Visible = true
	Theme.pop(self.frame, 0.3)
	if self.onOpen then
		self.onOpen()
	end
	opened:Fire(self.key)
end

function Modal:close()
	self.frame.Visible = false
	if openModal == self then
		openModal = nil
	end
end

function Modal:toggle()
	if self.frame.Visible then
		self:close()
	else
		self:open()
	end
end

function Modal.closeAll()
	if openModal then
		openModal:close()
	end
end

return Modal
