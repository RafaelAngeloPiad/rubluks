-- DynamicHitboxServer: Processes generated hitbox requests for weapons and skills

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")

local DEFAULT_DAMAGE = 1000 -- Fallback damage if none specified - significantly increased

-- Simple PvP toggle
local PVP_ENABLED = true -- Set to false to disable player vs player damage

-- Simple PvP control functions
_G.setPVPEnabled = function(enabled)
    PVP_ENABLED = enabled
end

_G.getPVPEnabled = function()
    return PVP_ENABLED
end

_G.togglePVP = function()
    PVP_ENABLED = not PVP_ENABLED
    return PVP_ENABLED
end

-- Debug function to check PvP status
_G.debugPVP = function()
end

-- Test function to manually enable PvP
_G.testPVP = function()
    PVP_ENABLED = true
end

local function validateGeneratedHitbox(player, equippedTool, hitboxCFrame)
    local character = player.Character
    if not character then 
        return false 
    end
    if not equippedTool:IsA("Tool") then 
        return false 
    end
    local handle = equippedTool:FindFirstChild("Handle")
    if not handle then 
        return false 
    end
    
    -- Check if this is an archer weapon (allow long range for projectiles)
    local isArcherWeapon = false
    if CollectionService:HasTag(equippedTool, "archer_weapon") then
        isArcherWeapon = true
    end
    
    -- For archer weapons, allow much longer range (up to 1000 studs)
    -- For other weapons, keep the 10-stud limit for anti-exploit
    local maxDistance = isArcherWeapon and 1000 or 10
    local distance = (handle.Position - hitboxCFrame.Position).Magnitude
    
    if distance > maxDistance then
        return false
    end
    return true
end


remote.OnServerEvent:Connect(function(player, generatedHitboxCFrame, hitboxSize, weaponDamage, hitboxId, tickNumber)
    
    -- Use weapon-specific damage or fallback to default
    local damageToApply = weaponDamage or DEFAULT_DAMAGE
    local character = player.Character
    if not character then 
        return 
    end

    -- Find currently equipped tool with "has_damage" tag
    local currentEquippedTool = nil
    for i, child in character:GetChildren() do
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            currentEquippedTool = child
            break
        end
    end
    if not currentEquippedTool then 
        return 
    end


    -- Validate generated hitbox position for anti-exploit
    if not validateGeneratedHitbox(player, currentEquippedTool, generatedHitboxCFrame) then 
        return 
    end

    local regionParts = workspace:GetPartBoundsInBox(generatedHitboxCFrame, hitboxSize)
    local damagedHumanoids = {}
    

    for i, part in regionParts do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local humanoid = model:FindFirstChild("Humanoid")
            local targetPlayer = game.Players:GetPlayerFromCharacter(model)
            
            
            if humanoid and not damagedHumanoids[humanoid] then
                local canDamage = true
                
                -- Simple PvP check: if target is a player and PvP is disabled, don't damage
                if targetPlayer and not PVP_ENABLED then
                    canDamage = false
                elseif targetPlayer and PVP_ENABLED then
                end
                
                if canDamage then
                    humanoid:TakeDamage(damageToApply)
                    damagedHumanoids[humanoid] = true
                else
                end
            end
        end
    end
end)

