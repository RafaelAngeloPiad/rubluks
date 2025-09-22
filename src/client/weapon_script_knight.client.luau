local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.weapon_scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Try to load combo module with error handling
local KnightCombo = nil
local comboLoadSuccess, comboError = pcall(function()
    -- Check if combo module exists first
    print("[KNIGHT WEAPON] Checking for combo module...")
    local comboModule = script.Parent:FindFirstChild("weapon_script_knight_combo")
    
    if comboModule then
        print("[KNIGHT WEAPON] Found combo module:", comboModule.Name, "Type:", comboModule.ClassName)
        KnightCombo = require(comboModule)
        print("[KNIGHT WEAPON] ✅ Successfully loaded combo module!")
    else
        print("[KNIGHT WEAPON] Combo module not found, listing all children:")
        for _, child in pairs(script.Parent:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
        end
        error("Combo module not found in script.Parent")
    end
end)
if not comboLoadSuccess then
    warn("[KNIGHT WEAPON] Failed to load combo module:", comboError)
    warn("[KNIGHT WEAPON] Falling back to standard attack system")
end

-- Knight weapon animation IDs (from old working script)
local idleAnimId = "rbxassetid://109402075157762"
local runAnimId = "rbxassetid://114926843826062"
local jumpAnimId = "rbxassetid://103828839495945"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://73728189126085"
local attackAnimId = "rbxassetid://116519685012277" -- Knight attack animation (placeholder)

-- Track WASD key states
local movementKeys = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.D] = false,
}

-- Store per-tool connections and animation state
local toolStates = {}
local weaponScanner = nil

-- Animation configuration
local animations = {
	idle = idleAnimId,
	run = runAnimId,
	jump = jumpAnimId,
	climb = climbAnimId,
	attack = attackAnimId,
}

-- Use utility functions for common animation logic
local function onStateChanged(state, old, new)
	WeaponUtils.onStateChanged(state, old, new, movementKeys)
end

local function onMove(state)
	WeaponUtils.onMove(state, movementKeys)
end

local function onInputBegan(state, input, gameProcessed)
	WeaponUtils.onInputBegan(state, input, gameProcessed, movementKeys)
end

local function onInputEnded(state, input, gameProcessed)
	WeaponUtils.onInputEnded(state, input, gameProcessed, movementKeys)
end

local function disconnectAll(state)
	WeaponUtils.disconnectAll(state)
end

local function playInstantAnimation(state)
	WeaponUtils.playInstantAnimation(state, movementKeys)
end

local function playAttack(state)
	print("[KNIGHT WEAPON] playAttack called")
	print("[KNIGHT WEAPON] State info - Character:", state.character, "Humanoid:", state.humanoid, "Animator:", state.animator)
	
	-- Use combo system if available, otherwise fall back to standard attack
	if KnightCombo then
		print("[KNIGHT WEAPON] Using combo system for attack")
		KnightCombo.executeComboAttack(state)
	else
		print("[KNIGHT WEAPON] Using standard attack system")
		print("[KNIGHT WEAPON] Calling WeaponUtils.playAttackAnimation")
		WeaponUtils.playAttackAnimation(state)
		print("[KNIGHT WEAPON] WeaponUtils.playAttackAnimation completed")
	end
end

-- ========================================
-- SHIELD HANDLING FUNCTIONS
-- ========================================

-- Knight-specific shield offset (moved forward by 0.5 studs)
local shieldForwardOffset = CFrame.new(-0.5, 0, 0)

local function detectSwordAndShield(tool)
	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")
	return sword ~= nil and shield ~= nil
end

local function attachSwordAndShield(tool, character, humanoid)
	if not character or not humanoid then return end

	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")
	
	if not sword or not shield then return end

	-- Make sure sword and shield are visible
	sword.Transparency = 0
	shield.Transparency = 0

	local offsets = WeaponUtils.getHandOffsets(humanoid.RigType, shieldForwardOffset)
	local swordMotorName = "SwordRightHandMotor"
	local shieldMotorName = "ShieldLeftHandMotor"

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		WeaponUtils.attachPartToLimb(sword, "RightHand", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		WeaponUtils.attachPartToLimb(shield, "LeftHand", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	else
		WeaponUtils.attachPartToLimb(sword, "Right Arm", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		WeaponUtils.attachPartToLimb(shield, "Left Arm", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	end
end

local function removeSwordAndShield(tool, character, humanoid)
	if not character or not humanoid then return end

	local swordMotorName = "SwordRightHandMotor"
	local shieldMotorName = "ShieldLeftHandMotor"

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		local rightHand = character:FindFirstChild("RightHand")
		local leftHand = character:FindFirstChild("LeftHand")
		if rightHand then
			for k, v in rightHand:GetChildren() do
				if v:IsA("Motor6D") and v.Name == swordMotorName then
					v:Destroy()
				end
			end
		end
		if leftHand then
			for k, v in leftHand:GetChildren() do
				if v:IsA("Motor6D") and v.Name == shieldMotorName then
					v:Destroy()
				end
			end
		end
	else
		local rightArm = character:FindFirstChild("Right Arm")
		local leftArm = character:FindFirstChild("Left Arm")
		if rightArm then
			for k, v in rightArm:GetChildren() do
				if v:IsA("Motor6D") and v.Name == swordMotorName then
					v:Destroy()
				end
			end
		end
		if leftArm then
			for k, v in leftArm:GetChildren() do
				if v:IsA("Motor6D") and v.Name == shieldMotorName then
					v:Destroy()
				end
			end
		end
	end

	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")
	if sword then sword.Transparency = 1 end
	if shield then shield.Transparency = 1 end
end

local function onCharacterAdded(state, char)
	print("[KNIGHT WEAPON] Character added, setting up animations")
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then 
		warn("[KNIGHT WEAPON] No humanoid found in character")
		return 
	end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		print("[KNIGHT WEAPON] Creating new animator")
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	print("[KNIGHT WEAPON] Setting up animation tracks")
	WeaponUtils.setupTracks(state, animations)
	disconnectAll(state)

	if state.toolEquipped then
		print("[KNIGHT WEAPON] Tool is equipped, connecting events")
		-- Detect and attach sword and shield
		if state.tool and detectSwordAndShield(state.tool) then
			print("[KNIGHT WEAPON] Attaching sword and shield")
			attachSwordAndShield(state.tool, char, state.humanoid)
		end
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			print("[KNIGHT WEAPON] State changed:", old, "->", new)
			onStateChanged(state, old, new)
			
			-- Test if movement animations are working
			if new == Enum.HumanoidStateType.Running then
				print("[KNIGHT WEAPON] ✅ Running animation should be playing")
			elseif new == Enum.HumanoidStateType.RunningNoPhysics then
				print("[KNIGHT WEAPON] ✅ Idle animation should be playing")
			elseif new == Enum.HumanoidStateType.Jumping then
				print("[KNIGHT WEAPON] ✅ Jump animation should be playing")
			end
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
			-- Only trigger attack animation on left mouse click
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
				print("[KNIGHT WEAPON] Attack input detected")
				playAttack(state)
			end
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		print("[KNIGHT WEAPON] Playing instant animation")
		playInstantAnimation(state)
	else
		print("[KNIGHT WEAPON] Tool not equipped, skipping event connections")
	end
end

local function onEquipped(tool)
	print("[KNIGHT WEAPON] Tool equipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then 
		warn("[KNIGHT WEAPON] No weapon state found for tool:", tool.Name)
		return 
	end
	state.toolEquipped = true
	state.tool = tool
	
	-- Detect sword and shield
	local hasSwordShield = detectSwordAndShield(tool)
	print("[KNIGHT WEAPON] Sword and shield detected:", hasSwordShield)
	
	if player.Character then
		print("[KNIGHT WEAPON] Character exists, setting up animations")
		onCharacterAdded(state, player.Character)
	else
		warn("[KNIGHT WEAPON] No character found when equipping tool")
	end
end

local function onUnequipped(tool)
	print("[KNIGHT WEAPON] Tool unequipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Reset combo if available
	if KnightCombo then
		print("[KNIGHT WEAPON] Resetting combo system")
		KnightCombo.resetCombo()
	end
	
	-- Remove sword and shield
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		print("[KNIGHT WEAPON] Removing sword and shield")
		removeSwordAndShield(tool, player.Character, player.Character:FindFirstChildOfClass("Humanoid"))
	end
	
	print("[KNIGHT WEAPON] Disconnecting all events")
	disconnectAll(state)
	state.tool = nil
end

local function setupTool(tool, state)
	-- Listen for equipped/unequipped
	state.equippedConn = tool.Equipped:Connect(function()
		onEquipped(tool)
	end)
	state.unequippedConn = tool.Unequipped:Connect(function()
		onUnequipped(tool)
	end)

	-- Listen for character added
	state.charConn = player.CharacterAdded:Connect(function(char)
		onCharacterAdded(state, char)
	end)
	if player.Character then
		onCharacterAdded(state, player.Character)
	end
end

local function cleanupTool(tool, state)
	print("[KNIGHT WEAPON] Cleaning up tool:", tool.Name)
	
	-- Reset combo when cleaning up
	if KnightCombo then
		print("[KNIGHT WEAPON] Resetting combo system during cleanup")
		KnightCombo.resetCombo()
	end
	
	if state.equippedConn then state.equippedConn:Disconnect() end
	if state.unequippedConn then state.unequippedConn:Disconnect() end
	if state.charConn then state.charConn:Disconnect() end
	disconnectAll(state)
end

-- Debug function to test animation system
local function debugAnimationSystem()
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            print("[KNIGHT DEBUG] Character found, humanoid state:", humanoid:GetState())
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                print("[KNIGHT DEBUG] Animator found")
                local playingTracks = animator:GetPlayingAnimationTracks()
                print("[KNIGHT DEBUG] Playing tracks:", #playingTracks)
                for i, track in ipairs(playingTracks) do
                    print("[KNIGHT DEBUG] Track", i, ":", track.Animation.AnimationId)
                end
            else
                warn("[KNIGHT DEBUG] No animator found")
            end
        else
            warn("[KNIGHT DEBUG] No humanoid found")
        end
    else
        warn("[KNIGHT DEBUG] No character found")
    end
end

-- Make debug function globally accessible
_G.debugKnightAnimations = debugAnimationSystem

-- Global debug functions for combo system
if KnightCombo then
    _G.debugKnightCombo = function()
        return KnightCombo.debugComboState()
    end
    
    _G.setKnightComboTimeout = function(seconds)
        return KnightCombo.setComboTimeout(seconds)
    end
    
    _G.getKnightComboTimeout = function()
        return KnightCombo.getComboTimeout()
    end
    
    _G.resetKnightCombo = function()
        return KnightCombo.resetCombo()
    end
    
    _G.setKnightAttackDuration = function(attackNumber, seconds)
        return KnightCombo.setAttackDuration(attackNumber, seconds)
    end
    
    _G.getKnightAttackDurations = function()
        return KnightCombo.getAttackDurations()
    end
    
    _G.checkKnightHitboxSystem = function()
        return KnightCombo.checkHitboxSystem()
    end
    
    print("[KNIGHT WEAPON] Global combo debug functions available:")
    print("  _G.debugKnightCombo() - Show current combo state")
    print("  _G.setKnightComboTimeout(seconds) - Change combo timeout")
    print("  _G.getKnightComboTimeout() - Get current timeout")
    print("  _G.setKnightAttackDuration(1/2/3, seconds) - Change attack duration")
    print("  _G.getKnightAttackDurations() - Get current durations")
    print("  _G.checkKnightHitboxSystem() - Check hitbox system availability")
    print("  _G.resetKnightCombo() - Manually reset combo")
end

-- Initialize weapon scanner
print("[KNIGHT WEAPON] Initializing weapon scanner")
weaponScanner = WeaponScanner.new("knight_weapon", setupTool, cleanupTool)
print("[KNIGHT WEAPON] Weapon scanner initialized successfully")