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
-- GLOBAL ANIMATION SPEED CONFIGURATION
-- ========================================

-- Global animation speed multiplier for all samurai animations
-- Adjust this single value to change speed of ALL samurai animations
-- NOTE: This also automatically scales ALL hitbox delays proportionally!
-- Example: If you set this to 2.0 (double speed), all delays become half (0.25s becomes 0.125s)
_G.SAMURAI_ANIMATION_SPEED = 2 -- 1.0 = normal speed, 2.0 = double speed, 0.5 = half speed

-- Function to apply speed to any animation track
function _G.applySamuraiAnimationSpeed(animTrack)
	if animTrack and _G.SAMURAI_ANIMATION_SPEED then
		animTrack:AdjustSpeed(_G.SAMURAI_ANIMATION_SPEED)
	end
end

-- Function to sync animation speed with client
local function syncAnimationSpeedWithClient(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "update_animation_speed", _G.SAMURAI_ANIMATION_SPEED)
end

-- Function to send cooldown status to client
local function sendCooldownStatus(player, skillName, isOnCooldown, remainingTime)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "cooldown_status", skillName, isOnCooldown, remainingTime)
end

-- ========================================
-- GLOBAL WALKING SPEED CONFIGURATION
-- ========================================

-- Global walking speed settings for all samurai actions
_G.SAMURAI_WALKING_SPEED = {
	normal = 18,    -- Normal walking speed
	slow = 3,       -- Speed during skills (wakizashi/kozuki)
	blocking = 0    -- Speed while blocking
}

-- Function to set player walking speed
function _G.setSamuraiWalkingSpeed(player, speedType)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local speed = _G.SAMURAI_WALKING_SPEED[speedType] or _G.SAMURAI_WALKING_SPEED.normal
	humanoid.WalkSpeed = speed
end

-- Combo system configuration
local COMBO_CONFIG = {
	comboTimeout = 1, -- 1 second timeout for combo reset
	combo3Cooldown = 20, -- 3 second cooldown for 3rd attack
}

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
		originalWalkSpeed = hum.WalkSpeed,
		-- Combo system variables
		comboTimer = nil,
		combo3CooldownEnd = 0,
		canUseCombo3 = true
	}
	
	-- Start with idle animation
		idleTrack:Play()
		_G.applySamuraiAnimationSpeed(idleTrack)
	
	-- Set walking speed immediately when weapon is equipped
	_G.setSamuraiWalkingSpeed(player, "normal")
	
	-- Sync animation speed with client
	syncAnimationSpeedWithClient(player)
	
	-- Movement animation handling
	hum.Running:Connect(function(speed)
		local data = playerAttackData[player]
		if not data then return end
		
		if speed > 1 then -- threshold for running
			if data.idleTrack.IsPlaying then data.idleTrack:Stop() end
			if not data.runTrack.IsPlaying then 
				data.runTrack:Play()
				_G.applySamuraiAnimationSpeed(data.runTrack)
			end
		else
			if data.runTrack.IsPlaying then data.runTrack:Stop() end
			if not data.idleTrack.IsPlaying then 
				data.idleTrack:Play()
				_G.applySamuraiAnimationSpeed(data.idleTrack)
			end
		end
	end)
	
	-- Detect Jump state
	hum.StateChanged:Connect(function(_, newState)
		local data = playerAttackData[player]
		if not data then return end
		
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			data.isJumping = true
		elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
			data.isJumping = false
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
	
	-- Clear combo timer
	if data.comboTimer then
		task.cancel(data.comboTimer)
		data.comboTimer = nil
	end
	
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
-- COMBO SYSTEM HELPERS
-- ========================================

local function resetComboTimer(player)
	local data = playerAttackData[player]
	if not data then return end
	
	-- Clear existing timer
	if data.comboTimer then
		task.cancel(data.comboTimer)
		data.comboTimer = nil
	end
	
	-- Set new timer
	data.comboTimer = task.delay(COMBO_CONFIG.comboTimeout, function()
		data.clickCount = 0
		data.isAttacking = false -- Reset attacking flag when combo times out
	end)
end

local function canPerformCombo3(player)
	local data = playerAttackData[player]
	if not data then return false end
	
	-- Check if cooldown has passed
	local currentTime = tick()
	if currentTime >= data.combo3CooldownEnd then
		data.canUseCombo3 = true
		return true
	end
	
	return false
end

local function startCombo3Cooldown(player)
	local data = playerAttackData[player]
	if not data then return end
	
	data.canUseCombo3 = false
	data.combo3CooldownEnd = tick() + COMBO_CONFIG.combo3Cooldown
end

-- ========================================
-- ATTACK HANDLERS
-- ========================================

local function handleNormalAttack(player)
	local data = playerAttackData[player]
	if not data then return end
	
	-- Prevent spam - only allow attack if not currently attacking
	if data.isAttacking or data.isBlocking then 
		return 
	end
	
	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local isMoving = hum.MoveDirection.Magnitude > 0
	local isJumping = data.isJumping
	
	data.isAttacking = true
	
	if isJumping then
		-- Jump attack - separate attack that resets combo (priority over movement)
		data.clickCount = 0 -- Reset combo when doing jump attack
		-- Clear combo timer
		if data.comboTimer then
			task.cancel(data.comboTimer)
			data.comboTimer = nil
		end
		data.jumpTrack:Play()
		_G.applySamuraiAnimationSpeed(data.jumpTrack)
		
		-- Jump attack hitbox
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -5, -10),
			size = Vector3.new(5, 17, 12),
			damage = 5,
			character = char,
			name = "JumpAttack",
			showVisual = true,
			visualColor = Color3.new(0, 1, 0),
			delay = 0
		})
		
		data.jumpTrack.Stopped:Once(function()
			data.isAttacking = false
		end)
		
	elseif isMoving then
		-- Move attack - separate attack that resets combo (only when on ground)
		data.clickCount = 0 -- Reset combo when doing move attack
		-- Clear combo timer
		if data.comboTimer then
			task.cancel(data.comboTimer)
			data.comboTimer = nil
		end
		data.moveSlashTrack:Play()
		_G.applySamuraiAnimationSpeed(data.moveSlashTrack)
		
		-- Move attack hitbox
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, -10), -- x left / right, y up / down, z forward / backward
			size = Vector3.new(12, 12, 12),
			damage = 7,
			character = char,
			name = "MoveAttack",
			showVisual = true,
			visualColor = Color3.new(0, 0.8, 1),
			delay = 0.4 -- Base delay (auto-scales with animation speed)
		})
		
		data.moveSlashTrack.Stopped:Once(function()
			data.isAttacking = false
		end)
		
	else
		-- Normal ground combo (standing still)
		-- Clear existing combo timer
		if data.comboTimer then
			task.cancel(data.comboTimer)
			data.comboTimer = nil
		end
		
		data.clickCount += 1
		
		if data.clickCount == 1 then
			data.animTrack1:Play()
			_G.applySamuraiAnimationSpeed(data.animTrack1)
			
			-- Combo 1 hitbox
			_G.createStaticHitbox({
				attachTo = root,
				offset = CFrame.new(0, 0, -3),
				size = Vector3.new(8, 8, 6),
				damage = 1,
				character = char,
				name = "Combo1",
				showVisual = true,
				visualColor = Color3.new(1, 0.8, 0),
				delay = 0
			})
			
			data.animTrack1.Stopped:Once(function() 
				data.isAttacking = false 
				-- Start combo timer after first attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 2 then
			data.animTrack2:Play()
			_G.applySamuraiAnimationSpeed(data.animTrack2)
			
			-- Combo 2 hitbox
			_G.createStaticHitbox({
				attachTo = root,
				offset = CFrame.new(0, 0, -4),
				size = Vector3.new(10, 10, 8),
				damage = 1,
				character = char,
				name = "Combo2",
				showVisual = true,
				visualColor = Color3.new(0.8, 0.2, 1),
				delay = 0
			})
			
			data.animTrack2.Stopped:Once(function() 
				data.isAttacking = false 
				-- Start combo timer after second attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 3 then
			-- Check if combo 3 is available
			if not canPerformCombo3(player) then
				-- Reset to combo 1 and play it
				data.clickCount = 1
				data.animTrack1:Play()
			_G.applySamuraiAnimationSpeed(data.animTrack1)
				
				-- Combo 1 hitbox (fallback from combo 3 cooldown)
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 0, -3),
					size = Vector3.new(8, 8, 6),
					damage = 1,
					character = char,
					name = "Combo1_Fallback",
					showVisual = true,
					visualColor = Color3.new(1, 0.8, 0),
					delay = 0
				})
				
				data.animTrack1.Stopped:Once(function() 
					data.isAttacking = false 
					resetComboTimer(player)
				end)
			else
				-- Perform combo 3 and start cooldown
				data.animTrack3:Play()
				_G.applySamuraiAnimationSpeed(data.animTrack3)
				
				-- Combo 3 hitbox (most powerful)
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 0, -5),
					size = Vector3.new(17, 17, 17),
					damage = 4,
					character = char,
					name = "Combo3",
					showVisual = true,
					visualColor = Color3.new(1, 0, 0),
					delay = 2 -- Base delay (auto-scales with animation speed: 2s at 1x speed, 1s at 2x speed)
				})
				
				data.animTrack3.Stopped:Once(function() 
					data.isAttacking = false 
					data.clickCount = 0 -- reset combo
					startCombo3Cooldown(player)
				end)
			end
		end
	end
end

local function handleWave(player)
	local data = playerAttackData[player]
	if not data then return end
	
	if data.isAttacking or data.isBlocking then 
		return 
	end
	
	-- Play wave animation
	data.waveTrack:Play()
	_G.applySamuraiAnimationSpeed(data.waveTrack)
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
		_G.applySamuraiAnimationSpeed(data.blockTrack)
		_G.setSamuraiWalkingSpeed(player, "blocking") -- Stop movement while blocking
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal movement
	end
end

local function handleJumpAttack(player)
	local data = playerAttackData[player]
	if not data then return end
	
	if data.isAttacking or data.isBlocking then 
		return 
	end
	
	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	-- Check if player is actually jumping using our tracking flag
	if not data.isJumping then
		return
	end
	
	data.isAttacking = true
	
	-- Play jump attack animation
	data.jumpTrack:Play()
	_G.applySamuraiAnimationSpeed(data.jumpTrack)
	data.jumpTrack.Stopped:Once(function()
		data.isAttacking = false
	end)
end

-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName)
	
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
