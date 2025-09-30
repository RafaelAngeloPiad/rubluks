-- DynamicHitboxV2: Simple hitbox generation system (like V1 but simpler)
-- Just generates hitboxes, no input handling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- =====================================================================================
-- DYNAMIC HITBOX V2 SYSTEM
-- =====================================================================================

local DynamicHitboxV2 = {}

-- Visual hitbox preview toggle
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

-- Generate hitbox for any skill/combo (with DPS support)
function DynamicHitboxV2.generateHitbox(hitboxConfig)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Extract config values
    local size = hitboxConfig.size
    local offset = hitboxConfig.offset
    local damage = hitboxConfig.damage
    local delay = hitboxConfig.delay
    local duration = hitboxConfig.duration
    local tickInterval = hitboxConfig.tickInterval
    local color = hitboxConfig.color
    local transparency = hitboxConfig.transparency

    -- Schedule hitbox generation after delay
    task.delay(delay, function()
        -- Calculate hitbox position
        local rootCFrame = humanoidRootPart.CFrame
        local forwardOffset = rootCFrame.LookVector * offset.Z
        local rightOffset = rootCFrame.RightVector * offset.X
        local upOffset = rootCFrame.UpVector * offset.Y
        local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
        local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

        -- Check if this should be DPS (duration > tickInterval)
        if tickInterval and duration > tickInterval then
            -- DPS hitbox - damage over time
            local startTime = tick()
            local tickNumber = 0
            
            local function applyDamageTick()
                local elapsed = tick() - startTime
                
                -- Stop if duration expired
                if elapsed >= duration then
                    return
                end
                
                tickNumber = tickNumber + 1
                
                -- Send damage tick to server
                local hitRequest = ReplicatedStorage:WaitForChild("DynamicHitboxV2Request")
                hitRequest:FireServer(hitboxCFrame, size, damage, hitboxConfig.name or "Unknown", tickNumber)
                
                -- Schedule next tick if there's still time
                local timeRemaining = duration - elapsed
                if timeRemaining > tickInterval then
                    task.delay(tickInterval, applyDamageTick)
                end
            end
            
            -- Start first tick immediately
            applyDamageTick()
        else
            -- Single hit - damage once
            local hitRequest = ReplicatedStorage:WaitForChild("DynamicHitboxV2Request")
            hitRequest:FireServer(hitboxCFrame, size, damage, hitboxConfig.name or "Unknown", 1)
        end

        -- Create visual hitbox
        createVisualHitbox(hitboxCFrame, size, color, transparency, duration)
        
        print("[DYNAMIC HITBOX V2] Generated hitbox for", hitboxConfig.name or "Unknown")
    end)
end

-- =====================================================================================
-- GLOBAL ACCESS AND DEBUG FUNCTIONS
-- =====================================================================================

-- Make functions available globally
_G.dynamicHitboxV2Generate = DynamicHitboxV2.generateHitbox

-- Debug functions
_G.dynamicHitboxV2ToggleVisuals = function()
    SHOW_HITBOX_VISUALS = not SHOW_HITBOX_VISUALS
    print("[DYNAMIC HITBOX V2] Visuals", SHOW_HITBOX_VISUALS and "ENABLED" or "DISABLED")
end

return DynamicHitboxV2
