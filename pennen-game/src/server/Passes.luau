--!strict
-- Gamepasses. Zolang een ID nog 0 is in Config, is die pass simpelweg uit.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("Config"))

local Passes = {}

local cache: { [Player]: { [string]: boolean } } = {}

local function check(player: Player, key: string): boolean
	local pass = Config.Gamepasses[key]
	if not pass or pass.id == 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
	end)
	if not ok then
		warn("[Pen] Gamepass-check mislukt: " .. tostring(owns))
		return false
	end
	return owns == true
end

function Passes.refresh(player: Player)
	local owned = {}
	for key in Config.Gamepasses do
		owned[key] = check(player, key)
	end
	cache[player] = owned
end

function Passes.owns(player: Player, key: string): boolean
	local owned = cache[player]
	return owned ~= nil and owned[key] == true
end

function Passes.owned(player: Player): { [string]: boolean }
	return cache[player] or {}
end

function Passes.prompt(player: Player, key: string)
	local pass = Config.Gamepasses[key]
	if not pass or pass.id == 0 then
		return
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	end)
	if not ok then
		warn("[Pen] Kon gamepass niet tonen: " .. tostring(err))
	end
end

function Passes.start(onChanged: (Player) -> ())
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _passId, purchased)
		if purchased then
			Passes.refresh(player)
			onChanged(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		cache[player] = nil
	end)
end

return Passes
