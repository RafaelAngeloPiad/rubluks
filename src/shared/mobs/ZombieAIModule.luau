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
local UPDATE_RATE = 0.2      -- How often to check for targets

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
	variantName = variantName or "Zombie_Sand"
	
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
	
	-- Setup ragdoll disable
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false
		end
	end)
	
	-- Main AI loop - simple follow on radius detect
	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			-- Check if zombie still exists and is alive
			if not zombie or not zombie.Parent or zombie.Parent ~= workspace or not humanoid or humanoid.Health <= 0 then
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
				-- Follow the target
				humanoid:MoveTo(target.Position)
			else
				-- No target found, stop moving
				humanoid:MoveTo(position)
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

