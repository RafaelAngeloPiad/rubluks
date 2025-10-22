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

-- Import the action module for shared logic
local BrawlerActions = require(script.Parent.BrawlerActionModule)

-- Camera speed configuration (separate for each action type)
local CAMERA_SPEED_MULTIPLIERS = {
	idle = 1.0,
	run = 1.0,
	jump = 1.0,
	combo1 = 1.0,
	combo2 = 1.0,
	moveAttack = 1.0,
	jumpAttack = 1.0,
	block = 1.0,
	wave = 1.0,
	-- Skills (placeholder for future)
	feralleap = 1.0,
	brawlersroar = 1.0,
	-- Buffs (placeholder for future)
	bloodthirst = 1.0,
	lastchance = 1.0,
	-- Ultimate (placeholder for future)
	meteordive = 1.0
}

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
		local timeText = remainingTime and tostring(remainingTime) or "unknown"
	end
end

-- Configuration (moved up to be accessible by feral leap functions)
local CONFIG = {
	weaponTag = "brawler_wpn",
	-- Walking speed is now controlled by server
	actions = {
		[Enum.KeyCode.Q] = "brawlersroar",   -- Skill 1
		[Enum.KeyCode.E] = "feralleap",      -- Skill 2
		[Enum.KeyCode.X] = "bloodthirst",    -- Buff 1
		[Enum.KeyCode.C] = "lastchance",     -- Buff 2
		[Enum.KeyCode.Z] = "meteordive",     -- Ultimate
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = Enum.UserInputType.MouseButton1, -- Left click
		block = Enum.KeyCode.V,  -- V key for blocking (same as knight/samurai)
		jump = Enum.KeyCode.Space, -- Spacebar
		feralleapStop = Enum.KeyCode.E, -- E key to stop feral leap early (same as activation)
		-- Note: Wave is now a global keybind (L key) - handled by GlobalKeybindManager
	}
}

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

local function stopFeralLeap()
	if not isLeaping then return end
	
	-- Debug info
	local leapDuration = tick() - leapStartTime
	
	isLeaping = false
	
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
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	isLeaping = true
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
	collisionBox.Size = Vector3.new(6, 5, 8) -- x (left/right), y (up/down), z (forward/back)	
	collisionBox.Transparency = 0
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
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType] or 1.0
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
	-- Use the module to perform the action (handles all validation)
	local success = BrawlerActions.useSkill(actionName)
	
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
	BrawlerActions._setTool(weaponTool)
	
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
			-- data = action name (placeholder for future brawler sequences)
			-- Server-triggered sequences should always run (server handles cooldown logic)
			task.spawn(function()
				-- Use the predefined sequence from CAMERA_SEQUENCES
				local sequence = CAMERA_SEQUENCES[data]
				if sequence then
					playCameraSequence(sequence, data)
				end
			end)
		elseif message == "feralleap_start" then
			-- Start feral leap movement control
			startFeralLeap()
		elseif message == "feralleap_stop" then
			-- Stop feral leap movement control
			stopFeralLeap()
		end
	end)
	
	-- Tell server to setup all animations (attack + movement) and attach sword/shield
	remote:FireServer("brawler_attack_setup", weaponTool)
	
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
			
			-- Handle jump (Spacebar)
			if input.KeyCode == CONFIG.keybinds.jump then
				BrawlerActions.jumpAttack()
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
	
	-- Stop feral leap if active
	if isLeaping then
		stopFeralLeap()
	end
	
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

