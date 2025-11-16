-- ========================================
-- GLADIATOR ACTIONS CLIENT (UNIFIED)
-- Handles skills, buffs, and ultimate for Gladiator class
-- Skills: Shield Bash (Q), Dragoon Jump (E)
-- Buffs: Champions Blood (X), Champions Cheer (C)
-- Ultimate: Demonic Vorpal Dance (Z)
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
local humanoidDeathConnection = nil
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Import centralized configuration
local ServerConfigs = require(ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Import the action module for shared logic
local GladiatorActions = require(script.Parent.GladiatorActionModule)

-- Import sound configuration
local GladiatorSoundConfig = require(ReplicatedStorage:WaitForChild("GladiatorSoundConfig"))

-- Helper function to check if equipped weapon matches player's class (client-side)
local function isWeaponClassMatch()
	local playerClass = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Class")
	if not playerClass then
		return false
	end
	
	local character = player.Character
	if not character then
		return false
	end
	
	local playerClassName = playerClass.Value or nil
	if not playerClassName or playerClassName == "Slavkorian" then
		return false
	end
	
	-- Check all tools in character
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") then
			-- Check each weapon tag
			for className, weaponTag in pairs(ServerConfigs.Client.WeaponTags) do
				if CollectionService:HasTag(item, weaponTag) then
					-- Capitalize first letter to match class names (e.g., "gladiator" -> "Gladiator")
					local weaponClassName = className:sub(1, 1):upper() .. className:sub(2)
					-- SLAVKO can use any weapon; otherwise compare classes
					if string.lower(playerClassName) == "slavko" then
						return true
					end
					-- Compare classes (case-insensitive)
					return string.lower(playerClassName) == string.lower(weaponClassName)
				end
			end
		end
	end
	
	return false
end

-- Camera speed configuration (separate for each action type)
local CAMERA_SPEED_MULTIPLIERS = ServerConfigs.Client.CameraSpeedMultipliers

-- Current action type for camera speed reference
local currentActionType = "idle"

-- Cooldown tracking for camera sequences
local skillCooldowns = {
	shieldbash = false,
	dragoonjump = false,
	championsblood = false,
	championscheer = false,
	demonicvorpaldance = false
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
	GladiatorActions._setCooldown(skillName, isOnCooldown, remainingTime)
end

-- Configuration
local CONFIG = {
	weaponTag = ServerConfigs.Client.WeaponTags.gladiator,
	-- Walking speed is now controlled by server
	actions = {
		[ServerConfigs.Client.Keybinds.gladiator.shieldbash] = "shieldbash",
		[ServerConfigs.Client.Keybinds.gladiator.dragoonjump] = "dragoonjump",
		[ServerConfigs.Client.Keybinds.gladiator.championsblood] = "championsblood",
		[ServerConfigs.Client.Keybinds.gladiator.championscheer] = "championscheer",
		[ServerConfigs.Client.Keybinds.gladiator.demonicvorpaldance] = "demonicvorpaldance",
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = ServerConfigs.Client.Keybinds.global.attack,
		block = ServerConfigs.Client.Keybinds.global.block,
		jump = ServerConfigs.Client.Keybinds.global.jump,
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
local originalCameraState = {
	cframe = nil,
	cameraType = nil,
}

-- Smoothly moves camera to a position over time (scales with action-specific speed multiplier)
local function tweenCameraTo(targetCFrame, tweenDuration, actionType)
	-- Cancel any existing camera tween
	if currentCameraTween then
		currentCameraTween:Cancel()
		currentCameraTween = nil
	end
	
	-- Use specific action speed or fallback to current action type
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType]
	local scaledDuration = tweenDuration / speedMultiplier
	local tweenInfo = TweenInfo.new(scaledDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	currentCameraTween = tween
	tween:Play()
	tween.Completed:Wait()
	currentCameraTween = nil
end

local function restoreOriginalCameraState()
	if originalCameraState.cameraType then
		camera.CameraType = originalCameraState.cameraType
	else
		camera.CameraType = Enum.CameraType.Custom
	end

	if originalCameraState.cframe then
		camera.CFrame = originalCameraState.cframe
	end

	originalCameraState.cframe = nil
	originalCameraState.cameraType = nil
end

local function cancelActiveCameraSequence()
	if currentCameraTween then
		currentCameraTween:Cancel()
		currentCameraTween = nil
	end

	cameraSequenceRunning = false
	lastCameraSequenceTime = tick()

	restoreOriginalCameraState()
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
	originalCameraState.cframe = camera.CFrame
	originalCameraState.cameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Get speed multiplier for this action
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType]

	-- Play each step in the sequence (exact copy from original MightyBlade.lua)
	for _, step in ipairs(sequence) do
		if not cameraSequenceRunning then
			break
		end

		-- Handle both old format (offset + rotX/Y/Z) and new format (cf)
		local targetCFrame
		if step.cf then
			-- New format: use pre-constructed CFrame (like original MightyBlade.lua)
			targetCFrame = root.CFrame * step.cf
		else
			-- Old format: construct CFrame from offset and rotations
			targetCFrame = root.CFrame * step.offset * CFrame.Angles(step.rotX, step.rotY, step.rotZ)
		end
		tweenCameraTo(targetCFrame, step.tweenTime, actionType)
		-- Scale hold time with action-specific camera speed multiplier
		if not cameraSequenceRunning then
			break
		end

		local scaledHoldTime = step.holdTime / speedMultiplier
		task.wait(scaledHoldTime)

		if not cameraSequenceRunning then
			break
		end
	end

	-- Restore original camera instantly (no smooth transition)
	restoreOriginalCameraState()
	
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
	-- Champions Cheer buff (from original Champions Cheer.lua)
	championscheer = {
		{cf = CFrame.new(-5, 1.5, -20) * CFrame.Angles(0, math.rad(-150), 0), tweenTime = 0, holdTime = 0.5},
		{cf = CFrame.new(-2, 2, -3.5) * CFrame.Angles(0, math.rad(-150), 0), tweenTime = 0.3, holdTime = 1},
	},
	-- Demonic Vorpal Dance ultimate (from original Demonic Vorpal Dance.lua)
	demonicvorpaldance = {
		{cf = CFrame.new(0, 1, -10) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 0, holdTime = 0.5},
		{cf = CFrame.new(8, -1.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), tweenTime = 1, holdTime = 0.5},
		{cf = CFrame.new(-8, 150, 0) * CFrame.Angles(math.rad(-90), math.rad(-20), 0), tweenTime = 0, holdTime = 4},
		{cf = CFrame.new(0, 100, 100) * CFrame.Angles(math.rad(-40), math.rad(0), 0), tweenTime = 0, holdTime = 4}
	},
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
	local tool = GladiatorActions._getTool()
	if not tool then
		return nil, nil, nil
	end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return nil, nil, nil
	end
	
	return handle:FindFirstChild("Trail1"), handle:FindFirstChild("Trail2"), handle:FindFirstChild("Trail3")
end

-- Function to enable all trails with individual settings
local function enableTrails(trailConfig)
	trail1, trail2, trail3 = getTrailReferences()
	
	if trail1 then 
		trail1.Enabled = true
		if trailConfig and trailConfig.Lifetime and trailConfig.Lifetime.trail1 then 
			trail1.Lifetime = trailConfig.Lifetime.trail1 
		end
		if trailConfig and trailConfig.Color and trailConfig.Color.trail1 then 
			trail1.Color = ColorSequence.new(Color3.fromRGB(trailConfig.Color.trail1[1], trailConfig.Color.trail1[2], trailConfig.Color.trail1[3]))
		end
		if trailConfig and trailConfig.FaceCamera and trailConfig.FaceCamera.trail1 ~= nil then 
			trail1.FaceCamera = trailConfig.FaceCamera.trail1
		end
	end
	if trail2 then 
		trail2.Enabled = true
		if trailConfig and trailConfig.Lifetime and trailConfig.Lifetime.trail2 then 
			trail2.Lifetime = trailConfig.Lifetime.trail2 
		end
		if trailConfig and trailConfig.Color and trailConfig.Color.trail2 then 
			trail2.Color = ColorSequence.new(Color3.fromRGB(trailConfig.Color.trail2[1], trailConfig.Color.trail2[2], trailConfig.Color.trail2[3]))
		end
		if trailConfig and trailConfig.FaceCamera and trailConfig.FaceCamera.trail2 ~= nil then 
			trail2.FaceCamera = trailConfig.FaceCamera.trail2
		end
	end
	if trail3 then 
		trail3.Enabled = true
		if trailConfig and trailConfig.Lifetime and trailConfig.Lifetime.trail3 then 
			trail3.Lifetime = trailConfig.Lifetime.trail3 
		end
		if trailConfig and trailConfig.Color and trailConfig.Color.trail3 then 
			trail3.Color = ColorSequence.new(Color3.fromRGB(trailConfig.Color.trail3[1], trailConfig.Color.trail3[2], trailConfig.Color.trail3[3]))
		end
		if trailConfig and trailConfig.FaceCamera and trailConfig.FaceCamera.trail3 ~= nil then 
			trail3.FaceCamera = trailConfig.FaceCamera.trail3
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
	
	GladiatorActions._setInputLocked(true)
	controls:Disable()
end

local function unlockInput()
	if not controls then
		return
	end
	
	GladiatorActions._setInputLocked(false)
	controls:Enable()
end

local function lockMovementOnly()
	if not humanoid then
		return
	end
	
	GladiatorActions._setMovementLocked(true)
	-- Walking speed is now controlled by server
end

local function unlockMovementOnly()
	if not humanoid then
		return
	end
	
	GladiatorActions._setMovementLocked(false)
	-- Walking speed is now controlled by server
end

-- ========================================
-- ACTION HANDLER
-- ========================================

local function useAction(actionName)
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not isWeaponClassMatch() then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Gladiator Client] Skill blocked: Player tried to use skill with mismatched weapon.")
			return
		end
	end
	
	-- Use the module to perform the action (handles all validation)
	local success = GladiatorActions.useSkill(actionName)
	
	if not success then
		return
	end
	
	-- Play camera sequence if this action has one AND it's not on cooldown AND weapon matches class
	if CAMERA_SEQUENCES[actionName] and not skillCooldowns[actionName] and isWeaponClassMatch() then
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
	GladiatorActions._setTool(weaponTool)
	
	-- Initialize trails (disable by default)
	disableTrails()
	
	-- Initialize PlayerModule
	initializePlayerModule()
	
	-- ========================================
	-- SOUND SYSTEM
	-- Handles playing attack sounds
	-- ========================================
	
	local function playAttackSound(soundId)
		local character = player.Character
		if not character then return end
		
		-- Find a suitable part to attach the sound to (prefer Head, fallback to HumanoidRootPart)
		local soundPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
		if not soundPart then return end
		
		-- Create and play sound
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0.5
		sound.Parent = soundPart
		sound:Play()
		
		-- Clean up sound when finished
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
	
	-- Play unsheathe sound when weapon is equipped
	local unsheatheSoundId = GladiatorSoundConfig.getSound("unsheathe")
	playAttackSound(unsheatheSoundId)
	
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
			-- data = action name (placeholder for future gladiator sequences)
			-- Check if weapon matches player class before playing camera sequence
			if not isWeaponClassMatch() then
				return -- Block camera sequence if weapon doesn't match class
			end
			-- Server-triggered sequences should always run (server handles cooldown logic)
			task.spawn(function()
				-- Use the predefined sequence from CAMERA_SEQUENCES
				local sequence = CAMERA_SEQUENCES[data]
				if sequence then
					playCameraSequence(sequence, data)
				end
			end)
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
		elseif message == "play_sound" then
			-- data = sound ID string
			if data then
				playAttackSound(data)
			end
		end
	end)
	
	-- Tell server to setup all animations (attack + movement) and attach sword/shield
	remote:FireServer("gladiator_attack_setup", weaponTool)
	
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
		
		-- Handle skills (E, Q, X, Z, C) - currently commented out for basic refactor
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local actionName = CONFIG.actions[input.KeyCode]
			if actionName then
				useAction(actionName)
				return
			end
			
			-- Handle block (V key)
			if input.KeyCode == CONFIG.keybinds.block then
				GladiatorActions.blockStart()
				return
			end
			
			
			-- Note: Wave is now handled globally by GlobalKeybindManager (L key)
		end
		
		-- Handle mouse clicks (left click attack)
		if input.UserInputType == CONFIG.keybinds.attack then
			GladiatorActions.basicAttack()
		end
	end)
	
	-- Listen for input release (block)
	UserInputService.InputEnded:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.block then
			-- V key block release
			GladiatorActions.blockEnd()
		end
	end)
end

local function onWeaponLost()
	cancelActiveCameraSequence()

	if GladiatorActions._getTool() then
		
		-- Tell server to cleanup all animations and remove sword/shield
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		local weaponTool = GladiatorActions._getTool()
		remote:FireServer("gladiator_attack_cleanup", weaponTool)
		
	-- Clear tool reference in module
	GladiatorActions._setTool(nil)
	end
	
	-- Disable trails when weapon is lost
	disableTrails()
	
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

	if humanoidDeathConnection then
		humanoidDeathConnection:Disconnect()
		humanoidDeathConnection = nil
	end

	if humanoid then
		humanoidDeathConnection = humanoid.Died:Connect(function()
			cancelActiveCameraSequence()
			disableTrails()
			unlockInput()
			unlockMovementOnly()
		end)
	end
	
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
		if desc == GladiatorActions._getTool() then
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

player.CharacterRemoving:Connect(function()
	cancelActiveCameraSequence()
	disableTrails()
	unlockInput()
	unlockMovementOnly()
end)

