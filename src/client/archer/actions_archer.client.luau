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
	normalAttack = 1.0,    -- Single normal attack (replaces combo1)
	moveAttack = 1.0,
	jumpAttack = 1.0,
	block = 1.0,
	wave = 1.0,
	piercingShot = 1.0,
	powerShot = 1.0,
	hunterInstinct = 1.0,
	hunterMark = 1.0,
	starfall = 1.0
}

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
	if isOnCooldown then
		local timeText = remainingTime and tostring(remainingTime) or "unknown"
	end
end

-- Configuration
local CONFIG = {
	weaponTag = "archer_wpn",
	-- Walking speed is now controlled by server
	actions = {
		[Enum.KeyCode.Q] = "piercingShot",
		[Enum.KeyCode.E] = "powerShot",
		[Enum.KeyCode.R] = "hunterInstinct",
		[Enum.KeyCode.F] = "hunterMark",
		[Enum.KeyCode.Z] = "starfall",
	},
	-- Custom keybinds for basic actions
	keybinds = {
		attack = Enum.UserInputType.MouseButton1, -- Left click
		block = Enum.KeyCode.LeftShift, -- Ctrl key
		jump = Enum.KeyCode.Space, -- Spacebar
		wave = Enum.KeyCode.T, -- T key for wave emote
	}
}

-- ========================================
-- CAMERA SYSTEM
-- Handles cinematic camera movements for skills/buffs/ultimates
-- ========================================

-- Smoothly moves camera to a position over time (scales with action-specific speed multiplier)
local function tweenCameraTo(targetCFrame, tweenDuration, actionType)
	-- Use specific action speed or fallback to current action type
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType] or 1.0
	local scaledDuration = tweenDuration / speedMultiplier
	local tweenInfo = TweenInfo.new(scaledDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	tween:Play()
	tween.Completed:Wait()
end

-- Plays a cinematic camera sequence
local function playCameraSequence(sequence, actionType)
	-- Save original camera settings
	local originalCFrame = camera.CFrame
	local originalType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Get speed multiplier for this action
	local speedMultiplier = CAMERA_SPEED_MULTIPLIERS[actionType] or CAMERA_SPEED_MULTIPLIERS[currentActionType] or 1.0

	-- Play each step in the sequence
	for _, step in ipairs(sequence) do
		local targetCFrame = root.CFrame * step.offset * CFrame.Angles(step.rotX or 0, step.rotY or 0, step.rotZ or 0)
		tweenCameraTo(targetCFrame, step.tweenTime, actionType)
		-- Scale hold time with action-specific camera speed multiplier
		local scaledHoldTime = step.holdTime / speedMultiplier
		task.wait(scaledHoldTime)
	end

	-- Restore original camera
	tweenCameraTo(originalCFrame, 1, actionType)
	task.wait(0.5 / speedMultiplier) -- Scale restoration delay
	camera.CameraType = originalType
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
	-- Starfall camera sequence (from original Starfall.lua)
	starfall = {
		{offset = CFrame.new(0, 6, -10), rotY = math.rad(180), tweenTime = 0, holdTime = 1},        -- Front view, elevated
		{offset = CFrame.new(-8, 6, -1.5), rotY = math.rad(-90), tweenTime = 1, holdTime = 2},      -- Left side, elevated
		{offset = CFrame.new(0, 100, 100), rotX = math.rad(-40), rotY = math.rad(0), tweenTime = 0, holdTime = 7}, -- Aerial view
	},
	-- HunterMark camera sequence (from original HunterMark.lua)
	hunterMark = {
		{offset = CFrame.new(-5, 1.5, -20), rotY = math.rad(-150), tweenTime = 0, holdTime = 1.3},  -- Far left view
		{offset = CFrame.new(-2, 2, -3.5), rotY = math.rad(-150), tweenTime = 0.3, holdTime = 1.5}, -- Close left view
	},
	-- Archer camera sequences (placeholder for future archer skills)
	-- hunterInstinct = {
	-- 	{offset = CFrame.new(-5, 1.5, -1.5), rotY = math.rad(-80), tweenTime = 1, holdTime = 2.5},
	-- 	{offset = CFrame.new(0, 2, -3.5), rotY = math.rad(-180), tweenTime = 0, holdTime = 1.5},
	-- },
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
	
	-- Check if movement is locked for non-skill actions (archer doesn't have skills yet)
	if movementLocked then
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
			-- data = action name (e.g., "starfall")
			if CAMERA_SEQUENCES[data] and not skillCooldowns[data] then
				task.spawn(function()
					playCameraSequence(CAMERA_SEQUENCES[data], data)
				end)
			end
		end
	end)
	
	-- Tell server to setup all animations (attack + movement)
	remote:FireServer("archer_attack_setup")
	
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
				remote:FireServer("archer_block_start")
				return
			end
			
			-- Handle jump (Spacebar) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.jump and not movementLocked then
				remote:FireServer("archer_jump_attack")
				return
			end
			
			-- Handle wave (P key) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.wave and not movementLocked then
				remote:FireServer("archer_wave")
				return
			end
		end
		
		-- Handle mouse clicks - but not when movement is locked
		if input.UserInputType == CONFIG.keybinds.attack and not movementLocked then
			-- Left click attack
			remote:FireServer("archer_left_click_attack")
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
			remote:FireServer("archer_block_end")
		end
	end)
end

local function onWeaponLost()
	if tool then
		
		-- Tell server to cleanup all animations
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		remote:FireServer("archer_attack_cleanup")
		
		tool = nil
	end
	
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

