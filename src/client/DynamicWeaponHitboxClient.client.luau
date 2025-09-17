-- DynamicWeaponHitboxClient: Generates dynamic hitboxes for any equipped Tool with "has_damage" tag

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Import weapon configuration (with safe fallback)
local WeaponHitboxConfig
local configLoadSuccess, configError = pcall(function()
    WeaponHitboxConfig = require(script.Parent.Parent.shared.WeaponHitboxConfig)
end)
if not configLoadSuccess then
    print("[CLIENT] Warning: Could not load WeaponHitboxConfig:", configError)
    print("[CLIENT] Trying alternative path...")
    -- Try alternative path
    local success2, error2 = pcall(function()
        WeaponHitboxConfig = require(game.ReplicatedStorage:WaitForChild("WeaponHitboxConfig"))
    end)
    if not success2 then
        print("[CLIENT] Alternative path also failed:", error2)
        WeaponHitboxConfig = nil
    else
        print("[CLIENT] Successfully loaded WeaponHitboxConfig from ReplicatedStorage")
    end
else
    print("[CLIENT] Successfully loaded WeaponHitboxConfig from shared folder")
end

-- Default hitbox values (fallback if config system fails)
local HITBOX_SIZE = Vector3.new(6, 6, 6) -- width, height, depth of the hitbox
local HITBOX_OFFSET = Vector3.new(0, 0, 4) -- (x, y, z) offset from HumanoidRootPart; z is forward

-- Helper function to get hitbox configuration for a tool
local function getHitboxConfig(tool)
    -- If config system is not available, use defaults
    if not WeaponHitboxConfig then
        print("[CLIENT] WeaponHitboxConfig not loaded, using defaults")
        return HITBOX_SIZE, HITBOX_OFFSET
    end
    
    -- Debug: Print all tags on this tool
    local allTags = CollectionService:GetTags(tool)
    print("[CLIENT] Tool", tool.Name, "has tags:", table.concat(allTags, ", "))
    
    -- Check for weapon-specific tags
    local weaponTags = WeaponHitboxConfig.getAllWeaponTags()
    print("[CLIENT] Available weapon tags:", table.concat(weaponTags, ", "))
    
    for _, weaponTag in ipairs(weaponTags) do
        if CollectionService:HasTag(tool, weaponTag) then
            local config = WeaponHitboxConfig.getWeaponConfig(weaponTag)
            print("[CLIENT] ✅ Using", weaponTag, "hitbox config - Size:", config.size, "Offset:", config.offset)
            return config.size, config.offset
        end
    end
    
    -- No specific weapon tag found, use defaults
    print("[CLIENT] ❌ No weapon tag found, using default hitbox config")
    print("[CLIENT] Tool needs one of these tags:", table.concat(weaponTags, ", "))
    return HITBOX_SIZE, HITBOX_OFFSET
end

local function setupHitboxGeneration(tool)
    if not tool:IsA("Tool") then return end
    if not CollectionService:HasTag(tool, "has_damage") then return end

    print("[CLIENT] Hitbox generation setup for tool:", tool.Name)
    print("[CLIENT] About to call getHitboxConfig...")
    
    -- Get weapon-specific hitbox configuration
    local hitboxSize, hitboxOffset = getHitboxConfig(tool)
    
    print("[CLIENT] Got hitbox config - Size:", hitboxSize, "Offset:", hitboxOffset)

    local function generateHitbox()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        -- Generate hitbox position in front of the player using LookVector
        local rootCFrame = humanoidRootPart.CFrame
        local forwardOffset = rootCFrame.LookVector * hitboxOffset.Z
        local rightOffset = rootCFrame.RightVector * hitboxOffset.X
        local upOffset = rootCFrame.UpVector * hitboxOffset.Y
        local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset

        -- Align the generated hitbox with the player's facing direction
        local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

        print("[CLIENT] Tool activated:", tool.Name)
        print("[CLIENT] Sending generated hitbox request to server. CFrame:", hitboxCFrame.Position, "Size:", hitboxSize)
        remote:FireServer(hitboxCFrame, hitboxSize)

        -- Visualize the generated hitbox for testing
        local hitboxPart = Instance.new("Part")
        hitboxPart.Size = hitboxSize
        hitboxPart.CFrame = hitboxCFrame
        hitboxPart.Anchored = true
        hitboxPart.CanCollide = false
        hitboxPart.CanQuery = false
        hitboxPart.CanTouch = false
        hitboxPart.Transparency = 0.5
        hitboxPart.Color = Color3.new(1, 0, 0) -- Solid red
        hitboxPart.Material = Enum.Material.Neon
        hitboxPart.Name = "GeneratedHitboxVisual"
        hitboxPart.Parent = Workspace

        -- Remove the generated hitbox visual after a short delay
        task.delay(0.3, function()
            if hitboxPart then
                hitboxPart:Destroy()
            end
        end)
    end

    tool.Activated:Connect(generateHitbox)
end

-- Listen for tools equipped by the player
local function onCharacterAdded(character)
    print("[CLIENT] Character added:", character.Name)
    character.ChildAdded:Connect(function(child)
        print("[CLIENT] Child added to character:", child.Name, "Type:", child.ClassName)
        if child:IsA("Tool") then
            local allTags = CollectionService:GetTags(child)
            print("[CLIENT] Tool", child.Name, "has tags:", table.concat(allTags, ", "))
            if CollectionService:HasTag(child, "has_damage") then
                print("[CLIENT] Tool equipped:", child.Name)
                setupHitboxGeneration(child)
            else
                print("[CLIENT] Tool", child.Name, "does NOT have 'has_damage' tag")
            end
        end
    end)
    -- Setup hitbox generation for already equipped tools
    for i, child in character:GetChildren() do
        if child:IsA("Tool") then
            local allTags = CollectionService:GetTags(child)
            print("[CLIENT] Existing tool", child.Name, "has tags:", table.concat(allTags, ", "))
            if CollectionService:HasTag(child, "has_damage") then
                print("[CLIENT] Tool already equipped:", child.Name)
                setupHitboxGeneration(child)
            else
                print("[CLIENT] Existing tool", child.Name, "does NOT have 'has_damage' tag")
            end
        end
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

