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
	jumpAttack = 1.0,
	block = 1.0,
	-- Note: Wave is now handled globally by GlobalAnimations.server.luau

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
	piercingShot = 5, -- 10 seconds cooldown
	powerShot = 5,     -- 8 seconds cooldown

	-- Buffs
	hunterInstinct = 5, -- 15 seconds cooldown
	hunterMark = 5,     -- 12 seconds cooldown

	-- Ultimate
	starfall = 5       -- 30 seconds cooldown (ultimate)
}

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

local archerArrowVisualSpeed = 100
local archerArrowHitboxSpeed = archerArrowVisualSpeed - 20

_G.ARCHER_ARROW_HITBOX = {
	delay = 0,           -- Delay before hitbox becomes active (seconds)
	size = Vector3.new(6, 6, 6),  -- Hitbox size for all arrows (increased from 2x2x2)
	damage = 20,         -- Damage for all normal arrows
	visualSpeed = archerArrowVisualSpeed,    -- Visual arrow asset speed (how fast the arrow model moves)
	hitboxSpeed = archerArrowHitboxSpeed,    -- Hitbox detection speed (how fast the hitbox moves for collision detection)
	anchorDelay = 0.03,   -- Delay before arrow gets anchored/sticks after hit detection (seconds) - tweak this for visual alignment
	preventPhysicsPush = true  -- Prevent arrows from pushing objects around (set to false if you want old behavior)
}

-- ========================================
-- ARROW SPAWN OFFSET CONFIGURATION
-- ========================================

-- Unified arrow spawn offsets for easy tweaking
_G.ARCHER_ARROW_SPAWN_OFFSETS = {
	-- First-person mode: offset from camera center
	firstPerson = Vector3.new(0, 0, 2),    -- Forward offset from camera center (adjust Z for distance)
	-- Third-person mode: offset from player body (current spawnOffset)
	thirdPerson = Vector3.new(1, 0, 1),    -- Offset from player body (X=left/right, Y=up/down, Z=forward/back)
}

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
-- SEPARATE ARROW VISUAL AND HITBOX SYSTEM
-- ========================================

-- Function to create arrow with separate visual and hitbox speeds
function _G.createSeparateSpeedArrow(config)
	local arrowPart = config.arrowPart
	local size = config.size
	local damage = config.damage
	local character = config.character
	local name = config.name
	local visualSpeed = config.visualSpeed or _G.ARCHER_ARROW_HITBOX.visualSpeed
	local hitboxSpeed = config.hitboxSpeed or _G.ARCHER_ARROW_HITBOX.hitboxSpeed
	local direction = config.direction
	local delay = config.delay or 0

	if not arrowPart or not direction then
		warn("[ARCHER] Missing arrowPart or direction for separate speed arrow")
		return
	end

	-- Make arrow part completely non-physical to prevent pushing objects (if enabled)
	if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
		arrowPart.CanCollide = false
		arrowPart.CanQuery = false
		arrowPart.CanTouch = false
	end

	-- Apply visual speed to the arrow part
	local visualBodyVelocity = Instance.new("BodyVelocity")
	visualBodyVelocity.Velocity = direction * visualSpeed
	visualBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	visualBodyVelocity.Parent = arrowPart

	-- Create separate invisible hitbox part that moves at hitbox speed
	local hitboxPart = Instance.new("Part")
	hitboxPart.Name = name .. "Hitbox"
	hitboxPart.Size = Vector3.new(1, 1, 1) -- Small part for precise collision
	hitboxPart.Anchored = false
	hitboxPart.CanCollide = false
	hitboxPart.CanQuery = false
	hitboxPart.CanTouch = false
	hitboxPart.Transparency = 1 -- Completely invisible
	hitboxPart.Parent = workspace

	-- Position hitbox at same location as arrow
	hitboxPart.CFrame = arrowPart.CFrame

	-- Apply hitbox speed to the separate hitbox part
	local hitboxBodyVelocity = Instance.new("BodyVelocity")
	hitboxBodyVelocity.Velocity = direction * hitboxSpeed
	hitboxBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	hitboxBodyVelocity.Parent = hitboxPart

	-- Create visual debug hitbox (optional, can be disabled)
	local visual = Instance.new("Part")
	visual.Size = size
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanQuery = false
	visual.CanTouch = false
	visual.Material = Enum.Material.Neon
	visual.Transparency = 1 -- Semi-transparent for debugging
	visual.Color = Color3.new(0, 1, 0) -- Green for arrow hitbox
	visual.Name = name .. "ArrowHitboxVisual"
	visual.Parent = workspace

	-- Start hitbox detection after delay
	task.delay(delay, function()
		local hitTargets = {}
		local arrowStopped = false

		-- Track hitbox part for collisions
		local connection
		connection = game:GetService("RunService").Heartbeat:Connect(function()
			if arrowStopped then
				connection:Disconnect()
				if visual then visual:Destroy() end
				return
			end

			-- Stop if either part is destroyed
			if not arrowPart or not arrowPart.Parent or not hitboxPart or not hitboxPart.Parent then
				arrowStopped = true
				connection:Disconnect()
				if visual then visual:Destroy() end
				if hitboxPart then hitboxPart:Destroy() end
				return
			end

			-- Update visual position to match hitbox
			if visual then
				visual.CFrame = hitboxPart.CFrame
			end

			-- Check for hits at hitbox's current position
			local regionParts = workspace:GetPartBoundsInBox(hitboxPart.CFrame, size)
			local hitSomething = false

			for _, part in regionParts do
				-- Skip the hitbox itself, arrow part, and character parts
				if part ~= hitboxPart and part ~= arrowPart and not part:IsDescendantOf(character) then
					local model = part:FindFirstAncestorOfClass("Model")
					if model and model ~= character then
						local humanoid = model:FindFirstChild("Humanoid")

						-- Check for enemy hit (only collide with living humanoids)
						if humanoid and not hitTargets[humanoid] and humanoid.Health > 0 then
							hitTargets[humanoid] = true
							humanoid:TakeDamage(damage)
							hitSomething = true
						end
						-- Non-humanoid objects are ignored - arrows pass through walls, terrain, etc.
						-- Dead humanoids (health <= 0) are also ignored - arrows pass through them
					end
				end
			end

			-- If we hit something, stop the arrow and stick it
			if hitSomething then
				arrowStopped = true

				-- Flash visual on hit
				if visual then
					visual.Color = Color3.new(1, 0, 0) -- Red flash on hit
					task.delay(0.1, function()
						if visual and visual.Parent then
							visual:Destroy()
						end
					end)
				end

				-- Apply configurable delay before anchoring the arrow for better visual alignment
				local anchorDelay = config.anchorDelay or _G.ARCHER_ARROW_HITBOX.anchorDelay or 0.1
				task.delay(anchorDelay, function()
					-- Stop the arrow's movement and position it at hit location (same as createArrowHitbox)
					if arrowPart and arrowPart.Parent then
						-- Find and destroy any BodyVelocity on the arrow part
						local bodyVelocity = arrowPart:FindFirstChildOfClass("BodyVelocity")
						if bodyVelocity then
							bodyVelocity:Destroy()
						end

						-- Also check the arrow's parent model for BodyVelocity (in case it's on the model)
						if arrowPart.Parent and arrowPart.Parent:IsA("Model") then
							local parentBodyVelocity = arrowPart.Parent:FindFirstChildOfClass("BodyVelocity")
							if parentBodyVelocity then
								parentBodyVelocity:Destroy()
							end
						end

						-- Position arrow at the exact hit location and anchor it
						local hitPosition = hitboxPart.CFrame
						if hitPosition then
							arrowPart.CFrame = hitPosition
						end

						-- Make sure arrow is completely non-physical before anchoring (if enabled)
						if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
							arrowPart.CanCollide = false
							arrowPart.CanQuery = false
							arrowPart.CanTouch = false
						end
						arrowPart.Anchored = true

						-- If the arrow part is inside a model, make sure the model follows it
						if arrowPart.Parent and arrowPart.Parent:IsA("Model") then
							-- Use PrimaryPart to make the model follow this part
							arrowPart.Parent.PrimaryPart = arrowPart
							-- Also make the model non-physical to prevent pushing
							arrowPart.Parent:SetAttribute("NonPhysical", true)
						end
					end

					-- Destroy the separate hitbox part since we're done with collision detection
					if hitboxPart and hitboxPart.Parent then
						hitboxPart:Destroy()
					end
				end)

				connection:Disconnect()
			end
		end)

		-- Auto cleanup after 3 seconds
		task.delay(3, function()
			if not arrowStopped then
				arrowStopped = true
				connection:Disconnect()
				if visual then visual:Destroy() end
				if hitboxPart and hitboxPart.Parent then hitboxPart:Destroy() end
			end
		end)
	end)

	-- Cleanup function
	return function()
		if arrowPart and arrowPart.Parent then arrowPart:Destroy() end
		if hitboxPart and hitboxPart.Parent then hitboxPart:Destroy() end
		if visual and visual.Parent then visual:Destroy() end
	end
end

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
_G.ARCHER_ARROW_TRAIL_COLOR = {255, 255, 255} -- White by default

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

			-- Use separate speed arrow system (visual and hitbox can have different speeds)
			_G.createSeparateSpeedArrow({
				arrowPart = arrow,
				size = _G.ARCHER_ARROW_HITBOX.size,
				damage = _G.ARCHER_ARROW_HITBOX.damage,
				character = char,
				name = "JumpArrow",
				direction = shootDirection,
				visualSpeed = _G.ARCHER_ARROW_HITBOX.visualSpeed,
				hitboxSpeed = _G.ARCHER_ARROW_HITBOX.hitboxSpeed,
				delay = _G.ARCHER_ARROW_HITBOX.delay
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

			-- Use separate speed arrow system (visual and hitbox can have different speeds)
			_G.createSeparateSpeedArrow({
				arrowPart = arrow,
				size = _G.ARCHER_ARROW_HITBOX.size,
				damage = _G.ARCHER_ARROW_HITBOX.damage,
				character = char,
				name = "NormalArrow",
				direction = shootDirection,
				visualSpeed = _G.ARCHER_ARROW_HITBOX.visualSpeed,
				hitboxSpeed = _G.ARCHER_ARROW_HITBOX.hitboxSpeed,
				delay = _G.ARCHER_ARROW_HITBOX.delay
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
	else
		-- Stop blocking
		data.isBlocking = false
		data.blockTrack:Stop()
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal movement
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

