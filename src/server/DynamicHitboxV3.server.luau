-- ========================================
-- DYNAMIC HITBOX V3 - FULLY SERVER SIDE
-- Modular hitbox system with part attachment
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ========================================
-- CONFIGURATION
-- ========================================

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("serverConfigs"))

local HITBOX_CONFIG = {
	transparency = ServerConfigs.Hitbox.transparency, -- Global transparency for all hitbox visuals
}

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

-- Function to create damage flash effect using Highlight
local function createDamageFlash(model, duration)
    duration = duration
    
    -- Find or create highlight for the model
    local highlight = model:FindFirstChildOfClass("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = model
    end
    
    -- Flash red
    highlight.FillColor = Color3.new(1, 0, 0) -- Bright red
    highlight.FillTransparency = 0.8 -- Slightly transparent
    highlight.OutlineColor = Color3.new(1, 0, 0) -- Red outline
    highlight.OutlineTransparency = 0 -- Solid outline
    
    -- Destroy highlight after duration
    task.delay(duration, function()
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end)
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
	})
]]
function _G.createStaticHitbox(config)
	-- config: cframe OR attachTo, size, damage, character, name, showVisual, visualColor, offset, delay, visualDuration
	local delay = getScaledDelay(config.delay, config.actionType)
	
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
		visualDuration = getScaledDelay(visualDuration, config.actionType)
		
		-- If attachTo is provided, use its CFrame with offset
		if attachTo and not cframe then
			cframe = attachTo.CFrame * offset
		elseif not cframe then
			warn("[HITBOX V3] Static hitbox needs either cframe or attachTo")
			return
		end
		
		-- Create visual
		local visual = nil
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.CFrame = cframe
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = HITBOX_CONFIG.transparency
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
						humanoid:TakeDamage(damage)
						
						-- Create damage flash effect on the target
						createDamageFlash(model, 0.2)
						
						-- Flash visual
						if visual then
							visual.Color = Color3.new(1, 1, 1)
							task.delay(0.05, function()
								if visual and visual.Parent then
									visual.Color = visualColor
								end
							end)
						end
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
	DURATION: Lasts until attachTo part is destroyed
	
	EXAMPLE:
	_G.createStaticDOTHitbox({
		attachTo = vfxPart,                 -- BasePart to track lifetime (REQUIRED for auto-cleanup)
		cframe = CFrame.new(0, 10, 0),      -- Direct CFrame position (OR use attachTo)
		offset = CFrame.new(0, 0, 0),       -- CFrame offset from attachTo (optional)
		size = Vector3.new(15, 15, 15),     -- Hitbox dimensions (REQUIRED)
		damage = 5,                         -- Damage PER TICK (REQUIRED)
		damageTickTime = 0.5,               -- Seconds between damage ticks (optional, default: 0.5)
		character = character,              -- Player's character to exclude (REQUIRED)
		name = "FireField",                 -- Hitbox name for debugging (REQUIRED)
		showVisual = true,                  -- Show debug visual (optional, default: true)
		visualColor = Color3.new(1, 0.5, 0),-- Debug visual color (REQUIRED)
		delay = 0,                          -- Delay before activation (optional, default: 0)
	})
]]
function _G.createStaticDOTHitbox(config)
	-- config: cframe OR attachTo, size, damage, character, name, showVisual, visualColor, offset, delay, damageTickTime
	local delay = getScaledDelay(config.delay, config.actionType)
	
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
		damageTickTime = getScaledDelay(damageTickTime, config.actionType)
		
		-- If attachTo is provided, use its CFrame with offset
		if attachTo and not cframe then
			cframe = attachTo.CFrame * offset
		elseif not cframe then
			warn("[HITBOX V3] Static DOT hitbox needs either cframe or attachTo")
			return
		end
		
		-- Create visual
		local visual = nil
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.CFrame = cframe
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = HITBOX_CONFIG.transparency
			visual.Color = visualColor
			visual.Name = name .. "DOTHitboxVisual"
			visual.Parent = workspace
		end
		
		-- Track last tick time
		local lastTickTime = tick()
		local active = true
		
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
			
			for _, part in regionParts do
				local model = part:FindFirstAncestorOfClass("Model")
				if model and model ~= character then
					local humanoid = model:FindFirstChild("Humanoid")
					
					if humanoid then
						-- Check if damage should be applied using new targeting system
						if shouldApplyDamage(character, model) then
							humanoid:TakeDamage(damage)
							
							-- Create damage flash effect on the target
							createDamageFlash(model, 0.15)
							
							-- Flash visual on hit
							if visual then
								visual.Color = Color3.new(1, 0.5, 0) -- Orange flash for DOT
								task.delay(0.05, function()
									if visual and visual.Parent then
										visual.Color = visualColor
									end
								end)
							end
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
				visual.CFrame = getCurrentHitboxCFrame()
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
	-- config: attachTo (BasePart), size, damage, character, name, showVisual, visualColor, offset, delay
	local delay = getScaledDelay(config.delay, config.actionType)
	
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
			warn("[HITBOX V3] No attachTo part provided for traveling hitbox")
			return
		end
		
		local hitTargets = {}
		
		-- Create visual
		local visual = nil
		if showVisual then
			visual = Instance.new("Part")
			visual.Size = size
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Material = Enum.Material.Neon
			visual.Transparency = HITBOX_CONFIG.transparency
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
							humanoid:TakeDamage(damage)
							
							-- Create damage flash effect on the target
							createDamageFlash(model, 0.2)
							
							-- Flash visual on hit
							if visual then
								visual.Color = Color3.new(1, 0, 0)
								task.delay(0.1, function()
									if visual and visual.Parent then
										visual.Color = visualColor
									end
								end)
							end
						end
					end
				end
			end
		end)
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
		warn("[HITBOX V3] Projectile hitbox needs visualPart and direction")
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
	if showVisual then
		visual = Instance.new("Part")
		visual.Size = size
		visual.Anchored = true
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.Material = Enum.Material.Neon
		visual.Transparency = HITBOX_CONFIG.transparency -- Use unified transparency setting
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
								humanoid:TakeDamage(damage)
								
								-- Create damage flash effect on the target
								createDamageFlash(model, 0.2)
								hitSomething = true
							end
						end
					end
				end
			end

			-- If we hit something, stop the projectile and stick it
			if hitSomething then
				projectileStopped = true

				-- Flash visual on hit
				if visual then
					visual.Color = Color3.new(1, 0, 0) -- Red flash on hit
					task.delay(0.1, function()
						if visual and visual.Parent then
							visual:Destroy()
						end
					end)
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
DynamicHitboxV3.createProjectileHitbox = _G.createProjectileHitbox

-- Export friendly fire control functions
DynamicHitboxV3.setPlayerFriendlyFire = _G.setPlayerFriendlyFire
DynamicHitboxV3.getPlayerFriendlyFire = _G.getPlayerFriendlyFire
DynamicHitboxV3.setMobFriendlyFire = _G.setMobFriendlyFire
DynamicHitboxV3.getMobFriendlyFire = _G.getMobFriendlyFire
DynamicHitboxV3.setFriendlyFire = _G.setFriendlyFire
DynamicHitboxV3.getFriendlyFire = _G.getFriendlyFire

return DynamicHitboxV3

