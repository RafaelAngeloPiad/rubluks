-- ========================================
-- WAKIZASHI SKILL CLIENT
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
    keyCode = Enum.KeyCode.Q,
    weaponTag = "samurai_wpn",
}

-- Hitbox configuration for traveling hitbox
local HITBOX_CONFIG = {
    type = "traveling", -- Use traveling hitbox type
    name = "Wakizashi",
    size = Vector3.new(20, 8, 8), -- Hitbox size as it travels (width, height, depth)
    offset = Vector3.new(0, 0, 5), -- Start position offset
    damage = 25, -- Damage per hit
    delay = 2, -- Delay before hitbox starts moving
    duration = 2.5, -- How long the hitbox travels
    speed = 160, -- Speed of the traveling hitbox
    maxDistance = 100, -- Maximum distance it can travel
    color = Color3.new(0, 0, 1), -- Blue
    transparency = 0.6,
}

-- Functions
local function useSkill()
    print("[WAKIZASHI] useSkill() called")
    
    if not tool or tool.Parent ~= player.Character then
        print("[WAKIZASHI] No tool or tool not equipped")
        return
    end
    
    print("[WAKIZASHI] Using skill:", HITBOX_CONFIG.name)
    
    -- Use unified AttackEvent with skill type parameter
    local remote = ReplicatedStorage:WaitForChild("AttackEvent")
    
    remote:FireServer("wakizashi")
    print("[WAKIZASHI] VFX event fired with skill type: wakizashi")
    
    -- Generate hitbox for damage using global access
    if _G.dynamicHitboxV2Generate then
        _G.dynamicHitboxV2Generate(HITBOX_CONFIG)
        print("[WAKIZASHI] Hitbox generation called")
    else
        print("[WAKIZASHI] DynamicHitboxV2 not loaded yet!")
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
            print("[WAKIZASHI] Q key pressed!")
            useSkill()
        end
    end)
    
    print("[WAKIZASHI] Input connection set up for", weaponTool.Name)
end

local function onCharacterAdded(character)
    print("[WAKIZASHI] Character added:", character.Name)
    
    for _, weaponTool in character:GetChildren() do
        print("[WAKIZASHI] Checking tool:", weaponTool.Name, "Tags:", CollectionService:GetTags(weaponTool))
        if weaponTool:IsA("Tool") and CollectionService:HasTag(weaponTool, CONFIG.weaponTag) then
            print("[WAKIZASHI] Found weapon with tag:", CONFIG.weaponTag)
            onWeaponFound(weaponTool)
        end
    end
    
    character.DescendantAdded:Connect(function(desc)
        if desc:IsA("Tool") then
            print("[WAKIZASHI] New tool added:", desc.Name, "Tags:", CollectionService:GetTags(desc))
            if CollectionService:HasTag(desc, CONFIG.weaponTag) then
                print("[WAKIZASHI] Found new weapon with tag:", CONFIG.weaponTag)
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
