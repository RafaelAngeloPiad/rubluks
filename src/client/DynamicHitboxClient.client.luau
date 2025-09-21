-- DynamicHitboxClient: Unified hitbox system for weapons and skills
-- Handles hitbox generation for any equipped Tool with "has_damage" tag and skill requests

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Import hitbox configuration (with safe fallback)
local HitboxConfig
local configLoadSuccess, configError = pcall(function()
    HitboxConfig = require(script.Parent.Parent.shared.HitboxConfig)
end)
if not configLoadSuccess then
    -- Try alternative path
    local success2, error2 = pcall(function()
        HitboxConfig = require(game.ReplicatedStorage:WaitForChild("HitboxConfig"))
    end)
    if not success2 then
        HitboxConfig = nil
    end
end

-- Default hitbox values (fallback if config system fails)
local HITBOX_SIZE = Vector3.new(6, 6, 6) -- width, height, depth of the hitbox
local HITBOX_OFFSET = Vector3.new(0, 0, 4) -- (x, y, z) offset from HumanoidRootPart; z is forward
local DEFAULT_DAMAGE = 25

-- =====================================================================================
-- UNIFIED HITBOX GENERATION SYSTEM
-- =====================================================================================

local DynamicHitboxClient = {}

-- Helper function to get weapon hitbox configuration for a tool
local function getHitboxConfig(tool)
    -- If config system is not available, use defaults
    if not HitboxConfig then
        return HITBOX_SIZE, HITBOX_OFFSET, DEFAULT_DAMAGE
    end
    
    -- Check for weapon-specific tags
    local weaponTags = HitboxConfig.getAllWeaponTags()
    for _, weaponTag in ipairs(weaponTags) do
        if CollectionService:HasTag(tool, weaponTag) then
            local config = HitboxConfig.getWeaponConfig(weaponTag)
            return config.size, config.offset, config.baseDamage
        end
    end
    
    -- No specific weapon tag found, use defaults
    return HITBOX_SIZE, HITBOX_OFFSET, DEFAULT_DAMAGE
end

-- Helper function to get skill hitbox configuration
local function getSkillHitboxConfig(skillKey)
    if HitboxConfig then
        local config = HitboxConfig.getSkillConfig(skillKey)
        return config -- Return full config object with timing info
    else
        -- Fallback values if config system isn't available
        return {
            size = Vector3.new(8, 6, 8),
            offset = Vector3.new(0, 0, 5),
            baseDamage = 40,
            name = "Unknown Skill",
            cooldownTime = 2.0,
            castTime = 0.8,
            hitboxDelay = 0.3,
        }
    end
end

-- Create visual hitbox (unified for weapons and skills)
local function createVisualHitbox(hitboxCFrame, size, hitboxType)
    local hitboxPart = Instance.new("Part")
    hitboxPart.Size = size
    hitboxPart.CFrame = hitboxCFrame
    hitboxPart.Anchored = true
    hitboxPart.CanCollide = false
    hitboxPart.CanQuery = false
    hitboxPart.CanTouch = false
    hitboxPart.Material = Enum.Material.Neon
    hitboxPart.Parent = Workspace
    
    -- Different colors and durations for different hitbox types
    if hitboxType == "weapon" then
        hitboxPart.Transparency = 0.7
        hitboxPart.Color = Color3.new(1, 0, 0) -- Red for weapons
        hitboxPart.Name = "WeaponHitboxVisual"
        -- Remove after 0.3 seconds
        task.delay(0.3, function()
            if hitboxPart then
                hitboxPart:Destroy()
            end
        end)
    elseif hitboxType == "skill" then
        hitboxPart.Transparency = 0.7
        hitboxPart.Color = Color3.new(0, 0, 1) -- Blue for skills
        hitboxPart.Name = "SkillHitboxVisual"
        -- Remove after 0.5 seconds (longer for skills)
        task.delay(0.5, function()
            if hitboxPart then
                hitboxPart:Destroy()
            end
        end)
    end
end

-- Generate hitbox for weapon attacks
function DynamicHitboxClient.generateWeaponHitbox(tool)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Get weapon-specific hitbox configuration
    local hitboxSize, hitboxOffset, weaponDamage = getHitboxConfig(tool)

    -- Generate hitbox position in front of the player using LookVector
    local rootCFrame = humanoidRootPart.CFrame
    local forwardOffset = rootCFrame.LookVector * hitboxOffset.Z
    local rightOffset = rootCFrame.RightVector * hitboxOffset.X
    local upOffset = rootCFrame.UpVector * hitboxOffset.Y
    local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset

    -- Align the generated hitbox with the player's facing direction
    local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

    remote:FireServer(hitboxCFrame, hitboxSize, weaponDamage)

    -- Create visual hitbox
    createVisualHitbox(hitboxCFrame, hitboxSize, "weapon")
end

-- =====================================================================================
-- SKILL COOLDOWN SYSTEM
-- =====================================================================================

-- Skill cooldown management functions
local SkillCooldownSystem = {}

function SkillCooldownSystem.isSkillOnCooldown(skillKey, cooldownTime)
    local lastUseTime = _G.skillCooldowns[skillKey] or 0
    local timeSinceLastUse = tick() - lastUseTime
    return timeSinceLastUse < cooldownTime
end

function SkillCooldownSystem.isSkillCasting(skillKey)
    return _G.skillCasting[skillKey] == true
end

function SkillCooldownSystem.setSkillCooldown(skillKey)
    _G.skillCooldowns[skillKey] = tick()
end

function SkillCooldownSystem.setSkillCasting(skillKey, isCasting)
    _G.skillCasting[skillKey] = isCasting
end

function SkillCooldownSystem.getSkillCooldownRemaining(skillKey, cooldownTime)
    local lastUseTime = _G.skillCooldowns[skillKey] or 0
    local timeSinceLastUse = tick() - lastUseTime
    return math.max(0, cooldownTime - timeSinceLastUse)
end

-- Generate hitbox for skill attacks (with cooldown and casting management)
function DynamicHitboxClient.generateSkillHitbox(skillKey)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Get skill-specific configuration including timing
    local skillConfig = getSkillHitboxConfig(skillKey)
    local size, offset, damage = skillConfig.size, skillConfig.offset, skillConfig.baseDamage
    local cooldownTime = skillConfig.cooldownTime or 2.0
    local castTime = skillConfig.castTime or 0.8
    local hitboxDelay = skillConfig.hitboxDelay or 0.3

    -- Check if skill is on cooldown
    if SkillCooldownSystem.isSkillOnCooldown(skillKey, cooldownTime) then
        local remainingTime = SkillCooldownSystem.getSkillCooldownRemaining(skillKey, cooldownTime)
        print(string.format("[SKILL COOLDOWN] ❌ %s on cooldown! %.1fs remaining", skillConfig.name or skillKey, remainingTime))
        return
    end

    -- Check if skill is already casting
    if SkillCooldownSystem.isSkillCasting(skillKey) then
        print(string.format("[SKILL COOLDOWN] ❌ %s already casting!", skillConfig.name or skillKey))
        return
    end

    print(string.format("[SKILL COOLDOWN] ✅ Casting %s (Cast: %.1fs, Cooldown: %.1fs)", skillConfig.name or skillKey, castTime, cooldownTime))

    -- Start casting
    SkillCooldownSystem.setSkillCasting(skillKey, true)
    SkillCooldownSystem.setSkillCooldown(skillKey) -- Set cooldown immediately when cast starts

    -- Schedule hitbox generation after delay
    task.delay(hitboxDelay, function()
        if SkillCooldownSystem.isSkillCasting(skillKey) then -- Only generate if still casting
            -- Calculate hitbox position
            local rootCFrame = humanoidRootPart.CFrame
            local forwardOffset = rootCFrame.LookVector * offset.Z
            local rightOffset = rootCFrame.RightVector * offset.X
            local upOffset = rootCFrame.UpVector * offset.Y
            local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
            local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

            remote:FireServer(hitboxCFrame, size, damage)

            -- Create visual hitbox
            createVisualHitbox(hitboxCFrame, size, "skill")
            
            print(string.format("[SKILL COOLDOWN] 💥 %s hitbox generated!", skillConfig.name or skillKey))
        end
    end)

    -- End casting after cast time
    task.delay(castTime, function()
        SkillCooldownSystem.setSkillCasting(skillKey, false)
        print(string.format("[SKILL COOLDOWN] ⏰ %s cast completed", skillConfig.name or skillKey))
    end)
end

-- Generate hitbox for combo attacks (uses weapon config but allows custom override)
function DynamicHitboxClient.generateComboHitbox(tool, customSize, customOffset, customDamage)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Use custom values if provided, otherwise get weapon config
    local hitboxSize, hitboxOffset, weaponDamage
    if customSize and customOffset and customDamage then
        hitboxSize = customSize
        hitboxOffset = customOffset
        weaponDamage = customDamage
        print("[COMBO HITBOX] Using custom combo hitbox config:", customSize, customOffset, customDamage)
    else
        hitboxSize, hitboxOffset, weaponDamage = getHitboxConfig(tool)
        print("[COMBO HITBOX] Using weapon hitbox config for combo")
    end

    -- Calculate hitbox position
    local rootCFrame = humanoidRootPart.CFrame
    local forwardOffset = rootCFrame.LookVector * hitboxOffset.Z
    local rightOffset = rootCFrame.RightVector * hitboxOffset.X
    local upOffset = rootCFrame.UpVector * hitboxOffset.Y
    local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
    local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

    remote:FireServer(hitboxCFrame, hitboxSize, weaponDamage)

    -- Create visual hitbox (red like weapon attacks)
    createVisualHitbox(hitboxCFrame, hitboxSize, "weapon")
end

-- =====================================================================================
-- COMBO STATE TRACKING (to disable tool activation during combos)
-- =====================================================================================

-- Global combo state tracking
_G.comboSystemActive = false -- Set to true when any combo system is running
_G.lastComboTime = 0 -- Track when last combo attack happened

-- Global skill cooldown tracking
_G.skillCooldowns = {} -- Track last use time for each skill
_G.skillCasting = {} -- Track if skills are currently casting

-- Function to check if we should allow tool activation
local function shouldAllowToolActivation(tool)
    -- Check if this is a berserker weapon with combo system
    if CollectionService:HasTag(tool, "berserker_weapon") then
        local currentTime = tick()
        local timeSinceLastCombo = currentTime - _G.lastComboTime
        
        -- If combo system is active, block tool activation
        if _G.comboSystemActive then
            print("[DYNAMIC HITBOX] ❌ Tool activation blocked - combo system is active")
            return false
        end
        
        -- If recent combo activity, block tool activation (small buffer)
        if timeSinceLastCombo < 0.1 then
            print("[DYNAMIC HITBOX] ❌ Tool activation blocked - recent combo activity")
            return false
        end
    end
    
    return true
end

-- =====================================================================================
-- WEAPON TOOL INTEGRATION (existing functionality)
-- =====================================================================================

local function setupHitboxGeneration(tool)
    if not tool:IsA("Tool") then return end
    if not CollectionService:HasTag(tool, "has_damage") then return end

    local function generateHitbox()
        -- Check if we should allow tool activation
        if not shouldAllowToolActivation(tool) then
            return
        end
        
        print("[DYNAMIC HITBOX] Tool activation allowed - generating weapon hitbox")
        DynamicHitboxClient.generateWeaponHitbox(tool)
    end

    tool.Activated:Connect(generateHitbox)
end

-- Listen for tools equipped by the player
local function onCharacterAdded(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            setupHitboxGeneration(child)
        end
    end)
    -- Setup hitbox generation for already equipped tools
    for i, child in character:GetChildren() do
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            setupHitboxGeneration(child)
        end
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

-- =====================================================================================
-- GLOBAL ACCESS (so other scripts can use skill and combo hitbox generation)
-- =====================================================================================

-- Make skill hitbox generation available globally
_G.generateSkillHitbox = DynamicHitboxClient.generateSkillHitbox

-- Make combo hitbox generation available globally
_G.generateComboHitbox = DynamicHitboxClient.generateComboHitbox

-- Make skill cooldown functions available globally for debugging
_G.getSkillCooldown = function(skillKey, cooldownTime)
    return SkillCooldownSystem.getSkillCooldownRemaining(skillKey, cooldownTime or 2.0)
end

_G.resetSkillCooldown = function(skillKey)
    _G.skillCooldowns[skillKey] = 0
    _G.skillCasting[skillKey] = false
    print(string.format("[SKILL COOLDOWN] ⚙️ Reset cooldown for %s", skillKey))
end

_G.resetAllSkillCooldowns = function()
    _G.skillCooldowns = {}
    _G.skillCasting = {}
    print("[SKILL COOLDOWN] ⚙️ Reset all skill cooldowns")
end

_G.debugSkillCooldowns = function()
    print("[SKILL COOLDOWN DEBUG] Current skill states:")
    for skillKey, lastUse in pairs(_G.skillCooldowns) do
        local isCasting = _G.skillCasting[skillKey] or false
        local timeSinceUse = tick() - lastUse
        print(string.format("  %s: Last used %.1fs ago, Casting: %s", skillKey, timeSinceUse, tostring(isCasting)))
    end
end

-- =====================================================================================
-- EXPORT MODULE
-- =====================================================================================

return DynamicHitboxClient
