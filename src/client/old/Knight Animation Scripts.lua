local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local tool = script.Parent

local sword = tool:FindFirstChild("Handle")
local shield = tool:FindFirstChild("Shield")

-- Animation asset IDs provided by user
local idleAnimId = "rbxassetid://109402075157762"
local runAnimId = "rbxassetid://114926843826062"
local jumpAnimId = "rbxassetid://103828839495945"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://73728189126085"

local swordMotorName = "SwordRightHandMotor"
local shieldMotorName = "ShieldLeftHandMotor"

local character
local humanoid
local animator

local idleTrack, runTrack, jumpTrack, climbTrack
local currentAnimState = nil
local stateConn
local inputBeganConn
local inputEndedConn
local equippedConn
local unequippedConn

local toolEquipped = false

-- Track WASD key states
local movementKeys = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.D] = false,
}

-- Helper to get default hand attachment offsets
local function getHandOffsets(rigType)
	-- Shield rotation: 100 degrees around Y, and move forward on Z axis
	local shieldRotation = CFrame.Angles(0, math.rad(100), 0)
	local shieldForwardOffset = CFrame.new(-0.5, 0, 0) -- Move shield forward by 0.5 studs
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

-- Utility: Set CanCollide for all Parts in Tool
local function setToolCollision(enabled)
	for k, obj in tool:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.CanCollide = false
		end
	end
end

-- Helper: Check if player is on stairs by checking FloorMaterial or touching a part named "Stairs"
local function isOnStairs()
	if not humanoid then return false end
	-- Option 1: Check FloorMaterial for custom stair material (if used)
	-- Option 2: Check if humanoid is standing on a part named "Stairs"
	local floorPart = humanoid.FloorMaterial
	-- If you use custom stair material, check here. Otherwise, use TouchingParts.
	-- We'll use TouchingParts for more reliability.
	if character and character:FindFirstChild("HumanoidRootPart") then
		local root = character.HumanoidRootPart
		local touchingParts = root:GetTouchingParts()
		for k, part in touchingParts do
			if part.Name:lower():find("stair") then
				return true
			end
		end
	end
	return false
end

local function isMoving()
	for key, pressed in movementKeys do
		if pressed then
			return true
		end
	end
	return false
end

local function stopAllTracks()
	if idleTrack then idleTrack:Stop() end
	if runTrack then runTrack:Stop() end
	if jumpTrack then jumpTrack:Stop() end
	if climbTrack then climbTrack:Stop() end
end

local function playTrack(track, stateName)
	if currentAnimState ~= stateName then
		stopAllTracks()
		currentAnimState = stateName
		if track then
			track:Play()
		end
	end
end

local function setupTracks()
	-- Properly create Animation instances and set AnimationId before loading
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = idleAnimId
	idleTrack = animator:LoadAnimation(idleAnim)

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = runAnimId
	runTrack = animator:LoadAnimation(runAnim)

	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = jumpAnimId
	jumpTrack = animator:LoadAnimation(jumpAnim)

	local climbAnim = Instance.new("Animation")
	climbAnim.AnimationId = climbAnimId
	climbTrack = animator:LoadAnimation(climbAnim)
end

-- Helper to update climbing animation speed based on WASD input
local function updateClimbAnimSpeed()
	if climbTrack and humanoid and humanoid:GetState() == Enum.HumanoidStateType.Climbing then
		if isMoving() then
			climbTrack:AdjustSpeed(1)
		else
			climbTrack:AdjustSpeed(0)
		end
	end
end

local function onStateChanged(old, new)
	if not toolEquipped then return end
	if new == Enum.HumanoidStateType.Climbing or isOnStairs() then
		setToolCollision(false)
		stopAllTracks()
		currentAnimState = "Climbing"
		if climbTrack then
			climbTrack:Play()
			updateClimbAnimSpeed()
		end
	elseif old == Enum.HumanoidStateType.Climbing and new ~= Enum.HumanoidStateType.Climbing and not isOnStairs() then
		setToolCollision(true)
		if climbTrack then
			climbTrack:AdjustSpeed(1)
		end
		if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			stopAllTracks()
			currentAnimState = "Jumping"
			if jumpTrack then
				jumpTrack:Play()
			end
		elseif new == Enum.HumanoidStateType.Landed then
			if isMoving() then
				playTrack(runTrack, "Running")
			else
				playTrack(idleTrack, "Idle")
				if runTrack and runTrack.IsPlaying then
					runTrack:Stop()
				end
			end
		elseif new == Enum.HumanoidStateType.Running then
			if isMoving() then
				playTrack(runTrack, "Running")
			else
				playTrack(idleTrack, "Idle")
			end
		else
			playTrack(idleTrack, "Idle")
		end
	else
		if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			setToolCollision(true)
			stopAllTracks()
			currentAnimState = "Jumping"
			if jumpTrack then
				jumpTrack:Play()
			end
		elseif new == Enum.HumanoidStateType.Landed then
			if isMoving() then
				setToolCollision(not isOnStairs())
				playTrack(runTrack, "Running")
			else
				setToolCollision(not isOnStairs())
				playTrack(idleTrack, "Idle")
				if runTrack and runTrack.IsPlaying then
					runTrack:Stop()
				end
			end
		elseif new == Enum.HumanoidStateType.Running then
			setToolCollision(not isOnStairs())
			if isMoving() then
				playTrack(runTrack, "Running")
			else
				playTrack(idleTrack, "Idle")
			end
		else
			setToolCollision(not isOnStairs())
			playTrack(idleTrack, "Idle")
		end
	end
end

local function onMove()
	if not toolEquipped then return end
	local state = humanoid and humanoid:GetState()
	if state == Enum.HumanoidStateType.Climbing or isOnStairs() then
		setToolCollision(false)
		stopAllTracks()
		currentAnimState = "Climbing"
		if climbTrack then
			climbTrack:Play()
			updateClimbAnimSpeed()
		end
		return
	elseif state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
		setToolCollision(true)
		return
	elseif state == Enum.HumanoidStateType.Landed then
		setToolCollision(not isOnStairs())
		if isMoving() then
			playTrack(runTrack, "Running")
		else
			playTrack(idleTrack, "Idle")
			if runTrack and runTrack.IsPlaying then
				runTrack:Stop()
			end
		end
	elseif state == Enum.HumanoidStateType.Running then
		setToolCollision(not isOnStairs())
		if isMoving() then
			playTrack(runTrack, "Running")
		else
			playTrack(idleTrack, "Idle")
		end
	else
		setToolCollision(not isOnStairs())
	end
end

local function onInputBegan(input, gameProcessed)
	if movementKeys[input.KeyCode] ~= nil then
		movementKeys[input.KeyCode] = true
		onMove()
		updateClimbAnimSpeed()
	end
end

local function onInputEnded(input, gameProcessed)
	if movementKeys[input.KeyCode] ~= nil then
		movementKeys[input.KeyCode] = false
		onMove()
		updateClimbAnimSpeed()
	end
end

local function disconnectAll()
	if stateConn then stateConn:Disconnect() stateConn = nil end
	if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
	if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
	stopAllTracks()
	currentAnimState = nil
	setToolCollision(true)
end

local function playInstantAnimation()
	if not toolEquipped or not humanoid then return end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Climbing or isOnStairs() then
		setToolCollision(false)
		stopAllTracks()
		currentAnimState = "Climbing"
		if climbTrack then
			climbTrack:Play()
			updateClimbAnimSpeed()
		end
	elseif state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
		setToolCollision(true)
		stopAllTracks()
		currentAnimState = "Jumping"
		if jumpTrack then
			jumpTrack:Play()
		end
	elseif isMoving() then
		setToolCollision(not isOnStairs())
		playTrack(runTrack, "Running")
	else
		setToolCollision(not isOnStairs())
		playTrack(idleTrack, "Idle")
	end
end

local function onCharacterAdded(char)
	character = char
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	setupTracks()

	disconnectAll()

	if toolEquipped then
		stateConn = humanoid.StateChanged:Connect(onStateChanged)
		inputBeganConn = UserInputService.InputBegan:Connect(onInputBegan)
		inputEndedConn = UserInputService.InputEnded:Connect(onInputEnded)
		playInstantAnimation()
	end
end

local function attachSwordAndShield()
	if not character or not humanoid then return end

	-- Make sure sword and shield are visible
	if sword then sword.Transparency = 0 end
	if shield then shield.Transparency = 0 end

	local offsets = getHandOffsets(humanoid.RigType)

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		attachPartToLimb(sword, "RightHand", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		attachPartToLimb(shield, "LeftHand", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	else
		attachPartToLimb(sword, "Right Arm", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		attachPartToLimb(shield, "Left Arm", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	end
end

local function removeSwordAndShield()
	if not character or not humanoid then return end

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

	if sword then sword.Transparency = 1 end
	if shield then shield.Transparency = 1 end
end

local function onEquipped()
	toolEquipped = true
	if player.Character then
		onCharacterAdded(player.Character)
		attachSwordAndShield()
	end
end

local function onUnequipped()
	toolEquipped = false
	disconnectAll()
	removeSwordAndShield()
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)