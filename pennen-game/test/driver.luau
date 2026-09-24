-- Speelt de game na met de nagemaakte API hierboven: een speler loopt naar de
-- pers, maakt pennen, pitcht, koopt upgrades, rebirtht, en wisselt een code in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = PEN.Config
local net = ReplicatedStorage:FindFirstChild("PenNet")

local failures = 0
local checks = 0

local function check(label, condition, extra)
	checks += 1
	if condition then
		print(string.format("  ok   %s", label))
	else
		failures += 1
		print(string.format("  FOUT %s %s", label, extra and ("(" .. tostring(extra) .. ")") or ""))
	end
end

local function remote(name)
	local ev = net:FindFirstChild(name)
	assert(ev, "remote ontbreekt: " .. name)
	return ev
end

local function lastPayload(name)
	local data = rawget(remote(name), "_data")
	return data._last and data._last[1]
end

-- ----------------------------------------------------------- nepklok ------
-- FAKE_CLOCK komt uit de stub en is wat os.clock() teruggeeft.
local function advance(seconds, steps)
	local slice = seconds / steps
	for _ = 1, steps do
		FAKE_CLOCK += slice
		RunService.Heartbeat:Fire(slice)
	end
end

-- ------------------------------------------------------------- speler -----
local player = Instance.new("Player")
player.Name = "Testspeler"
player.UserId = 42

local character = Instance.new("Model")
character.Name = "Testspeler"
local humanoid = Instance.new("Humanoid")
humanoid.Parent = character
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Parent = character
player.Character = character

table.insert(rawget(Players, "_data")._list, player)
Players.PlayerAdded:Fire(player)

local profile = PEN.Data.get(player)
check("profiel aangemaakt", profile ~= nil)
check("statusbericht naar client gestuurd", lastPayload("StateChanged") ~= nil)

local world = workspace:FindFirstChild("PenWorld")
check("wereld gebouwd", world ~= nil)

local function standOn(padName)
	local pad = world:FindFirstChild(padName, true)
	assert(pad, "plaat niet gevonden: " .. padName)
	root.Position = pad.CFrame.Position + Vector3.new(0, 3, 0)
end

local function standAway()
	root.Position = Vector3.new(9999, 3, 9999)
end

-- ------------------------------------------------------- pennen maken -----
standOn("Press_kraam")
advance(30, 300)
local capacity = math.floor(Config.getUpgrade("capacity").value(1))
check("pennen gemaakt tot de tas vol was", profile.pens == capacity,
	string.format("pens=%d capaciteit=%d", profile.pens, capacity))
check("pennen hebben de waarde van de kraam", math.abs(profile.penValue - Config.Stations[1].pen.value) < 0.001,
	profile.penValue)

-- de gesloten fabriek mag niets opleveren
profile.pens = 0
profile.penValue = 0
standOn("Press_fabriek")
advance(10, 100)
check("gesloten zaak maakt geen pennen", profile.pens == 0, profile.pens)

-- ------------------------------------------------------------- pitchen ----
standOn("Press_kraam")
advance(30, 300)
local pensBefore = profile.pens
standOn("Sell_kraam")
advance(1, 10)

local pitch = lastPayload("PitchStart")
check("pitch gestart aan de toonbank", pitch ~= nil)
check("pitch heeft drie opties", pitch and #pitch.options == Config.Pitch.optionCount, pitch and #pitch.options)

remote("PitchAnswer").OnServerEvent:Fire(player, pitch.id, 1)
local result = lastPayload("PitchEnd")
check("pitch afgerond", result ~= nil and result.ok == true)
check("tas is leeg na verkoop", profile.pens == 0, profile.pens)
check("geld verdiend", profile.cash > 0, profile.cash)
check("verkochte pennen geteld", profile.totalSold == pensBefore, profile.totalSold)

-- tweede pitch: een fout antwoord levert minder op dan een perfect antwoord
local function pitchOnce(wantPerfect)
	standOn("Press_kraam")
	advance(30, 300)
	standOn("Sell_kraam")
	advance(1, 10)
	local info = lastPayload("PitchStart")
	assert(info, "geen pitch gestart")
	local chosen = 1
	for index, optionText in info.options do
		local isGood = false
		for _, arg in Config.PitchArguments do
			if arg.text == optionText and table.find(arg.good, nil) == nil then
				isGood = table.find(arg.good, PEN.Customers.get("kraam").typeKey) ~= nil
			end
		end
		if isGood == wantPerfect then
			chosen = index
			break
		end
	end
	local before = profile.cash
	remote("PitchAnswer").OnServerEvent:Fire(player, info.id, chosen)
	return profile.cash - before, lastPayload("PitchEnd")
end

local _, perfectResult = pitchOnce(true)
check("pitch geeft een uitslag met multiplier", perfectResult ~= nil and perfectResult.multiplier > 0,
	perfectResult and perfectResult.multiplier)

-- ------------------------------------------------------------ upgrades ----
standAway()
profile.cash = 100000
local levelBefore = profile.upgrades.capacity
remote("BuyUpgrade").OnServerEvent:Fire(player, "capacity")
check("upgrade gekocht via de knop", profile.upgrades.capacity == levelBefore + 1, profile.upgrades.capacity)
check("upgrade kost geld", profile.cash < 100000, profile.cash)

profile.cash = 100000
standOn("UpgradePad_speed")
advance(3, 30)
check("upgrade gekocht door op de plaat te staan", profile.upgrades.speed > 1, profile.upgrades.speed)

-- ------------------------------------------------------------- rebirth ----
standAway()
profile.cash = Config.rebirthPrice(0) + 10
remote("Rebirth").OnServerEvent:Fire(player)
check("rebirth uitgevoerd", profile.rebirths == 1, profile.rebirths)
check("geld gaat op 0 na rebirth", profile.cash == 0, profile.cash)
check("upgrades resetten na rebirth", profile.upgrades.capacity == 1 and profile.upgrades.speed == 1,
	profile.upgrades.capacity)

profile.cash = 100000
standOn("Press_winkel")
advance(20, 200)
check("nieuwe zaak maakt duurdere pennen",
	math.abs(profile.penValue - Config.Stations[2].pen.value) < 0.001, profile.penValue)

local state = lastPayload("StateChanged")
check("kraam blijft passief doorlopen", state ~= nil and state.passivePerSecond > 0,
	state and state.passivePerSecond)

-- rebirth via de plaat (2 seconden blijven staan)
profile.cash = Config.rebirthPrice(1) + 10
standOn("RebirthPad")
advance(3, 30)
check("rebirth via de plaat", profile.rebirths == 2, profile.rebirths)
standAway()

-- -------------------------------------------------------------- reizen ----
standAway()
remote("Travel").OnServerEvent:Fire(player, "winkel")
local winkelPad = world:FindFirstChild("Press_winkel", true)
local afstand = (root.Position - winkelPad.CFrame.Position).Magnitude
check("reizen brengt je bij de geopende zaak", afstand < 12, afstand)

remote("Travel").OnServerEvent:Fire(player, "jacht")
local naLocked = (root.Position - winkelPad.CFrame.Position).Magnitude
check("reizen naar een gesloten zaak doet niets", naLocked == afstand, naLocked)

-- --------------------------------------------------- codes, pets, daily ---
remote("RedeemCode").OnServerEvent:Fire(player, " penstart ")
check("code ingewisseld (ook met spaties en kleine letters)", profile.redeemed.PENSTART == true)
local cashAfterCode = profile.cash
remote("RedeemCode").OnServerEvent:Fire(player, "PENSTART")
check("dezelfde code werkt niet twee keer", profile.cash == cashAfterCode, profile.cash)
remote("RedeemCode").OnServerEvent:Fire(player, "BESTAATNIET")
check("onbekende code wordt geweigerd", profile.cash == cashAfterCode, profile.cash)

profile.cash = 5000
remote("BuyPet").OnServerEvent:Fire(player, "clip")
check("mascotte gekocht", profile.pets.clip == true)
check("mascotte gelijk gedragen", profile.equippedPet == "clip", profile.equippedPet)
remote("EquipPet").OnServerEvent:Fire(player, "")
check("mascotte afgedaan", profile.equippedPet == nil, profile.equippedPet)

profile.cash = 0
remote("ClaimDaily").OnServerEvent:Fire(player)
check("dagbeloning uitbetaald", profile.cash > 0, profile.cash)
check("dagstreak op 1", profile.dailyStreak == 1, profile.dailyStreak)
local cashAfterDaily = profile.cash
remote("ClaimDaily").OnServerEvent:Fire(player)
check("dagbeloning niet twee keer op een dag", profile.cash == cashAfterDaily, profile.cash)

-- ------------------------------------------------------- opslaan/laden ----
profile.cash = 123456
profile.pens = 3
local saved = PEN.Data.save(player)
check("profiel opgeslagen", saved == true)

Players.PlayerRemoving:Fire(player)
check("profiel opgeruimd bij vertrek", PEN.Data.get(player) == nil)

Players.PlayerAdded:Fire(player)
local reloaded = PEN.Data.get(player)
check("geld terug na opnieuw joinen", reloaded ~= nil and math.floor(reloaded.cash) == 123456,
	reloaded and reloaded.cash)
check("rebirths bewaard", reloaded ~= nil and reloaded.rebirths == 2, reloaded and reloaded.rebirths)
check("mascotte bewaard", reloaded ~= nil and reloaded.pets.clip == true)

-- ------------------------------------------------------------- scorebord --
local boardBody = world:FindFirstChild("Board_cash", true)
local screenGui = boardBody and boardBody:FindFirstChild("Screen")
local body = screenGui and screenGui:FindFirstChild("Body")
check("scorebord heeft tekst", body ~= nil and body.Text ~= nil and body.Text ~= "")

print(string.format("\n%d van de %d controles goed", checks - failures, checks))
if failures > 0 then
	error(string.format("%d controles mislukt", failures), 0)
end
