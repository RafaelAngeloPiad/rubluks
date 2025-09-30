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

-- Configuration
local CONFIG = {
    keyCode = Enum.KeyCode.Q,
    weaponTag = "samurai_wpn",
}

-- Functions
local function useSkill()
    if not tool or tool.Parent ~= player.Character then
        return
    end
    
    -- Find the Wakizashi skill event in samurai/events folder
    local samuraiFolder = ReplicatedStorage:WaitForChild("samurai")
    local eventsFolder = samuraiFolder:WaitForChild("events")
    local remote = eventsFolder:WaitForChild("WakizashiSkillEvent")
    
    remote:FireServer()
end

local function onWeaponFound(weaponTool)
    if tool then return end
    
    tool = weaponTool
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
