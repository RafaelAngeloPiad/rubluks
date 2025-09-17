-- DynamicWeaponHitboxClient: Applies hitbox logic to any equipped Tool with "has_damage" tag

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Tweak these values to change hitbox size and offset
local HITBOX_SIZE = Vector3.new(6, 6, 6) -- width, height, depth of the hitbox
local HITBOX_OFFSET = Vector3.new(0, 0, 4) -- (x, y, z) offset from HumanoidRootPart; z is forward

local function attachHitbox(tool)
    if not tool:IsA("Tool") then return end
    if not CollectionService:HasTag(tool, "has_damage") then return end

    print("[CLIENT] Hitbox attached to tool:", tool.Name)

    local function onActivated()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        -- Calculate hitbox position in front of the player using LookVector
        local rootCFrame = humanoidRootPart.CFrame
        local forwardOffset = rootCFrame.LookVector * HITBOX_OFFSET.Z
        local rightOffset = rootCFrame.RightVector * HITBOX_OFFSET.X
        local upOffset = rootCFrame.UpVector * HITBOX_OFFSET.Y
        local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset

        -- Keep the hitbox aligned with the player's facing direction
        local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

        print("[CLIENT] Tool activated:", tool.Name)
        print("[CLIENT] Sending hit request to server. CFrame:", hitboxCFrame.Position, "Size:", HITBOX_SIZE)
        remote:FireServer(hitboxCFrame, HITBOX_SIZE)

        -- Visualize the hitbox for testing
        local hitboxPart = Instance.new("Part")
        hitboxPart.Size = HITBOX_SIZE
        hitboxPart.CFrame = hitboxCFrame
        hitboxPart.Anchored = true
        hitboxPart.CanCollide = false
        hitboxPart.CanQuery = false
        hitboxPart.CanTouch = false
        hitboxPart.Transparency = 0.5
        hitboxPart.Color = Color3.new(1, 0, 0) -- Solid red
        hitboxPart.Material = Enum.Material.Neon
        hitboxPart.Name = "HitboxVisual"
        hitboxPart.Parent = Workspace

        -- Remove the hitbox after a short delay
        task.delay(0.3, function()
            if hitboxPart then
                hitboxPart:Destroy()
            end
        end)
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

