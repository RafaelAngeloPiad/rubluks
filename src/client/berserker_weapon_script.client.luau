local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.scan_for_weapon_tag)

-- Berserker weapon animation IDs (from old working script)
local idleAnimId = "rbxassetid://131906517756576"
local runAnimId = "rbxassetid://127835518362781"
local jumpAnimId = "rbxassetid://87006823550715"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://111950022379992"

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

local function isMoving()
	for key, pressed in movementKeys do
		if pressed then
			return true
		end
	end
	return false
end

local function stopAllTracks(state)
	if state.idleTrack then state.idleTrack:Stop() end
	if state.runTrack then state.runTrack:Stop() end
	if state.jumpTrack then state.jumpTrack:Stop() end
	if state.climbTrack then state.climbTrack:Stop() end
end

local function playTrack(state, track, stateName)
	if state.currentAnimState ~= stateName then
		stopAllTracks(state)
		state.currentAnimState = stateName
		if track then
			track:Play()
		end
	end
end

local function setupTracks(state)
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = idleAnimId
	state.idleTrack = state.animator:LoadAnimation(idleAnim)

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = runAnimId
	state.runTrack = state.animator:LoadAnimation(runAnim)

	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = jumpAnimId
	state.jumpTrack = state.animator:LoadAnimation(jumpAnim)

	local climbAnim = Instance.new("Animation")
	climbAnim.AnimationId = climbAnimId
	state.climbTrack = state.animator:LoadAnimation(climbAnim)
end

local function updateClimbAnimSpeed(state)
	if state.climbTrack and state.humanoid and state.humanoid:GetState() == Enum.HumanoidStateType.Climbing then
		if isMoving() then
			state.climbTrack:AdjustSpeed(1)
		else
			state.climbTrack:AdjustSpeed(0)
		end
	end
end

local function onStateChanged(state, old, new)
	if not state.toolEquipped then return end
	if new == Enum.HumanoidStateType.Climbing then
		stopAllTracks(state)
		state.currentAnimState = "Climbing"
		if state.climbTrack then
			state.climbTrack:Play()
			updateClimbAnimSpeed(state)
		end
	elseif old == Enum.HumanoidStateType.Climbing and new ~= Enum.HumanoidStateType.Climbing then
		if state.climbTrack then
			state.climbTrack:AdjustSpeed(1)
		end
		if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			stopAllTracks(state)
			state.currentAnimState = "Jumping"
			if state.jumpTrack then
				state.jumpTrack:Play()
			end
		elseif new == Enum.HumanoidStateType.Landed then
			if isMoving() then
				playTrack(state, state.runTrack, "Running")
			else
				playTrack(state, state.idleTrack, "Idle")
				if state.runTrack and state.runTrack.IsPlaying then
					state.runTrack:Stop()
				end
			end
		elseif new == Enum.HumanoidStateType.Running then
			if isMoving() then
				playTrack(state, state.runTrack, "Running")
			else
				playTrack(state, state.idleTrack, "Idle")
			end
		else
			playTrack(state, state.idleTrack, "Idle")
		end
	else
		if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			stopAllTracks(state)
			state.currentAnimState = "Jumping"
			if state.jumpTrack then
				state.jumpTrack:Play()
			end
		elseif new == Enum.HumanoidStateType.Landed then
			if isMoving() then
				playTrack(state, state.runTrack, "Running")
			else
				playTrack(state, state.idleTrack, "Idle")
				if state.runTrack and state.runTrack.IsPlaying then
					state.runTrack:Stop()
				end
			end
		elseif new == Enum.HumanoidStateType.Running then
			if isMoving() then
				playTrack(state, state.runTrack, "Running")
			else
				playTrack(state, state.idleTrack, "Idle")
			end
		else
			playTrack(state, state.idleTrack, "Idle")
		end
	end
end

local function onMove(state)
	if not state.toolEquipped then return end
	local humanoid = state.humanoid
	if not humanoid then return end
	local s = humanoid:GetState()
	if s == Enum.HumanoidStateType.Climbing then
		stopAllTracks(state)
		state.currentAnimState = "Climbing"
		if state.climbTrack then
			state.climbTrack:Play()
			updateClimbAnimSpeed(state)
		end
		return
	elseif s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall then
		return
	elseif s == Enum.HumanoidStateType.Landed then
		if isMoving() then
			playTrack(state, state.runTrack, "Running")
		else
			playTrack(state, state.idleTrack, "Idle")
			if state.runTrack and state.runTrack.IsPlaying then
				state.runTrack:Stop()
			end
		end
	elseif s == Enum.HumanoidStateType.Running then
		if isMoving() then
			playTrack(state, state.runTrack, "Running")
		else
			playTrack(state, state.idleTrack, "Idle")
		end
	else
		-- Default
	end
end

local function onInputBegan(state, input, gameProcessed)
	if movementKeys[input.KeyCode] ~= nil then
		movementKeys[input.KeyCode] = true
		onMove(state)
		updateClimbAnimSpeed(state)
	end
end

local function onInputEnded(state, input, gameProcessed)
	if movementKeys[input.KeyCode] ~= nil then
		movementKeys[input.KeyCode] = false
		onMove(state)
		updateClimbAnimSpeed(state)
	end
end

local function disconnectAll(state)
	if state.stateConn then state.stateConn:Disconnect() state.stateConn = nil end
	if state.inputBeganConn then state.inputBeganConn:Disconnect() state.inputBeganConn = nil end
	if state.inputEndedConn then state.inputEndedConn:Disconnect() state.inputEndedConn = nil end
	stopAllTracks(state)
	state.currentAnimState = nil
end

local function playInstantAnimation(state)
	if not state.toolEquipped or not state.humanoid then return end
	local s = state.humanoid:GetState()
	if s == Enum.HumanoidStateType.Climbing then
		stopAllTracks(state)
		state.currentAnimState = "Climbing"
		if state.climbTrack then
			state.climbTrack:Play()
			updateClimbAnimSpeed(state)
		end
	elseif s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall then
		stopAllTracks(state)
		state.currentAnimState = "Jumping"
		if state.jumpTrack then
			state.jumpTrack:Play()
		end
	elseif isMoving() then
		playTrack(state, state.runTrack, "Running")
	else
		playTrack(state, state.idleTrack, "Idle")
	end
end

-- ========================================
-- SHIELD HANDLING FUNCTIONS
-- ========================================

-- Helper to get default hand attachment offsets
local function getHandOffsets(rigType)
	-- Shield rotation: 100 degrees around Y, and move forward on Z axis
	local shieldRotation = CFrame.Angles(0, math.rad(100), 0)
	local shieldForwardOffset = CFrame.new(0, 0, 0) -- Move shield forward by 0.5 studs
	if rigType == Enum.HumanoidRigType.R15 then
		-- R15 default hand offsets
		return {
			swordC0 = CFrame.new(0, 0, 0),
			swordC1 = CFrame.new(0, 0, 0),
			shieldC0 = shieldForwardOffset * shieldRotation,
			shieldC1 = CFrame.new(0, 0, 0),
		}
	else
		-- R6 default arm offsets
		return {
			swordC0 = CFrame.new(0, -1, 0),
			swordC1 = CFrame.new(0, 0, 0),
			shieldC0 = CFrame.new(0, -1, 0) * shieldForwardOffset * shieldRotation,
			shieldC1 = CFrame.new(0, 0, 0),
		}
	end
end

local function attachPartToLimb(part, limbName, motorName, character, c0, c1)
	local limb = character:FindFirstChild(limbName)
	if not limb or not part then return end

	-- Remove previous Motor6D if exists
	for k, v in limb:GetChildren() do
		if v:IsA("Motor6D") and v.Name == motorName then
			v:Destroy()
		end
	end

	local motor = Instance.new("Motor6D")
	motor.Name = motorName
	motor.Part0 = limb
	motor.Part1 = part
	motor.Parent = limb
	motor.C0 = c0 or CFrame.new(0, 0, 0)
	motor.C1 = c1 or CFrame.new(0, 0, 0)
end

local function detectSwordAndShield(tool)
	print("[BERSERKER WEAPON] Detecting sword and shield in tool: " .. tool.Name)
	
	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")
	
	if sword then
		print("[BERSERKER WEAPON] Found sword (Handle): " .. sword.Name)
	else
		print("[BERSERKER WEAPON] WARNING: No Handle found in tool!")
	end
	
	if shield then
		print("[BERSERKER WEAPON] Found shield: " .. shield.Name)
	else
		print("[BERSERKER WEAPON] WARNING: No Shield found in tool!")
	end
	
	return sword ~= nil and shield ~= nil
end

local function attachSwordAndShield(tool, character, humanoid)
	if not character or not humanoid then return end
	print("[BERSERKER WEAPON] Attaching sword and shield to character")

	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")
	
	if not sword or not shield then return end

	-- Make sure sword and shield are visible
	sword.Transparency = 0
	shield.Transparency = 0

	local offsets = getHandOffsets(humanoid.RigType)
	local swordMotorName = "SwordRightHandMotor"
	local shieldMotorName = "ShieldLeftHandMotor"

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		attachPartToLimb(sword, "RightHand", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		attachPartToLimb(shield, "LeftHand", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	else
		attachPartToLimb(sword, "Right Arm", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		attachPartToLimb(shield, "Left Arm", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	end
end

local function removeSwordAndShield(tool, character, humanoid)
	if not character or not humanoid then return end
	print("[BERSERKER WEAPON] Removing sword and shield from character")

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
	if not state.humanoid then return end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	setupTracks(state)
	disconnectAll(state)

	if state.toolEquipped then
		-- Detect and attach sword and shield
		if state.tool and detectSwordAndShield(state.tool) then
			attachSwordAndShield(state.tool, char, state.humanoid)
		end
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			onStateChanged(state, old, new)
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		playInstantAnimation(state)
	end
end

local function onEquipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = true
	state.tool = tool
	
	-- Detect sword and shield
	detectSwordAndShield(tool)
	
	if player.Character then
		onCharacterAdded(state, player.Character)
	end
end

local function onUnequipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Remove sword and shield
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		removeSwordAndShield(tool, player.Character, player.Character:FindFirstChildOfClass("Humanoid"))
	end
	
	disconnectAll(state)
	state.tool = nil
end

local function setupTool(tool, state)
	print("[BERSERKER WEAPON] Setting up tool: " .. tool.Name)
	
	-- Listen for equipped/unequipped
	state.equippedConn = tool.Equipped:Connect(function()
		print("[BERSERKER WEAPON] Tool equipped: " .. tool.Name)
		onEquipped(tool)
	end)
	state.unequippedConn = tool.Unequipped:Connect(function()
		print("[BERSERKER WEAPON] Tool unequipped: " .. tool.Name)
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
	if state.equippedConn then state.equippedConn:Disconnect() end
	if state.unequippedConn then state.unequippedConn:Disconnect() end
	if state.charConn then state.charConn:Disconnect() end
	disconnectAll(state)
end

-- Initialize weapon scanner
print("[BERSERKER WEAPON] Initializing weapon scanner...")
weaponScanner = WeaponScanner.new("berserker_weapon", setupTool, cleanupTool)
print("[BERSERKER WEAPON] Weapon scanner initialized!")