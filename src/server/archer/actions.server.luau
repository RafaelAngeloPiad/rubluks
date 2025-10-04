-- ========================================
-- ARCHER ATTACKS SERVER
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
-- 3. Use _G.updateArcherAnimationSpeed(actionType, newSpeed) to update at runtime
--
_G.ARCHER_ANIMATION_SPEEDS = {
	-- Basic movements
	idle = 1.0,
	run = 1.0,
	jump = 1.0,
	
	-- Walking speeds (fixed values, not affected by animation speed)
	walking = {
		normal = 18,    -- Fixed normal walking speed
		slow = 3,       -- Fixed speed during skills
		blocking = 0    -- Fixed speed while blocking
	},
	
	-- Attack animations (archer uses single attack system)
	normalAttack = 1.0,    -- Single normal attack (replaces combo1)
	moveAttack = 1.0,
	jumpAttack = 1.0,
	block = 1.0,
	wave = 1.0,
	
	-- Skills
	piercingShot = 1.0,
	powerShot = 1.0,
	
	-- Buffs
	hunterInstinct = 1.0,
	hunterMark = 1.0,
	
	-- Ultimate
	starfall = 1.0
}

-- Function to apply specific speed to animation track
function _G.applyArcherAnimationSpeed(animTrack, actionType)
	if not animTrack or not actionType then return end
	
	local speed = _G.ARCHER_ANIMATION_SPEEDS[actionType] or 1.0
	animTrack:AdjustSpeed(speed)
end

-- Function to sync specific animation speed with client
local function syncAnimationSpeedWithClient(player, actionType)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	local speed = _G.ARCHER_ANIMATION_SPEEDS[actionType] or 1.0
	remote:FireClient(player, "update_animation_speed", speed, actionType)
end

-- Function to sync all animation speeds with client
local function syncAllAnimationSpeedsWithClient(player)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	for actionType, speed in pairs(_G.ARCHER_ANIMATION_SPEEDS) do
		remote:FireClient(player, "update_animation_speed", speed, actionType)
	end
end

-- Function to update animation speed and sync with all clients
function _G.updateArcherAnimationSpeed(actionType, newSpeed)
	if not actionType or not newSpeed then
		warn("Invalid parameters for updateArcherAnimationSpeed")
		return
	end
	
	-- Update the speed
	_G.ARCHER_ANIMATION_SPEEDS[actionType] = newSpeed
	
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
_G.ARCHER_WALKING_SPEED = {
	normal = 18,    -- Fixed normal walking speed
	slow = 3,       -- Fixed speed during skills
	blocking = 0    -- Fixed speed while blocking
}

-- Function to set player walking speed
function _G.setArcherWalkingSpeed(player, speedType)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local speed = _G.ARCHER_WALKING_SPEED[speedType] or _G.ARCHER_WALKING_SPEED.normal
	humanoid.WalkSpeed = speed
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
_G.ARCHER_COOLDOWNS = {
	-- Skills
	piercingShot = 10, -- 10 seconds cooldown
	powerShot = 8,     -- 8 seconds cooldown
	
	-- Buffs
	hunterInstinct = 15, -- 15 seconds cooldown
	hunterMark = 12,     -- 12 seconds cooldown
	
	-- Ultimate
	starfall = 30       -- 30 seconds cooldown (ultimate)
}

-- Centralized cooldown tracking for all players
local playerCooldowns = {}

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

	-- Move Attack Animation (from original archer Attack.lua)
	local moveSlashAnim = Instance.new("Animation")
	moveSlashAnim.AnimationId = "rbxassetid://92621939945348"
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
		moveSlashTrack = moveSlashTrack,
		blockTrack = blockTrack,
		waveTrack = waveTrack,
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
	if data.jumpTrack then data.jumpTrack:Stop() end
	if data.jumpAttackTrack then data.jumpAttackTrack:Stop() end
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
-- ARCHER USES SIMPLE SINGLE ATTACK SYSTEM
-- ========================================

-- ========================================
-- ATTACK HANDLERS
-- ========================================

local function handleNormalAttack(player, cameraDirection)
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
	
	-- Use camera direction if provided, otherwise fallback to character direction
	local shootDirection = cameraDirection or root.CFrame.LookVector
	
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

			-- Position sa harap ng player (independent, no weld)
			local forwardOffset = 4 -- gaano kalayo sa harap magsimula
			local rotationX = 0 -- ikot pataas/pababa
			local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
			local rotationZ = 0 -- ikot paikot

			local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

			vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -forwardOffset)* rotation)

			-- Ensure lahat ng parts ay hindi naka-anchor pero stable
			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
				end
			end

			-- Kukunin natin yung main mesh (arrow)
			local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

			-- Gagalaw forward gamit BodyVelocity (use camera direction for proper aiming)
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = shootDirection * 120 -- adjust speed
			bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			bodyVelocity.Parent = arrow

			-- Use projectile hitbox system
			_G.createTravelingHitbox({
				attachTo = arrow,
				offset = CFrame.new(0, 0, 0),
				size = Vector3.new(2, 2, 2),
				damage = 5,
				character = char,
				name = "JumpArrow",
				showVisual = true,
				visualColor = Color3.new(0, 1, 0),
				delay = 0
			})

			-- Auto cleanup
			game:GetService("Debris"):AddItem(vfx, 3)
			game:GetService("Debris"):AddItem(bodyVelocity, 2)
		end)
		
		data.jumpAttackTrack.Stopped:Once(function()
			data.isAttacking = false
		end)
		
	elseif speed > 0 then
		-- Move attack (from original archer Attack.lua)
		data.moveSlashTrack:Play()
		_G.applyArcherAnimationSpeed(data.moveSlashTrack, "moveAttack")
		
		-- Move attack projectile (from original archer Attack.lua)
		data.moveSlashTrack:GetMarkerReachedSignal("DashAttack"):Once(function()
			local vfx = ReplicatedStorage.ArcherArrow:WaitForChild("Arrow"):Clone()
			vfx.Parent = workspace

			local root = char:WaitForChild("HumanoidRootPart")

			-- Position sa harap ng player (independent, no weld)
			local forwardOffset = 4 -- gaano kalayo sa harap magsimula
			local rotationX = 0 -- ikot pataas/pababa
			local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
			local rotationZ = 0 -- ikot paikot

			local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

			vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -forwardOffset)* rotation)

			-- Ensure lahat ng parts ay hindi naka-anchor pero stable
			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
				end
			end

			-- Kukunin natin yung main mesh (arrow)
			local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

			-- Gagalaw forward gamit BodyVelocity (use camera direction for proper aiming)
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = shootDirection * 120 -- adjust speed
			bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			bodyVelocity.Parent = arrow

			-- Use projectile hitbox system
			_G.createTravelingHitbox({
				attachTo = arrow,
				offset = CFrame.new(0, 0, 0),
				size = Vector3.new(2, 2, 2),
				damage = 7,
				character = char,
				name = "MoveArrow",
				showVisual = true,
				visualColor = Color3.new(0, 0.8, 1),
				delay = 0
			})

			-- Auto cleanup
			game:GetService("Debris"):AddItem(vfx, 3)
			game:GetService("Debris"):AddItem(bodyVelocity, 2)
			
			-- Dash backwards like original
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(200000, 0, 200000)
			bodyVelocity.Velocity = -root.CFrame.LookVector * 50
			bodyVelocity.Parent = root
			game.Debris:AddItem(bodyVelocity, 0.2)
		end)
		
		data.moveSlashTrack.Stopped:Once(function()
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

			-- Position sa harap ng player (independent, no weld)
			local forwardOffset = 4 -- gaano kalayo sa harap magsimula
			local rotationX = 0 -- ikot pataas/pababa
			local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
			local rotationZ = 0 -- ikot paikot

			local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

			vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -forwardOffset)* rotation)

			-- Ensure lahat ng parts ay hindi naka-anchor pero stable
			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
				end
			end

			-- Kukunin natin yung main mesh (arrow)
			local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

			-- Gagalaw forward gamit BodyVelocity (use camera direction for proper aiming)
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = shootDirection * 120 -- adjust speed
			bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			bodyVelocity.Parent = arrow

			-- Use projectile hitbox system
			_G.createTravelingHitbox({
				attachTo = arrow,
				offset = CFrame.new(0, 0, 0),
				size = Vector3.new(2, 2, 2),
				damage = 1,
				character = char,
				name = "NormalArrow",
				showVisual = true,
				visualColor = Color3.new(1, 0.8, 0),
				delay = 0
			})

			-- Auto cleanup
			game:GetService("Debris"):AddItem(vfx, 3)
			game:GetService("Debris"):AddItem(bodyVelocity, 2)
		end)
		
		data.animTrack1.Stopped:Once(function() 
			data.isAttacking = false 
		end)
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
	_G.applyArcherAnimationSpeed(data.waveTrack, "wave")
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
		_G.applyArcherAnimationSpeed(data.blockTrack, "block")
		_G.setArcherWalkingSpeed(player, "blocking") -- Stop movement while blocking
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal movement
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
	data.jumpAttackTrack:Play()
	_G.applyArcherAnimationSpeed(data.jumpAttackTrack, "jumpAttack")
	data.jumpAttackTrack.Stopped:Once(function()
		data.isAttacking = false
	end)
end

-- ========================================
-- ACTION EVENT HANDLER
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName, ...)
	local args = {...}
	
	-- Handle archer-specific attack actions (prefixed with "archer_")
	if actionName == "archer_attack_setup" then
		setupAttackAnimations(player)
	elseif actionName == "archer_attack_cleanup" then
		cleanupAttackAnimations(player)
	elseif actionName == "archer_left_click_attack" then
		-- Pass camera direction if provided
		local cameraDirection = args[1]
		handleNormalAttack(player, cameraDirection)
	elseif actionName == "archer_wave" then
		handleWave(player)
	elseif actionName == "archer_block_start" then
		handleBlock(player, true)
	elseif actionName == "archer_block_end" then
		handleBlock(player, false)
	elseif actionName == "archer_jump_attack" then
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

