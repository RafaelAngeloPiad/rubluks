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
-- SEPARATE ANIMATION SPEED CONFIGURATION
-- ========================================

-- Individual animation speed multipliers for each action type
-- Each action can now have its own speed independent of others
-- 
-- HOW TO USE:
-- 1. Change values here to adjust animation speeds
-- 2. Camera speeds will automatically sync with these values
-- 3. Use _G.updateSamuraiAnimationSpeed(actionType, newSpeed) to update at runtime
--
_G.SAMURAI_ANIMATION_SPEEDS = {
	-- Basic movements
	idle = 1.0,
	run = 1.0,
	jump = 1.0,
	
	-- Walking speeds (fixed values, not affected by animation speed)
	walking = {
		normal = 18,    -- Fixed normal walking speed
		slow = 3,       -- Fixed speed during skills (wakizashi/kozuki)
		blocking = 0    -- Fixed speed while blocking
	},
	
	-- Attack combos
	combo1 = 1.0,
	combo2 = 1.0,
	combo3 = 1.0,
	moveAttack = 1.0,
	jumpAttack = 1.0,
	block = 1.0,
	-- Note: Wave is now handled globally by GlobalAnimations.server.luau
	
	-- Skills
	kozuki = 1.0,
	wakizashi = 1.0,
	
	-- Buffs
	banzai = 1.0,
	bushido = 1.0,
	
	-- Ultimate
	zantetsuken = 1.0
}

-- Function to apply specific speed to animation track
function _G.applySamuraiAnimationSpeed(animTrack, actionType)
	if not animTrack or not actionType then return end
	
	local speed = _G.SAMURAI_ANIMATION_SPEEDS[actionType] or 1.0
	animTrack:AdjustSpeed(speed)
end

-- Function to sync specific animation speed with client
local function syncAnimationSpeedWithClient(player, actionType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local speed = _G.SAMURAI_ANIMATION_SPEEDS[actionType] or 1.0
	remote:FireClient(player, "update_animation_speed", speed, actionType)
end

-- Function to sync all animation speeds with client
local function syncAllAnimationSpeedsWithClient(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	for actionType, speed in pairs(_G.SAMURAI_ANIMATION_SPEEDS) do
		remote:FireClient(player, "update_animation_speed", speed, actionType)
	end
end

-- Function to update animation speed and sync with all clients
function _G.updateSamuraiAnimationSpeed(actionType, newSpeed)
	if not actionType or not newSpeed then
		warn("Invalid parameters for updateSamuraiAnimationSpeed")
		return
	end
	
	-- Update the speed
	_G.SAMURAI_ANIMATION_SPEEDS[actionType] = newSpeed
	
	-- Sync with all players
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	for _, player in pairs(Players:GetPlayers()) do
		remote:FireClient(player, "update_animation_speed", newSpeed, actionType)
	end
	
end


-- ========================================
-- WALKING SPEED CONFIGURATION
-- ========================================

-- Fixed walking speed settings (no longer dependent on animation speed)
-- These are the actual speeds used, not multiplied by anything
_G.SAMURAI_WALKING_SPEED = {
	normal = 18,    -- Fixed normal walking speed
	slow = 3,       -- Fixed speed during skills (wakizashi/kozuki)
	blocking = 0    -- Fixed speed while blocking
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
-- CENTRALIZED COOLDOWN CONFIGURATION
-- ========================================

-- All skill cooldowns in one place for easy management
-- HOW TO USE:
-- 1. Change values here to adjust cooldown times
-- 2. All skills automatically use these values
-- 3. No need to modify individual skill files
--
_G.SAMURAI_COOLDOWNS = {
	-- Skills
	kozuki = 5,        -- 10 seconds cooldown
	wakizashi = 5,      -- 8 seconds cooldown
	
	-- Buffs
	banzai = 5,        -- 15 seconds cooldown
	bushido = 5,       -- 12 seconds cooldown
	
	-- Ultimate
	zantetsuken = 5    -- 30 seconds cooldown (ultimate)
}

-- Centralized cooldown tracking for all players
local playerCooldowns = {}

-- Function to check if skill is on cooldown
function _G.isSkillOnCooldown(player, skillName)
	local currentTime = tick()
	local cooldownTime = _G.SAMURAI_COOLDOWNS[skillName]
	
	if not cooldownTime then
		return false -- Skill doesn't exist
	end
	
	if not playerCooldowns[player.UserId] then
		playerCooldowns[player.UserId] = {}
	end
	
	local lastUsed = playerCooldowns[player.UserId][skillName]
	if not lastUsed then
		return false -- Never used before
	end
	
	local timeSinceLastUse = currentTime - lastUsed
	return timeSinceLastUse < cooldownTime
end

-- Function to get remaining cooldown time
function _G.getRemainingCooldown(player, skillName)
	local currentTime = tick()
	local cooldownTime = _G.SAMURAI_COOLDOWNS[skillName]
	
	if not cooldownTime or not playerCooldowns[player.UserId] then
		return 0
	end
	
	local lastUsed = playerCooldowns[player.UserId][skillName]
	if not lastUsed then
		return 0
	end
	
	local timeSinceLastUse = currentTime - lastUsed
	local remaining = cooldownTime - timeSinceLastUse
	return math.max(0, remaining)
end

-- Function to set skill cooldown
function _G.setSkillCooldown(player, skillName)
	local currentTime = tick()
	
	if not playerCooldowns[player.UserId] then
		playerCooldowns[player.UserId] = {}
	end
	
	playerCooldowns[player.UserId][skillName] = currentTime
end

-- Function to send cooldown status to client
function _G.sendCooldownStatus(player, skillName, isOnCooldown, remainingTime)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "cooldown_status", skillName, isOnCooldown, remainingTime)
end

-- ========================================
-- TRAIL MANAGEMENT SYSTEM
-- Handles katana trail activation during attacks
-- ========================================

-- ========================================
-- TRAIL CONFIGURATION (SERVER-SIDE ONLY)
-- This is the ONLY place to configure trail behavior
-- ========================================
-- HOW TO USE:
-- 1. Change lifetime values to adjust how long each individual trail stays active
-- 2. These settings apply to ALL attacks and combos
-- 3. Set lifetime to 0 to keep trails on until manually disabled
-- 4. Changes here automatically sync to all clients
-- ========================================
_G.SAMURAI_TRAIL_CONFIG = {
	-- Individual Trail Lifetime settings (in seconds)
	-- These apply to ALL attacks and combos
	Lifetime = {
		trail1 = 0.13,      -- Trail1.Lifetime for all attacks
		trail2 = 0.1,      -- Trail2.Lifetime for all attacks
		trail3 = 0.08       -- Trail3.Lifetime for all attacks
	}
}

-- Function to enable trails on client (uses global trail config)
function _G.enableSamuraiTrails(player, attackType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local trailConfig = _G.SAMURAI_TRAIL_CONFIG.Lifetime
	remote:FireClient(player, "enable_trails", trailConfig)
end

-- Function to enable trails on client with custom individual trail lifetimes
function _G.enableSamuraiTrailsCustom(player, trail1Lifetime, trail2Lifetime, trail3Lifetime)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local customConfig = {
		trail1 = trail1Lifetime,
		trail2 = trail2Lifetime,
		trail3 = trail3Lifetime
	}
	remote:FireClient(player, "enable_trails", customConfig)
end

-- Function to disable trails on client
function _G.disableSamuraiTrails(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "disable_trails")
end

-- Function to sync trail configuration with client
function _G.syncTrailConfig(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "sync_trail_config", _G.SAMURAI_TRAIL_CONFIG)
end

-- ========================================
-- ATTACK ANIMATION SETUP
-- ========================================

local function setupAttackAnimations(player, tool)
	local character = player.Character
	if not character then return end
	
	-- Make samurai weapon non-collidable when held
	if tool then
		for _, part in ipairs(tool:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
	
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

	-- Note: Wave animation is now handled globally by GlobalAnimations.server.luau

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
		-- Note: waveTrack removed - now handled globally
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
		_G.applySamuraiAnimationSpeed(idleTrack, "idle")
	
	-- Set walking speed immediately when weapon is equipped
	_G.setSamuraiWalkingSpeed(player, "normal")
	
	-- Sync all animation speeds with client
	syncAllAnimationSpeedsWithClient(player)
	
	-- Sync trail configuration with client
	_G.syncTrailConfig(player)
	
	-- Movement animation handling
	hum.Running:Connect(function(speed)
		local data = playerAttackData[player]
		if not data then return end
		
		if speed > 1 then -- threshold for running
			if data.idleTrack.IsPlaying then data.idleTrack:Stop() end
			if not data.runTrack.IsPlaying then 
				data.runTrack:Play()
				_G.applySamuraiAnimationSpeed(data.runTrack, "run")
			end
		else
			if data.runTrack.IsPlaying then data.runTrack:Stop() end
			if not data.idleTrack.IsPlaying then 
				data.idleTrack:Play()
				_G.applySamuraiAnimationSpeed(data.idleTrack, "idle")
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

local function cleanupAttackAnimations(player, tool)
	local data = playerAttackData[player]
	if not data then return end
	
	-- Stop all animations
	if data.animTrack1 then data.animTrack1:Stop() end
	if data.animTrack2 then data.animTrack2:Stop() end
	if data.animTrack3 then data.animTrack3:Stop() end
	if data.jumpTrack then data.jumpTrack:Stop() end
	if data.moveSlashTrack then data.moveSlashTrack:Stop() end
	if data.blockTrack then data.blockTrack:Stop() end
	-- Note: waveTrack removed - now handled globally
	if data.idleTrack then data.idleTrack:Stop() end
	if data.runTrack then data.runTrack:Stop() end
	
	-- Disable trails when weapon is unequipped
	_G.disableSamuraiTrails(player)
	
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
		_G.applySamuraiAnimationSpeed(data.jumpTrack, "jumpAttack")
		
		-- Enable trails for jump attack
		_G.enableSamuraiTrails(player, "jumpAttack")
		
		-- Jump attack hitbox
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -5, -10),
			size = Vector3.new(8, 20, 15), -- Increased from 5x17x12 to 8x20x15
			damage = 12,
		character = char,
		name = "JumpAttack",
		showVisual = true,
		visualColor = Color3.new(0, 1, 0),
		delay = 0
	})
		
		data.jumpTrack.Stopped:Once(function()
			data.isAttacking = false
			-- Disable trails when attack animation ends
			_G.disableSamuraiTrails(player)
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
		_G.applySamuraiAnimationSpeed(data.moveSlashTrack, "moveAttack")
		
		-- Enable trails for move attack
		_G.enableSamuraiTrails(player, "moveAttack")
		
		-- Move attack hitbox
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, -10), -- x left / right, y up / down, z forward / backward
			size = Vector3.new(18, 18, 18), -- Increased from 12x12x12 to 18x18x18
			damage = 15,
			character = char,
			name = "MoveAttack",
			showVisual = true,
			visualColor = Color3.new(0, 0.8, 1),
			delay = 0.4 -- Base delay (auto-scales with animation speed)
		})
		
		data.moveSlashTrack.Stopped:Once(function()
			data.isAttacking = false
			-- Disable trails when attack animation ends
			_G.disableSamuraiTrails(player)
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
			_G.applySamuraiAnimationSpeed(data.animTrack1, "combo1")
			
			-- Enable trails for combo 1
			_G.enableSamuraiTrails(player, "combo1")
			
			-- Combo 1 hitbox
			_G.createStaticHitbox({
				attachTo = root,
				offset = CFrame.new(0, 0, -3),
				size = Vector3.new(12, 12, 9), -- Increased from 8x8x6 to 12x12x9
				damage = 8,
				character = char,
				name = "Combo1",
				showVisual = true,
				visualColor = Color3.new(1, 0.8, 0),
				delay = 0
			})
			
			data.animTrack1.Stopped:Once(function() 
				data.isAttacking = false 
				-- Disable trails when attack animation ends
				_G.disableSamuraiTrails(player)
				-- Start combo timer after first attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 2 then
			data.animTrack2:Play()
			_G.applySamuraiAnimationSpeed(data.animTrack2, "combo2")
			
			-- Enable trails for combo 2
			_G.enableSamuraiTrails(player, "combo2")
			
			-- Combo 2 hitbox
			_G.createStaticHitbox({
				attachTo = root,
				offset = CFrame.new(0, 0, -4),
				size = Vector3.new(15, 15, 12), -- Increased from 10x10x8 to 15x15x12
				damage = 12,
				character = char,
				name = "Combo2",
				showVisual = true,
				visualColor = Color3.new(0.8, 0.2, 1),
				delay = 0
			})
			
			data.animTrack2.Stopped:Once(function() 
				data.isAttacking = false 
				-- Disable trails when attack animation ends
				_G.disableSamuraiTrails(player)
				-- Start combo timer after second attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 3 then
			-- Check if combo 3 is available
			if not canPerformCombo3(player) then
				-- Reset to combo 1 and play it
				data.clickCount = 1
				data.animTrack1:Play()
				_G.applySamuraiAnimationSpeed(data.animTrack1, "combo1")
				
				-- Enable trails for combo 1 fallback
				_G.enableSamuraiTrails(player, "combo1Fallback")
				
				-- Combo 1 hitbox (fallback from combo 3 cooldown)
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 0, -3),
					size = Vector3.new(12, 12, 9), -- Increased from 8x8x6 to 12x12x9
					damage = 8,
					character = char,
					name = "Combo1_Fallback",
					showVisual = true,
					visualColor = Color3.new(1, 0.8, 0),
					delay = 0
				})
				
				data.animTrack1.Stopped:Once(function() 
					data.isAttacking = false 
					-- Disable trails when attack animation ends
					_G.disableSamuraiTrails(player)
					resetComboTimer(player)
				end)
			else
				-- Perform combo 3 and start cooldown
				data.animTrack3:Play()
				_G.applySamuraiAnimationSpeed(data.animTrack3, "combo3")
				
				-- Enable trails for combo 3 (longer duration for the powerful attack)
				_G.enableSamuraiTrails(player, "combo3")
				
				-- Combo 3 hitbox (most powerful)
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 0, -5),
					size = Vector3.new(25, 25, 25), -- Increased from 17x17x17 to 25x25x25
					damage = 20,
					character = char,
					name = "Combo3",
					showVisual = true,
					visualColor = Color3.new(1, 0, 0),
					delay = 2 -- Base delay (auto-scales with animation speed: 2s at 1x speed, 1s at 2x speed)
				})
				
				data.animTrack3.Stopped:Once(function() 
					data.isAttacking = false 
					-- Disable trails when attack animation ends
					_G.disableSamuraiTrails(player)
					data.clickCount = 0 -- reset combo
					startCombo3Cooldown(player)
				end)
			end
		end
	end
end

-- Note: handleWave removed - now handled globally by GlobalAnimations.server.luau

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
		_G.applySamuraiAnimationSpeed(data.blockTrack, "block")
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
	
	-- Enable trails for jump attack
	_G.enableSamuraiTrails(player, "jumpAttack")
	
	-- Play jump attack animation
	data.jumpTrack:Play()
	_G.applySamuraiAnimationSpeed(data.jumpTrack, "jumpAttack")
	data.jumpTrack.Stopped:Once(function()
		data.isAttacking = false
		-- Disable trails when attack animation ends
		_G.disableSamuraiTrails(player)
	end)
end

-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName, tool)
	
	-- Handle samurai-specific attack actions (prefixed with "samurai_")
	if actionName == "samurai_attack_setup" then
		setupAttackAnimations(player, tool)
	elseif actionName == "samurai_attack_cleanup" then
		cleanupAttackAnimations(player, tool)
	elseif actionName == "samurai_left_click_attack" then
		handleNormalAttack(player)
	-- Note: samurai_wave removed - now handled globally by GlobalAnimations.server.luau
	elseif actionName == "samurai_block_start" then
		handleBlock(player, true)
	elseif actionName == "samurai_block_end" then
		handleBlock(player, false)
	elseif actionName == "samurai_jump_attack" then
		handleJumpAttack(player)
	elseif actionName == "sync_camera_speeds" then
		-- Sync all camera speeds with client
		syncAllAnimationSpeedsWithClient(player)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	cleanupAttackAnimations(player)
end)

