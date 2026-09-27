--!strict
-- Twee borden: de LIVE CHART boven de loper (de 10 songs met de meeste
-- streams in deze server, met eigenaar: een doelwittenlijst voor dieven) en
-- het all-time leaderboard op basis van alles wat spelers ooit verdienden.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Economy"))
local Format = require(Shared:WaitForChild("Format"))
local Songs = require(Shared:WaitForChild("Songs"))

local MapBuilder = require(script.Parent.MapBuilder)
local Plots = require(script.Parent.Plots)

local Boards = {}

local ROWS = 10
local FONT = Enum.Font.FredokaOne

type Row = { rank: TextLabel, name: TextLabel, detail: TextLabel }

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		(label :: any)[key] = value
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(10, 5, 20)
	stroke.Parent = label
	label.Parent = parent
	return label
end

-- Bouwt een bord met titel en ROWS regels op één kant van een part
local function buildList(board: BasePart, face: Enum.NormalId, title: string, titleColor: Color3): { Row }
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board

	text(gui, {
		Name = "Title",
		Text = title,
		TextColor3 = titleColor,
		Size = UDim2.new(1, -30, 0.14, 0),
		Position = UDim2.new(0, 15, 0.02, 0),
	})

	local rows: { Row } = {}
	local top = 0.18
	local height = (1 - top - 0.03) / ROWS
	for i = 1, ROWS do
		local y = top + (i - 1) * height
		local rank = text(gui, {
			Text = "#" .. i,
			TextColor3 = if i == 1 then Color3.fromRGB(255, 215, 60) else Color3.fromRGB(200, 190, 230),
			Size = UDim2.new(0.1, 0, height * 0.9, 0),
			Position = UDim2.new(0.02, 0, y, 0),
		})
		local name = text(gui, {
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.5, 0, height * 0.9, 0),
			Position = UDim2.new(0.13, 0, y, 0),
		})
		local detail = text(gui, {
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = Color3.fromRGB(170, 225, 255),
			Size = UDim2.new(0.34, 0, height * 0.9, 0),
			Position = UDim2.new(0.64, 0, y, 0),
		})
		rows[i] = { rank = rank, name = name, detail = detail }
	end
	return rows
end

local function updateChart(sides: { { Row } })
	local entries = {}
	for _, plot in Plots.all() do
		local owner = plot.owner
		if owner then
			for _, slot in plot.slots do
				local song = slot.song
				if song and not slot.thief then
					table.insert(entries, { song = song, owner = owner })
				end
			end
		end
	end
	table.sort(entries, function(a, b)
		return a.song.streams > b.song.streams
	end)

	for _, rows in sides do
		for i, row in rows do
			local entry = entries[i]
			if entry then
				local def = Songs.byId[entry.song.id]
				local rarity = Economy.rarity(def.rarity)
				local mutation = if entry.song.mut then entry.song.mut .. " " else ""
				row.name.Text = mutation .. def.name .. "  ·  " .. entry.owner.DisplayName
				row.name.TextColor3 = if def.rarity == "Secret" then Color3.fromRGB(245, 245, 255) else rgb(rarity.color)
				row.detail.Text = "🎧 " .. Format.short(entry.song.streams)
			else
				row.name.Text = if i == 1 then "No songs yet. Go buy one!" else ""
				row.name.TextColor3 = Color3.new(1, 1, 1)
				row.detail.Text = ""
			end
		end
	end
end

local nameCache: { [number]: string } = {}

local function nameFor(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local player = Players:GetPlayerByUserId(userId)
	local name = if player then player.DisplayName else nil
	if not name then
		local ok, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		name = if ok then result else "Player " .. userId
	end
	nameCache[userId] = name :: string
	return name :: string
end

local function updateLeaderboard(rows: { Row })
	local ok, pages = pcall(function()
		local store = DataStoreService:GetOrderedDataStore("StealASong_Lifetime_v1")
		return store:GetSortedAsync(false, ROWS)
	end)
	if not ok then
		rows[1].name.Text = "Leaderboard offline"
		rows[1].detail.Text = ""
		return
	end
	local list = (pages :: DataStorePages):GetCurrentPage()
	for i, row in rows do
		local entry = list[i]
		if entry then
			row.name.Text = nameFor(tonumber(entry.key) or 0)
			row.detail.Text = Format.cash(entry.value)
			row.detail.TextColor3 = Color3.fromRGB(110, 255, 130)
		else
			row.name.Text = ""
			row.detail.Text = ""
		end
	end
end

function Boards.init(map: MapBuilder.MapInfo)
	local chartTitle = "🔥 LIVE CHART · MOST STREAMED IN THIS SERVER"
	local chartColor = Color3.fromRGB(255, 90, 200)
	local chartSides = {
		buildList(map.chartBoard, Enum.NormalId.Front, chartTitle, chartColor),
		buildList(map.chartBoard, Enum.NormalId.Back, chartTitle, chartColor),
	}
	local leaderRows = buildList(map.leaderboard, Enum.NormalId.Front, "💰 ALL-TIME TOP ARTISTS", Color3.fromRGB(255, 215, 60))

	task.spawn(function()
		while true do
			updateChart(chartSides)
			task.wait(3)
		end
	end)

	task.spawn(function()
		while true do
			updateLeaderboard(leaderRows)
			task.wait(120)
		end
	end)
end

return Boards
