-- ========================================
-- SAMURAI ACTIONS CLIENT (UNIFIED)
-- Handles skills, buffs, and ultimate for Samurai class
-- Skills: Kozuki (E), Wakizashi (Q)
-- Buffs: Banzai (R), Bushido (F)
-- Ultimate: Zantetsuken (Z)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local tool = nil
local inputConnection = nil
local inputLocked = false -- Flag to control input registration
local movementLocked = false -- Flag to control movement only (for skills like wakizashi/kozuki)
local playerModule = nil
local controls = nil
local humanoid = nil
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

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
	kozuki = 1.0,
	wakizashi = 1.0,
	banzai = 1.0,
	bushido = 1.0,
	zantetsuken = 1.0
}

-- Current action type for camera speed reference
local currentActionType = "idle"

-- Cooldown tracking for camera sequences
local skillCooldowns = {
	banzai = false,
	bushido = false,
	wakizashi = false,
	kozuki = false,
	zantetsuken = false
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
	if isOnCooldown then
		local timeText = remainingTime and tostring(remainingTime) or "unknown"
	end
end

-- Configuration
local CONFIG = {
	weaponTag = "samurai_wpn",
	-- Walking speed is now controlled by server
	actions = {
		[Enum.KeyCode.E] = "kozuki",
		[Enum.KeyCode.Q] = "wakizashi",
		[Enum.KeyCode.X] = "banzai",
		[Enum.KeyCode.Z] = "bushido",
		[Enum.KeyCode.C] = "zantetsuken",
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = Enum.UserInputType.MouseButton1, -- Left click
		block = Enum.KeyCode.V,
		jump = Enum.KeyCode.Space, -- Spacebar
		wave = Enum.KeyCode.T, -- T key for wave emote
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

	-- Play each step in the sequence (exact copy from original Zantetsuken.lua)
	for _, step in ipairs(sequence) do
		-- Handle both old format (offset + rotX/Y/Z) and new format (cf)
		local targetCFrame
		if step.cf then
			-- New format: use pre-constructed CFrame (like original Zantetsuken.lua)
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
	-- Buff (exact copy from original Bushido.lua format)
	bushido = {
		{cf = CFrame.new(-5, 1.5, -1.5) * CFrame.Angles(0, math.rad(-80), 0), tweenTime = 1, holdTime = 2.5},
		{cf = CFrame.new(0, 2, -3.5) * CFrame.Angles(0, math.rad(-180), 0), tweenTime = 0, holdTime = 1.5},
	},
	-- Ultimate (exact copy from original Zantetsuken.lua format)
	zantetsuken = {
		{cf = CFrame.new(0, 2, 4) * CFrame.Angles(0, math.rad(0), 0), tweenTime = 0, holdTime = 1},        -- Front view
		{cf = CFrame.new(-5, -0.5, -1.5) * CFrame.Angles(0, math.rad(-90), 0), tweenTime = 1, holdTime = 2}, -- Left side
		{cf = CFrame.new(8, -0.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), tweenTime = 0, holdTime = 1},   -- Right side
		{cf = CFrame.new(0, -0.5, 8) * CFrame.Angles(0, math.rad(0), 0), tweenTime = 0, holdTime = 1},       -- Back view
		{cf = CFrame.new(0, -0.5, -8) * CFrame.Angles(0, math.rad(-180), 0), tweenTime = 0, holdTime = 1},   -- Behind player
		{cf = CFrame.new(0, 8, 8) * CFrame.Angles(math.rad(-40), math.rad(0), 0), tweenTime = 0, holdTime = 1}, -- Aerial view
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
	
	inputLocked = true
	controls:Disable()
end

local function unlockInput()
	if not controls then
		return
	end
	
	inputLocked = false
	controls:Enable()
end

local function lockMovementOnly()
	if not humanoid then
		return
	end
	
	movementLocked = true
	-- Walking speed is now controlled by server
end

local function unlockMovementOnly()
	if not humanoid then
		return
	end
	
	movementLocked = false
	-- Walking speed is now controlled by server
end

-- ========================================
-- ACTION HANDLER
-- ========================================

local function useAction(actionName)
	-- Check if input is locked (but allow movement-only locked actions)
	if inputLocked then
		return
	end
	
	-- Check if movement is locked for non-skill actions
	if movementLocked and actionName ~= "wakizashi" and actionName ~= "kozuki" then
		return
	end
	
	-- Validate tool is equipped
	if not tool or tool.Parent ~= player.Character then
		return
	end
	
	-- Tell server to handle VFX and hitboxes
	remote:FireServer(actionName)
	
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
	tool = weaponTool
	
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
			-- data = action name (e.g., "bushido", "zantetsuken")
			-- Server-triggered sequences should always run (server handles cooldown logic)
			if data == "bushido" or data == "zantetsuken" then
				task.spawn(function()
					-- Use the predefined sequence from CAMERA_SEQUENCES
					local sequence = CAMERA_SEQUENCES[data]
					if sequence then
						playCameraSequence(sequence, data)
					end
				end)
			end
		end
	end)
	
	-- Tell server to setup all animations (attack + movement)
	remote:FireServer("samurai_attack_setup")
	
	-- Sync all camera speeds with server values
	syncAllCameraSpeeds()
	
	-- Clean up old connections
	if inputConnection then
		inputConnection:Disconnect()
	end
	
	-- Listen for all input (skills, attacks, block, jump)
	inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		-- Check if input is locked
		if inputLocked then
			return
		end
		
		-- Allow camera movement (mouse movement) even when movement is locked
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			return -- Allow camera movement
		end
		
		-- Handle skills (E, Q, R, F, Z)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local actionName = CONFIG.actions[input.KeyCode]
			if actionName then
				useAction(actionName)
				return
			end
			
			-- Handle block (Ctrl) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.block and not movementLocked then
				remote:FireServer("samurai_block_start")
				return
			end
			
			-- Handle jump (Spacebar) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.jump and not movementLocked then
				remote:FireServer("samurai_jump_attack")
				return
			end
			
			-- Handle wave (P key) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.wave and not movementLocked then
				remote:FireServer("samurai_wave")
				return
			end
		end
		
		-- Handle mouse clicks - but not when movement is locked
		if input.UserInputType == CONFIG.keybinds.attack and not movementLocked then
			-- Left click attack
			remote:FireServer("samurai_left_click_attack")
		end
	end)
	
	-- Listen for input release (block)
	UserInputService.InputEnded:Connect(function(input, isProcessed)
		if isProcessed then return end
		
		-- Check if input is locked
		if inputLocked then
			return
		end
		
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.keybinds.block and not movementLocked then
			-- Block release
			remote:FireServer("samurai_block_end")
		end
	end)
end

local function onWeaponLost()
	if tool then
		
		-- Tell server to cleanup all animations
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		remote:FireServer("samurai_attack_cleanup")
		
		tool = nil
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
		if desc == tool then
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

