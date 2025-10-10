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

local HITBOX_CONFIG = {
	transparency = 1, -- Global transparency for all hitbox visuals
}

-- ========================================
-- DELAY SCALING SYSTEM
-- ========================================

-- Function to scale delays based on animation speed multiplier
local function getScaledDelay(baseDelay, actionType)
	if not baseDelay or baseDelay == 0 then
		return 0
	end
	
	-- Get specific animation speed for the action type
	local animationSpeed = 1.0 -- Default speed
	
	-- Check for Knight animation speeds
	if _G.KNIGHT_ANIMATION_SPEEDS and actionType then
		animationSpeed = _G.KNIGHT_ANIMATION_SPEEDS[actionType] or 1.0
	-- Check for Archer animation speeds
	elseif _G.ARCHER_ANIMATION_SPEEDS and actionType then
		animationSpeed = _G.ARCHER_ANIMATION_SPEEDS[actionType] or 1.0
	-- Check for Samurai animation speeds (fallback)
	elseif _G.SAMURAI_ANIMATION_SPEEDS and actionType then
		animationSpeed = _G.SAMURAI_ANIMATION_SPEEDS[actionType] or 1.0
	end
	
	-- Scale delay inversely with animation speed
	-- If animation is 2x faster, delays should be 0.5x (half the time)
	-- If animation is 0.5x slower, delays should be 2x (double the time)
	return baseDelay / animationSpeed
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
					hitTargets[humanoid] = true
					humanoid:TakeDamage(damage)
					
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
		if not damageTickTime then damageTickTime = 0.5 end
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
						humanoid:TakeDamage(damage)
						
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
						hitTargets[humanoid] = true
						humanoid:TakeDamage(damage)
						
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
		end)
	end)
end

