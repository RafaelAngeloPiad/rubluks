-- ========================================
-- BRAWLER PASSIVES SERVER
-- Passive: Rage - Increases Attack and Attack Speed when HP < 30%
-- Passive: Madness - Provides chance to stun on attacks when HP < 30%
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Store player state for Brawler passives
local playerBrawlerPassiveStates = {}

local function canUseBrawlerPassives(player)
	if ServerConfigs.isWeaponClassMatch(player) then
		return true
	end

	local mismatchedConfig = ServerConfigs.Client and ServerConfigs.Client.MismatchedWeaponPenalty
	if mismatchedConfig and mismatchedConfig.allowSkills == false then
		warn("[BrawlerPassives] Passive blocked: Player " .. player.Name .. " tried to use Brawler passives with mismatched weapon.")
		return false
	end

	return true
end

-- Function to apply Rage passive bonuses
local function applyRagePassive(player, attackIncrease, attackSpeedIncrease)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	local maxAttack = leaderstats:FindFirstChild("MaxAttack")
	local attackSpeed = leaderstats:FindFirstChild("AttackSpeed")
	
	if not maxAttack then
		return false
	end
	
	local state = playerBrawlerPassiveStates[player]
	if not state then
		return false
	end
	
	-- Get the true base attack (check if BaseStats folder exists with BaseMaxAttack)
	-- This ensures we use the original base even if buffs are active
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	local trueBaseAttack = nil
	if baseStatsFolder then
		local baseMaxAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
		if baseMaxAttack then
			trueBaseAttack = baseMaxAttack.Value
		end
	end
	
	-- If no BaseMaxAttack found, use current MaxAttack as base (for first activation)
	if not trueBaseAttack then
		trueBaseAttack = maxAttack.Value - (state.rageAttackIncrease or 0)
		-- Store it in state for later use
		state.baseMaxAttack = trueBaseAttack
	else
		-- Use the true base from BaseStats
		state.baseMaxAttack = trueBaseAttack
	end
	
	-- Apply attack increase to current MaxAttack (which may already include buffs)
	-- This ensures stacking works correctly (buff + passive = combined bonus)
	local newMaxAttack = maxAttack.Value + attackIncrease
	maxAttack.Value = newMaxAttack
	
	-- Apply attack speed increase to current AttackSpeed (which may already include buffs)
	if attackSpeed then
		local newAttackSpeed = attackSpeed.Value + attackSpeedIncrease
		attackSpeed.Value = newAttackSpeed
	end
	
	-- Store base stats in BaseStats folder for UI display (similar to buffs)
	-- Only create/update if it doesn't exist (to preserve true base from buffs)
	if not baseStatsFolder then
		baseStatsFolder = Instance.new("Folder", leaderstats)
		baseStatsFolder.Name = "BaseStats"
	end
	
	-- Store base MaxAttack for UI (only if it doesn't exist)
	local baseMaxAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
	if not baseMaxAttack then
		baseMaxAttack = Instance.new("NumberValue", baseStatsFolder)
		baseMaxAttack.Name = "BaseMaxAttack"
		baseMaxAttack.Value = trueBaseAttack
	end
	
	-- Update state
	state.rageActive = true
	state.rageAttackIncrease = attackIncrease
	state.rageAttackSpeedIncrease = attackSpeedIncrease
	
	-- Update ActivePassives tracking
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	if activePassives then
		local currentPassives = activePassives.Value
		-- Check if Rage is already in the list
		if not string.find(currentPassives, "Rage") then
			if currentPassives == "" then
				activePassives.Value = "Rage"
			else
				activePassives.Value = currentPassives .. ",Rage"
			end
		end
	end
	
	return true
end

-- Function to remove Rage passive bonuses
local function removeRagePassive(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	local maxAttack = leaderstats:FindFirstChild("MaxAttack")
	local attackSpeed = leaderstats:FindFirstChild("AttackSpeed")
	
	if not maxAttack then
		return false
	end
	
	local state = playerBrawlerPassiveStates[player]
	if not state or not state.rageActive then
		return false
	end
	
	if maxAttack then
		-- Remove Rage bonus from current MaxAttack (which may include buffs)
		-- This ensures stacking works correctly when removing
		local newMaxAttack = maxAttack.Value - state.rageAttackIncrease
		maxAttack.Value = math.max(0, newMaxAttack)
	end
	
	if attackSpeed then
		-- Remove Rage bonus from current AttackSpeed (which may include buffs)
		local newAttackSpeed = attackSpeed.Value - state.rageAttackSpeedIncrease
		attackSpeed.Value = math.max(0, newAttackSpeed)
	end
	
	-- Update state
	state.rageActive = false
	
	-- Update ActivePassives tracking
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	if activePassives then
		local currentPassives = activePassives.Value
		local passiveList = {}
		-- Parse and rebuild list without Rage
		for passiveName in string.gmatch(currentPassives, "([^,]+)") do
			passiveName = passiveName:match("^%s*(.-)%s*$") -- Trim whitespace
			if passiveName ~= "Rage" then
				table.insert(passiveList, passiveName)
			end
		end
		activePassives.Value = table.concat(passiveList, ",")
	end
	
	return true
end

-- Function to check and update Brawler passives for a player
local function checkBrawlerPassives(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	
	local class = leaderstats:FindFirstChild("Class")
	local level = leaderstats:FindFirstChild("Level")
	
	if not class or class.Value ~= "Brawler" or not level then
		-- Not a Brawler or no level, remove passives if active
		if playerBrawlerPassiveStates[player] then
			if playerBrawlerPassiveStates[player].rageActive then
				removeRagePassive(player)
			end
		end
		return
	end

	if not canUseBrawlerPassives(player) then
		if playerBrawlerPassiveStates[player] then
			if playerBrawlerPassiveStates[player].rageActive then
				removeRagePassive(player)
			end

			if playerBrawlerPassiveStates[player].madnessActive then
				playerBrawlerPassiveStates[player].madnessActive = false
				playerBrawlerPassiveStates[player].madnessStunChance = 0

				local activePassives = leaderstats:FindFirstChild("ActivePassives")
				if activePassives then
					local currentPassives = activePassives.Value
					local passiveList = {}
					for passiveName in string.gmatch(currentPassives, "([^,]+)") do
						passiveName = passiveName:match("^%s*(.-)%s*$")
						if passiveName ~= "Madness" then
							table.insert(passiveList, passiveName)
						end
					end
					activePassives.Value = table.concat(passiveList, ",")
				end
			end
		end
		return
	end
	
	-- Check HP condition
	local character = player.Character
	if not character then
		-- No character, remove passives if active
		if playerBrawlerPassiveStates[player] then
			if playerBrawlerPassiveStates[player].rageActive then
				removeRagePassive(player)
			end
		end
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		-- No humanoid, remove passives if active
		if playerBrawlerPassiveStates[player] then
			if playerBrawlerPassiveStates[player].rageActive then
				removeRagePassive(player)
			end
		end
		return
	end
	
	-- Calculate HP percentage
	local maxHealth = humanoid.MaxHealth
	local currentHealth = humanoid.Health
	local healthPercentage = maxHealth > 0 and (currentHealth / maxHealth) or 1
	
	-- Get HP threshold from config
	local rageHpThreshold = ServerConfigs.BrawlerPassives.Rage.hpThreshold or 0.3
	local madnessHpThreshold = ServerConfigs.BrawlerPassives.Madness.hpThreshold or 0.3
	
	-- Check Rage passive
	local ragePassiveConfig = ServerConfigs.getBrawlerPassiveConfig("Rage", level.Value)
	if ragePassiveConfig and healthPercentage < rageHpThreshold then
		-- HP is below threshold, activate Rage passive
		if not playerBrawlerPassiveStates[player] then
			playerBrawlerPassiveStates[player] = {
				rageActive = false,
				rageAttackIncrease = 0,
				rageAttackSpeedIncrease = 0,
				baseMaxAttack = 0,
				madnessActive = false,
				madnessStunChance = 0
			}
		end
		
		-- Check if already active with same increase
		if not playerBrawlerPassiveStates[player].rageActive or 
		   playerBrawlerPassiveStates[player].rageAttackIncrease ~= ragePassiveConfig.attackIncrease or
		   playerBrawlerPassiveStates[player].rageAttackSpeedIncrease ~= ragePassiveConfig.attackSpeedIncrease then
			applyRagePassive(player, ragePassiveConfig.attackIncrease, ragePassiveConfig.attackSpeedIncrease)
		end
	else
		-- HP is above threshold, deactivate Rage passive
		if playerBrawlerPassiveStates[player] and playerBrawlerPassiveStates[player].rageActive then
			removeRagePassive(player)
		end
	end
	
	-- Check Madness passive (only track active state, stun chance is checked during attacks)
	local madnessPassiveConfig = ServerConfigs.getBrawlerPassiveConfig("Madness", level.Value)
	if madnessPassiveConfig and healthPercentage < madnessHpThreshold then
		-- HP is below threshold, activate Madness passive
		if not playerBrawlerPassiveStates[player] then
			playerBrawlerPassiveStates[player] = {
				rageActive = false,
				rageAttackIncrease = 0,
				rageAttackSpeedIncrease = 0,
				baseMaxAttack = 0,
				madnessActive = false,
				madnessStunChance = 0
			}
		end
		
		-- Update Madness state
		playerBrawlerPassiveStates[player].madnessActive = true
		playerBrawlerPassiveStates[player].madnessStunChance = madnessPassiveConfig.stunChance
		
		-- Update ActivePassives tracking
		local activePassives = leaderstats:FindFirstChild("ActivePassives")
		if activePassives then
			local currentPassives = activePassives.Value
			-- Check if Madness is already in the list
			if not string.find(currentPassives, "Madness") then
				if currentPassives == "" then
					activePassives.Value = "Madness"
				else
					activePassives.Value = currentPassives .. ",Madness"
				end
			end
		end
	else
		-- HP is above threshold, deactivate Madness passive
		if playerBrawlerPassiveStates[player] then
			playerBrawlerPassiveStates[player].madnessActive = false
			playerBrawlerPassiveStates[player].madnessStunChance = 0
			
			-- Update ActivePassives tracking
			local activePassives = leaderstats:FindFirstChild("ActivePassives")
			if activePassives then
				local currentPassives = activePassives.Value
				local passiveList = {}
				-- Parse and rebuild list without Madness
				for passiveName in string.gmatch(currentPassives, "([^,]+)") do
					passiveName = passiveName:match("^%s*(.-)%s*$") -- Trim whitespace
					if passiveName ~= "Madness" then
						table.insert(passiveList, passiveName)
					end
				end
				activePassives.Value = table.concat(passiveList, ",")
			end
		end
	end
end

-- Function to get Madness stun chance for a player (called from hitbox damage)
-- @param player: Player instance
-- @return: Stun chance (0-100) or nil if passive not active
function _G.getBrawlerMadnessStunChance(player)
	if not player or not playerBrawlerPassiveStates[player] then
		return nil
	end
	
	local state = playerBrawlerPassiveStates[player]
	if not state.madnessActive then
		return nil
	end
	
	return state.madnessStunChance or nil
end

-- Monitor all players for Brawler passives
local function setupPlayerBrawlerPassives(player)
	-- Wait for character to spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Initialize state
		if not playerBrawlerPassiveStates[player] then
			playerBrawlerPassiveStates[player] = {
				rageActive = false,
				rageAttackIncrease = 0,
				rageAttackSpeedIncrease = 0,
				baseMaxAttack = 0,
				madnessActive = false,
				madnessStunChance = 0
			}
		end
		
		-- Monitor health changes
		local connection
		connection = humanoid.HealthChanged:Connect(function()
			checkBrawlerPassives(player)
		end)
		
		-- Also monitor MaxHealth changes
		local maxHealthConnection
		maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
			checkBrawlerPassives(player)
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
		checkBrawlerPassives(player)
	end)
	
	-- Also monitor level changes (for passive unlocking)
	player:WaitForChild("leaderstats", 10)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level")
		if level then
			level.Changed:Connect(function()
				checkBrawlerPassives(player)
			end)
		end
		
		-- Monitor class changes
		local class = leaderstats:FindFirstChild("Class")
		if class then
			class.Changed:Connect(function()
				checkBrawlerPassives(player)
			end)
		end
	end
end

-- Setup for all players
Players.PlayerAdded:Connect(function(player)
	setupPlayerBrawlerPassives(player)
end)

-- Setup for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerBrawlerPassives(player)
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerBrawlerPassiveStates[player] then
		playerBrawlerPassiveStates[player] = nil
	end
end)

