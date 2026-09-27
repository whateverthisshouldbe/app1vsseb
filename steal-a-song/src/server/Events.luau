--!strict
-- Server-events die om de paar minuten beginnen: meer mutaties, snellere
-- drops, meer geluk of dubbel inkomen. Iedereen ziet een aftelklok, dus er
-- is altijd een reden om nog even te blijven.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(script.Parent.Remotes)

local Events = {}

local DAY_CLOCK = 15.5
local NIGHT_CLOCK = 0.2

local current: any = nil
local endsAt = 0
local nextAt = 0
local rng = Random.new()

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Schuift de klok altijd vooruit, zodat de zon niet achteruit draait
local function shiftClock(target: number, seconds: number)
	task.spawn(function()
		local from = Lighting.ClockTime
		local delta = (target - from) % 24
		local elapsed = 0
		while elapsed < seconds do
			elapsed += RunService.Heartbeat:Wait()
			local alpha = math.min(1, elapsed / seconds)
			Lighting.ClockTime = (from + delta * alpha) % 24
		end
	end)
end

function Events.state(): any
	local info = nil
	if current then
		info = {
			id = current.id,
			name = current.name,
			icon = current.icon,
			desc = current.desc,
			color = current.color,
			endsAt = endsAt,
		}
	end
	return { current = info, nextAt = nextAt }
end

local function broadcast()
	Remotes.fireAll("EventState", Events.state())
end

function Events.start(id: string?)
	if current then
		Events.stop()
	end
	local def = Config.Events[rng:NextInteger(1, #Config.Events)]
	if id then
		for _, candidate in Config.Events do
			if string.lower(candidate.id) == string.lower(id) then
				def = candidate
			end
		end
	end
	current = def
	endsAt = now() + Config.EventDuration
	if def.night then
		shiftClock(NIGHT_CLOCK, 5)
	end
	broadcast()
	Remotes.announce(def.icon .. " " .. string.upper(def.name) .. "! " .. def.desc, def.color, true)
end

function Events.stop()
	if not current then
		return
	end
	local ended = current
	current = nil
	if ended.night then
		shiftClock(DAY_CLOCK, 6)
	end
	nextAt = now() + rng:NextNumber(Config.EventMinGap, Config.EventMaxGap)
	broadcast()
	Remotes.announce(ended.icon .. " " .. ended.name .. " is over. Next event soon!", { 200, 200, 220 }, false)
end

function Events.current(): any
	return current
end

function Events.luck(): number
	return if current and current.luck then current.luck else 1
end

function Events.mutationMult(): number
	return if current and current.mutationMult then current.mutationMult else 1
end

function Events.spawnMult(): number
	return if current and current.spawnMult then current.spawnMult else 1
end

function Events.incomeMult(): number
	return if current and current.incomeMult then current.incomeMult else 1
end

function Events.init()
	nextAt = now() + rng:NextNumber(Config.EventMinGap, Config.EventMaxGap)
	task.spawn(function()
		while true do
			task.wait(1)
			local t = now()
			if current and t >= endsAt then
				Events.stop()
			elseif not current and t >= nextAt then
				Events.start()
			end
		end
	end)
end

return Events
