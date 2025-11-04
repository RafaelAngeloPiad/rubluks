-- ========================================
-- TENACITY PASSIVE SERVER
-- Passive: Increases Defense when HP < 30%
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Store player state for Tenacity passive
local playerTenacityStates = {}

-- Function to apply Tenacity defense bonus
local function applyTenacityDefense(player, defenseIncrease)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	local maxDefense = leaderstats:FindFirstChild("MaxDefense")
	local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
	
	if not maxDefense then
		return false
	end
	
	local state = playerTenacityStates[player]
	if not state then
		return false
	end
	
	-- Get the true base defense (check if BaseStats folder exists with BaseMaxDefense)
	-- This ensures we use the original base even if buffs are active
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	local trueBaseDefense = nil
	if baseStatsFolder then
		local baseMaxDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
		if baseMaxDefense then
			trueBaseDefense = baseMaxDefense.Value
		end
	end
	
	-- If no BaseMaxDefense found, use current MaxDefense as base (for first activation)
	if not trueBaseDefense then
		trueBaseDefense = maxDefense.Value - (state.defenseIncrease or 0)
		-- Store it in state for later use
		state.baseMaxDefense = trueBaseDefense
	else
		-- Use the true base from BaseStats
		state.baseMaxDefense = trueBaseDefense
	end
	
	-- Apply defense increase to current MaxDefense (which may already include buffs)
	-- This ensures stacking works correctly (buff + passive = combined bonus)
	local newMaxDefense = maxDefense.Value + defenseIncrease
	maxDefense.Value = newMaxDefense
	
	-- Also update CurrentDefense if it exists
	if currentDefense then
		local newCurrentDef = currentDefense.Value + defenseIncrease
		currentDefense.Value = math.max(0, newCurrentDef)
	end
	
	-- Store base defense in BaseStats folder for UI display (similar to buffs)
	-- Only create/update if it doesn't exist (to preserve true base from buffs)
	if not baseStatsFolder then
		baseStatsFolder = Instance.new("Folder", leaderstats)
		baseStatsFolder.Name = "BaseStats"
	end
	
	-- Store base MaxDefense for UI (only if it doesn't exist)
	local baseMaxDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
	if not baseMaxDefense then
		baseMaxDefense = Instance.new("NumberValue", baseStatsFolder)
		baseMaxDefense.Name = "BaseMaxDefense"
		baseMaxDefense.Value = trueBaseDefense
	end
	
	-- Update state
	state.isActive = true
	state.defenseIncrease = defenseIncrease
	
	-- Update ActivePassives tracking
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	if activePassives then
		local currentPassives = activePassives.Value
		-- Check if Tenacity is already in the list
		if not string.find(currentPassives, "Tenacity") then
			if currentPassives == "" then
				activePassives.Value = "Tenacity"
			else
				activePassives.Value = currentPassives .. ",Tenacity"
			end
		end
	end
	
	return true
end

-- Function to remove Tenacity defense bonus
local function removeTenacityDefense(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	local maxDefense = leaderstats:FindFirstChild("MaxDefense")
	local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
	
	if not maxDefense then
		return false
	end
	
	local state = playerTenacityStates[player]
	if not state or not state.isActive then
		return false
	end
	
	if maxDefense then
		-- Remove Tenacity bonus from current MaxDefense (which may include buffs)
		-- This ensures stacking works correctly when removing
		local newMaxDefense = maxDefense.Value - state.defenseIncrease
		maxDefense.Value = math.max(0, newMaxDefense)
	end
	
	if currentDefense then
		-- Remove Tenacity bonus from current defense
		local newCurrentDef = math.max(0, currentDefense.Value - state.defenseIncrease)
		currentDefense.Value = newCurrentDef
	end
	
	-- Update state
	state.isActive = false
	
	-- Update ActivePassives tracking
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	if activePassives then
		local currentPassives = activePassives.Value
		local passiveList = {}
		-- Parse and rebuild list without Tenacity
		for passiveName in string.gmatch(currentPassives, "([^,]+)") do
			passiveName = passiveName:match("^%s*(.-)%s*$") -- Trim whitespace
			if passiveName ~= "Tenacity" then
				table.insert(passiveList, passiveName)
			end
		end
		activePassives.Value = table.concat(passiveList, ",")
	end
	
	return true
end

-- Function to check and update Tenacity passive for a player
local function checkTenacityPassive(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	
	local class = leaderstats:FindFirstChild("Class")
	local level = leaderstats:FindFirstChild("Level")
	
	if not class or class.Value ~= "Knight" or not level then
		-- Not a Knight or no level, remove passive if active
		if playerTenacityStates[player] and playerTenacityStates[player].isActive then
			removeTenacityDefense(player)
		end
		return
	end
	
	-- Get passive config
	local passiveConfig = ServerConfigs.getPassiveConfig("Tenacity", level.Value)
	if not passiveConfig then
		-- Passive not unlocked, remove if active
		if playerTenacityStates[player] and playerTenacityStates[player].isActive then
			removeTenacityDefense(player)
		end
		return
	end
	
	-- Check HP condition
	local character = player.Character
	if not character then
		-- No character, remove if active
		if playerTenacityStates[player] and playerTenacityStates[player].isActive then
			removeTenacityDefense(player)
		end
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		-- No humanoid, remove if active
		if playerTenacityStates[player] and playerTenacityStates[player].isActive then
			removeTenacityDefense(player)
		end
		return
	end
	
	-- Calculate HP percentage
	local maxHealth = humanoid.MaxHealth
	local currentHealth = humanoid.Health
	local healthPercentage = maxHealth > 0 and (currentHealth / maxHealth) or 1
	
	-- Get HP threshold from config
	local hpThreshold = ServerConfigs.KnightPassives.Tenacity.hpThreshold or 0.3
	
	-- Check if HP is below threshold
	if healthPercentage < hpThreshold then
		-- HP is below threshold, activate passive
		if not playerTenacityStates[player] then
			playerTenacityStates[player] = {
				isActive = false,
				defenseIncrease = 0,
				baseMaxDefense = 0
			}
		end
		
		-- Check if already active with same increase
		if not playerTenacityStates[player].isActive or playerTenacityStates[player].defenseIncrease ~= passiveConfig.defenseIncrease then
			applyTenacityDefense(player, passiveConfig.defenseIncrease)
		end
	else
		-- HP is above threshold, deactivate passive
		if playerTenacityStates[player] and playerTenacityStates[player].isActive then
			removeTenacityDefense(player)
		end
	end
end

-- Monitor all players for Tenacity passive
local function setupPlayerTenacity(player)
	-- Wait for character to spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Initialize state
		if not playerTenacityStates[player] then
			playerTenacityStates[player] = {
				isActive = false,
				defenseIncrease = 0,
				baseMaxDefense = 0
			}
		end
		
		-- Monitor health changes
		local connection
		connection = humanoid.HealthChanged:Connect(function()
			checkTenacityPassive(player)
		end)
		
		-- Also monitor MaxHealth changes
		local maxHealthConnection
		maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
			checkTenacityPassive(player)
		end)
		
		-- Clean up when character is removed
		character:WaitForChild("HumanoidRootPart").AncestryChanged:Connect(function()
			if not character.Parent then
				if connection then
					connection:Disconnect()
				end
				if maxHealthConnection then
					maxHealthConnection:Disconnect()
				end
			end
		end)
		
		-- Initial check
		checkTenacityPassive(player)
	end)
	
	-- Also monitor level changes (for passive unlocking)
	player:WaitForChild("leaderstats", 10)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level")
		if level then
			level.Changed:Connect(function()
				checkTenacityPassive(player)
			end)
		end
		
		-- Monitor class changes
		local class = leaderstats:FindFirstChild("Class")
		if class then
			class.Changed:Connect(function()
				checkTenacityPassive(player)
			end)
		end
	end
end

-- Setup for all players
Players.PlayerAdded:Connect(function(player)
	setupPlayerTenacity(player)
end)

-- Setup for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerTenacity(player)
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerTenacityStates[player] then
		playerTenacityStates[player] = nil
	end
end)

