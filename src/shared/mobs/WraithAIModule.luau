-- Wraith AI Module
-- Barebones: Just detects and follows

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
local FOLLOW_RANGE = 100
local MAX_RADIUS = 40
local RETURN_RADIUS = 60
local RETURN_WAIT = 2
local UPDATE_RATE = 0.5

-- === HELPERS ===
local function HasAnyExcludedTag(model)
	return HitboxExclusions.hasExcludedTag(model)
end

-- === WRAITH INITIALIZATION ===
local function initializeWraith(wraith, variantName)
	-- Default variant if not provided
	variantName = variantName or "Wraith_Sand"
	
	-- Apply stats to the wraith
	local statsApplied = MobStatsConfig.applyStats(wraith, variantName)
	if not statsApplied then
		warn("Wraith: Failed to apply stats for variant:", variantName)
	end
	
	local humanoid = wraith:WaitForChild("Humanoid")
	local root = wraith:FindFirstChild("HumanoidRootPart") or wraith.PrimaryPart
	
	if not root then
		warn("Wraith missing HumanoidRootPart:", wraith.Name)
		return
	end
	
	-- Ensure root is set as PrimaryPart
	wraith.PrimaryPart = root
	
	-- Create floating stats display GUI
	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(wraith)
	end
	
	-- Internal variables
	local spawnPosition = wraith:GetPivot().Position
	local timeSinceTarget = 0
	local returningHome = false
	
	-- Main loop (exactly like SimpleMeleeMob)
	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			-- Safety check
			if not wraith or not wraith.Parent or not humanoid or not humanoid.Parent or not root or not root.Parent then
				break
			end
			
			if humanoid.Health <= 0 then break end
			
			local position = root.Position
			local distFromSpawn = (position - spawnPosition).Magnitude
			
			-- Return logic
			if returningHome then
				if distFromSpawn <= MAX_RADIUS * 0.8 then
					returningHome = false
				else
					humanoid:MoveTo(spawnPosition)
				end
			else
				-- Find nearest player within FOLLOW_RANGE
				local nearest = nil
				local nearestDist = FOLLOW_RANGE
				
				for _, player in pairs(game.Players:GetPlayers()) do
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
						if dist < nearestDist then
							nearestDist = dist
							nearest = player.Character.HumanoidRootPart
						end
					end
				end
				
				-- Follow or return home
				if nearest then
					local dist = (nearest.Position - position).Magnitude
					local targetDistFromSpawn = (nearest.Position - spawnPosition).Magnitude
					
					if targetDistFromSpawn <= RETURN_RADIUS then
						-- Target is within return radius, follow
						humanoid:MoveTo(nearest.Position)
						timeSinceTarget = 0
					else
						-- Target too far from spawn, return home
						returningHome = true
						humanoid:MoveTo(spawnPosition)
					end
				else
					-- No target found
					timeSinceTarget += UPDATE_RATE
					if timeSinceTarget >= RETURN_WAIT then
						returningHome = true
						humanoid:MoveTo(spawnPosition)
						timeSinceTarget = 0
					end
				end
			end
		end
	end)
end

-- === MODULE EXPORTS ===
local WraithAIModule = {}

function WraithAIModule.initializeWraith(model, variantName)
	initializeWraith(model, variantName)
end

function WraithAIModule.isInitialized(model)
	return false
end

return WraithAIModule
