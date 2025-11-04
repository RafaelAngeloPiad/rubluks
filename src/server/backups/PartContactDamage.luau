-- ========================================
-- PART CONTACT DAMAGE SCRIPT
-- Standalone script for parts that deal contact damage
-- Place this Script in any Part to make it deal damage on contact
-- Each part can have its own configuration by editing the CONFIG table below
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Wait for required modules (will wait until they're available)
local ServerConfigs = require(ReplicatedStorage:WaitForChild("SlavkosConfigs"))
local StatusAilmentHandler = require(ReplicatedStorage:WaitForChild("StatusAilmentHandler"))

-- ========================================
-- CONFIGURATION
-- ========================================

-- Local configuration (can be customized per part)
local CONFIG = {
	-- Damage Settings
	damage = 50,                    -- Base damage amount
	damageCooldown = 1.0,           -- Seconds between damage ticks (prevents spam)
	
	-- Status Ailment Settings
	statusAilmentType = nil,        -- "stun", "poison", "burn", "ice", "slow", or nil for none
	statusAilmentChance = 100,      -- Chance to apply status ailment (0-100)
	statusAilmentDuration = 5.0,    -- Duration in seconds
	statusAilmentDPS = 5,          -- Damage per second (for poison/burn/ice)
	statusAilmentTickInterval = 1.0, -- Tick interval for DPS ailments
	statusAilmentSlowMultiplier = 0.5, -- Slow multiplier (for slow/ice)
	
	-- Visual Settings
	showDamageNumbers = true,       -- Show damage numbers above character
	showDamageFlash = true,         -- Show damage flash highlight
	damageFlashColor = Color3.new(1, 0, 0), -- Red flash color
	damageFlashDuration = 0.1,      -- Flash duration in seconds
	
	-- Targeting Settings
	damagePlayers = true,          -- Damage players
	damageMobs = false,            -- Damage mobs
	damageSelf = false,            -- Damage the character that owns this part (if applicable)
	
	-- Cleanup Settings
	cleanupInterval = 5.0,         -- Cleanup interval for highlights
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to get player from model
local function getPlayer(model)
	if not model then return nil end
	return Players:GetPlayerFromCharacter(model)
end

-- Function to get defense stats for a model (player or mob)
local function getDefenseStats(model)
	if not model then
		return 0, 0 -- currentDefense, maxDefense
	end
	
	-- Check if it's a player
	local player = Players:GetPlayerFromCharacter(model)
	if player and player:FindFirstChild("leaderstats") then
		local leaderstats = player.leaderstats
		local currentDefense = 0
		local maxDefense = 0
		
		if leaderstats:FindFirstChild("MaxDefense") then
			maxDefense = leaderstats.MaxDefense.Value
		end
		if leaderstats:FindFirstChild("CurrentDefense") then
			currentDefense = leaderstats.CurrentDefense.Value
		else
			currentDefense = maxDefense
		end
		
		return currentDefense, maxDefense
	end
	
	-- Check if it's a mob (using attributes)
	if model:IsA("Model") then
		local currentDefense = model:GetAttribute("CurrentDefense") or 0
		local maxDefense = model:GetAttribute("MaxDefense") or 0
		return currentDefense, maxDefense
	end
	
	return 0, 0
end

-- Function to set defense stats for a model
local function setDefenseStats(model, currentDefense, maxDefense)
	if not model then return end
	
	currentDefense = math.max(0, math.min(currentDefense, maxDefense))
	
	local player = Players:GetPlayerFromCharacter(model)
	if player and player:FindFirstChild("leaderstats") then
		local leaderstats = player.leaderstats
		local currentDefStat = leaderstats:FindFirstChild("CurrentDefense")
		if currentDefStat then
			currentDefStat.Value = currentDefense
		end
	end
	
	if model:IsA("Model") then
		model:SetAttribute("CurrentDefense", currentDefense)
		if maxDefense then
			model:SetAttribute("MaxDefense", maxDefense)
		end
	end
end

-- Function to calculate damage with defense system
local function calculateDamageWithDefense(rawDamage, target)
	if not target then
		return rawDamage, 0
	end
	
	local currentDefense, maxDefense = getDefenseStats(target)
	
	-- If target has defense, damage goes to defense first, then health
	local damageToDefense = 0
	local damageToHealth = 0
	
	if currentDefense > 0 then
		if rawDamage <= currentDefense then
			damageToDefense = rawDamage
			damageToHealth = 0
		else
			damageToDefense = currentDefense
			damageToHealth = rawDamage - currentDefense
		end
	else
		damageToHealth = rawDamage
		damageToDefense = 0
	end
	
	return damageToHealth, damageToDefense
end

-- Function to create damage flash effect using Highlight
local function createDamageFlash(model, color, duration)
	duration = duration or CONFIG.damageFlashDuration
	
	if not model or not model.Parent then
		return
	end
	
	-- Create a NEW highlight for EACH flash
	local highlight = Instance.new("Highlight")
	highlight.Parent = model
	highlight.Name = "DamageFlash_" .. tostring(tick() * 1000)
	
	-- Apply configuration values
	highlight.FillColor = color or CONFIG.damageFlashColor
	highlight.FillTransparency = 0.95
	highlight.OutlineColor = color or CONFIG.damageFlashColor
	highlight.OutlineTransparency = 0
	
	-- Use Debris service for automatic cleanup
	Debris:AddItem(highlight, duration)
	
	-- Also monitor model removal as backup
	local removalConnection
	removalConnection = model.AncestryChanged:Connect(function()
		if not model.Parent then
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
			if removalConnection then
				removalConnection:Disconnect()
			end
		end
	end)
	
	-- Disconnect after duration to avoid memory leaks
	task.delay(duration + 0.1, function()
		if removalConnection then
			removalConnection:Disconnect()
		end
	end)
end

-- Function to check if damage should be applied
local function shouldApplyDamage(target)
	if not target then return false end
	
	local player = getPlayer(target)
	local isPlayer = player ~= nil
	
	-- Check if we should damage players
	if isPlayer and not CONFIG.damagePlayers then
		return false
	end
	
	-- Check if we should damage mobs
	if not isPlayer and not CONFIG.damageMobs then
		return false
	end
	
	-- Check if we should damage self (if part has a parent character)
	local part = script.Parent
	if part and part.Parent then
		local partCharacter = part.Parent
		if partCharacter:IsA("Model") and partCharacter == target then
			return CONFIG.damageSelf
		end
	end
	
	return true
end

-- ========================================
-- MAIN DAMAGE HANDLER
-- ========================================

-- Track last damage time per character to prevent spam
local lastDamageTime = {} -- {[model]: lastDamageTime}

-- Function to apply damage to a character
local function applyDamage(character)
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	
	-- Check if we should apply damage
	if not shouldApplyDamage(character) then
		return
	end
	
	-- Check cooldown
	local currentTime = tick()
	if lastDamageTime[character] then
		local timeSinceLastDamage = currentTime - lastDamageTime[character]
		if timeSinceLastDamage < CONFIG.damageCooldown then
			return -- Still on cooldown
		end
	end
	
	-- Update last damage time
	lastDamageTime[character] = currentTime
	
	-- Calculate damage with defense
	local damageToHealth, damageToDefense = calculateDamageWithDefense(CONFIG.damage, character)
	
	-- Apply damage to health
	if damageToHealth > 0 then
		humanoid:TakeDamage(damageToHealth)
	end
	
	-- Apply damage to defense
	if damageToDefense > 0 then
		local currentDef, maxDef = getDefenseStats(character)
		setDefenseStats(character, currentDef - damageToDefense, maxDef)
	end
	
	-- Show damage numbers if enabled
	if CONFIG.showDamageNumbers and (damageToHealth + damageToDefense) > 0 then
		if _G.createDamageNumber then
			_G.createDamageNumber(character, damageToHealth + damageToDefense)
		end
	end
	
	-- Show damage flash if enabled
	if CONFIG.showDamageFlash and (damageToHealth + damageToDefense) > 0 then
		createDamageFlash(character, CONFIG.damageFlashColor, CONFIG.damageFlashDuration)
	end
	
	-- Apply status ailment if configured
	if CONFIG.statusAilmentType then
		local ailmentTypeLower = string.lower(CONFIG.statusAilmentType)
		local ailmentTypeConstant = nil
		
		if ailmentTypeLower == "stun" then
			ailmentTypeConstant = StatusAilmentHandler.AilmentTypes.STUN
		elseif ailmentTypeLower == "poison" then
			ailmentTypeConstant = StatusAilmentHandler.AilmentTypes.POISON
		elseif ailmentTypeLower == "burn" then
			ailmentTypeConstant = StatusAilmentHandler.AilmentTypes.BURN
		elseif ailmentTypeLower == "ice" then
			ailmentTypeConstant = StatusAilmentHandler.AilmentTypes.ICE
		elseif ailmentTypeLower == "slow" then
			ailmentTypeConstant = StatusAilmentHandler.AilmentTypes.SLOW
		end
		
		if ailmentTypeConstant then
			local ailmentConfig = {
				duration = CONFIG.statusAilmentDuration,
				chance = CONFIG.statusAilmentChance,
				dps = CONFIG.statusAilmentDPS,
				tickInterval = CONFIG.statusAilmentTickInterval,
				slowMultiplier = CONFIG.statusAilmentSlowMultiplier
			}
			
			StatusAilmentHandler.apply(character, ailmentTypeConstant, ailmentConfig)
		end
	end
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Get the part this script is in
local part = script.Parent
if not part or not part:IsA("BasePart") then
	warn("[PartContactDamage] Script must be placed in a BasePart!")
	return
end

-- Make sure part can detect touches
part.CanTouch = true
part.CanCollide = true

-- Track touched characters to prevent multiple touches per character
local touchedCharacters = {} -- {[character]: true}

-- Handle part touches
part.Touched:Connect(function(hit)
	-- Get the character model
	local character = hit.Parent
	if not character or not character:IsA("Model") then
		return
	end
	
	-- Check if character has a humanoid
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	-- Check if character is already being tracked (prevent spam)
	if not touchedCharacters[character] then
		touchedCharacters[character] = true
		
		-- Apply damage
		applyDamage(character)
		
		-- Remove from tracking after a short delay (allows for re-touching after cooldown)
		task.delay(0.1, function()
			touchedCharacters[character] = nil
		end)
	end
end)

-- Clean up tracking data when characters are removed
game.Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		lastDamageTime[player.Character] = nil
		touchedCharacters[player.Character] = nil
	end
end)

-- Clean up tracking data when part is destroyed
part.AncestryChanged:Connect(function()
	if not part.Parent then
		lastDamageTime = {}
		touchedCharacters = {}
	end
end)

-- ========================================
-- CONFIGURATION NOTES
-- ========================================

--[[
	TO CUSTOMIZE THIS PART:
	Edit the CONFIG table above (lines 21-47) to customize:
	- damage: Base damage amount
	- statusAilmentType: "stun", "poison", "burn", "ice", "slow", or nil
	- statusAilmentChance: 0-100 (percentage chance to apply)
	- statusAilmentDuration: How long the ailment lasts
	- statusAilmentDPS: Damage per second for poison/burn/ice
	- showDamageNumbers: Show damage text above character
	- showDamageFlash: Show damage flash highlight
	- damageFlashColor: Color of the flash highlight
	- damagePlayers/damageMobs: What to damage
	
	EXAMPLE CONFIGURATIONS:
	
	-- Fire Trap (burn damage)
	damage = 25,
	statusAilmentType = "burn",
	statusAilmentChance = 100,
	statusAilmentDuration = 5.0,
	statusAilmentDPS = 10,
	damageFlashColor = Color3.new(1, 0.5, 0), -- Orange
	
	-- Poison Trap (poison damage)
	damage = 20,
	statusAilmentType = "poison",
	statusAilmentChance = 100,
	statusAilmentDuration = 5.0,
	statusAilmentDPS = 5,
	damageFlashColor = Color3.new(0.5, 0, 0.5), -- Purple
	
	-- Ice Trap (slow + damage)
	damage = 15,
	statusAilmentType = "ice",
	statusAilmentChance = 100,
	statusAilmentDuration = 3.0,
	statusAilmentDPS = 3,
	statusAilmentSlowMultiplier = 0.3,
	damageFlashColor = Color3.new(0, 0.5, 1), -- Blue
	
	-- Slow Trap (slow only, no damage)
	damage = 0,
	statusAilmentType = "slow",
	statusAilmentChance = 100,
	statusAilmentDuration = 3.0,
	statusAilmentSlowMultiplier = 0.5,
	showDamageNumbers = false,
	showDamageFlash = false,
	
	-- Stun Trap (stun only, no damage)
	damage = 0,
	statusAilmentType = "stun",
	statusAilmentChance = 50,
	statusAilmentDuration = 2.0,
	showDamageNumbers = false,
	damageFlashColor = Color3.new(0.5, 0.5, 0.5), -- Gray
]]

