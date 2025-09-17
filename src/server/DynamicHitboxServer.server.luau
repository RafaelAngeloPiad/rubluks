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

remote.OnServerEvent:Connect(function(player, generatedHitboxCFrame, hitboxSize, weaponDamage)
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
            if humanoid and not damagedHumanoids[humanoid] then
                humanoid:TakeDamage(damageToApply)
                damagedHumanoids[humanoid] = true
                print("[SERVER] Damaged:", model.Name, "(", damageToApply, "damage)")
            end
        end
    end
end)

