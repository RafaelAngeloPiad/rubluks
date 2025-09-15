-- DynamicWeaponHitboxClient: Applies hitbox logic to any equipped Tool with "has_damage" tag

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")
local player = Players.LocalPlayer

-- Hitbox parameters
local HITBOX_SIZE = Vector3.new(3, 3, 6)
local HITBOX_OFFSET = Vector3.new(0, 0, 3)

local function attachHitbox(tool)
    if not tool:IsA("Tool") then return end
    if not CollectionService:HasTag(tool, "has_damage") then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    print("[CLIENT] Hitbox attached to tool:", tool.Name)

    local function onActivated()
        local character = player.Character or player.CharacterAdded:Wait()
        -- Calculate hitbox CFrame (in front of handle)
        local hitboxCFrame = handle.CFrame * CFrame.new(HITBOX_OFFSET)
        print("[CLIENT] Tool activated:", tool.Name)
        print("[CLIENT] Sending hit request to server. CFrame:", hitboxCFrame.Position, "Size:", HITBOX_SIZE)
        remote:FireServer(hitboxCFrame, HITBOX_SIZE)
    end

    tool.Activated:Connect(onActivated)
end

-- Listen for tools equipped by the player
local function onCharacterAdded(character)
    print("[CLIENT] Character added:", character.Name)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            print("[CLIENT] Tool equipped:", child.Name)
            attachHitbox(child)
        end
    end)
    -- Attach to already equipped tools
    for i, child in character:GetChildren() do
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            print("[CLIENT] Tool already equipped:", child.Name)
            attachHitbox(child)
        end
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

