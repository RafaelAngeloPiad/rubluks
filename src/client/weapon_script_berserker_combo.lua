-- Berserker Combo System: Handles 3-attack combo system for berserker weapons
-- This module provides a clean, organized combo system with configurable timing, damage, and hitboxes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitRequest = ReplicatedStorage:WaitForChild("HitRequest")

-- Import hitbox configuration
local HitboxConfig
local configLoadSuccess, configError = pcall(function()
    HitboxConfig = require(script.Parent.Parent.shared.HitboxConfig)
end)
if not configLoadSuccess then
    print("[BERSERKER COMBO] Failed to load HitboxConfig from shared folder:", configError)
    -- Try alternative path
    local success2, error2 = pcall(function()
        HitboxConfig = require(game.ReplicatedStorage:WaitForChild("HitboxConfig"))
    end)
    if not success2 then
        print("[BERSERKER COMBO] Failed to load HitboxConfig from ReplicatedStorage:", error2)
        HitboxConfig = nil
    else
        print("[BERSERKER COMBO] Successfully loaded HitboxConfig from ReplicatedStorage")
    end
else
    print("[BERSERKER COMBO] Successfully loaded HitboxConfig from shared folder")
end

local BerserkerCombo = {}

-- Combo state tracking
local comboState = {
    currentCombo = 0, -- 0 = no combo, 1-3 = current attack in combo
    lastAttackTime = 0, -- Time of last attack input
    isAttacking = false, -- Whether currently performing an attack
    comboResetThread = nil, -- Thread for combo reset timer
    animationStartTime = 0, -- When current animation started
    currentAnimationDuration = 0, -- Duration of current animation
}

-- Get berserker combo configuration
local function getComboConfig()
    if HitboxConfig then
        local config = HitboxConfig.getComboConfig("berserker_weapon")
        if config then
            print("[BERSERKER COMBO] Using HitboxConfig combo configuration")
            return config
        else
            print("[BERSERKER COMBO] HitboxConfig returned nil, using fallback")
        end
    else
        print("[BERSERKER COMBO] HitboxConfig not available, using fallback configuration")
    end
    
    -- Fallback configuration
    return {
        comboWindow = 2.0,
        resetTime = 3.0,
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.8,
            hitboxDelay = 0.3,
            hitboxDuration = 0.4,
            size = Vector3.new(5, 5, 3),
            offset = Vector3.new(0, 0, 1.5),
            baseDamage = 8,
            name = "Default Strike 1",
        },
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.0,
            hitboxDelay = 0.2,
            hitboxDuration = 0.5,
            size = Vector3.new(6, 5, 4),
            offset = Vector3.new(0, 0, 2),
            baseDamage = 10,
            name = "Default Strike 2",
        },
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.2,
            hitboxDelay = 0.4,
            hitboxDuration = 0.6,
            size = Vector3.new(7, 6, 5),
            offset = Vector3.new(0, 0, 2.5),
            baseDamage = 15,
            name = "Default Finisher",
        },
    }
end

-- Generate hitbox for combo attack using weapon hitbox system
local function generateComboHitbox(attackConfig, state)
    print(string.format("[BERSERKER COMBO] Generating weapon hitbox for attack %d: %s", comboState.currentCombo, attackConfig.name))
    
    -- Find the equipped berserker weapon tool
    local equippedTool = nil
    if state.character then
        for _, child in pairs(state.character:GetChildren()) do
            if child:IsA("Tool") and child.Name:find("Berserker") then
                equippedTool = child
                break
            end
        end
    end
    
    if equippedTool then
        print("[BERSERKER COMBO] Found berserker weapon tool:", equippedTool.Name)
        
        -- Use the DynamicHitboxClient to generate weapon hitbox (red color)
        -- This will use the weapon's configuration from HitboxConfig.luau automatically
        local DynamicHitboxClient = require(script.Parent.Parent.DynamicHitboxClient)
        if DynamicHitboxClient and DynamicHitboxClient.generateWeaponHitbox then
            print("[BERSERKER COMBO] Using DynamicHitboxClient.generateWeaponHitbox (red weapon hitbox)")
            DynamicHitboxClient.generateWeaponHitbox(equippedTool)
        else
            warn("[BERSERKER COMBO] ❌ DynamicHitboxClient not available!")
        end
    else
        warn("[BERSERKER COMBO] ❌ No berserker weapon tool found!")
        if state.character then
            print("[BERSERKER COMBO] Available tools:")
            for _, child in pairs(state.character:GetChildren()) do
                if child:IsA("Tool") then
                    print("  -", child.Name)
                end
            end
        end
    end
end

-- Show combo feedback
local function showComboFeedback(attackNumber, attackName)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    if player.Character and player.Character:FindFirstChild("Head") then
        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.new(0, 120, 0, 60)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.Parent = player.Character.Head
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = string.format("COMBO %d!\n%s", attackNumber, attackName)
        label.TextColor3 = Color3.new(1, 0, 0) -- Red for berserker
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = gui
        
        -- Remove after 1 second
        task.delay(1, function()
            if gui then gui:Destroy() end
        end)
    end
end

-- Reset combo timer
local function resetComboTimer(config)
    -- Cancel existing timer if it exists
    if comboState.comboResetThread then
        task.cancel(comboState.comboResetThread)
        comboState.comboResetThread = nil
        print("[BERSERKER COMBO] Cancelled previous combo timer")
    end
    
    -- Only start timer if we're in a combo (not at 0)
    if comboState.currentCombo > 0 then
        print(string.format("[BERSERKER COMBO] Starting combo timeout timer: %.1f seconds", config.resetTime))
        
        -- Set new timer
        comboState.comboResetThread = task.delay(config.resetTime, function()
            print(string.format("[BERSERKER COMBO] ⏰ COMBO TIMEOUT! No input for %.1f seconds - resetting combo", config.resetTime))
            comboState.currentCombo = 0
            comboState.isAttacking = false
            comboState.animationStartTime = 0
            comboState.currentAnimationDuration = 0
            comboState.comboResetThread = nil
        end)
    else
        print("[BERSERKER COMBO] No combo active, skipping timeout timer")
    end
end

-- Execute a single attack in the combo
local function executeAttack(state, attackConfig, attackNumber, comboConfig)
    if not state.animator or not state.character then
        return
    end
    
    comboState.isAttacking = true
    comboState.lastAttackTime = tick()
    comboState.animationStartTime = tick()
    comboState.currentAnimationDuration = attackConfig.duration
    
    print(string.format("[BERSERKER COMBO] Executing attack %d: %s (Duration: %.2fs)", attackNumber, attackConfig.name, attackConfig.duration))
    
    -- Set the WeaponUtils state to indicate we're attacking
    state.attackPlaying = true
    state.currentAnimState = "Attack"
    
    -- Create and load animation
    local animationObject = Instance.new("Animation")
    animationObject.AnimationId = attackConfig.animationId
    
    local success, track = pcall(function()
        return state.animator:LoadAnimation(animationObject)
    end)
    
    if not success or not track then
        print("[BERSERKER COMBO] Failed to load animation for attack", attackNumber)
        comboState.isAttacking = false
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
    
    -- Show visual feedback
    showComboFeedback(attackNumber, attackConfig.name)
    
    -- Schedule hitbox generation
    task.delay(attackConfig.hitboxDelay, function()
        if comboState.isAttacking and comboState.currentCombo == attackNumber then
            generateComboHitbox(attackConfig, state)
        end
    end)
    
    -- Wait for the full duration before allowing next attack
    task.delay(attackConfig.duration, function()
        -- Only proceed if this is still the current attack
        if comboState.currentCombo == attackNumber and comboState.isAttacking then
            -- Reset attack states
            comboState.isAttacking = false
            state.attackPlaying = false
            
            print(string.format("[BERSERKER COMBO] Attack %d duration completed (%.2fs)", attackNumber, attackConfig.duration))
            
            -- Check if we're still in combo window for next attack
            local timeSinceLastAttack = tick() - comboState.lastAttackTime
            print(string.format("[BERSERKER COMBO] Time since last attack: %.2fs, Combo window: %.2fs", timeSinceLastAttack, comboConfig.comboWindow))
            
            if timeSinceLastAttack <= comboConfig.comboWindow and comboState.currentCombo < 3 then
                -- Still in combo window, wait for next input
                print("[BERSERKER COMBO] Still in combo window, waiting for next input...")
                resetComboTimer(comboConfig)
                
                -- Return to idle animation for combo window
                if state.idleTrack then
                    state.currentAnimState = "Idle"
                    state.idleTrack:Play()
                end
            else
                -- Combo finished or timed out
                if timeSinceLastAttack > comboConfig.comboWindow then
                    print(string.format("[BERSERKER COMBO] ⏰ COMBO WINDOW EXPIRED! %.2fs > %.2fs - resetting combo", timeSinceLastAttack, comboConfig.comboWindow))
                else
                    print("[BERSERKER COMBO] Combo sequence completed naturally")
                end
                
                comboState.currentCombo = 0
                
                -- Cancel any pending timeout timer since we're resetting manually
                if comboState.comboResetThread then
                    task.cancel(comboState.comboResetThread)
                    comboState.comboResetThread = nil
                end
                
                -- Return to idle animation
                if state.idleTrack then
                    state.currentAnimState = "Idle"
                    state.idleTrack:Play()
                end
            end
        end
    end)
    
    -- Handle animation completion (but don't advance combo until duration is up)
    local connection
    connection = track.Stopped:Connect(function()
        connection:Disconnect()
        print(string.format("[BERSERKER COMBO] Animation for attack %d finished, but waiting for full duration (%.2fs)", attackNumber, attackConfig.duration))
    end)
end

-- Main combo attack function
function BerserkerCombo.executeComboAttack(state)
    if not state or not state.character or not state.animator then
        warn("[BERSERKER COMBO] Invalid state provided - falling back to standard attack")
        return
    end
    
    print("[BERSERKER COMBO] executeComboAttack called")
    
    local config = getComboConfig()
    local currentTime = tick()
    
    -- Check if we're already attacking (respect WeaponUtils state)
    if comboState.isAttacking or state.attackPlaying then
        print("[BERSERKER COMBO] ❌ ATTACK BLOCKED - Attack in progress, ignoring input")
        print("[BERSERKER COMBO] Current combo:", comboState.currentCombo, "isAttacking:", comboState.isAttacking, "attackPlaying:", state.attackPlaying)
        
        -- Show how much time is left in current animation
        if comboState.currentAnimationDuration > 0 then
            local timeElapsed = tick() - comboState.animationStartTime
            local timeRemaining = comboState.currentAnimationDuration - timeElapsed
            if timeRemaining > 0 then
                print(string.format("[BERSERKER COMBO] ⏱️ Animation time remaining: %.2fs (must wait for full duration)", timeRemaining))
            else
                print("[BERSERKER COMBO] ⏱️ Animation duration complete, but still in attack state")
            end
        end
        return
    end
    
    -- Safety check: Make sure we're not interfering with other systems
    if state.humanoid and state.humanoid:GetState() == Enum.HumanoidStateType.Dead then
        print("[BERSERKER COMBO] Character is dead, ignoring attack")
        return
    end
    
    -- Check if we're within combo window
    local timeSinceLastAttack = currentTime - comboState.lastAttackTime
    print("[BERSERKER COMBO] Time check - Current combo:", comboState.currentCombo, "Time since last attack:", timeSinceLastAttack, "Combo window:", config.comboWindow)
    
    if comboState.currentCombo > 0 and timeSinceLastAttack > config.comboWindow then
        -- Combo window expired, reset
        comboState.currentCombo = 0
        comboState.pendingComboInput = false
        print("[BERSERKER COMBO] Combo window expired, resetting")
    end
    
    -- Determine next attack in combo
    local nextAttack = comboState.currentCombo + 1
    if nextAttack > 3 then
        -- Combo sequence completed, reset to first attack
        comboState.currentCombo = 1
        nextAttack = 1
        print("[BERSERKER COMBO] Combo sequence completed, restarting from attack 1")
    else
        comboState.currentCombo = nextAttack
    end
    
    -- Get attack configuration
    local attackConfig
    if nextAttack == 1 then
        attackConfig = config.attack1
    elseif nextAttack == 2 then
        attackConfig = config.attack2
    else
        attackConfig = config.attack3
    end
    
    print("[BERSERKER COMBO] Next attack will be:", nextAttack, "with config:", attackConfig.name)
    
    -- Reset combo timer
    resetComboTimer(config)
    
    -- Execute the attack
    executeAttack(state, attackConfig, nextAttack, config)
end

-- Get current combo state (for debugging)
function BerserkerCombo.getComboState()
    return {
        currentCombo = comboState.currentCombo,
        isAttacking = comboState.isAttacking,
        timeSinceLastAttack = tick() - comboState.lastAttackTime,
    }
end

-- Reset combo state (useful for testing or when switching weapons)
function BerserkerCombo.resetCombo()
    comboState.currentCombo = 0
    comboState.isAttacking = false
    comboState.lastAttackTime = 0
    comboState.animationStartTime = 0
    comboState.currentAnimationDuration = 0
    
    if comboState.comboResetThread then
        task.cancel(comboState.comboResetThread)
        comboState.comboResetThread = nil
    end
    
    print("[BERSERKER COMBO] Combo state manually reset")
end

-- Clean up combo system (called when weapon is removed)
function BerserkerCombo.cleanup()
    BerserkerCombo.resetCombo()
    print("[BERSERKER COMBO] Combo system cleaned up")
end

-- Check if combo is active
function BerserkerCombo.isComboActive()
    return comboState.currentCombo > 0
end

-- Check if currently attacking
function BerserkerCombo.isAttacking()
    return comboState.isAttacking
end

-- Debug function to print current combo state
function BerserkerCombo.debugComboState()
    local state = BerserkerCombo.getComboState()
    local timeRemaining = 0
    if comboState.currentAnimationDuration > 0 then
        local timeElapsed = tick() - comboState.animationStartTime
        timeRemaining = math.max(0, comboState.currentAnimationDuration - timeElapsed)
    end
    
    print(string.format("[BERSERKER COMBO DEBUG] Current: %d, Attacking: %s, Time Since Last: %.2fs, Animation Time Remaining: %.2fs", 
        state.currentCombo, 
        tostring(state.isAttacking),
        state.timeSinceLastAttack,
        timeRemaining
    ))
    return state
end

-- Function to easily adjust combo timeout (for testing/debugging)
function BerserkerCombo.setComboTimeout(newTimeoutSeconds)
    if HitboxConfig then
        local config = HitboxConfig.getComboConfig("berserker_weapon")
        if config then
            config.resetTime = newTimeoutSeconds
            print(string.format("[BERSERKER COMBO] ⚙️ Combo timeout adjusted to %.1f seconds", newTimeoutSeconds))
            return true
        end
    end
    
    print("[BERSERKER COMBO] ❌ Could not adjust timeout - HitboxConfig not available")
    return false
end

-- Function to get current combo timeout setting
function BerserkerCombo.getComboTimeout()
    if HitboxConfig then
        local config = HitboxConfig.getComboConfig("berserker_weapon")
        if config then
            return config.resetTime
        end
    end
    return 3.0 -- Default fallback
end

-- Function to adjust animation duration for specific attacks (for testing/debugging)
function BerserkerCombo.setAttackDuration(attackNumber, newDurationSeconds)
    if HitboxConfig then
        local config = HitboxConfig.getComboConfig("berserker_weapon")
        if config then
            if attackNumber == 1 then
                config.attack1.duration = newDurationSeconds
                print(string.format("[BERSERKER COMBO] ⚙️ Attack 1 duration set to %.2f seconds", newDurationSeconds))
            elseif attackNumber == 2 then
                config.attack2.duration = newDurationSeconds
                print(string.format("[BERSERKER COMBO] ⚙️ Attack 2 duration set to %.2f seconds", newDurationSeconds))
            elseif attackNumber == 3 then
                config.attack3.duration = newDurationSeconds
                print(string.format("[BERSERKER COMBO] ⚙️ Attack 3 duration set to %.2f seconds", newDurationSeconds))
            else
                print("[BERSERKER COMBO] ❌ Invalid attack number. Use 1, 2, or 3")
                return false
            end
            return true
        end
    end
    
    print("[BERSERKER COMBO] ❌ Could not adjust duration - HitboxConfig not available")
    return false
end

-- Function to get current animation durations
function BerserkerCombo.getAttackDurations()
    if HitboxConfig then
        local config = HitboxConfig.getComboConfig("berserker_weapon")
        if config then
            return {
                attack1 = config.attack1.duration,
                attack2 = config.attack2.duration,
                attack3 = config.attack3.duration,
            }
        end
    end
    return {attack1 = 0.8, attack2 = 1.0, attack3 = 1.2} -- Default fallback
end

-- Function to check if DynamicHitboxClient is available
function BerserkerCombo.checkHitboxSystem()
    print("[BERSERKER COMBO] Checking hitbox system availability:")
    
    local DynamicHitboxClient = require(script.Parent.Parent.DynamicHitboxClient)
    if DynamicHitboxClient then
        print("  ✅ DynamicHitboxClient module loaded")
        if DynamicHitboxClient.generateWeaponHitbox then
            print("  ✅ generateWeaponHitbox function available")
        else
            print("  ❌ generateWeaponHitbox function not found")
        end
        return true
    else
        print("  ❌ DynamicHitboxClient module not available")
        return false
    end
end

return BerserkerCombo
