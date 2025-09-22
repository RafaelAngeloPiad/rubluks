local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.weapon_scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Try to load combo module with error handling
local ArcherCombo = nil
local comboLoadSuccess, comboError = pcall(function()
    -- Check if combo module exists first
    local comboModule = script.Parent:FindFirstChild("weapon_script_archer_combo")
    
    if comboModule then
        ArcherCombo = require(comboModule)
    else
        for _, child in pairs(script.Parent:GetChildren()) do
        end
        error("Combo module not found in script.Parent")
    end
end)
if not comboLoadSuccess then
    warn("[ARCHER WEAPON] Failed to load combo module:", comboError)
    warn("[ARCHER WEAPON] Falling back to standard attack system")
end

-- Archer weapon animation IDs (from old working script)
local idleAnimId = "rbxassetid://82542810529243"
local runAnimId = "rbxassetid://114148291546049"
local jumpAnimId = "rbxassetid://118577091214692"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://112756927751345"
local attackAnimId = "rbxassetid://116519685012277" -- Archer attack animation (placeholder)

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
	
	-- Use combo system if available, otherwise fall back to standard attack
	if ArcherCombo then
		ArcherCombo.executeComboAttack(state)
	else
		WeaponUtils.playAttackAnimation(state)
	end
end

-- ========================================
-- SHIELD HANDLING FUNCTIONS
-- ========================================

-- Archer-specific shield offset (moved forward by 0.5 studs)
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
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then 
		warn("[ARCHER WEAPON] No humanoid found in character")
		return 
	end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	WeaponUtils.setupTracks(state, animations)
	disconnectAll(state)

	if state.toolEquipped then
		-- Detect and attach sword and shield
		if state.tool and detectSwordAndShield(state.tool) then
			attachSwordAndShield(state.tool, char, state.humanoid)
		end
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			onStateChanged(state, old, new)
			
			-- Test if movement animations are working
			if new == Enum.HumanoidStateType.Running then
			elseif new == Enum.HumanoidStateType.RunningNoPhysics then
			elseif new == Enum.HumanoidStateType.Jumping then
			end
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
			-- Only trigger attack animation on left mouse click
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
				playAttack(state)
			end
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		playInstantAnimation(state)
	else
	end
end

local function onEquipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then 
		warn("[ARCHER WEAPON] No weapon state found for tool:", tool.Name)
		return 
	end
	state.toolEquipped = true
	state.tool = tool
	
	-- Detect sword and shield
	local hasSwordShield = detectSwordAndShield(tool)
	
	if player.Character then
		onCharacterAdded(state, player.Character)
	else
		warn("[ARCHER WEAPON] No character found when equipping tool")
	end
end

local function onUnequipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Reset combo if available
	if ArcherCombo then
		ArcherCombo.resetCombo()
	end
	
	-- Remove sword and shield
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		removeSwordAndShield(tool, player.Character, player.Character:FindFirstChildOfClass("Humanoid"))
	end
	
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
	
	-- Reset combo when cleaning up
	if ArcherCombo then
		ArcherCombo.resetCombo()
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
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local playingTracks = animator:GetPlayingAnimationTracks()
                for i, track in ipairs(playingTracks) do
                end
            else
                warn("[ARCHER DEBUG] No animator found")
            end
        else
            warn("[ARCHER DEBUG] No humanoid found")
        end
    else
        warn("[ARCHER DEBUG] No character found")
    end
end

-- Make debug function globally accessible
_G.debugArcherAnimations = debugAnimationSystem

-- Global debug functions for combo system
if ArcherCombo then
    _G.debugArcherCombo = function()
        return ArcherCombo.debugComboState()
    end
    
    _G.setArcherComboTimeout = function(seconds)
        return ArcherCombo.setComboTimeout(seconds)
    end
    
    _G.getArcherComboTimeout = function()
        return ArcherCombo.getComboTimeout()
    end
    
    _G.resetArcherCombo = function()
        return ArcherCombo.resetCombo()
    end
    
    _G.setArcherAttackDuration = function(attackNumber, seconds)
        return ArcherCombo.setAttackDuration(attackNumber, seconds)
    end
    
    _G.getArcherAttackDurations = function()
        return ArcherCombo.getAttackDurations()
    end
    
    _G.checkArcherHitboxSystem = function()
        return ArcherCombo.checkHitboxSystem()
    end
    
end

-- Initialize weapon scanner
weaponScanner = WeaponScanner.new("archer_weapon", setupTool, cleanupTool)