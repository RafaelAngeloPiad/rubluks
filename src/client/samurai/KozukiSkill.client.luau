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

-- Configuration
local CONFIG = {
    keyCode = Enum.KeyCode.E,
    weaponTag = "samurai_wpn",
}

-- Functions
local function useSkill()
    if not tool or tool.Parent ~= player.Character then
        return
    end
    
    -- Just fire server - server handles EVERYTHING (VFX + Hitbox)
    local remote = ReplicatedStorage:WaitForChild("AttackEvent")
    remote:FireServer("kozuki")
end

local function onWeaponFound(weaponTool)
    tool = weaponTool
    
    -- Disconnect existing connection if any
    if inputConnection then
        inputConnection:Disconnect()
    end
    
    inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
        if not isProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keyCode then
            useSkill()
        end
    end)
end

local function onCharacterAdded(character)
    for _, weaponTool in character:GetChildren() do
        if weaponTool:IsA("Tool") and CollectionService:HasTag(weaponTool, CONFIG.weaponTag) then
            onWeaponFound(weaponTool)
        end
    end
    
    character.DescendantAdded:Connect(function(desc)
        if desc:IsA("Tool") and CollectionService:HasTag(desc, CONFIG.weaponTag) then
            onWeaponFound(desc)
        end
    end)
end

-- Initialize
if player.Character then
    onCharacterAdded(player.Character)
else
    player.CharacterAdded:Connect(onCharacterAdded)
end
