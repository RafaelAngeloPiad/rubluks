-- ========================================
-- STATUS AILMENT HANDLER
-- Manages status ailments on characters (players and mobs)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Import configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- ========================================
-- STATUS AILMENT TRACKING
-- ========================================

-- Track active ailments per character
local activeAilments = {} -- {model: {[ailmentType]: {duration, startTime, config}}}

-- Store original stats to restore after ailments expire
local originalStats = {} -- {model: {walkSpeed, jumpPower, platformStand}}

-- ========================================
-- AILMENT TYPES
-- ========================================

local AilmentTypes = {
	STUN = "stun",           -- Stops all movement
	POISON = "poison",       -- DPS damage (purple highlight)
	BURN = "burn",           -- DPS damage (orange highlight)
	ICE = "ice",             -- Slow + Damage (blue highlight)
	SLOW = "slow"            -- Reduces movement speed
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to get player from model
local function getPlayer(model)
	if not model then return nil end
	return Players:GetPlayerFromCharacter(model)
end

-- Function to get humanoid from model
local function getHumanoid(model)
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

-- Function to get HumanoidRootPart from model
local function getHumanoidRootPart(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart")
end

-- Function to restore original stats
local function restoreOriginalStats(model)
	if not model or not originalStats[model] then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid then return end
	
	local stats = originalStats[model]
	
	-- Restore walk speed
	if stats.walkSpeed then
		humanoid.WalkSpeed = stats.walkSpeed
	end
	
	-- Restore jump power
	if stats.jumpPower then
		humanoid.JumpPower = stats.jumpPower
	end
	
	-- Restore platform stand
	if stats.platformStand ~= nil then
		humanoid.PlatformStand = stats.platformStand
	end
	
	-- Restore HumanoidRootPart anchored state
	if stats.rootAnchored ~= nil then
		local rootPart = getHumanoidRootPart(model)
		if rootPart then
			rootPart.Anchored = stats.rootAnchored
		end
	end
	
	-- Clean up stored stats
	originalStats[model] = nil
end

-- Function to save original stats
local function saveOriginalStats(model)
	if not model then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid then return end
	
	local rootPart = getHumanoidRootPart(model)
	
	-- Only save if not already saved
	if not originalStats[model] then
		originalStats[model] = {
			walkSpeed = humanoid.WalkSpeed,
			jumpPower = humanoid.JumpPower,
			platformStand = humanoid.PlatformStand,
			rootAnchored = rootPart and rootPart.Anchored or false
		}
	end
end

-- Function to create ailment highlight
local function createAilmentHighlight(model, ailmentType)
	if not model or not model.Parent then return end
	
	local config = ServerConfigs.Hitbox.statusAilments[ailmentType]
	if not config then return end
	
	-- Remove existing highlight for this ailment type
	local existingHighlight = model:FindFirstChild("StatusAilment_" .. ailmentType)
	if existingHighlight then
		existingHighlight:Destroy()
	end
	
	-- Create new highlight
	local highlight = Instance.new("Highlight")
	highlight.Parent = model
	highlight.Name = "StatusAilment_" .. ailmentType
	
	-- Apply configuration
	highlight.FillColor = config.highlightColor.fillColor
	highlight.FillTransparency = config.highlightColor.fillTransparency
	highlight.OutlineColor = config.highlightColor.outlineColor
	highlight.OutlineTransparency = config.highlightColor.outlineTransparency
	
	return highlight
end

-- Function to apply ailment effects
local function applyAilmentEffects(model, ailmentType, config)
	if not model then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid then return end
	
	-- Save original stats if not already saved
	saveOriginalStats(model)
	
	if ailmentType == AilmentTypes.STUN then
		-- Stun: Stop all movement and anchor in place
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.PlatformStand = true
		
		-- Anchor HumanoidRootPart to prevent sinking
		local rootPart = getHumanoidRootPart(model)
		if rootPart then
			rootPart.Anchored = true
		end
		
	elseif ailmentType == AilmentTypes.SLOW then
		-- Slow: Reduce movement speed
		-- Get slow multiplier from config or default config
		local ailmentConfig = ServerConfigs.Hitbox.statusAilments[AilmentTypes.SLOW]
		local slowMultiplier = config.slowMultiplier or (ailmentConfig and ailmentConfig.slowMultiplier) or 0.5 -- Default 50% speed
		local currentSpeed = originalStats[model] and originalStats[model].walkSpeed or humanoid.WalkSpeed
		humanoid.WalkSpeed = currentSpeed * slowMultiplier
		
	elseif ailmentType == AilmentTypes.ICE then
		-- Ice: Slow + Damage
		-- Get slow multiplier from config or default config
		local ailmentConfig = ServerConfigs.Hitbox.statusAilments[AilmentTypes.ICE]
		local slowMultiplier = config.slowMultiplier or (ailmentConfig and ailmentConfig.slowMultiplier) or 0.3 -- Default 30% speed
		local currentSpeed = originalStats[model] and originalStats[model].walkSpeed or humanoid.WalkSpeed
		humanoid.WalkSpeed = currentSpeed * slowMultiplier
	end
	
	-- Create visual highlight
	createAilmentHighlight(model, ailmentType)
end

-- Function to remove ailment effects
local function removeAilmentEffects(model, ailmentType)
	if not model then return end
	
	-- Remove highlight
	local highlight = model:FindFirstChild("StatusAilment_" .. ailmentType)
	if highlight then
		highlight:Destroy()
	end
	
	-- Check if there are other active ailments
	local ailments = activeAilments[model]
	if ailments then
		-- Remove this ailment from tracking
		ailments[ailmentType] = nil
		
		-- Check if any slow/stun ailments remain
		local hasSlowEffect = false
		local slowMultiplier = 1.0
		
		for type, ailmentData in pairs(ailments) do
			if type == AilmentTypes.STUN then
				hasSlowEffect = true
				slowMultiplier = 0 -- Stun overrides everything
				break
			elseif type == AilmentTypes.SLOW or type == AilmentTypes.ICE then
				hasSlowEffect = true
				-- Get slow multiplier from active ailment's config or default config
				local ailmentData = ailments[type]
				local ailmentConfig = ServerConfigs.Hitbox.statusAilments[type]
				local ailmentSlowMultiplier = nil
				
				if ailmentData and ailmentData.config and ailmentData.config.slowMultiplier then
					ailmentSlowMultiplier = ailmentData.config.slowMultiplier
				elseif ailmentConfig and ailmentConfig.slowMultiplier then
					ailmentSlowMultiplier = ailmentConfig.slowMultiplier
				end
				
				if ailmentSlowMultiplier then
					slowMultiplier = math.min(slowMultiplier, ailmentSlowMultiplier)
				end
			end
		end
		
		-- If no slow effects remain, restore original stats
		if not hasSlowEffect then
			restoreOriginalStats(model)
		else
			-- Reapply slow effects with the worst multiplier
			local humanoid = getHumanoid(model)
			if humanoid and originalStats[model] then
				if ailments[AilmentTypes.STUN] then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
					humanoid.PlatformStand = true
					-- Re-anchor HumanoidRootPart when stun is still active
					local rootPart = getHumanoidRootPart(model)
					if rootPart then
						rootPart.Anchored = true
					end
				else
					local currentSpeed = originalStats[model].walkSpeed
					humanoid.WalkSpeed = currentSpeed * slowMultiplier
				end
			end
		end
		
		-- Clean up if no ailments remain
		local hasAnyAilment = false
		for _ in pairs(ailments) do
			hasAnyAilment = true
			break
		end
		if not hasAnyAilment then
			activeAilments[model] = nil
			restoreOriginalStats(model)
		end
	else
		-- No ailments left, restore stats
		restoreOriginalStats(model)
	end
end

-- Function to apply DPS damage
local function applyDPSDamage(model, ailmentType, damage, tickInterval)
	if not model then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Get defense stats (from DynamicHitboxV3)
	local currentDefense, maxDefense = 0, 0
	local player = getPlayer(model)
	
	if player and player:FindFirstChild("leaderstats") then
		local leaderstats = player.leaderstats
		if leaderstats:FindFirstChild("MaxDefense") then
			maxDefense = leaderstats.MaxDefense.Value
		end
		if leaderstats:FindFirstChild("CurrentDefense") then
			currentDefense = leaderstats.CurrentDefense.Value
		else
			currentDefense = maxDefense
		end
	elseif model:IsA("Model") then
		currentDefense = model:GetAttribute("CurrentDefense") or 0
		maxDefense = model:GetAttribute("MaxDefense") or 0
	end
	
	-- Calculate damage with defense (simplified - no penetration for DPS)
	local damageToHealth = 0
	local damageToDefense = 0
	
	if currentDefense > 0 then
		if damage <= currentDefense then
			damageToDefense = damage
			damageToHealth = 0
		else
			damageToDefense = currentDefense
			damageToHealth = damage - currentDefense
		end
	else
		damageToHealth = damage
		damageToDefense = 0
	end
	
	-- Apply damage to health
	if damageToHealth > 0 then
		humanoid:TakeDamage(damageToHealth)
	end
	
	-- Apply damage to defense
	if damageToDefense > 0 then
		if player and player:FindFirstChild("leaderstats") then
			local leaderstats = player.leaderstats
			local currentDefStat = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefStat then
				currentDefStat.Value = math.max(0, currentDefStat.Value - damageToDefense)
			end
		elseif model:IsA("Model") then
			model:SetAttribute("CurrentDefense", math.max(0, currentDefense - damageToDefense))
		end
	end
	
	-- Create damage number display (show total damage: health + defense)
	-- Only show if there's actual damage dealt
	if (damageToHealth + damageToDefense) > 0 then
		if _G.createDamageNumber then
			_G.createDamageNumber(model, damageToHealth + damageToDefense)
		end
	end
end

-- ========================================
-- MAIN AILMENT FUNCTIONS
-- ========================================

-- Function to apply a status ailment to a model
-- @param model: The character model
-- @param ailmentType: Type of ailment (AilmentTypes.STUN, etc.)
-- @param config: Configuration {duration, chance, dps, tickInterval, slowMultiplier}
function _G.applyStatusAilment(model, ailmentType, config)
	if not model or not model.Parent then return end
	if not ailmentType or not ServerConfigs.Hitbox.statusAilments[ailmentType] then return end
	
	-- Validate config
	config = config or {}
	local duration = config.duration or ServerConfigs.Hitbox.statusAilments[ailmentType].defaultDuration
	local chance = config.chance or 100 -- Default 100% chance
	
	-- Roll for chance
	if chance < 100 then
		local roll = math.random() * 100
		if roll >= chance then
			return -- Failed chance roll
		end
	end
	
	-- Initialize ailments tracking for this model
	if not activeAilments[model] then
		activeAilments[model] = {}
	end
	
	-- Check if ailment already exists (refresh duration if it does)
	if activeAilments[model][ailmentType] then
		-- Refresh duration
		activeAilments[model][ailmentType].duration = duration
		activeAilments[model][ailmentType].startTime = tick()
		activeAilments[model][ailmentType].config = config
	else
		-- Create new ailment
		activeAilments[model][ailmentType] = {
			duration = duration,
			startTime = tick(),
			config = config
		}
		
		-- Apply effects immediately
		applyAilmentEffects(model, ailmentType, config)
	end
	
	-- Setup DPS for poison/burn/ice
	if ailmentType == AilmentTypes.POISON or ailmentType == AilmentTypes.BURN or ailmentType == AilmentTypes.ICE then
		local dps = config.dps or 0
		local tickInterval = config.tickInterval or 1.0
		
		if dps > 0 and tickInterval > 0 then
			-- Store DPS info
			activeAilments[model][ailmentType].dps = dps
			activeAilments[model][ailmentType].tickInterval = tickInterval
			activeAilments[model][ailmentType].lastDPS = tick()
		end
	end
end

-- Function to check if model has a specific ailment
function _G.hasStatusAilment(model, ailmentType)
	if not model or not activeAilments[model] then return false end
	return activeAilments[model][ailmentType] ~= nil
end

-- Function to remove a specific ailment from a model
function _G.removeStatusAilment(model, ailmentType)
	if not model or not activeAilments[model] then return end
	
	removeAilmentEffects(model, ailmentType)
end

-- Function to clear all ailments from a model
function _G.clearAllStatusAilments(model)
	if not model or not activeAilments[model] then return end
	
	-- Remove all ailments
	for ailmentType, _ in pairs(activeAilments[model]) do
		removeAilmentEffects(model, ailmentType)
	end
	
	activeAilments[model] = nil
	restoreOriginalStats(model)
end

-- ========================================
-- UPDATE LOOP
-- ========================================

-- Main update loop to process ailments
RunService.Heartbeat:Connect(function()
	for model, ailments in pairs(activeAilments) do
		-- Safety check: model still exists
		if not model or not model.Parent then
			-- Clean up
			activeAilments[model] = nil
			originalStats[model] = nil
		else
			local humanoid = getHumanoid(model)
			if not humanoid or humanoid.Health <= 0 then
				-- Character is dead, clean up
				activeAilments[model] = nil
				restoreOriginalStats(model)
			else
				-- Process each ailment
				for ailmentType, ailmentData in pairs(ailments) do
					local currentTime = tick()
					local elapsed = currentTime - ailmentData.startTime
					
					-- Check if ailment expired
					if elapsed >= ailmentData.duration then
						removeAilmentEffects(model, ailmentType)
					else
						-- Process DPS ailments
						if ailmentType == AilmentTypes.POISON or ailmentType == AilmentTypes.BURN or ailmentType == AilmentTypes.ICE then
							local dps = ailmentData.dps or 0
							local tickInterval = ailmentData.tickInterval or 1.0
							local lastDPS = ailmentData.lastDPS or ailmentData.startTime
							
							if dps > 0 and (currentTime - lastDPS) >= tickInterval then
								-- Apply DPS damage
								applyDPSDamage(model, ailmentType, dps, tickInterval)
								ailmentData.lastDPS = currentTime
							end
						end
					end
				end
			end
		end
	end
end)

-- Clean up when characters are removed
game.Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		_G.clearAllStatusAilments(player.Character)
	end
end)

-- ========================================
-- MODULE EXPORTS
-- ========================================

local StatusAilmentHandler = {}

StatusAilmentHandler.apply = _G.applyStatusAilment
StatusAilmentHandler.has = _G.hasStatusAilment
StatusAilmentHandler.remove = _G.removeStatusAilment
StatusAilmentHandler.clearAll = _G.clearAllStatusAilments
StatusAilmentHandler.AilmentTypes = AilmentTypes

return StatusAilmentHandler

