local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.weapon_scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Try to load combo module with error handling
local BerserkerCombo = nil
local comboLoadSuccess, comboError = pcall(function()
    -- Check if combo module exists first
    print("[BERSERKER WEAPON] Checking for combo module...")
    local comboModule = script.Parent:FindFirstChild("weapon_script_berserker_combo")
    
    if comboModule then
        print("[BERSERKER WEAPON] Found combo module:", comboModule.Name, "Type:", comboModule.ClassName)
        BerserkerCombo = require(comboModule)
        print("[BERSERKER WEAPON] ✅ Successfully loaded combo module!")
    else
        print("[BERSERKER WEAPON] Combo module not found, listing all children:")
        for _, child in pairs(script.Parent:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
        end
        error("Combo module not found in script.Parent")
    end
end)
if not comboLoadSuccess then
    warn("[BERSERKER WEAPON] Failed to load combo module:", comboError)
    warn("[BERSERKER WEAPON] Falling back to standard attack system")
end

-- Berserker weapon animation IDs (from old working script)
local idleAnimId = "rbxassetid://131906517756576"
local runAnimId = "rbxassetid://127835518362781"
local jumpAnimId = "rbxassetid://87006823550715"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://111950022379992"
local attackAnimId = "rbxassetid://116519685012277" -- Berserker attack animation (placeholder)

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
	print("[BERSERKER WEAPON] playAttack called")
	print("[BERSERKER WEAPON] State info - Character:", state.character, "Humanoid:", state.humanoid, "Animator:", state.animator)
	
	-- Use combo system if available, otherwise fall back to standard attack
	if BerserkerCombo then
		print("[BERSERKER WEAPON] Using combo system for attack")
		BerserkerCombo.executeComboAttack(state)
	else
		print("[BERSERKER WEAPON] Using standard attack system")
		print("[BERSERKER WEAPON] Calling WeaponUtils.playAttackAnimation")
		WeaponUtils.playAttackAnimation(state)
		print("[BERSERKER WEAPON] WeaponUtils.playAttackAnimation completed")
	end
end

-- ========================================
-- SHIELD HANDLING FUNCTIONS
-- ========================================

-- Berserker-specific shield offset (no forward offset)
local shieldForwardOffset = CFrame.new(0, 0, 0)

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
	print("[BERSERKER WEAPON] Character added, setting up animations")
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then 
		warn("[BERSERKER WEAPON] No humanoid found in character")
		return 
	end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		print("[BERSERKER WEAPON] Creating new animator")
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	print("[BERSERKER WEAPON] Setting up animation tracks")
	WeaponUtils.setupTracks(state, animations)
	disconnectAll(state)

	if state.toolEquipped then
		print("[BERSERKER WEAPON] Tool is equipped, connecting events")
		-- Detect and attach sword and shield
		if state.tool and detectSwordAndShield(state.tool) then
			print("[BERSERKER WEAPON] Attaching sword and shield")
			attachSwordAndShield(state.tool, char, state.humanoid)
		end
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			print("[BERSERKER WEAPON] State changed:", old, "->", new)
			onStateChanged(state, old, new)
			
			-- Test if movement animations are working
			if new == Enum.HumanoidStateType.Running then
				print("[BERSERKER WEAPON] ✅ Running animation should be playing")
			elseif new == Enum.HumanoidStateType.RunningNoPhysics then
				print("[BERSERKER WEAPON] ✅ Idle animation should be playing")
			elseif new == Enum.HumanoidStateType.Jumping then
				print("[BERSERKER WEAPON] ✅ Jump animation should be playing")
			end
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
			-- Only trigger attack animation on left mouse click
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
				print("[BERSERKER WEAPON] Attack input detected")
				playAttack(state)
			end
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		print("[BERSERKER WEAPON] Playing instant animation")
		playInstantAnimation(state)
	else
		print("[BERSERKER WEAPON] Tool not equipped, skipping event connections")
	end
end

local function onEquipped(tool)
	print("[BERSERKER WEAPON] Tool equipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then 
		warn("[BERSERKER WEAPON] No weapon state found for tool:", tool.Name)
		return 
	end
	state.toolEquipped = true
	state.tool = tool
	
	-- Detect sword and shield
	local hasSwordShield = detectSwordAndShield(tool)
	print("[BERSERKER WEAPON] Sword and shield detected:", hasSwordShield)
	
	if player.Character then
		print("[BERSERKER WEAPON] Character exists, setting up animations")
		onCharacterAdded(state, player.Character)
	else
		warn("[BERSERKER WEAPON] No character found when equipping tool")
	end
end

local function onUnequipped(tool)
	print("[BERSERKER WEAPON] Tool unequipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Reset combo if available
	if BerserkerCombo then
		print("[BERSERKER WEAPON] Resetting combo system")
		BerserkerCombo.resetCombo()
	end
	
	-- Remove sword and shield
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		print("[BERSERKER WEAPON] Removing sword and shield")
		removeSwordAndShield(tool, player.Character, player.Character:FindFirstChildOfClass("Humanoid"))
	end
	
	print("[BERSERKER WEAPON] Disconnecting all events")
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
	print("[BERSERKER WEAPON] Cleaning up tool:", tool.Name)
	
	-- Reset combo when cleaning up
	if BerserkerCombo then
		print("[BERSERKER WEAPON] Resetting combo system during cleanup")
		BerserkerCombo.resetCombo()
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
            print("[BERSERKER DEBUG] Character found, humanoid state:", humanoid:GetState())
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                print("[BERSERKER DEBUG] Animator found")
                local playingTracks = animator:GetPlayingAnimationTracks()
                print("[BERSERKER DEBUG] Playing tracks:", #playingTracks)
                for i, track in ipairs(playingTracks) do
                    print("[BERSERKER DEBUG] Track", i, ":", track.Animation.AnimationId)
                end
            else
                warn("[BERSERKER DEBUG] No animator found")
            end
        else
            warn("[BERSERKER DEBUG] No humanoid found")
        end
    else
        warn("[BERSERKER DEBUG] No character found")
    end
end

-- Make debug function globally accessible
_G.debugBerserkerAnimations = debugAnimationSystem

-- Global debug functions for combo system
if BerserkerCombo then
    _G.debugCombo = function()
        return BerserkerCombo.debugComboState()
    end
    
    _G.setComboTimeout = function(seconds)
        return BerserkerCombo.setComboTimeout(seconds)
    end
    
    _G.getComboTimeout = function()
        return BerserkerCombo.getComboTimeout()
    end
    
    _G.resetCombo = function()
        return BerserkerCombo.resetCombo()
    end
    
    _G.setAttackDuration = function(attackNumber, seconds)
        return BerserkerCombo.setAttackDuration(attackNumber, seconds)
    end
    
    _G.getAttackDurations = function()
        return BerserkerCombo.getAttackDurations()
    end
    
    _G.checkHitboxSystem = function()
        return BerserkerCombo.checkHitboxSystem()
    end
    
    print("[BERSERKER WEAPON] Global combo debug functions available:")
    print("  _G.debugCombo() - Show current combo state")
    print("  _G.setComboTimeout(seconds) - Change combo timeout")
    print("  _G.getComboTimeout() - Get current timeout")
    print("  _G.setAttackDuration(1/2/3, seconds) - Change attack duration")
    print("  _G.getAttackDurations() - Get current durations")
    print("  _G.checkHitboxSystem() - Check hitbox system availability")
    print("  _G.resetCombo() - Manually reset combo")
end

-- Initialize weapon scanner
print("[BERSERKER WEAPON] Initializing weapon scanner")
weaponScanner = WeaponScanner.new("berserker_weapon", setupTool, cleanupTool)
print("[BERSERKER WEAPON] Weapon scanner initialized successfully")