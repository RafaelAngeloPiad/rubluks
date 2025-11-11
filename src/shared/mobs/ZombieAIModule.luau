-- Zombie AI Module
-- Simple: Just follows players within detection radius

local CollectionService = game:GetService("CollectionService")

-- Import global exclusions
local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfig = require(script.Parent.MobStatsConfig)

-- Try to require MobStatsDisplay module
local MobStatsDisplay = nil
local success, displayModule = pcall(function()
	return require(game.ReplicatedStorage.MobStatsDisplay)
end)
if success then
	MobStatsDisplay = displayModule
end

-- === CONFIG ===
local DETECTION_RANGE = 50  -- Radius to detect players
local UPDATE_RATE = 0.2     -- How often to check for targets
local ATTACK_RANGE = 6      -- Distance to trigger attack hitbox
local ATTACK_COOLDOWN = 1.5 -- Delay between attacks (seconds)
local ATTACK_ANIMATION_ID = "rbxassetid://120608701056761" -- Placeholder attack animation; replace with final asset
local RUN_ANIMATION_ID = "rbxassetid://3489173414"
local IDLE_ANIMATION_IDS = {
	"rbxassetid://3489171152",
	"rbxassetid://3489171152"
}
local MOVE_SPEED_THRESHOLD = 1.0

-- === HELPERS ===
local function HasAnyExcludedTag(model)
	return HitboxExclusions.hasExcludedTag(model)
end

local function FindNearestTarget(origin)
	local nearest, nearestDist = nil, DETECTION_RANGE
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and not HasAnyExcludedTag(model) then
			local root = model:FindFirstChild("HumanoidRootPart")
			local hum = model:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = (root.Position - origin).Magnitude
				if dist < nearestDist then
					nearest = root
					nearestDist = dist
				end
			end
		end
	end
	return nearest
end

-- === ZOMBIE INITIALIZATION ===
local function initializeZombie(zombie, variantName)
    -- Default variant if not provided
    variantName = variantName or zombie:GetAttribute("Variant") or "Zombie_Sand"

    -- Persist the resolved variant on the zombie for reference/debugging
    zombie:SetAttribute("Variant", variantName)
	
	-- Apply stats to the zombie
	local statsApplied = MobStatsConfig.applyStats(zombie, variantName)
	if not statsApplied then
		warn("Zombie: Failed to apply stats for variant:", variantName)
	end
	
	local humanoid = zombie:WaitForChild("Humanoid")
	local root = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart
	
	if not root then
		warn("Zombie missing HumanoidRootPart:", zombie.Name)
		return
	end
	
	-- Add exclusion tag so zombies don't damage each other
	CollectionService:AddTag(zombie, "zombie_entity")
	
	-- Create floating stats display GUI
	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(zombie)
	end
	
	-- Setup animations
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local runTrack = nil
	local idleTracks = {}
	local currentIdleTrack = nil
	local attackTrack = nil
	local attacking = false

	local function loadAnimation(animationId)
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		return animator:LoadAnimation(animation)
	end

	local successRun, resultRun = pcall(function()
		local track = loadAnimation(RUN_ANIMATION_ID)
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Movement
		return track
	end)
	if successRun then
		runTrack = resultRun
	end

	for _, idleId in ipairs(IDLE_ANIMATION_IDS) do
		local successIdle, track = pcall(function()
			local idleTrack = loadAnimation(idleId)
			idleTrack.Looped = true
			idleTrack.Priority = Enum.AnimationPriority.Core
			return idleTrack
		end)
		if successIdle and track then
			table.insert(idleTracks, track)
		end
	end

	local successAttack, resultAttack = pcall(function()
		local track = loadAnimation(ATTACK_ANIMATION_ID)
		track.Looped = false
		track.Priority = Enum.AnimationPriority.Action
		return track
	end)
	if successAttack then
		attackTrack = resultAttack
	end

	local function stopRun()
		if runTrack and runTrack.IsPlaying then
			pcall(function()
				runTrack:Stop(0.2)
			end)
		end
	end

	local function stopAllIdle()
		for _, track in ipairs(idleTracks) do
			if track.IsPlaying then
				pcall(function()
					track:Stop(0.2)
				end)
			end
		end
		currentIdleTrack = nil
	end

	local function playRun()
		if attacking or not runTrack then
			return
		end
		stopAllIdle()
		if not runTrack.IsPlaying then
			pcall(function()
				runTrack:Play(0.1)
			end)
		end
	end

	local function playIdle()
		if attacking or #idleTracks == 0 then
			return
		end
		stopRun()
		if currentIdleTrack and currentIdleTrack.IsPlaying then
			return
		end
		local nextTrack = idleTracks[math.random(1, #idleTracks)]
		currentIdleTrack = nextTrack
		pcall(function()
			nextTrack:Play(0.2)
		end)
	end

	local function onAttackFinished()
		attacking = false
		playIdle()
	end

	if attackTrack then
		attackTrack.Stopped:Connect(onAttackFinished)
	end

	local function playAttack()
		if attacking then
			return
		end
		attacking = true
		stopRun()
		stopAllIdle()
		if attackTrack then
			pcall(function()
				attackTrack:Play(0.1)
			end)
		else
			task.delay(0.4, onAttackFinished)
		end
		if _G.createStaticHitbox and root then
			local damage = zombie:GetAttribute("Damage") or 15
			local stats = MobStatsConfig.getStats(variantName)
			local statusAilment = stats and stats.StatusAilment or nil
			task.delay(0.2, function()
				if not zombie or not zombie.Parent or not humanoid or humanoid.Health <= 0 then
					return
				end
				local currentRoot = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart
				if not currentRoot then
					return
				end
				local hitboxConfig = {
					attachTo = currentRoot,
					offset = CFrame.new(0, 0, -3),
					size = Vector3.new(6, 6, 6),
					damage = damage,
					character = zombie,
					name = "ZombieBite",
					showVisual = false,
					visualColor = Color3.new(0, 0.6, 0),
					delay = 0,
					visualDuration = 0.5
				}
				if statusAilment then
					hitboxConfig.statusAilment = statusAilment
				end
				_G.createStaticHitbox(hitboxConfig)
			end)
		end
	end

	playIdle()

	-- Setup ragdoll disable
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false
		end
	end)
	
	-- Main AI loop - simple follow on radius detect
	local lastAttackTime = 0
	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			-- Check if zombie still exists and is alive
			if not zombie or not zombie.Parent or not zombie:IsDescendantOf(workspace) or not humanoid or humanoid.Health <= 0 then
				break
			end
			
			if not root then 
				root = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart 
			end
			if not root then 
				continue 
			end
			
			local position = root.Position
			
			-- Find nearest target within detection radius
			local target = FindNearestTarget(position)
			
			if target then
				local targetDist = (target.Position - position).Magnitude
				if targetDist <= ATTACK_RANGE then
					humanoid:MoveTo(position)
					local now = tick()
					if not attacking and now - lastAttackTime >= ATTACK_COOLDOWN then
						lastAttackTime = now
						playAttack()
					end
				else
					if not attacking then
						humanoid:MoveTo(target.Position)
					end
				end
			else
				if not attacking then
					humanoid:MoveTo(position)
				end
			end
			local horizontalSpeed = (root.Velocity * Vector3.new(1, 0, 1)).Magnitude
			if not attacking then
				if horizontalSpeed > MOVE_SPEED_THRESHOLD then
					playRun()
				else
					playIdle()
				end
			end
		end
	end)
end

-- === MODULE EXPORTS ===
local ZombieAIModule = {}

function ZombieAIModule.initializeZombie(model, variantName)
	initializeZombie(model, variantName)
end

function ZombieAIModule.isInitialized(model)
	return false
end

return ZombieAIModule

