-- ========================================
-- WAKIZASHI SKILL CLIENT
-- Ultra-simple Wakizashi skill implementation
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

-- ========================================
-- WAKIZASHI SKILL CONFIGURATION
-- ========================================

local WAKIZASHI_CONFIG = {
    name = "Wakizashi",
    keyCode = Enum.KeyCode.Q,
    weaponTag = "samurai_wpn",
}

-- ========================================
-- WAKIZASHI SKILL VARIABLES
-- ========================================

local tool = nil
local inputConnection = nil

-- ========================================
-- WAKIZASHI SKILL FUNCTIONS
-- ========================================

local function useSkill()
    -- Check if tool is equipped
    if not tool or not tool.Parent or tool.Parent ~= player.Character then
        print("WakizashiSkill: Tool not equipped")
        return
    end
    
    print("WakizashiSkill: Using skill via KEYBIND (not tool.Activated)")
    
    -- Fire server event (use existing AttackEvent)
    local remote = ReplicatedStorage:FindFirstChild("AttackEvent")
    if not remote then
        warn("WakizashiSkill: AttackEvent not found")
        return
    end
    
    remote:FireServer()
end

local function onWeaponFound(weaponTool)
    if tool then return end -- Already have a weapon
    
    tool = weaponTool
    print("WakizashiSkill: Weapon found -", weaponTool.Name)
    
    -- Set up input handling
    inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
        if isProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == WAKIZASHI_CONFIG.keyCode then
            useSkill()
        end
    end)
end

local function onCharacterAdded(character)
    -- Scan for samurai weapon
    for _, weaponTool in character:GetChildren() do
        if weaponTool:IsA("Tool") and CollectionService:HasTag(weaponTool, WAKIZASHI_CONFIG.weaponTag) then
            onWeaponFound(weaponTool)
        end
    end
    
    -- Listen for new tools
    character.DescendantAdded:Connect(function(desc)
        if desc:IsA("Tool") and CollectionService:HasTag(desc, WAKIZASHI_CONFIG.weaponTag) then
            onWeaponFound(desc)
        end
    end)
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Wait for character
if player.Character then
    onCharacterAdded(player.Character)
else
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(char)
    end)
end

print("WakizashiSkill: Client initialized")
