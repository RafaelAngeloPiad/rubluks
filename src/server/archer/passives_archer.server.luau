-- ========================================
-- ARCHER PASSIVES SERVER
-- Passive: Headshot - Attacks have chance to deal double damage (x2)
-- Passive: Immobilize - Attacks have chance to stun targets
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

local function canUseArcherPassives(player)
	if ServerConfigs.isWeaponClassMatch(player) then
		return true
	end

	local mismatchedConfig = ServerConfigs.Client and ServerConfigs.Client.MismatchedWeaponPenalty
	if mismatchedConfig and mismatchedConfig.allowSkills == false then
		warn("[ArcherPassives] Passive blocked: Player " .. player.Name .. " tried to use Archer passives with mismatched weapon.")
		return false
	end

	return true
end

-- Function to check if Headshot passive should trigger
-- @param player: Player instance
-- @return: boolean indicating if passive should trigger
function _G.checkHeadshotPassive(player)
	if not player then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Check if player is Archer class (respect SLAVKO acting class)
	local class = leaderstats:FindFirstChild("Class")
	local actingClass = (ServerConfigs.getActingClass and ServerConfigs.getActingClass(player)) or (class and class.Value)
	if not actingClass or actingClass ~= "Archer" then
		return false
	end

	if not canUseArcherPassives(player) then
		return false
	end
	
	-- Get player level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return false
	end
	
	-- Get passive config (this checks for highest unlocked level)
	local passiveConfig = ServerConfigs.getArcherPassiveConfig("Headshot", level.Value)
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

-- Store player state for Archer passives
local playerArcherPassiveStates = {}

-- Function to get Immobilize stun chance for a player (called from hitbox damage)
-- @param player: Player instance
-- @return: Stun chance (0-100) or nil if passive not active
function _G.getArcherImmobilizeStunChance(player)
	if not player then
		return nil
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	
	-- Check if player is Archer class (respect SLAVKO acting class)
	local class = leaderstats:FindFirstChild("Class")
	local actingClass = (ServerConfigs.getActingClass and ServerConfigs.getActingClass(player)) or (class and class.Value)
	if not actingClass or actingClass ~= "Archer" then
		return nil
	end

	if not canUseArcherPassives(player) then
		return nil
	end
	
	-- Get player level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return nil
	end
	
	-- Get passive config (this checks for highest unlocked level)
	local passiveConfig = ServerConfigs.getArcherPassiveConfig("Immobilize", level.Value)
	if not passiveConfig or not passiveConfig.stunChance then
		-- Passive not unlocked or config invalid
		return nil
	end
	
	return passiveConfig.stunChance or nil
end

-- Check and update Immobilize passive state
local function checkImmobilizePassive(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local class = leaderstats:FindFirstChild("Class")
	local level = leaderstats:FindFirstChild("Level")
	
	local actingClass = (ServerConfigs.getActingClass and ServerConfigs.getActingClass(player)) or (class and class.Value)
	if not actingClass or actingClass ~= "Archer" or not level then
		-- Not an Archer or no level, deactivate Immobilize
		if playerArcherPassiveStates[player] then
			playerArcherPassiveStates[player].immobilizeActive = false
			playerArcherPassiveStates[player].immobilizeStunChance = 0
			
			-- Update ActivePassives tracking
			local activePassives = leaderstats:FindFirstChild("ActivePassives")
			if activePassives then
				local currentPassives = activePassives.Value
				local passiveList = {}
				-- Parse and rebuild list without Immobilize
				for passiveName in string.gmatch(currentPassives, "([^,]+)") do
					passiveName = passiveName:match("^%s*(.-)%s*$") -- Trim whitespace
					if passiveName ~= "Immobilize" then
						table.insert(passiveList, passiveName)
					end
				end
				activePassives.Value = table.concat(passiveList, ",")
			end
		end
		return
	end

	if not canUseArcherPassives(player) then
		if playerArcherPassiveStates[player] then
			playerArcherPassiveStates[player].immobilizeActive = false
			playerArcherPassiveStates[player].immobilizeStunChance = 0

			local activePassives = leaderstats:FindFirstChild("ActivePassives")
			if activePassives then
				local currentPassives = activePassives.Value
				local passiveList = {}
				for passiveName in string.gmatch(currentPassives, "([^,]+)") do
					passiveName = passiveName:match("^%s*(.-)%s*$")
					if passiveName ~= "Immobilize" then
						table.insert(passiveList, passiveName)
					end
				end
				activePassives.Value = table.concat(passiveList, ",")
			end
		end
		return
	end
	
	-- Check Immobilize passive (always active if unlocked, no HP threshold)
	local immobilizePassiveConfig = ServerConfigs.getArcherPassiveConfig("Immobilize", level.Value)
	if immobilizePassiveConfig then
		-- Passive is unlocked, activate it
		if not playerArcherPassiveStates[player] then
			playerArcherPassiveStates[player] = {
				immobilizeActive = false,
				immobilizeStunChance = 0
			}
		end
		
		-- Update Immobilize state
		playerArcherPassiveStates[player].immobilizeActive = true
		playerArcherPassiveStates[player].immobilizeStunChance = immobilizePassiveConfig.stunChance
		
		-- Update ActivePassives tracking
		local activePassives = leaderstats:FindFirstChild("ActivePassives")
		if activePassives then
			local currentPassives = activePassives.Value
			-- Check if Immobilize is already in the list
			if not string.find(currentPassives, "Immobilize") then
				if currentPassives == "" then
					activePassives.Value = "Immobilize"
				else
					activePassives.Value = currentPassives .. ",Immobilize"
				end
			end
		end
	else
		-- Passive not unlocked, deactivate it
		if playerArcherPassiveStates[player] then
			playerArcherPassiveStates[player].immobilizeActive = false
			playerArcherPassiveStates[player].immobilizeStunChance = 0
			
			-- Update ActivePassives tracking
			local activePassives = leaderstats:FindFirstChild("ActivePassives")
			if activePassives then
				local currentPassives = activePassives.Value
				local passiveList = {}
				-- Parse and rebuild list without Immobilize
				for passiveName in string.gmatch(currentPassives, "([^,]+)") do
					passiveName = passiveName:match("^%s*(.-)%s*$") -- Trim whitespace
					if passiveName ~= "Immobilize" then
						table.insert(passiveList, passiveName)
					end
				end
				activePassives.Value = table.concat(passiveList, ",")
			end
		end
	end
end

-- Monitor all players for Archer passives
local function setupPlayerArcherPassives(player)
	-- Wait for character to spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Initialize state
		if not playerArcherPassiveStates[player] then
			playerArcherPassiveStates[player] = {
				immobilizeActive = false,
				immobilizeStunChance = 0
			}
		end
		
		-- Monitor level changes (for passive unlocking)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local level = leaderstats:FindFirstChild("Level")
			if level then
				level.Changed:Connect(function()
					checkImmobilizePassive(player)
				end)
			end
			
			-- Monitor class changes
			local class = leaderstats:FindFirstChild("Class")
			if class then
				class.Changed:Connect(function()
					checkImmobilizePassive(player)
				end)
			end
		end
		
		-- Initial check
		checkImmobilizePassive(player)
	end)
	
	-- Also check passives when player first joins (before character spawns)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level")
		if level then
			level.Changed:Connect(function()
				checkImmobilizePassive(player)
			end)
		end
		
		-- Monitor class changes
		local class = leaderstats:FindFirstChild("Class")
		if class then
			class.Changed:Connect(function()
				checkImmobilizePassive(player)
			end)
		end
		
		-- Initial check
		checkImmobilizePassive(player)
	end
end

-- Setup for all players
Players.PlayerAdded:Connect(function(player)
	setupPlayerArcherPassives(player)
end)

-- Setup for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerArcherPassives(player)
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerArcherPassiveStates[player] then
		playerArcherPassiveStates[player] = nil
	end
end)

