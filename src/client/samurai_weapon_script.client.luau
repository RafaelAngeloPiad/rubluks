local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.scan_for_weapon_tag)

-- Replace these asset IDs with your actual animation asset IDs
local idleAnimId = "rbxassetid://132322083369838"
local runAnimId = "rbxassetid://80487023516839"
local jumpAnimId = "rbxassetid://121459102540074"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://91967450916175"

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
	if player.Character then
		onCharacterAdded(state, player.Character)
	end
end

local function onUnequipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	disconnectAll(state)
end

local function setupTool(tool, state)
	print("[SAMURAI WEAPON] Setting up tool: " .. tool.Name)
	
	-- Listen for equipped/unequipped
	state.equippedConn = tool.Equipped:Connect(function()
		print("[SAMURAI WEAPON] Tool equipped: " .. tool.Name)
		onEquipped(tool)
	end)
	state.unequippedConn = tool.Unequipped:Connect(function()
		print("[SAMURAI WEAPON] Tool unequipped: " .. tool.Name)
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
print("[SAMURAI WEAPON] Initializing weapon scanner...")
weaponScanner = WeaponScanner.new("samurai_weapon", setupTool, cleanupTool)
print("[SAMURAI WEAPON] Weapon scanner initialized!")

