-- Nagemaakte Roblox-API, alleen voor de test hieronder. Dit hoort NIET in de game.

local function class(name)
	return name
end

-- ---------------------------------------------------------------- Vector3 --
local Vector3mt = {}
Vector3mt.__index = Vector3mt
local function vec(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3mt)
end
function Vector3mt.__add(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function Vector3mt.__sub(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function Vector3mt.__mul(a, b)
	if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
	return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
function Vector3mt.__div(a, b)
	if type(b) == "number" then return vec(a.X / b, a.Y / b, a.Z / b) end
	return vec(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
Vector3mt.__index = function(self, key)
	if key == "Magnitude" then
		return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
	end
	if key == "Unit" then
		local m = math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
		return vec(self.X / m, self.Y / m, self.Z / m)
	end
	return rawget(Vector3mt, key)
end

function Vector3mt.__tostring(a) return string.format("(%.1f, %.1f, %.1f)", a.X, a.Y, a.Z) end
Vector3 = { new = function(x, y, z) return vec(x, y, z) end, zero = vec(0, 0, 0) }

-- ----------------------------------------------------------------- CFrame --
-- Positie plus draaiing. Alleen de draaiing om de Y-as wordt echt doorgerekend
-- (dat is wat de game gebruikt); pitch en roll worden bewaard voor de preview.
local CFramemt = {}
local function cframe(pos, yaw, pitch, roll)
	return setmetatable({ _pos = pos, _yaw = yaw or 0, _pitch = pitch or 0, _roll = roll or 0 }, CFramemt)
end
CFramemt.__index = function(self, key)
	if key == "Position" or key == "p" then
		return rawget(self, "_pos")
	end
	if key == "Yaw" then
		return rawget(self, "_yaw")
	end
	return rawget(CFramemt, key)
end
local function rotY(yaw, v)
	local c, s = math.cos(yaw), math.sin(yaw)
	return vec(v.X * c + v.Z * s, v.Y, -v.X * s + v.Z * c)
end
function CFramemt.__mul(a, b)
	if getmetatable(b) == CFramemt then
		return cframe(a._pos + rotY(a._yaw, b._pos), a._yaw + b._yaw, a._pitch + b._pitch, a._roll + b._roll)
	end
	return cframe(a._pos + rotY(a._yaw, b), a._yaw, a._pitch, a._roll)
end
function CFramemt:PointToObjectSpace(p)
	return rotY(-self._yaw, p - self._pos)
end
CFrame = {
	new = function(a, b, c)
		if type(a) == "number" then
			return cframe(vec(a, b, c), 0)
		elseif a == nil then
			return cframe(vec(0, 0, 0), 0)
		elseif b ~= nil then
			local dir = b - a
			return cframe(a, math.atan2(dir.X, dir.Z))
		end
		return cframe(a, 0)
	end,
	Angles = function(rx, ry, rz)
		return cframe(vec(0, 0, 0), ry or 0, rx or 0, rz or 0)
	end,
	fromEulerAnglesXYZ = function(rx, ry, rz)
		return cframe(vec(0, 0, 0), ry or 0, rx or 0, rz or 0)
	end,
}

-- ----------------------------------------------------------------- Color3 --
local Color3mt = {}
Color3mt.__index = Color3mt
local function color(r, g, b)
	return setmetatable({ R = r, G = g, B = b }, Color3mt)
end
function Color3mt:Lerp(other, t)
	return color(self.R + (other.R - self.R) * t, self.G + (other.G - self.G) * t, self.B + (other.B - self.B) * t)
end
Color3 = {
	new = function(r, g, b) return color(r or 0, g or 0, b or 0) end,
	fromRGB = function(r, g, b) return color(r / 255, g / 255, b / 255) end,
	fromHSV = function(h, s, v) return color(h, s, v) end,
}

-- ------------------------------------------------------------ UDim / UDim2 --
UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = {
	new = function(xs, xo, ys, yo) return { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo } } end,
	fromScale = function(x, y) return { X = { Scale = x, Offset = 0 }, Y = { Scale = y, Offset = 0 } } end,
	fromOffset = function(x, y) return { X = { Scale = 0, Offset = x }, Y = { Scale = 0, Offset = y } } end,
}
Vector2 = { new = function(x, y) return { X = x, Y = y } end }
NumberRange = { new = function(a, b) return { Min = a, Max = b or a } end }
NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
NumberSequence = { new = function(v) return { Keypoints = v } end }
ColorSequence = { new = function(v) return { Keypoints = v } end }

-- ------------------------------------------------------------------- Enum --
local enumItem = {}
enumItem.__index = enumItem
local enumCategory = {}
enumCategory.__index = function(self, key)
	local cached = rawget(self, "_items")[key]
	if not cached then
		cached = setmetatable({ Name = key, Value = 0 }, enumItem)
		rawget(self, "_items")[key] = cached
	end
	return cached
end
Enum = setmetatable({}, {
	__index = function(self, key)
		local cat = setmetatable({ _items = {} }, enumCategory)
		rawset(self, key, cat)
		return cat
	end,
})

-- ----------------------------------------------------------------- Signal --
local Signal = {}
Signal.__index = Signal
local function newSignal(name)
	return setmetatable({ _name = name, _handlers = {} }, Signal)
end
function Signal:Connect(fn)
	table.insert(self._handlers, fn)
	return { Disconnect = function() end, Connected = true }
end
function Signal:Once(fn)
	return self:Connect(fn)
end
function Signal:Wait()
	return nil
end
function Signal:Fire(...)
	for _, fn in self._handlers do
		local ok, err = pcall(fn, ...)
		if not ok then
			error("[signal " .. tostring(self._name) .. "] " .. tostring(err), 0)
		end
	end
end

local SIGNAL_NAMES = {
	Heartbeat = true, Stepped = true, RenderStepped = true,
	PlayerAdded = true, PlayerRemoving = true, CharacterAdded = true, CharacterRemoving = true,
	OnServerEvent = true, OnClientEvent = true, Touched = true, TouchEnded = true,
	Activated = true, FocusLost = true, Completed = true, Changed = true,
	PromptGamePassPurchaseFinished = true, ChildAdded = true, AncestryChanged = true,
}

-- --------------------------------------------------------------- Instance --
local Instancemt = {}

local function isA(self, className)
	local map = {
		Part = { "Part", "BasePart", "Instance", "PVInstance" },
		SpawnLocation = { "SpawnLocation", "Part", "BasePart", "Instance" },
		MeshPart = { "MeshPart", "BasePart", "Instance" },
		TextLabel = { "TextLabel", "GuiObject", "GuiBase2d", "Instance" },
		TextButton = { "TextButton", "GuiObject", "GuiBase2d", "Instance" },
		TextBox = { "TextBox", "GuiObject", "GuiBase2d", "Instance" },
		Frame = { "Frame", "GuiObject", "GuiBase2d", "Instance" },
		ScrollingFrame = { "ScrollingFrame", "GuiObject", "GuiBase2d", "Instance" },
		Model = { "Model", "Instance", "PVInstance" },
		Folder = { "Folder", "Instance" },
		IntValue = { "IntValue", "ValueBase", "Instance" },
		Humanoid = { "Humanoid", "Instance" },
		RemoteEvent = { "RemoteEvent", "Instance" },
	}
	local list = map[self.ClassName] or { self.ClassName, "Instance" }
	return table.find(list, className) ~= nil
end

local function newInstance(className)
	local self = {}
	local data = {
		ClassName = className,
		Name = className,
		_children = {},
		_signals = {},
		_destroyed = false,
	}
	rawset(self, "_data", data)
	return setmetatable(self, Instancemt)
end

local DEFAULTS = {
	Size = function() return vec(1, 1, 1) end,
	CFrame = function() return cframe(vec(0, 0, 0)) end,
	Transparency = function() return 0 end,
	Text = function() return "" end,
	Value = function() return 0 end,
	WalkSpeed = function() return 16 end,
	Visible = function() return true end,
	PrimaryPart = function() return nil end,
}

Instancemt.__index = function(self, key)
	local data = rawget(self, "_data")
	if key == "Position" and data.CFrame then
		return data.CFrame.Position
	end
	if data[key] ~= nil then
		return data[key]
	end
	if SIGNAL_NAMES[key] then
		local sig = data._signals[key]
		if not sig then
			sig = newSignal(data.Name .. "." .. key)
			data._signals[key] = sig
		end
		return sig
	end
	local method = Instancemt.methods[key]
	if method then
		return method
	end
	local default = DEFAULTS[key]
	if default then
		return default()
	end
	return nil
end

Instancemt.__newindex = function(self, key, value)
	local data = rawget(self, "_data")
	if key == "Parent" then
		local old = data.Parent
		if old then
			local siblings = rawget(old, "_data")._children
			local index = table.find(siblings, self)
			if index then
				table.remove(siblings, index)
			end
		end
		data.Parent = value
		if value then
			table.insert(rawget(value, "_data")._children, self)
		end
		return
	end
	if key == "Position" then
		data.CFrame = cframe(value)
		return
	end
	data[key] = value
end

Instancemt.__tostring = function(self)
	return rawget(self, "_data").Name
end

Instancemt.methods = {
	IsA = function(self, className)
		return isA(rawget(self, "_data"), className)
	end,
	GetChildren = function(self)
		local copy = {}
		for _, child in rawget(self, "_data")._children do
			table.insert(copy, child)
		end
		return copy
	end,
	GetDescendants = function(self)
		local out = {}
		local function walk(node)
			for _, child in rawget(node, "_data")._children do
				table.insert(out, child)
				walk(child)
			end
		end
		walk(self)
		return out
	end,
	FindFirstChild = function(self, name, recursive)
		for _, child in rawget(self, "_data")._children do
			if rawget(child, "_data").Name == name then
				return child
			end
		end
		if recursive then
			for _, child in rawget(self, "_data")._children do
				local found = Instancemt.methods.FindFirstChild(child, name, true)
				if found then
					return found
				end
			end
		end
		return nil
	end,
	FindFirstChildOfClass = function(self, className)
		for _, child in rawget(self, "_data")._children do
			if rawget(child, "_data").ClassName == className then
				return child
			end
		end
		return nil
	end,
	WaitForChild = function(self, name)
		local found = Instancemt.methods.FindFirstChild(self, name)
		if not found then
			error("WaitForChild zou blijven hangen op: " .. tostring(name), 0)
		end
		return found
	end,
	Destroy = function(self)
		local data = rawget(self, "_data")
		data._destroyed = true
		if data.Parent then
			local siblings = rawget(data.Parent, "_data")._children
			local index = table.find(siblings, self)
			if index then
				table.remove(siblings, index)
			end
			data.Parent = nil
		end
	end,
	ClearAllChildren = function(self)
		local data = rawget(self, "_data")
		for _, child in Instancemt.methods.GetChildren(self) do
			Instancemt.methods.Destroy(child)
		end
		data._children = {}
	end,
	FireClient = function(self, _player, ...)
		local data = rawget(self, "_data")
		data._fired = (data._fired or 0) + 1
		data._last = { ... }
	end,
	FireAllClients = function(self, ...)
		local data = rawget(self, "_data")
		data._fired = (data._fired or 0) + 1
		data._last = { ... }
	end,
	FireServer = function() end,
	SetPrimaryPartCFrame = function() end,
	PivotTo = function() end,
}

Instance = {
	new = function(className, parent)
		local inst = newInstance(className)
		if parent then
			inst.Parent = parent
		end
		return inst
	end,
}

-- ------------------------------------------------------------------ task ---
local scheduled = {}
task = {
	spawn = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			error("[task.spawn] " .. tostring(err), 0)
		end
		return co
	end,
	defer = function(fn, ...)
		return task.spawn(fn, ...)
	end,
	delay = function(seconds, fn, ...)
		table.insert(scheduled, { seconds = seconds, fn = fn, args = { ... } })
	end,
	wait = function()
		if coroutine.isyieldable() then
			coroutine.yield()
		end
		return 0
	end,
	cancel = function() end,
}
wait = task.wait

-- vervangende os: de test bepaalt zelf hoe laat het is
local realOs = os
FAKE_CLOCK = 1000
TIME_OFFSET = 0
os = {
	clock = function()
		return FAKE_CLOCK
	end,
	time = function()
		return realOs.time() + TIME_OFFSET
	end,
	date = realOs.date,
	difftime = realOs.difftime,
}

-- --------------------------------------------------------------- services --
local services = {}
local dataStores = {}

local function makeService(name)
	local svc = newInstance(name)
	svc.Name = name

	if name == "Players" then
		local list = {}
		rawget(svc, "_data").GetPlayers = function()
			return list
		end
		rawget(svc, "_data")._list = list
		rawget(svc, "_data").GetNameFromUserIdAsync = function(_, id)
			return "Speler" .. id
		end
	elseif name == "RunService" then
		rawget(svc, "_data").IsServer = function() return true end
		rawget(svc, "_data").IsClient = function() return false end
		rawget(svc, "_data").IsStudio = function() return true end
	elseif name == "DataStoreService" then
		rawget(svc, "_data").GetDataStore = function(_, key)
			local store = dataStores[key]
			if not store then
				local values = {}
				store = {
					_values = values,
					GetAsync = function(_, k) return values[k] end,
					SetAsync = function(_, k, v) values[k] = v end,
					UpdateAsync = function(_, k, fn) values[k] = fn(values[k]) end,
				}
				dataStores[key] = store
			end
			return store
		end
		rawget(svc, "_data").GetOrderedDataStore = function(self, key)
			local store = rawget(svc, "_data").GetDataStore(self, "ordered_" .. key)
			store.GetSortedAsync = function()
				return {
					GetCurrentPage = function()
						local rows = {}
						for k, v in store._values do
							table.insert(rows, { key = k, value = v })
						end
						table.sort(rows, function(a, b) return a.value > b.value end)
						return rows
					end,
				}
			end
			return store
		end
	elseif name == "MarketplaceService" then
		rawget(svc, "_data").UserOwnsGamePassAsync = function() return false end
		rawget(svc, "_data").PromptGamePassPurchase = function() end
	elseif name == "TweenService" then
		rawget(svc, "_data").Create = function()
			return { Play = function() end, Completed = newSignal("tween") }
		end
	end

	return svc
end

game = {
	GetService = function(_, name)
		local svc = services[name]
		if not svc then
			svc = makeService(name)
			services[name] = svc
		end
		return svc
	end,
	BindToClose = function() end,
	Players = nil,
}
setmetatable(game, {
	__index = function(_, key)
		if services[key] then
			return services[key]
		end
		return nil
	end,
})

workspace = game:GetService("Workspace")
SERVICES = services
