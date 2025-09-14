-- ========================================
-- WEAPON UTILITIES
-- Common functions that don't need to be edited
-- ========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local WeaponUtils = {}

-- ========================================
-- MOVEMENT DETECTION
-- ========================================

function WeaponUtils.isMoving(movementKeys)
    for key, pressed in movementKeys do
        if pressed then
            return true
        end
    end
    return false
end

-- ========================================
-- ANIMATION MANAGEMENT
-- ========================================

function WeaponUtils.stopAllTracks(state)
    if state.idleTrack then state.idleTrack:Stop() end
    if state.runTrack then state.runTrack:Stop() end
    if state.jumpTrack then state.jumpTrack:Stop() end
    if state.climbTrack then state.climbTrack:Stop() end
    if state.attackTrack then state.attackTrack:Stop() end
end

function WeaponUtils.playTrack(state, track, stateName)
    -- If attack animation is playing, ignore other animation requests
    if state.attackPlaying then return end
    if state.currentAnimState ~= stateName then
        WeaponUtils.stopAllTracks(state)
        state.currentAnimState = stateName
        if track then
            track:Play()
        end
    end
end

function WeaponUtils.setupTracks(state, animations)
    local idleAnim = Instance.new("Animation")
    idleAnim.AnimationId = animations.idle
    state.idleTrack = state.animator:LoadAnimation(idleAnim)

    local runAnim = Instance.new("Animation")
    runAnim.AnimationId = animations.run
    state.runTrack = state.animator:LoadAnimation(runAnim)

    local jumpAnim = Instance.new("Animation")
    jumpAnim.AnimationId = animations.jump
    state.jumpTrack = state.animator:LoadAnimation(jumpAnim)

    local climbAnim = Instance.new("Animation")
    climbAnim.AnimationId = animations.climb
    state.climbTrack = state.animator:LoadAnimation(climbAnim)

    -- Setup attack animation if provided
    if animations.attack then
        local attackAnim = Instance.new("Animation")
        attackAnim.AnimationId = animations.attack
        state.attackTrack = state.animator:LoadAnimation(attackAnim)
        state.attackTrack.Looped = false -- Ensure attack animation only plays once per click
    else
        state.attackTrack = nil
    end
end

function WeaponUtils.updateClimbAnimSpeed(state, movementKeys)
    if state.climbTrack and state.humanoid and state.humanoid:GetState() == Enum.HumanoidStateType.Climbing then
        if WeaponUtils.isMoving(movementKeys) then
            state.climbTrack:AdjustSpeed(1)
        else
            state.climbTrack:AdjustSpeed(0)
        end
    end
end

-- ========================================
-- ATTACK ANIMATION MANAGEMENT
-- ========================================

function WeaponUtils.playAttackAnimation(state)
    if not state.toolEquipped or not state.attackTrack then return end
    -- If already playing attack, ignore
    if state.attackPlaying then return end
    WeaponUtils.stopAllTracks(state)
    state.attackPlaying = true
    state.currentAnimState = "Attack"
    state.attackTrack:Play()
    -- When attack animation finishes, reset attackPlaying and play idle
    if state.attackConn then state.attackConn:Disconnect() end
    state.attackConn = state.attackTrack.Stopped:Connect(function()
        state.attackPlaying = false
        WeaponUtils.playTrack(state, state.idleTrack, "Idle")
    end)
end

-- ========================================
-- STATE MANAGEMENT
-- ========================================

function WeaponUtils.onStateChanged(state, old, new, movementKeys)
    if not state.toolEquipped then return end
    -- If attack animation is playing, ignore state changes
    if state.attackPlaying then return end
    if new == Enum.HumanoidStateType.Climbing then
        WeaponUtils.stopAllTracks(state)
        state.currentAnimState = "Climbing"
        if state.climbTrack then
            state.climbTrack:Play()
            WeaponUtils.updateClimbAnimSpeed(state, movementKeys)
        end
    elseif old == Enum.HumanoidStateType.Climbing and new ~= Enum.HumanoidStateType.Climbing then
        if state.climbTrack then
            state.climbTrack:AdjustSpeed(1)
        end
        if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
            WeaponUtils.stopAllTracks(state)
            state.currentAnimState = "Jumping"
            if state.jumpTrack then
                state.jumpTrack:Play()
            end
        elseif new == Enum.HumanoidStateType.Landed then
            if WeaponUtils.isMoving(movementKeys) then
                WeaponUtils.playTrack(state, state.runTrack, "Running")
            else
                WeaponUtils.playTrack(state, state.idleTrack, "Idle")
                if state.runTrack and state.runTrack.IsPlaying then
                    state.runTrack:Stop()
                end
            end
        elseif new == Enum.HumanoidStateType.Running then
            if WeaponUtils.isMoving(movementKeys) then
                WeaponUtils.playTrack(state, state.runTrack, "Running")
            else
                WeaponUtils.playTrack(state, state.idleTrack, "Idle")
            end
        else
            WeaponUtils.playTrack(state, state.idleTrack, "Idle")
        end
    else
        if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
            WeaponUtils.stopAllTracks(state)
            state.currentAnimState = "Jumping"
            if state.jumpTrack then
                state.jumpTrack:Play()
            end
        elseif new == Enum.HumanoidStateType.Landed then
            if WeaponUtils.isMoving(movementKeys) then
                WeaponUtils.playTrack(state, state.runTrack, "Running")
            else
                WeaponUtils.playTrack(state, state.idleTrack, "Idle")
                if state.runTrack and state.runTrack.IsPlaying then
                    state.runTrack:Stop()
                end
            end
        elseif new == Enum.HumanoidStateType.Running then
            if WeaponUtils.isMoving(movementKeys) then
                WeaponUtils.playTrack(state, state.runTrack, "Running")
            else
                WeaponUtils.playTrack(state, state.idleTrack, "Idle")
            end
        else
            WeaponUtils.playTrack(state, state.idleTrack, "Idle")
        end
    end
end

function WeaponUtils.onMove(state, movementKeys)
    if not state.toolEquipped then return end
    if state.attackPlaying then return end
    local humanoid = state.humanoid
    if not humanoid then return end
    local s = humanoid:GetState()
    if s == Enum.HumanoidStateType.Climbing then
        WeaponUtils.stopAllTracks(state)
        state.currentAnimState = "Climbing"
        if state.climbTrack then
            state.climbTrack:Play()
            WeaponUtils.updateClimbAnimSpeed(state, movementKeys)
        end
        return
    elseif s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall then
        return
    elseif s == Enum.HumanoidStateType.Landed then
        if WeaponUtils.isMoving(movementKeys) then
            WeaponUtils.playTrack(state, state.runTrack, "Running")
        else
            WeaponUtils.playTrack(state, state.idleTrack, "Idle")
            if state.runTrack and state.runTrack.IsPlaying then
                state.runTrack:Stop()
            end
        end
    elseif s == Enum.HumanoidStateType.Running then
        if WeaponUtils.isMoving(movementKeys) then
            WeaponUtils.playTrack(state, state.runTrack, "Running")
        else
            WeaponUtils.playTrack(state, state.idleTrack, "Idle")
        end
    else
        -- Default
    end
end

-- ========================================
-- INPUT HANDLING
-- ========================================

function WeaponUtils.onInputBegan(state, input, gameProcessed, movementKeys)
    if movementKeys[input.KeyCode] ~= nil then
        movementKeys[input.KeyCode] = true
        WeaponUtils.onMove(state, movementKeys)
        WeaponUtils.updateClimbAnimSpeed(state, movementKeys)
    end
end

function WeaponUtils.onInputEnded(state, input, gameProcessed, movementKeys)
    if movementKeys[input.KeyCode] ~= nil then
        movementKeys[input.KeyCode] = false
        WeaponUtils.onMove(state, movementKeys)
        WeaponUtils.updateClimbAnimSpeed(state, movementKeys)
    end
end

-- ========================================
-- CONNECTION MANAGEMENT
-- ========================================

function WeaponUtils.disconnectAll(state)
    if state.stateConn then state.stateConn:Disconnect() state.stateConn = nil end
    if state.inputBeganConn then state.inputBeganConn:Disconnect() state.inputBeganConn = nil end
    if state.inputEndedConn then state.inputEndedConn:Disconnect() state.inputEndedConn = nil end
    if state.attackConn then state.attackConn:Disconnect() state.attackConn = nil end
    WeaponUtils.stopAllTracks(state)
    state.currentAnimState = nil
    state.attackPlaying = false
end

function WeaponUtils.playInstantAnimation(state, movementKeys)
    if not state.toolEquipped or not state.humanoid then return end
    if state.attackPlaying then return end
    local s = state.humanoid:GetState()
    if s == Enum.HumanoidStateType.Climbing then
        WeaponUtils.stopAllTracks(state)
        state.currentAnimState = "Climbing"
        if state.climbTrack then
            state.climbTrack:Play()
            WeaponUtils.updateClimbAnimSpeed(state, movementKeys)
        end
    elseif s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall then
        WeaponUtils.stopAllTracks(state)
        state.currentAnimState = "Jumping"
        if state.jumpTrack then
            state.jumpTrack:Play()
        end
    else
        -- Always start with idle animation when equipped, regardless of movement state
        -- The movement detection will handle switching to run animation when needed
        WeaponUtils.playTrack(state, state.idleTrack, "Idle")
    end
end

-- ========================================
-- SHIELD UTILITIES
-- ========================================

function WeaponUtils.getHandOffsets(rigType, shieldForwardOffset)
    local shieldRotation = CFrame.Angles(0, math.rad(100), 0)
    local forwardOffset = shieldForwardOffset or CFrame.new(0, 0, 0)
    
    if rigType == Enum.HumanoidRigType.R15 then
        return {
            swordC0 = CFrame.new(0, 0, 0),
            swordC1 = CFrame.new(0, 0, 0),
            shieldC0 = forwardOffset * shieldRotation,
            shieldC1 = CFrame.new(0, 0, 0),
        }
    else
        return {
            swordC0 = CFrame.new(0, -1, 0),
            swordC1 = CFrame.new(0, 0, 0),
            shieldC0 = CFrame.new(0, -1, 0) * forwardOffset * shieldRotation,
            shieldC1 = CFrame.new(0, 0, 0),
        }
    end
end

function WeaponUtils.attachPartToLimb(part, limbName, motorName, character, c0, c1)
    local limb = character:FindFirstChild(limbName)
    if not limb or not part then return end

    -- Remove previous Motor6D if exists
    for k, v in limb:GetChildren() do
        if v:IsA("Motor6D") and v.Name == motorName then
            v:Destroy()
        end
    end

    local motor = Instance.new("Motor6D")
    motor.Name = motorName
    motor.Part0 = limb
    motor.Part1 = part
    motor.Parent = limb
    motor.C0 = c0 or CFrame.new(0, 0, 0)
    motor.C1 = c1 or CFrame.new(0, 0, 0)
end

return WeaponUtils

