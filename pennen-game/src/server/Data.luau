--!strict
-- Opslaan en laden. Gebruikt DataStore, maar de game blijft werken
-- als DataStore niet beschikbaar is (bijv. in Studio zonder API-toegang).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

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
