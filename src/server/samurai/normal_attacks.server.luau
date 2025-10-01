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

	-- Right Click Idle Animation
	local rightClickIdleAnim = Instance.new("Animation")
	rightClickIdleAnim.AnimationId = "rbxassetid://116101111905611"
	local rightClickIdleTrack = animator:LoadAnimation(rightClickIdleAnim)
	rightClickIdleTrack.Priority = Enum.AnimationPriority.Action

	-- Store player data
	playerAttackData[player] = {
		animTrack1 = animTrack1,
		animTrack2 = animTrack2,
		animTrack3 = animTrack3,
		jumpTrack = jumpTrack,
		moveSlashTrack = moveSlashTrack,
		rightClickIdleTrack = rightClickIdleTrack,
		clickCount = 0,
		isAttacking = false,
		isRightClicking = false,
		isJumping = false,
		holdingRightClick = false,
		originalWalkSpeed = hum.WalkSpeed
	}
	
	-- Detect Jump state
	hum.StateChanged:Connect(function(_, newState)
		local data = playerAttackData[player]
		if not data then return end
		
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			data.isJumping = true
		elseif newState == Enum.HumanoidStateType.Landed then
			data.isJumping = false
			if data.jumpTrack.IsPlaying then
				data.jumpTrack:Stop()
				print("[Attack] Jump attack ended for", player.Name)
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
	
	print("[Attack] Setup attack animations for", player.Name)
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
	if data.rightClickIdleTrack then data.rightClickIdleTrack:Stop() end
	
	-- Reset walk speed
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = data.originalWalkSpeed
		end
	end
	
	playerAttackData[player] = nil
	print("[Attack] Cleaned up attack animations for", player.Name)
end

-- ========================================
-- ATTACK HANDLERS
-- ========================================

local function handleNormalAttack(player)
	local data = playerAttackData[player]
	if not data then return end
	
	if data.isAttacking or data.isRightClicking then 
		print("[Attack] Attack blocked - already attacking")
		return 
	end
	
	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	local isMoving = hum.MoveDirection.Magnitude > 0
	local isJumping = data.isJumping
	
	data.isAttacking = true
	print("[Attack]", player.Name, "performing attack - Moving:", isMoving, "Jumping:", isJumping)
	
	if isJumping then
		-- Jump + Left click = Jump attack anim
		data.jumpTrack:Play()
		data.jumpTrack.Stopped:Once(function()
			data.isAttacking = false
		end)
		
	elseif isMoving then
		-- Move attack kapag naglalakad
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

local function handleRightClickHold(player, isHolding)
	local data = playerAttackData[player]
	if not data then return end
	
	if isHolding then
		if data.isAttacking then return end
		
		data.holdingRightClick = true
		data.isRightClicking = true
		data.rightClickIdleTrack:Play()
		
		-- Lock movement
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 0
			end
		end
		
	else
		data.holdingRightClick = false
		data.isRightClicking = false
		
		-- Reset walk speed
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = data.originalWalkSpeed
			end
		end
		
		-- Stop animation
		data.rightClickIdleTrack:Stop()
	end
end

-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName)
	print("[Attack] Server received request from", player.Name, "with actionName:", actionName)
	
	-- Handle attack actions
	if actionName == "normal_attack_setup" then
		setupAttackAnimations(player)
	elseif actionName == "normal_attack_cleanup" then
		cleanupAttackAnimations(player)
	elseif actionName == "left_click_attack" then
		handleNormalAttack(player)
	elseif actionName == "right_click_hold" then
		handleRightClickHold(player, true)
	elseif actionName == "right_click_release" then
		handleRightClickHold(player, false)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	cleanupAttackAnimations(player)
end)
