-- ========================================
-- NORMAL ATTACKS SERVER
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
-- @param classType: Class name (e.g., "Samurai")
-- @param damageMultiplier: Damage multiplier (e.g., 0.24 = 24% of MaxAttack)
-- @param forceCrit: Optional boolean to force a critical hit (default: false)
-- @return: actualDamage, isCrit - the final damage value and whether it was a critical hit
local function calculateDamageForHitbox(player, classType, damageMultiplier, forceCrit)
	forceCrit = forceCrit or false -- Default to false if not provided
	
	-- Check if calculateDamageWithCrit function exists (fallback for module caching issues)
	if ServerConfigs.calculateDamageWithCrit then
		return ServerConfigs.calculateDamageWithCrit(damageMultiplier, player, forceCrit)
	else
		-- Fallback: if function doesn't exist, use base damage calculation
		local maxAttack = getPlayerMaxAttack(player)
		if ServerConfigs.calculateDamage then
			return ServerConfigs.calculateDamage(damageMultiplier, maxAttack), false
		else
			warn("[Samurai] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Store player attack data
local playerAttackData = {}

-- ========================================
-- UNIFIED ANIMATION SPEED CONFIGURATION
-- ========================================

-- Unified animation speeds (attack and movement)
-- Attack actions: combo1, combo2, combo3, moveAttack, jumpAttack, kozuki, wakizashi, banzai, bushido, zantetsuken
-- Movement actions: run, jump (idle and block are NOT affected - always 1.0)

-- Helper function to get animation speed for an action type
local function getAnimationSpeed(actionType)
	if not actionType then return 1.0 end
	
	-- Block and idle animations always use 1.0 (not affected by animation speeds)
	if actionType == "block" or actionType == "idle" then
		return 1.0
	end
	
	-- Determine if this is an attack or movement action
	local isAttack = actionType == "combo1" or actionType == "combo2" or actionType == "combo3" or actionType == "moveAttack" or actionType == "jumpAttack" or
	                 actionType == "kozuki" or actionType == "wakizashi" or actionType == "banzai" or actionType == "bushido" or actionType == "zantetsuken"
	
	local isMovement = actionType == "run" or actionType == "jump"
	
	-- Return appropriate unified speed
	if isAttack then
		return ServerConfigs.Samurai.AttackSpeed or 1.0
	elseif isMovement then
		return ServerConfigs.Samurai.MovementSpeed or 1.0
	end
	
	-- Default to 1.0 for unknown action types
	return 1.0
end

-- Function to apply specific speed to animation track
function _G.applySamuraiAnimationSpeed(animTrack, actionType)
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
	local actionTypes = {"idle", "run", "jump", "combo1", "combo2", "combo3", "moveAttack", "jumpAttack", "block",
	                     "kozuki", "wakizashi", "banzai", "bushido", "zantetsuken"}
	for _, actionType in ipairs(actionTypes) do
		local speed = getAnimationSpeed(actionType)
		remote:FireClient(player, "update_animation_speed", speed, actionType)
	end
end

-- Function to update animation speed and sync with all clients
-- Note: Now updates the unified speed in ServerConfigs, not individual action types
function _G.updateSamuraiAnimationSpeed(speedType, newSpeed)
	if not speedType or not newSpeed then
		warn("Invalid parameters for updateSamuraiAnimationSpeed. Use 'attack' or 'movement' as speedType.")
		return
	end

	-- Update the unified speed in config
	if speedType == "attack" then
		ServerConfigs.Samurai.AttackSpeed = newSpeed
		ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.attackSpeed = newSpeed
	elseif speedType == "movement" then
		ServerConfigs.Samurai.MovementSpeed = newSpeed
		ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.movementSpeed = newSpeed
	else
		warn("Invalid speedType. Use 'attack' or 'movement'.")
		return
	end

	-- Sync with all players (sync all action types affected by this change)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local actionTypes = {}
	if speedType == "attack" then
		actionTypes = {"combo1", "combo2", "combo3", "moveAttack", "jumpAttack", "kozuki", "wakizashi", "banzai", "bushido", "zantetsuken"}
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
_G.SAMURAI_WALKING_SPEED = ServerConfigs.Samurai.walking

-- Function to set player walking speed
function _G.setSamuraiWalkingSpeed(player, speedType)
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

	local baseSpeed = _G.SAMURAI_WALKING_SPEED[speedType] or _G.SAMURAI_WALKING_SPEED.normal
	-- Walk speed = base speed * MovementSpeed multiplier from leaderstats
	humanoid.WalkSpeed = baseSpeed * movementSpeedMultiplier
end

-- Combo system configuration
local COMBO_CONFIG = ServerConfigs.Samurai.ComboConfig

-- ========================================
-- CENTRALIZED COOLDOWN CONFIGURATION
-- ========================================

-- All skill cooldowns in one place for easy management
-- HOW TO USE:
-- 1. Change values here to adjust cooldown times
-- 2. All skills automatically use these values
-- 3. No need to modify individual skill files
--
_G.SAMURAI_COOLDOWNS = ServerConfigs.Samurai.Cooldowns

-- Centralized cooldown tracking for all players
local playerCooldowns = {}

-- Function to check if skill is on cooldown
function _G.samuraiIsSkillOnCooldown(player, skillName)
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
function _G.samuraiGetRemainingCooldown(player, skillName)
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
function _G.samuraiSetSkillCooldown(player, skillName)
	local currentTime = tick()
	
	if not playerCooldowns[player.UserId] then
		playerCooldowns[player.UserId] = {}
	end
	
	playerCooldowns[player.UserId][skillName] = currentTime
end

-- Function to send cooldown status to client
function _G.samuraiSendCooldownStatus(player, skillName, isOnCooldown, remainingTime)
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
_G.SAMURAI_TRAIL_CONFIG = ServerConfigs.Samurai.TrailConfig

-- Function to enable trails on client (uses global trail config)
function _G.enableSamuraiTrails(player, attackType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local trailConfig = {
		Lifetime = _G.SAMURAI_TRAIL_CONFIG.Lifetime,
		Color = _G.SAMURAI_TRAIL_CONFIG.Color,
		FaceCamera = _G.SAMURAI_TRAIL_CONFIG.FaceCamera
	}
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
		local hitboxConfig = ServerConfigs.getHitboxConfig("jumpAttack", "Samurai")
		local damageMultiplier = hitboxConfig.damage
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Samurai", damageMultiplier)
		
		-- Check for Blade Dance passive (Atk+) - adds flat Attack to damage
		local bladeDanceAttackIncrease = 0
		if _G.checkSamuraiBladeDancePassive then
			local success, result = pcall(function()
				return _G.checkSamuraiBladeDancePassive(player)
			end)
			if success and result then
				bladeDanceAttackIncrease = result
			end
		end
		
		-- Add Blade Dance attack increase to final damage
		local finalDamage = actualDamage + bladeDanceAttackIncrease
		local visualColor = hitboxConfig.visualColor
		if bladeDanceAttackIncrease > 0 then
			-- Use orange/gold color to indicate Blade Dance triggered
			visualColor = Color3.new(1, 0.8, 0)
		end
		
		_G.createStaticHitbox({
			attachTo = root,
			offset = hitboxConfig.offset,
			size = hitboxConfig.size,
			damage = finalDamage,
			character = char,
			name = "JumpAttack",
			showVisual = false,
			visualColor = visualColor,
			delay = hitboxConfig.delay,
			actionType = "jumpAttack",
			classType = "Samurai"
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
		local hitboxConfig = ServerConfigs.getHitboxConfig("moveAttack", "Samurai")
		local damageMultiplier = hitboxConfig.damage
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Samurai", damageMultiplier)
		
		-- Check for Blade Dance passive (Atk+) - adds flat Attack to damage
		local bladeDanceAttackIncrease = 0
		if _G.checkSamuraiBladeDancePassive then
			local success, result = pcall(function()
				return _G.checkSamuraiBladeDancePassive(player)
			end)
			if success and result then
				bladeDanceAttackIncrease = result
			end
		end
		
		-- Add Blade Dance attack increase to final damage
		local finalDamage = actualDamage + bladeDanceAttackIncrease
		local visualColor = hitboxConfig.visualColor
		if bladeDanceAttackIncrease > 0 then
			-- Use orange/gold color to indicate Blade Dance triggered
			visualColor = Color3.new(1, 0.8, 0)
		end
		
		_G.createStaticHitbox({
			attachTo = root,
			offset = hitboxConfig.offset,
			size = hitboxConfig.size,
			damage = finalDamage,
			character = char,
			name = "MoveAttack",
			showVisual = false,
			visualColor = visualColor,
			delay = hitboxConfig.delay, -- Base delay (auto-scales with animation speed)
			actionType = "moveAttack",
			classType = "Samurai"
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
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo1", "Samurai")
			local damageMultiplier = hitboxConfig.damage
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Samurai", damageMultiplier)
			
			-- Check for Blade Dance passive (Atk+) - adds flat Attack to damage
			local bladeDanceAttackIncrease = 0
			if _G.checkSamuraiBladeDancePassive then
				local success, result = pcall(function()
					return _G.checkSamuraiBladeDancePassive(player)
				end)
				if success and result then
					bladeDanceAttackIncrease = result
				end
			end
			
			-- Add Blade Dance attack increase to final damage
			local finalDamage = actualDamage + bladeDanceAttackIncrease
			local visualColor = hitboxConfig.visualColor
			if bladeDanceAttackIncrease > 0 then
				-- Use orange/gold color to indicate Blade Dance triggered
				visualColor = Color3.new(1, 0.8, 0)
			end
			
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = finalDamage,
				character = char,
				name = "Combo1",
				showVisual = false,
				visualColor = visualColor,
				delay = hitboxConfig.delay,
				actionType = "combo1",
				classType = "Samurai"
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
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo2", "Samurai")
			local damageMultiplier = hitboxConfig.damage
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Samurai", damageMultiplier)
			
			-- Check for Blade Dance passive (Atk+) - adds flat Attack to damage
			local bladeDanceAttackIncrease = 0
			if _G.checkSamuraiBladeDancePassive then
				local success, result = pcall(function()
					return _G.checkSamuraiBladeDancePassive(player)
				end)
				if success and result then
					bladeDanceAttackIncrease = result
				end
			end
			
			-- Add Blade Dance attack increase to damage (before Burst check)
			local damageWithBladeDance = actualDamage + bladeDanceAttackIncrease
			
			-- Check for Burst passive (combo2 Atk x2) - BEFORE creating hitbox
			-- Similar to how crits work: multiply damage by 2 instead of creating two separate hits
			local burstTriggered = false
			if _G.checkSamuraiBurstPassive then
				local success, result = pcall(function()
					return _G.checkSamuraiBurstPassive(player)
				end)
				if success then
					burstTriggered = result
				end
			end
			
			-- If Burst passive triggered, multiply damage by 2 (like crit multiplier)
			-- This creates ONE hit with double damage, not two separate hits
			local finalDamage = damageWithBladeDance
			local visualColor = hitboxConfig.visualColor
			if burstTriggered then
				-- Double the damage (including Blade Dance bonus)
				finalDamage = math.floor(damageWithBladeDance * 2)
				-- Use orange/gold color to indicate Burst triggered
				visualColor = Color3.new(1, 0.8, 0)
			elseif bladeDanceAttackIncrease > 0 then
				-- Only Blade Dance triggered, use orange/gold color
				visualColor = Color3.new(1, 0.8, 0)
			end
			
			-- Create ONE hitbox with final damage (doubled if Burst triggered)
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
				classType = "Samurai"
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
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo1", "Samurai")
			local damageMultiplier = hitboxConfig.damage
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Samurai", damageMultiplier)
			
			-- Check for Blade Dance passive (Atk+) - adds flat Attack to damage
			local bladeDanceAttackIncrease = 0
			if _G.checkSamuraiBladeDancePassive then
				local success, result = pcall(function()
					return _G.checkSamuraiBladeDancePassive(player)
				end)
				if success and result then
					bladeDanceAttackIncrease = result
				end
			end
			
			-- Add Blade Dance attack increase to final damage
			local finalDamage = actualDamage + bladeDanceAttackIncrease
			local visualColor = hitboxConfig.visualColor
			if bladeDanceAttackIncrease > 0 then
				-- Use orange/gold color to indicate Blade Dance triggered
				visualColor = Color3.new(1, 0.8, 0)
			end
			
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = finalDamage,
				character = char,
				name = "Combo1_Fallback",
				showVisual = false,
				visualColor = visualColor,
				delay = hitboxConfig.delay,
				actionType = "combo1",
				classType = "Samurai"
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
				
			-- Combo 3 hitbox (most powerful) - FORCED CRIT
			local hitboxConfig = ServerConfigs.getHitboxConfig("combo3", "Samurai")
			local damageMultiplier = hitboxConfig.damage
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Samurai", damageMultiplier, true) -- Force crit for combo3
			
			-- Check for Blade Dance passive (Atk+) - adds flat Attack to damage
			local bladeDanceAttackIncrease = 0
			if _G.checkSamuraiBladeDancePassive then
				local success, result = pcall(function()
					return _G.checkSamuraiBladeDancePassive(player)
				end)
				if success and result then
					bladeDanceAttackIncrease = result
				end
			end
			
			-- Add Blade Dance attack increase to final damage
			local finalDamage = actualDamage + bladeDanceAttackIncrease
			local visualColor = hitboxConfig.visualColor
			if bladeDanceAttackIncrease > 0 then
				-- Use orange/gold color to indicate Blade Dance triggered
				visualColor = Color3.new(1, 0.8, 0)
			end
			
			_G.createStaticHitbox({
				attachTo = root,
				offset = hitboxConfig.offset,
				size = hitboxConfig.size,
				damage = finalDamage,
				character = char,
				name = "Combo3",
				showVisual = false,
				visualColor = visualColor,
				delay = hitboxConfig.delay, -- Base delay (auto-scales with animation speed: 2s at 1x speed, 1s at 2x speed)
				actionType = "combo3",
				classType = "Samurai"
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
		-- Update global blocking state for damage reduction
		if _G.setPlayerBlockingState then
			_G.setPlayerBlockingState(player, true)
		end
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal movement
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
	elseif actionName == "sync_camera_speeds" then
		-- Sync all camera speeds with client
		syncAllAnimationSpeedsWithClient(player)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	cleanupAttackAnimations(player)
end)

