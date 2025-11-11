-- ========================================
-- DYNAMIC HITBOX V3 - FULLY SERVER SIDE
-- Modular hitbox system with part attachment
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- ========================================
-- CONFIGURATION
-- ========================================

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

local HITBOX_CONFIG = {
	transparency = ServerConfigs.Hitbox.transparency, -- Global transparency for all hitbox visuals
}

-- Utility helper to clone configuration tables safely
local function cloneConfig(config)
	if table.clone then
		return table.clone(config)
	end

	local copy = {}
	for key, value in pairs(config) do
		copy[key] = value
	end
	return copy
end

-- ========================================
-- GLOBAL BLOCKING STATE TRACKER
-- ========================================

-- Track which players are currently blocking (by UserId)
-- Key: player.UserId, Value: boolean (true = blocking, false/nil = not blocking)
local playerBlockingState = {}

-- Function to set player blocking state
function _G.setPlayerBlockingState(player, isBlocking)
	if not player then return end
	local userId = player.UserId
	if isBlocking then
		playerBlockingState[userId] = true
	else
		playerBlockingState[userId] = false
	end
end

-- Function to get player blocking state
function _G.getPlayerBlockingState(player)
	if not player then return false end
	local userId = player.UserId
	return playerBlockingState[userId] == true
end

-- Function to clear player blocking state (called when player leaves)
function _G.clearPlayerBlockingState(player)
	if not player then return end
	local userId = player.UserId
	playerBlockingState[userId] = nil
end

-- Clean up blocking state when player leaves
Players.PlayerRemoving:Connect(function(player)
	_G.clearPlayerBlockingState(player)
end)

-- ========================================
-- DELAY SCALING SYSTEM
-- ========================================

-- Function to scale delays based on animation speed multiplier
local function getScaledDelay(baseDelay, actionType, classType)
	if not baseDelay or baseDelay == 0 then
		return 0
	end
	
	-- Use centralized configuration for delay scaling
	return ServerConfigs.getScaledDelay(baseDelay, actionType, classType)
end

-- ========================================
-- DAMAGE TARGETING SYSTEM
-- ========================================

-- Import HitboxExclusions for mob detection
local HitboxExclusions = require(game.ReplicatedStorage:WaitForChild("mobs"):WaitForChild("HitboxExclusions"))

-- Import StatusAilmentHandler for status ailments
-- StatusAilmentHandler is in ReplicatedStorage (from src/shared/)
local StatusAilmentHandler = require(game.ReplicatedStorage:WaitForChild("StatusAilmentHandler"))

-- ========================================
-- DEFENSE SYSTEM
-- ========================================

-- Function to get defense stats for a model (player or mob)
-- Returns: currentDefense, maxDefense
-- 
-- FOR PLAYERS: Reads from leaderstats (CurrentDefense, MaxDefense IntValues)
-- FOR MOBS: Reads from model attributes (CurrentDefense, MaxDefense attributes)
--            Mob attributes are set by MobStatsConfig.applyStats() based on variant
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
			-- If CurrentDefense doesn't exist, default to MaxDefense (full defense)
			currentDefense = maxDefense
		end
		
		return currentDefense, maxDefense
	end
	
	-- Check if it's a mob (using attributes set by MobStatsConfig)
	if model:IsA("Model") then
		local currentDefense = model:GetAttribute("CurrentDefense") or 0
		local maxDefense = model:GetAttribute("MaxDefense") or 0
		return currentDefense, maxDefense
	end
	
	return 0, 0
end

-- Function to set defense stats for a model
local function setDefenseStats(model, currentDefense, maxDefense)
	if not model then
		return
	end
	
	-- Clamp currentDefense to valid range
	currentDefense = math.max(0, math.min(currentDefense, maxDefense))
	
	-- Check if it's a player
	local player = Players:GetPlayerFromCharacter(model)
	if player and player:FindFirstChild("leaderstats") then
		local leaderstats = player.leaderstats
		
		local currentDefStat = leaderstats:FindFirstChild("CurrentDefense")
		if currentDefStat then
			currentDefStat.Value = currentDefense
		else
			-- Create CurrentDefense if it doesn't exist (shouldn't happen normally, but safety check)
			local newCurrentDef = Instance.new("NumberValue", leaderstats)
			newCurrentDef.Name = "CurrentDefense"
			newCurrentDef.Value = currentDefense
		end
	end
	
	-- Check if it's a mob (using attributes)
	if model:IsA("Model") then
		model:SetAttribute("CurrentDefense", currentDefense)
		if maxDefense then
			model:SetAttribute("MaxDefense", maxDefense)
		end
	end
end

-- Function to calculate damage with defense system and crit (for mobs)
-- Returns: damageToHealth, damageToDefense
local function calculateDamageWithDefense(rawDamage, attacker, target)
	if not target or not attacker then
		return rawDamage, 0
	end
	
	-- Check for mob crit (if attacker is a mob)
	local finalDamage = rawDamage
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	if not attackerPlayer and attacker:IsA("Model") then
		-- Attacker is a mob - check for crit
		local critRate = attacker:GetAttribute("CritRate") or 0
		local critMult = attacker:GetAttribute("CritMultiplier") or 150
		
		if critRate > 0 then
			-- Roll for crit
			local roll = math.random() * 100
			if roll < critRate then
				-- Crit hit! Multiply damage by crit multiplier (e.g., 150 = 1.5x)
				finalDamage = math.floor(rawDamage * (critMult / 100))
			end
		end
	end
	
	-- Check if target is a player and is blocking
	local targetPlayer = Players:GetPlayerFromCharacter(target)
	if targetPlayer then
		-- Check if blocking state function exists (defensive check)
		if _G.getPlayerBlockingState then
			local isBlocking = _G.getPlayerBlockingState(targetPlayer)
			if isBlocking then
				-- Determine player class to get block damage reduction
				local playerClass = nil
				local leaderstats = targetPlayer:FindFirstChild("leaderstats")
				if leaderstats then
					local classStat = leaderstats:FindFirstChild("Class")
					if classStat then
						playerClass = classStat.Value
					end
				end
				
				-- Get block damage reduction from config based on class
				local blockReduction = 0
				if playerClass == "Archer" and ServerConfigs.Archer then
					blockReduction = ServerConfigs.Archer.blockDamageReduction or 0
				elseif playerClass == "Samurai" and ServerConfigs.Samurai then
					blockReduction = ServerConfigs.Samurai.blockDamageReduction or 0
				elseif playerClass == "Brawler" and ServerConfigs.Brawler then
					blockReduction = ServerConfigs.Brawler.blockDamageReduction or 0
				elseif playerClass == "Knight" and ServerConfigs.Knight then
					blockReduction = ServerConfigs.Knight.blockDamageReduction or 0
				elseif playerClass == "Gladiator" and ServerConfigs.Gladiator then
					blockReduction = ServerConfigs.Gladiator.blockDamageReduction or 0
				end
				
				-- Apply block damage reduction (reduce damage by the percentage)
				-- Example: blockReduction = 0.5 means 50% reduction, so damage becomes 50% of original
				if blockReduction > 0 then
					finalDamage = math.floor(finalDamage * (1 - blockReduction))
				end
			end
		end
	end
	
	-- Get target's defense
	local currentDefense, maxDefense = getDefenseStats(target)
	
	-- Get attacker's defense penetration
	local defensePenetration = 0
	if attackerPlayer and attackerPlayer:FindFirstChild("leaderstats") then
		-- Attacker is a player - read from leaderstats
		local attackerStats = attackerPlayer.leaderstats
		if attackerStats:FindFirstChild("DefensePenetration") then
			defensePenetration = attackerStats.DefensePenetration.Value
		end
	elseif attacker:IsA("Model") then
		-- Attacker is a mob - read from attributes
		defensePenetration = attacker:GetAttribute("DefensePenetration") or 0
	end
	
	-- Calculate effective defense after penetration
	-- Defense penetrates defense at 1:1 ratio
	local effectiveDefense = math.max(0, currentDefense - defensePenetration)
	
	-- If target has defense, damage goes to defense first, then health
	local damageToDefense = 0
	local damageToHealth = 0
	
	if effectiveDefense > 0 then
		-- Defense absorbs damage
		if finalDamage <= effectiveDefense then
			-- All damage goes to defense
			damageToDefense = finalDamage
			damageToHealth = 0
		else
			-- Defense is depleted, rest goes to health
			damageToDefense = effectiveDefense
			damageToHealth = finalDamage - effectiveDefense
		end
	else
		-- No defense, all damage goes to health
		damageToHealth = finalDamage
		damageToDefense = 0
	end
	
	return damageToHealth, damageToDefense
end

-- Friendly fire configuration - separate controls for players and mobs
local PLAYER_FRIENDLY_FIRE = false -- Set to true to allow players to damage each other
local MOB_FRIENDLY_FIRE = false -- Set to true to allow mobs to damage each other

-- Function to check if a model is a player
local function isPlayer(model)
    return game:GetService("Players"):GetPlayerFromCharacter(model) ~= nil
end

-- Function to check if a model is a mob (has exclusion tags)
local function isMob(model)
    return HitboxExclusions.hasExcludedTag(model)
end

-- Function to check if damage should be applied
local function shouldApplyDamage(attacker, target)
    -- Don't damage self
    if attacker == target then
        return false
    end
    
    local attackerIsPlayer = isPlayer(attacker)
    local targetIsPlayer = isPlayer(target)
    local attackerIsMob = isMob(attacker)
    local targetIsMob = isMob(target)
    
    -- Player attacking another player
    if attackerIsPlayer and targetIsPlayer then
        return PLAYER_FRIENDLY_FIRE
    end
    
    -- Player attacking mob
    if attackerIsPlayer and targetIsMob then
        return true
    end
    
    -- Mob attacking player
    if attackerIsMob and targetIsPlayer then
        return true
    end
    
    -- Mob attacking mob
    if attackerIsMob and targetIsMob then
        return MOB_FRIENDLY_FIRE
    end
    
    -- Default: allow damage
    return true
end

-- Track the last player who damaged a mob so death handlers can reward XP
local function recordPlayerDamage(attacker, target)
	if not attacker or not target then
		return
	end

	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	if not attackerPlayer then
		return
	end

	-- Ignore player-vs-player hits
	if Players:GetPlayerFromCharacter(target) then
		return
	end

	-- Only record for models (mobs/NPCs)
	if not target:IsA("Model") then
		target = target:FindFirstAncestorOfClass("Model")
		if not target then
			return
		end
	end

	target:SetAttribute("LastDamagePlayerId", attackerPlayer.UserId)
	target:SetAttribute("LastDamagePlayerName", attackerPlayer.Name)
	target:SetAttribute("LastDamageTimestamp", os.clock())
end

-- Function to create damage flash effect using Highlight
local function createDamageFlash(model, duration)
    duration = duration or ServerConfigs.Hitbox.highlighting.damageFlash.duration
    
    -- Validate model exists
    if not model or not model.Parent then
        return
    end
    
    -- Get highlighting configuration
    local highlightConfig = ServerConfigs.Hitbox.highlighting.damageFlash
    
    -- Create a NEW highlight for EACH flash (don't reuse - each flash gets its own)
    local highlight = Instance.new("Highlight")
    highlight.Parent = model
    highlight.Name = "DamageFlash_" .. tostring(tick() * 1000) -- More unique name
    
    -- Apply configuration values
    highlight.FillColor = highlightConfig.fillColor
    highlight.FillTransparency = highlightConfig.fillTransparency
    highlight.OutlineColor = highlightConfig.outlineColor
    highlight.OutlineTransparency = highlightConfig.outlineTransparency
    
    -- Use Debris service for automatic cleanup - MOST RELIABLE method
    -- This will destroy the highlight after duration regardless of anything else
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

-- Shared helper to create floating number popups (damage, XP, etc.)
local function createFloatingNumber(model, text, visualConfig)
	if not model or not model.Parent or not visualConfig then
		return
	end

	local head = model:FindFirstChild("Head")
	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
	local attachPart = head or humanoidRootPart
	if not attachPart then
		return
	end

	local popupNamePrefix = visualConfig.namePrefix or "FloatingNumber"
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = popupNamePrefix .. "_" .. tostring(tick() * 1000)
	billboardGui.Size = UDim2.new(0, visualConfig.width or 200, 0, visualConfig.height or 100)

	local randomOffsetRange = visualConfig.randomOffsetX or 0
	local offsetX = (math.random() - 0.5) * 2 * randomOffsetRange
	local offsetY = visualConfig.offsetY or 2
	billboardGui.StudsOffset = Vector3.new(offsetX, offsetY, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboardGui.Parent = attachPart

	local duration = visualConfig.duration or 1
	Debris:AddItem(billboardGui, duration + 0.2)

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = visualConfig.backgroundTransparency ~= nil and visualConfig.backgroundTransparency or 1
	if visualConfig.backgroundColor then
		textLabel.BackgroundColor3 = visualConfig.backgroundColor
	end
	textLabel.Text = text
	textLabel.TextColor3 = visualConfig.textColor or Color3.new(1, 1, 1)
	textLabel.TextSize = visualConfig.textSize or 28
	textLabel.Font = visualConfig.font or Enum.Font.GothamBold

	local baseStrokeTransparency = visualConfig.strokeTransparency
	if baseStrokeTransparency == nil then
		baseStrokeTransparency = visualConfig.textStrokeTransparency
	end
	if baseStrokeTransparency == nil then
		baseStrokeTransparency = 0
	end

	local strokeColor = visualConfig.strokeColor or visualConfig.textStrokeColor or Color3.new(0, 0, 0)
	textLabel.TextStrokeColor3 = strokeColor
	textLabel.TextStrokeTransparency = baseStrokeTransparency

	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = billboardGui

	local startTime = tick()
	local initialOffset = billboardGui.StudsOffset
	local riseHeight = visualConfig.riseHeight or 3
	local fadeStart = visualConfig.fadeStart or (duration * 0.5)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not billboardGui or not billboardGui.Parent or not model or not model.Parent or not attachPart or not attachPart.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local elapsed = tick() - startTime
		if elapsed >= duration then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local progress = elapsed / duration
		billboardGui.StudsOffset = Vector3.new(
			initialOffset.X,
			initialOffset.Y + (riseHeight * progress),
			initialOffset.Z
		)

		if elapsed >= fadeStart then
			local fadeDuration = math.max(duration - fadeStart, 0.0001)
			local fadeProgress = math.min((elapsed - fadeStart) / fadeDuration, 1)
			textLabel.TextTransparency = fadeProgress
			textLabel.TextStrokeTransparency = math.min(baseStrokeTransparency + fadeProgress, 1)
		end
	end)

	task.delay(duration + 0.2, function()
		if connection then
			connection:Disconnect()
		end
	end)
end

-- Function to create damage number display above character head
-- Exported as global function so StatusAilmentHandler can use it
function _G.createDamageNumber(model, damage)
	local damageNumbersConfig = ServerConfigs.Hitbox.damageNumbers
	if not damageNumbersConfig or not damageNumbersConfig.enabled then
		return
	end

	if not model or not model.Parent then
		return
	end

	local clone = cloneConfig(damageNumbersConfig)
	clone.namePrefix = "DamageNumber"

	local damageValue = damage or 0
	local displayText = "-" .. tostring(math.floor(damageValue))
	createFloatingNumber(model, displayText, clone)
end

-- Function to create XP gain popup above the player's character
-- Accepts a Player instance, Model, or any descendant part of the player's character
function _G.createXpGainNumber(target, xpAmount)
	local xpConfig = ServerConfigs.Hitbox.xpNumbers
	if not xpConfig or not xpConfig.enabled then
		return
	end

	if not xpAmount or xpAmount <= 0 then
		return
	end

	local character = nil
	if typeof(target) == "Instance" then
		if target:IsA("Player") then
			character = target.Character
		elseif target:IsA("Model") then
			character = target
		else
			character = target:FindFirstAncestorOfClass("Model")
		end
	end

	if not character or not character.Parent then
		return
	end

	local clone = cloneConfig(xpConfig)
	clone.namePrefix = "XpGain"

	local prefix = clone.prefix or "+"
	local suffix = clone.suffix or " XP"
	local xpText = prefix .. tostring(math.floor(xpAmount)) .. suffix

	createFloatingNumber(character, xpText, clone)
end

-- Function to apply status ailments from hitbox config
-- @param model: Target model to apply ailment to
-- @param config: Hitbox config that may contain statusAilment field
local function applyStatusAilmentFromConfig(model, config)
	if not model or not config then return end
	
	-- Check if status ailment is configured
	local statusAilment = config.statusAilment
	if not statusAilment then return end
	
	-- Check for status immunity (LastChance buff) - only for players
	local targetPlayer = Players:GetPlayerFromCharacter(model)
	if targetPlayer then
		-- Check if function exists (defensive check)
		if _G.hasStatusImmunity then
			local hasImmunity = _G.hasStatusImmunity(targetPlayer)
			if hasImmunity then
				-- Player has status immunity, don't apply ailment
				return
			end
		end
	end
	
	-- Validate ailment type (accept lowercase string like "stun", "poison", etc.)
	local ailmentType = statusAilment.type
	if not ailmentType then return end
	
	-- Convert to lowercase for lookup
	local ailmentTypeLower = string.lower(ailmentType)
	
	-- Map to AilmentTypes constant (handles both "stun" and "STUN" input)
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
	
	if not ailmentTypeConstant then return end
	
	-- Build ailment config
	local ailmentConfig = {
		duration = statusAilment.duration,
		chance = statusAilment.chance or 100, -- Default 100% chance
		dps = statusAilment.dps,
		tickInterval = statusAilment.tickInterval,
		slowMultiplier = statusAilment.slowMultiplier,
		skipDefense = statusAilment.skipDefense or false -- If true, bypasses defense for DPS damage
	}
	
	-- Apply the ailment
	StatusAilmentHandler.apply(model, ailmentTypeConstant, ailmentConfig)
end

-- Function to apply lifesteal from hitbox config or active buffs
-- @param attacker: The attacker model (character) that will be healed
-- @param config: Hitbox config that may contain lifesteal field
-- @param totalDamage: Total damage dealt (damageToHealth + damageToDefense)
local function applyLifestealFromConfig(attacker, config, totalDamage)
	if not attacker or not config or not totalDamage or totalDamage <= 0 then return end
	
	-- Check if attacker is a player (for buff lifesteal)
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	
	-- Get lifesteal percentage from active buffs (BloodThirst) - only for players
	local buffLifestealPercentage = nil
	if attackerPlayer then
		-- Check if function exists (defensive check)
		if _G.getPlayerLifestealPercentage then
			buffLifestealPercentage = _G.getPlayerLifestealPercentage(attackerPlayer)
		end
	end
	
	-- Check if lifesteal is configured in hitbox config
	local lifesteal = config.lifesteal
	
	-- If no lifesteal from config or buff, return
	if not lifesteal and not buffLifestealPercentage then return end
	
	-- Get attacker's humanoid
	local attackerHumanoid = attacker:FindFirstChildOfClass("Humanoid")
	if not attackerHumanoid or attackerHumanoid.Health <= 0 then return end
	
	-- Calculate healing amount
	local healingAmount = 0
	
	-- Percentage-based lifesteal from hitbox config (e.g., 0.5 = 50% of damage dealt)
	-- Works for both players and mobs
	if lifesteal and lifesteal.percentage then
		healingAmount = healingAmount + (totalDamage * lifesteal.percentage)
	end
	
	-- Percentage-based lifesteal from active buff (BloodThirst) - only for players
	if buffLifestealPercentage then
		healingAmount = healingAmount + (totalDamage * buffLifestealPercentage)
	end
	
	-- Flat amount lifesteal from hitbox config (e.g., 10 = flat 10 HP healed)
	-- Works for both players and mobs
	if lifesteal and lifesteal.flatAmount then
		healingAmount = healingAmount + lifesteal.flatAmount
	end
	
	-- Round to integer
	healingAmount = math.floor(healingAmount)
	
	-- Apply healing if amount is positive
	if healingAmount > 0 then
		-- Clamp healing to not exceed max health
		local currentHealth = attackerHumanoid.Health
		local maxHealth = attackerHumanoid.MaxHealth
		local newHealth = math.min(currentHealth + healingAmount, maxHealth)
		attackerHumanoid.Health = newHealth
	end
end

-- Function to apply Madness passive stun chance from Brawler passive
-- @param attacker: The attacker model (character) that has Madness passive
-- @param target: The target model to potentially stun
local function applyMadnessPassiveStun(attacker, target)
	if not attacker or not target or not target.Parent then return end
	
	-- Check if attacker is a player (for passive stun)
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	if not attackerPlayer then return end
	
	-- Get Madness stun chance from passive (only for Brawler players)
	local stunChance = nil
	if _G.getBrawlerMadnessStunChance then
		stunChance = _G.getBrawlerMadnessStunChance(attackerPlayer)
	end
	
	-- If no Madness passive active, return
	if not stunChance or stunChance <= 0 then return end
	
	-- Get stun duration from config
	local stunDuration = ServerConfigs.BrawlerPassives.Madness.stunDuration or 2.0
	
	-- Apply stun with chance
	StatusAilmentHandler.apply(target, StatusAilmentHandler.AilmentTypes.STUN, {
		duration = stunDuration,
		chance = stunChance
	})
end

-- Function to apply Immobilize passive stun chance from Archer passive
-- @param attacker: The attacker model (character) that has Immobilize passive
-- @param target: The target model to potentially stun
local function applyImmobilizePassiveStun(attacker, target)
	if not attacker or not target or not target.Parent then return end
	
	-- Check if attacker is a player (for passive stun)
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	if not attackerPlayer then return end
	
	-- Get Immobilize stun chance from passive (only for Archer players)
	local stunChance = nil
	if _G.getArcherImmobilizeStunChance then
		stunChance = _G.getArcherImmobilizeStunChance(attackerPlayer)
	end
	
	-- If no Immobilize passive active, return
	if not stunChance or stunChance <= 0 then return end
	
	-- Get stun duration from config
	local stunDuration = ServerConfigs.ArcherPassives.Immobilize.stunDuration or 2.0
	
	-- Apply stun with chance
	StatusAilmentHandler.apply(target, StatusAilmentHandler.AilmentTypes.STUN, {
		duration = stunDuration,
		chance = stunChance
	})
end

-- Function to apply knockback to mobs when hit by players
local function applyKnockback(attacker, target)
	-- Only apply knockback when player attacks mob
	if not isPlayer(attacker) or not isMob(target) then
		return
	end
	
	-- Check if knockback is enabled
	local knockbackConfig = ServerConfigs.Hitbox.knockback
	if not knockbackConfig or not knockbackConfig.enabled then
		return
	end
	
	-- Get target model's HumanoidRootPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return
	end
	
	-- Get target's facing direction (reverse it for knockback)
	local targetFacing = targetRoot.CFrame.LookVector
	local knockbackDirection = -targetFacing -- Reverse the facing direction
	local horizontalDirection = Vector3.new(knockbackDirection.X, 0, knockbackDirection.Z)
	local magnitude = horizontalDirection.Magnitude
	
	if magnitude > 0.1 then
		-- Normalize horizontal direction
		horizontalDirection = horizontalDirection / magnitude
		
		-- Calculate knockback velocity (horizontal only)
		local knockbackVel = horizontalDirection * knockbackConfig.force
		
		-- Get humanoid
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		
		-- Temporarily disable AI movement
		local originalPlatformStand = humanoid.PlatformStand
		humanoid.PlatformStand = true
		
		-- Make sure part is not anchored
		if targetRoot.Anchored then
			targetRoot.Anchored = false
		end
		
		-- Simply apply horizontal velocity (no collision floors, no position corrections)
		local currentVel = targetRoot.AssemblyLinearVelocity
		local horizontalVel = Vector3.new(knockbackVel.X, 0, knockbackVel.Z)
		
		-- Apply velocity - keep Y unchanged, only push horizontally
		targetRoot.AssemblyLinearVelocity = Vector3.new(currentVel.X + horizontalVel.X, currentVel.Y, currentVel.Z + horizontalVel.Z)
		
		-- Restore AI movement after short delay
		task.delay(0.3, function()
			if humanoid and humanoid.Parent and targetRoot and targetRoot.Parent then
				humanoid.PlatformStand = originalPlatformStand
			end
		end)
	end
end

-- ========================================
-- FRIENDLY FIRE CONTROL FUNCTIONS
-- ========================================

-- Function to set player friendly fire setting
function _G.setPlayerFriendlyFire(enabled)
    PLAYER_FRIENDLY_FIRE = enabled
end

-- Function to get player friendly fire setting
function _G.getPlayerFriendlyFire()
    return PLAYER_FRIENDLY_FIRE
end

-- Function to set mob friendly fire setting
function _G.setMobFriendlyFire(enabled)
    MOB_FRIENDLY_FIRE = enabled
end

-- Function to get mob friendly fire setting
function _G.getMobFriendlyFire()
    return MOB_FRIENDLY_FIRE
end

-- Function to set both friendly fire settings at once (for convenience)
function _G.setFriendlyFire(playerEnabled, mobEnabled)
    if playerEnabled ~= nil then
        PLAYER_FRIENDLY_FIRE = playerEnabled
    end
    if mobEnabled ~= nil then
        MOB_FRIENDLY_FIRE = mobEnabled
    end
end

-- Function to get both friendly fire settings
function _G.getFriendlyFire()
    return {
        player = PLAYER_FRIENDLY_FIRE,
        mob = MOB_FRIENDLY_FIRE
    }
end

-- ========================================
-- GLOBAL FUNCTIONS
-- ========================================

--[[
	STATIC HITBOX - Fixed position, one-time damage
	
	SPECIALTY: Damages all enemies in area ONCE when created
	USE CASE: Slash attacks, ground pounds, instant AoE damage
	
	EXAMPLE:
	_G.createStaticHitbox({
		attachTo = root,                    -- BasePart to use for position (OR use cframe)
		cframe = CFrame.new(0, 10, 0),      -- Direct CFrame position (OR use attachTo)
		offset = CFrame.new(0, 0, -5),      -- CFrame offset from attachTo (optional)
		size = Vector3.new(10, 10, 10),     -- Hitbox dimensions (REQUIRED)
		damage = 25,                        -- Damage to apply (REQUIRED)
		character = character,              -- Player's character to exclude (REQUIRED)
		name = "Slash",                     -- Hitbox name for debugging (REQUIRED)
		showVisual = true,                  -- Show debug visual (optional, default: true)
		visualColor = Color3.new(1, 0, 0),  -- Debug visual color (REQUIRED)
		visualDuration = 0.5,               -- How long visual stays (optional, default: 0.5)
		delay = 0,                          -- Delay before activation (optional, default: 0)
		statusAilment = {...},              -- Optional: Status ailment config (stun, poison, etc.)
		lifesteal = {                       -- Optional: Lifesteal config (heal attacker when dealing damage)
			percentage = 0.5,               -- Heal for % of damage dealt (e.g., 0.5 = 50%)
			flatAmount = 10                 -- Optional: Flat HP healed per hit
		}
	})
]]
function _G.createStaticHitbox(config)
	-- config: cframe OR attachTo, size, damage, character, name, showVisual, visualColor, offset, delay, visualDuration, actionType, classType
	local delay = getScaledDelay(config.delay, config.actionType, config.classType)
	
	task.delay(delay, function()
		local cframe = config.cframe
		local attachTo = config.attachTo
		local offset = config.offset
		if not offset then offset = CFrame.new(0, 0, 0) end
		
		local size = config.size
		local damage = config.damage
		local character = config.character
		local name = config.name
		local showVisual = config.showVisual
		if showVisual == nil then showVisual = true end
		
		local visualColor = config.visualColor
		local visualDuration = config.visualDuration
		if not visualDuration then visualDuration = 0.5 end
		visualDuration = getScaledDelay(visualDuration, config.actionType, config.classType)
		
		-- If attachTo is provided, use its CFrame with offset
		if attachTo and not cframe then
			cframe = attachTo.CFrame * offset
		elseif not cframe then
			return
		end
		
		-- Create visual
		local visual = nil
		local visualTransparency = config.visualTransparency
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.CFrame = cframe
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = visualTransparency ~= nil and visualTransparency or HITBOX_CONFIG.transparency
			visual.Color = visualColor
			visual.Name = name .. "HitboxVisual"
			visual.Parent = workspace
			
			game:GetService("Debris"):AddItem(visual, visualDuration)
		end
		
		-- Check for hits once
		local regionParts = workspace:GetPartBoundsInBox(cframe, size)
		local hitTargets = {}
		
		for _, part in regionParts do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and model ~= character then
				local humanoid = model:FindFirstChild("Humanoid")
				
				if humanoid and not hitTargets[humanoid] then
					-- Check if damage should be applied using new targeting system
					if shouldApplyDamage(character, model) then
						hitTargets[humanoid] = true
						
						recordPlayerDamage(character, model)
						
						-- Check if target is a player and if they're invincible (during skill/ult)
						local targetPlayer = Players:GetPlayerFromCharacter(model)
						local isInvincible = targetPlayer and _G.isPlayerInvincible and _G.isPlayerInvincible(targetPlayer)
						
						-- Calculate damage with defense system
						local damageToHealth, damageToDefense = calculateDamageWithDefense(damage, character, model)
						
						-- Skip damage if player is invincible (freezes health)
						if not isInvincible then
							-- Apply damage to health
							if damageToHealth > 0 then
								humanoid:TakeDamage(damageToHealth)
							end
							
							-- Apply damage to defense
							if damageToDefense > 0 then
								local currentDef, maxDef = getDefenseStats(model)
								setDefenseStats(model, currentDef - damageToDefense, maxDef)
							end
							
							-- Create damage number display (show actual damage applied, which includes block reduction)
							-- Only show damage number if not invincible
							_G.createDamageNumber(model, damageToHealth + damageToDefense)
						end
						
						-- Apply knockback to mobs
						applyKnockback(character, model)
						
						-- Create damage flash effect on the target
						createDamageFlash(model, ServerConfigs.Hitbox.highlighting.damageFlash.duration)
						
						-- Apply status ailments if configured (optional)
						applyStatusAilmentFromConfig(model, config)
						
						-- Apply Madness passive stun chance (Brawler passive)
						applyMadnessPassiveStun(character, model)
						
						-- Apply Immobilize passive stun chance (Archer passive)
						applyImmobilizePassiveStun(character, model)
						
						-- Apply lifesteal if configured (optional)
						applyLifestealFromConfig(character, config, damageToHealth + damageToDefense)
					end
				end
			end
		end
	end)
end

--[[
	STATIC DOT HITBOX - Fixed position, damage over time
	
	SPECIALTY: Damages ALL enemies in area REPEATEDLY every X seconds
	USE CASE: Fire fields, poison clouds, damage zones
	DURATION: Lasts until attachTo part is destroyed OR duration expires (if duration is specified)
	
	EXAMPLE:
	_G.createStaticDOTHitbox({
		attachTo = vfxPart,                 -- BasePart to track lifetime (REQUIRED for auto-cleanup)
		cframe = CFrame.new(0, 10, 0),      -- Direct CFrame position (OR use attachTo)
		offset = CFrame.new(0, 0, 0),       -- CFrame offset from attachTo (optional)
		size = Vector3.new(15, 15, 15),     -- Hitbox dimensions (REQUIRED)
		damage = 5,                         -- Damage PER TICK (REQUIRED)
		damageTickTime = 0.5,               -- Seconds between damage ticks (optional, default: 0.5)
		duration = 4.0,                     -- Optional: Total duration in seconds (if not specified, lasts until attachTo is destroyed)
		character = character,              -- Player's character to exclude (REQUIRED)
		name = "FireField",                 -- Hitbox name for debugging (REQUIRED)
		showVisual = true,                  -- Show debug visual (optional, default: true)
		visualColor = Color3.new(1, 0.5, 0),-- Debug visual color (REQUIRED)
		delay = 0,                          -- Delay before activation (optional, default: 0)
	})
]]
function _G.createStaticDOTHitbox(config)
	-- config: cframe OR attachTo, size, damage, character, name, showVisual, visualColor, offset, delay, damageTickTime, duration, actionType, classType
	local delay = getScaledDelay(config.delay, config.actionType, config.classType)
	
	task.delay(delay, function()
		local cframe = config.cframe
		local attachTo = config.attachTo
		local offset = config.offset
		if not offset then offset = CFrame.new(0, 0, 0) end
		
		local size = config.size
		local damage = config.damage
		local character = config.character
		local name = config.name
		local showVisual = config.showVisual
		if showVisual == nil then showVisual = true end
		
		local visualColor = config.visualColor
		local damageTickTime = config.damageTickTime
		-- damageTickTime must be provided in config
		if not damageTickTime or damageTickTime <= 0 then
			warn("[createStaticDOTHitbox] ERROR: damageTickTime is invalid! Value:", damageTickTime, "Defaulting to 0.5")
			damageTickTime = 0.5
		else
			local originalTickTime = damageTickTime
			damageTickTime = getScaledDelay(damageTickTime, config.actionType, config.classType)
			if not damageTickTime or damageTickTime <= 0 then
				warn("[createStaticDOTHitbox] ERROR: damageTickTime became invalid after scaling! Original:", originalTickTime, "Scaled:", damageTickTime, "Defaulting to 0.5")
				damageTickTime = 0.5
			end
		end
		
		-- If attachTo is provided, use its CFrame with offset
		if attachTo and not cframe then
			cframe = attachTo.CFrame * offset
		elseif not cframe then
			return
		end
		
		-- Create visual
		local visual = nil
		local visualTransparency = config.visualTransparency
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.CFrame = cframe
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = visualTransparency ~= nil and visualTransparency or HITBOX_CONFIG.transparency
			visual.Color = visualColor
			visual.Name = name .. "DOTHitboxVisual"
			visual.Parent = workspace
		end
		
		-- Track last tick time - initialize BEFORE connection (matches old working version)
		local lastTickTime = tick()
		local startTime = tick() -- Track when hitbox started (for duration check)
		local active = true
		local duration = config.duration -- Optional duration limit
		
		-- Function to get current hitbox position with offset
		local function getCurrentHitboxCFrame()
			if attachTo and attachTo.Parent then
				return attachTo.CFrame * offset
			else
				return cframe
			end
		end
		
		-- Initial damage tick
		local function damageInArea()
			if not active then return end
			
			-- If attachTo exists, check if it's still valid
			if attachTo and (not attachTo.Parent) then
				active = false
				if visual then
					visual:Destroy()
				end
				return
			end
			
			-- Get current hitbox position with offset
			local currentCFrame = getCurrentHitboxCFrame()
			local regionParts = workspace:GetPartBoundsInBox(currentCFrame, size)
			
			-- Track which humanoids have been hit this tick to prevent multiple damage per tick
			local hitHumanoids = {}
			
			for _, part in regionParts do
				local model = part:FindFirstAncestorOfClass("Model")
				if model and model ~= character then
					local humanoid = model:FindFirstChild("Humanoid")
					
					if humanoid and not hitHumanoids[humanoid] then
						-- Check if damage should be applied using new targeting system
						if shouldApplyDamage(character, model) then
							-- Mark this humanoid as hit for this tick
							hitHumanoids[humanoid] = true
							
							recordPlayerDamage(character, model)
							
							-- Check if target is a player and if they're invincible (during skill/ult)
							local targetPlayer = Players:GetPlayerFromCharacter(model)
							local isInvincible = targetPlayer and _G.isPlayerInvincible and _G.isPlayerInvincible(targetPlayer)
							
							-- Calculate damage with defense system
							local damageToHealth, damageToDefense = calculateDamageWithDefense(damage, character, model)
							
							-- Skip damage if player is invincible (freezes health)
							if not isInvincible then
								-- Apply damage to health
								if damageToHealth > 0 then
									humanoid:TakeDamage(damageToHealth)
								end
								
								-- Apply damage to defense
								if damageToDefense > 0 then
									local currentDef, maxDef = getDefenseStats(model)
									setDefenseStats(model, currentDef - damageToDefense, maxDef)
								end
								
								-- Create damage number display (show actual damage applied, which includes block reduction)
								-- Only show damage number if not invincible
								_G.createDamageNumber(model, damageToHealth + damageToDefense)
							end
							
							-- Apply knockback to mobs
							applyKnockback(character, model)
							
							-- Create damage flash effect on the target
							createDamageFlash(model, ServerConfigs.Hitbox.highlighting.damageFlash.duration)
							
							-- Apply status ailments if configured (optional)
							applyStatusAilmentFromConfig(model, config)
							
							-- Apply lifesteal if configured (optional)
							applyLifestealFromConfig(character, config, damageToHealth + damageToDefense)
						end
					end
				end
			end
		end
		
		-- Apply damage every tick
		local connection
		connection = RunService.Heartbeat:Connect(function()
			-- Stop if attachTo part destroyed
			if attachTo and not attachTo.Parent then
				active = false
				connection:Disconnect()
				if visual then
					visual:Destroy()
				end
				return
			end
			
			-- Check if duration has expired (if duration is specified)
			if duration and duration > 0 then
				local currentTime = tick()
				local elapsed = currentTime - startTime
				if elapsed >= duration then
					-- Duration expired, stop hitbox
					active = false
					connection:Disconnect()
					if visual then
						visual:Destroy()
					end
					return
				end
			end
			
			-- Update visual position to follow attachTo part with offset
			if visual and attachTo and attachTo.Parent then
				visual.CFrame = getCurrentHitboxCFrame()
			end
			
			local currentTime = tick()
			local timeSinceLastTick = currentTime - lastTickTime
			
			-- Check if it's time for next damage tick (matches old working version exactly)
			if timeSinceLastTick >= damageTickTime then
				-- Before damaging, check once more if part still exists
				if attachTo and not attachTo.Parent then
					active = false
					connection:Disconnect()
					if visual then
						visual:Destroy()
					end
					return
				end
				
				-- Check if duration has expired (if duration is specified)
				if duration and duration > 0 then
					local elapsed = currentTime - startTime
					if elapsed >= duration then
						-- Duration expired, stop hitbox
						active = false
						connection:Disconnect()
						if visual then
							visual:Destroy()
						end
						return
					end
				end
				
				damageInArea()
				lastTickTime = currentTime
			end
		end)
		
		-- Initial damage tick - called AFTER connection is created (matches old working version)
		damageInArea()
	end)
end

--[[
	TRAVELING HITBOX - Follows a moving part, one-time damage per enemy
	
	SPECIALTY: Moves with attachTo part, damages each enemy ONCE
	USE CASE: Projectiles, moving blades, dash attacks
	DURATION: Lasts until attachTo part is destroyed
	
	EXAMPLE:
	_G.createTravelingHitbox({
		attachTo = bladePart,               -- BasePart to follow (REQUIRED)
		offset = CFrame.new(0, 0, 0),       -- CFrame offset from attachTo (optional)
		size = Vector3.new(8, 30, 8),       -- Hitbox dimensions (REQUIRED)
		damage = 25,                        -- Damage to apply (REQUIRED)
		character = character,              -- Player's character to exclude (REQUIRED)
		name = "Wakizashi",                 -- Hitbox name for debugging (REQUIRED)
		showVisual = true,                  -- Show debug visual (optional, default: true)
		visualColor = Color3.new(0, 0.5, 1),-- Debug visual color (REQUIRED)
		delay = 0.2,                        -- Delay before activation (optional, default: 0)
	})
]]
function _G.createTravelingHitbox(config)
	-- config: attachTo (BasePart), size, damage, character, name, showVisual, visualColor, offset, delay, actionType, classType
	local delay = getScaledDelay(config.delay, config.actionType, config.classType)
	
	task.delay(delay, function()
		local attachTo = config.attachTo
		local offset = config.offset
		if not offset then offset = CFrame.new(0, 0, 0) end
		
		local size = config.size
		local damage = config.damage
		local character = config.character
		local name = config.name
		local showVisual = config.showVisual
		if showVisual == nil then showVisual = true end
		
		local visualColor = config.visualColor
		
		if not attachTo then
			return
		end
		
		local hitTargets = {}
		
		-- Create visual
		local visual = nil
		local visualTransparency = config.visualTransparency
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = visualTransparency ~= nil and visualTransparency or HITBOX_CONFIG.transparency
			visual.Color = visualColor
			visual.Name = name .. "HitboxVisual"
			visual.Parent = workspace
		end
		
		-- Track hitbox with part (lasts until part is destroyed)
		local connection
		connection = RunService.Heartbeat:Connect(function()
			-- Stop if part destroyed
			if not attachTo or not attachTo.Parent then
				connection:Disconnect()
				if visual then
					visual:Destroy()
				end
				return
			end
			
			-- Calculate CFrame with offset
			local hitboxCFrame = attachTo.CFrame * offset
			
			-- Update visual position to match attached part with offset
			if visual then
				visual.CFrame = hitboxCFrame
			end
			
			-- Check for hits at current position
			local regionParts = workspace:GetPartBoundsInBox(hitboxCFrame, size)
			
			for _, part in regionParts do
				local model = part:FindFirstAncestorOfClass("Model")
				if model and model ~= character then
					local humanoid = model:FindFirstChild("Humanoid")
					
					if humanoid and not hitTargets[humanoid] then
						-- Check if damage should be applied using new targeting system
						if shouldApplyDamage(character, model) then
							hitTargets[humanoid] = true
							
							recordPlayerDamage(character, model)
							
							-- Check if target is a player and if they're invincible (during skill/ult)
							local targetPlayer = Players:GetPlayerFromCharacter(model)
							local isInvincible = targetPlayer and _G.isPlayerInvincible and _G.isPlayerInvincible(targetPlayer)
							
							-- Calculate damage with defense system
							local damageToHealth, damageToDefense = calculateDamageWithDefense(damage, character, model)
							
							-- Skip damage if player is invincible (freezes health)
							if not isInvincible then
								-- Apply damage to health
								if damageToHealth > 0 then
									humanoid:TakeDamage(damageToHealth)
								end
								
								-- Apply damage to defense
								if damageToDefense > 0 then
									local currentDef, maxDef = getDefenseStats(model)
									setDefenseStats(model, currentDef - damageToDefense, maxDef)
								end
								
								-- Create damage number display (show actual damage applied, which includes block reduction)
								-- Only show damage number if not invincible
								_G.createDamageNumber(model, damageToHealth + damageToDefense)
							end
							
							-- Apply knockback to mobs
							applyKnockback(character, model)
							
							-- Create damage flash effect on the target
							createDamageFlash(model, ServerConfigs.Hitbox.highlighting.damageFlash.duration)
							
							-- Apply status ailments if configured (optional)
							applyStatusAilmentFromConfig(model, config)
							
							-- Apply lifesteal if configured (optional)
							applyLifestealFromConfig(character, config, damageToHealth + damageToDefense)
						end
					end
				end
			end
		end)
	end)
end

--[[
	TRAVELING DOT HITBOX - Follows a moving part, damage over time
	
	SPECIALTY: Moves with attachTo part, damages enemies REPEATEDLY while in range
	USE CASE: Homing poison clouds, traveling fireballs, moving damage zones
	DURATION: Lasts until attachTo part is destroyed
	
	EXAMPLE:
	_G.createTravelingDOTHitbox({
		attachTo = cloudPart,                 -- BasePart to follow (REQUIRED)
		offset = CFrame.new(0, 0, 0),        -- CFrame offset from attachTo (optional)
		size = Vector3.new(15, 15, 15),      -- Hitbox dimensions (REQUIRED)
		damage = 10,                         -- Damage PER TICK (REQUIRED)
		damageTickTime = 0.5,                -- Seconds between damage ticks (REQUIRED)
		character = character,               -- Player's character to exclude (REQUIRED)
		name = "PoisonCloud",                -- Hitbox name for debugging (REQUIRED)
		showVisual = true,                   -- Show debug visual (optional, default: true)
		visualColor = Color3.new(0, 1, 0),  -- Debug visual color (REQUIRED)
		delay = 0,                           -- Delay before activation (optional, default: 0)
	})
]]
function _G.createTravelingDOTHitbox(config)
	-- config: attachTo (BasePart), size, damage, character, name, showVisual, visualColor, offset, delay, damageTickTime, actionType, classType
	local delay = getScaledDelay(config.delay, config.actionType, config.classType)
	
	task.delay(delay, function()
		local attachTo = config.attachTo
		local offset = config.offset
		if not offset then offset = CFrame.new(0, 0, 0) end
		
		local size = config.size
		local damage = config.damage
		local character = config.character
		local name = config.name
		local showVisual = config.showVisual
		if showVisual == nil then showVisual = true end
		
		local visualColor = config.visualColor
		local damageTickTime = config.damageTickTime
		-- damageTickTime must be provided in config
		damageTickTime = getScaledDelay(damageTickTime, config.actionType, config.classType)
		
		if not attachTo then
			return
		end
		
		-- Create visual
		local visual = nil
		local visualTransparency = config.visualTransparency
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = visualTransparency ~= nil and visualTransparency or HITBOX_CONFIG.transparency
			visual.Color = visualColor
			visual.Name = name .. "TravelingDOTHitboxVisual"
			visual.Parent = workspace
		end
		
		-- Track last tick time
		local lastTickTime = tick()
		local active = true
		
		-- Function to apply damage at current position
		local function damageInArea()
			if not active then return end
			
			-- If attachTo exists, check if it's still valid
			if attachTo and (not attachTo.Parent) then
				active = false
				if visual then
					visual:Destroy()
				end
				return
			end
			
			-- Get current hitbox position with offset
			local hitboxCFrame = attachTo.CFrame * offset
			local regionParts = workspace:GetPartBoundsInBox(hitboxCFrame, size)
			
			-- Track which humanoids have been hit this tick to prevent multiple damage per tick
			local hitHumanoids = {}
			
			for _, part in regionParts do
				local model = part:FindFirstAncestorOfClass("Model")
				if model and model ~= character then
					local humanoid = model:FindFirstChild("Humanoid")
					
					if humanoid and not hitHumanoids[humanoid] then
						-- Check if damage should be applied using new targeting system
						if shouldApplyDamage(character, model) then
							-- Mark this humanoid as hit for this tick
							hitHumanoids[humanoid] = true
							
							-- Check if target is a player and if they're invincible (during skill/ult)
							local targetPlayer = Players:GetPlayerFromCharacter(model)
							local isInvincible = targetPlayer and _G.isPlayerInvincible and _G.isPlayerInvincible(targetPlayer)
							
							-- Calculate damage with defense system
							local damageToHealth, damageToDefense = calculateDamageWithDefense(damage, character, model)
							
							-- Skip damage if player is invincible (freezes health)
							if not isInvincible then
								-- Apply damage to health
								if damageToHealth > 0 then
									humanoid:TakeDamage(damageToHealth)
								end
								
								-- Apply damage to defense
								if damageToDefense > 0 then
									local currentDef, maxDef = getDefenseStats(model)
									setDefenseStats(model, currentDef - damageToDefense, maxDef)
								end
								
								-- Create damage number display (show actual damage applied, which includes block reduction)
								-- Only show damage number if not invincible
								_G.createDamageNumber(model, damageToHealth + damageToDefense)
							end
							
							-- Apply knockback to mobs
							applyKnockback(character, model)
							
							-- Create damage flash effect on the target
							createDamageFlash(model, ServerConfigs.Hitbox.highlighting.damageFlash.duration)
							
							-- Apply status ailments if configured (optional)
							applyStatusAilmentFromConfig(model, config)
							
							-- Apply lifesteal if configured (optional)
							applyLifestealFromConfig(character, config, damageToHealth + damageToDefense)
						end
					end
				end
			end
		end
		
		-- Apply damage every tick
		local connection
		connection = RunService.Heartbeat:Connect(function()
			-- Stop if attachTo part destroyed
			if attachTo and not attachTo.Parent then
				active = false
				connection:Disconnect()
				if visual then
					visual:Destroy()
				end
				return
			end
			
			-- Update visual position to follow attachTo part with offset
			if visual and attachTo and attachTo.Parent then
				visual.CFrame = attachTo.CFrame * offset
			end
			
			local currentTime = tick()
			local timeSinceLastTick = currentTime - lastTickTime
			
			-- Check if it's time for next damage tick
			if timeSinceLastTick >= damageTickTime then
				-- Before damaging, check once more if part still exists
				if attachTo and not attachTo.Parent then
					active = false
					connection:Disconnect()
					if visual then
						visual:Destroy()
					end
					return
				end
				
				damageInArea()
				lastTickTime = currentTime
			end
		end)
		
		-- Initial damage tick
		damageInArea()
	end)
end

--[[
	PROJECTILE HITBOX - Separate visual and hitbox parts with different speeds (Archer arrows)
	
	SPECIALTY: Visual part moves at one speed, hitbox detection at another speed
	USE CASE: Archer arrows where visual needs to align with hit detection at different speeds
	DURATION: Lasts until arrow stops or hits something
	
	EXAMPLE:
	_G.createProjectileHitbox({
		visualPart = arrowPart,             -- Visual part (the actual arrow) (REQUIRED)
		direction = shootDirection,         -- Direction vector to move (REQUIRED)
		size = Vector3.new(6, 6, 6),        -- Hitbox size (REQUIRED)
		damage = 20,                        -- Damage to apply (REQUIRED)
		character = character,              -- Player's character to exclude (REQUIRED)
		name = "NormalArrow",               -- Hitbox name for debugging (REQUIRED)
		visualSpeed = 100,                  -- Speed of visual part (optional)
		hitboxSpeed = 80,                   -- Speed of hitbox detection (optional)
		delay = 0,                          -- Delay before activation (optional)
		anchorDelay = 0.03,                 -- Delay before anchoring after hit (optional)
		showVisual = true,                  -- Show debug visual (optional, default: true)
		visualColor = Color3.new(0, 1, 0), -- Debug visual color (optional)
		preventPhysicsPush = true,          -- Prevent physics interactions (optional, default: true)
	})
]]
function _G.createProjectileHitbox(config)
	local visualPart = config.visualPart
	local direction = config.direction
	local size = config.size
	local damage = config.damage
	local character = config.character
	local name = config.name
	local visualSpeed = config.visualSpeed or 100
	local hitboxSpeed = config.hitboxSpeed
	local delay = config.delay
	local anchorDelay = config.anchorDelay
	local showVisual = config.showVisual
	if showVisual == nil then showVisual = true end
	local visualColor = config.visualColor or Color3.new(0, 1, 0) -- Green for projectiles
	local preventPhysicsPush = config.preventPhysicsPush ~= false -- Default true

	if not visualPart or not direction then
		return
	end

	-- Make visual part non-physical if enabled
	if preventPhysicsPush then
		visualPart.CanCollide = false
		visualPart.CanQuery = false
		visualPart.CanTouch = false
	end

	-- Apply visual speed to the visual part
	local visualBodyVelocity = Instance.new("BodyVelocity")
	visualBodyVelocity.Velocity = direction * visualSpeed
	visualBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	visualBodyVelocity.Parent = visualPart

	-- Create separate invisible hitbox part that moves at hitbox speed
	local hitboxPart = Instance.new("Part")
	hitboxPart.Name = name .. "Hitbox"
	hitboxPart.Size = Vector3.new(1, 1, 1) -- Small part for precise collision
	hitboxPart.Anchored = false
	hitboxPart.CanCollide = false
	hitboxPart.CanQuery = false
	hitboxPart.CanTouch = false
	hitboxPart.Transparency = 1 -- Completely invisible
	hitboxPart.Parent = workspace

	-- Position hitbox at same location as visual
	hitboxPart.CFrame = visualPart.CFrame

	-- Apply hitbox speed to the separate hitbox part
	local hitboxBodyVelocity = Instance.new("BodyVelocity")
	hitboxBodyVelocity.Velocity = direction * hitboxSpeed
	hitboxBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	hitboxBodyVelocity.Parent = hitboxPart

	-- Create visual debug hitbox (using HITBOX_CONFIG.transparency for consistency)
	local visual = nil
	local visualTransparency = config.visualTransparency
	if showVisual then
		visual = Instance.new("Part")
		visual.Size = size
		visual.Anchored = true
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.Material = Enum.Material.Neon
		visual.Transparency = visualTransparency ~= nil and visualTransparency or HITBOX_CONFIG.transparency -- Use unified transparency setting
		visual.Color = visualColor
		visual.Name = name .. "ProjectileHitboxVisual"
		visual.Parent = workspace
	end

	-- Start hitbox detection after delay
	task.delay(delay, function()
		local hitTargets = {}
		local projectileStopped = false

		-- Track hitbox part for collisions
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if projectileStopped then
				connection:Disconnect()
				if visual then visual:Destroy() end
				return
			end

			-- Stop if either part is destroyed
			if not visualPart or not visualPart.Parent or not hitboxPart or not hitboxPart.Parent then
				projectileStopped = true
				connection:Disconnect()
				if visual then visual:Destroy() end
				if hitboxPart then hitboxPart:Destroy() end
				return
			end

			-- Update visual position to match hitbox
			if visual then
				visual.CFrame = hitboxPart.CFrame
			end

			-- Check for hits at hitbox's current position
			local regionParts = workspace:GetPartBoundsInBox(hitboxPart.CFrame, size)
			local hitSomething = false

			for _, part in regionParts do
				-- Skip the hitbox itself, visual part, and character parts
				if part ~= hitboxPart and part ~= visualPart and not part:IsDescendantOf(character) then
					local model = part:FindFirstAncestorOfClass("Model")
					if model and model ~= character then
						local humanoid = model:FindFirstChild("Humanoid")

						-- Check for enemy hit (only collide with living humanoids)
						if humanoid and not hitTargets[humanoid] and humanoid.Health > 0 then
							-- Check if damage should be applied using new targeting system
							if shouldApplyDamage(character, model) then
								hitTargets[humanoid] = true
								
								recordPlayerDamage(character, model)
								
								-- Check if target is a player and if they're invincible (during skill/ult)
								local targetPlayer = Players:GetPlayerFromCharacter(model)
								local isInvincible = targetPlayer and _G.isPlayerInvincible and _G.isPlayerInvincible(targetPlayer)
								
								-- Calculate damage with defense system
								local damageToHealth, damageToDefense = calculateDamageWithDefense(damage, character, model)
								
								-- Skip damage if player is invincible (freezes health)
								if not isInvincible then
									-- Apply damage to health
									if damageToHealth > 0 then
										humanoid:TakeDamage(damageToHealth)
									end
									
									-- Apply damage to defense
									if damageToDefense > 0 then
										local currentDef, maxDef = getDefenseStats(model)
										setDefenseStats(model, currentDef - damageToDefense, maxDef)
									end
									
									-- Create damage number display (show actual damage applied, which includes block reduction)
									-- Only show damage number if not invincible
									_G.createDamageNumber(model, damageToHealth + damageToDefense)
								end
								
								-- Apply knockback to mobs
								applyKnockback(character, model)
								
								-- Create damage flash effect on the target
								createDamageFlash(model, ServerConfigs.Hitbox.highlighting.damageFlash.duration)
								
								-- Apply status ailments if configured (optional)
								applyStatusAilmentFromConfig(model, config)
								
								-- Apply lifesteal if configured (optional)
								applyLifestealFromConfig(character, config, damageToHealth + damageToDefense)
								
								hitSomething = true
							end
						end
					end
				end
			end

			-- If we hit something, stop the projectile and stick it
			if hitSomething then
				projectileStopped = true

				-- Destroy visual on hit
				if visual then
					visual:Destroy()
				end

				-- Apply configurable delay before anchoring the arrow for better visual alignment
				task.delay(anchorDelay, function()
					-- Stop the visual part's movement and position it at hit location
					if visualPart and visualPart.Parent then
						-- Find and destroy any BodyVelocity on the visual part
						local bodyVelocity = visualPart:FindFirstChildOfClass("BodyVelocity")
						if bodyVelocity then
							bodyVelocity:Destroy()
						end

						-- Also check the visual part's parent model for BodyVelocity (in case it's on the model)
						if visualPart.Parent and visualPart.Parent:IsA("Model") then
							local parentBodyVelocity = visualPart.Parent:FindFirstChildOfClass("BodyVelocity")
							if parentBodyVelocity then
								parentBodyVelocity:Destroy()
							end
						end

						-- Position visual at the exact hit location and anchor it
						local hitPosition = hitboxPart.CFrame
						if hitPosition then
							visualPart.CFrame = hitPosition
						end

						-- Make sure visual is completely non-physical before anchoring (if enabled)
						if preventPhysicsPush then
							visualPart.CanCollide = false
							visualPart.CanQuery = false
							visualPart.CanTouch = false
						end
						visualPart.Anchored = true

						-- If the visual part is inside a model, make sure the model follows it
						if visualPart.Parent and visualPart.Parent:IsA("Model") then
							-- Use PrimaryPart to make the model follow this part
							visualPart.Parent.PrimaryPart = visualPart
							-- Also make the model non-physical to prevent pushing
							visualPart.Parent:SetAttribute("NonPhysical", true)
						end
					end

					-- Destroy the separate hitbox part since we're done with collision detection
					if hitboxPart and hitboxPart.Parent then
						hitboxPart:Destroy()
					end
				end)

				connection:Disconnect()
			end
		end)

		-- Auto cleanup after 3 seconds
		task.delay(3, function()
			if not projectileStopped then
				projectileStopped = true
				connection:Disconnect()
				if visual then visual:Destroy() end
				if hitboxPart and hitboxPart.Parent then hitboxPart:Destroy() end
			end
		end)
	end)

	-- Cleanup function
	return function()
		if visualPart and visualPart.Parent then visualPart:Destroy() end
		if hitboxPart and hitboxPart.Parent then hitboxPart:Destroy() end
		if visual and visual.Parent then visual:Destroy() end
	end
end

-- ========================================
-- MODULE EXPORTS
-- ========================================

local DynamicHitboxV3 = {}

-- Export hitbox creation functions
DynamicHitboxV3.createStaticHitbox = _G.createStaticHitbox
DynamicHitboxV3.createStaticDOTHitbox = _G.createStaticDOTHitbox
DynamicHitboxV3.createTravelingHitbox = _G.createTravelingHitbox
DynamicHitboxV3.createTravelingDOTHitbox = _G.createTravelingDOTHitbox
DynamicHitboxV3.createProjectileHitbox = _G.createProjectileHitbox

-- Export friendly fire control functions
DynamicHitboxV3.setPlayerFriendlyFire = _G.setPlayerFriendlyFire
DynamicHitboxV3.getPlayerFriendlyFire = _G.getPlayerFriendlyFire
DynamicHitboxV3.setMobFriendlyFire = _G.setMobFriendlyFire
DynamicHitboxV3.getMobFriendlyFire = _G.getMobFriendlyFire
DynamicHitboxV3.setFriendlyFire = _G.setFriendlyFire
DynamicHitboxV3.getFriendlyFire = _G.getFriendlyFire

return DynamicHitboxV3

