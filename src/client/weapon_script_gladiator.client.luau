local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.weapon_scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Try to load combo module with error handling
local GladiatorCombo = nil
local comboLoadSuccess, comboError = pcall(function()
    -- Check if combo module exists first
    print("[GLADIATOR WEAPON] Checking for combo module...")
    local comboModule = script.Parent:FindFirstChild("weapon_script_gladiator_combo")
    
    if comboModule then
        print("[GLADIATOR WEAPON] Found combo module:", comboModule.Name, "Type:", comboModule.ClassName)
        GladiatorCombo = require(comboModule)
        print("[GLADIATOR WEAPON] ✅ Successfully loaded combo module!")
    else
        print("[GLADIATOR WEAPON] Combo module not found, listing all children:")
        for _, child in pairs(script.Parent:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
        end
        error("Combo module not found in script.Parent")
    end
end)
if not comboLoadSuccess then
    warn("[GLADIATOR WEAPON] Failed to load combo module:", comboError)
    warn("[GLADIATOR WEAPON] Falling back to standard attack system")
end

-- Gladiator weapon animation IDs (from old working script)
local idleAnimId = "rbxassetid://79881876893934"
local runAnimId = "rbxassetid://113591617263552"
local jumpAnimId = "rbxassetid://131643962945265"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://83874564246965"
local attackAnimId = "rbxassetid://116519685012277" -- Gladiator attack animation (placeholder)

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
	print("[GLADIATOR WEAPON] playAttack called")
	print("[GLADIATOR WEAPON] State info - Character:", state.character, "Humanoid:", state.humanoid, "Animator:", state.animator)
	
	-- Use combo system if available, otherwise fall back to standard attack
	if GladiatorCombo then
		print("[GLADIATOR WEAPON] Using combo system for attack")
		GladiatorCombo.executeComboAttack(state)
	else
		print("[GLADIATOR WEAPON] Using standard attack system")
		print("[GLADIATOR WEAPON] Calling WeaponUtils.playAttackAnimation")
		WeaponUtils.playAttackAnimation(state)
		print("[GLADIATOR WEAPON] WeaponUtils.playAttackAnimation completed")
	end
end

-- ========================================
-- SHIELD HANDLING FUNCTIONS
-- ========================================

-- Gladiator-specific shield offset (moved forward by 0.5 studs)
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
	print("[GLADIATOR WEAPON] Character added, setting up animations")
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then 
		warn("[GLADIATOR WEAPON] No humanoid found in character")
		return 
	end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		print("[GLADIATOR WEAPON] Creating new animator")
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	print("[GLADIATOR WEAPON] Setting up animation tracks")
	WeaponUtils.setupTracks(state, animations)
	disconnectAll(state)

	if state.toolEquipped then
		print("[GLADIATOR WEAPON] Tool is equipped, connecting events")
		-- Detect and attach sword and shield
		if state.tool and detectSwordAndShield(state.tool) then
			print("[GLADIATOR WEAPON] Attaching sword and shield")
			attachSwordAndShield(state.tool, char, state.humanoid)
		end
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			print("[GLADIATOR WEAPON] State changed:", old, "->", new)
			onStateChanged(state, old, new)
			
			-- Test if movement animations are working
			if new == Enum.HumanoidStateType.Running then
				print("[GLADIATOR WEAPON] ✅ Running animation should be playing")
			elseif new == Enum.HumanoidStateType.RunningNoPhysics then
				print("[GLADIATOR WEAPON] ✅ Idle animation should be playing")
			elseif new == Enum.HumanoidStateType.Jumping then
				print("[GLADIATOR WEAPON] ✅ Jump animation should be playing")
			end
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
			-- Only trigger attack animation on left mouse click
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
				print("[GLADIATOR WEAPON] Attack input detected")
				playAttack(state)
			end
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		print("[GLADIATOR WEAPON] Playing instant animation")
		playInstantAnimation(state)
	else
		print("[GLADIATOR WEAPON] Tool not equipped, skipping event connections")
	end
end

local function onEquipped(tool)
	print("[GLADIATOR WEAPON] Tool equipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then 
		warn("[GLADIATOR WEAPON] No weapon state found for tool:", tool.Name)
		return 
	end
	state.toolEquipped = true
	state.tool = tool
	
	-- Detect sword and shield
	local hasSwordShield = detectSwordAndShield(tool)
	print("[GLADIATOR WEAPON] Sword and shield detected:", hasSwordShield)
	
	if player.Character then
		print("[GLADIATOR WEAPON] Character exists, setting up animations")
		onCharacterAdded(state, player.Character)
	else
		warn("[GLADIATOR WEAPON] No character found when equipping tool")
	end
end

local function onUnequipped(tool)
	print("[GLADIATOR WEAPON] Tool unequipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Reset combo if available
	if GladiatorCombo then
		print("[GLADIATOR WEAPON] Resetting combo system")
		GladiatorCombo.resetCombo()
	end
	
	-- Remove sword and shield
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		print("[GLADIATOR WEAPON] Removing sword and shield")
		removeSwordAndShield(tool, player.Character, player.Character:FindFirstChildOfClass("Humanoid"))
	end
	
	print("[GLADIATOR WEAPON] Disconnecting all events")
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
	print("[GLADIATOR WEAPON] Cleaning up tool:", tool.Name)
	
	-- Reset combo when cleaning up
	if GladiatorCombo then
		print("[GLADIATOR WEAPON] Resetting combo system during cleanup")
		GladiatorCombo.resetCombo()
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
            print("[GLADIATOR DEBUG] Character found, humanoid state:", humanoid:GetState())
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                print("[GLADIATOR DEBUG] Animator found")
                local playingTracks = animator:GetPlayingAnimationTracks()
                print("[GLADIATOR DEBUG] Playing tracks:", #playingTracks)
                for i, track in ipairs(playingTracks) do
                    print("[GLADIATOR DEBUG] Track", i, ":", track.Animation.AnimationId)
                end
            else
                warn("[GLADIATOR DEBUG] No animator found")
            end
        else
            warn("[GLADIATOR DEBUG] No humanoid found")
        end
    else
        warn("[GLADIATOR DEBUG] No character found")
    end
end

-- Make debug function globally accessible
_G.debugGladiatorAnimations = debugAnimationSystem

-- Global debug functions for combo system
if GladiatorCombo then
    _G.debugGladiatorCombo = function()
        return GladiatorCombo.debugComboState()
    end
    
    _G.setGladiatorComboTimeout = function(seconds)
        return GladiatorCombo.setComboTimeout(seconds)
    end
    
    _G.getGladiatorComboTimeout = function()
        return GladiatorCombo.getComboTimeout()
    end
    
    _G.resetGladiatorCombo = function()
        return GladiatorCombo.resetCombo()
    end
    
    _G.setGladiatorAttackDuration = function(attackNumber, seconds)
        return GladiatorCombo.setAttackDuration(attackNumber, seconds)
    end
    
    _G.getGladiatorAttackDurations = function()
        return GladiatorCombo.getAttackDurations()
    end
    
    _G.checkGladiatorHitboxSystem = function()
        return GladiatorCombo.checkHitboxSystem()
    end
    
    print("[GLADIATOR WEAPON] Global combo debug functions available:")
    print("  _G.debugGladiatorCombo() - Show current combo state")
    print("  _G.setGladiatorComboTimeout(seconds) - Change combo timeout")
    print("  _G.getGladiatorComboTimeout() - Get current timeout")
    print("  _G.setGladiatorAttackDuration(1/2/3, seconds) - Change attack duration")
    print("  _G.getGladiatorAttackDurations() - Get current durations")
    print("  _G.checkGladiatorHitboxSystem() - Check hitbox system availability")
    print("  _G.resetGladiatorCombo() - Manually reset combo")
end

-- Initialize weapon scanner
print("[GLADIATOR WEAPON] Initializing weapon scanner")
weaponScanner = WeaponScanner.new("gladiator_weapon", setupTool, cleanupTool)
print("[GLADIATOR WEAPON] Weapon scanner initialized successfully")