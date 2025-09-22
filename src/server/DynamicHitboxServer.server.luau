-- DynamicHitboxServer: Processes generated hitbox requests for weapons and skills

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")

local DEFAULT_DAMAGE = 25 -- Fallback damage if none specified

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
    local distance = (handle.Position - hitboxCFrame.Position).Magnitude
    if distance > 10 then
        return false
    end
    return true
end

-- Track player damage immunity for DOT hitboxes
local playerDamageImmunity = {} -- [playerId][hitboxId] = lastDamageTime

remote.OnServerEvent:Connect(function(player, generatedHitboxCFrame, hitboxSize, weaponDamage, hitboxId, tickNumber)
    -- Use weapon-specific damage or fallback to default
    local damageToApply = weaponDamage or DEFAULT_DAMAGE
    local character = player.Character
    if not character then 
        return 
    end
    
    -- Initialize immunity tracking for this player if needed
    if not playerDamageImmunity[player.UserId] then
        playerDamageImmunity[player.UserId] = {}
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
                
                -- Check DOT immunity if this is a DOT hitbox
                if hitboxId and targetPlayer then
                    local targetUserId = targetPlayer.UserId
                    if not playerDamageImmunity[targetUserId] then
                        playerDamageImmunity[targetUserId] = {}
                    end
                    
                    local lastDamageTime = playerDamageImmunity[targetUserId][hitboxId] or 0
                    local timeSinceLastDamage = tick() - lastDamageTime
                    
                    -- Prevent damage if hit too recently by this specific DOT hitbox
                    if timeSinceLastDamage < 0.4 then -- 0.4s immunity per DOT tick
                        canDamage = false
                    else
                        -- Update last damage time for this DOT hitbox
                        playerDamageImmunity[targetUserId][hitboxId] = tick()
                    end
                end
                
                if canDamage then
                    humanoid:TakeDamage(damageToApply)
                    damagedHumanoids[humanoid] = true
                end
            end
        end
    end
end)

