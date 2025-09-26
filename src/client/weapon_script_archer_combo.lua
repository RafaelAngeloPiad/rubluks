-- Archer Single Shot System: Handles single arrow shot for archer weapons
-- This module provides a clean, organized single shot system with configurable timing, damage, and hitboxes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitRequest = ReplicatedStorage:WaitForChild("HitRequest")

-- Import hitbox configuration
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
    else
    end
else
end

local ArcherShot = {}

-- Shot state tracking
local shotState = {
    lastShotTime = 0, -- Time of last shot input
    isShooting = false, -- Whether currently performing a shot
    animationStartTime = 0, -- When current animation started
    currentAnimationDuration = 0, -- Duration of current animation
    cooldownTime = 0.1, -- Cooldown between shots in seconds (rapid fire)
    showCooldownText = true, -- Toggle for cooldown text feedback
}

-- Get archer shot configuration (uses unified ARCHER_CONFIG)
local function getShotConfig()
    if HitboxConfig then
        local weaponConfig = HitboxConfig.getWeaponConfig("archer_weapon")
        local archerConfig = HitboxConfig.getArcherConfig()
        
        if weaponConfig and archerConfig then
            return {
                animationId = "rbxassetid://116519685012277",
                duration = archerConfig.shotAnimationDuration,
                hitboxDelay = archerConfig.shotHitboxDelay,
                hitboxDuration = archerConfig.shotHitboxDuration,
                size = weaponConfig.size,
                offset = weaponConfig.offset,
                baseDamage = weaponConfig.baseDamage,
                name = "Rapid Arrow",
                cooldownTime = archerConfig.shotCooldown,
            }
        end
    end
    
    -- Fallback configuration (uses default values)
    return {
        animationId = "rbxassetid://116519685012277",
        duration = 0.3,
        hitboxDelay = 0.1,
        hitboxDuration = 0.2,
        size = Vector3.new(5, 5, 6),
        offset = Vector3.new(0, 0, 3),
        baseDamage = 5,
        name = "Rapid Arrow",
        cooldownTime = 0.1,
    }
end

-- Generate arrow projectile for archer shot using the global projectile system
local function generateShotHitbox(shotConfig, state)
    
    -- Find the equipped archer weapon tool
    local equippedTool = nil
    if state.character then
        for _, child in pairs(state.character:GetChildren()) do
            if child:IsA("Tool") and child.Name:find("Archer") then
                equippedTool = child
                break
            end
        end
    end
    
    if equippedTool then
        -- Use the global arrow projectile function with custom shot config including delay and duration
        if _G.generateArrowProjectile then
            _G.generateArrowProjectile(equippedTool, shotConfig.size, shotConfig.offset, shotConfig.baseDamage, shotConfig.hitboxDelay, shotConfig.hitboxDuration)
        end
    end
end

-- Show shot feedback (always shows attack name - like skill name)
local function showShotFeedback(shotName)
    -- Use centralized announcement system
    if _G.showSkill then
        _G.showSkill(shotName, "archer")
    end
end

-- Show cooldown feedback (can be toggled - like skill cooldown)
local function showCooldownFeedback(remainingTime)
    -- Don't show cooldown text if disabled
    if not shotState.showCooldownText then
        return
    end
    
    -- Use centralized announcement system
    if _G.showCooldown then
        _G.showCooldown(remainingTime)
    end
end

-- Check if shot is on cooldown
local function isShotOnCooldown()
    local currentTime = tick()
    local timeSinceLastShot = currentTime - shotState.lastShotTime
    return timeSinceLastShot < shotState.cooldownTime
end

-- Get remaining cooldown time
local function getRemainingCooldown()
    local currentTime = tick()
    local timeSinceLastShot = currentTime - shotState.lastShotTime
    return math.max(0, shotState.cooldownTime - timeSinceLastShot)
end

-- Execute a single arrow shot
local function executeShot(state, shotConfig)
    if not state.animator or not state.character then
        return
    end
    
    shotState.isShooting = true
    shotState.lastShotTime = tick()
    shotState.animationStartTime = tick()
    shotState.currentAnimationDuration = shotConfig.duration
    
    -- Set the WeaponUtils state to indicate we're attacking
    state.attackPlaying = true
    state.currentAnimState = "Attack"
    
    -- Create and load animation
    local animationObject = Instance.new("Animation")
    animationObject.AnimationId = shotConfig.animationId
    
    local success, track = pcall(function()
        return state.animator:LoadAnimation(animationObject)
    end)
    
    if not success or not track then
        shotState.isShooting = false
        
        -- Set global cooldown even on animation failure
        if _G.setGlobalCooldown then
            _G.setGlobalCooldown()
        end
        
        state.attackPlaying = false
        return
    end
    
    -- Configure animation track
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = false
    
    -- Stop other animations (but preserve WeaponUtils state management)
    if state.idleTrack then state.idleTrack:Stop() end
    if state.runTrack then state.runTrack:Stop() end
    if state.jumpTrack then state.jumpTrack:Stop() end
    if state.climbTrack then state.climbTrack:Stop() end
    
    -- Play animation
    track:Play()
    
    -- Show visual feedback (always show attack name)
    showShotFeedback(shotConfig.name)
    
    -- Generate shot hitbox immediately (delay is handled inside the function)
    generateShotHitbox(shotConfig, state)
    
    -- Wait for the full duration before allowing next shot
    task.delay(shotConfig.duration, function()
        -- Only proceed if this is still the current shot
        if shotState.isShooting then
            -- Reset shot states
            shotState.isShooting = false
            
            -- Set global cooldown to prevent rapid weapon switching
            if _G.setGlobalCooldown then
                _G.setGlobalCooldown()
            end
            
            state.attackPlaying = false
            
            -- Return to idle animation
            if state.idleTrack then
                state.currentAnimState = "Idle"
                state.idleTrack:Play()
            end
        end
    end)
    
    -- Handle animation completion
    local connection
    connection = track.Stopped:Connect(function()
        connection:Disconnect()
    end)
end

-- Main shot function
function ArcherShot.executeShot(state)
    if not state or not state.character or not state.animator then
        warn("[ARCHER SHOT] Invalid state provided - falling back to standard attack")
        return
    end
    
    local config = getShotConfig()
    
    -- Check global cooldown first (prevents rapid weapon switching exploits)
    if _G.canStartNewAttack then
        local canStart, remaining = _G.canStartNewAttack()
        if not canStart then
            return
        end
    end
    
    -- Check if we're already shooting (respect WeaponUtils state)
    if shotState.isShooting or state.attackPlaying then
        -- Show how much time is left in current animation
        if shotState.currentAnimationDuration > 0 then
            local timeElapsed = tick() - shotState.animationStartTime
            local timeRemaining = shotState.currentAnimationDuration - timeElapsed
            if timeRemaining > 0 then
                -- Show cooldown feedback
                local remainingCooldown = getRemainingCooldown()
                if remainingCooldown > 0 then
                    showCooldownFeedback(remainingCooldown)
                end
            end
        end
        return
    end
    
    -- Check if shot is on cooldown
    if isShotOnCooldown() then
        local remaining = getRemainingCooldown()
        showCooldownFeedback(remaining)
        return
    end
    
    -- Safety check: Make sure we're not interfering with other systems
    if state.humanoid and state.humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end
    
    -- Execute the shot
    executeShot(state, config)
end

-- Get current shot state (for debugging)
function ArcherShot.getShotState()
    return {
        isShooting = shotState.isShooting,
        timeSinceLastShot = tick() - shotState.lastShotTime,
        cooldownRemaining = getRemainingCooldown(),
    }
end

-- Reset shot state (useful for testing or when switching weapons)
function ArcherShot.resetShot()
    shotState.isShooting = false
    shotState.lastShotTime = 0
    shotState.animationStartTime = 0
    shotState.currentAnimationDuration = 0
    
    -- Set global cooldown when shot is reset during weapon cleanup
    if _G.setGlobalCooldown then
        _G.setGlobalCooldown()
    end
end

-- Clean up shot system (called when weapon is removed)
function ArcherShot.cleanup()
    ArcherShot.resetShot()
end

-- Check if currently shooting
function ArcherShot.isShooting()
    return shotState.isShooting
end

-- Check if shot is on cooldown
function ArcherShot.isOnCooldown()
    return isShotOnCooldown()
end

-- Debug function to print current shot state
function ArcherShot.debugShotState()
    local state = ArcherShot.getShotState()
    local timeRemaining = 0
    if shotState.currentAnimationDuration > 0 then
        local timeElapsed = tick() - shotState.animationStartTime
        timeRemaining = math.max(0, shotState.currentAnimationDuration - timeElapsed)
    end
    

    return state
end

-- Function to easily adjust shot cooldown (for testing/debugging)
function ArcherShot.setCooldown(newCooldownSeconds)
    shotState.cooldownTime = newCooldownSeconds
    return true
end

-- Function to get current cooldown setting
function ArcherShot.getCooldown()
    return shotState.cooldownTime
end

-- Function to adjust animation duration (for testing/debugging)
function ArcherShot.setAnimationDuration(newDurationSeconds)
    -- This would need to be implemented in the config system
    return false
end

-- Function to get current animation duration
function ArcherShot.getAnimationDuration()
    local config = getShotConfig()
    return config.duration
end

-- Function to check if shot hitbox system is available
function ArcherShot.checkHitboxSystem()
    
    if _G.generateComboHitbox then
        return true
    else
        return false
    end
end

-- Toggle cooldown text display
function ArcherShot.toggleCooldownText()
    shotState.showCooldownText = not shotState.showCooldownText
    return shotState.showCooldownText
end

-- Set cooldown text display state
function ArcherShot.setCooldownTextEnabled(enabled)
    shotState.showCooldownText = enabled
    return shotState.showCooldownText
end

-- Get cooldown text display state
function ArcherShot.getCooldownTextEnabled()
    return shotState.showCooldownText
end

return ArcherShot
