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

-- Global camera speed configuration (automatically synced with server)
local CAMERA_SPEED_MULTIPLIER = 1 -- Default value, will be updated by server

-- Cooldown tracking for camera sequences
local skillCooldowns = {
	banzai = false,
	bushido = false,
	wakizashi = false,
	kozuki = false,
	zantetsuken = false
}

-- Function to update camera speed (called automatically by server)
local function updateCameraSpeed(newSpeed)
	CAMERA_SPEED_MULTIPLIER = newSpeed
	print("Camera speed updated to:", newSpeed) -- Debug message
end

-- Function to update cooldown status
local function updateCooldownStatus(skillName, isOnCooldown, remainingTime)
	skillCooldowns[skillName] = isOnCooldown
	if isOnCooldown then
		print(skillName .. " is on cooldown for " .. remainingTime .. " seconds")
	else
		print(skillName .. " cooldown ended")
	end
end

-- Configuration
local CONFIG = {
	weaponTag = "samurai_wpn",
	-- Walking speed is now controlled by server
	actions = {
		[Enum.KeyCode.E] = "kozuki",
		[Enum.KeyCode.Q] = "wakizashi",
		[Enum.KeyCode.R] = "banzai",
		[Enum.KeyCode.F] = "bushido",
		[Enum.KeyCode.Z] = "zantetsuken",
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

-- Smoothly moves camera to a position over time (scales with speed multiplier)
local function tweenCameraTo(targetCFrame, tweenDuration)
	-- Scale tween duration with camera speed multiplier
	local scaledDuration = tweenDuration / CAMERA_SPEED_MULTIPLIER
	local tweenInfo = TweenInfo.new(scaledDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	tween:Play()
	tween.Completed:Wait()
end

-- Plays a cinematic camera sequence
local function playCameraSequence(sequence)
	-- Save original camera settings
	local originalCFrame = camera.CFrame
	local originalType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Play each step in the sequence
	for _, step in ipairs(sequence) do
		local targetCFrame = root.CFrame * step.offset * CFrame.Angles(step.rotX or 0, step.rotY or 0, step.rotZ or 0)
		tweenCameraTo(targetCFrame, step.tweenTime)
		-- Scale hold time with camera speed multiplier
		local scaledHoldTime = step.holdTime / CAMERA_SPEED_MULTIPLIER
		task.wait(scaledHoldTime)
	end

	-- Restore original camera
	tweenCameraTo(originalCFrame, 1)
	task.wait(0.5 / CAMERA_SPEED_MULTIPLIER) -- Scale restoration delay
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
	bushido = {
		{offset = CFrame.new(-5, 1.5, -1.5), rotY = math.rad(-80), tweenTime = 1, holdTime = 2.5},
		{offset = CFrame.new(0, 2, -3.5), rotY = math.rad(-180), tweenTime = 0, holdTime = 1.5},
	},
	
	zantetsuken = {
		{offset = CFrame.new(0, 2, 4), rotY = math.rad(0), tweenTime = 0, holdTime = 1},        -- Front view
		{offset = CFrame.new(-5, -0.5, -1.5), rotY = math.rad(-90), tweenTime = 1, holdTime = 2}, -- Left side
		{offset = CFrame.new(8, -0.5, -1.5), rotY = math.rad(90), tweenTime = 0, holdTime = 1},   -- Right side
		{offset = CFrame.new(0, -0.5, 8), rotY = math.rad(0), tweenTime = 0, holdTime = 1},       -- Back view
		{offset = CFrame.new(0, -0.5, -8), rotY = math.rad(-180), tweenTime = 0, holdTime = 1},   -- Behind player
		{offset = CFrame.new(0, 8, 8), rotX = math.rad(-40), rotY = math.rad(0), tweenTime = 0, holdTime = 1}, -- Aerial view
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
			playCameraSequence(CAMERA_SEQUENCES[actionName])
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
	remote.OnClientEvent:Connect(function(message, data, extraData)
		if message == "lock_input" then
			lockInput()
		elseif message == "unlock_input" then
			unlockInput()
		elseif message == "lock_movement" then
			lockMovementOnly()
		elseif message == "unlock_movement" then
			unlockMovementOnly()
		elseif message == "update_animation_speed" then
			updateCameraSpeed(data) -- data contains the new speed value
		elseif message == "cooldown_status" then
			updateCooldownStatus(data, extraData, nil) -- data = skillName, extraData = isOnCooldown, remainingTime not used
		end
	end)
	
	-- Tell server to setup all animations (attack + movement)
	remote:FireServer("normal_attack_setup")
	
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
				remote:FireServer("block_start")
				return
			end
			
			-- Handle jump (Spacebar) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.jump and not movementLocked then
				remote:FireServer("jump_attack")
				return
			end
			
			-- Handle wave (P key) - but not when movement is locked
			if input.KeyCode == CONFIG.keybinds.wave and not movementLocked then
				remote:FireServer("wave")
				return
			end
		end
		
		-- Handle mouse clicks - but not when movement is locked
		if input.UserInputType == CONFIG.keybinds.attack and not movementLocked then
			-- Left click attack
			remote:FireServer("left_click_attack")
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
			remote:FireServer("block_end")
		end
	end)
end

local function onWeaponLost()
	if tool then
		
		-- Tell server to cleanup all animations
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		remote:FireServer("normal_attack_cleanup")
		
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

