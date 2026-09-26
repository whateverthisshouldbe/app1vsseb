-- Stacking toast notifications on the right side of the screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)

local Notifier = {}

local KIND_COLORS = {
	info = Theme.Colors.blue,
	success = Theme.Colors.money,
	error = Theme.Colors.red,
	big = Theme.Colors.gold,
	event = Theme.Colors.purple,
}

local container

function Notifier.mount(screen)
	container = Theme.create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 90),
		Size = UDim2.new(0, 340, 0.6, 0),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Theme.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
		Theme.create("UISizeConstraint", { MaxSize = Vector2.new(340, math.huge) }),
	})

	ReplicatedStorage.Remotes.Notify.OnClientEvent:Connect(Notifier.show)
end

local order = 0
function Notifier.show(text, kind)
	if not container then
		return
	end
	order += 1
	local color = KIND_COLORS[kind] or KIND_COLORS.info
	local toast = Theme.create("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.panel,
		BackgroundTransparency = 0.08,
		Parent = container,
	}, {
		Theme.corner(10),
		Theme.stroke(color, 2),
		Theme.padding(10),
		Theme.create("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}),
		Theme.create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -12, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = kind == "big" and Theme.FontBlack or Theme.FontBold,
			TextSize = kind == "big" and 19 or 17,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Colors.text,
			Text = text,
		}),
	})
	Theme.pop(toast, 0.3)

	-- Keep the stack short.
	local toasts = {}
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts > 5 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end

	task.delay(kind == "big" and 6 or 4, function()
		if toast.Parent then
			Theme.tween(toast, 0.3, { BackgroundTransparency = 1 })
			task.wait(0.3)
			toast:Destroy()
		end
	end)
end

return Notifier
