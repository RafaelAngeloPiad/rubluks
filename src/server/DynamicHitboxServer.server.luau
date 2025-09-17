-- DynamicHitboxServer: Processes generated hitbox requests for weapons and skills

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")

local DEFAULT_DAMAGE = 25 -- Fallback damage if none specified

local function validateGeneratedHitbox(player, equippedTool, hitboxCFrame)
    local character = player.Character
    if not character then 
        print("[SERVER] Invalid hitbox: No character for player", player.Name)
        return false 
    end
    if not equippedTool:IsA("Tool") then 
        print("[SERVER] Invalid hitbox: Equipped item is not a Tool instance")
        return false 
    end
    local handle = equippedTool:FindFirstChild("Handle")
    if not handle then 
        print("[SERVER] Invalid hitbox: Equipped tool has no Handle")
        return false 
    end
    local distance = (handle.Position - hitboxCFrame.Position).Magnitude
    if distance > 10 then
        print("[SERVER] Invalid hitbox: Generated hitbox too far from tool", distance)
        return false
    end
    print("[SERVER] Generated hitbox validated for tool", equippedTool.Name, "Distance:", distance)
    return true
end

remote.OnServerEvent:Connect(function(player, generatedHitboxCFrame, hitboxSize, weaponDamage)
    -- Use weapon-specific damage or fallback to default
    local damageToApply = weaponDamage or DEFAULT_DAMAGE
    print("[SERVER] Hitbox request received from player:", player.Name, "CFrame:", generatedHitboxCFrame.Position, "Size:", hitboxSize, "Damage:", damageToApply)
    local character = player.Character
    if not character then 
        print("[SERVER] No character for player", player.Name)
        return 
    end

    -- Find currently equipped tool with "has_damage" tag
    local currentEquippedTool = nil
    for i, child in character:GetChildren() do
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            currentEquippedTool = child
            print("[SERVER] Found currently equipped tool with damage tag:", child.Name)
            break
        end
    end
    if not currentEquippedTool then 
        print("[SERVER] No currently equipped tool with damage tag for player", player.Name)
        return 
    end

    -- Validate generated hitbox position for anti-exploit
    if not validateGeneratedHitbox(player, currentEquippedTool, generatedHitboxCFrame) then 
        print("[SERVER] Generated hitbox validation failed for player", player.Name)
        return 
    end

    local regionParts = workspace:GetPartBoundsInBox(generatedHitboxCFrame, hitboxSize)
    local damagedHumanoids = {}

    print("[SERVER] Checking generated hitbox region for hit targets. Parts found:", #regionParts)
    for i, part in regionParts do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid and not damagedHumanoids[humanoid] then
                humanoid:TakeDamage(damageToApply)
                damagedHumanoids[humanoid] = true
                print("[SERVER] Damaged humanoid in model:", model.Name, "with damage:", damageToApply)
            end
        end
    end
    print("[SERVER] Generated hitbox request processing complete for player:", player.Name)
end)

