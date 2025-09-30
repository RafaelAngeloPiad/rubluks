-- DynamicHitboxV2: Advanced hitbox generation system with multiple types
-- Supports: Static hitboxes, Traveling hitboxes, and Projectile hitboxes
--
-- MANDATORY IMPLEMENTATION REQUIREMENTS:
-- 1. All hitbox configs MUST include: type, size, offset, damage
-- 2. Static hitboxes MUST include: duration (tickInterval for DOT)
-- 3. Traveling hitboxes MUST include: duration, speed, maxDistance
-- 4. Projectile hitboxes MUST include: speed, maxDistance, projectileSize
-- 5. Server MUST have DynamicHitboxV2.server.luau running
-- 6. RemoteEvent "DynamicHitboxV2Request" MUST exist in ReplicatedStorage

-- MANDATORY: Required services for hitbox system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- MANDATORY: Local player reference for hitbox generation
local player = Players.LocalPlayer

-- =====================================================================================
-- DYNAMIC HITBOX V2 SYSTEM
-- =====================================================================================

-- MANDATORY: Main module table for hitbox system
local DynamicHitboxV2 = {}

-- MANDATORY: Hitbox type constants - must match server expectations
local HITBOX_TYPES = {
    STATIC = "static",           -- Fixed position, optional intervals
    TRAVELING = "traveling",     -- Moves and damages anything it touches
    PROJECTILE = "projectile"    -- Single hit at target location (V1 style)
}

-- =====================================================================================
-- HITBOX PARAMETER DOCUMENTATION
-- =====================================================================================

--[[
    HITBOX CONFIGURATION PARAMETERS
    ================================
    
    MANDATORY REQUIRED PARAMETERS (for all types):
    - type: string - "static", "traveling", or "projectile" (MUST be valid type)
    - size: Vector3 - Hitbox dimensions (width, height, depth) (MUST be positive)
    - offset: Vector3 - Position offset from player (x, y, z) (MANDATORY for positioning)
    - damage: number - Damage amount per hit (MUST be positive number)
    
    OPTIONAL PARAMETERS (for all types):
    - delay: number - Delay before hitbox activates (default: 0)
    - color: Color3 - Visual hitbox color (default: blue)
    - transparency: number - Visual transparency 0-1 (default: 0.7)
    - name: string - Debug name for console output (default: "Unknown")
    
    STATIC HITBOX PARAMETERS:
    - duration: number - How long hitbox stays active (MANDATORY for static, default: 0.3)
    - tickInterval: number - Damage interval for DPS (MANDATORY for DOT, must be < duration)
    
    Example Static Hitbox:
    local config = {
        type = "static",
        size = Vector3.new(8, 8, 8),
        offset = Vector3.new(0, 0, 5),
        damage = 30,
        duration = 2,
        tickInterval = 0.5,  -- Damage every 0.5 seconds
        color = Color3.new(1, 0, 0),
        name = "Fire AOE"
    }
    
    TRAVELING HITBOX PARAMETERS:
    - duration: number - How long hitbox travels (MANDATORY for traveling, default: 0.3)
    - speed: number - Movement speed in studs/second (MANDATORY for traveling, default: 50)
    - maxDistance: number - Maximum travel distance (MANDATORY for traveling, default: speed * duration)
    
    Example Traveling Hitbox:
    local config = {
        type = "traveling",
        size = Vector3.new(6, 6, 6),
        offset = Vector3.new(0, 0, 3),
        damage = 25,
        duration = 2.5,
        speed = 40,
        maxDistance = 100,
        color = Color3.new(0, 1, 0),
        name = "Dash Attack"
    }
    
    PROJECTILE HITBOX PARAMETERS:
    - speed: number - Projectile speed in studs/second (MANDATORY for projectile, default: 200)
    - maxDistance: number - Maximum range (MANDATORY for projectile, default: 100)
    - projectileSize: Vector3 - Visual projectile size (MANDATORY for projectile, default: Vector3.new(0.5, 0.5, 3))
    
    Example Projectile Hitbox:
    local config = {
        type = "projectile",
        size = Vector3.new(6, 6, 6),
        offset = Vector3.new(0, 0, 2),
        damage = 50,
        speed = 150,
        maxDistance = 100,
        projectileSize = Vector3.new(0.5, 0.5, 3),
        color = Color3.new(1, 1, 0),
        name = "Magic Missile"
    }
    
    USAGE:
    _G.dynamicHitboxV2Generate(config)
    
    OR use helper function:
    local config = _G.createHitboxConfig("traveling", Vector3.new(8, 8, 8), Vector3.new(0, 0, 5), 25, {
        duration = 3,
        speed = 50,
        color = Color3.new(0, 0, 1)
    })
--]]

-- MANDATORY: Visual hitbox preview toggle (set to false for production)
local SHOW_HITBOX_VISUALS = true

-- Create visual hitbox (simple square)
local function createVisualHitbox(hitboxCFrame, size, color, transparency, duration)
    if not SHOW_HITBOX_VISUALS then
        return
    end
    
    local hitboxPart = Instance.new("Part")
    hitboxPart.Size = size
    hitboxPart.CFrame = hitboxCFrame
    hitboxPart.Anchored = true
    hitboxPart.CanCollide = false
    hitboxPart.CanQuery = false
    hitboxPart.CanTouch = false
    hitboxPart.Material = Enum.Material.Neon
    hitboxPart.Transparency = transparency or 0.7
    hitboxPart.Color = color or Color3.new(0, 0, 1)
    hitboxPart.Name = "DynamicHitboxV2Visual"
    hitboxPart.Parent = Workspace
    
    -- Remove after duration
    task.delay(duration or 0.3, function()
        if hitboxPart then
            hitboxPart:Destroy()
        end
    end)
end

-- MANDATORY: Main hitbox generation function (supports multiple types)
function DynamicHitboxV2.generateHitbox(hitboxConfig)
    -- MANDATORY: Validate player and character exist
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- MANDATORY: Extract config values (all required parameters must be present)
    local size = hitboxConfig.size
    local offset = hitboxConfig.offset
    local damage = hitboxConfig.damage
    local delay = hitboxConfig.delay
    local duration = hitboxConfig.duration
    local tickInterval = hitboxConfig.tickInterval
    local color = hitboxConfig.color
    local transparency = hitboxConfig.transparency
    local hitboxType = hitboxConfig.type or HITBOX_TYPES.STATIC -- MANDATORY: Default to static

    -- MANDATORY: Schedule hitbox generation after delay
    task.delay(delay, function()
        -- MANDATORY: Calculate initial hitbox position using player's CFrame
        local rootCFrame = humanoidRootPart.CFrame
        local forwardOffset = rootCFrame.LookVector * offset.Z
        local rightOffset = rootCFrame.RightVector * offset.X
        local upOffset = rootCFrame.UpVector * offset.Y
        local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
        local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

        -- MANDATORY: Route to appropriate hitbox type based on configuration
        if hitboxType == HITBOX_TYPES.STATIC then
            DynamicHitboxV2.generateStaticHitbox(hitboxCFrame, size, damage, duration, tickInterval, hitboxConfig)
        elseif hitboxType == HITBOX_TYPES.TRAVELING then
            DynamicHitboxV2.generateTravelingHitbox(hitboxCFrame, size, damage, duration, hitboxConfig)
        elseif hitboxType == HITBOX_TYPES.PROJECTILE then
            DynamicHitboxV2.generateProjectileHitbox(hitboxCFrame, size, damage, hitboxConfig)
        else
            warn("[DYNAMIC HITBOX V2] Unknown hitbox type:", hitboxType)
        end
    end)
end

-- MANDATORY: Generate static hitbox (supports both single hit and DOT)
function DynamicHitboxV2.generateStaticHitbox(hitboxCFrame, size, damage, duration, tickInterval, hitboxConfig)
    -- MANDATORY: Check if this should be DPS (duration > tickInterval) for DOT functionality
    if tickInterval and duration > tickInterval then
        -- MANDATORY: DPS hitbox - damage over time (DOT system)
        local startTime = tick()
        local tickNumber = 0
        
        -- MANDATORY: DOT tick function - handles damage over time
        local function applyDamageTick()
            local elapsed = tick() - startTime
            
            -- MANDATORY: Stop if duration expired
            if elapsed >= duration then
                return
            end
            
            tickNumber = tickNumber + 1
            
            -- MANDATORY: Send damage tick to server with tick number
            local hitRequest = ReplicatedStorage:WaitForChild("DynamicHitboxV2Request")
            hitRequest:FireServer(hitboxCFrame, size, damage, hitboxConfig.name or "Unknown", tickNumber)
            
            -- MANDATORY: Schedule next tick if there's still time
            local timeRemaining = duration - elapsed
            if timeRemaining > tickInterval then
                task.delay(tickInterval, applyDamageTick)
            end
        end
        
        -- MANDATORY: Start first tick immediately for DOT
        applyDamageTick()
    else
        -- MANDATORY: Single hit - damage once (no DOT)
        local hitRequest = ReplicatedStorage:WaitForChild("DynamicHitboxV2Request")
        hitRequest:FireServer(hitboxCFrame, size, damage, hitboxConfig.name or "Unknown", 1)
    end

    -- MANDATORY: Create visual hitbox for debugging
    createVisualHitbox(hitboxCFrame, size, hitboxConfig.color, hitboxConfig.transparency, duration)
    
    print("[DYNAMIC HITBOX V2] Generated static hitbox for", hitboxConfig.name or "Unknown")
end

-- Generate traveling hitbox (moves and damages anything it touches)
function DynamicHitboxV2.generateTravelingHitbox(hitboxCFrame, size, damage, duration, hitboxConfig)
    local startPosition = hitboxCFrame.Position
    local direction = hitboxCFrame.LookVector
    local speed = hitboxConfig.speed or 50 -- Default speed
    local maxDistance = hitboxConfig.maxDistance or (speed * duration) -- Calculate max distance from speed and duration
    
    -- Track damaged targets to prevent multiple hits
    local damagedTargets = {}
    
    -- Create visual hitbox that moves
    local visualHitbox = nil
    if SHOW_HITBOX_VISUALS then
        visualHitbox = Instance.new("Part")
        visualHitbox.Size = size
        visualHitbox.CFrame = hitboxCFrame
        visualHitbox.Anchored = true
        visualHitbox.CanCollide = false
        visualHitbox.CanQuery = false
        visualHitbox.CanTouch = false
        visualHitbox.Material = Enum.Material.Neon
        visualHitbox.Transparency = hitboxConfig.transparency or 0.7
        visualHitbox.Color = hitboxConfig.color or Color3.new(0, 0, 1)
        visualHitbox.Name = "TravelingHitboxVisual"
        visualHitbox.Parent = Workspace
    end
    
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        
        -- Stop if duration expired
        if elapsed >= duration then
            if visualHitbox then
                visualHitbox:Destroy()
            end
            connection:Disconnect()
            return
        end
        
        -- Calculate current position
        local distanceTraveled = speed * elapsed
        local currentPosition = startPosition + (direction * distanceTraveled)
        local currentCFrame = CFrame.new(currentPosition, currentPosition + direction)
        
        -- Update visual hitbox position
        if visualHitbox then
            visualHitbox.CFrame = currentCFrame
        end
        
        -- Check for targets in current hitbox area
        local regionParts = workspace:GetPartBoundsInBox(currentCFrame, size)
        
        for _, part in regionParts do
            local model = part:FindFirstAncestorOfClass("Model")
            if model and model ~= player.Character then
                local humanoid = model:FindFirstChild("Humanoid")
                local targetPlayer = Players:GetPlayerFromCharacter(model)
                
                if humanoid and not damagedTargets[humanoid] then
                    -- Mark as damaged to prevent multiple hits
                    damagedTargets[humanoid] = true
                    
                    -- Send damage to server
                    local hitRequest = ReplicatedStorage:WaitForChild("DynamicHitboxV2Request")
                    hitRequest:FireServer(currentCFrame, size, damage, hitboxConfig.name or "Unknown", 1)
                    
                    print("[DYNAMIC HITBOX V2] Traveling hitbox damaged", targetPlayer and targetPlayer.Name or "NPC")
                end
            end
        end
        
        -- Stop if we've traveled max distance
        if distanceTraveled >= maxDistance then
            if visualHitbox then
                visualHitbox:Destroy()
            end
            connection:Disconnect()
        end
    end)
    
    print("[DYNAMIC HITBOX V2] Generated traveling hitbox for", hitboxConfig.name or "Unknown")
end

-- Generate projectile hitbox (V1 style - single hit at target)
function DynamicHitboxV2.generateProjectileHitbox(hitboxCFrame, size, damage, hitboxConfig)
    local startPosition = hitboxCFrame.Position
    local direction = hitboxCFrame.LookVector
    local speed = hitboxConfig.speed or 200 -- Default speed
    local maxDistance = hitboxConfig.maxDistance or 100 -- Default max distance
    
    -- Perform raycast for hit detection
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character} -- Don't hit self
    
    local raycastResult = workspace:Raycast(startPosition, direction * maxDistance, raycastParams)
    
    -- Calculate hit position
    local hitPosition = raycastResult and raycastResult.Position or (startPosition + direction * maxDistance)
    local actualDistance = (hitPosition - startPosition).Magnitude
    
    -- Create projectile visual
    local projectile = Instance.new("Part")
    projectile.Name = "ProjectileVisual"
    projectile.Size = hitboxConfig.projectileSize or Vector3.new(0.5, 0.5, 3)
    projectile.Material = Enum.Material.Neon
    projectile.Color = hitboxConfig.color or Color3.new(1, 1, 0)
    projectile.Transparency = hitboxConfig.transparency or 0.3
    projectile.CanCollide = false
    projectile.Anchored = true
    projectile.Parent = Workspace
    
    -- Position projectile at start
    local projectileCFrame = CFrame.lookAt(startPosition, hitPosition)
    projectile.CFrame = projectileCFrame
    
    -- Calculate travel time
    local travelTime = actualDistance / speed
    
    -- Animate projectile movement
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / travelTime, 1)
        
        if progress >= 1 then
            -- Projectile reached target
            connection:Disconnect()
            projectile:Destroy()
            
            -- Apply damage at hit location
            local hitCFrame = CFrame.new(hitPosition, hitPosition + direction)
            local hitRequest = ReplicatedStorage:WaitForChild("DynamicHitboxV2Request")
            hitRequest:FireServer(hitCFrame, size, damage, hitboxConfig.name or "Unknown", 1)
            
            -- Create visual hit effect
            createVisualHitbox(hitCFrame, size, hitboxConfig.color, hitboxConfig.transparency, 0.2)
            
            print("[DYNAMIC HITBOX V2] Projectile hit target for", hitboxConfig.name or "Unknown")
        else
            -- Move projectile along path
            local currentPosition = startPosition + (direction * actualDistance * progress)
            projectile.CFrame = CFrame.lookAt(currentPosition, hitPosition)
        end
    end)
    
    -- Safety cleanup after maximum time
    task.delay(travelTime + 1, function()
        if projectile and projectile.Parent then
            projectile:Destroy()
        end
        if connection then
            connection:Disconnect()
        end
    end)
    
    print("[DYNAMIC HITBOX V2] Generated projectile hitbox for", hitboxConfig.name or "Unknown")
end

-- =====================================================================================
-- MANDATORY GLOBAL ACCESS AND DEBUG FUNCTIONS
-- =====================================================================================

-- MANDATORY: Make functions available globally for other scripts
_G.dynamicHitboxV2Generate = DynamicHitboxV2.generateHitbox
_G.dynamicHitboxV2GenerateStatic = DynamicHitboxV2.generateStaticHitbox
_G.dynamicHitboxV2GenerateTraveling = DynamicHitboxV2.generateTravelingHitbox
_G.dynamicHitboxV2GenerateProjectile = DynamicHitboxV2.generateProjectileHitbox

-- MANDATORY: Hitbox type constants for external use
_G.HITBOX_TYPES = HITBOX_TYPES

-- Debug functions
_G.dynamicHitboxV2ToggleVisuals = function()
    SHOW_HITBOX_VISUALS = not SHOW_HITBOX_VISUALS
    print("[DYNAMIC HITBOX V2] Visuals", SHOW_HITBOX_VISUALS and "ENABLED" or "DISABLED")
end

-- MANDATORY: Helper function to create hitbox configs easily
_G.createHitboxConfig = function(type, size, offset, damage, options)
    local config = {
        type = type or HITBOX_TYPES.STATIC,
        size = size or Vector3.new(6, 6, 6),
        offset = offset or Vector3.new(0, 0, 4),
        damage = damage or 25,
        delay = options and options.delay or 0,
        duration = options and options.duration or 0.3,
        tickInterval = options and options.tickInterval, -- MANDATORY for DOT
        color = options and options.color or Color3.new(0, 0, 1),
        transparency = options and options.transparency or 0.7,
        name = options and options.name or "Unknown",
        speed = options and options.speed, -- MANDATORY for traveling/projectile
        maxDistance = options and options.maxDistance, -- MANDATORY for traveling/projectile
        projectileSize = options and options.projectileSize -- MANDATORY for projectile
    }
    return config
end

return DynamicHitboxV2
