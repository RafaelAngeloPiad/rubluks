-- ========================================
-- KNIGHTS BLADE PASSIVE SERVER
-- Passive: 2nd combo attack has chance to hit twice (double damage)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

local function canUseKnightPassives(player)
	if ServerConfigs.isWeaponClassMatch(player) then
		return true
	end

	local mismatchedConfig = ServerConfigs.Client and ServerConfigs.Client.MismatchedWeaponPenalty
	if mismatchedConfig and mismatchedConfig.allowSkills == false then
		warn("[KnightPassives] Passive blocked: Player " .. player.Name .. " tried to use Knight passives with mismatched weapon.")
		return false
	end

	return true
end

-- Function to check if Knights Blade passive should trigger
-- @param player: Player instance
-- @return: boolean indicating if passive should trigger
function _G.checkKnightsBladePassive(player)
	if not player then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Check if player is Knight class
	local class = leaderstats:FindFirstChild("Class")
	if not class or class.Value ~= "Knight" then
		return false
	end

	if not canUseKnightPassives(player) then
		return false
	end
	
	-- Get player level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return false
	end
	
	-- Get passive config (this checks for highest unlocked level)
	local passiveConfig = ServerConfigs.getPassiveConfig("KnightsBlade", level.Value)
	if not passiveConfig or not passiveConfig.chance then
		-- Passive not unlocked or config invalid
		return false
	end
	
	-- Roll for chance to trigger passive (0-100)
	-- If chance is 100, always trigger; otherwise roll
	if passiveConfig.chance >= 100 then
		return true
	end
	
	local roll = math.random() * 100
	local shouldTrigger = roll < passiveConfig.chance
	
	return shouldTrigger
end

