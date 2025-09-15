-- DynamicWeaponHitboxServer: Handles hit requests for any Tool with "has_damage" tag

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")

local DAMAGE = 25

local function isValidHitbox(player, tool, hitboxCFrame)
    local character = player.Character
    if not character then 
        print("[SERVER] Invalid hitbox: No character for player", player.Name)
        return false 
    end
    if not tool:IsA("Tool") then 
        print("[SERVER] Invalid hitbox: Tool is not a Tool instance")
        return false 
    end
    local handle = tool:FindFirstChild("Handle")
    if not handle then 
        print("[SERVER] Invalid hitbox: Tool has no Handle")
        return false 
    end
    local distance = (handle.Position - hitboxCFrame.Position).Magnitude
    if distance > 10 then
        print("[SERVER] Invalid hitbox: Distance too far", distance)
        return false
    end
    print("[SERVER] Hitbox validated for tool", tool.Name, "Distance:", distance)
    return true
end

remote.OnServerEvent:Connect(function(player, hitboxCFrame, hitboxSize)
    print("[SERVER] HitRequest received from player:", player.Name, "CFrame:", hitboxCFrame.Position, "Size:", hitboxSize)
    local character = player.Character
    if not character then 
        print("[SERVER] No character for player", player.Name)
        return 
    end

    -- Find equipped tool with "has_damage" tag
    local equippedTool = nil
    for i, child in character:GetChildren() do
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            equippedTool = child
            print("[SERVER] Found equipped tool with damage tag:", child.Name)
            break
        end
    end
    if not equippedTool then 
        print("[SERVER] No equipped tool with damage tag for player", player.Name)
        return 
    end

    -- Validate hitbox position for anti-exploit
    if not isValidHitbox(player, equippedTool, hitboxCFrame) then 
        print("[SERVER] Hitbox validation failed for player", player.Name)
        return 
    end

    local regionParts = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize)
    local damagedHumanoids = {}

    print("[SERVER] Checking region for hit targets. Parts found:", #regionParts)
    for i, part in regionParts do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid and not damagedHumanoids[humanoid] then
                humanoid:TakeDamage(DAMAGE)
                damagedHumanoids[humanoid] = true
                print("[SERVER] Damaged humanoid in model:", model.Name, "Damage:", DAMAGE)
            end
        end
    end
    print("[SERVER] HitRequest processing complete for player:", player.Name)
end)

