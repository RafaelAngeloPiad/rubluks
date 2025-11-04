-- ========================================
-- ARCHER ATTACKS SERVER
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
-- @param classType: Class name (e.g., "Archer")
-- @param damageMultiplier: Damage multiplier (e.g., 0.2 = 20% of MaxAttack)
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
			warn("[Archer] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
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
-- Attack actions: normalAttack, jumpAttack, piercingShot, powerShot, hunterInstinct, hunterMark, starfall
-- Movement actions: run, jump (idle and block are NOT affected - always 1.0)

-- Helper function to get animation speed for an action type
local function getAnimationSpeed(actionType)
	if not actionType then return 1.0 end
	
	-- Block and idle animations always use 1.0 (not affected by animation speeds)
	if actionType == "block" or actionType == "idle" then
		return 1.0
	end
	
	-- Determine if this is an attack or movement action
	local isAttack = actionType == "normalAttack" or actionType == "jumpAttack" or
	                 actionType == "piercingShot" or actionType == "powerShot" or
	                 actionType == "hunterInstinct" or actionType == "hunterMark" or actionType == "starfall"
	
	local isMovement = actionType == "run" or actionType == "jump"
	
	-- Return appropriate unified speed
	if isAttack then
		return ServerConfigs.Archer.AttackSpeed or 1.0
	elseif isMovement then
		return ServerConfigs.Archer.MovementSpeed or 1.0
	end
	
	-- Default to 1.0 for unknown action types
	return 1.0
end

-- Function to apply specific speed to animation track
function _G.applyArcherAnimationSpeed(animTrack, actionType)
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
	local actionTypes = {"idle", "run", "jump", "normalAttack", "jumpAttack", "block",
	                     "piercingShot", "powerShot", "hunterInstinct", "hunterMark", "starfall"}
	for _, actionType in ipairs(actionTypes) do
		local speed = getAnimationSpeed(actionType)
		remote:FireClient(player, "update_animation_speed", speed, actionType)
	end
end

-- Function to update animation speed and sync with all clients
-- Note: Now updates the unified speed in ServerConfigs, not individual action types
function _G.updateArcherAnimationSpeed(speedType, newSpeed)
	if not speedType or not newSpeed then
		warn("Invalid parameters for updateArcherAnimationSpeed. Use 'attack' or 'movement' as speedType.")
		return
	end

	-- Update the unified speed in config
	if speedType == "attack" then
		ServerConfigs.Archer.AttackSpeed = newSpeed
		ServerConfigs.Hitboxes.UnifiedAttacks.Archer.attackSpeed = newSpeed
	elseif speedType == "movement" then
		ServerConfigs.Archer.MovementSpeed = newSpeed
		ServerConfigs.Hitboxes.UnifiedAttacks.Archer.movementSpeed = newSpeed
	else
		warn("Invalid speedType. Use 'attack' or 'movement'.")
		return
	end

	-- Sync with all players (sync all action types affected by this change)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local actionTypes = {}
	if speedType == "attack" then
		actionTypes = {"normalAttack", "jumpAttack", "piercingShot", "powerShot", "hunterInstinct", "hunterMark", "starfall"}
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
_G.ARCHER_WALKING_SPEED = ServerConfigs.Archer.walking

-- Function to set player walking speed
function _G.setArcherWalkingSpeed(player, speedType)
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

	local baseSpeed = _G.ARCHER_WALKING_SPEED[speedType] or _G.ARCHER_WALKING_SPEED.normal
	-- Walk speed = base speed * MovementSpeed multiplier from leaderstats
	humanoid.WalkSpeed = baseSpeed * movementSpeedMultiplier
end

-- Archer uses simple single attack system (no combos)

-- ========================================
-- CENTRALIZED COOLDOWN CONFIGURATION
-- ========================================

-- All skill cooldowns in one place for easy management
-- HOW TO USE:
-- 1. Change values here to adjust cooldown times
-- 2. All skills automatically use these values
-- 3. No need to modify individual skill files
--
_G.ARCHER_COOLDOWNS = ServerConfigs.Archer.Cooldowns

-- ========================================
-- CENTRALIZED ARROW HITBOX CONFIGURATION
-- ========================================

-- All arrow hitbox settings in one place for easy management
-- HOW TO USE:
-- 1. Change values here to adjust all arrow hitboxes at once
-- 2. All normal attacks (jump, move, normal) use these values
-- 3. No need to modify individual attack calls
-- 4. anchorDelay: Adjust this to fix visual alignment when arrows stop mid-air
--    - Increase if arrow stops too early (before reaching target)
--    - Decrease if arrow goes through target before stopping
--

_G.ARCHER_ARROW_HITBOX = ServerConfigs.Archer.ArrowHitbox

-- ========================================
-- ARROW SPAWN OFFSET CONFIGURATION
-- ========================================

-- Unified arrow spawn offsets for easy tweaking
_G.ARCHER_ARROW_SPAWN_OFFSETS = ServerConfigs.Archer.ArrowSpawnOffsets

-- Function to get spawn offset based on first-person state
function _G.getArrowSpawnOffset(isFirstPerson)
	if isFirstPerson then
		return _G.ARCHER_ARROW_SPAWN_OFFSETS.firstPerson
	else
		return _G.ARCHER_ARROW_SPAWN_OFFSETS.thirdPerson
	end
end

-- Centralized cooldown tracking for all players
local playerCooldowns = {}

-- ========================================
-- NOTE: SEPARATE ARROW VISUAL AND HITBOX SYSTEM
-- ========================================
-- This functionality has been moved to DynamicHitboxV3.createProjectileHitbox()
-- See src/server/DynamicHitboxV3.server.luau for implementation
--
-- The archer arrows now use the unified DynamicHitbox system which includes:
-- - Separate visual and hitbox speeds
-- - Unified damage flash highlighting
-- - Consistent transparency settings
-- - Better integration with friendly fire system
-- ========================================

-- Function to check if skill is on cooldown
function _G.isSkillOnCooldown(player, skillName)
	local currentTime = tick()
	local cooldownTime = _G.ARCHER_COOLDOWNS[skillName]

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
	local cooldownTime = _G.ARCHER_COOLDOWNS[skillName]

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

-- Function to sync aim lock state to client
function _G.syncAimLockState(player, aimLockEnabled)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "sync_aim_lock_state", aimLockEnabled)
end

-- ========================================
-- ARROW TRAIL COLOR CONFIGURATION
-- Simple color configuration for arrow trails
-- ========================================

-- Arrow trail color configuration (RGB values 0-255)
_G.ARCHER_ARROW_TRAIL_COLOR = ServerConfigs.Archer.ArrowTrailColor

-- Function to set arrow trail color
function _G.setArcherArrowTrailColor(player, r, g, b)
	_G.ARCHER_ARROW_TRAIL_COLOR = {r, g, b}
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "set_arrow_trail_color", {r, g, b})
end

-- Function to sync arrow trail color with client
function _G.syncArcherArrowTrailColor(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "set_arrow_trail_color", _G.ARCHER_ARROW_TRAIL_COLOR)
end

-- ========================================
-- ATTACK ANIMATION SETUP
-- ========================================

local function setupAttackAnimations(player, tool)
	local character = player.Character
	if not character then return end

	-- Make archer weapon non-collidable when held
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

	-- Attack Animations (from original archer Attack.lua)
	local anim1 = Instance.new("Animation")
	anim1.AnimationId = "rbxassetid://70754044037236"
	local animTrack1 = animator:LoadAnimation(anim1)

	-- Jump Animation (from original archer Archer Animation Script.lua)
	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = "rbxassetid://70438108632909"
	local jumpTrack = animator:LoadAnimation(jumpAnim)
	jumpTrack.Priority = Enum.AnimationPriority.Movement

	-- Jump Attack Animation (from original archer Attack.lua)
	local jumpAttackAnim = Instance.new("Animation")
	jumpAttackAnim.AnimationId = "rbxassetid://73381106980733"
	local jumpAttackTrack = animator:LoadAnimation(jumpAttackAnim)
	jumpAttackTrack.Priority = Enum.AnimationPriority.Action


	-- Block Animation
	local blockAnim = Instance.new("Animation")
	blockAnim.AnimationId = "rbxassetid://116101111905611"
	local blockTrack = animator:LoadAnimation(blockAnim)
	blockTrack.Priority = Enum.AnimationPriority.Action

	-- Note: Wave animation is now handled globally by GlobalAnimations.server.luau

	-- Movement Animations (from original archer Archer Animation Script.lua)
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = "rbxassetid://86837452232042"
	local idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Looped = true
	idleTrack.Priority = Enum.AnimationPriority.Idle

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = "rbxassetid://94263084277064"
	local runTrack = animator:LoadAnimation(runAnim)
	runTrack.Looped = true
	runTrack.Priority = Enum.AnimationPriority.Movement

	-- Store player data
	playerAttackData[player] = {
		animTrack1 = animTrack1,
		jumpTrack = jumpTrack,
		jumpAttackTrack = jumpAttackTrack,
		blockTrack = blockTrack,
		-- Note: waveTrack removed - now handled globally
		idleTrack = idleTrack,
		runTrack = runTrack,
		isAttacking = false,
		isJumping = false,
		isBlocking = false,
		originalWalkSpeed = hum.WalkSpeed
	}

	-- Start with idle animation
	idleTrack:Play()
	_G.applyArcherAnimationSpeed(idleTrack, "idle")

	-- Set walking speed immediately when weapon is equipped
	_G.setArcherWalkingSpeed(player, "normal")

	-- Sync all animation speeds with client
	syncAllAnimationSpeedsWithClient(player)
	
	-- Sync arrow trail color with client
	_G.syncArcherArrowTrailColor(player)

	-- Movement animation handling
	hum.Running:Connect(function(speed)
		local data = playerAttackData[player]
		if not data then return end

		if speed > 1 then -- threshold for running
			if data.idleTrack.IsPlaying then data.idleTrack:Stop() end
			if not data.runTrack.IsPlaying then 
				data.runTrack:Play()
				_G.applyArcherAnimationSpeed(data.runTrack, "run")
			end
		else
			if data.runTrack.IsPlaying then data.runTrack:Stop() end
			if not data.idleTrack.IsPlaying then 
				data.idleTrack:Play()
				_G.applyArcherAnimationSpeed(data.idleTrack, "idle")
			end
		end
	end)

	-- Detect Jump state
	hum.StateChanged:Connect(function(_, newState)
		local data = playerAttackData[player]
		if not data then return end

		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			data.isJumping = true
			-- Play regular jump animation for movement
			if not data.isAttacking then -- Only play if not attacking
				data.jumpTrack:Play()
				_G.applyArcherAnimationSpeed(data.jumpTrack, "jump")
			end
		elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
			data.isJumping = false
			if data.jumpTrack.IsPlaying then
				data.jumpTrack:Stop()
			end
		end
	end)


end

local function cleanupAttackAnimations(player, tool)
	local data = playerAttackData[player]
	if not data then return end

	-- Stop all animations
	if data.animTrack1 then data.animTrack1:Stop() end
	if data.jumpTrack then data.jumpTrack:Stop() end
	if data.jumpAttackTrack then data.jumpAttackTrack:Stop() end
	if data.blockTrack then data.blockTrack:Stop() end
	-- Note: waveTrack removed - now handled globally
	if data.idleTrack then data.idleTrack:Stop() end
	if data.runTrack then data.runTrack:Stop() end

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
-- ARCHER USES SIMPLE SINGLE ATTACK SYSTEM
-- ========================================

-- ========================================
-- ATTACK HANDLERS
-- ========================================

local function handleNormalAttack(player, cameraDirection, aimLockEnabled, isFirstPerson)
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

	local speed = hum.MoveDirection.Magnitude
	local isJumping = data.isJumping

	-- Sync aim lock state to client
	_G.syncAimLockState(player, aimLockEnabled)

	-- Determine shooting direction based on aim lock state (not first-person state)
	local shootDirection
	if aimLockEnabled then
		-- Aim lock enabled (first or third person): use full camera direction (vertical + horizontal)
		shootDirection = cameraDirection or root.CFrame.LookVector
	else
		-- Aim lock disabled (first or third person): use character direction (horizontal only)
		shootDirection = root.CFrame.LookVector
	end

	data.isAttacking = true

	if isJumping then
		-- Jump attack (from original archer Attack.lua)
		-- Stop regular jump animation and play jump attack animation
		if data.jumpTrack.IsPlaying then data.jumpTrack:Stop() end
		data.jumpAttackTrack:Play()
		_G.applyArcherAnimationSpeed(data.jumpAttackTrack, "jumpAttack")

		-- Jump attack projectile (from original archer Attack.lua)
		data.jumpAttackTrack:GetMarkerReachedSignal("Arrow"):Once(function()
			local vfx = ReplicatedStorage.ArcherArrow:WaitForChild("Arrow"):Clone()
			vfx.Parent = workspace

			local root = char:WaitForChild("HumanoidRootPart")

			-- Position sa harap ng player (independent, no weld) - exact v1 positioning
			local spawnOffset = _G.getArrowSpawnOffset(isFirstPerson) -- Configurable spawn offset based on first-person state
			local rotationX = 0 -- ikot pataas/pababa
			local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
			local rotationZ = 0 -- ikot paikot

			local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

			vfx:PivotTo(root.CFrame * CFrame.new(spawnOffset.X, spawnOffset.Y, -spawnOffset.Z) * rotation)

			-- Ensure lahat ng parts ay hindi naka-anchor pero stable and non-physical (if enabled)
			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
						part.CanCollide = false
						part.CanQuery = false
						part.CanTouch = false
					end
				end
			end

			-- Kukunin natin yung main mesh (arrow)
			local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

			-- Calculate actual damage based on player's MaxAttack stat (damage is now a multiplier)
			local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.damage or 0.2
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Archer", damageMultiplier)

			-- Check for Headshot passive (attack x2) - BEFORE creating hitbox
			-- Similar to how crits work: multiply damage by 2 instead of creating two separate hits
			local headshotTriggered = false
			if _G.checkHeadshotPassive then
				local success, result = pcall(function()
					return _G.checkHeadshotPassive(player)
				end)
				if success then
					headshotTriggered = result
				end
			end
			
			-- If Headshot passive triggered, multiply damage by 2 (like crit multiplier)
			-- This creates ONE hit with double damage, not two separate hits
			local finalDamage = actualDamage
			local visualColor = Color3.new(0, 1, 0) -- Green for arrow
			if headshotTriggered then
				-- Double the damage (like crits multiply by critMultiplier/100, but we multiply by 2)
				finalDamage = math.floor(actualDamage * 2)
				-- Use orange/gold color to indicate Headshot triggered
				visualColor = Color3.new(1, 0.8, 0)
			end

			-- Use DynamicHitbox V3 projectile hitbox system (visual and hitbox can have different speeds)
			_G.createProjectileHitbox({
				visualPart = arrow,
				direction = shootDirection,
				size = _G.ARCHER_ARROW_HITBOX.size,
				damage = finalDamage, -- Use final damage (doubled if Headshot triggered)
				character = char,
				name = "JumpArrow",
				visualSpeed = _G.ARCHER_ARROW_HITBOX.visualSpeed,
				hitboxSpeed = _G.ARCHER_ARROW_HITBOX.hitboxSpeed,
				delay = _G.ARCHER_ARROW_HITBOX.delay,
				anchorDelay = _G.ARCHER_ARROW_HITBOX.anchorDelay,
				showVisual = true,
				visualColor = visualColor, -- Use color based on Headshot trigger
				preventPhysicsPush = _G.ARCHER_ARROW_HITBOX.preventPhysicsPush
			})

			-- Auto cleanup
			game:GetService("Debris"):AddItem(vfx, 3)
		end)

		data.jumpAttackTrack.Stopped:Once(function()
			data.isAttacking = false
		end)

	else
		-- Normal attack (from original archer Attack.lua) - single attack, no combo
		data.animTrack1:Play()
		_G.applyArcherAnimationSpeed(data.animTrack1, "normalAttack")

		-- Normal attack projectile (from original archer Attack.lua)
		data.animTrack1:GetMarkerReachedSignal("Arrow"):Once(function()
			local vfx = ReplicatedStorage.ArcherArrow:WaitForChild("Arrow"):Clone()
			vfx.Parent = workspace

			local root = char:WaitForChild("HumanoidRootPart")

			-- Position sa harap ng player (independent, no weld) - exact v1 positioning
			local spawnOffset = _G.getArrowSpawnOffset(isFirstPerson) -- Configurable spawn offset based on first-person state
			local rotationX = 0 -- ikot pataas/pababa
			local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
			local rotationZ = 0 -- ikot paikot

			local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

			vfx:PivotTo(root.CFrame * CFrame.new(spawnOffset.X, spawnOffset.Y, -spawnOffset.Z) * rotation)

			-- Ensure lahat ng parts ay hindi naka-anchor pero stable and non-physical (if enabled)
			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
						part.CanCollide = false
						part.CanQuery = false
						part.CanTouch = false
					end
				end
			end

			-- Kukunin natin yung main mesh (arrow)
			local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

			-- Calculate actual damage based on player's MaxAttack stat (damage is now a multiplier)
			local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.damage or 0.2
			local actualDamage, isCrit = calculateDamageForHitbox(player, "Archer", damageMultiplier)

			-- Check for Headshot passive (attack x2) - BEFORE creating hitbox
			-- Similar to how crits work: multiply damage by 2 instead of creating two separate hits
			local headshotTriggered = false
			if _G.checkHeadshotPassive then
				local success, result = pcall(function()
					return _G.checkHeadshotPassive(player)
				end)
				if success then
					headshotTriggered = result
				end
			end
			
			-- If Headshot passive triggered, multiply damage by 2 (like crit multiplier)
			-- This creates ONE hit with double damage, not two separate hits
			local finalDamage = actualDamage
			local visualColor = Color3.new(0, 1, 0) -- Green for arrow
			if headshotTriggered then
				-- Double the damage (like crits multiply by critMultiplier/100, but we multiply by 2)
				finalDamage = math.floor(actualDamage * 2)
				-- Use orange/gold color to indicate Headshot triggered
				visualColor = Color3.new(1, 0.8, 0)
			end

			-- Use DynamicHitbox V3 projectile hitbox system (visual and hitbox can have different speeds)
			_G.createProjectileHitbox({
				visualPart = arrow,
				direction = shootDirection,
				size = _G.ARCHER_ARROW_HITBOX.size,
				damage = finalDamage, -- Use final damage (doubled if Headshot triggered)
				character = char,
				name = "NormalArrow",
				visualSpeed = _G.ARCHER_ARROW_HITBOX.visualSpeed,
				hitboxSpeed = _G.ARCHER_ARROW_HITBOX.hitboxSpeed,
				delay = _G.ARCHER_ARROW_HITBOX.delay,
				anchorDelay = _G.ARCHER_ARROW_HITBOX.anchorDelay,
				showVisual = true,
				visualColor = visualColor, -- Use color based on Headshot trigger
				preventPhysicsPush = _G.ARCHER_ARROW_HITBOX.preventPhysicsPush
			})

			-- Auto cleanup
			game:GetService("Debris"):AddItem(vfx, 3)
		end)

		data.animTrack1.Stopped:Once(function() 
			data.isAttacking = false 
		end)
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
		_G.applyArcherAnimationSpeed(data.blockTrack, "block")
		_G.setArcherWalkingSpeed(player, "blocking") -- Stop movement while blocking
		-- Update global blocking state for damage reduction
		if _G.setPlayerBlockingState then
			_G.setPlayerBlockingState(player, true)
		end
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal movement
		-- Update global blocking state for damage reduction
		if _G.setPlayerBlockingState then
			_G.setPlayerBlockingState(player, false)
		end
	end
end


-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName, ...)
	local args = {...}

	-- Handle archer-specific attack actions (prefixed with "archer_")
	if actionName == "archer_attack_setup" then
		local tool = args[1]
		setupAttackAnimations(player, tool)
	elseif actionName == "archer_attack_cleanup" then
		local tool = args[1]
		cleanupAttackAnimations(player, tool)
	elseif actionName == "archer_left_click_attack" then
		-- Pass camera direction, aim lock state, and first-person state if provided
		local cameraDirection = args[1]
		local aimLockEnabled = args[2] or false
		local isFirstPerson = args[3] or false
		handleNormalAttack(player, cameraDirection, aimLockEnabled, isFirstPerson)
		-- Note: archer_wave removed - now handled globally by GlobalAnimations.server.luau
	elseif actionName == "archer_block_start" then
		handleBlock(player, true)
	elseif actionName == "archer_block_end" then
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

