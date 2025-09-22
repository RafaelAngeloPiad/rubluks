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

-- Create visual hitbox (unified for weapons and skills with custom duration)
local function createVisualHitbox(hitboxCFrame, size, hitboxType, customDuration)
    local hitboxPart = Instance.new("Part")
    hitboxPart.Size = size
    hitboxPart.CFrame = hitboxCFrame
    hitboxPart.Anchored = true
    hitboxPart.CanCollide = false
    hitboxPart.CanQuery = false
    hitboxPart.CanTouch = false
    hitboxPart.Material = Enum.Material.Neon
    hitboxPart.Parent = Workspace
    
    -- Determine duration and visual properties
    local duration, color, name
    if hitboxType == "weapon" then
        duration = customDuration or 0.3 -- Use custom duration or default 0.3s
        color = Color3.new(1, 0, 0) -- Red for weapons
        name = "WeaponHitboxVisual"
    elseif hitboxType == "skill" then
        duration = customDuration or 0.5 -- Use custom duration or default 0.5s
        color = Color3.new(0, 0, 1) -- Blue for skills
        name = "SkillHitboxVisual"
    else
        duration = customDuration or 0.3
        color = Color3.new(1, 1, 1) -- White for unknown
        name = "HitboxVisual"
    end
    
        hitboxPart.Transparency = 0.7
    hitboxPart.Color = color
    hitboxPart.Name = name
    
    -- Remove after specified duration
    print(string.format("[VISUAL HITBOX] %s will last %.2fs", name, duration))
    task.delay(duration, function()
            if hitboxPart then
                hitboxPart:Destroy()
            print(string.format("[VISUAL HITBOX] %s destroyed after %.2fs", name, duration))
            end
        end)
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
    local hitboxDuration = skillConfig.hitboxDuration or 0.5

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

    print(string.format("[SKILL COOLDOWN] ✅ Casting %s (Cast: %.1fs, Cooldown: %.1fs, Duration: %.1fs)", skillConfig.name or skillKey, castTime, cooldownTime, hitboxDuration))

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

            -- Get damage interval configuration
            local damageIntervalConfig = HitboxConfig.getDamageIntervalConfig()
            local damageInterval = damageIntervalConfig.hitboxDamageInterval
            
            -- Check if this should be a DOT hitbox (duration > damage interval)
            if hitboxDuration > damageInterval then
                -- Create DOT hitbox
                local damageInfo = HitboxConfig.calculateDamagePerTick(damage, hitboxDuration)
                local hitboxId = DOTSystem.generateUniqueHitboxId(skillKey, "skill")
                
                print(string.format("[SKILL COOLDOWN] 💥 Creating simple DOT skill hitbox: %d damage every %.1fs for %.1fs", 
                    damage, damageInterval, hitboxDuration))
                
                DOTSystem.createDOTHitbox(hitboxId, hitboxCFrame, size, damage, hitboxDuration, damageInterval, "skill")
            else
                -- Single-hit hitbox (traditional)
                remote:FireServer(hitboxCFrame, size, damage)
                print(string.format("[SKILL COOLDOWN] 💥 Single-hit skill hitbox: %d damage", damage))
            end

            -- Create visual hitbox with custom duration
            createVisualHitbox(hitboxCFrame, size, "skill", hitboxDuration)
            
            print(string.format("[SKILL COOLDOWN] %s visual hitbox lasting %.1fs!", skillConfig.name or skillKey, hitboxDuration))
        end
    end)

    -- End casting after cast time
    task.delay(castTime, function()
        SkillCooldownSystem.setSkillCasting(skillKey, false)
        print(string.format("[SKILL COOLDOWN] ⏰ %s cast completed", skillConfig.name or skillKey))
    end)
end

-- Generate hitbox for combo attacks (uses weapon config but allows custom override with optional delay and duration)
function DynamicHitboxClient.generateComboHitbox(tool, customSize, customOffset, customDamage, customDelay, customDuration)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Use custom values if provided, otherwise get weapon config
    local hitboxSize, hitboxOffset, weaponDamage, hitboxDelay, hitboxDuration
    if customSize and customOffset and customDamage then
        hitboxSize = customSize
        hitboxOffset = customOffset
        weaponDamage = customDamage
        hitboxDelay = customDelay or 0.0 -- Default to immediate if no delay specified
        hitboxDuration = customDuration or 0.3 -- Default to 0.3s if no duration specified
        print(string.format("[COMBO HITBOX] Using custom combo hitbox config: Size=%s, Offset=%s, Damage=%d, Delay=%.2fs, Duration=%.2fs", 
            tostring(customSize), tostring(customOffset), customDamage, hitboxDelay, hitboxDuration))
    else
        hitboxSize, hitboxOffset, weaponDamage = getHitboxConfig(tool)
        hitboxDelay = 0.0 -- Default weapon hitboxes have no delay
        hitboxDuration = 0.3 -- Default weapon hitboxes last 0.3s
        print("[COMBO HITBOX] Using weapon hitbox config for combo")
    end

    -- Apply hitbox delay (like skills)
    local function generateActualHitbox()
        -- Calculate hitbox position
        local rootCFrame = humanoidRootPart.CFrame
        local forwardOffset = rootCFrame.LookVector * hitboxOffset.Z
        local rightOffset = rootCFrame.RightVector * hitboxOffset.X
        local upOffset = rootCFrame.UpVector * hitboxOffset.Y
        local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
        local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

        -- Get damage interval configuration
        local damageIntervalConfig = HitboxConfig.getDamageIntervalConfig()
        local damageInterval = damageIntervalConfig.hitboxDamageInterval
        
        -- Check if this should be a DOT hitbox (duration > damage interval)
        if hitboxDuration > damageInterval then
            -- Create DOT hitbox
            local damageInfo = HitboxConfig.calculateDamagePerTick(weaponDamage, hitboxDuration)
            local hitboxId = DOTSystem.generateUniqueHitboxId("combo", "attack")
            
            print(string.format("[COMBO HITBOX] 💥 Creating simple DOT combo hitbox: %d damage every %.1fs for %.1fs", 
                weaponDamage, damageInterval, hitboxDuration))
            
            DOTSystem.createDOTHitbox(hitboxId, hitboxCFrame, hitboxSize, weaponDamage, hitboxDuration, damageInterval, "weapon")
        else
            -- Single-hit hitbox (traditional)
            remote:FireServer(hitboxCFrame, hitboxSize, weaponDamage)
            print(string.format("[COMBO HITBOX] 💥 Single-hit combo hitbox: %d damage", weaponDamage))
        end

        -- Create visual hitbox (red like weapon attacks) with custom duration
        createVisualHitbox(hitboxCFrame, hitboxSize, "weapon", hitboxDuration)
        
        print(string.format("[COMBO HITBOX] Visual hitbox lasting %.2fs!", hitboxDuration))
    end

    -- Generate hitbox immediately or after delay
    if hitboxDelay > 0 then
        task.delay(hitboxDelay, generateActualHitbox)
    else
        generateActualHitbox()
    end
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

-- Global damage over time tracking
_G.activeDOTHitboxes = {} -- Track active DOT hitboxes
_G.playerDamageImmunity = {} -- Track player immunity to specific hitboxes

-- DOT Hitbox Management System
DOTSystem = {}

function DOTSystem.createDOTHitbox(hitboxId, hitboxCFrame, size, damagePerTick, duration, interval, hitboxType)
    local dotHitbox = {
        id = hitboxId,
        cframe = hitboxCFrame,
        size = size,
        damagePerTick = damagePerTick, -- Full base damage every tick
        duration = duration,
        interval = interval,
        startTime = tick(),
        hitboxType = hitboxType,
        nextTickTime = tick() + interval, -- When next damage tick should happen
        isActive = true
    }
    
    _G.activeDOTHitboxes[hitboxId] = dotHitbox
    
    print(string.format("[DOT SYSTEM] Created simple DOT hitbox %s: %d damage every %.1fs for %.1fs", 
        hitboxId, damagePerTick, interval, duration))
    
    -- Apply first damage immediately
    print(string.format("[DOT SYSTEM] %s tick 1 (immediate) - applying %d damage", hitboxId, damagePerTick))
    remote:FireServer(hitboxCFrame, size, damagePerTick, hitboxId, 1)
    
    -- Start the DOT damage loop for subsequent ticks
    DOTSystem.startDamageLoop(hitboxId)
    
    -- Auto-cleanup after duration
    task.delay(duration, function()
        DOTSystem.removeDOTHitbox(hitboxId)
    end)
    
    return dotHitbox
end

function DOTSystem.startDamageLoop(hitboxId)
    local dotHitbox = _G.activeDOTHitboxes[hitboxId]
    if not dotHitbox then return end
    
    local tickNumber = 1 -- First tick already applied
    
    local function applyNextTick()
        dotHitbox = _G.activeDOTHitboxes[hitboxId] -- Refresh reference
        if not dotHitbox or not dotHitbox.isActive then return end -- Hitbox was removed or expired
        
        local currentTime = tick()
        local elapsedTime = currentTime - dotHitbox.startTime
        
        -- Check if hitbox duration has expired
        if elapsedTime >= dotHitbox.duration then
            print(string.format("[DOT SYSTEM] %s duration expired (%.2fs)", hitboxId, elapsedTime))
            DOTSystem.removeDOTHitbox(hitboxId)
            return
        end
        
        -- Apply damage for this tick
        tickNumber = tickNumber + 1
        print(string.format("[DOT SYSTEM] %s tick %d (%.2fs elapsed) - applying %d damage", 
            hitboxId, tickNumber, elapsedTime, dotHitbox.damagePerTick))
        
        -- Send damage to server
        remote:FireServer(dotHitbox.cframe, dotHitbox.size, dotHitbox.damagePerTick, hitboxId, tickNumber)
        
        -- Schedule next tick if there's still time
        local timeUntilExpiry = dotHitbox.duration - elapsedTime
        if timeUntilExpiry > dotHitbox.interval then
            task.delay(dotHitbox.interval, applyNextTick)
        else
            print(string.format("[DOT SYSTEM] %s no more ticks - %.2fs remaining < %.2fs interval", 
                hitboxId, timeUntilExpiry, dotHitbox.interval))
        end
    end
    
    -- Schedule first interval tick
    task.delay(dotHitbox.interval, applyNextTick)
end

function DOTSystem.removeDOTHitbox(hitboxId)
    if _G.activeDOTHitboxes[hitboxId] then
        _G.activeDOTHitboxes[hitboxId] = nil
        print(string.format("[DOT SYSTEM] Removed DOT hitbox %s", hitboxId))
    end
end

function DOTSystem.generateUniqueHitboxId(skillKey, attackType)
    local timestamp = tostring(tick()):gsub("%.", "_")
    return string.format("%s_%s_%s_%s", player.Name, skillKey or "weapon", attackType or "attack", timestamp)
end

-- Function to check if we should allow tool activation
local function shouldAllowToolActivation(tool)
    -- Check if this is a weapon with combo system
    local weaponTags = {"berserker_weapon", "archer_weapon", "gladiator_weapon", "knight_weapon", "samurai_weapon"}
    
    for _, weaponTag in ipairs(weaponTags) do
        if CollectionService:HasTag(tool, weaponTag) then
            -- For all class weapons, ALWAYS block tool activation
            -- The combo system should handle ALL weapon attacks
            print("[DYNAMIC HITBOX] ❌ Tool activation blocked - " .. weaponTag .. " uses combo system")
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

-- Make DOT system functions available globally for debugging
_G.debugDOTHitboxes = function()
    print("[DOT SYSTEM DEBUG] Active DOT hitboxes:")
    for hitboxId, dotHitbox in pairs(_G.activeDOTHitboxes) do
        local elapsed = tick() - dotHitbox.startTime
        print(string.format("  %s: Tick %d/%d, Elapsed: %.1fs, %d damage per %.1fs", 
            hitboxId, dotHitbox.currentTick, dotHitbox.tickCount, elapsed, dotHitbox.damagePerTick, dotHitbox.interval))
    end
end

_G.clearAllDOTHitboxes = function()
    local count = 0
    for hitboxId, _ in pairs(_G.activeDOTHitboxes) do
        _G.activeDOTHitboxes[hitboxId] = nil
        count = count + 1
    end
    print(string.format("[DOT SYSTEM] Cleared %d active DOT hitboxes", count))
end

_G.getDamageInterval = function()
    if HitboxConfig then
        return HitboxConfig.getDamageInterval()
    end
    return 0.5
end

_G.testDOTCalculations = function()
    if HitboxConfig then
        return HitboxConfig.testDOTCalculations()
    else
        print("[DOT TEST] HitboxConfig not available")
    end
end

-- =====================================================================================
-- EXPORT MODULE
-- =====================================================================================

return DynamicHitboxClient
