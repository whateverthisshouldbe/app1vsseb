-- Draai met: lune run tests/run   (vanuit de map steal-a-song, rojo moet
-- geïnstalleerd zijn). Bouwt de place, test de rekenregels en speelt daarna
-- een complete sessie na met twee spelers: kopen, ophalen, stelen, slaan,
-- locken, verkopen, rebirth, cadeaus, opslaan en opnieuw joinen, en tot slot
-- de interface van de client.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Harness = require("./harness")

local passed, failed = 0, 0

local function check(name: string, condition: any, detail: any?)
	if condition then
		passed += 1
	else
		failed += 1
		print("  FAIL " .. name .. (if detail ~= nil then ": " .. tostring(detail) else ""))
	end
end

-- Vernietigde instances geven in Lune een fout bij elke toegang
local function gone(instance): boolean
	local ok, parent = pcall(function()
		return instance.Parent
	end)
	return not ok or parent == nil
end

local function section(name: string)
	print("== " .. name)
end

-- Place bouwen en inladen --------------------------------------------------

local buildDir = "tests/.build"
if not fs.isDir(buildDir) then
	fs.writeDir(buildDir)
end
local placePath = buildDir .. "/StealASong.rbxlx"
local build = process.exec("rojo", { "build", "default.project.json", "-o", placePath })
assert(build.ok, "rojo build failed: " .. build.stderr .. build.stdout)
local dm = Harness.load(roblox.deserializePlace(fs.readFile(placePath)))

local Workspace = dm:GetService("Workspace")
local RunService = dm:GetService("RunService")
local Players = dm:GetService("Players")
local ReplicatedStorage = dm:GetService("ReplicatedStorage")

local server = Harness.context("server")
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
local Config = server.require(sharedFolder.Config)
local Economy = server.require(sharedFolder.Economy)
local Format = server.require(sharedFolder.Format)
local Songs = server.require(sharedFolder.Songs)

local function main()
	-- Rekenregels ---------------------------------------------------------------

	section("Format")
	local cases = {
		{ 0, "0" },
		{ 5, "5" },
		{ 1.55, "1.5" },
		{ 999, "999" },
		{ 1000, "1K" },
		{ 1234, "1.23K" },
		{ 12345, "12.3K" },
		{ 123456, "123K" },
		{ 999999, "999K" },
		{ 1e6, "1M" },
		{ 1.5e9, "1.5B" },
		{ 1e12, "1T" },
		{ 1e15, "1Qa" },
		{ -2500, "-2.5K" },
	}
	for _, case in cases do
		check("short(" .. case[1] .. ")", Format.short(case[1]) == case[2], Format.short(case[1]))
	end
	check("cash", Format.cash(1500) == "$1.5K", Format.cash(1500))
	check("time m:ss", Format.time(90) == "1:30", Format.time(90))
	check("time h:mm:ss", Format.time(3725) == "1:02:05", Format.time(3725))
	check("duration", Format.duration(7500) == "2h 5m", Format.duration(7500))
	check("multiplier", Format.multiplier(1.5) == "x1.5", Format.multiplier(1.5))

	section("Economy")
	local function fixed(value)
		return function()
			return value
		end
	end
	check("roll common", Economy.rollRarity(1, fixed(0)) == "Common")
	check("roll secret", Economy.rollRarity(1, fixed(0.9999999)) == "Secret")
	check("no mutation", Economy.rollMutation(1, fixed(0.5)) == nil)
	check("gold mutation", Economy.rollMutation(1, fixed(0.01)) == "Gold")
	check("slots start", Economy.slotCount(0) == Config.StartSlots)
	check("slots max", Economy.slotCount(100) == Config.MaxSlots)
	check("rebirth cost 0", Economy.rebirthCost(0) == 1e6)
	check("rebirth cost 1", Economy.rebirthCost(1) == 8e6)
	check("upgrade cost", Economy.upgradeCost("Speed", 0) == 1000)
	check("upgrade maxed", Economy.upgradeCost("Speed", 5) == nil)
	check("walk speed", Economy.walkSpeed(2, true) == Config.WalkSpeed + 4 + 4)

	local song = { id = "garage_demo", base = 5000, streams = 5000 }
	check("price", Economy.price(song) == 100, Economy.price(song))
	check("sell price", Economy.sellPrice(song) == 50)
	check("income", Economy.income(song.streams) == 5)
	local peaked = false
	for _ = 1, 100000 do
		if Economy.grow(song, 1, 0) then
			peaked = true
			break
		end
	end
	check("grows to peak", peaked and song.streams == 5000 * Config.MaxGrowth, song.streams)
	check("no growth past peak", not Economy.grow(song, 100, 0) and song.streams == 15000)

	local gold = Economy.makeSong(Songs.byId.neon_nights, "Gold", fixed(0))
	check("mutation doubles", gold.streams == 10_000_000, gold.streams)

	for _, rarity in Config.Rarities do
		check("songs for " .. rarity.name, Songs.byRarity[rarity.name] and #Songs.byRarity[rarity.name] > 0)
	end
	for _, reward in Config.Gifts do
		check("gift rarity " .. tostring(reward.rarity), reward.kind ~= "song" or Songs.byRarity[reward.rarity] ~= nil)
	end
	for _, reward in Config.Daily do
		check("daily rarity " .. tostring(reward.rarity), reward.kind ~= "song" or Songs.byRarity[reward.rarity] ~= nil)
	end
	for _, def in Songs.list do
		check("range " .. def.id, def.min > 0 and def.max >= def.min)
	end

	local discovered = {}
	for _, def in Songs.byRarity.Common do
		discovered[def.id] = true
	end
	local progress, bonus = Economy.indexProgress(discovered)
	check("index progress", progress.Common.found == progress.Common.total)
	check("index bonus", math.abs(bonus - Config.IndexBonusPerRarity) < 1e-9, bonus)

	-- Verdeling van de loper: grofweg de gewichten uit Config
	local counts = {}
	local rolls = 200000
	for _ = 1, rolls do
		local r = Economy.rollRarity(1)
		counts[r] = (counts[r] or 0) + 1
	end
	local totalWeight = 0
	for _, rarity in Config.Rarities do
		totalWeight += rarity.weight
	end
	local common = counts.Common / rolls
	check("common share", math.abs(common - 55 / totalWeight) < 0.01, common)

	print("  balans (terugverdientijd = prijs / inkomen):")
	for _, rarity in Config.Rarities do
		local def = Songs.byRarity[rarity.name][1]
		local s = Economy.makeSong(def, nil, fixed(0))
		print(string.format(
			"    %-10s %-24s %8s streams  %9s/s  prijs %9s  %3ds  1 op %d drops",
			rarity.name,
			def.name,
			Format.short(s.streams),
			Format.cash(Economy.income(s.streams)),
			Format.cash(Economy.price(s)),
			math.floor(Economy.price(s) / Economy.income(s.streams)),
			math.floor(totalWeight / rarity.weight)
		))
	end

	-- De server --------------------------------------------------------------

	section("server boot")
	local ServerScript = dm:GetService("ServerScriptService"):FindFirstChild("Server")
	server.run(ServerScript)
	task.wait(0.3)

	local Plots = server.require(ServerScript.Plots)
	local PlayerData = server.require(ServerScript.PlayerData)
	local Events = server.require(ServerScript.Events)
	local Remotes = server.require(ServerScript.Remotes)

	check("map built", Workspace:FindFirstChild("Map") ~= nil)
	check("8 studios", #Workspace.Studios:GetChildren() == 8)
	check("conveyor filled", #Workspace.ConveyorSongs:GetChildren() >= 10, #Workspace.ConveyorSongs:GetChildren())
	check("remotes", ReplicatedStorage:FindFirstChild("Remotes") ~= nil)
	check("collision groups", Harness.collisionGroups.Owner1 and Harness.collisionGroups.Barrier8)
	check("no warnings on boot", #Harness.warnings == 0, Harness.warnings[1])

	-- Studio's liggen niet over elkaar en de spawn ligt binnen
	for i, plot in Plots.all() do
		check("spawn inside studio " .. i, Plots.isInside(plot, plot.info.spawn.Position))
		check("outside is outside " .. i, not Plots.isInside(plot, plot.info.outside.Position))
		for j, other in Plots.all() do
			if i ~= j then
				check("studios apart " .. i .. "/" .. j, not Plots.isInside(other, plot.info.cframe.Position))
			end
		end
	end

	-- Niets naast een studio mag hoog genoeg zijn om over de muur (16) te
	-- springen: sprong is ongeveer 7.2 studs.
	local STRUCTURE = {
		WallLeft = true,
		WallRight = true,
		WallBack = true,
		FrontPillar = true,
		Header = true,
		Trim = true,
		TrimBack = true,
		Sign = true,
		SignGlow = true,
		Barrier = true,
	}
	local function nearStudio(position: any): boolean
		for _, plot in Plots.all() do
			local p = plot.info.cframe:PointToObjectSpace(position)
			local nearX = math.abs(p.X) <= 25 + 6
			local nearZ = math.abs(p.Z) <= 31 + 6
			local inside = math.abs(p.X) < 24 and math.abs(p.Z) < 30
			if nearX and nearZ and not inside then
				return true
			end
		end
		return false
	end
	for _, folder in { Workspace.Map, Workspace.Studios } do
		for _, part in folder:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide and not STRUCTURE[part.Name] and part.Transparency < 1 then
				local top = part.CFrame.Position.Y + part.Size.Y / 2
				if top > 8.5 and nearStudio(part.CFrame.Position) then
					check("no launch pad next to a studio: " .. part:GetFullName(), false, top)
				end
			end
		end
	end

	section("join")
	local alice = Harness.addPlayer(1, "Alice")
	task.wait(0.2)
	local plotA = Plots.get(alice)
	check("alice gets a studio", plotA ~= nil)
	local charA = Harness.spawnCharacter(alice)
	task.wait(0.3)
	local rootA = charA.HumanoidRootPart
	check("guitar", alice.Backpack:FindFirstChild("Guitar") ~= nil)
	check("spawned in studio", Plots.isInside(plotA, rootA.Position))
	check("collision group", rootA.CollisionGroup == "Owner" .. plotA.index, rootA.CollisionGroup)
	check("leaderstats", alice:FindFirstChild("leaderstats") ~= nil)
	check("walk speed", charA.Humanoid.WalkSpeed == Config.WalkSpeed)
	check("sign", plotA.info.signLabel.Text == "ALICE'S STUDIO", plotA.info.signLabel.Text)
	local dataA = PlayerData.get(alice)
	check("starting cash", dataA.cash == Config.StartingCash)

	section("buy")
	local conveyorSong = Workspace.ConveyorSongs:GetChildren()[1]
	local buyTriggered = conveyorSong.Root.PromptAttachment.BuyPrompt.Triggered
	dataA.cash = 0
	buyTriggered:Fire(alice)
	task.wait()
	check("broke buyer refused", #dataA.songs == 0 and conveyorSong.Parent ~= nil)
	check("broke toast", Harness.lastRemote("Toast", alice).args[1].kind == "bad")
	dataA.cash = 1e12
	buyTriggered:Fire(alice)
	task.wait()
	check("bought", #dataA.songs == 1)
	check("left the carpet", gone(conveyorSong))
	check("placed on slot 1", plotA.slots[1].song ~= nil and plotA.slots[1].model ~= nil)
	check("fly-in attribute", plotA.slots[1].model:GetAttribute("FlyFrom") ~= nil)
	check("discovered", dataA.discovered[dataA.songs[1].id] == true)
	buyTriggered:Fire(alice)
	task.wait()
	check("can't buy twice", #dataA.songs == 1)

	section("income")
	dataA.cash = 0
	local streamsBefore = dataA.songs[1].streams
	Plots.tick(10)
	local slotA = plotA.slots[1]
	check("pending", slotA.pending > 0, slotA.pending)
	check("streams grow", dataA.songs[1].streams > streamsBefore)
	check("pad shows cash", slotA.info.padLabel.Text ~= "")
	slotA.info.pad.Touched:Fire(charA.LeftFoot)
	task.wait()
	check("collected", dataA.cash > 0, dataA.cash)
	check("collected remote", Harness.lastRemote("Collected", alice) ~= nil)
	check("lifetime", dataA.lifetime == dataA.cash)

	section("steal")
	local bob = Harness.addPlayer(2, "Bob")
	task.wait(0.2)
	local charB = Harness.spawnCharacter(bob)
	task.wait(0.3)
	local plotB = Plots.get(bob)
	local dataB = PlayerData.get(bob)
	check("bob other studio", plotB and plotB ~= plotA)
	local stolenSong = slotA.song
	charB:PivotTo(plotA.info.spawn)
	slotA.model.Root.PromptAttachment.StealPrompt.Triggered:Fire(bob)
	task.wait()
	check("carrying", bob:GetAttribute("Carrying") == true)
	check("slot marked", slotA.thief == bob)
	check("model hidden", slotA.model.Parent ~= plotA.info.model)
	check("carried model", charB:FindFirstChild("CarriedSong") ~= nil)
	check("owner alerted", Harness.lastRemote("StealAlert", alice).args[1].active == true)
	check("thief slowed", charB.Humanoid.WalkSpeed < Config.WalkSpeed)
	check("no income while carried", (function()
		local pending = slotA.pending
		Plots.tick(5)
		return slotA.pending == pending
	end)())

	charB:PivotTo(plotB.info.spawn)
	RunService.Heartbeat:Fire(0.2)
	task.wait()
	check("stolen", #dataB.songs == 1 and #dataA.songs == 0)
	check("same song", dataB.songs[1] == stolenSong)
	check("steal count", dataB.steals == 1)
	check("speed back", charB.Humanoid.WalkSpeed == Config.WalkSpeed)
	check("carried gone", charB:FindFirstChild("CarriedSong") == nil)
	check("owner told", Harness.lastRemote("StealAlert", alice).args[1].saved == false)

	section("hit makes thief drop")
	local slotB = plotB.slots[stolenSong.slot]
	charA:PivotTo(plotB.info.spawn)
	slotB.model.Root.PromptAttachment.StealPrompt.Triggered:Fire(alice)
	task.wait()
	check("alice carrying", alice:GetAttribute("Carrying") == true)
	local guitar = bob.Backpack:FindFirstChild("Guitar")
	guitar.Parent = charB
	local alicePos = rootA.Position
	-- Bob staat schuin voor Alice en kijkt naar haar. Niet via CFrame.lookAt:
	-- die draait in Lune de Z-as om.
	charB:PivotTo(roblox.CFrame.new(alicePos + roblox.Vector3.new(3, 0, 3)) * roblox.CFrame.Angles(0, math.pi / 4, 0))
	guitar.Activated:Fire()
	task.wait()
	check("knockback", Harness.lastRemote("Knockback", alice) ~= nil)
	check("dropped", alice:GetAttribute("Carrying") == nil)
	check("back home", slotB.thief == nil and slotB.model.Parent == plotB.info.model)
	check("bob keeps it", #dataB.songs == 1 and #dataA.songs == 0)

	section("lock")
	charA:PivotTo(plotB.info.spawn)
	plotB.info.lockPrompt.Triggered:Fire(bob)
	task.wait()
	check("barrier up", plotB.info.barrier.CanCollide == true)
	check("intruder ejected", not Plots.isInside(plotB, rootA.Position))
	slotB.model.Root.PromptAttachment.StealPrompt.Triggered:Fire(alice)
	task.wait()
	check("locked studio safe", alice:GetAttribute("Carrying") == nil)
	check("lock label", string.find(plotB.info.lockLabel.Text, "LOCKED") ~= nil, plotB.info.lockLabel.Text)
	plotB.info.lockPrompt.Triggered:Fire(alice)
	check("only owner locks", Harness.lastRemote("Toast", bob).args[1].text ~= nil)
	plotB.lockedUntil = os.clock() - 1
	Plots.tick(1)
	check("unlocks", plotB.info.barrier.CanCollide == false)

	section("sell")
	local cashB = dataB.cash
	slotB.model.Root.PromptAttachment.SellPrompt.Triggered:Fire(alice)
	task.wait()
	check("only owner sells", #dataB.songs == 1)
	slotB.model.Root.PromptAttachment.SellPrompt.Triggered:Fire(bob)
	task.wait()
	check("sold", #dataB.songs == 0 and dataB.cash > cashB)

	section("actions")
	local action = ReplicatedStorage.Remotes.Action
	local invoke = Harness.invokeHandlers[action]
	check("unknown action", invoke(alice, "Nope") == false)
	check("bad argument", invoke(alice, "BuyUpgrade", {}) == false)
	dataA.cash = 1e9
	check("buy speed", invoke(alice, "BuyUpgrade", "Speed") == true)
	check("speed applied", charA.Humanoid.WalkSpeed == Config.WalkSpeed + 2)
	check("gift not ready", invoke(alice, "ClaimGift", 1) == false)
	PlayerData.session(alice).joinedAt = os.clock() - 3 * 3600
	for i in Config.Gifts do
		check("gift " .. i, invoke(alice, "ClaimGift", i) == true)
	end
	check("gift once", invoke(alice, "ClaimGift", 1) == false)
	check("daily", invoke(alice, "ClaimDaily") == true)
	check("daily once", invoke(alice, "ClaimDaily") == false)
	local songsBeforeRebirth = #dataA.songs
	check("gift songs placed", songsBeforeRebirth >= 3, songsBeforeRebirth)

	dataA.cash = 10
	check("rebirth too poor", invoke(alice, "Rebirth") == false)
	dataA.cash = Economy.rebirthCost(0)
	local ok, message = invoke(alice, "Rebirth")
	check("rebirth", ok == true, message)
	check("rebirth count", dataA.rebirths == 1)
	check("kept best song", #dataA.songs == 1)
	check("more slots", plotA.unlocked == Config.StartSlots + Config.SlotsPerRebirth)
	check("multiplier", PlayerData.multiplier(alice) >= 1.5)

	section("events and dev commands")
	Events.start("ConcertNight")
	check("event on", Events.mutationMult() == 4)
	check("event broadcast", Harness.lastRemote("EventState").args[1].current.id == "ConcertNight")
	Events.stop()
	check("event off", Events.mutationMult() == 1)
	alice.Chatted:Fire("!give mythic")
	task.wait()
	check("dev give", #dataA.songs == 2)
	alice.Chatted:Fire("!drop secret viral")
	task.wait()
	check("dev drop", Harness.lastRemote("Announce").args[1].text:find("SECRET") ~= nil)

	section("boards")
	task.wait(3.2)
	local chartRows = Workspace.Map.LiveChart.ChartBoard:GetChildren()
	local foundRow = false
	for _, gui in chartRows do
		if gui:IsA("SurfaceGui") then
			for _, label in gui:GetChildren() do
				if label:IsA("TextLabel") and string.find(label.Text, "Alice") then
					foundRow = true
				end
			end
		end
	end
	check("live chart lists alice", foundRow)

	section("save and rejoin")
	local songCount = #dataA.songs
	local rebirths = dataA.rebirths
	alice.Parent = nil
	Players.PlayerRemoving:Fire(alice)
	task.wait(0.3)
	check("saved", Harness.store.player_1 ~= nil)
	check("studio freed", plotA.owner == nil and plotA.info.signLabel.Text == "EMPTY STUDIO")
	Harness.store.player_1.lastSeen = os.time() - 3600
	local alice2 = Harness.addPlayer(1, "Alice")
	task.wait(0.3)
	local data2 = PlayerData.get(alice2)
	check("songs restored", data2 and #data2.songs == songCount, data2 and #data2.songs)
	check("rebirths restored", data2 and data2.rebirths == rebirths)
	check("offline popup", Harness.lastRemote("Popup", alice2) ~= nil)
	check("songs on pedestals", Plots.get(alice2) and Plots.get(alice2).slots[1].model ~= nil)

	-- De client ----------------------------------------------------------------

	section("client")
	Harness.setLocalPlayer(alice2)
	local charA2 = Harness.spawnCharacter(alice2)
	task.wait(0.3)
	local client = Harness.context("client")
	local ClientScript = dm:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")
	client.run(ClientScript)
	task.wait(0.5)
	local gui = alice2.PlayerGui:FindFirstChild("StealASongUI")
	check("ui built", gui ~= nil)
	PlayerData.push(alice2)
	task.wait()
	for _ = 1, 30 do
		RunService.RenderStepped:Fire(1 / 30)
	end
	task.wait()
	local cashLabel = gui.Root.CashPanel:FindFirstChildOfClass("TextLabel")
	check("cash shown", cashLabel and string.sub(cashLabel.Text, 1, 1) == "$", cashLabel and cashLabel.Text)

	local Windows = client.require(ClientScript.Windows)
	for _, name in { "Upgrades", "Rebirth", "Index", "Gifts", "Daily", "Store", "Offline" } do
		local okOpen, err = pcall(function()
			Windows.open(name)
			Windows.tick()
		end)
		check("window " .. name, okOpen, err)
		Windows.close()
	end

	Remotes.toast(alice2, "Hello", "good")
	Remotes.announce("Big news", { 255, 200, 0 }, true)
	Remotes.fire("Carry", alice2, { active = true, song = "Test", plotIndex = Plots.get(alice2).index })
	Remotes.fire("StealAlert", alice2, { active = true, song = "Test", thief = "Bob" })
	Remotes.fire("Collected", alice2, { amount = 123, position = roblox.Vector3.new(0, 1, 0) })
	Remotes.fire("Knockback", alice2, { velocity = roblox.Vector3.new(0, 30, 0), stun = 0.1 })
	for _ = 1, 10 do
		RunService.RenderStepped:Fire(1 / 30)
	end
	task.wait(0.2)
	check("carry beam", charA2.HumanoidRootPart:FindFirstChildOfClass("Attachment") ~= nil)
	Remotes.fire("Carry", alice2, { active = false })
	Remotes.fire("StealAlert", alice2, { active = false })

	-- Een knop in de interface indrukken gaat via de echte RemoteFunction
	local speedBefore = PlayerData.get(alice2).upgrades.Speed or 0
	PlayerData.get(alice2).cash = 1e12
	Windows.open("Upgrades")
	local upgradesPage = gui.Root.Window.Content.Upgrades
	local buyButton
	for _, d in upgradesPage:GetDescendants() do
		if d:IsA("TextButton") and buyButton == nil then
			buyButton = d
		end
	end
	buyButton.Activated:Fire()
	task.wait()
	check("ui buys upgrade", (PlayerData.get(alice2).upgrades.Speed or 0) == speedBefore + 1)

	-- Draaiende songs krijgen een nieuwe positie van de client
	local spinModel = Plots.get(alice2).slots[1].model
	local pivotBefore = spinModel:GetPivot()
	RunService.RenderStepped:Fire(1 / 30)
	check("song spins", spinModel:GetPivot() ~= pivotBefore)

	check("no warnings", #Harness.warnings == 0, Harness.warnings[1])
end

local ok, err = pcall(main)
if not ok then
	failed += 1
	print("  CRASH " .. tostring(err))
end

print(string.format("\n%d passed, %d failed", passed, failed))
process.exit(if failed > 0 then 1 else 0)
