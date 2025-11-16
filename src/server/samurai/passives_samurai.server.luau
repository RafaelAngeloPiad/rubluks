-- ========================================
-- SAMURAI PASSIVES SERVER
-- Passive: Blade Dance - Adds Attack stat on attacks (HP-based with different chances)
-- Passive: Burst - Combo2 attack has chance to deal double damage (x2)
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Store player state for Samurai passives
local playerSamuraiPassiveStates = {}

local function canUseSamuraiPassives(player)
	if ServerConfigs.isWeaponClassMatch(player) then
		return true
	end

	local mismatchedConfig = ServerConfigs.Client and ServerConfigs.Client.MismatchedWeaponPenalty
	if mismatchedConfig and mismatchedConfig.allowSkills == false then
		warn("[SamuraiPassives] Passive blocked: Player " .. player.Name .. " tried to use Samurai passive with mismatched weapon.")
		return false
	end

	return true
end

-- Function to check if Burst passive should trigger
-- @param player: Player instance
-- @return: boolean indicating if passive should trigger
function _G.checkSamuraiBurstPassive(player)
	if not player then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Check if player is Samurai class (respect SLAVKO acting class)
	local class = leaderstats:FindFirstChild("Class")
	local actingClass = (ServerConfigs.getActingClass and ServerConfigs.getActingClass(player)) or (class and class.Value)
	if not actingClass or actingClass ~= "Samurai" then
		return false
	end
	
	if not canUseSamuraiPassives(player) then
		return false
	end

	-- Get player level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return false
	end
	
	-- Get passive config (this checks for highest unlocked level)
	local passiveConfig = ServerConfigs.getSamuraiPassiveConfig("Burst", level.Value)
	if not passiveConfig then
		-- Passive not unlocked or config invalid
		return false
	end
	
	-- Check HP condition to determine which chance to use
	local character = player.Character
	if not character then
		return false
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return false
	end
	
	-- Calculate HP percentage
	local maxHealth = humanoid.MaxHealth
	local currentHealth = humanoid.Health
	local healthPercentage = maxHealth > 0 and (currentHealth / maxHealth) or 1
	
	-- Get HP threshold from config
	local hpThreshold = ServerConfigs.SamuraiPassives.Burst.hpThreshold or 0.3
	
	-- Determine which chance to use based on HP
	local chance = nil
	if healthPercentage < hpThreshold then
		-- HP < 30%, use much larger chance
		chance = passiveConfig.chanceLowHP
	else
		-- HP > 30%, use normal chance
		chance = passiveConfig.chanceHighHP
	end
	
	if not chance or chance <= 0 then
		return false
	end
	
	-- Roll for chance to trigger passive (0-100)
	-- If chance is 100, always trigger; otherwise roll
	if chance >= 100 then
		return true
	end
	
	local roll = math.random() * 100
	local shouldTrigger = roll < chance
	
	return shouldTrigger
end

-- Function to check if Blade Dance passive should trigger and get attack increase
-- @param player: Player instance
-- @return: attackIncrease (number) or nil if passive should not trigger
function _G.checkSamuraiBladeDancePassive(player)
	if not player then
		return nil
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	
	-- Check if player is Samurai class (respect SLAVKO acting class)
	local class = leaderstats:FindFirstChild("Class")
	local actingClass = (ServerConfigs.getActingClass and ServerConfigs.getActingClass(player)) or (class and class.Value)
	if not actingClass or actingClass ~= "Samurai" then
		return nil
	end
	
	if not canUseSamuraiPassives(player) then
		return nil
	end

	-- Get player level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return nil
	end
	
	-- Get passive config (this checks for highest unlocked level)
	local passiveConfig = ServerConfigs.getSamuraiPassiveConfig("BladeDance", level.Value)
	if not passiveConfig or not passiveConfig.attackIncrease or not passiveConfig.chance then
		-- Passive not unlocked or config invalid
		return nil
	end
	
	-- Check HP condition to determine which chance to use
	local character = player.Character
	if not character then
		return nil
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return nil
	end
	
	-- Calculate HP percentage
	local maxHealth = humanoid.MaxHealth
	local currentHealth = humanoid.Health
	local healthPercentage = maxHealth > 0 and (currentHealth / maxHealth) or 1
	
	-- Get HP threshold and chance multiplier from config
	local bladeDanceConfig = ServerConfigs.SamuraiPassives.BladeDance
	local hpThreshold = bladeDanceConfig.hpThreshold or 0.3
	local lowHPChanceMultiplier = bladeDanceConfig.lowHPChanceMultiplier or 2.0
	
	-- Determine which chance to use based on HP (same multiplier for both)
	local chance = nil
	if healthPercentage < hpThreshold then
		-- HP < 30%, use much larger chance (2x the base chance)
		chance = passiveConfig.chance * lowHPChanceMultiplier
	else
		-- HP >= 30%, use normal chance (base chance from config)
		chance = passiveConfig.chance
	end
	
	if not chance or chance <= 0 then
		return nil
	end
	
	-- Roll for chance to trigger passive (0-100)
	-- If chance is 100, always trigger; otherwise roll
	if chance >= 100 then
		return passiveConfig.attackIncrease
	end
	
	local roll = math.random() * 100
	if roll < chance then
		return passiveConfig.attackIncrease
	end
	
	return nil
end

-- Monitor all players for Samurai passives
local function setupPlayerSamuraiPassives(player)
	-- Wait for character to spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Initialize state
		if not playerSamuraiPassiveStates[player] then
			playerSamuraiPassiveStates[player] = {
				bladeDanceActive = false,
				bladeDanceAttackIncrease = 0
			}
		end
		
		-- Check and update passives (Blade Dance is checked on attacks, not continuously)
		-- Burst is checked on combo2 attacks, not continuously
		
		-- Monitor level changes (for passive unlocking)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local level = leaderstats:FindFirstChild("Level")
			if level then
				level.Changed:Connect(function()
					-- Passives are checked on-demand, no need to update state here
				end)
			end
			
			-- Monitor class changes
			local class = leaderstats:FindFirstChild("Class")
			if class then
				class.Changed:Connect(function()
					-- Clear passives if class changes
					if playerSamuraiPassiveStates[player] then
						playerSamuraiPassiveStates[player].bladeDanceActive = false
						playerSamuraiPassiveStates[player].bladeDanceAttackIncrease = 0
					end
				end)
			end
		end
	end)
end

-- Setup for all players
Players.PlayerAdded:Connect(function(player)
	setupPlayerSamuraiPassives(player)
end)

-- Setup for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerSamuraiPassives(player)
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerSamuraiPassiveStates[player] then
		playerSamuraiPassiveStates[player] = nil
	end
end)

