-- Sell Me This Pen - SERVER. Plak dit in een Script in ServerScriptService.
-- AUTOMATISCH GEGENEREERD door tools/bundle.py - niet met de hand aanpassen.
-- Pas de bestanden in src/ aan en draai het script opnieuw.

local PEN = {}

PEN.Config = (function()
	--!strict
	-- Alle balans-instellingen van "Sell Me This Pen" staan hier.
	-- Wil je de game sneller/langzamer maken? Pas alleen dit bestand aan.

	local Config = {}

	Config.GameName = "Sell Me This Pen"
	Config.DataStoreKey = "PenTycoon_v1" -- ophogen = iedereen begint opnieuw

	-- Pennen die je maakt. Je maakt altijd de hoogste pen die je hebt vrijgespeeld.
	-- Vrijspelen gebeurt met rebirths (zie Config.Rebirth.penUnlockPerRebirth).
	Config.Pens = {
		{ name = "Balpen",        value = 4,     color = Color3.fromRGB(35, 35, 40) },
		{ name = "Gelpen",        value = 14,    color = Color3.fromRGB(30, 110, 220) },
		{ name = "Marker",        value = 45,    color = Color3.fromRGB(230, 90, 40) },
		{ name = "Vulpen",        value = 150,   color = Color3.fromRGB(150, 120, 60) },
		{ name = "Zilveren pen",  value = 520,   color = Color3.fromRGB(190, 195, 205) },
		{ name = "Gouden pen",    value = 1900,  color = Color3.fromRGB(235, 190, 60) },
		{ name = "Diamanten pen", value = 7200,  color = Color3.fromRGB(120, 230, 235) },
		{ name = "Sterrenpen",    value = 28000, color = Color3.fromRGB(180, 110, 240) },
	}

	-- Upgrades die je bij de kiosk koopt.
	-- prijs = basePrice * (growth ^ (level - 1))
	Config.Upgrades = {
		{
			key = "capacity",
			name = "Grotere tas",
			info = "Meer pennen tegelijk dragen",
			basePrice = 60,
			growth = 1.28,
			maxLevel = 40,
			-- level 1 = 12 pennen, elke level +6
			value = function(level: number): number
				return 6 + level * 6
			end,
			format = function(v: number): string
				return string.format("%d pennen", v)
			end,
		},
		{
			key = "speed",
			name = "Snellere pers",
			info = "Sneller pennen maken",
			basePrice = 90,
			growth = 1.33,
			maxLevel = 40,
			-- seconden per pen, van 1.0s naar minimaal ~0.08s
			value = function(level: number): number
				return math.max(0.08, 1.0 * (0.92 ^ (level - 1)))
			end,
			format = function(v: number): string
				return string.format("%.2fs per pen", v)
			end,
		},
		{
			key = "charm",
			name = "Verkooppraatje",
			info = "Klanten betalen meer",
			basePrice = 140,
			growth = 1.40,
			maxLevel = 40,
			-- verkoop-multiplier: level 1 = 1.0, daarna +12% per level
			value = function(level: number): number
				return 1 + (level - 1) * 0.12
			end,
			format = function(v: number): string
				return string.format("x%.2f prijs", v)
			end,
		},
		{
			key = "legs",
			name = "Snellere schoenen",
			info = "Je loopt harder",
			basePrice = 200,
			growth = 1.55,
			maxLevel = 20,
			value = function(level: number): number
				return math.min(60, 16 + level * 2)
			end,
			format = function(v: number): string
				return string.format("%d snelheid", v)
			end,
		},
	}

	Config.Rebirth = {
		basePrice = 15000,
		growth = 4.2,          -- prijs = basePrice * growth ^ rebirths
		cashMultiplier = 0.75, -- +75% verkoopprijs per rebirth
		penUnlockPerRebirth = 1,
	}

	Config.Production = {
		padCooldownGrace = 0.05,
	}

	Config.Customer = {
		rotateSeconds = 26,    -- hoe lang een klant blijft staan
		minMultiplier = 0.8,
		maxMultiplier = 2.4,
		names = {
			"Karel", "Wendy", "Mo", "Sanne", "Dirk", "Priya", "Bram", "Lisa",
			"Youssef", "Femke", "Ravi", "Joost", "Nina", "Tom", "Ayla",
		},
		lines = {
			"Sell me this pen!",
			"Overtuig me eens...",
			"Ik schrijf nog met potlood, hoezo pen?",
			"Wat maakt jouw pen bijzonder?",
			"Ik heb er al drie. Waarom nog een?",
			"Snel, ik heb een vergadering!",
			"Doe maar een dure.",
		},
	}

	function Config.getPen(index: number)
		local i = math.clamp(index, 1, #Config.Pens)
		return Config.Pens[i]
	end

	function Config.unlockedPenIndex(rebirths: number): number
		return math.clamp(1 + rebirths * Config.Rebirth.penUnlockPerRebirth, 1, #Config.Pens)
	end

	function Config.getUpgrade(key: string)
		for _, up in Config.Upgrades do
			if up.key == key then
				return up
			end
		end
		return nil
	end

	function Config.upgradePrice(up, level: number): number
		return math.floor(up.basePrice * (up.growth ^ (level - 1)) + 0.5)
	end

	function Config.rebirthPrice(rebirths: number): number
		return math.floor(Config.Rebirth.basePrice * (Config.Rebirth.growth ^ rebirths) + 0.5)
	end

	function Config.rebirthMultiplier(rebirths: number): number
		return 1 + rebirths * Config.Rebirth.cashMultiplier
	end

	-- 1234567 -> "1.23M"
	function Config.short(n: number): string
		local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
		local i = 1
		local v = math.abs(n)
		while v >= 1000 and i < #units do
			v /= 1000
			i += 1
		end
		local sign = n < 0 and "-" or ""
		if i == 1 then
			return sign .. tostring(math.floor(v))
		end
		return string.format("%s%.2f%s", sign, v, units[i])
	end

	return Config
end)()

PEN.Net = (function()
	--!strict
	-- Maakt en vindt de RemoteEvents. Server maakt ze, client wacht erop.

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local Net = {}

	local EVENT_NAMES = {
		"StateChanged", -- server -> client: hele spelerstatus
		"Notify",       -- server -> client: toastje (tekst, kleur)
		"BuyUpgrade",   -- client -> server: upgrade-key
		"Rebirth",      -- client -> server
		"CustomerChanged", -- server -> alle clients: huidige klant
	}

	local folder: Folder

	local function ensureFolder(): Folder
		if folder and folder.Parent then
			return folder
		end
		if RunService:IsServer() then
			local existing = ReplicatedStorage:FindFirstChild("PenNet")
			if existing then
				folder = existing :: Folder
			else
				local f = Instance.new("Folder")
				f.Name = "PenNet"
				f.Parent = ReplicatedStorage
				folder = f
			end
			for _, name in EVENT_NAMES do
				if not folder:FindFirstChild(name) then
					local ev = Instance.new("RemoteEvent")
					ev.Name = name
					ev.Parent = folder
				end
			end
		else
			folder = ReplicatedStorage:WaitForChild("PenNet") :: Folder
		end
		return folder
	end

	function Net.event(name: string): RemoteEvent
		local f = ensureFolder()
		if RunService:IsServer() then
			return f:FindFirstChild(name) :: RemoteEvent
		end
		return f:WaitForChild(name) :: RemoteEvent
	end

	function Net.init()
		ensureFolder()
	end

	return Net
end)()

PEN.Data = (function()
	--!strict
	-- Opslaan en laden. Gebruikt DataStore, maar de game blijft werken
	-- als DataStore niet beschikbaar is (bijv. in Studio zonder API-toegang).

	local DataStoreService = game:GetService("DataStoreService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local Config = PEN.Config

	local Data = {}

	export type Profile = {
		cash: number,
		pens: number,
		rebirths: number,
		totalSold: number,
		upgrades: { [string]: number },
		loaded: boolean,
		dirty: boolean,
	}

	local AUTOSAVE_SECONDS = 60
	local store: DataStore? = nil
	local profiles: { [Player]: Profile } = {}

	local function defaultProfile(): Profile
		local upgrades = {}
		for _, up in Config.Upgrades do
			upgrades[up.key] = 1
		end
		return {
			cash = 0,
			pens = 0,
			rebirths = 0,
			totalSold = 0,
			upgrades = upgrades,
			loaded = false,
			dirty = false,
		}
	end

	local function sanitize(raw: any): Profile
		local p = defaultProfile()
		if typeof(raw) ~= "table" then
			return p
		end
		p.cash = math.max(0, tonumber(raw.cash) or 0)
		p.pens = math.max(0, math.floor(tonumber(raw.pens) or 0))
		p.rebirths = math.max(0, math.floor(tonumber(raw.rebirths) or 0))
		p.totalSold = math.max(0, math.floor(tonumber(raw.totalSold) or 0))
		if typeof(raw.upgrades) == "table" then
			for _, up in Config.Upgrades do
				local lvl = math.floor(tonumber(raw.upgrades[up.key]) or 1)
				p.upgrades[up.key] = math.clamp(lvl, 1, up.maxLevel)
			end
		end
		return p
	end

	local function getStore(): DataStore?
		if store then
			return store
		end
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(Config.DataStoreKey)
		end)
		if ok then
			store = result
			return store
		end
		warn("[Pen] DataStore niet beschikbaar: " .. tostring(result))
		return nil
	end

	local function key(player: Player): string
		return "player_" .. player.UserId
	end

	function Data.load(player: Player): Profile
		local profile = defaultProfile()
		profiles[player] = profile

		local ds = getStore()
		if ds then
			local ok, result = pcall(function()
				return ds:GetAsync(key(player))
			end)
			if ok then
				if result ~= nil then
					local loaded = sanitize(result)
					loaded.loaded = true
					profiles[player] = loaded
					return loaded
				end
			else
				warn("[Pen] Laden mislukt voor " .. player.Name .. ": " .. tostring(result))
			end
		end

		profile.loaded = true
		return profile
	end

	function Data.get(player: Player): Profile?
		return profiles[player]
	end

	function Data.markDirty(player: Player)
		local p = profiles[player]
		if p then
			p.dirty = true
		end
	end

	function Data.save(player: Player): boolean
		local profile = profiles[player]
		if not profile or not profile.loaded then
			return false
		end
		local ds = getStore()
		if not ds then
			return false
		end
		local payload = {
			cash = profile.cash,
			pens = profile.pens,
			rebirths = profile.rebirths,
			totalSold = profile.totalSold,
			upgrades = profile.upgrades,
		}
		local ok, err = pcall(function()
			ds:SetAsync(key(player), payload)
		end)
		if not ok then
			warn("[Pen] Opslaan mislukt voor " .. player.Name .. ": " .. tostring(err))
			return false
		end
		profile.dirty = false
		return true
	end

	function Data.release(player: Player)
		Data.save(player)
		profiles[player] = nil
	end

	function Data.start()
		task.spawn(function()
			while true do
				task.wait(AUTOSAVE_SECONDS)
				for player, profile in profiles do
					if profile.dirty then
						Data.save(player)
					end
				end
			end
		end)

		game:BindToClose(function()
			if RunService:IsStudio() then
				return
			end
			for _, player in Players:GetPlayers() do
				task.spawn(Data.save, player)
			end
			task.wait(3)
		end)
	end

	return Data
end)()

PEN.World = (function()
	--!strict
	-- Bouwt de hele map met code, zodat je niets met de hand hoeft te bouwen.
	-- Wil je later een eigen map? Zet World.ENABLED op false en geef je eigen
	-- onderdelen dezelfde namen (PenPress, SellDesk, UpgradePad_<key>, RebirthPad).

	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	local Config = PEN.Config

	local World = {}

	World.ENABLED = true

	local FLOOR_Y = 0

	local function part(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(p :: any)[k] = v
		end
		return p
	end

	local function label(parent: BasePart, text: string, offsetY: number, size: number): TextLabel
		local gui = Instance.new("BillboardGui")
		gui.Name = "Label"
		gui.Size = UDim2.fromScale(10, 2.6)
		gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 140
		gui.Parent = parent

		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextScaled = false
		tl.TextSize = size
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextStrokeTransparency = 0.35
		tl.TextStrokeColor3 = Color3.new(0, 0, 0)
		tl.RichText = true
		tl.Text = text
		tl.Parent = gui
		return tl
	end

	local function pad(name: string, cf: CFrame, size: Vector3, color: Color3, text: string, parent: Instance): Part
		local p = part({
			Name = name,
			Size = size,
			CFrame = cf,
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.25,
		})
		p.Parent = parent
		label(p, text, size.Y / 2 + 3, 22)
		return p
	end

	function World.build(): Folder
		local existing = Workspace:FindFirstChild("PenWorld")
		if existing then
			existing:Destroy()
		end

		local root = Instance.new("Folder")
		root.Name = "PenWorld"
		root.Parent = Workspace

		Lighting.Ambient = Color3.fromRGB(110, 110, 120)
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
		Lighting.Brightness = 2.4

		-- vloer
		local floor = part({
			Name = "Floor",
			Size = Vector3.new(220, 2, 220),
			CFrame = CFrame.new(0, FLOOR_Y - 1, 0),
			Color = Color3.fromRGB(58, 62, 74),
			Material = Enum.Material.Concrete,
		})
		floor.Parent = root

		local carpet = part({
			Name = "Carpet",
			Size = Vector3.new(90, 0.2, 120),
			CFrame = CFrame.new(0, FLOOR_Y + 0.1, 0),
			Color = Color3.fromRGB(38, 92, 120),
			Material = Enum.Material.Fabric,
		})
		carpet.Parent = root

		-- spawn
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PenSpawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.CFrame = CFrame.new(0, FLOOR_Y + 0.5, 0)
		spawn.Color = Color3.fromRGB(80, 200, 140)
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Duration = 0
		spawn.Parent = root

		-- pennenpers
		local press = part({
			Name = "PressBody",
			Size = Vector3.new(14, 10, 10),
			CFrame = CFrame.new(-34, FLOOR_Y + 5, -26),
			Color = Color3.fromRGB(70, 78, 96),
			Material = Enum.Material.Metal,
		})
		press.Parent = root
		label(press, "<b>PENNENPERS</b>\nga op de plaat staan", 7, 26)

		pad("PenPress", CFrame.new(-34, FLOOR_Y + 0.35, -14), Vector3.new(16, 0.7, 12),
			Color3.fromRGB(90, 190, 255), "Pennen maken", root)

		-- verkoopbalie
		local desk = part({
			Name = "DeskBody",
			Size = Vector3.new(20, 5, 6),
			CFrame = CFrame.new(34, FLOOR_Y + 2.5, -26),
			Color = Color3.fromRGB(120, 86, 56),
			Material = Enum.Material.Wood,
		})
		desk.Parent = root
		label(desk, "<b>VERKOOPBALIE</b>", 4.5, 26)

		pad("SellDesk", CFrame.new(34, FLOOR_Y + 0.35, -17), Vector3.new(20, 0.7, 12),
			Color3.fromRGB(120, 255, 150), "Verkopen", root)

		-- plek waar de klant staat (achter de balie)
		local customerSpot = part({
			Name = "CustomerSpot",
			Size = Vector3.new(4, 0.4, 4),
			CFrame = CFrame.new(34, FLOOR_Y + 0.2, -31),
			Color = Color3.fromRGB(200, 200, 210),
			Transparency = 1,
			CanCollide = false,
		})
		customerSpot.Parent = root

		-- upgrade-kiosk
		local kioskZ = 22
		local spacing = 18
		local startX = -((#Config.Upgrades - 1) * spacing) / 2
		for i, up in Config.Upgrades do
			local x = startX + (i - 1) * spacing
			local stand = part({
				Name = "KioskBody_" .. up.key,
				Size = Vector3.new(8, 6, 4),
				CFrame = CFrame.new(x, FLOOR_Y + 3, kioskZ + 8),
				Color = Color3.fromRGB(46, 52, 66),
			})
			stand.Parent = root
			label(stand, string.format("<b>%s</b>\n%s", up.name, up.info), 5, 20)

			pad("UpgradePad_" .. up.key, CFrame.new(x, FLOOR_Y + 0.35, kioskZ), Vector3.new(10, 0.7, 10),
				Color3.fromRGB(255, 200, 90), up.name, root)
		end

		-- rebirth
		local rebirthBody = part({
			Name = "RebirthBody",
			Size = Vector3.new(10, 12, 10),
			CFrame = CFrame.new(0, FLOOR_Y + 6, -48),
			Color = Color3.fromRGB(120, 60, 180),
			Material = Enum.Material.Neon,
			Transparency = 0.4,
		})
		rebirthBody.Parent = root
		label(rebirthBody, "<b>REBIRTH</b>\nnieuwe pen + hogere prijzen", 8, 24)

		pad("RebirthPad", CFrame.new(0, FLOOR_Y + 0.35, -38), Vector3.new(12, 0.7, 10),
			Color3.fromRGB(200, 120, 255), "Rebirth", root)

		return root
	end

	function World.findPad(root: Instance, name: string): BasePart?
		local p = root:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then
			return p
		end
		return nil
	end

	return World
end)()

PEN.Customers = (function()
	--!strict
	-- De klant achter de balie. Elke klant heeft een eigen vraagprijs-multiplier,
	-- dus timing is belangrijk: wachten op een goede klant loont.

	local Config = PEN.Config
	local Net = PEN.Net

	local Customers = {}

	export type Customer = {
		name: string,
		line: string,
		multiplier: number,
		expiresAt: number,
	}

	local current: Customer? = nil
	local model: Model? = nil
	local bubbleText: TextLabel? = nil

	local function bodyPart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	local function buildModel(spot: BasePart): Model
		local m = Instance.new("Model")
		m.Name = "Customer"

		local skin = Color3.fromRGB(235, 200, 160)
		local shirt = Color3.fromHSV(math.random(), 0.55, 0.85)
		local pants = Color3.fromRGB(45, 50, 70)
		local base = spot.CFrame * CFrame.new(0, 0, 0)
		local facing = CFrame.new(base.Position, base.Position + Vector3.new(0, 0, 14))

		local torso = bodyPart("Torso", Vector3.new(2, 2, 1), facing * CFrame.new(0, 3, 0), shirt, m)
		bodyPart("Head", Vector3.new(1.4, 1.4, 1.4), facing * CFrame.new(0, 4.6, 0), skin, m)
		bodyPart("ArmL", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(-1.4, 3, 0), skin, m)
		bodyPart("ArmR", Vector3.new(0.8, 2, 0.8), facing * CFrame.new(1.4, 3, 0), skin, m)
		bodyPart("LegL", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(-0.55, 1, 0), pants, m)
		bodyPart("LegR", Vector3.new(0.9, 2, 0.9), facing * CFrame.new(0.55, 1, 0), pants, m)

		m.PrimaryPart = torso

		local gui = Instance.new("BillboardGui")
		gui.Name = "Bubble"
		gui.Size = UDim2.fromScale(12, 3.4)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 160
		gui.Adornee = torso
		gui.Parent = torso

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
		frame.BackgroundTransparency = 0.25
		frame.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = frame

		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.new(1, -12, 1, -8)
		tl.Position = UDim2.new(0, 6, 0, 4)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamMedium
		tl.TextSize = 20
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextWrapped = true
		tl.RichText = true
		tl.Text = ""
		tl.Parent = frame

		bubbleText = tl
		return m
	end

	local function refreshBubble()
		local c = current
		if not c or not bubbleText then
			return
		end
		local color = c.multiplier >= 1.6 and "rgb(120,255,150)"
			or (c.multiplier >= 1.1 and "rgb(255,220,120)" or "rgb(255,150,150)")
		bubbleText.Text = string.format(
			'<b>%s</b>: "%s"\n<font color="%s">betaalt x%.2f</font>',
			c.name, c.line, color, c.multiplier
		)
	end

	function Customers.current(): Customer?
		return current
	end

	local function newCustomer()
		local cfg = Config.Customer
		local mult = cfg.minMultiplier + math.random() * (cfg.maxMultiplier - cfg.minMultiplier)
		current = {
			name = cfg.names[math.random(#cfg.names)],
			line = cfg.lines[math.random(#cfg.lines)],
			multiplier = math.floor(mult * 100 + 0.5) / 100,
			expiresAt = os.clock() + cfg.rotateSeconds,
		}
		if model then
			local torso = model.PrimaryPart
			if torso then
				torso.Color = Color3.fromHSV(math.random(), 0.55, 0.85)
			end
		end
		refreshBubble()
		Net.event("CustomerChanged"):FireAllClients(current)
	end

	function Customers.start(spot: BasePart)
		model = buildModel(spot)
		model.Parent = spot.Parent
		newCustomer()

		task.spawn(function()
			while true do
				task.wait(Config.Customer.rotateSeconds)
				newCustomer()
			end
		end)
	end

	-- Na een verkoop gaat de klant tevreden weg en komt er een nieuwe.
	function Customers.serve()
		newCustomer()
	end

	return Customers
end)()

PEN.Game = (function()
	--!strict
	-- De spelregels: pennen maken, verkopen, upgraden, rebirthen.

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local Config = PEN.Config
	local Net = PEN.Net
	local Data = PEN.Data
	local World = PEN.World
	local Customers = PEN.Customers

	local Game = {}

	local TICK = 0.1
	local UPGRADE_PAD_COOLDOWN = 0.55
	local SELL_COOLDOWN = 0.25
	local REBIRTH_HOLD = 2

	local pads: { [string]: BasePart } = {}
	local nextProduce: { [Player]: number } = {}
	local nextSell: { [Player]: number } = {}
	local nextUpgrade: { [Player]: number } = {}
	local rebirthHeldSince: { [Player]: number? } = {}

	local function notify(player: Player, text: string, color: Color3?)
		Net.event("Notify"):FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
	end

	local function upgradeValue(profile, key: string): number
		local up = Config.getUpgrade(key)
		if not up then
			return 0
		end
		return up.value(profile.upgrades[key] or 1)
	end

	local function capacityOf(profile): number
		return math.floor(upgradeValue(profile, "capacity"))
	end

	local function sellMultiplier(profile): number
		return upgradeValue(profile, "charm") * Config.rebirthMultiplier(profile.rebirths)
	end

	local function currentPen(profile)
		return Config.getPen(Config.unlockedPenIndex(profile.rebirths))
	end

	local function buildState(player: Player, profile)
		local pen = currentPen(profile)
		local customer = Customers.current()
		local upgrades = {}
		for _, up in Config.Upgrades do
			local level = profile.upgrades[up.key] or 1
			local maxed = level >= up.maxLevel
			table.insert(upgrades, {
				key = up.key,
				name = up.name,
				info = up.info,
				level = level,
				maxed = maxed,
				price = maxed and 0 or Config.upgradePrice(up, level),
				display = up.format(up.value(level)),
				nextDisplay = maxed and "" or up.format(up.value(level + 1)),
			})
		end
		return {
			cash = profile.cash,
			pens = profile.pens,
			capacity = capacityOf(profile),
			rebirths = profile.rebirths,
			totalSold = profile.totalSold,
			penName = pen.name,
			penValue = pen.value,
			penColor = pen.color,
			sellMultiplier = sellMultiplier(profile),
			bagValue = math.floor(profile.pens * pen.value * sellMultiplier(profile) * (customer and customer.multiplier or 1)),
			rebirthPrice = Config.rebirthPrice(profile.rebirths),
			canRebirth = profile.cash >= Config.rebirthPrice(profile.rebirths)
				and Config.unlockedPenIndex(profile.rebirths) < #Config.Pens,
			nextPenName = Config.getPen(Config.unlockedPenIndex(profile.rebirths) + 1).name,
			upgrades = upgrades,
		}
	end

	local function push(player: Player)
		local profile = Data.get(player)
		if not profile then
			return
		end
		Net.event("StateChanged"):FireClient(player, buildState(player, profile))

		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local cash = stats:FindFirstChild("Cash") :: IntValue?
			local pens = stats:FindFirstChild("Pennen") :: IntValue?
			local rb = stats:FindFirstChild("Rebirths") :: IntValue?
			if cash then cash.Value = math.floor(math.min(profile.cash, 2 ^ 31 - 1)) end
			if pens then pens.Value = profile.pens end
			if rb then rb.Value = profile.rebirths end
		end
	end

	local function applyWalkSpeed(player: Player)
		local profile = Data.get(player)
		local character = player.Character
		if not profile or not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = upgradeValue(profile, "legs")
		end
	end

	local function isOnPad(root: BasePart, padPart: BasePart): boolean
		local offset = padPart.CFrame:PointToObjectSpace(root.Position)
		local half = padPart.Size / 2
		return math.abs(offset.X) <= half.X + 1
			and math.abs(offset.Z) <= half.Z + 1
			and offset.Y >= -2
			and offset.Y <= 8
	end

	local function sell(player: Player, profile)
		if profile.pens <= 0 then
			return
		end
		local pen = currentPen(profile)
		local customer = Customers.current()
		local customerMult = customer and customer.multiplier or 1
		local earned = math.floor(profile.pens * pen.value * sellMultiplier(profile) * customerMult)

		local sold = profile.pens
		profile.cash += earned
		profile.totalSold += sold
		profile.pens = 0
		profile.dirty = true

		notify(player, string.format(
			"%s kocht %d x %s voor %s (x%.2f)",
			customer and customer.name or "Klant", sold, pen.name, Config.short(earned), customerMult
		), Color3.fromRGB(120, 255, 150))

		Customers.serve()
		push(player)
	end

	local function buyUpgrade(player: Player, key: string, silent: boolean?)
		local profile = Data.get(player)
		if not profile then
			return
		end
		local up = Config.getUpgrade(key)
		if not up then
			return
		end
		local level = profile.upgrades[key] or 1
		if level >= up.maxLevel then
			if not silent then
				notify(player, up.name .. " is al maximaal", Color3.fromRGB(255, 220, 120))
			end
			return
		end
		local price = Config.upgradePrice(up, level)
		if profile.cash < price then
			if not silent then
				notify(player, string.format("Je hebt %s nodig voor %s", Config.short(price), up.name),
					Color3.fromRGB(255, 150, 150))
			end
			return
		end
		profile.cash -= price
		profile.upgrades[key] = level + 1
		profile.dirty = true

		notify(player, string.format("%s -> level %d (%s)", up.name, level + 1, up.format(up.value(level + 1))),
			Color3.fromRGB(255, 220, 120))

		if key == "legs" then
			applyWalkSpeed(player)
		end
		if key == "capacity" then
			profile.pens = math.min(profile.pens, capacityOf(profile))
		end
		push(player)
	end

	local function rebirth(player: Player)
		local profile = Data.get(player)
		if not profile then
			return
		end
		if Config.unlockedPenIndex(profile.rebirths) >= #Config.Pens then
			notify(player, "Je hebt alle pennen al vrijgespeeld!", Color3.fromRGB(255, 220, 120))
			return
		end
		local price = Config.rebirthPrice(profile.rebirths)
		if profile.cash < price then
			notify(player, string.format("Rebirth kost %s", Config.short(price)), Color3.fromRGB(255, 150, 150))
			return
		end
		profile.cash -= price
		profile.rebirths += 1
		profile.pens = 0
		profile.dirty = true

		local pen = currentPen(profile)
		notify(player, string.format("REBIRTH %d! Je maakt nu %s (x%.2f prijs)",
			profile.rebirths, pen.name, Config.rebirthMultiplier(profile.rebirths)),
			Color3.fromRGB(200, 120, 255))
		push(player)
		Data.save(player)
	end

	local function onCharacter(player: Player, character: Model)
		character:WaitForChild("Humanoid")
		task.wait(0.1)
		applyWalkSpeed(player)
	end

	local function onPlayerAdded(player: Player)
		local profile = Data.load(player)

		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		for _, name in { "Cash", "Pennen", "Rebirths" } do
			local v = Instance.new("IntValue")
			v.Name = name
			v.Parent = stats
		end
		stats.Parent = player

		nextProduce[player] = 0
		nextSell[player] = 0
		nextUpgrade[player] = 0

		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			onCharacter(player, player.Character)
		end

		push(player)
		notify(player, string.format("Welkom! Je maakt %s.", currentPen(profile).name), Color3.fromRGB(150, 210, 255))
	end

	local function onPlayerRemoving(player: Player)
		nextProduce[player] = nil
		nextSell[player] = nil
		nextUpgrade[player] = nil
		rebirthHeldSince[player] = nil
		Data.release(player)
	end

	local function step()
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local profile = Data.get(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not profile or not root then
				continue
			end

			-- pennen maken
			local pressPad = pads.PenPress
			if pressPad and isOnPad(root, pressPad) then
				local capacity = capacityOf(profile)
				local interval = upgradeValue(profile, "speed")
				local made = 0
				-- bij hoge snelheid passen er meerdere pennen in een tick
				while now >= (nextProduce[player] or 0) and profile.pens < capacity and made < 64 do
					profile.pens += 1
					made += 1
					nextProduce[player] = math.max((nextProduce[player] or now) + interval, now - interval)
				end
				if made > 0 then
					profile.dirty = true
					push(player)
				elseif profile.pens >= capacity and now >= (nextProduce[player] or 0) then
					nextProduce[player] = now + 1
					notify(player, "Je tas zit vol - ga verkopen!", Color3.fromRGB(255, 220, 120))
				end
			else
				nextProduce[player] = math.max(nextProduce[player] or 0, now)
			end

			-- verkopen
			local sellPad = pads.SellDesk
			if sellPad and isOnPad(root, sellPad) and profile.pens > 0 and now >= (nextSell[player] or 0) then
				nextSell[player] = now + SELL_COOLDOWN
				sell(player, profile)
			end

			-- upgrades op de plaat
			if now >= (nextUpgrade[player] or 0) then
				for _, up in Config.Upgrades do
					local padPart = pads["UpgradePad_" .. up.key]
					if padPart and isOnPad(root, padPart) then
						nextUpgrade[player] = now + UPGRADE_PAD_COOLDOWN
						buyUpgrade(player, up.key, true)
						break
					end
				end
			end

			-- rebirth: even blijven staan
			local rebirthPad = pads.RebirthPad
			if rebirthPad and isOnPad(root, rebirthPad) then
				local since = rebirthHeldSince[player]
				if not since then
					rebirthHeldSince[player] = now
				elseif now - since >= REBIRTH_HOLD then
					rebirthHeldSince[player] = nil
					rebirth(player)
				end
			else
				rebirthHeldSince[player] = nil
			end
		end
	end

	function Game.start()
		Net.init()

		local root = World.build()
		for _, name in { "PenPress", "SellDesk", "RebirthPad" } do
			local p = World.findPad(root, name)
			if p then
				pads[name] = p
			end
		end
		for _, up in Config.Upgrades do
			local p = World.findPad(root, "UpgradePad_" .. up.key)
			if p then
				pads["UpgradePad_" .. up.key] = p
			end
		end

		local spot = root:FindFirstChild("CustomerSpot")
		if spot and spot:IsA("BasePart") then
			Customers.start(spot)
		end

		Net.event("BuyUpgrade").OnServerEvent:Connect(function(player, key)
			if typeof(key) == "string" then
				buyUpgrade(player, key)
			end
		end)
		Net.event("Rebirth").OnServerEvent:Connect(function(player)
			rebirth(player)
		end)

		Players.PlayerAdded:Connect(onPlayerAdded)
		Players.PlayerRemoving:Connect(onPlayerRemoving)
		for _, player in Players:GetPlayers() do
			task.spawn(onPlayerAdded, player)
		end

		Data.start()

		-- klantwissel: prijzen in de UI bijwerken
		task.spawn(function()
			while true do
				task.wait(1)
				for _, player in Players:GetPlayers() do
					push(player)
				end
			end
		end)

		local acc = 0
		RunService.Heartbeat:Connect(function(dt)
			acc += dt
			if acc >= TICK then
				acc = 0
				step()
			end
		end)
	end

	return Game
end)()

-- ---- startpunt ----
--!strict
-- Startpunt op de server.
local Game = PEN.Game
Game.start()
