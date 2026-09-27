--!strict
-- De laatste status van de server, plus een manier om acties te vragen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = {}

Store.state = nil :: any
Store.receivedAt = 0
Store.event = nil :: any

local listeners: { (any) -> () } = {}
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("Action") :: RemoteFunction

function Store.set(state: any)
	Store.state = state
	Store.receivedAt = os.clock()
	for _, listener in listeners do
		task.spawn(listener, state)
	end
end

function Store.onChange(listener: (any) -> ())
	table.insert(listeners, listener)
	if Store.state then
		task.spawn(listener, Store.state)
	end
end

-- Minuten speeltijd deze sessie, doorgeteld sinds de laatste status
function Store.playMinutes(): number
	local state = Store.state
	if not state then
		return 0
	end
	return (state.playMinutes or 0) + (os.clock() - Store.receivedAt) / 60
end

function Store.call(name: string, ...: any): (boolean, string?)
	local ok, result, message = pcall(action.InvokeServer, action, name, ...)
	if not ok then
		return false, "Connection problem, try again"
	end
	return result == true, message
end

function Store.remote(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

return Store
