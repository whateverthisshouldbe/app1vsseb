-- Walk styles for players (by suit) and customers (by personality), plus
-- relaying jump flips so everyone sees them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(ReplicatedStorage.Shared.Animations)
local DataService = require(script.Parent.DataService)

local Remotes = ReplicatedStorage.Remotes

local AnimationService = {}

local appliedPack = {} -- [Player] = pack name currently on their character

local function setAnim(animate, folderName, animName, assetId)
	local folder = animate:FindFirstChild(folderName)
	local anim = folder and folder:FindFirstChild(animName)
	if anim and anim:IsA("Animation") then
		anim.AnimationId = Animations.id(assetId)
	end
end

-- Swap the ids inside the character's default Animate script. It reloads
-- an animation as soon as its id changes.
function AnimationService.applyToCharacter(character, packName)
	local pack = Animations.Packs[packName]
	local animate = character and character:WaitForChild("Animate", 5)
	if not pack or not animate then
		return
	end
	setAnim(animate, "walk", "WalkAnim", pack.walk)
	setAnim(animate, "run", "RunAnim", pack.run)
	setAnim(animate, "jump", "JumpAnim", pack.jump)
	setAnim(animate, "fall", "FallAnim", pack.fall)
	setAnim(animate, "climb", "ClimbAnim", pack.climb)
	setAnim(animate, "idle", "Animation1", pack.idle[1])
	setAnim(animate, "idle", "Animation2", pack.idle[2])
end

function AnimationService.refresh(player)
	appliedPack[player] = nil
	AnimationService.refreshPlayer(player)
end

function AnimationService.refreshPlayer(player)
	local profile = DataService.get(player)
	local packName = profile and Animations.BySuit[profile.suit]
	if packName and player.Character and appliedPack[player] ~= packName then
		appliedPack[player] = packName
		AnimationService.applyToCharacter(player.Character, packName)
	end
end

-- Customers are server-side, so their Animate LocalScript never runs.
-- Drive idle/walk/run from the server instead (it replicates to everyone).
function AnimationService.animateNpc(humanoid, packName)
	local pack = Animations.Packs[packName] or Animations.Packs.Rthro
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local model = humanoid.Parent
	local animate = model and model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end

	local function load(assetId, priority)
		local animation = Instance.new("Animation")
		animation.AnimationId = Animations.id(assetId)
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok then
			return nil
		end
		track.Looped = true
		track.Priority = priority
		return track
	end

	local idle = load(pack.idle[1], Enum.AnimationPriority.Idle)
	local walk = load(pack.walk, Enum.AnimationPriority.Movement)
	local run = load(pack.run, Enum.AnimationPriority.Movement)
	if not idle or not walk then
		return
	end
	idle:Play()

	local current = idle
	local function switch(track, speed)
		if current ~= track then
			current:Stop(0.25)
			track:Play(0.25)
			current = track
		end
		if speed and track ~= idle then
			track:AdjustSpeed(math.clamp(speed / (track == run and 18 or 9), 0.6, 1.6))
		end
	end
	humanoid.Running:Connect(function(speed)
		if speed > 13 and run then
			switch(run, speed)
		elseif speed > 0.5 then
			switch(walk, speed)
		else
			switch(idle)
		end
	end)
end

function AnimationService.start()
	local function onPlayer(player)
		player.CharacterAdded:Connect(function()
			appliedPack[player] = nil
			-- Let the engine apply the avatar's own animations first, then ours.
			task.wait(1)
			AnimationService.refreshPlayer(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		appliedPack[player] = nil
	end)
	-- Buying a suit (or rebirthing out of one) changes your walk.
	DataService.onChanged(function(player)
		AnimationService.refreshPlayer(player)
	end)

	-- Flips: the jumper animates locally; everyone else gets told.
	local lastFlip = {}
	Remotes.Flip.OnServerEvent:Connect(function(player, kind)
		if type(kind) ~= "string" or #kind > 12 then
			return
		end
		local now = os.clock()
		if (lastFlip[player] or 0) > now - 0.4 then
			return
		end
		lastFlip[player] = now
		for _, other in Players:GetPlayers() do
			if other ~= player then
				Remotes.Flip:FireClient(other, player, kind)
			end
		end
	end)
end

return AnimationService
