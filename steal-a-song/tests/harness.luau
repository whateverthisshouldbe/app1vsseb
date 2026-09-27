-- Een nep-Roblox rond Lune: laadt de gebouwde place en draait de echte
-- scripts, met zelfgemaakte signals en services. Lune controleert daarbij
-- elke eigenschap die de code zet tegen de Roblox API, zodat typfouten in
-- namen of types hier al een fout geven in plaats van pas in Studio.

local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Instance = roblox.Instance
local Harness = {}

-- Signals ------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlers = {}, waiting = {} }, Signal)
end

function Signal:Connect(fn)
	local connection = { Connected = true }
	local handler = { fn = fn, connection = connection }
	table.insert(self.handlers, handler)
	function connection.Disconnect()
		connection.Connected = false
	end
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Wait()
	table.insert(self.waiting, coroutine.running())
	return coroutine.yield()
end

function Signal:Fire(...)
	local handlers = table.clone(self.handlers)
	for _, handler in handlers do
		if handler.connection.Connected then
			task.spawn(handler.fn, ...)
		end
	end
	local waiting = self.waiting
	self.waiting = {}
	for _, thread in waiting do
		task.spawn(thread, ...)
	end
end

Harness.Signal = Signal

local signals = {}

function Harness.signal(instance, name)
	local byName = signals[instance]
	if not byName then
		byName = {}
		signals[instance] = byName
	end
	local signal = byName[name]
	if not signal then
		signal = Signal.new()
		byName[name] = signal
	end
	return signal
end

local EVENTS = {
	BasePart = { "Touched", "TouchEnded" },
	ProximityPrompt = { "Triggered", "PromptShown" },
	Tool = { "Activated", "Equipped", "Unequipped" },
	GuiButton = { "Activated", "MouseEnter", "MouseLeave", "MouseButton1Click" },
	Instance = { "DescendantAdded", "ChildAdded", "AncestryChanged", "Destroying" },
	Player = { "CharacterAdded", "CharacterRemoving", "Chatted" },
	Players = { "PlayerAdded", "PlayerRemoving" },
	RemoteEvent = { "OnClientEvent", "OnServerEvent" },
	RunService = { "Heartbeat", "RenderStepped", "Stepped" },
	MarketplaceService = { "PromptGamePassPurchaseFinished" },
}

for className, names in EVENTS do
	for _, name in names do
		roblox.implementProperty(className, name, function(self)
			return Harness.signal(self, name)
		end)
	end
end

-- Stand in voor wat Lune niet kent ------------------------------------------

Harness.remoteLog = {}
Harness.invokeHandlers = {}
Harness.localPlayer = nil
Harness.clockOffset = 0
Harness.store = {}
Harness.orderedStore = {}
Harness.collisionGroups = {}

local function now()
	return os.clock() + Harness.clockOffset
end

roblox.implementMethod("Instance", "WaitForChild", function(self, name, timeout)
	local started = os.clock()
	while true do
		local child = self:FindFirstChild(name)
		if child then
			return child
		end
		if os.clock() - started > (timeout or 5) then
			error("WaitForChild timed out: " .. self:GetFullName() .. "." .. name)
		end
		task.wait(0.01)
	end
end)

roblox.implementMethod("Instance", "GetAttributeChangedSignal", function(self, name)
	return Harness.signal(self, "attr:" .. name)
end)

roblox.implementMethod("Instance", "GetPropertyChangedSignal", function(self, name)
	return Harness.signal(self, "prop:" .. name)
end)

-- Lune houdt Position niet bij als afgeleide van CFrame. PivotTo zet hem
-- meteen, en een lus houdt de rest van de parts bij.
local function syncPosition(part)
	part.Position = part.CFrame.Position
end

function Harness.startPositionSync()
	task.spawn(function()
		while true do
			for _, d in Harness.game:GetDescendants() do
				if d:IsA("BasePart") then
					syncPosition(d)
				end
			end
			task.wait(0.02)
		end
	end)
end

local function modelPivot(model)
	local primary = model.PrimaryPart
	if primary then
		return primary.CFrame
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			return d.CFrame
		end
	end
	return roblox.CFrame.new()
end

roblox.implementMethod("Model", "GetPivot", modelPivot)
roblox.implementMethod("Model", "PivotTo", function(self, target)
	local delta = target * modelPivot(self):Inverse()
	for _, d in self:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = delta * d.CFrame
			syncPosition(d)
		end
	end
end)
roblox.implementMethod("BasePart", "GetPivot", function(self)
	return self.CFrame
end)
roblox.implementMethod("BasePart", "PivotTo", function(self, target)
	self.CFrame = target
	syncPosition(self)
end)
roblox.implementMethod("BasePart", "SetNetworkOwner", function(self)
	assert(not self.Anchored, "SetNetworkOwner on an anchored part")
	assert(self:FindFirstAncestorOfClass("Workspace"), "SetNetworkOwner outside Workspace")
end)

roblox.implementMethod("Player", "IsFriendsWith", function()
	return false
end)

roblox.implementMethod("Sound", "Play", function() end)
roblox.implementMethod("Sound", "Stop", function() end)
roblox.implementMethod("Humanoid", "ChangeState", function() end)

roblox.implementMethod("RemoteEvent", "FireClient", function(self, player, ...)
	assert(player and player:IsA("Player"), "FireClient needs a player")
	table.insert(Harness.remoteLog, { name = self.Name, player = player, args = table.pack(...) })
	if player == Harness.localPlayer then
		Harness.signal(self, "OnClientEvent"):Fire(...)
	end
end)
roblox.implementMethod("RemoteEvent", "FireAllClients", function(self, ...)
	table.insert(Harness.remoteLog, { name = self.Name, player = "all", args = table.pack(...) })
	if Harness.localPlayer then
		Harness.signal(self, "OnClientEvent"):Fire(...)
	end
end)

roblox.implementProperty("RemoteFunction", "OnServerInvoke", function(self)
	return Harness.invokeHandlers[self]
end, function(self, fn)
	Harness.invokeHandlers[self] = fn
end)
roblox.implementMethod("RemoteFunction", "InvokeServer", function(self, ...)
	local handler = Harness.invokeHandlers[self]
	assert(handler, "no OnServerInvoke")
	return handler(Harness.localPlayer, ...)
end)

roblox.implementMethod("Workspace", "GetServerTimeNow", now)

roblox.implementMethod("DataModel", "BindToClose", function() end)
roblox.implementProperty("DataModel", "CreatorId", function()
	return 0
end)
roblox.implementProperty("DataModel", "CreatorType", function()
	return roblox.Enum.CreatorType.User
end)

roblox.implementMethod("RunService", "IsStudio", function()
	return true
end)
roblox.implementMethod("RunService", "IsServer", function()
	return true
end)

roblox.implementMethod("Players", "GetPlayers", function(self)
	local list = {}
	for _, child in self:GetChildren() do
		if child:IsA("Player") then
			table.insert(list, child)
		end
	end
	return list
end)
roblox.implementMethod("Players", "GetPlayerByUserId", function(self, userId)
	for _, child in self:GetChildren() do
		if child:IsA("Player") and child.UserId == userId then
			return child
		end
	end
	return nil
end)
roblox.implementMethod("Players", "GetPlayerFromCharacter", function(self, character)
	for _, child in self:GetChildren() do
		if child:IsA("Player") and Harness.characters[child] == character then
			return child
		end
	end
	return nil
end)
roblox.implementMethod("Players", "GetNameFromUserIdAsync", function(_, userId)
	return "User" .. userId
end)

-- Player.Character is in Lune een gewone referentie-eigenschap
Harness.characters = {}

roblox.implementMethod("PhysicsService", "IsCollisionGroupRegistered", function(_, name)
	return Harness.collisionGroups[name] ~= nil
end)
roblox.implementMethod("PhysicsService", "RegisterCollisionGroup", function(_, name)
	assert(Harness.collisionGroups[name] == nil, "collision group registered twice: " .. name)
	Harness.collisionGroups[name] = {}
end)
roblox.implementMethod("PhysicsService", "CollisionGroupSetCollidable", function(_, a, b, collidable)
	assert(Harness.collisionGroups[a] and Harness.collisionGroups[b], "unknown collision group")
	Harness.collisionGroups[a][b] = collidable
end)

roblox.implementMethod("Debris", "AddItem", function(_, item, seconds)
	task.delay(seconds or 10, function()
		item:Destroy()
	end)
end)

roblox.implementMethod("TweenService", "Create", function(_, instance, _info, props)
	return {
		Completed = Signal.new(),
		Play = function(tween)
			for key, value in props do
				instance[key] = value
			end
			tween.Completed:Fire(roblox.Enum.PlaybackState.Completed)
		end,
		Cancel = function() end,
	}
end)

roblox.implementMethod("CollectionService", "GetTagged", function(_, tag)
	local found = {}
	for _, d in Harness.game:GetDescendants() do
		if d:HasTag(tag) then
			table.insert(found, d)
		end
	end
	return found
end)
roblox.implementMethod("CollectionService", "GetInstanceAddedSignal", function(self, tag)
	return Harness.signal(self, "added:" .. tag)
end)
roblox.implementMethod("CollectionService", "GetInstanceRemovedSignal", function(self, tag)
	return Harness.signal(self, "removed:" .. tag)
end)

roblox.implementMethod("MarketplaceService", "UserOwnsGamePassAsync", function()
	return false
end)
roblox.implementMethod("MarketplaceService", "PromptGamePassPurchase", function() end)

-- In-memory DataStores
local function makeStore(data)
	return {
		GetAsync = function(_, key)
			return data[key]
		end,
		SetAsync = function(_, key, value)
			data[key] = value
		end,
		UpdateAsync = function(_, key, transform)
			data[key] = transform(data[key])
			return data[key]
		end,
		GetSortedAsync = function(_, _ascending, size)
			local list = {}
			for key, value in data do
				table.insert(list, { key = key, value = value })
			end
			table.sort(list, function(a, b)
				return a.value > b.value
			end)
			while #list > size do
				table.remove(list)
			end
			return {
				GetCurrentPage = function()
					return list
				end,
			}
		end,
	}
end
roblox.implementMethod("DataStoreService", "GetDataStore", function()
	return makeStore(Harness.store)
end)
roblox.implementMethod("DataStoreService", "GetOrderedDataStore", function()
	return makeStore(Harness.orderedStore)
end)

-- Globals die Lune niet heeft -------------------------------------------

local Random = {}
Random.__index = Random
function Random.new()
	return setmetatable({}, Random)
end
function Random:NextInteger(a, b)
	return math.random(a, b)
end
function Random:NextNumber(a, b)
	a = a or 0
	b = b or 1
	return a + (b - a) * math.random()
end

local TweenInfo = {
	new = function(...)
		return table.pack(...)
	end,
}

local warnings = {}
Harness.warnings = warnings

local function makeEnv(scriptInstance, requireFn)
	return {
		game = Harness.game,
		workspace = Harness.game:GetService("Workspace"),
		script = scriptInstance,
		require = requireFn,
		task = task,
		warn = function(...)
			local parts = table.pack(...)
			for i = 1, parts.n do
				parts[i] = tostring(parts[i])
			end
			local text = table.concat(parts, " ")
			table.insert(warnings, text)
			print("  [warn] " .. text)
		end,
		Instance = Instance,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		BrickColor = roblox.BrickColor,
		Font = roblox.Font,
		Rect = roblox.Rect,
		PhysicalProperties = roblox.PhysicalProperties,
		Random = Random,
		TweenInfo = TweenInfo,
	}
end

-- Elke "kant" (server, client) heeft zijn eigen module-cache, net als in Roblox
function Harness.context(name)
	local cache = {}
	local context = { name = name }

	local function requireModule(module)
		if type(module) ~= "userdata" then
			error("require expects a ModuleScript, got " .. typeof(module))
		end
		assert(module:IsA("ModuleScript"), "require on a " .. module.ClassName)
		local cached = cache[module]
		if cached ~= nil then
			return cached.value
		end
		local chunk = luau.load(module.Source, {
			debugName = module:GetFullName(),
			environment = makeEnv(module, requireModule),
		})
		local value = chunk()
		cache[module] = { value = value }
		return value
	end

	function context.require(module)
		return requireModule(module)
	end

	function context.run(scriptInstance)
		local chunk = luau.load(scriptInstance.Source, {
			debugName = scriptInstance:GetFullName(),
			environment = makeEnv(scriptInstance, requireModule),
		})
		task.spawn(chunk)
	end

	return context
end

-- LocalPlayer is een bekende eigenschap, dus die zetten we gewoon
function Harness.setLocalPlayer(player)
	Harness.localPlayer = player
	Harness.game:GetService("Players").LocalPlayer = player
	local workspace = Harness.game:GetService("Workspace")
	local camera = workspace.CurrentCamera or Instance.new("Camera")
	camera.ViewportSize = roblox.Vector2.new(1280, 720)
	camera.CFrame = roblox.CFrame.new(0, 20, 60)
	camera.Parent = workspace
	workspace.CurrentCamera = camera
end

function Harness.load(place)
	Harness.game = place
	Harness.startPositionSync()
	return place
end

-- Een speler met een simpel R15-achtig karakter
function Harness.addPlayer(userId, name)
	local players = Harness.game:GetService("Players")
	local player = Instance.new("Player")
	player.Name = name
	player.DisplayName = name
	player.UserId = userId
	Instance.new("Backpack").Parent = player
	Instance.new("PlayerGui").Parent = player
	player.Parent = players
	players.PlayerAdded:Fire(player)
	return player
end

function Harness.spawnCharacter(player, position)
	local character = Instance.new("Model")
	character.Name = player.Name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = roblox.Vector3.new(2, 2, 1)
	root.CFrame = roblox.CFrame.new(position or roblox.Vector3.new(0, 5, 14))
	syncPosition(root)
	root.Parent = character
	local foot = Instance.new("Part")
	foot.Name = "LeftFoot"
	foot.Parent = character
	local humanoid = Instance.new("Humanoid")
	humanoid.Health = 100
	humanoid.Parent = character
	character.PrimaryPart = root
	character.Parent = Harness.game:GetService("Workspace")
	player.Character = character
	Harness.characters[player] = character
	player.CharacterAdded:Fire(character)
	return character
end

function Harness.lastRemote(name, player)
	for i = #Harness.remoteLog, 1, -1 do
		local entry = Harness.remoteLog[i]
		if entry.name == name and (player == nil or entry.player == player) then
			return entry
		end
	end
	return nil
end

return Harness
