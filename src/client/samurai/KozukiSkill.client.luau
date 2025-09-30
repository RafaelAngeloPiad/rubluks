-- ========================================
-- KOZUKI SKILL CLIENT
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local tool = nil
local inputConnection = nil

-- DynamicHitboxV2 will be available globally after it loads

-- Configuration
local CONFIG = {
    keyCode = Enum.KeyCode.E,
    weaponTag = "samurai_wpn",
}

-- Hitbox configuration for static hitbox with DOT (as requested)
local HITBOX_CONFIG = {
    type = "static", -- Use static hitbox type
    name = "Kozuki",
    size = Vector3.new(12, 8, 55), -- Hitbox size (width, height, depth)
    offset = Vector3.new(0, 0, -30), --from Player Offset X = left/right, Y = top/down, Z = forward/back
    damage = 15, -- Damage per tick (reduced since it's DOT)
    delay = 2.1, -- Delay before hitbox activates (after dash)
    duration = 3, -- How long the hitbox stays active (increased for DOT)
    tickInterval = 0.5, -- Damage every 0.5 seconds (DOT)
    color = Color3.new(1, 0, 0), -- Red
    transparency = 0.6,
}

-- Functions
local function useSkill()
    print("[KOZUKI] useSkill() called")
    
    if not tool or tool.Parent ~= player.Character then
        print("[KOZUKI] No tool or tool not equipped")
        return
    end
    
    print("[KOZUKI] Using skill:", HITBOX_CONFIG.name)
    
    -- Find the Kozuki skill event in samurai/events folder
    local samuraiFolder = ReplicatedStorage:WaitForChild("samurai")
    local eventsFolder = samuraiFolder:WaitForChild("events")
    local remote = eventsFolder:WaitForChild("KozukiSkillEvent")
    
    remote:FireServer()
    print("[KOZUKI] VFX event fired")
    
    -- Generate hitbox for damage using global access
    if _G.dynamicHitboxV2Generate then
        _G.dynamicHitboxV2Generate(HITBOX_CONFIG)
        print("[KOZUKI] Hitbox generation called")
    else
        print("[KOZUKI] DynamicHitboxV2 not loaded yet!")
    end
end

local function onWeaponFound(weaponTool)
    tool = weaponTool
    
    -- Disconnect existing connection if any
    if inputConnection then
        inputConnection:Disconnect()
    end
    
    inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
        if not isProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keyCode then
            print("[KOZUKI] E key pressed!")
            useSkill()
        end
    end)
    
    print("[KOZUKI] Input connection set up for", weaponTool.Name)
end

local function onCharacterAdded(character)
    print("[KOZUKI] Character added:", character.Name)
    
    for _, weaponTool in character:GetChildren() do
        print("[KOZUKI] Checking tool:", weaponTool.Name, "Tags:", CollectionService:GetTags(weaponTool))
        if weaponTool:IsA("Tool") and CollectionService:HasTag(weaponTool, CONFIG.weaponTag) then
            print("[KOZUKI] Found weapon with tag:", CONFIG.weaponTag)
            onWeaponFound(weaponTool)
        end
    end
    
    character.DescendantAdded:Connect(function(desc)
        if desc:IsA("Tool") then
            print("[KOZUKI] New tool added:", desc.Name, "Tags:", CollectionService:GetTags(desc))
            if CollectionService:HasTag(desc, CONFIG.weaponTag) then
                print("[KOZUKI] Found new weapon with tag:", CONFIG.weaponTag)
                onWeaponFound(desc)
            end
        end
    end)
end

-- Initialize
if player.Character then
    onCharacterAdded(player.Character)
else
    player.CharacterAdded:Connect(onCharacterAdded)
end
