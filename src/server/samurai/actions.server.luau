-- ========================================
-- NORMAL ATTACKS SERVER
-- Handles basic attack animations and mechanics
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Store player attack data
local playerAttackData = {}

-- ========================================
-- ATTACK ANIMATION SETUP
-- ========================================

local function setupAttackAnimations(player)
	local character = player.Character
	if not character then return end
	
	local hum = character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local root = character:FindFirstChild("HumanoidRootPart")
	
	if not animator then return end
	
	-- Attack Animations
	local anim1 = Instance.new("Animation")
	anim1.AnimationId = "rbxassetid://106425822034811"
	local animTrack1 = animator:LoadAnimation(anim1)

	local anim2 = Instance.new("Animation")
	anim2.AnimationId = "rbxassetid://82347640503852"
	local animTrack2 = animator:LoadAnimation(anim2)

	local anim3 = Instance.new("Animation")
	anim3.AnimationId = "rbxassetid://138494804545108"
	local animTrack3 = animator:LoadAnimation(anim3)

	-- Jump Attack Animation
	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = "rbxassetid://92927046911901"
	local jumpTrack = animator:LoadAnimation(jumpAnim)
	jumpTrack.Priority = Enum.AnimationPriority.Action

	-- Move Attack Animation
	local moveSlashAnim = Instance.new("Animation")
	moveSlashAnim.AnimationId = "rbxassetid://106133804561379"
	local moveSlashTrack = animator:LoadAnimation(moveSlashAnim)

	-- Block Animation
	local blockAnim = Instance.new("Animation")
	blockAnim.AnimationId = "rbxassetid://116101111905611"
	local blockTrack = animator:LoadAnimation(blockAnim)
	blockTrack.Priority = Enum.AnimationPriority.Action

	-- Wave Emote Animation
	local waveAnim = Instance.new("Animation")
	waveAnim.AnimationId = "rbxassetid://507770239"
	local waveTrack = animator:LoadAnimation(waveAnim)
	waveTrack.Looped = false
	waveTrack.Priority = Enum.AnimationPriority.Action

	-- Movement Animations
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = "rbxassetid://132322083369838"
	local idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Looped = true
	idleTrack.Priority = Enum.AnimationPriority.Idle

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = "rbxassetid://112708480600525"
	local runTrack = animator:LoadAnimation(runAnim)
	runTrack.Looped = true
	runTrack.Priority = Enum.AnimationPriority.Movement

	-- Store player data
	playerAttackData[player] = {
		animTrack1 = animTrack1,
		animTrack2 = animTrack2,
		animTrack3 = animTrack3,
		jumpTrack = jumpTrack,
		moveSlashTrack = moveSlashTrack,
		blockTrack = blockTrack,
		waveTrack = waveTrack,
		idleTrack = idleTrack,
		runTrack = runTrack,
		clickCount = 0,
		isAttacking = false,
		isJumping = false,
		isBlocking = false,
		originalWalkSpeed = hum.WalkSpeed
	}
	
	-- Start with idle animation
	idleTrack:Play()
	
	-- Movement animation handling
	hum.Running:Connect(function(speed)
		local data = playerAttackData[player]
		if not data then return end
		
		if speed > 1 then -- threshold for running
			if data.idleTrack.IsPlaying then data.idleTrack:Stop() end
			if not data.runTrack.IsPlaying then data.runTrack:Play() end
		else
			if data.runTrack.IsPlaying then data.runTrack:Stop() end
			if not data.idleTrack.IsPlaying then data.idleTrack:Play() end
		end
	end)
	
	-- Detect Jump state
	hum.StateChanged:Connect(function(_, newState)
		local data = playerAttackData[player]
		if not data then return end
		
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			data.isJumping = true
			print("[Actions] Player", player.Name, "jump state changed to:", newState, "- isJumping set to true")
		elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
			data.isJumping = false
			print("[Actions] Player", player.Name, "jump state changed to:", newState, "- isJumping set to false")
			if data.jumpTrack.IsPlaying then
				data.jumpTrack:Stop()
			end
		end
	end)
	
	-- Setup move attack dash effect
	moveSlashTrack:GetMarkerReachedSignal("DashAttack"):Connect(function()
		if root then
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(200000, 0, 200000)
			bodyVelocity.Velocity = root.CFrame.LookVector * 50
			bodyVelocity.Parent = root
			Debris:AddItem(bodyVelocity, 0.2)
		end
	end)
	
end

local function cleanupAttackAnimations(player)
	local data = playerAttackData[player]
	if not data then return end
	
	-- Stop all animations
	if data.animTrack1 then data.animTrack1:Stop() end
	if data.animTrack2 then data.animTrack2:Stop() end
	if data.animTrack3 then data.animTrack3:Stop() end
	if data.jumpTrack then data.jumpTrack:Stop() end
	if data.moveSlashTrack then data.moveSlashTrack:Stop() end
	if data.blockTrack then data.blockTrack:Stop() end
	if data.waveTrack then data.waveTrack:Stop() end
	if data.idleTrack then data.idleTrack:Stop() end
	if data.runTrack then data.runTrack:Stop() end
	
	-- Reset walk speed
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = data.originalWalkSpeed
		end
	end
	
	playerAttackData[player] = nil
end

-- ========================================
-- ATTACK HANDLERS
-- ========================================

local function handleNormalAttack(player)
	local data = playerAttackData[player]
	if not data then return end
	
	if data.isAttacking or data.isBlocking then 
		print("[Actions] Attack blocked - already performing action")
		return 
	end
	
	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	local isMoving = hum.MoveDirection.Magnitude > 0
	local isJumping = data.isJumping
	
	data.isAttacking = true
	
	if isJumping then
		-- Jump attack - separate attack that resets combo (priority over movement)
		data.clickCount = 0 -- Reset combo when doing jump attack
		data.jumpTrack:Play()
		data.jumpTrack.Stopped:Once(function()
			data.isAttacking = false
		end)
		
	elseif isMoving then
		-- Move attack - separate attack that resets combo (only when on ground)
		data.clickCount = 0 -- Reset combo when doing move attack
		data.moveSlashTrack:Play()
		data.moveSlashTrack.Stopped:Once(function()
			data.isAttacking = false
		end)
		
	else
		-- Normal ground combo (standing still)
		data.clickCount += 1
		
		if data.clickCount == 1 then
			data.animTrack1:Play()
			data.animTrack1.Stopped:Once(function() 
				data.isAttacking = false 
			end)
		elseif data.clickCount == 2 then
			data.animTrack2:Play()
			data.animTrack2.Stopped:Once(function() 
				data.isAttacking = false 
			end)
		elseif data.clickCount == 3 then
			data.animTrack3:Play()
			data.animTrack3.Stopped:Once(function() 
				data.isAttacking = false 
				data.clickCount = 0 -- reset combo
			end)
		end
	end
end

local function handleWave(player)
	local data = playerAttackData[player]
	if not data then return end
	
	if data.isAttacking or data.isBlocking then 
		print("[Actions] Wave blocked - already performing action")
		return 
	end
	
	print("[Actions] Player", player.Name, "performing wave emote")
	
	-- Play wave animation
	data.waveTrack:Play()
end

local function handleBlock(player, isBlocking)
	local data = playerAttackData[player]
	if not data then return end
	
	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	if isBlocking then
		-- Start blocking
		data.isBlocking = true
		data.blockTrack:Play()
		hum.WalkSpeed = 0 -- Stop movement while blocking
		print("[Actions] Player", player.Name, "started blocking")
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		hum.WalkSpeed = data.originalWalkSpeed -- Restore movement
		print("[Actions] Player", player.Name, "stopped blocking")
	end
end

local function handleJumpAttack(player)
	local data = playerAttackData[player]
	if not data then return end
	
	if data.isAttacking or data.isBlocking then 
		print("[Actions] Jump attack blocked - already performing action")
		return 
	end
	
	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	-- Check if player is actually jumping using our tracking flag
	if not data.isJumping then
		print("[Actions] Jump attack blocked - not jumping (isJumping:", data.isJumping, "humState:", hum:GetState(), ")")
		return
	end
	
	data.isAttacking = true
	print("[Actions] Player", player.Name, "performing jump attack")
	
	-- Play jump attack animation
	data.jumpTrack:Play()
	data.jumpTrack.Stopped:Once(function()
		data.isAttacking = false
	end)
end

-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName)
	print("[Actions] Server received:", actionName, "from", player.Name)
	
	-- Handle attack actions
	if actionName == "normal_attack_setup" then
		setupAttackAnimations(player)
	elseif actionName == "normal_attack_cleanup" then
		cleanupAttackAnimations(player)
	elseif actionName == "left_click_attack" then
		handleNormalAttack(player)
	elseif actionName == "wave" then
		handleWave(player)
	elseif actionName == "block_start" then
		handleBlock(player, true)
	elseif actionName == "block_end" then
		handleBlock(player, false)
	elseif actionName == "jump_attack" then
		handleJumpAttack(player)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	cleanupAttackAnimations(player)
end)
