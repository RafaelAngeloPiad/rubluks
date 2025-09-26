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
    print("[PVP] Player vs Player damage", enabled and "ENABLED" or "DISABLED")
end

_G.getPVPEnabled = function()
    return PVP_ENABLED
end

_G.togglePVP = function()
    PVP_ENABLED = not PVP_ENABLED
    print("[PVP] Player vs Player damage", PVP_ENABLED and "ENABLED" or "DISABLED")
    return PVP_ENABLED
end

-- Debug function to check PvP status
_G.debugPVP = function()
    print("[PVP DEBUG] PvP Enabled:", PVP_ENABLED)
    print("[PVP DEBUG] Players in game:", #Players:GetPlayers())
    for _, player in pairs(Players:GetPlayers()) do
        print("[PVP DEBUG] Player:", player.Name, "UserId:", player.UserId)
    end
end

-- Test function to manually enable PvP
_G.testPVP = function()
    print("[PVP TEST] Setting PvP to enabled")
    PVP_ENABLED = true
    print("[PVP TEST] PvP is now:", PVP_ENABLED)
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
    print("[PVP DEBUG] Hitbox request from", player.Name, "damage:", weaponDamage or DEFAULT_DAMAGE)
    
    -- Use weapon-specific damage or fallback to default
    local damageToApply = weaponDamage or DEFAULT_DAMAGE
    local character = player.Character
    if not character then 
        print("[PVP DEBUG] No character found for", player.Name)
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
        print("[PVP DEBUG] No equipped tool with has_damage tag found for", player.Name)
        return 
    end

    print("[PVP DEBUG] Using tool:", currentEquippedTool.Name, "for", player.Name)

    -- Validate generated hitbox position for anti-exploit
    if not validateGeneratedHitbox(player, currentEquippedTool, generatedHitboxCFrame) then 
        print("[SERVER] Hitbox validation failed for", player.Name, "with tool", currentEquippedTool.Name)
        return 
    end

    local regionParts = workspace:GetPartBoundsInBox(generatedHitboxCFrame, hitboxSize)
    local damagedHumanoids = {}
    
    print("[PVP DEBUG] Found", #regionParts, "parts in hitbox area")

    for i, part in regionParts do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local humanoid = model:FindFirstChild("Humanoid")
            local targetPlayer = game.Players:GetPlayerFromCharacter(model)
            
            print("[PVP DEBUG] Checking part:", part.Name, "model:", model and model.Name or "nil", "targetPlayer:", targetPlayer and targetPlayer.Name or "nil")
            
            if humanoid and not damagedHumanoids[humanoid] then
                local canDamage = true
                
                -- Simple PvP check: if target is a player and PvP is disabled, don't damage
                if targetPlayer and not PVP_ENABLED then
                    print("[PVP DEBUG] PvP disabled, cannot damage player", targetPlayer.Name)
                    canDamage = false
                elseif targetPlayer and PVP_ENABLED then
                    print("[PVP DEBUG] PvP enabled, can damage player", targetPlayer.Name)
                end
                
                if canDamage then
                    humanoid:TakeDamage(damageToApply)
                    damagedHumanoids[humanoid] = true
                    print("[SERVER] Applied", damageToApply, "damage to", model.Name, "from", player.Name)
                else
                    print("[PVP DEBUG] Damage blocked for", model.Name, "from", player.Name)
                end
            end
        end
    end
end)

