-- ========================================
-- SCAN FOR WEAPON TAG MODULE
-- Modular weapon detection system for tagged tools
-- ========================================

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

-- ========================================
-- WEAPON SCANNER MODULE
-- ========================================
local WeaponScanner = {}
WeaponScanner.__index = WeaponScanner

function WeaponScanner.new(tagName, onWeaponFound, onWeaponRemoved)
    local self = setmetatable({}, WeaponScanner)
    
    self.tagName = tagName
    self.onWeaponFound = onWeaponFound
    self.onWeaponRemoved = onWeaponRemoved
    self.weaponStates = {}
    
    self:_initialize()
    
    return self
end

function WeaponScanner:_initialize()
    -- Listen for tag changes
    CollectionService:GetInstanceAddedSignal(self.tagName):Connect(function(tool)
        if tool:IsA("Tool") then
            self:_setupWeapon(tool)
        end
    end)
    
    CollectionService:GetInstanceRemovedSignal(self.tagName):Connect(function(tool)
        if tool:IsA("Tool") then
            self:_cleanupWeapon(tool)
        end
    end)
    
    -- Listen for tools being parented to Backpack/Character
    if player:FindFirstChildOfClass("Backpack") then
        player.Backpack.DescendantAdded:Connect(function(desc)
            self:_onDescendantAdded(desc)
        end)
        player.Backpack.DescendantRemoving:Connect(function(desc)
            self:_onDescendantRemoving(desc)
        end)
    end
    
    player.CharacterAdded:Connect(function(char)
        char.DescendantAdded:Connect(function(desc)
            self:_onDescendantAdded(desc)
        end)
        char.DescendantRemoving:Connect(function(desc)
            self:_onDescendantRemoving(desc)
        end)
    end)
    
    if player.Character then
        player.Character.DescendantAdded:Connect(function(desc)
            self:_onDescendantAdded(desc)
        end)
        player.Character.DescendantRemoving:Connect(function(desc)
            self:_onDescendantRemoving(desc)
        end)
    end
    
    -- Initial scan
    self:scanForTaggedWeapons()
end

function WeaponScanner:scanForTaggedWeapons()
    -- Scan Backpack and Character for tagged tools
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in backpack:GetChildren() do
            if tool:IsA("Tool") and CollectionService:HasTag(tool, self.tagName) then
                self:_setupWeapon(tool)
            end
        end
    end
    if player.Character then
        for _, tool in player.Character:GetChildren() do
            if tool:IsA("Tool") and CollectionService:HasTag(tool, self.tagName) then
                self:_setupWeapon(tool)
            end
        end
    end
end

function WeaponScanner:_onDescendantAdded(desc)
    if desc:IsA("Tool") and CollectionService:HasTag(desc, self.tagName) then
        self:_setupWeapon(desc)
    end
end

function WeaponScanner:_onDescendantRemoving(desc)
    if desc:IsA("Tool") and self.weaponStates[desc] then
        self:_cleanupWeapon(desc)
    end
end

function WeaponScanner:_setupWeapon(tool)
    if self.weaponStates[tool] then return end
    
    print("[WEAPON SCANNER] Setting up weapon: " .. tool.Name .. " with tag: " .. self.tagName)
    
    local state = {
        tool = tool,
        toolEquipped = false,
        character = nil,
        humanoid = nil,
        animator = nil,
        idleTrack = nil,
        runTrack = nil,
        jumpTrack = nil,
        climbTrack = nil,
        currentAnimState = nil,
        stateConn = nil,
        inputBeganConn = nil,
        inputEndedConn = nil,
    }
    self.weaponStates[tool] = state
    
    -- Call the weapon-specific setup function
    if self.onWeaponFound then
        print("[WEAPON SCANNER] Calling onWeaponFound for: " .. tool.Name)
        self.onWeaponFound(tool, state)
    end
end

function WeaponScanner:getWeaponState(tool)
    return self.weaponStates[tool]
end

function WeaponScanner:_cleanupWeapon(tool)
    local state = self.weaponStates[tool]
    if not state then return end
    
    -- Call the weapon-specific cleanup function
    if self.onWeaponRemoved then
        self.onWeaponRemoved(tool, state)
    end
    
    self.weaponStates[tool] = nil
end

function WeaponScanner:getAllWeaponStates()
    return self.weaponStates
end

function WeaponScanner:destroy()
    for tool, state in pairs(self.weaponStates) do
        self:_cleanupWeapon(tool)
    end
    self.weaponStates = {}
end

return WeaponScanner
