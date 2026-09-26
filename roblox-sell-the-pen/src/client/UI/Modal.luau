-- A centered window with a title bar and a close button.

local Theme = require(script.Parent.Theme)
local Colors = Theme.Colors

local Modal = {}
Modal.__index = Modal

local openModal

-- `maxSize` is the size on a big screen; on phones the window shrinks to fit.
function Modal.new(screen, title, accent, maxSize)
	local self = setmetatable({}, Modal)
	maxSize = maxSize or Vector2.new(640, 460)
	self.frame = Theme.create("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.88),
		BackgroundColor3 = Colors.bg,
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	}, {
		Theme.corner(18),
		Theme.stroke(accent or Colors.money, 2.5),
		Theme.create("UISizeConstraint", { MaxSize = maxSize }),
	})

	local bar = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Colors.panel,
		ZIndex = 10,
		Parent = self.frame,
	}, {
		Theme.corner(18),
		Theme.gradient(Colors.panelLight, Colors.panel),
	})
	Theme.label({
		Position = UDim2.new(0, 20, 0, 10),
		Size = UDim2.new(1, -90, 0, 36),
		Font = Theme.FontBlack,
		Text = title,
		TextColor3 = accent or Colors.money,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
		Parent = bar,
	})
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Colors.red,
		Font = Theme.FontBlack,
		Text = "X",
		ZIndex = 11,
		Parent = bar,
	}, function()
		self:close()
	end)
	Theme.corner(10).Parent = close

	self.content = Theme.create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 16, 0, 66),
		Size = UDim2.new(1, -32, 1, -80),
		BackgroundTransparency = 1,
		ZIndex = 10,
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
