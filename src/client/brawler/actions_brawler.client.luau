-- ========================================
-- BRAWLER ACTIONS CLIENT (UNIFIED)
-- Handles skills, buffs, and ultimate for Brawler class
-- Skills: Berserker's Roar (Q), Feral Leap (E)
-- Buffs: Bloodthirst (X), Last Chance (C)
-- Ultimate: Meteor Dive (Z)
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

-- Import centralized configuration
local ServerConfigs = require(ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Import the action module for shared logic
local BrawlerActions = require(script.Parent.BrawlerActionModule)

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
					-- Capitalize first letter to match class names (e.g., "brawler" -> "Brawler")
					local weaponClassName = className:sub(1, 1):upper() .. className:sub(2)
					-- Compare classes (case-insensitive)
					return playerClassName:lower() == weaponClassName:lower()
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
	feralleap = false,
	brawlersroar = false,
	bloodthirst = false,
	lastchance = false,
	meteordive = false
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
	BrawlerActions._setCooldown(skillName, isOnCooldown)
	if isOnCooldown then
		local timeText = remainingTime and tostring(remainingTime)
	end
end

-- Configuration (moved up to be accessible by feral leap functions)
local CONFIG = {
	weaponTag = ServerConfigs.Client.WeaponTags.brawler,
	-- Walking speed is now controlled by server
	actions = {
		[ServerConfigs.Client.Keybinds.brawler.brawlersroar] = "brawlersroar",
		[ServerConfigs.Client.Keybinds.brawler.feralleap] = "feralleap",
		[ServerConfigs.Client.Keybinds.brawler.bloodthirst] = "bloodthirst",
		[ServerConfigs.Client.Keybinds.brawler.lastchance] = "lastchance",
		[ServerConfigs.Client.Keybinds.brawler.meteordive] = "meteordive",
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = ServerConfigs.Client.Keybinds.global.attack,
		block = ServerConfigs.Client.Keybinds.global.block,
		jump = ServerConfigs.Client.Keybinds.global.jump,
		feralleapStop = ServerConfigs.Client.Keybinds.brawler.feralleapStop,
		-- Note: Wave is now a global keybind (L key) - handled by GlobalKeybindManager
	}
}

-- ========================================
-- TRAIL MANAGEMENT SYSTEM
-- Handles weapon trail activation during attacks
-- ========================================

-- Trail references (for both Handle and Shield)
local trail1, trail2, trail3, trail4, trail5, trail6 = nil

-- Function to get trail references from the current weapon
local function getTrailReferences()
	local tool = BrawlerActions._getTool()
	if not tool then
		return nil, nil, nil, nil, nil, nil
	end

	local handle = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")
	
	if not handle or not shield then
		return nil, nil, nil, nil, nil, nil
	end

	-- Handle trails (trail1, trail2, trail3) - these are the first 3 trails
	local handleTrail1 = handle:FindFirstChild("Trail1")
	local handleTrail2 = handle:FindFirstChild("Trail2")
	local handleTrail3 = handle:FindFirstChild("Trail3")
	
	-- Shield trails (trail4, trail5, trail6) - these are the next 3 trails
	local shieldTrail1 = shield:FindFirstChild("Trail1")
	local shieldTrail2 = shield:FindFirstChild("Trail2")
	local shieldTrail3 = shield:FindFirstChild("Trail3")
	
	-- Return in order: handle trails first, then shield trails
	return handleTrail1, handleTrail2, handleTrail3, shieldTrail1, shieldTrail2, shieldTrail3
end

-- Function to enable all trails with individual settings
local function enableTrails(trailConfig)
	trail1, trail2, trail3, trail4, trail5, trail6 = getTrailReferences()
	
	
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
	if trail4 then 
		trail4.Enabled = true
		if trailConfig and trailConfig.Lifetime and trailConfig.Lifetime.trail4 then 
			trail4.Lifetime = trailConfig.Lifetime.trail4 
		end
		if trailConfig and trailConfig.Color and trailConfig.Color.trail4 then 
			trail4.Color = ColorSequence.new(Color3.fromRGB(trailConfig.Color.trail4[1], trailConfig.Color.trail4[2], trailConfig.Color.trail4[3]))
		end
		if trailConfig and trailConfig.FaceCamera and trailConfig.FaceCamera.trail4 ~= nil then 
			trail4.FaceCamera = trailConfig.FaceCamera.trail4
		end
	end
	if trail5 then 
		trail5.Enabled = true
		if trailConfig and trailConfig.Lifetime and trailConfig.Lifetime.trail5 then 
			trail5.Lifetime = trailConfig.Lifetime.trail5 
		end
		if trailConfig and trailConfig.Color and trailConfig.Color.trail5 then 
			trail5.Color = ColorSequence.new(Color3.fromRGB(trailConfig.Color.trail5[1], trailConfig.Color.trail5[2], trailConfig.Color.trail5[3]))
		end
		if trailConfig and trailConfig.FaceCamera and trailConfig.FaceCamera.trail5 ~= nil then 
			trail5.FaceCamera = trailConfig.FaceCamera.trail5
		end
	end
	if trail6 then 
		trail6.Enabled = true
		if trailConfig and trailConfig.Lifetime and trailConfig.Lifetime.trail6 then 
			trail6.Lifetime = trailConfig.Lifetime.trail6 
		end
		if trailConfig and trailConfig.Color and trailConfig.Color.trail6 then 
			trail6.Color = ColorSequence.new(Color3.fromRGB(trailConfig.Color.trail6[1], trailConfig.Color.trail6[2], trailConfig.Color.trail6[3]))
		end
		if trailConfig and trailConfig.FaceCamera and trailConfig.FaceCamera.trail6 ~= nil then 
			trail6.FaceCamera = trailConfig.FaceCamera.trail6
		end
	end
end

-- Function to disable all trails
local function disableTrails()
	if trail1 then trail1.Enabled = false end
	if trail2 then trail2.Enabled = false end
	if trail3 then trail3.Enabled = false end
	if trail4 then trail4.Enabled = false end
	if trail5 then trail5.Enabled = false end
	if trail6 then trail6.Enabled = false end
end

-- Function to enable trails with configuration
local function enableTrailsWithConfig(trailConfig)
	-- Enable trails with the individual trail settings
	enableTrails(trailConfig)
	
	-- Note: Trail cleanup is handled by server when attack animations end
end

-- ========================================
-- FERAL LEAP CLIENT-SIDE MOVEMENT CONTROL
-- ========================================

local isLeaping = false
local leapConnection = nil
local currentVelocity = nil
local leapStartTime = 0
local MAX_LEAP_DURATION = 5 -- Maximum leap duration in seconds (safety measure)
local collisionConnection = nil
local collisionBox = nil
local collisionBoxWeld = nil
local hasStoppedLeap = false -- Flag to prevent multiple stop calls
local isInitialized = false -- Flag to track if system is ready
local initializationDelay = ServerConfigs.Client.Brawler.feralLeap.initializationDelay

local function disconnectLeapConnections()
	if leapConnection then
		leapConnection:Disconnect()
		leapConnection = nil
	end
	if collisionConnection then
		collisionConnection:Disconnect()
		collisionConnection = nil
	end
	-- Destroy collision box if exists
	if collisionBox then
		pcall(function()
			collisionBox:Destroy()
		end)
		collisionBox = nil
		collisionBoxWeld = nil
	end
end

local function cleanupFeralLeapState()
	-- Stop any active leap
	if isLeaping then
		isLeaping = false
		hasStoppedLeap = true
		disconnectLeapConnections()
		
		-- Destroy velocity
		if currentVelocity then
			pcall(function()
				currentVelocity:Destroy()
			end)
			currentVelocity = nil
		end
	end
	
	-- Reset all state
	isLeaping = false
	hasStoppedLeap = false
	isInitialized = false
end

local function stopFeralLeap()
	if not isLeaping or hasStoppedLeap then return end
	
	-- Debug info
	local leapDuration = tick() - leapStartTime
	
	isLeaping = false
	hasStoppedLeap = true
	
	-- Disconnect movement loop and collision
	disconnectLeapConnections()
	
	-- Destroy velocity (with error handling)
	if currentVelocity then
		pcall(function()
			currentVelocity:Destroy()
		end)
		currentVelocity = nil
	end
	
	-- Tell server to stop (triggers attack animation)
	remote:FireServer("feralleap_client_stop")
end

local function startFeralLeap()
	-- Safety checks
	if not isInitialized then
		warn("Feral Leap: System not fully initialized yet, but attempting to start anyway...")
		-- Don't return, allow it to proceed with warning
	end
	
	if isLeaping then
		warn("Feral Leap: Already leaping, ignoring start request")
		return
	end
	
	local char = player.Character
	if not char then 
		warn("Feral Leap: No character found")
		return 
	end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then 
		warn("Feral Leap: No HumanoidRootPart found")
		return 
	end
	
	-- Clean up any existing state first (but don't reset isLeaping yet)
	if isLeaping then
		-- Stop any existing leap
		hasStoppedLeap = true
		disconnectLeapConnections()
		
		-- Destroy velocity
		if currentVelocity then
			pcall(function()
				currentVelocity:Destroy()
			end)
			currentVelocity = nil
		end
	end
	
	isLeaping = true
	hasStoppedLeap = false
	leapStartTime = tick()
	
	-- Create BodyVelocity
	local baseDirection = root.CFrame.LookVector
	currentVelocity = Instance.new("BodyVelocity")
	currentVelocity.MaxForce = Vector3.new(1e6, 0, 1e6)
	currentVelocity.Velocity = baseDirection * 170
	currentVelocity.Parent = root
	
	-- Create collision box for reliable collision detection
	collisionBox = Instance.new("Part")
	collisionBox.Name = "FeralLeapCollisionBox"
	collisionBox.Size = Vector3.new(8, 5, 8) -- x (left/right), y (up/down), z (forward/back)	
	collisionBox.Transparency = 1
	collisionBox.CanCollide = false
	collisionBox.CanQuery = false
	collisionBox.CanTouch = true
	collisionBox.Anchored = false
	collisionBox.Massless = true
	collisionBox.Parent = char
	
	-- Position the box with forward offset BEFORE welding
	collisionBox.CFrame = root.CFrame * CFrame.new(0, 0, -4) -- 4 studs forward
	
	-- Weld collision box to HumanoidRootPart with offset
	collisionBoxWeld = Instance.new("WeldConstraint")
	collisionBoxWeld.Part0 = root
	collisionBoxWeld.Part1 = collisionBox
	collisionBoxWeld.Parent = collisionBox
	
	-- Collision detection: stop leap instantly on collision
	collisionConnection = collisionBox.Touched:Connect(function(hit)
		if not isLeaping then return end
		if hit:IsDescendantOf(char) then return end
		stopFeralLeap()
	end)
	
	-- Update direction with WASD
	leapConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if not isLeaping or not currentVelocity or not root then return end
		
		-- Safety timeout check
		local currentTime = tick()
		if currentTime - leapStartTime > MAX_LEAP_DURATION then
			warn("Feral Leap: Maximum duration reached, forcing stop")
			stopFeralLeap()
			return
		end
		
		local moveDir = Vector3.zero
		
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir += root.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir -= root.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir -= root.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir += root.CFrame.RightVector
		end
		
		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
			currentVelocity.Velocity = moveDir * 170
		else
			currentVelocity.Velocity = baseDirection * 170
		end
		
		-- Collision box position is handled by weld constraint
	end)
	
	-- E key to stop leap early (same as activation key)
	local eKeyConnection
	eKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == CONFIG.keybinds.feralleapStop and isLeaping then
			stopFeralLeap()
			if eKeyConnection then
				eKeyConnection:Disconnect()
			end
		end
	end)
end

-- ========================================
-- CAMERA SYSTEM
-- Handles cinematic camera movements for skills/buffs/ultimates
-- ========================================

local currentCameraTween = nil
local cameraSequenceRunning = false
local lastCameraSequenceTime = 0
local CAMERA_SEQUENCE_COOLDOWN = 0.1 -- 100ms cooldown between camera sequences

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
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType]

	-- Play each step in the sequence (exact copy from original MightyBlade.lua)
	for _, step in ipairs(sequence) do
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
	-- Meteor Dive ultimate (from original Meteor Dive.lua)
	meteordive = {
		{cf = CFrame.new(0, 1, -50) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 0, holdTime = 0.2},
		{cf = CFrame.new(0, -1.5, -10) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 1, holdTime = 0.5},
		{cf = CFrame.new(-8, 150, 0) * CFrame.Angles(math.rad(-90), math.rad(-20), 0), tweenTime = 0, holdTime = 6},
		{cf = CFrame.new(-5, 2, -10) * CFrame.Angles(0, math.rad(210), 0), tweenTime = 0, holdTime = 2},
	},
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
	
	BrawlerActions._setInputLocked(true)
	controls:Disable()
end

local function unlockInput()
	if not controls then
		return
	end
	
	BrawlerActions._setInputLocked(false)
	controls:Enable()
end

local function lockMovementOnly()
	if not humanoid then
		return
	end
	
	BrawlerActions._setMovementLocked(true)
	-- Walking speed is now controlled by server
end

local function unlockMovementOnly()
	if not humanoid then
		return
	end
	
	BrawlerActions._setMovementLocked(false)
	-- Walking speed is now controlled by server
end

-- ========================================
-- ACTION HANDLER
-- ========================================

local function useAction(actionName)
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not isWeaponClassMatch() then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Brawler Client] Skill blocked: Player tried to use skill with mismatched weapon.")
			return
		end
	end
	
	-- Use the module to perform the action (handles all validation)
	local success = BrawlerActions.useSkill(actionName)
	
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
	-- Clean up any existing feral leap state first
	cleanupFeralLeapState()
	
	-- Update module state
	BrawlerActions._setTool(weaponTool)
	
	-- Initialize PlayerModule
	initializePlayerModule()
	
	-- Mark as not initialized initially
	isInitialized = false
	
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
			-- data = action name (placeholder for future brawler sequences)
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
		elseif message == "feralleap_start" then
			-- Start feral leap movement control (with safety check)
			startFeralLeap()
		elseif message == "feralleap_stop" then
			-- Stop feral leap movement control (only if still leaping)
			-- This is called by server when animation naturally ends
			if isLeaping then
				-- Don't call stopFeralLeap() here as it would create a loop
				-- Just stop the movement without firing server event
				isLeaping = false
				hasStoppedLeap = true
				disconnectLeapConnections()
				if currentVelocity then
					pcall(function()
						currentVelocity:Destroy()
					end)
					currentVelocity = nil
				end
			end
		elseif message == "enable_trails" then
			-- Only enable trails if brawler weapon is equipped
			if BrawlerActions._getTool() then
				-- data = trail configuration table with trail1-6 settings
				local trailConfig = data
				
				task.spawn(function()
					enableTrailsWithConfig(trailConfig)
				end)
			end
		elseif message == "disable_trails" then
			-- Disable all trails
			task.spawn(function()
				disableTrails()
			end)
		elseif message == "sync_trail_config" then
			-- data = complete trail configuration from server
			-- Store for future use (no immediate action needed)
			-- The config will be used when trails are enabled
		end
	end)
	
	-- Tell server to setup all animations (attack + movement) and attach sword/shield
	remote:FireServer("brawler_attack_setup", weaponTool)
	
	-- Sync all camera speeds with server values
	syncAllCameraSpeeds()
	
	-- Initialize trails (disable by default)
	disableTrails()
	
	-- Initialize system after delay to ensure everything is ready
	task.delay(initializationDelay, function()
		isInitialized = true
	end)
	
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
		
		-- Handle skills (Q, E, X, Z, C)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local actionName = CONFIG.actions[input.KeyCode]
			if actionName then
				useAction(actionName)
				return
			end
			
			-- Handle block (V key)
			if input.KeyCode == CONFIG.keybinds.block then
				BrawlerActions.blockStart()
				return
			end
			
			
			-- Note: Wave is now handled globally by GlobalKeybindManager (L key)
		end
		
		-- Handle mouse clicks (left click attack)
		if input.UserInputType == CONFIG.keybinds.attack then
			BrawlerActions.basicAttack()
		end
	end)
	
	-- Listen for input release (block)
	UserInputService.InputEnded:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.block then
			-- V key block release
			BrawlerActions.blockEnd()
		end
	end)
end

local function onWeaponLost()
	if BrawlerActions._getTool() then
		
		-- Tell server to cleanup all animations and remove sword/shield
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		local weaponTool = BrawlerActions._getTool()
		remote:FireServer("brawler_attack_cleanup", weaponTool)
		
		-- Clear tool reference in module
		BrawlerActions._setTool(nil)
	end
	
	-- Clean up all feral leap state
	cleanupFeralLeapState()
	
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
	
	-- Disable trails when weapon is lost
	disableTrails()
end

local function onCharacterAdded(character)
	-- Update humanoid reference
	humanoid = character:FindFirstChildOfClass("Humanoid")
	
	-- Clean up leap connections if character respawns
	disconnectLeapConnections()
	isLeaping = false
	currentVelocity = nil
	
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
		if desc == BrawlerActions._getTool() then
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

