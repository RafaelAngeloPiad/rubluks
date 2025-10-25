-- ========================================
-- KNIGHT NORMAL ATTACKS SERVER
-- Handles basic attack animations and mechanics
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

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
-- 3. Use _G.updateKnightAnimationSpeed(actionType, newSpeed) to update at runtime
--
_G.KNIGHT_ANIMATION_SPEEDS = ServerConfigs.Knight.AnimationSpeeds

-- Function to apply specific speed to animation track
function _G.applyKnightAnimationSpeed(animTrack, actionType)
	if not animTrack or not actionType then return end
	
	local speed = _G.KNIGHT_ANIMATION_SPEEDS[actionType]
	animTrack:AdjustSpeed(speed)
end

-- Function to sync specific animation speed with client
local function syncAnimationSpeedWithClient(player, actionType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local speed = _G.KNIGHT_ANIMATION_SPEEDS[actionType]
	remote:FireClient(player, "update_animation_speed", speed, actionType)
end

-- Function to sync all animation speeds with client
local function syncAllAnimationSpeedsWithClient(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	for actionType, speed in pairs(_G.KNIGHT_ANIMATION_SPEEDS) do
		remote:FireClient(player, "update_animation_speed", speed, actionType)
	end
end

-- Function to update animation speed and sync with all clients
function _G.updateKnightAnimationSpeed(actionType, newSpeed)
	if not actionType or not newSpeed then
		warn("Invalid parameters for updateKnightAnimationSpeed")
		return
	end
	
	-- Update the speed
	_G.KNIGHT_ANIMATION_SPEEDS[actionType] = newSpeed
	
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
_G.KNIGHT_WALKING_SPEED = ServerConfigs.Knight.AnimationSpeeds.walking

-- Function to set player walking speed
function _G.setKnightWalkingSpeed(player, speedType)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local speed = _G.KNIGHT_WALKING_SPEED[speedType] or _G.KNIGHT_WALKING_SPEED.normal
	humanoid.WalkSpeed = speed
end

-- Combo system configuration
local COMBO_CONFIG = ServerConfigs.Knight.ComboConfig

-- ========================================
-- CENTRALIZED COOLDOWN CONFIGURATION
-- ========================================

-- All skill cooldowns in one place for easy management
-- HOW TO USE:
-- 1. Change values here to adjust cooldown times
-- 2. All skills automatically use these values
-- 3. No need to modify individual skill files
--
_G.KNIGHT_COOLDOWNS = ServerConfigs.Knight.Cooldowns

-- Centralized cooldown tracking for all players
local playerCooldowns = {}

-- Function to check if skill is on cooldown
function _G.isSkillOnCooldown(player, skillName)
	local currentTime = tick()
	local cooldownTime = _G.KNIGHT_COOLDOWNS[skillName]
	
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
	local cooldownTime = _G.KNIGHT_COOLDOWNS[skillName]
	
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
-- Handles sword trail activation during attacks
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
_G.KNIGHT_TRAIL_CONFIG = {
	-- Individual Trail Lifetime settings (in seconds)
	-- These apply to ALL attacks and combos
	Lifetime = {
		trail1 = 0.13,      -- Trail1.Lifetime for all attacks
		trail2 = 0.1,       -- Trail2.Lifetime for all attacks
		trail3 = 0.08       -- Trail3.Lifetime for all attacks
	},
	-- Individual Trail Color settings (RGB values 0-255)
	Color = {
		trail1 = {255, 255, 255},  -- Trail1.Color (white)
		trail2 = {255, 255, 255},  -- Trail2.Color (white)
		trail3 = {255, 255, 255}   -- Trail3.Color (white)
	},
	-- Individual Trail FaceCamera settings (boolean)
	FaceCamera = {
		trail1 = true,      -- Trail1.FaceCamera
		trail2 = true,      -- Trail2.FaceCamera
		trail3 = true       -- Trail3.FaceCamera
	}
}

-- Function to enable trails on client (uses global trail config)
function _G.enableKnightTrails(player, attackType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local trailConfig = {
		Lifetime = _G.KNIGHT_TRAIL_CONFIG.Lifetime,
		Color = _G.KNIGHT_TRAIL_CONFIG.Color,
		FaceCamera = _G.KNIGHT_TRAIL_CONFIG.FaceCamera
	}
	remote:FireClient(player, "enable_trails", trailConfig)
end

-- Function to enable trails on client with custom individual trail lifetimes
function _G.enableKnightTrailsCustom(player, trail1Lifetime, trail2Lifetime, trail3Lifetime)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local customConfig = {
		trail1 = trail1Lifetime,
		trail2 = trail2Lifetime,
		trail3 = trail3Lifetime
	}
	remote:FireClient(player, "enable_trails", customConfig)
end

-- Function to disable trails on client
function _G.disableKnightTrails(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "disable_trails")
end

-- Function to sync trail configuration with client
function _G.syncKnightTrailConfig(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "sync_trail_config", _G.KNIGHT_TRAIL_CONFIG)
end

-- ========================================
-- SWORD & SHIELD ATTACHMENT (from Knight Animation Scripts.lua)
-- ========================================

local swordMotorName = "SwordRightHandMotor"
local shieldMotorName = "ShieldLeftHandMotor"

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

local function attachSwordAndShield(character, tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")

	-- Make sure sword and shield are visible and non-collidable when held
	if sword then 
		sword.Transparency = 0
		sword.CanCollide = false
	end
	if shield then 
		shield.Transparency = 0
		shield.CanCollide = false
	end

	local offsets = getHandOffsets(humanoid.RigType)

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		attachPartToLimb(sword, "RightHand", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		attachPartToLimb(shield, "LeftHand", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	else
		attachPartToLimb(sword, "Right Arm", swordMotorName, character, offsets.swordC0, offsets.swordC1)
		attachPartToLimb(shield, "Left Arm", shieldMotorName, character, offsets.shieldC0, offsets.shieldC1)
	end
end

local function removeSwordAndShield(character, tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local sword = tool:FindFirstChild("Handle")
	local shield = tool:FindFirstChild("Shield")

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

-- ========================================
-- ATTACK ANIMATION SETUP
-- ========================================

local function setupAttackAnimations(player, tool)
	local character = player.Character
	if not character then return end
	
	-- Attach sword and shield to player's hands (server-side for replication)
	if tool then
		attachSwordAndShield(character, tool)
	end
	
	local hum = character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local root = character:FindFirstChild("HumanoidRootPart")
	
	if not animator then return end
	
	-- Attack Animations
	local anim1 = Instance.new("Animation")
	anim1.AnimationId = "rbxassetid://84832524704792"
	local animTrack1 = animator:LoadAnimation(anim1)

	local anim2 = Instance.new("Animation")
	anim2.AnimationId = "rbxassetid://85669585505960"
	local animTrack2 = animator:LoadAnimation(anim2)

	local anim3 = Instance.new("Animation")
	anim3.AnimationId = "rbxassetid://107397939946639"
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
	blockAnim.AnimationId = "rbxassetid://122699913339617"
	local blockTrack = animator:LoadAnimation(blockAnim)
	blockTrack.Priority = Enum.AnimationPriority.Action

	-- Note: Wave animation is now handled globally by GlobalAnimations.server.luau

	-- Movement Animations
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = "rbxassetid://124151833095983"
	local idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Looped = true
	idleTrack.Priority = Enum.AnimationPriority.Idle

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = "rbxassetid://82332507172404"
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
		_G.applyKnightAnimationSpeed(idleTrack, "idle")
	
	-- Set walking speed immediately when weapon is equipped
	_G.setKnightWalkingSpeed(player, "normal")
	
	-- Sync all animation speeds with client
	syncAllAnimationSpeedsWithClient(player)
	
	-- Sync trail configuration with client
	_G.syncKnightTrailConfig(player)
	
	-- Movement animation handling
	hum.Running:Connect(function(speed)
		local data = playerAttackData[player]
		if not data then return end
		
		if speed > 1 then -- threshold for running
			if data.idleTrack.IsPlaying then data.idleTrack:Stop() end
			if not data.runTrack.IsPlaying then 
				data.runTrack:Play()
				_G.applyKnightAnimationSpeed(data.runTrack, "run")
			end
		else
			if data.runTrack.IsPlaying then data.runTrack:Stop() end
			if not data.idleTrack.IsPlaying then 
				data.idleTrack:Play()
				_G.applyKnightAnimationSpeed(data.idleTrack, "idle")
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
	
	-- Remove sword and shield from player's hands
	if tool then
		local char = player.Character
		if char then
			removeSwordAndShield(char, tool)
		end
	end
	
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
	_G.disableKnightTrails(player)
	
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
		_G.applyKnightAnimationSpeed(data.jumpTrack, "jumpAttack")
		
		-- Enable trails for jump attack
		_G.enableKnightTrails(player, "jumpAttack")
		
		-- Jump attack hitbox
		local hitboxConfig = ServerConfigs.getHitboxConfig("jumpAttack", "Knight")
		_G.createStaticHitbox({
			attachTo = root,
			offset = hitboxConfig.offset,
			size = hitboxConfig.size,
			damage = hitboxConfig.damage,
			character = char,
			name = "JumpAttack",
			showVisual = true,
			visualColor = hitboxConfig.visualColor,
			delay = hitboxConfig.delay
		})
		
		data.jumpTrack.Stopped:Once(function()
			data.isAttacking = false
			-- Disable trails when attack animation ends
			_G.disableKnightTrails(player)
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
		_G.applyKnightAnimationSpeed(data.moveSlashTrack, "moveAttack")
		
		-- Enable trails for move attack
		_G.enableKnightTrails(player, "moveAttack")
		
		-- Move attack hitbox
		local hitboxConfig = ServerConfigs.getHitboxConfig("moveAttack", "Knight")
		_G.createStaticHitbox({
			attachTo = root,
			offset = hitboxConfig.offset,
			size = hitboxConfig.size,
			damage = hitboxConfig.damage,
			character = char,
			name = "MoveAttack",
			showVisual = true,
			visualColor = hitboxConfig.visualColor,
			delay = hitboxConfig.delay -- Base delay (auto-scales with animation speed)
		})
		
		data.moveSlashTrack.Stopped:Once(function()
			data.isAttacking = false
			-- Disable trails when attack animation ends
			_G.disableKnightTrails(player)
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
			_G.applyKnightAnimationSpeed(data.animTrack1, "combo1")
			
			-- Enable trails for combo 1
			_G.enableKnightTrails(player, "combo1")
			
			-- Combo 1 hitbox
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo1", "Knight")
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = hitboxConfig.damage,
				character = char,
				name = "Combo1",
				showVisual = true,
				visualColor = hitboxConfig.visualColor,
				delay = hitboxConfig.delay
			})
			
			data.animTrack1.Stopped:Once(function() 
				data.isAttacking = false 
				-- Disable trails when attack animation ends
				_G.disableKnightTrails(player)
				-- Start combo timer after first attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 2 then
			data.animTrack2:Play()
			_G.applyKnightAnimationSpeed(data.animTrack2, "combo2")
			
			-- Enable trails for combo 2
			_G.enableKnightTrails(player, "combo2")
			
			-- Combo 2 hitbox
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo2", "Knight")
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = hitboxConfig.damage,
				character = char,
				name = "Combo2",
				showVisual = true,
				visualColor = hitboxConfig.visualColor,
				delay = hitboxConfig.delay
			})
			
			data.animTrack2.Stopped:Once(function() 
				data.isAttacking = false 
				-- Disable trails when attack animation ends
				_G.disableKnightTrails(player)
				-- Start combo timer after second attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 3 then
			-- Check if combo 3 is available
			if not canPerformCombo3(player) then
				-- Reset to combo 1 and play it
				data.clickCount = 1
				data.animTrack1:Play()
				_G.applyKnightAnimationSpeed(data.animTrack1, "combo1")
				
				-- Enable trails for combo 1 fallback
				_G.enableKnightTrails(player, "combo1Fallback")
				
			-- Combo 1 hitbox (fallback from combo 3 cooldown)
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo1", "Knight")
				_G.createStaticHitbox({
					attachTo = root,
					offset = hitboxConfig.offset,
					size = hitboxConfig.size,
					damage = hitboxConfig.damage,
					character = char,
					name = "Combo1_Fallback",
					showVisual = true,
					visualColor = hitboxConfig.visualColor,
					delay = hitboxConfig.delay
				})
				
				data.animTrack1.Stopped:Once(function() 
					data.isAttacking = false 
					-- Disable trails when attack animation ends
					_G.disableKnightTrails(player)
					resetComboTimer(player)
				end)
			else
				-- Perform combo 3 and start cooldown
				data.animTrack3:Play()
				_G.applyKnightAnimationSpeed(data.animTrack3, "combo3")
				
				-- Enable trails for combo 3
				_G.enableKnightTrails(player, "combo3")
				
			-- Combo 3 hitbox (most powerful)
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo3", "Knight")
				_G.createStaticHitbox({
					attachTo = root,
					offset = hitboxConfig.offset,
					size = hitboxConfig.size,
					damage = hitboxConfig.damage,
					character = char,
					name = "Combo3",
					showVisual = true,
					visualColor = hitboxConfig.visualColor,
					delay = hitboxConfig.delay -- Base delay (auto-scales with animation speed: 2s at 1x speed, 1s at 2x speed)
				})
				
				data.animTrack3.Stopped:Once(function() 
					data.isAttacking = false 
					-- Disable trails when attack animation ends
					_G.disableKnightTrails(player)
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
		_G.applyKnightAnimationSpeed(data.blockTrack, "block")
		_G.setKnightWalkingSpeed(player, "blocking") -- Stop movement while blocking
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setKnightWalkingSpeed(player, "normal") -- Restore normal movement
	end
end


-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName, tool)
	
	-- Handle knight-specific attack actions (prefixed with "knight_")
	if actionName == "knight_attack_setup" then
		setupAttackAnimations(player, tool)
	elseif actionName == "knight_attack_cleanup" then
		cleanupAttackAnimations(player, tool)
	elseif actionName == "knight_left_click_attack" then
		handleNormalAttack(player)
	-- Note: knight_wave removed - now handled globally by GlobalAnimations.server.luau
	elseif actionName == "knight_block_start" then
		handleBlock(player, true)
	elseif actionName == "knight_block_end" then
		handleBlock(player, false)
	elseif actionName == "sync_camera_speeds" then
		-- Sync all camera speeds with client
		syncAllAnimationSpeedsWithClient(player)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	cleanupAttackAnimations(player)
end)

