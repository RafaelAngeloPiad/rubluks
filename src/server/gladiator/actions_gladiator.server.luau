-- ========================================
-- GLADIATOR NORMAL ATTACKS SERVER
-- Handles basic attack animations and mechanics
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Helper function to get player's MaxAttack stat
local function getPlayerMaxAttack(player)
	if not player then return 0 end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end
	
	local maxAttack = leaderstats:FindFirstChild("MaxAttack")
	if not maxAttack then return 0 end
	
	return maxAttack.Value or 0
end

-- Helper function to calculate actual damage from multiplier with crit chance
-- @param player: Player instance
-- @param classType: Class name (e.g., "Gladiator")
-- @param damageMultiplier: Damage multiplier (e.g., 0.4 = 40% of MaxAttack)
-- @return: actualDamage, isCrit - the final damage value and whether it was a critical hit
local function calculateDamageForHitbox(player, classType, damageMultiplier)
	-- Check if calculateDamageWithCrit function exists (fallback for module caching issues)
	if ServerConfigs.calculateDamageWithCrit then
		return ServerConfigs.calculateDamageWithCrit(damageMultiplier, player)
	else
		-- Fallback: if function doesn't exist, use base damage calculation
		local maxAttack = getPlayerMaxAttack(player)
		if ServerConfigs.calculateDamage then
			return ServerConfigs.calculateDamage(damageMultiplier, maxAttack), false
		else
			warn("[Gladiator] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Store player attack data
local playerAttackData = {}

-- ========================================
-- SOUND SYSTEM
-- Helper function to play attack sounds on client
-- ========================================

-- Import sound configuration
local GladiatorSoundConfig = require(ReplicatedStorage:WaitForChild("GladiatorSoundConfig"))

local function playAttackSound(player, attackType)
	if not player then return end
	local soundId = GladiatorSoundConfig.getSound(attackType)
	remote:FireClient(player, "play_sound", soundId)
end

-- ========================================
-- UNIFIED ANIMATION SPEED CONFIGURATION
-- ========================================

-- Unified animation speeds (attack and movement)
-- Attack actions: combo1, combo2, moveAttack, jumpAttack, shieldbash, dragoonjump, championsblood, championscheer, demonicvorpaldance
-- Movement actions: run, jump (idle and block are NOT affected - always 1.0)

-- Helper function to get animation speed for an action type
local function getAnimationSpeed(actionType)
	if not actionType then return 1.0 end
	
	-- Block and idle animations always use 1.0 (not affected by animation speeds)
	if actionType == "block" or actionType == "idle" then
		return 1.0
	end
	
	-- Determine if this is an attack or movement action
	local isAttack = actionType == "combo1" or actionType == "combo2" or actionType == "moveAttack" or actionType == "jumpAttack" or
	                 actionType == "shieldbash" or actionType == "dragoonjump" or actionType == "championsblood" or actionType == "championscheer" or actionType == "demonicvorpaldance"
	
	local isMovement = actionType == "run" or actionType == "jump"
	
	-- Return appropriate unified speed
	if isAttack then
		return ServerConfigs.Gladiator.AttackSpeed or 1.0
	elseif isMovement then
		return ServerConfigs.Gladiator.MovementSpeed or 1.0
	end
	
	-- Default to 1.0 for unknown action types
	return 1.0
end

-- Function to apply specific speed to animation track
function _G.applyGladiatorAnimationSpeed(animTrack, actionType)
	if not animTrack or not actionType then return end

	local speed = getAnimationSpeed(actionType)
	animTrack:AdjustSpeed(speed)
end

-- Function to sync specific animation speed with client
local function syncAnimationSpeedWithClient(player, actionType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local speed = getAnimationSpeed(actionType)
	remote:FireClient(player, "update_animation_speed", speed, actionType)
end

-- Function to sync all animation speeds with client
local function syncAllAnimationSpeedsWithClient(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	-- Sync all known action types
	local actionTypes = {"idle", "run", "jump", "combo1", "combo2", "moveAttack", "jumpAttack", "block",
	                     "shieldbash", "dragoonjump", "championsblood", "championscheer", "demonicvorpaldance"}
	for _, actionType in ipairs(actionTypes) do
		local speed = getAnimationSpeed(actionType)
		remote:FireClient(player, "update_animation_speed", speed, actionType)
	end
end

-- Function to update animation speed and sync with all clients
-- Note: Now updates the unified speed in ServerConfigs, not individual action types
function _G.updateGladiatorAnimationSpeed(speedType, newSpeed)
	if not speedType or not newSpeed then
		warn("Invalid parameters for updateGladiatorAnimationSpeed. Use 'attack' or 'movement' as speedType.")
		return
	end

	-- Update the unified speed in config
	if speedType == "attack" then
		ServerConfigs.Gladiator.AttackSpeed = newSpeed
		ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.attackSpeed = newSpeed
	elseif speedType == "movement" then
		ServerConfigs.Gladiator.MovementSpeed = newSpeed
		ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.movementSpeed = newSpeed
	else
		warn("Invalid speedType. Use 'attack' or 'movement'.")
		return
	end

	-- Sync with all players (sync all action types affected by this change)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local actionTypes = {}
	if speedType == "attack" then
		actionTypes = {"combo1", "combo2", "moveAttack", "jumpAttack", "shieldbash", "dragoonjump", "championsblood", "championscheer", "demonicvorpaldance"}
	elseif speedType == "movement" then
		actionTypes = {"run", "jump"} -- Note: idle is NOT affected by movement speed (always 1.0)
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		for _, actionType in ipairs(actionTypes) do
			remote:FireClient(player, "update_animation_speed", newSpeed, actionType)
		end
	end
end


-- ========================================
-- WALKING SPEED CONFIGURATION
-- ========================================

-- Fixed walking speed settings (no longer dependent on animation speed)
-- These are the actual speeds used, not multiplied by anything
_G.GLADIATOR_WALKING_SPEED = ServerConfigs.Gladiator.walking

-- Function to set player walking speed
function _G.setGladiatorWalkingSpeed(player, speedType)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local movementSpeedMultiplier = 1.0
	if leaderstats then
		local movementSpeedStat = leaderstats:FindFirstChild("MovementSpeed")
		if movementSpeedStat then
			movementSpeedMultiplier = movementSpeedStat.Value
		end
	end

	local baseSpeed = _G.GLADIATOR_WALKING_SPEED[speedType] or _G.GLADIATOR_WALKING_SPEED.normal
	-- Walk speed = base speed * MovementSpeed multiplier from leaderstats
	humanoid.WalkSpeed = baseSpeed * movementSpeedMultiplier
end

-- Combo system configuration
local COMBO_CONFIG = ServerConfigs.Gladiator.ComboConfig

-- ========================================
-- CENTRALIZED COOLDOWN CONFIGURATION
-- ========================================

-- All skill cooldowns in one place for easy management
-- HOW TO USE:
-- 1. Change values here to adjust cooldown times
-- 2. All skills automatically use these values
-- 3. No need to modify individual skill files
--
_G.GLADIATOR_COOLDOWNS = ServerConfigs.Gladiator.Cooldowns

-- Centralized cooldown tracking for all players
local playerCooldowns = {}

-- Function to check if skill is on cooldown
function _G.gladiatorIsSkillOnCooldown(player, skillName)
	local currentTime = tick()
	local cooldownTime = _G.GLADIATOR_COOLDOWNS[skillName]
	
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
function _G.gladiatorGetRemainingCooldown(player, skillName)
	local currentTime = tick()
	local cooldownTime = _G.GLADIATOR_COOLDOWNS[skillName]
	
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
function _G.gladiatorSetSkillCooldown(player, skillName)
	local currentTime = tick()
	
	if not playerCooldowns[player.UserId] then
		playerCooldowns[player.UserId] = {}
	end
	
	playerCooldowns[player.UserId][skillName] = currentTime
end

-- Function to send cooldown status to client
function _G.gladiatorSendCooldownStatus(player, skillName, isOnCooldown, remainingTime)
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
_G.GLADIATOR_TRAIL_CONFIG = {
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
function _G.enableGladiatorTrails(player, attackType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local trailConfig = {
		Lifetime = _G.GLADIATOR_TRAIL_CONFIG.Lifetime,
		Color = _G.GLADIATOR_TRAIL_CONFIG.Color,
		FaceCamera = _G.GLADIATOR_TRAIL_CONFIG.FaceCamera
	}
	remote:FireClient(player, "enable_trails", trailConfig)
end

-- Function to enable trails on client with custom individual trail lifetimes
function _G.enableGladiatorTrailsCustom(player, trail1Lifetime, trail2Lifetime, trail3Lifetime)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local customConfig = {
		trail1 = trail1Lifetime,
		trail2 = trail2Lifetime,
		trail3 = trail3Lifetime
	}
	remote:FireClient(player, "enable_trails", customConfig)
end

-- Function to disable trails on client
function _G.disableGladiatorTrails(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "disable_trails")
end

-- Function to sync trail configuration with client
function _G.syncGladiatorTrailConfig(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "sync_trail_config", _G.GLADIATOR_TRAIL_CONFIG)
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

	-- Make sure sword and shield (and any child parts) are visible and non-physical when held.
	-- This will walk ALL descendants so nested Parts / MeshParts are also updated.
	if tool then
		for _, part in ipairs(tool:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
			end
		end
	end
	if sword then 
		sword.Transparency = 0
	end
	if shield then 
		shield.Transparency = 0
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
	
	-- Attack Animations (Gladiator has only 2-hit combo)
	local anim1 = Instance.new("Animation")
	anim1.AnimationId = "rbxassetid://93306564380704"
	local animTrack1 = animator:LoadAnimation(anim1)

	local anim2 = Instance.new("Animation")
	anim2.AnimationId = "rbxassetid://85669585505960"
	local animTrack2 = animator:LoadAnimation(anim2)

	-- Jump Attack Animation
	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = "rbxassetid://92927046911901"
	local jumpTrack = animator:LoadAnimation(jumpAnim)
	jumpTrack.Priority = Enum.AnimationPriority.Action

	-- Move Attack Animation
	local moveSlashAnim = Instance.new("Animation")
	moveSlashAnim.AnimationId = "rbxassetid://85752352985435"
	local moveSlashTrack = animator:LoadAnimation(moveSlashAnim)

	-- Block Animation (Right Click)
	local blockAnim = Instance.new("Animation")
	blockAnim.AnimationId = "rbxassetid://95754766804055"
	local blockTrack = animator:LoadAnimation(blockAnim)
	blockTrack.Priority = Enum.AnimationPriority.Action

	-- Note: Wave animation is now handled globally by GlobalAnimations.server.luau

	-- Movement Animations
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = "rbxassetid://124239767875200"
	local idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Looped = true
	idleTrack.Priority = Enum.AnimationPriority.Idle

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = "rbxassetid://78012536571899"
	local runTrack = animator:LoadAnimation(runAnim)
	runTrack.Looped = true
	runTrack.Priority = Enum.AnimationPriority.Movement

	-- Store player data (Gladiator only has 2-hit combo)
	playerAttackData[player] = {
		animTrack1 = animTrack1,
		animTrack2 = animTrack2,
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
	}
	
	-- Start with idle animation
		idleTrack:Play()
		_G.applyGladiatorAnimationSpeed(idleTrack, "idle")
	
	-- Set walking speed immediately when weapon is equipped
	_G.setGladiatorWalkingSpeed(player, "normal")
	
	-- Sync all animation speeds with client
	syncAllAnimationSpeedsWithClient(player)
	
	-- Sync trail configuration with client
	_G.syncGladiatorTrailConfig(player)
	
	-- Movement animation handling
	hum.Running:Connect(function(speed)
		local data = playerAttackData[player]
		if not data then return end
		
		if speed > 1 then -- threshold for running
			if data.idleTrack.IsPlaying then data.idleTrack:Stop() end
			if not data.runTrack.IsPlaying then 
				data.runTrack:Play()
				_G.applyGladiatorAnimationSpeed(data.runTrack, "run")
			end
		else
			if data.runTrack.IsPlaying then data.runTrack:Stop() end
			if not data.idleTrack.IsPlaying then 
				data.idleTrack:Play()
				_G.applyGladiatorAnimationSpeed(data.idleTrack, "idle")
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
	
	-- Stop all animations (Gladiator only has 2 combos)
	if data.animTrack1 then data.animTrack1:Stop() end
	if data.animTrack2 then data.animTrack2:Stop() end
	if data.jumpTrack then data.jumpTrack:Stop() end
	if data.moveSlashTrack then data.moveSlashTrack:Stop() end
	if data.blockTrack then data.blockTrack:Stop() end
	-- Note: waveTrack removed - now handled globally
	if data.idleTrack then data.idleTrack:Stop() end
	if data.runTrack then data.runTrack:Stop() end
	
	-- Disable trails when weapon is unequipped
	_G.disableGladiatorTrails(player)
	
	-- Clear combo timer
	if data.comboTimer then
		task.cancel(data.comboTimer)
		data.comboTimer = nil
	end
	
	-- Clear blocking state when weapon is unequipped
	if _G.setPlayerBlockingState then
		_G.setPlayerBlockingState(player, false)
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
	
	-- Set new timer (Gladiator has simple 2-hit combo)
	data.comboTimer = task.delay(COMBO_CONFIG.comboTimeout, function()
		data.clickCount = 0
		data.isAttacking = false -- Reset attacking flag when combo times out
	end)
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
		_G.applyGladiatorAnimationSpeed(data.jumpTrack, "jumpAttack")
		
		-- Enable trails for jump attack
		_G.enableGladiatorTrails(player, "jumpAttack")
		
		-- Play attack sound
		playAttackSound(player, "jumpAttack")
		
		-- Jump attack hitbox
		local hitboxConfig = ServerConfigs.getHitboxConfig("jumpAttack", "Gladiator")
		local damageMultiplier = hitboxConfig.damage
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Gladiator", damageMultiplier)
		_G.createStaticHitbox({
			attachTo = root,
			offset = hitboxConfig.offset,
			size = hitboxConfig.size,
			damage = actualDamage,
			character = char,
			name = "JumpAttack",
			showVisual = false,
			visualColor = hitboxConfig.visualColor,
			delay = hitboxConfig.delay,
			actionType = "jumpAttack",
			classType = "Gladiator"
		})
		
		data.jumpTrack.Stopped:Once(function()
			data.isAttacking = false
			-- Disable trails when attack animation ends
			_G.disableGladiatorTrails(player)
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
		_G.applyGladiatorAnimationSpeed(data.moveSlashTrack, "moveAttack")
		
		-- Enable trails for move attack
		_G.enableGladiatorTrails(player, "moveAttack")
		
		-- Play attack sound
		playAttackSound(player, "moveAttack")
		
		-- Move attack hitbox
		local hitboxConfig = ServerConfigs.getHitboxConfig("moveAttack", "Gladiator")
		local damageMultiplier = hitboxConfig.damage
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Gladiator", damageMultiplier)
		_G.createStaticHitbox({
			attachTo = root,
			offset = hitboxConfig.offset,
			size = hitboxConfig.size,
			damage = actualDamage,
			character = char,
			name = "MoveAttack",
			showVisual = false,
			visualColor = hitboxConfig.visualColor,
			delay = hitboxConfig.delay, -- Base delay (auto-scales with animation speed)
			actionType = "moveAttack",
			classType = "Gladiator"
		})
		
		data.moveSlashTrack.Stopped:Once(function()
			data.isAttacking = false
			-- Disable trails when attack animation ends
			_G.disableGladiatorTrails(player)
		end)
		
	else
		-- Normal ground combo (standing still) - Gladiator has 2-hit combo that loops (1,2,1,2...)
		-- Clear existing combo timer
		if data.comboTimer then
			task.cancel(data.comboTimer)
			data.comboTimer = nil
		end
		
		data.clickCount += 1
		
		if data.clickCount == 1 then
			data.animTrack1:Play()
			_G.applyGladiatorAnimationSpeed(data.animTrack1, "combo1")
			
			-- Enable trails for combo 1
			_G.enableGladiatorTrails(player, "combo1")
			
			-- Play attack sound
			playAttackSound(player, "combo1")
			
			-- Combo 1 hitbox
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo1", "Gladiator")
			local damageMultiplier = hitboxConfig.damage
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Gladiator", damageMultiplier)
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = actualDamage,
				character = char,
				name = "Combo1",
				showVisual = false,
				visualColor = hitboxConfig.visualColor,
				delay = hitboxConfig.delay,
				actionType = "combo1",
				classType = "Gladiator"
			})
			
			data.animTrack1.Stopped:Once(function() 
				data.isAttacking = false 
				-- Disable trails when attack animation ends
				_G.disableGladiatorTrails(player)
				-- Start combo timer after first attack
				resetComboTimer(player)
			end)
		elseif data.clickCount == 2 then
			data.animTrack2:Play()
			_G.applyGladiatorAnimationSpeed(data.animTrack2, "combo2")
			
			-- Enable trails for combo 2
			_G.enableGladiatorTrails(player, "combo2")
			
			-- Combo 2 hitbox
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo2", "Gladiator")
			local damageMultiplier = hitboxConfig.damage
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Gladiator", damageMultiplier)
			
			-- Check for Champion's Rebuke passive (2nd combo attack x2) - BEFORE creating hitbox
			-- Similar to how crits work: multiply damage by 2 instead of creating two separate hits
			local championsRebukeTriggered = false
			if _G.checkChampionsRebukePassive then
				local success, result = pcall(function()
					return _G.checkChampionsRebukePassive(player)
				end)
				if success then
					championsRebukeTriggered = result
				end
			end
			
			-- If Champion's Rebuke passive triggered, multiply damage by 2 (like crit multiplier)
			-- This creates ONE hit with double damage, not two separate hits
			local finalDamage = actualDamage
			local visualColor = hitboxConfig.visualColor
			if championsRebukeTriggered then
				-- Double the damage (like crits multiply by critMultiplier/100, but we multiply by 2)
				finalDamage = math.floor(actualDamage * 2)
				-- Use orange/gold color to indicate Champion's Rebuke triggered
				visualColor = Color3.new(1, 0.8, 0)
			end
			
			-- Play attack sound
			playAttackSound(player, "combo2")
			
			-- Create ONE hitbox with final damage (doubled if Champion's Rebuke triggered)
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = finalDamage,
				character = char,
				name = "Combo2",
				showVisual = false,
				visualColor = visualColor,
				delay = hitboxConfig.delay,
				actionType = "combo2",
				classType = "Gladiator"
			})
			
			data.animTrack2.Stopped:Once(function() 
				data.isAttacking = false 
				-- Disable trails when attack animation ends
				_G.disableGladiatorTrails(player)
				data.clickCount = 0 -- Reset combo to loop back to combo 1
				-- Start combo timer after second attack
				resetComboTimer(player)
			end)
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
		_G.applyGladiatorAnimationSpeed(data.blockTrack, "block")
		_G.setGladiatorWalkingSpeed(player, "blocking") -- Stop movement while blocking
		-- Update global blocking state for damage reduction
		if _G.setPlayerBlockingState then
			_G.setPlayerBlockingState(player, true)
		end
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setGladiatorWalkingSpeed(player, "normal") -- Restore normal movement
		-- Update global blocking state for damage reduction
		if _G.setPlayerBlockingState then
			_G.setPlayerBlockingState(player, false)
		end
	end
end


-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName, tool)
	
	-- Handle gladiator-specific attack actions (prefixed with "gladiator_")
	if actionName == "gladiator_attack_setup" then
		setupAttackAnimations(player, tool)
	elseif actionName == "gladiator_attack_cleanup" then
		cleanupAttackAnimations(player, tool)
	elseif actionName == "gladiator_left_click_attack" then
		handleNormalAttack(player)
	-- Note: gladiator_wave removed - now handled globally by GlobalAnimations.server.luau
	elseif actionName == "gladiator_block_start" then
		handleBlock(player, true)
	elseif actionName == "gladiator_block_end" then
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

