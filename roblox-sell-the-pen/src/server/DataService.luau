-- Loads, holds and saves every player's profile.
-- Works without DataStore access (e.g. an unpublished place in Studio):
-- progress then simply isn't saved.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local STORE_NAME = "SellMeThisPen_v2"
local LEADERBOARD_NAME = "SellMeThisPen_NetWorth_v2"

local store
local leaderboardStore
do
	local ok, err = pcall(function()
		store = DataStoreService:GetDataStore(STORE_NAME)
		leaderboardStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_NAME)
	end)
	if not ok then
		warn("[DataService] DataStores unavailable, progress won't save:", err)
	end
end

local profiles = {} -- [Player] = profile
local loaded = {} -- [Player] = true once the load attempt finished
local changedCallbacks = {}

local function defaultProfile()
	return {
		cash = Config.StartingCash,
		lifetime = 0, -- lifetime earnings, never reset (leaderboard)
		pensSold = 0,
		ipos = 0,
		pen = "bic",
		suit = "thrift",
		phone = "none",
		brokers = {}, -- array of visitor ids, max Config.MaxBrokers
		index = {}, -- [visitorId] = times sold to
		best = nil, -- id of the rarest visitor ever sold to
		perfectCloses = 0,
		napkins = 0,
		lastOnline = 0,
		tutorialStep = 0, -- steps finished
		tutorialDone = false,
		boostUntil = 0, -- os.time() until x2 money ends
		lastDaily = 0,
	}
end

-- Fill in fields added in later versions of the game.
local function reconcile(data)
	local template = defaultProfile()
	for key, value in template do
		if data[key] == nil then
			data[key] = value
		end
	end
	-- Brokers must be a plain array of visitor ids.
	local clean = {}
	for _, id in ipairs(data.brokers) do
		if type(id) == "string" and #clean < Config.MaxBrokers then
			table.insert(clean, id)
		end
	end
	data.brokers = clean
	data.zones = nil
	return data
end

local function withRetries(fn)
	for attempt = 1, 4 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(string.format("[DataService] attempt %d failed: %s", attempt, tostring(result)))
		-- No API access (e.g. Studio without "Enable Studio Access to API Services"): don't bother retrying.
		local message = tostring(result)
		if message:find("403") or message:find("Studio") or message:find("publish") then
			return false, nil
		end
		task.wait(attempt * 1.5)
	end
	return false, nil
end

function DataService.onChanged(callback)
	table.insert(changedCallbacks, callback)
end

function DataService.get(player)
	return profiles[player]
end

function DataService.isLoaded(player)
	return loaded[player] == true
end

-- Call after mutating a profile so clients and leaderstats refresh.
function DataService.changed(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	for _, callback in changedCallbacks do
		task.spawn(callback, player, profile)
	end
end

function DataService.addCash(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.cash += amount
	if amount > 0 then
		profile.lifetime += amount
	end
	DataService.changed(player)
end

function DataService.load(player)
	local key = "player_" .. player.UserId
	local data
	if store then
		local ok, result = withRetries(function()
			return store:GetAsync(key)
		end)
		if ok then
			data = result
		else
			-- Don't let a failed load overwrite the real save later.
			player:SetAttribute("SaveDisabled", true)
			warn("[DataService] could not load", player.Name, "- saving disabled this session")
		end
	end
	if not player.Parent then
		return nil
	end
	local profile = reconcile(type(data) == "table" and data or defaultProfile())
	profiles[player] = profile
	loaded[player] = true
	return profile
end

function DataService.save(player)
	local profile = profiles[player]
	if not store or not profile or player:GetAttribute("SaveDisabled") then
		return
	end
	profile.lastOnline = os.time()
	local key = "player_" .. player.UserId
	withRetries(function()
		store:SetAsync(key, profile)
	end)
	if leaderboardStore then
		pcall(function()
			leaderboardStore:SetAsync(key, math.floor(profile.lifetime))
		end)
	end
end

function DataService.release(player)
	DataService.save(player)
	profiles[player] = nil
	loaded[player] = nil
end

function DataService.getTopEarners(count)
	if not leaderboardStore then
		return {}
	end
	local ok, pages = pcall(function()
		return leaderboardStore:GetSortedAsync(false, count)
	end)
	if not ok then
		return {}
	end
	local results = {}
	for rank, entry in pages:GetCurrentPage() do
		local userId = tonumber(string.match(entry.key, "%d+"))
		local name = "???"
		if userId then
			local nameOk, fetched = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameOk then
				name = fetched
			end
		end
		table.insert(results, { rank = rank, name = name, value = entry.value })
	end
	return results
end

function DataService.start()
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for player in profiles do
				task.spawn(DataService.save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.save(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait()
		end
	end)
end

return DataService
