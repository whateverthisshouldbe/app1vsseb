--!strict
-- Maakt en vindt de RemoteEvents. Server maakt ze, client wacht erop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local EVENT_NAMES = {
	"StateChanged", -- server -> client: hele spelerstatus
	"Notify",       -- server -> client: toastje (tekst, kleur)
	"BuyUpgrade",   -- client -> server: upgrade-key
	"Rebirth",      -- client -> server
	"CustomerChanged", -- server -> alle clients: huidige klant
}

local folder: Folder

local function ensureFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild("PenNet")
		if existing then
			folder = existing :: Folder
		else
			local f = Instance.new("Folder")
			f.Name = "PenNet"
			f.Parent = ReplicatedStorage
			folder = f
		end
		for _, name in EVENT_NAMES do
			if not folder:FindFirstChild(name) then
				local ev = Instance.new("RemoteEvent")
				ev.Name = name
				ev.Parent = folder
			end
		end
	else
		folder = ReplicatedStorage:WaitForChild("PenNet") :: Folder
	end
	return folder
end

function Net.event(name: string): RemoteEvent
	local f = ensureFolder()
	if RunService:IsServer() then
		return f:FindFirstChild(name) :: RemoteEvent
	end
	return f:WaitForChild(name) :: RemoteEvent
end

function Net.init()
	ensureFolder()
end

return Net
