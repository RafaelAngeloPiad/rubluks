-- ========================================
-- ARCHER ACTIONS CLIENT (UNIFIED)
-- Handles skills, buffs, and ultimate for Archer class
-- Skills: Piercing Shot (Q), Power Shot (E)
-- Buffs: Hunter Instinct (X), Hunter Mark (C)
-- Ultimate: Starfall (Z)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
local ArcherActions = require(script.Parent.ArcherActionModule)

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
					-- Capitalize first letter to match class names (e.g., "archer" -> "Archer")
					local weaponClassName = className:sub(1, 1):upper() .. className:sub(2)
					-- Compare classes (case-insensitive)
					return playerClassName:lower() == weaponClassName:lower()
				end
			end
		end
	end
	
	return false
end

-- V1 Camera Lock and Crosshair System
local crosshairGui = nil
local cameraLockEnabled = false
local cameraLockConnection = nil
local crosshairConnection = nil
local cameraOffsetEnabled = false
local originalCameraOffset = nil

-- Aim Lock Toggle System
local aimLockEnabled = false
local dynamicAimHeld = false

-- Aim Lock Mode Configuration
-- Options: true (always aim lock), false (never aim lock), "dynamic" (toggle with F key)
local AIM_LOCK_MODE = ServerConfigs.Client.Archer.aimLock.mode

-- Aim Lock Mode Toggle System
local aimLockModes = ServerConfigs.Client.Archer.aimLock.modes
local currentModeIndex = ServerConfigs.Client.Archer.aimLock.currentModeIndex

-- First-Person Detection System
local isFirstPerson = false
local firstPersonConnection = nil

-- ========================================
-- ARROW TRAIL COLOR MANAGEMENT
-- Simple color configuration for arrow trails
-- ========================================

-- Current arrow trail color
local currentArrowTrailColor = ServerConfigs.Client.Archer.arrowTrailColor

-- Function to set arrow trail color
local function setArrowTrailColor(colorRGB)
	currentArrowTrailColor = colorRGB
	
	-- Find the current arrow in workspace and set its trail color
	local archerArrow = workspace:FindFirstChild("ArcherArrow")
	if archerArrow then
		local arrow = archerArrow:FindFirstChild("Arrow")
		if arrow then
			local trail1 = arrow:FindFirstChild("Trail1")
			if trail1 then
				trail1.Color = ColorSequence.new(Color3.fromRGB(colorRGB[1], colorRGB[2], colorRGB[3]))
			end
		end
	end
end


-- Camera speed configuration (separate for each action type)
local CAMERA_SPEED_MULTIPLIERS = ServerConfigs.Client.CameraSpeedMultipliers

-- Current action type for camera speed reference
local currentActionType = "idle"

-- Cooldown tracking for camera sequences
local skillCooldowns = {
	piercingShot = false,
	powerShot = false,
	hunterInstinct = false,
	hunterMark = false,
	starfall = false
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
	ArcherActions._setCooldown(skillName, isOnCooldown, remainingTime)
end

-- Configuration
local CONFIG = {
	weaponTag = ServerConfigs.Client.WeaponTags.archer,
	-- Walking speed is now controlled by server
	actions = {
		[ServerConfigs.Client.Keybinds.archer.piercingShot] = "piercingShot",
		[ServerConfigs.Client.Keybinds.archer.powerShot] = "powerShot",
		[ServerConfigs.Client.Keybinds.archer.hunterInstinct] = "hunterInstinct",
		[ServerConfigs.Client.Keybinds.archer.hunterMark] = "hunterMark",
		[ServerConfigs.Client.Keybinds.archer.starfall] = "starfall",
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = ServerConfigs.Client.Keybinds.global.attack,
		block = ServerConfigs.Client.Keybinds.global.block,
		jump = ServerConfigs.Client.Keybinds.global.jump,
		-- Note: Wave is now a global keybind (L key) - handled by GlobalKeybindManager
		aimLockToggle = Enum.KeyCode.T, -- T key for aim lock mode toggle
		dynamicAim = ServerConfigs.Client.Keybinds.archer.dynamicAim,
	}
}

-- ========================================
-- V1 CAMERA LOCK AND CROSSHAIR SYSTEM
-- Simple, clean implementation for archer aiming
-- ========================================

-- Create crosshair UI that matches camera's center view exactly (v1 implementation)
local function createCrosshair()
	if crosshairGui then
		crosshairGui:Destroy()
	end
	
	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "ArcherCrosshair"
	crosshairGui.ResetOnSpawn = false
	crosshairGui.Parent = player.PlayerGui
	
	-- Create simple black dot crosshair
	local crosshairFrame = Instance.new("Frame")
	crosshairFrame.Name = "CrosshairFrame"
	crosshairFrame.Size = UDim2.new(0, 8, 0, 8) -- Small 8x8 pixel dot
	crosshairFrame.BackgroundColor3 = Color3.new(0, 0, 0) -- Black dot
	crosshairFrame.BorderSizePixel = 0
	crosshairFrame.Parent = crosshairGui
	
	-- Position crosshair to match camera's center view exactly
	local function updateCrosshairPosition()
		if not crosshairGui or not crosshairGui.Parent then return end
		
		-- Different positioning for first-person vs third-person
		if isFirstPerson then
			-- In first-person: center the crosshair perfectly (no offset needed)
			-- Use absolute positioning to ensure it stays perfectly centered
			crosshairFrame.Position = UDim2.new(0.5, -4, 0.5, -4) -- Perfect center
		else
		-- In third-person: use offset to avoid body overlap
		local camera = workspace.CurrentCamera
		if not camera then return end
		
		local crosshairOffset = Vector3.new(-19.5, 14, 0) -- X: left(-)/right(+), Y: down(-)/up(+) (adjusted for increased camera offset)
			
			-- Get camera's center view direction (same as projectile)
			local cameraDirection = camera.CFrame.LookVector
			local cameraPosition = camera.CFrame.Position
			
			-- Calculate where camera is looking in world space (same as projectile target)
			local lookTarget = cameraPosition + cameraDirection * 100
			
			-- Convert world position to screen position
			local screenPoint, onScreen = camera:WorldToScreenPoint(lookTarget)
			
			if onScreen then
				-- Position crosshair with offset
				local xPos = screenPoint.X - 4 + crosshairOffset.X
				local yPos = screenPoint.Y - 4 + crosshairOffset.Y
				crosshairFrame.Position = UDim2.new(0, xPos, 0, yPos)
				
			else
				-- If off-screen, keep it centered with offset
				local centerX = -4 + crosshairOffset.X
				local centerY = -4 + crosshairOffset.Y
				crosshairFrame.Position = UDim2.new(0.5, centerX, 0.5, centerY)
				
			end
		end
	end
	
	-- Update crosshair position every frame to match camera
	crosshairConnection = RunService.Heartbeat:Connect(function()
		updateCrosshairPosition()
	end)
	
	-- No animation - just a steady dot
end

-- Remove crosshair UI
local function removeCrosshair()
	if crosshairGui then
		crosshairGui:Destroy()
		crosshairGui = nil
	end
	
	-- Disconnect crosshair position update connection
	if crosshairConnection then
		crosshairConnection:Disconnect()
		crosshairConnection = nil
	end
end

-- Enable v1 camera lock - simple character rotation to face camera
local function enableCameraLock()
	if cameraLockEnabled then return end
	
	cameraLockEnabled = true
	
	-- Create camera lock connection
	cameraLockConnection = RunService.Heartbeat:Connect(function()
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			
			if rootPart then
				-- Get camera direction
				local cameraDirection = camera.CFrame.LookVector
				
				-- Make character face camera direction (only horizontal rotation)
				local lookDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit
				
				-- Rotate character to face camera direction
				if lookDirection.Magnitude > 0 then
					rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookDirection)
				end
			end
		end
	end)
end

-- Disable v1 camera lock
local function disableCameraLock()
	if not cameraLockEnabled then return end
	
	cameraLockEnabled = false
	
	-- Disconnect camera lock connection
	if cameraLockConnection then
		cameraLockConnection:Disconnect()
		cameraLockConnection = nil
	end
end

-- Enable v1 camera offset - moves player to left side of screen
local function enableCameraOffset()
	if cameraOffsetEnabled then return end
	
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then return end
	
	local humanoid = player.Character.Humanoid
	
	-- Store original camera offset
	originalCameraOffset = humanoid.CameraOffset
	
	-- Set camera offset to move player to the left side of screen
	-- This moves the player but keeps the crosshair centered
	humanoid.CameraOffset = Vector3.new(4.0, 0, 0) -- 4.0 studs to the left (increased from 2.5)
	
	cameraOffsetEnabled = true
end

-- Disable v1 camera offset and restore original
local function disableCameraOffset()
	if not cameraOffsetEnabled then return end
	
	cameraOffsetEnabled = false
	
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local humanoid = player.Character.Humanoid
		-- Restore original camera offset
		humanoid.CameraOffset = originalCameraOffset
	end
end

-- ========================================
-- FIRST-PERSON DETECTION SYSTEM
-- Uses Roblox's built-in camera properties for accurate detection
-- ========================================

-- Function to detect if player is in first-person mode using MouseBehavior
local function detectFirstPerson()
	return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

-- Function to update first-person state and handle changes
local function updateFirstPersonState()
	local wasFirstPerson = isFirstPerson
	isFirstPerson = detectFirstPerson()
	
	-- Sync with module
	ArcherActions._setFirstPerson(isFirstPerson)
	
	-- Only handle when state changes
	if wasFirstPerson ~= isFirstPerson then
		if isFirstPerson then
			-- Hide mouse pointer and disable camera offset in first-person
			UserInputService.MouseIconEnabled = false
			if cameraOffsetEnabled then
				disableCameraOffset()
			end
		else
			-- Show mouse pointer and enable camera offset in third-person
			UserInputService.MouseIconEnabled = true
			if aimLockEnabled and not cameraOffsetEnabled then
				enableCameraOffset()
			end
		end
	end
end

-- Function to start first-person detection
local function startFirstPersonDetection()
	if firstPersonConnection then return end
	
	-- Initial check
	updateFirstPersonState()
	
	-- Listen for changes to MouseBehavior
	firstPersonConnection = UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(updateFirstPersonState)
end

-- Function to stop first-person detection
local function stopFirstPersonDetection()
	if firstPersonConnection then
		firstPersonConnection:Disconnect()
		firstPersonConnection = nil
	end
end

-- Setup v1 archer aiming system
local function setupArcherAiming()
	createCrosshair()
	-- Start with crosshair visibility based on current aim lock state
	if crosshairGui then
		crosshairGui.Enabled = aimLockEnabled
	end
	enableCameraLock()
	-- Only enable camera offset if aim lock is enabled
	if aimLockEnabled then
		enableCameraOffset()
	end
end

-- Cleanup v1 archer aiming system
local function cleanupArcherAiming()
	removeCrosshair()
	disableCameraLock()
	disableCameraOffset()
end

-- Toggle aim lock based on configuration mode
local function updateAimLockState()
	-- Determine aim lock state based on mode
	if AIM_LOCK_MODE == true then
		-- Always aim lock mode
		aimLockEnabled = true
	elseif AIM_LOCK_MODE == false then
		-- Never aim lock mode
		aimLockEnabled = false
	elseif AIM_LOCK_MODE == "dynamic" then
		-- Dynamic toggle mode (F key)
		aimLockEnabled = dynamicAimHeld
	else
		-- Default to dynamic mode if invalid setting
		aimLockEnabled = dynamicAimHeld
	end
	
	-- Sync with module
	ArcherActions._setAimLockEnabled(aimLockEnabled)
	
	-- Apply camera and crosshair changes based on aim lock state
	if aimLockEnabled then
		-- Enable camera offset and lock when aiming (but NOT in first-person)
		if not isFirstPerson then
			enableCameraOffset()
		end
		enableCameraLock()
		-- Show crosshair when aiming
		if crosshairGui then
			crosshairGui.Enabled = true
		end
	else
		-- Disable camera offset and lock when not aiming
		disableCameraOffset()
		disableCameraLock()
		-- Hide crosshair when not aiming
		if crosshairGui then
			crosshairGui.Enabled = false
		end
	end
end

-- Function to cycle through aim lock modes
local function cycleAimLockMode()
	currentModeIndex = currentModeIndex + 1
	if currentModeIndex > #aimLockModes then
		currentModeIndex = 1
	end
	
	AIM_LOCK_MODE = aimLockModes[currentModeIndex]
	
	-- Update the aim lock state immediately
	updateAimLockState()
end

-- ========================================
-- CAMERA SYSTEM
-- Handles cinematic camera movements for skills/buffs/ultimates
-- ========================================

-- Current camera tween (to prevent multiple tweens running simultaneously)
local currentCameraTween = nil
local cameraSequenceRunning = false
local cameraSequenceCancelled = false
local lastCameraSequenceTime = 0
local CAMERA_SEQUENCE_COOLDOWN = 0.1 -- 100ms cooldown between camera sequences
local originalCameraState = {
	cframe = nil,
	cameraType = nil,
}
local currentSequenceAction = nil

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

	cameraSequenceCancelled = true
	cameraSequenceRunning = false
	lastCameraSequenceTime = tick()

	restoreOriginalCameraState()

	if currentSequenceAction == "starfall" or currentSequenceAction == "hunterMark" then
		setupArcherAiming()
	end

	currentSequenceAction = nil
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
	cameraSequenceCancelled = false
	currentSequenceAction = actionType
	lastCameraSequenceTime = currentTime
	
	-- Save original camera settings
	originalCameraState.cframe = camera.CFrame
	originalCameraState.cameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Get speed multiplier for this action
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType]

	-- Disable archer aiming system during starfall ultimate and hunterMark buff
	if actionType == "starfall" or actionType == "hunterMark" then
		cleanupArcherAiming()
	end
	
	-- Play each step in the sequence (exact copy from original format)
	for _, step in ipairs(sequence) do
		if not cameraSequenceRunning then
			break
		end

		-- Handle both old format (offset + rotX/Y/Z) and new format (cf)
		local targetCFrame
		if step.cf then
			-- New format: use pre-constructed CFrame (like original files)
			targetCFrame = root.CFrame * step.cf
		else
			-- Old format: construct CFrame from offset and rotations
			targetCFrame = root.CFrame * step.offset * CFrame.Angles(step.rotX, step.rotY, step.rotZ)
		end
		tweenCameraTo(targetCFrame, step.tweenTime, actionType)
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
	
	-- Re-enable archer aiming system after starfall or hunterMark camera sequence ends
	if not cameraSequenceCancelled and (actionType == "starfall" or actionType == "hunterMark") then
		setupArcherAiming()
	end
	
	-- Mark sequence as completed
	cameraSequenceRunning = false
	cameraSequenceCancelled = false
	currentSequenceAction = nil
end

-- ========================================
-- CAMERA SEQUENCES
-- Define cinematic sequences for each action (clean organization like samurai)
-- Format: {offset = CFrame.new(x, y, z), rotX/Y/Z = angle, tweenTime = seconds, holdTime = seconds}
-- Offset: X = left(-)/right(+), Y = down(-)/up(+), Z = forward(-)/back(+) relative to player
-- ========================================

local CAMERA_SEQUENCES = {
	-- Buff (exact copy from original HunterMark.lua format)
	hunterMark = {
		{cf = CFrame.new(-5, 1.5, -20) * CFrame.Angles(0, math.rad(-150), 0), tweenTime = 0, holdTime = 1.3},
		{cf = CFrame.new(-2, 2, -3.5) * CFrame.Angles(0, math.rad(-150), 0), tweenTime = 0.3, holdTime = 1.5}
	},
	-- Ultimate (exact copy from original Starfall.lua format)
	starfall = {
		{cf = CFrame.new(0, 2, -10) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 0, holdTime = 1},
		{cf = CFrame.new(-8, 2, -1.5) * CFrame.Angles(0, math.rad(-90), 0), tweenTime = 1, holdTime = 2},
		{cf = CFrame.new(0, 100, 100) * CFrame.Angles(math.rad(-40), math.rad(0), 0), tweenTime = 0, holdTime = 7}
	}
}

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
	
	ArcherActions._setInputLocked(true)
	controls:Disable()
end

local function unlockInput()
	if not controls then
		return
	end
	
	ArcherActions._setInputLocked(false)
	controls:Enable()
end

local function lockMovementOnly()
	if not humanoid then
		return
	end
	
	ArcherActions._setMovementLocked(true)
	-- Walking speed is now controlled by server
end

local function unlockMovementOnly()
	if not humanoid then
		return
	end
	
	ArcherActions._setMovementLocked(false)
	-- Walking speed is now controlled by server
end

-- ========================================
-- ACTION HANDLER
-- ========================================

local function useAction(actionName)
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not isWeaponClassMatch() then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Archer Client] Skill blocked: Player tried to use skill with mismatched weapon.")
			return
		end
	end
	
	-- Use the module to perform the action (handles all validation)
	local success = ArcherActions.useSkill(actionName)
	
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
	ArcherActions._setTool(weaponTool)
	
	-- Register aim control callbacks for module
	ArcherActions._registerAimCallbacks(
		cycleAimLockMode,
		function()
			-- Dynamic aim start
			dynamicAimHeld = true
			updateAimLockState()
		end,
		function()
			-- Dynamic aim end
			dynamicAimHeld = false
			updateAimLockState()
		end,
		function()
			-- Get current aim mode
			return AIM_LOCK_MODE
		end
	)
	
	-- Initialize PlayerModule
	initializePlayerModule()
	
	-- Setup v1 archer aiming system
	setupArcherAiming()
	
	-- Start first-person detection
	startFirstPersonDetection()
	
	-- Initialize aim lock mode from current index
	AIM_LOCK_MODE = aimLockModes[currentModeIndex]
	
	-- Set initial aim lock state based on mode
	updateAimLockState()
	
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
		elseif message == "cleanup_archer_aiming" then
			cleanupArcherAiming()
		elseif message == "setup_archer_aiming" then
			setupArcherAiming()
		elseif message == "update_animation_speed" then
			updateCameraSpeed(data, extraData) -- data = speed value, extraData = action type
		elseif message == "cooldown_status" then
			updateCooldownStatus(data, extraData, thirdParam) -- data = skillName, extraData = isOnCooldown, thirdParam = remainingTime
		elseif message == "sync_aim_lock_state" then
			-- Server is syncing aim lock state to client
			aimLockEnabled = data -- data = aim lock enabled state
			-- Update crosshair visibility based on server state
			if crosshairGui then
				crosshairGui.Enabled = aimLockEnabled
			end
			-- Only update aim lock state if not in first-person mode
			-- In first-person mode, camera offset should stay disabled
			if not isFirstPerson then
				updateAimLockState()
			end
		elseif message == "play_camera_sequence" then
			-- data = action name (e.g., "starfall", "hunterMark")
			-- Check if weapon matches player class before playing camera sequence
			if not isWeaponClassMatch() then
				return -- Block camera sequence if weapon doesn't match class
			end
			-- Server-triggered sequences should always run (server handles cooldown logic)
			if data == "starfall" or data == "hunterMark" then
				task.spawn(function()
					-- Use the predefined sequence from CAMERA_SEQUENCES
					local sequence = CAMERA_SEQUENCES[data]
					if sequence then
						playCameraSequence(sequence, data)
					end
				end)
			end
		elseif message == "set_arrow_trail_color" then
			-- data = {r, g, b} color values
			local colorRGB = data
			setArrowTrailColor(colorRGB)
		end
	end)
	
	-- Tell server to setup all animations (attack + movement)
	remote:FireServer("archer_attack_setup", weaponTool)
	
	-- Sync all camera speeds with server values
	syncAllCameraSpeeds()
	
	-- Clean up old connections
	if inputConnection then
		inputConnection:Disconnect()
	end
	
	-- Listen for all input (skills, attacks, block, jump)
	inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		-- Allow camera movement (mouse movement) even when input is locked
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			return -- Allow camera movement
		end
		
		-- Handle skills (Q, E, X, C, Z)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local actionName = CONFIG.actions[input.KeyCode]
			if actionName then
				useAction(actionName)
				return
			end
			
			-- Handle block (V key)
			if input.KeyCode == CONFIG.keybinds.block then
				ArcherActions.blockStart()
				return
			end
			
			
			-- Note: Wave is now handled globally by GlobalKeybindManager (L key)
			
			-- Handle aim lock mode toggle - works even when movement is locked
			if input.KeyCode == CONFIG.keybinds.aimLockToggle then
				cycleAimLockMode()
				return
			end
		end
		
		-- Handle mouse clicks
		if input.UserInputType == CONFIG.keybinds.attack then
			ArcherActions.basicAttack()
		end
		
		-- Handle F key for aim lock toggle (only in dynamic mode)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.dynamicAim and AIM_LOCK_MODE == "dynamic" then
			dynamicAimHeld = true
			updateAimLockState()
		end
	end)
	
	-- Listen for input release (block and dynamic aim)
	UserInputService.InputEnded:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.block then
			-- Block release
			ArcherActions.blockEnd()
		elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.dynamicAim and AIM_LOCK_MODE == "dynamic" then
			-- F key release - disable aim lock (only in dynamic mode)
			dynamicAimHeld = false
			updateAimLockState()
		end
	end)
end

local function onWeaponLost()
	cancelActiveCameraSequence()

	if ArcherActions._getTool() then
		local weaponTool = ArcherActions._getTool()
		
		-- Tell server to cleanup all animations
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		remote:FireServer("archer_attack_cleanup", weaponTool)
		
		-- Clear tool reference in module
		ArcherActions._setTool(nil)
	end
	
	-- Cleanup v1 archer aiming system
	cleanupArcherAiming()
	
	-- Stop first-person detection
	stopFirstPersonDetection()
	
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
			cleanupArcherAiming()
			stopFirstPersonDetection()
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
		if desc == ArcherActions._getTool() then
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
	cleanupArcherAiming()
	stopFirstPersonDetection()
end)

