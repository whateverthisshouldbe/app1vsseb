--!strict
-- Maakt de RemoteEvents aan en verdeelt de acties die de client mag vragen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = {}

local EVENT_NAMES = {
	"State", -- volledige spelerstatus
	"Toast", -- korte melding
	"Announce", -- grote melding voor iedereen
	"Collected", -- geld opgehaald bij een pedestal
	"Knockback", -- geraakt door een gitaar
	"StealAlert", -- iemand steelt jouw song
	"Carry", -- jij draagt een gestolen song
	"EventState", -- huidig server-event
	"Popup", -- offline-inkomen en andere vensters
}

local events: { [string]: RemoteEvent } = {}
local handlers: { [string]: (Player, ...any) -> (any, any) } = {}

function Remotes.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENT_NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		events[name] = remote
	end

	local action = Instance.new("RemoteFunction")
	action.Name = "Action"
	action.OnServerInvoke = function(player: Player, name: any, ...: any)
		if type(name) ~= "string" then
			return false, "Unknown action"
		end
		local handler = handlers[name]
		if not handler then
			return false, "Unknown action"
		end
		local ok, result, message = pcall(handler, player, ...)
		if not ok then
			warn("[StealASong] action " .. name .. " failed: " .. tostring(result))
			return false, "Something went wrong"
		end
		return result, message
	end
	action.Parent = folder

	folder.Parent = ReplicatedStorage
end

function Remotes.handle(name: string, handler: (Player, ...any) -> (any, any))
	handlers[name] = handler
end

function Remotes.fire(name: string, player: Player, ...: any)
	if player.Parent == Players then
		events[name]:FireClient(player, ...)
	end
end

function Remotes.fireAll(name: string, ...: any)
	events[name]:FireAllClients(...)
end

-- kind: "good" | "bad" | "info" | "buy" | "rare"
function Remotes.toast(player: Player, text: string, kind: string?)
	Remotes.fire("Toast", player, { text = text, kind = kind or "info" })
end

function Remotes.announce(text: string, color: { number }?, big: boolean?)
	Remotes.fireAll("Announce", { text = text, color = color, big = big == true })
end

return Remotes
