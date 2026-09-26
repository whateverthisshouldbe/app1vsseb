-- Client-side copy of the player's profile, kept fresh by DataSync.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = {
	data = nil, -- { profile, income, ipoMult, nextIpoMult }
	inPitch = false,
}

local changed = Instance.new("BindableEvent")
Store.Changed = changed.Event

local dataSync = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DataSync")
dataSync.OnClientEvent:Connect(function(data)
	local previous = Store.data
	Store.data = data
	changed:Fire(data, previous)
end)
dataSync:FireServer()

function Store.profile()
	return Store.data and Store.data.profile
end

return Store
