-- DynamicHitboxV2: Unified server for all V2 hitboxes
-- Simple server that handles all V2 hitbox requests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create remote event for V2 hitboxes
local v2Remote = Instance.new("RemoteEvent")
v2Remote.Name = "DynamicHitboxV2Request"
v2Remote.Parent = ReplicatedStorage

-- PvP settings
local PVP_ENABLED = true

-- PvP control functions
_G.setV2PVPEnabled = function(enabled)
    PVP_ENABLED = enabled
   --print("[DYNAMIC HITBOX V2 SERVER] PvP", enabled and "ENABLED" or "DISABLED")
end

_G.getV2PVPEnabled = function()
    return PVP_ENABLED
end

_G.toggleV2PVP = function()
    PVP_ENABLED = not PVP_ENABLED
   --print("[DYNAMIC HITBOX V2 SERVER] PvP", PVP_ENABLED and "ENABLED" or "DISABLED")
    return PVP_ENABLED
end

-- Validate hitbox position (anti-exploit)
local function validateV2Hitbox(player, hitboxCFrame)
    local character = player.Character
    if not character then 
        return false 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        return false 
    end
    
    -- Check distance (max studs for V2 hitboxes)
    local maxDistance = 1000
    local distance = (humanoidRootPart.Position - hitboxCFrame.Position).Magnitude
    
    if distance > maxDistance then
       --print("[DYNAMIC HITBOX V2 SERVER] Hitbox too far from player:", distance, "studs (max:", maxDistance, ")")
        return false
    end
    
   --print("[DYNAMIC HITBOX V2 SERVER] Hitbox distance:", distance, "studs (within limit)")
    
    return true
end

-- Process V2 hitbox
v2Remote.OnServerEvent:Connect(function(player, hitboxCFrame, hitboxSize, damage, skillName, tickNumber)
   --print("[DYNAMIC HITBOX V2 SERVER] Received hitbox from", player.Name, "for skill:", skillName, "tick:", tickNumber or 1)
    
    local character = player.Character
    if not character then 
       --print("[DYNAMIC HITBOX V2 SERVER] No character found for player")
        return 
    end

    -- Validate hitbox position
    if not validateV2Hitbox(player, hitboxCFrame) then
       --print("[DYNAMIC HITBOX V2 SERVER] Hitbox validation failed for", player.Name)
        return 
    end

    -- Find targets in hitbox
    local regionParts = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize)
    local damagedHumanoids = {}
    
   --print("[DYNAMIC HITBOX V2 SERVER] Found", #regionParts, "parts in hitbox")

    for _, part in regionParts do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local humanoid = model:FindFirstChild("Humanoid")
            local targetPlayer = Players:GetPlayerFromCharacter(model)
            
            if humanoid and not damagedHumanoids[humanoid] then
                local canDamage = true
                
                -- PvP check
                if targetPlayer and not PVP_ENABLED then
                    canDamage = false
                   --print("[DYNAMIC HITBOX V2 SERVER] PvP disabled, not damaging player:", targetPlayer.Name)
                end
                
                if canDamage then
                    humanoid:TakeDamage(damage)
                    damagedHumanoids[humanoid] = true
                   --print("[DYNAMIC HITBOX V2 SERVER] Damaged", targetPlayer and targetPlayer.Name or "NPC", "for", damage, "damage")
                end
            end
        end
    end
    
   --print("[DYNAMIC HITBOX V2 SERVER] Hitbox processed, damaged", #damagedHumanoids, "targets")
end)

print("[DYNAMIC HITBOX V2 SERVER] V2 hitbox server initialized")
