--!strict
-- De twee borden op het plein: rijkste verkopers en meeste rebirths.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

local Leaderboards = {}

local REFRESH_SECONDS = 120
local MAX_VALUE = 1e15

local stores: { [string]: OrderedDataStore } = {}
local labels: { [string]: TextLabel } = {}
local nameCache: { [number]: string } = {}

local function getStore(kind: string): OrderedDataStore?
	if stores[kind] then
		return stores[kind]
	end
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(Config.DataStoreKey .. "_" .. kind)
	end)
	if not ok then
		return nil
	end
	stores[kind] = result
	return result
end

local function nameFor(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = ok and name or ("Speler " .. userId)
	nameCache[userId] = resolved
	return resolved
end

function Leaderboards.submit(player: Player, cash: number, rebirths: number)
	task.spawn(function()
		local cashStore = getStore("cash")
		if cashStore then
			pcall(function()
				cashStore:SetAsync(tostring(player.UserId), math.clamp(math.floor(cash), 0, MAX_VALUE))
			end)
		end
		local rebirthStore = getStore("rebirths")
		if rebirthStore then
			pcall(function()
				rebirthStore:SetAsync(tostring(player.UserId), math.clamp(math.floor(rebirths), 0, MAX_VALUE))
			end)
		end
	end)
end

local function render(kind: string, formatValue: (number) -> string)
	local label = labels[kind]
	if not label then
		return
	end
	local store = getStore(kind)
	if not store then
		label.Text = "Scorebord werkt pas in een gepubliceerde game."
		return
	end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not ok then
		label.Text = "Even geen verbinding met het scorebord."
		return
	end
	local rows = {}
	local place = 1
	for _, entry in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(entry.key)
		if userId then
			table.insert(rows, string.format("%d. %s  -  %s", place, nameFor(userId), formatValue(entry.value)))
			place += 1
		end
	end
	if #rows == 0 then
		label.Text = "Nog niemand. Wees de eerste!"
	else
		label.Text = table.concat(rows, "\n")
	end
end

function Leaderboards.start(cashLabel: TextLabel?, rebirthLabel: TextLabel?)
	if cashLabel then
		labels.cash = cashLabel
	end
	if rebirthLabel then
		labels.rebirths = rebirthLabel
	end

	task.spawn(function()
		while true do
			render("cash", function(v)
				return "$" .. Config.short(v)
			end)
			render("rebirths", function(v)
				return string.format("%d rebirths", v)
			end)
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return Leaderboards
