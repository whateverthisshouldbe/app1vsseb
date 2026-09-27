--!strict
-- Spelersdata: laden en opslaan in een DataStore, geld, multipliers en de
-- status die naar de client gaat. Werkt ook zonder DataStore (Studio zonder
-- API-toegang); de voortgang wordt dan alleen niet bewaard.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))

local Events = require(script.Parent.Events)
local Remotes = require(script.Parent.Remotes)

local STORE_NAME = "StealASong_v1"
local LEADERBOARD_NAME = "StealASong_Lifetime_v1"
local AUTOSAVE_SECONDS = 60

export type Data = {
	cash: number,
	lifetime: number,
	rebirths: number,
	steals: number,
	songs: { Economy.Song },
	upgrades: { [string]: number },
	discovered: { [string]: boolean },
	discoveredMut: { [string]: boolean },
	dailyDay: number,
	dailyStreak: number,
	lastSeen: number,
}

export type Session = {
	player: Player,
	data: Data,
	canSave: boolean,
	income: number,
	friends: { [number]: boolean },
	friendCount: number,
	passes: { [string]: boolean },
	joinedAt: number,
	dirty: boolean,
	cashValue: StringValue,
	stealsValue: IntValue,
	rebirthsValue: IntValue,
}

local PlayerData = {}

local sessions: { [Player]: Session } = {}
local providers: { (Player, any) -> () } = {}
local activeSaves = 0

local store: DataStore? = nil
local leaderboardStore: OrderedDataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[StealASong] DataStore unavailable, progress will not be saved: " .. tostring(result))
	end
	local okBoard, board = pcall(function()
		return DataStoreService:GetOrderedDataStore(LEADERBOARD_NAME)
	end)
	if okBoard then
		leaderboardStore = board
	end
end

local function defaultData(): Data
	return {
		cash = Config.StartingCash,
		lifetime = 0,
		rebirths = 0,
		steals = 0,
		songs = {},
		upgrades = {},
		discovered = {},
		discoveredMut = {},
		dailyDay = 0,
		dailyStreak = 0,
		lastSeen = 0,
	}
end

-- Vult ontbrekende velden aan en gooit ongeldige songs weg, zodat oude of
-- kapotte saves nooit een fout geven.
local function reconcile(raw: any): Data
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end
	for key, value in data :: any do
		if type(raw[key]) == type(value) then
			(data :: any)[key] = raw[key]
		end
	end
	local songs = {}
	for _, song in data.songs do
		if Economy.isValidSong(song) then
			table.insert(songs, { id = song.id, mut = song.mut, base = song.base, streams = song.streams, slot = song.slot })
		end
	end
	data.songs = songs
	return data
end

local function serialize(data: Data): any
	local songs = {}
	for _, song in data.songs do
		table.insert(songs, {
			id = song.id,
			mut = song.mut,
			base = math.floor(song.base),
			streams = math.floor(song.streams),
			slot = song.slot,
		})
	end
	return {
		cash = data.cash,
		lifetime = data.lifetime,
		rebirths = data.rebirths,
		steals = data.steals,
		songs = songs,
		upgrades = data.upgrades,
		discovered = data.discovered,
		discoveredMut = data.discoveredMut,
		dailyDay = data.dailyDay,
		dailyStreak = data.dailyStreak,
		lastSeen = data.lastSeen,
	}
end

local function key(player: Player): string
	return "player_" .. player.UserId
end

local function makeLeaderstats(player: Player): (StringValue, IntValue, IntValue)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = folder
	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = folder
	folder.Parent = player
	return cash, steals, rebirths
end

function PlayerData.load(player: Player): Session
	local raw = nil
	local loaded = false
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return (store :: DataStore):GetAsync(key(player))
			end)
			if ok then
				raw = result
				loaded = true
				break
			end
			warn("[StealASong] load failed for " .. player.Name .. " (" .. attempt .. "/3): " .. tostring(result))
			-- In Studio zonder API-toegang heeft opnieuw proberen geen zin
			local message = tostring(result)
			if string.find(message, "StudioAccessToApisNotAllowed", 1, true) or string.find(message, "publish", 1, true) then
				break
			end
			if attempt < 3 then
				task.wait(attempt)
			end
		end
	end

	local cashValue, stealsValue, rebirthsValue = makeLeaderstats(player)
	local session: Session = {
		player = player,
		data = reconcile(raw),
		canSave = loaded,
		income = 0,
		friends = {},
		friendCount = 0,
		passes = {},
		joinedAt = os.clock(),
		dirty = true,
		cashValue = cashValue,
		stealsValue = stealsValue,
		rebirthsValue = rebirthsValue,
	}
	sessions[player] = session
	return session
end

function PlayerData.save(player: Player)
	local session = sessions[player]
	if not session or not session.canSave or not store then
		return
	end
	local data = session.data
	data.lastSeen = os.time()
	local payload = serialize(data)
	activeSaves += 1
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key(player), function()
				return payload
			end)
		end)
		if ok then
			break
		end
		warn("[StealASong] save failed for " .. player.Name .. " (" .. attempt .. "/3): " .. tostring(err))
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	activeSaves -= 1

	if leaderboardStore then
		local score = math.floor(math.min(data.lifetime, 2 ^ 53))
		pcall(function()
			(leaderboardStore :: OrderedDataStore):SetAsync(tostring(player.UserId), score)
		end)
	end
end

function PlayerData.session(player: Player): Session?
	return sessions[player]
end

function PlayerData.get(player: Player): Data?
	local session = sessions[player]
	return if session then session.data else nil
end

function PlayerData.canSave(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and session.canSave
end

function PlayerData.markDirty(player: Player)
	local session = sessions[player]
	if session then
		session.dirty = true
	end
end

function PlayerData.addCash(player: Player, amount: number, earned: boolean?)
	local session = sessions[player]
	if not session or amount ~= amount then
		return
	end
	session.data.cash += amount
	if earned then
		session.data.lifetime += amount
	end
	session.dirty = true
end

function PlayerData.spend(player: Player, amount: number): boolean
	local session = sessions[player]
	if not session or session.data.cash < amount then
		return false
	end
	session.data.cash -= amount
	session.dirty = true
	return true
end

function PlayerData.setIncome(player: Player, income: number)
	local session = sessions[player]
	if session and session.income ~= income then
		session.income = income
		session.dirty = true
	end
end

function PlayerData.income(player: Player): number
	local session = sessions[player]
	return if session then session.income else 0
end

-- Geeft true als het een nieuwe song voor de Index is
function PlayerData.discover(player: Player, song: Economy.Song): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	local data = session.data
	local isNew = not data.discovered[song.id]
	data.discovered[song.id] = true
	if song.mut then
		data.discoveredMut[song.id .. "|" .. song.mut] = true
	end
	session.dirty = true
	return isNew
end

function PlayerData.setPass(player: Player, passKey: string, owned: boolean)
	local session = sessions[player]
	if session then
		session.passes[passKey] = owned
		session.dirty = true
	end
end

function PlayerData.multiplier(player: Player): (number, { [string]: number })
	local session = sessions[player]
	if not session then
		return 1, {}
	end
	local data = session.data
	local rebirth = Economy.rebirthMultiplier(data.rebirths)
	local _, indexBonus = Economy.indexProgress(data.discovered)
	local friends = Economy.friendBoost(session.friendCount)
	local pass = (if session.passes.DoubleCash then 2 else 1) * (if session.passes.VIP then 1.5 else 1)
	local event = Events.incomeMult()
	local total = rebirth * (1 + indexBonus) * (1 + friends) * pass * event
	return total, {
		rebirth = rebirth,
		index = 1 + indexBonus,
		friends = 1 + friends,
		pass = pass,
		event = event,
	}
end

function PlayerData.walkSpeed(player: Player): number
	local session = sessions[player]
	if not session then
		return Config.WalkSpeed
	end
	return Economy.walkSpeed(session.data.upgrades.Speed or 0, session.passes.VIP == true)
end

-- Vriendenbonus: telt vrienden die in dezelfde server zitten
local function recountFriends()
	for _, session in sessions do
		local count = 0
		for userId in session.friends do
			local other = Players:GetPlayerByUserId(userId)
			if other and sessions[other] then
				count += 1
			end
		end
		if count ~= session.friendCount then
			session.friendCount = count
			session.dirty = true
			if count > 0 then
				Remotes.toast(session.player, "👯 Friend boost: +" .. math.floor(Economy.friendBoost(count) * 100) .. "% royalties", "good")
			end
		end
	end
end

function PlayerData.refreshFriends(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	for other, otherSession in sessions do
		if other ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWith(other.UserId)
			end)
			if ok and isFriend then
				session.friends[other.UserId] = true
				otherSession.friends[player.UserId] = true
			end
		end
	end
	recountFriends()
end

function PlayerData.addStateProvider(provider: (Player, any) -> ())
	table.insert(providers, provider)
end

function PlayerData.push(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	session.dirty = false
	local data = session.data
	local multiplier, boosts = PlayerData.multiplier(player)
	local state = {
		cash = data.cash,
		lifetime = data.lifetime,
		rebirths = data.rebirths,
		steals = data.steals,
		income = session.income,
		multiplier = multiplier,
		boosts = boosts,
		friendCount = session.friendCount,
		upgrades = data.upgrades,
		discovered = data.discovered,
		discoveredMut = data.discoveredMut,
		songCount = #data.songs,
		slots = Economy.slotCount(data.rebirths),
		rebirthCost = Economy.rebirthCost(data.rebirths),
		passes = session.passes,
		canSave = session.canSave,
	}
	for _, provider in providers do
		provider(player, state)
	end
	Remotes.fire("State", player, state)

	session.cashValue.Value = Format.cash(data.cash)
	session.stealsValue.Value = data.steals
	session.rebirthsValue.Value = data.rebirths
end

function PlayerData.release(player: Player)
	if not sessions[player] then
		return
	end
	PlayerData.save(player)
	sessions[player] = nil
	recountFriends()
end

function PlayerData.all(): { [Player]: Session }
	return sessions
end

function PlayerData.init()
	-- Status bundelen: hooguit vijf keer per seconde naar de client
	task.spawn(function()
		while true do
			task.wait(0.2)
			for player, session in sessions do
				if session.dirty then
					PlayerData.push(player)
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in sessions do
				task.spawn(PlayerData.save, player)
			end
		end
	end)

	game:BindToClose(function()
		for player in sessions do
			task.spawn(PlayerData.save, player)
		end
		local started = os.clock()
		task.wait(0.5)
		while activeSaves > 0 and os.clock() - started < 25 do
			task.wait(0.5)
		end
	end)
end

return PlayerData
