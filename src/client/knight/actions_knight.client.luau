-- ========================================
-- KNIGHT ACTIONS CLIENT (UNIFIED)
-- Handles skills, buffs, and ultimate for Knight class
-- Skills: Sword Dance (Q), Cyclone Slash (E)
-- Buffs: War Cry (X), Warrior Might (C)
-- Ultimate: Mighty Blade (Z)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local inputConnection = nil
local playerModule = nil
local controls = nil
local humanoid = nil
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Import the action module for shared logic
local KnightActions = require(script.Parent.KnightActionModule)

-- Camera speed configuration (separate for each action type)
local CAMERA_SPEED_MULTIPLIERS = {
	idle = 1.0,
	run = 1.0,
	jump = 1.0,
	combo1 = 1.0,
	combo2 = 1.0,
	combo3 = 1.0,
	moveAttack = 1.0,
	jumpAttack = 1.0,
	block = 1.0,
	wave = 1.0,
	sworddance = 1.0,
	cyclone_slash = 1.0,
	warcry = 1.0,
	warriormight = 1.0,
	mightyblade = 1.0
}

-- Current action type for camera speed reference
local currentActionType = "idle"

-- Cooldown tracking for camera sequences
local skillCooldowns = {
	warcry = false,
	warriormight = false,
	sworddance = false,
	cyclone_slash = false,
	mightyblade = false
}

-- Function to update camera speed for specific action (called automatically by server)
local function updateCameraSpeed(newSpeed, actionType)
	if actionType then
		CAMERA_SPEED_MULTIPLIERS[actionType] = newSpeed
		currentActionType = actionType
	else
		-- Fallback for old system - update all speeds
		for action, _ in pairs(CAMERA_SPEED_MULTIPLIERS) do
			CAMERA_SPEED_MULTIPLIERS[action] = newSpeed
		end
	end
end

-- Function to sync all camera speeds with server values
local function syncAllCameraSpeeds()
	-- Request all animation speeds from server
	remote:FireServer("sync_camera_speeds")
end

-- Function to update cooldown status
local function updateCooldownStatus(skillName, isOnCooldown, remainingTime)
	skillCooldowns[skillName] = isOnCooldown
	KnightActions._setCooldown(skillName, isOnCooldown)
	if isOnCooldown then
		local timeText = remainingTime and tostring(remainingTime) or "unknown"
	end
end

-- Configuration
local CONFIG = {
	weaponTag = "knight_wpn",
	-- Walking speed is now controlled by server
	actions = {
		[Enum.KeyCode.Q] = "sworddance",      -- Skill 1
		[Enum.KeyCode.E] = "cyclone_slash",   -- Skill 2
		[Enum.KeyCode.X] = "warcry",          -- Buff 1
		[Enum.KeyCode.C] = "warriormight",    -- Buff 2
		[Enum.KeyCode.Z] = "mightyblade",     -- Ultimate
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = Enum.UserInputType.MouseButton1, -- Left click
		block = Enum.KeyCode.V,
		jump = Enum.KeyCode.Space, -- Spacebar
		-- Note: Wave is now a global keybind (L key) - handled by GlobalKeybindManager
	}
}

-- ========================================
-- CAMERA SYSTEM
-- Handles cinematic camera movements for skills/buffs/ultimates
-- ========================================

-- Current camera tween (to prevent multiple tweens running simultaneously)
local currentCameraTween = nil
local cameraSequenceRunning = false
local lastCameraSequenceTime = 0
local CAMERA_SEQUENCE_COOLDOWN = 0.1 -- 100ms cooldown between camera sequences

-- Smoothly moves camera to a position over time (scales with action-specific speed multiplier)
local function tweenCameraTo(targetCFrame, tweenDuration, actionType)
	-- Cancel any existing camera tween
	if currentCameraTween then
		currentCameraTween:Cancel()
		currentCameraTween = nil
	end
	
	-- Use specific action speed or fallback to current action type
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType] or 1.0
	local scaledDuration = tweenDuration / speedMultiplier
	local tweenInfo = TweenInfo.new(scaledDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	currentCameraTween = tween
	tween:Play()
	tween.Completed:Wait()
	currentCameraTween = nil
end

-- Plays a cinematic camera sequence
local function playCameraSequence(sequence, actionType)
	-- Spam protection: check cooldown
	local currentTime = tick()
	if currentTime - lastCameraSequenceTime < CAMERA_SEQUENCE_COOLDOWN then
		return
	end
	
	-- Prevent multiple camera sequences from running simultaneously
	if cameraSequenceRunning then
		return
	end
	
	cameraSequenceRunning = true
	lastCameraSequenceTime = currentTime
	
	-- Save original camera settings
	local originalCFrame = camera.CFrame
	local originalType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Get speed multiplier for this action
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType] or 1.0

	-- Play each step in the sequence (exact copy from original MightyBlade.lua)
	for _, step in ipairs(sequence) do
		-- Handle both old format (offset + rotX/Y/Z) and new format (cf)
		local targetCFrame
		if step.cf then
			-- New format: use pre-constructed CFrame (like original MightyBlade.lua)
			targetCFrame = root.CFrame * step.cf
		else
			-- Old format: construct CFrame from offset and rotations
			targetCFrame = root.CFrame * step.offset * CFrame.Angles(step.rotX or 0, step.rotY or 0, step.rotZ or 0)
		end
		tweenCameraTo(targetCFrame, step.tweenTime, actionType)
		-- Scale hold time with action-specific camera speed multiplier
		local scaledHoldTime = step.holdTime / speedMultiplier
		task.wait(scaledHoldTime)
	end

	-- Restore original camera instantly (no smooth transition)
	camera.CFrame = originalCFrame
	camera.CameraType = originalType
	
	-- Mark sequence as completed
	cameraSequenceRunning = false
end

-- ========================================
-- CAMERA SEQUENCES
-- Define cinematic sequences for each action
-- Format: {offset = CFrame.new(x, y, z), rotX/Y/Z = angle, tweenTime = seconds, holdTime = seconds}
-- Offset: X = left(-)/right(+), Y = down(-)/up(+), Z = forward(-)/back(+) relative to player
-- NOTE: All timing values are automatically scaled by CAMERA_SPEED_MULTIPLIER
-- Example: If speed multiplier is 2, a 1 second tween becomes 0.5 seconds
-- ========================================

local CAMERA_SEQUENCES = {
	-- Warrior Might buff (from original WarriorMight.lua)
	warriormight = {
		{cf = CFrame.new(-5, 1.5, -20) * CFrame.Angles(0, math.rad(-150), 0), tweenTime = 0, holdTime = 1.3},
		{cf = CFrame.new(-2, 2, -3.5) * CFrame.Angles(0, math.rad(-150), 0), tweenTime = 0.3, holdTime = 1.5},
	},
	-- Mighty Blade ultimate (from original MightyBlade.lua)
	mightyblade = {
		{cf = CFrame.new(0, 1, -10) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 0, holdTime = 1},
		{cf = CFrame.new(8, -1.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), tweenTime = 1, holdTime = 2},
		{cf = CFrame.new(0, 100, 100) * CFrame.Angles(math.rad(-40), math.rad(0), 0), tweenTime = 0, holdTime = 7}
	}
}

-- ========================================
-- TRAIL MANAGEMENT SYSTEM
-- Handles sword trail activation during attacks
-- ========================================

-- Trail references
local trail1 = nil
local trail2 = nil
local trail3 = nil

-- Function to get trail references from equipped weapon
local function getTrailReferences()
	local tool = KnightActions._getTool()
	if not tool then
		return nil, nil, nil
	end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return nil, nil, nil
	end
	
	return handle:FindFirstChild("Trail1"), handle:FindFirstChild("Trail2"), handle:FindFirstChild("Trail3")
end

-- Function to enable all trails with individual Lifetime settings
local function enableTrails(trailConfig)
	trail1, trail2, trail3 = getTrailReferences()
	
	if trail1 then 
		trail1.Enabled = true
		if trailConfig and trailConfig.trail1 then 
			trail1.Lifetime = trailConfig.trail1 
		end
	end
	if trail2 then 
		trail2.Enabled = true
		if trailConfig and trailConfig.trail2 then 
			trail2.Lifetime = trailConfig.trail2 
		end
	end
	if trail3 then 
		trail3.Enabled = true
		if trailConfig and trailConfig.trail3 then 
			trail3.Lifetime = trailConfig.trail3 
		end
	end
end

-- Function to disable all trails
local function disableTrails()
	if trail1 then trail1.Enabled = false end
	if trail2 then trail2.Enabled = false end
	if trail3 then trail3.Enabled = false end
end

-- Function to enable trails with server-provided configuration
local function enableTrailsWithConfig(trailConfig)
	-- Enable trails with the individual trail Lifetime settings
	enableTrails(trailConfig)
	
	-- Note: Trail cleanup is handled by server when attack animations end
end

-- ========================================
-- INPUT LOCK SYSTEM (Using PlayerModule)
-- ========================================

local function initializePlayerModule()
	-- Get PlayerModule and Controls
	playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
	controls = playerModule:GetControls()
	
	-- Get humanoid for movement control
	local character = player.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
end

local function lockInput()
	if not controls then
		return
	end
	
	KnightActions._setInputLocked(true)
	controls:Disable()
end

local function unlockInput()
	if not controls then
		return
	end
	
	KnightActions._setInputLocked(false)
	controls:Enable()
end

local function lockMovementOnly()
	if not humanoid then
		return
	end
	
	KnightActions._setMovementLocked(true)
	-- Walking speed is now controlled by server
end

local function unlockMovementOnly()
	if not humanoid then
		return
	end
	
	KnightActions._setMovementLocked(false)
	-- Walking speed is now controlled by server
end

-- ========================================
-- ACTION HANDLER
-- ========================================

local function useAction(actionName)
	-- Use the module to perform the action (handles all validation)
	local success = KnightActions.useSkill(actionName)
	
	if not success then
		return
	end
	
	-- Play camera sequence if this action has one AND it's not on cooldown
	if CAMERA_SEQUENCES[actionName] and not skillCooldowns[actionName] then
		task.spawn(function()
			playCameraSequence(CAMERA_SEQUENCES[actionName], actionName)
		end)
	end
end

-- ========================================
-- WEAPON DETECTION & INPUT HANDLING
-- ========================================

local function onWeaponFound(weaponTool)
	-- Update module state
	KnightActions._setTool(weaponTool)
	
	-- Initialize trails (disable by default)
	disableTrails()
	
	-- Initialize PlayerModule
	initializePlayerModule()
	
	-- Listen for messages from server
	remote.OnClientEvent:Connect(function(message, data, extraData, thirdParam)
		if message == "lock_input" then
			lockInput()
		elseif message == "unlock_input" then
			unlockInput()
		elseif message == "lock_movement" then
			lockMovementOnly()
		elseif message == "unlock_movement" then
			unlockMovementOnly()
		elseif message == "update_animation_speed" then
			updateCameraSpeed(data, extraData) -- data = speed value, extraData = action type
		elseif message == "cooldown_status" then
			updateCooldownStatus(data, extraData, thirdParam) -- data = skillName, extraData = isOnCooldown, thirdParam = remainingTime
		elseif message == "play_camera_sequence" then
			-- data = action name (e.g., "warriormight", "mightyblade")
			-- Server-triggered sequences should always run (server handles cooldown logic)
			if data == "warriormight" or data == "mightyblade" then
				task.spawn(function()
					-- Use the predefined sequence from CAMERA_SEQUENCES
					local sequence = CAMERA_SEQUENCES[data]
					if sequence then
						playCameraSequence(sequence, data)
					end
				end)
			end
		elseif message == "enable_trails" then
			-- data = trail configuration table with trail1, trail2, trail3 lifetimes
			local trailConfig = data
			
			task.spawn(function()
				enableTrailsWithConfig(trailConfig)
			end)
		elseif message == "disable_trails" then
			disableTrails()
		elseif message == "sync_trail_config" then
			-- data = trail configuration from server
			-- This is just for reference - the server handles all trail timing
			-- No action needed on client side since server sends specific values
		end
	end)
	
	-- Tell server to setup all animations (attack + movement) and attach sword/shield
	remote:FireServer("knight_attack_setup", weaponTool)
	
	-- Sync all camera speeds with server values
	syncAllCameraSpeeds()
	
	-- Clean up old connections
	if inputConnection then
		inputConnection:Disconnect()
	end
	
	-- Listen for all input (skills, attacks, block, jump)
	inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		-- Allow camera movement (mouse movement) even when movement is locked
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			return -- Allow camera movement
		end
		
		-- Handle skills (E, Q, X, Z, C)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local actionName = CONFIG.actions[input.KeyCode]
			if actionName then
				useAction(actionName)
				return
			end
			
			-- Handle block (V key)
			if input.KeyCode == CONFIG.keybinds.block then
				KnightActions.blockStart()
				return
			end
			
			-- Handle jump (Spacebar)
			if input.KeyCode == CONFIG.keybinds.jump then
				KnightActions.jumpAttack()
				return
			end
			
			-- Note: Wave is now handled globally by GlobalKeybindManager (L key)
		end
		
		-- Handle mouse clicks (left click attack)
		if input.UserInputType == CONFIG.keybinds.attack then
			KnightActions.basicAttack()
		end
	end)
	
	-- Listen for input release (block)
	UserInputService.InputEnded:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.block then
			-- Block release
			KnightActions.blockEnd()
		end
	end)
end

local function onWeaponLost()
	if KnightActions._getTool() then
		
		-- Tell server to cleanup all animations and remove sword/shield
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		local weaponTool = KnightActions._getTool()
		remote:FireServer("knight_attack_cleanup", weaponTool)
		
	-- Clear tool reference in module
	KnightActions._setTool(nil)
	end
	
	-- Disable trails when weapon is lost
	disableTrails()
	
	-- Reset camera sequence flag
	cameraSequenceRunning = false
	
	-- Unlock input when weapon is lost
	unlockInput()
	unlockMovementOnly()
	
	-- Clean up input connections
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
end

local function onCharacterAdded(character)
	-- Update humanoid reference
	humanoid = character:FindFirstChildOfClass("Humanoid")
	
	-- Check if weapon is already equipped
	for _, weaponTool in character:GetChildren() do
		if weaponTool:IsA("Tool") and CollectionService:HasTag(weaponTool, CONFIG.weaponTag) then
			onWeaponFound(weaponTool)
		end
	end
	
	-- Listen for weapon being equipped
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("Tool") and CollectionService:HasTag(desc, CONFIG.weaponTag) then
			onWeaponFound(desc)
		end
	end)
	
	-- Listen for weapon being unequipped
	character.DescendantRemoving:Connect(function(desc)
		if desc == KnightActions._getTool() then
			onWeaponLost()
		end
	end)
end

-- ========================================
-- INITIALIZE
-- ========================================

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

