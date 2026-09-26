--!strict
-- Opslaan en laden. Gebruikt DataStore, maar de game blijft speelbaar
-- als DataStore niet beschikbaar is (bijv. Studio zonder API-toegang).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

local Data = {}

export type Profile = {
	cash: number,
	bag: { [string]: number },   -- pennen per soort zaak
	rebirths: number,
	totalSold: number,
	upgrades: { [string]: number },
	pets: { [string]: boolean },
	equippedPet: string?,
	dailyStreak: number,
	lastDailyAt: number,
	redeemed: { [string]: boolean },
	index: { [string]: number },          -- bezoekers die je getrade hebt
	staff: { { key: string, stamina: number, lastPaidAt: number } },
	lastSeen: number,
	-- niet opgeslagen, alleen deze sessie:
	loaded: boolean,
	dirty: boolean,
	pitchStreak: number,
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
		bag = {},
		rebirths = 0,
		totalSold = 0,
		upgrades = upgrades,
		pets = {},
		equippedPet = nil,
		dailyStreak = 0,
		lastDailyAt = 0,
		redeemed = {},
		index = {},
		staff = {},
		lastSeen = 0,
		loaded = false,
		dirty = false,
		pitchStreak = 0,
	}
end

local function sanitize(raw: any): Profile
	local p = defaultProfile()
	if typeof(raw) ~= "table" then
		return p
	end
	p.cash = math.max(0, tonumber(raw.cash) or 0)
	if typeof(raw.bag) == "table" then
		for _, station in Config.Stations do
			local amount = math.floor(tonumber(raw.bag[station.key]) or 0)
			if amount > 0 then
				p.bag[station.key] = amount
			end
		end
	elseif tonumber(raw.pens) then
		-- opslag van voor de bezoekers-update: alles telt als pennen van de kraam
		local amount = math.max(0, math.floor(tonumber(raw.pens) or 0))
		if amount > 0 then
			p.bag[Config.Stations[1].key] = amount
		end
	end
	p.rebirths = math.clamp(math.floor(tonumber(raw.rebirths) or 0), 0, #Config.Stations - 1)
	p.totalSold = math.max(0, math.floor(tonumber(raw.totalSold) or 0))
	p.dailyStreak = math.clamp(math.floor(tonumber(raw.dailyStreak) or 0), 0, Config.Daily.maxStreak)
	p.lastDailyAt = math.max(0, math.floor(tonumber(raw.lastDailyAt) or 0))
	p.lastSeen = math.max(0, math.floor(tonumber(raw.lastSeen) or 0))

	if typeof(raw.upgrades) == "table" then
		for _, up in Config.Upgrades do
			local lvl = math.floor(tonumber(raw.upgrades[up.key]) or 1)
			p.upgrades[up.key] = math.clamp(lvl, 1, up.maxLevel)
		end
	end
	if typeof(raw.pets) == "table" then
		for _, pet in Config.Pets do
			if raw.pets[pet.key] == true then
				p.pets[pet.key] = true
			end
		end
	end
	if typeof(raw.equippedPet) == "string" and p.pets[raw.equippedPet] then
		p.equippedPet = raw.equippedPet
	end
	if typeof(raw.index) == "table" then
		for _, visitor in Config.Visitors do
			local traded = math.floor(tonumber(raw.index[visitor.key]) or 0)
			if traded > 0 then
				p.index[visitor.key] = traded
			end
		end
	end
	if typeof(raw.staff) == "table" then
		for _, entry in raw.staff do
			if typeof(entry) == "table" and typeof(entry.key) == "string"
				and Config.getVisitor(entry.key) and p.index[entry.key] then
				table.insert(p.staff, {
					key = entry.key,
					stamina = math.clamp(tonumber(entry.stamina) or 100, 0, 1000),
					lastPaidAt = math.max(0, math.floor(tonumber(entry.lastPaidAt) or 0)),
				})
			end
		end
	end
	if typeof(raw.redeemed) == "table" then
		for _, entry in Config.Codes do
			if raw.redeemed[entry.code] == true then
				p.redeemed[entry.code] = true
			end
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

function Data.all(): { [Player]: Profile }
	return profiles
end

function Data.save(player: Player): boolean
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false
	end
	profile.lastSeen = os.time()
	local ds = getStore()
	if not ds then
		return false
	end
	local payload = {
		cash = profile.cash,
		bag = profile.bag,
		rebirths = profile.rebirths,
		totalSold = profile.totalSold,
		upgrades = profile.upgrades,
		pets = profile.pets,
		equippedPet = profile.equippedPet,
		dailyStreak = profile.dailyStreak,
		lastDailyAt = profile.lastDailyAt,
		redeemed = profile.redeemed,
		index = profile.index,
		staff = profile.staff,
		lastSeen = profile.lastSeen,
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
