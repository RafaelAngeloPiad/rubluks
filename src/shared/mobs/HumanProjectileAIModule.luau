-- Human Projectile AI Module
-- Handles pathfinding, animation control, and ranged attack logic for human-style projectile mobs

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local MobStatsConfig = require(script.Parent.MobStatsConfig)

local ArcherArrowFolder = ReplicatedStorage:WaitForChild("ArcherArrow")
local ArrowTemplate = ArcherArrowFolder:WaitForChild("Arrow")

local MobStatsDisplay = nil
pcall(function()
	MobStatsDisplay = require(game.ReplicatedStorage.MobStatsDisplay)
end)

-- Animation asset IDs
local ANIMATION_IDS = {
	idle = "507766666",
	walk = "913402848",
	run = "913376220",
	swim = "913384386",
	swimIdle = "913389285",
	jump = "507765000",
	fall = "507767968",
	climb = "507765644",
	point = "507770453",
	attack = "70754044037236",
}

-- Core behaviour tuning
local HUMAN_TAG = "human_projectile_entity"
local DEFAULT_VARIANT = "Arrabow_Sand"

local FOLLOW_RANGE = 50
local ATTACK_RANGE = 35
local MAX_RADIUS = 50
local RETURN_RADIUS = 50
local RETURN_WAIT = 2
local UPDATE_RATE = 0.2

local ATTACK_COOLDOWN = 1.8
local POINT_COOLDOWN = 4

local WALK_SPEED_THRESHOLD = 9
local RUN_SPEED_THRESHOLD = 14
local SWIM_SPEED_THRESHOLD = 6
local FLEE_HEALTH_THRESHOLD = 0.3
local FLEE_DISTANCE = 40

local HITBOX_VISUAL_COLOR = Color3.new(0, 1, 0)

local DEFAULT_ARROW_OFFSET = Vector3.new(0, 2, -2)

-- Pathfinding configuration
local agentParameters = {
	AgentRadius = 4,
	AgentHeight = 5,
	AgentCanJump = true,
	WaypointSpacing = 4,
}

local function toAssetId(id)
	if type(id) == "number" then
		return "rbxassetid://" .. tostring(id)
	end

	if type(id) == "string" then
		if string.find(id, "rbxassetid://") then
			return id
		end
		return "rbxassetid://" .. id
	end

	return ""
end

local function loadTrack(animator, id, looped, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = toAssetId(id)

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not success or not track then
		warn("[HumanProjectile] Failed to load animation", id)
		return nil
	end

	track.Looped = looped
	track.Priority = priority

	return track
end

local function createAnimationSet(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

	return {
		idle = loadTrack(animator, ANIMATION_IDS.idle, true, Enum.AnimationPriority.Movement),
		walk = loadTrack(animator, ANIMATION_IDS.walk, true, Enum.AnimationPriority.Movement),
		run = loadTrack(animator, ANIMATION_IDS.run, true, Enum.AnimationPriority.Movement),
		swim = loadTrack(animator, ANIMATION_IDS.swim, true, Enum.AnimationPriority.Movement),
		swimIdle = loadTrack(animator, ANIMATION_IDS.swimIdle, true, Enum.AnimationPriority.Movement),
		jump = loadTrack(animator, ANIMATION_IDS.jump, false, Enum.AnimationPriority.Movement),
		fall = loadTrack(animator, ANIMATION_IDS.fall, true, Enum.AnimationPriority.Movement),
		climb = loadTrack(animator, ANIMATION_IDS.climb, true, Enum.AnimationPriority.Movement),
		point = loadTrack(animator, ANIMATION_IDS.point, false, Enum.AnimationPriority.Action),
		attack = loadTrack(animator, ANIMATION_IDS.attack, false, Enum.AnimationPriority.Action),
	}
end

local function playTrack(track, fade)
	if not track then
		return
	end

	local success, err = pcall(function()
		track:Play(fade or 0.1)
	end)

	if not success then
		warn("[HumanProjectile] Failed to play animation:", err)
	end
end

local function stopTrack(track, fade)
	if not track then
		return
	end

	local success, err = pcall(function()
		track:Stop(fade or 0.1)
	end)

	if not success then
		warn("[HumanProjectile] Failed to stop animation:", err)
	end
end

local function getArrowSpawnOffset()
	if _G and _G.getArrowSpawnOffset then
		local ok, offset = pcall(function()
			return _G.getArrowSpawnOffset(false)
		end)
		if ok and offset then
			return offset
		end
	end
	return DEFAULT_ARROW_OFFSET
end

local function getArrowHitboxConfig()
	if _G and _G.ARCHER_ARROW_HITBOX then
		return _G.ARCHER_ARROW_HITBOX
	end

	return {
		size = Vector3.new(2, 2, 6),
		visualSpeed = 180,
		hitboxSpeed = 180,
		delay = 0,
		anchorDelay = 0.2,
		showVisual = false,
		visualColor = HITBOX_VISUAL_COLOR,
		preventPhysicsPush = true,
	}
end

local function initializeHumanProjectile(character, variantName)
	variantName = variantName or DEFAULT_VARIANT

	if not character or not character:IsA("Model") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

	if not humanoid or not root then
		warn("[HumanProjectile] Missing humanoid or root part for", character.Name)
		return
	end

	local statsApplied = MobStatsConfig.applyStats(character, variantName)
	if not statsApplied then
		warn("[HumanProjectile] Failed to apply stats for variant:", variantName)
	end

	CollectionService:AddTag(character, HUMAN_TAG)

	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(character)
	end

	local animations = createAnimationSet(humanoid)

	local currentMovementTrack = nil
	local movementLocked = false
	local isPointing = false
	local attacking = false
	local lastAttackTime = 0
	local lastPointTime = 0
	local fleeing = false

	local currentTargetPlayer = nil
	local currentTargetRoot = nil

	local function setMovementTrack(track, fade)
		if movementLocked then
			return
		end

		if currentMovementTrack == track then
			return
		end

		if currentMovementTrack then
			stopTrack(currentMovementTrack, fade or 0.15)
		end

		currentMovementTrack = track

		if currentMovementTrack then
			playTrack(currentMovementTrack, fade or 0.15)
		end
	end

	local function stopMovement()
		if currentMovementTrack then
			stopTrack(currentMovementTrack, 0.1)
			currentMovementTrack = nil
		end
	end

	local function unlockMovement()
		movementLocked = false
	end

	if animations.idle then
		setMovementTrack(animations.idle, 0)
	end

	local function getProjectileDamage(stats)
		local damage = character:GetAttribute("Damage")
		if damage and damage > 0 then
			return damage
		end

		if stats and stats.Damage then
			return stats.Damage
		end

		return 20
	end

	local function computeProjectileDirection()
		if currentTargetRoot and currentTargetRoot.Parent then
			local direction = currentTargetRoot.Position - root.Position
			if direction.Magnitude > 0.01 then
				return direction.Unit
			end
		end
		return root.CFrame.LookVector
	end

	local function spawnProjectile()
		if not attacking then
			return
		end

		if not _G or not _G.createProjectileHitbox then
			return
		end

		local arrowInstance = ArrowTemplate:Clone()
		arrowInstance.Parent = workspace

		local spawnOffset = getArrowSpawnOffset()
		local rotation = CFrame.Angles(0, math.rad(-90), 0)

		arrowInstance:PivotTo(root.CFrame * CFrame.new(spawnOffset.X, spawnOffset.Y, -spawnOffset.Z) * rotation)

		for _, part in ipairs(arrowInstance:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			end
		end

		local arrowMain = arrowInstance:FindFirstChildWhichIsA("BasePart") or arrowInstance
		local stats = MobStatsConfig.getStats(variantName)
		local damage = getProjectileDamage(stats)
		local direction = computeProjectileDirection()
		local arrowConfig = getArrowHitboxConfig()

		_G.createProjectileHitbox({
			visualPart = arrowMain,
			direction = direction,
			size = arrowConfig.size,
			damage = damage,
			character = character,
			name = "ArrabowArrow",
			visualSpeed = arrowConfig.visualSpeed,
			hitboxSpeed = arrowConfig.hitboxSpeed,
			delay = arrowConfig.delay,
			anchorDelay = arrowConfig.anchorDelay,
			showVisual = false,
			visualColor = HITBOX_VISUAL_COLOR,
			preventPhysicsPush = arrowConfig.preventPhysicsPush,
			statusAilment = stats and stats.StatusAilment or nil,
		})

		Debris:AddItem(arrowInstance, 3)
	end

	local attackTrack = animations.attack
	if attackTrack then
		attackTrack:GetMarkerReachedSignal("Arrow"):Connect(spawnProjectile)
	end

	local function faceCurrentTarget()
		if not currentTargetRoot or not root then
			return
		end

		if not currentTargetRoot.Parent then
			return
		end

		local targetPosition = currentTargetRoot.Position
		local rootPosition = root.Position
		local lookAtPosition = Vector3.new(targetPosition.X, rootPosition.Y, targetPosition.Z)
		if (lookAtPosition - rootPosition).Magnitude > 0.01 then
			root.CFrame = CFrame.lookAt(rootPosition, lookAtPosition)
		end
	end

	local function playAttack()
		if attacking or movementLocked then
			return
		end

		if tick() - lastAttackTime < ATTACK_COOLDOWN then
			return
		end

		if not attackTrack then
			return
		end

		lastAttackTime = tick()
		attacking = true
		movementLocked = true

		stopMovement()
		faceCurrentTarget()

		local connection
		connection = attackTrack.Stopped:Connect(function()
			attacking = false
			movementLocked = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end)

		playTrack(attackTrack, 0.1)
	end

	local function playPointAnimation(targetRoot)
		if isPointing or movementLocked then
			return
		end

		if tick() - lastPointTime < POINT_COOLDOWN then
			return
		end

		local pointTrack = animations.point
		if not pointTrack then
			return
		end
		if targetRoot and root and root.Parent then
			local targetPosition = targetRoot.Position
			local rootPosition = root.Position
			local lookAtPosition = Vector3.new(targetPosition.X, rootPosition.Y, targetPosition.Z)
			if (lookAtPosition - rootPosition).Magnitude > 0.01 then
				root.CFrame = CFrame.lookAt(rootPosition, lookAtPosition)
			end
		end

		isPointing = true
		movementLocked = true
		stopMovement()
		lastPointTime = tick()

		local connection
		connection = pointTrack.Stopped:Connect(function()
			isPointing = false
			movementLocked = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end)

		playTrack(pointTrack, 0.1)
	end

	-- Animation state handlers
	humanoid.Running:Connect(function(speed)
		if movementLocked then
			return
		end

		if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			return
		end

		if speed < 0.1 then
			setMovementTrack(animations.idle)
		elseif speed < RUN_SPEED_THRESHOLD then
			setMovementTrack(animations.walk)
		else
			setMovementTrack(animations.run)
		end
	end)

	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if movementLocked then
			return
		end

		if humanoid.MoveDirection.Magnitude < 0.05 and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
			setMovementTrack(animations.idle)
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		if movementLocked and newState ~= Enum.HumanoidStateType.Dead then
			return
		end

		if newState == Enum.HumanoidStateType.Jumping then
			setMovementTrack(animations.jump, 0.05)
		elseif newState == Enum.HumanoidStateType.Freefall then
			setMovementTrack(animations.fall, 0.1)
		elseif newState == Enum.HumanoidStateType.Climbing then
			setMovementTrack(animations.climb, 0.1)
		elseif newState == Enum.HumanoidStateType.Swimming then
			local speed = humanoid.RootPart and humanoid.RootPart.Velocity.Magnitude or 0
			if speed > SWIM_SPEED_THRESHOLD then
				setMovementTrack(animations.swim, 0.1)
			else
				setMovementTrack(animations.swimIdle, 0.1)
			end
		elseif newState == Enum.HumanoidStateType.Landed then
			setMovementTrack(animations.idle, 0.15)
		elseif newState == Enum.HumanoidStateType.Dead then
			movementLocked = true
			stopMovement()
		end
	end)

	local spawnPosition = character:GetPivot().Position
	local timeSinceTarget = 0
	local returningHome = false
	local pathfindingTo = false
	local pathsCreated = 0
	local pathStarted = false

	local raycastParameters = RaycastParams.new()
	raycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParameters.IgnoreWater = true
	raycastParameters.FilterDescendantsInstances = { character }

	local path = PathfindingService:CreatePath(agentParameters)

	local function blocked(targetPosition, targetCharacter)
		raycastParameters.FilterDescendantsInstances = { character, targetCharacter }
		local direction = targetPosition - root.Position
		local result = workspace:Raycast(root.Position, direction, raycastParameters)
		return result ~= nil
	end

	local function resetNetworkOwner()
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") and not descendant.Anchored then
				descendant:SetNetworkOwner(nil)
			end
		end
	end

	local function stuck()
		raycastParameters.FilterDescendantsInstances = { character }
		local result = workspace:Raycast(root.Position, root.CFrame.LookVector * 1000, raycastParameters)
		if result then
			return (root.Position - result.Position).Magnitude <= 4
		end
		return false
	end

	local function cancelPath()
		pathStarted = false
		pathfindingTo = false
		pathsCreated += 1
	end

	local function pathfindTo(goalPosition, targetPart)
		pathfindingTo = true
		pathStarted = false
		pathsCreated += 1

		local currentPathNumber = pathsCreated

		path:ComputeAsync(root.Position, goalPosition)
		local waypoints = path:GetWaypoints()

		if pathsCreated ~= currentPathNumber then
			return
		end

		pathStarted = true

		for _, waypoint in ipairs(waypoints) do
			if pathsCreated ~= currentPathNumber or not pathStarted then
				break
			end

			if attacking then
				break
			end

			resetNetworkOwner()

			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end

			humanoid:MoveTo(waypoint.Position, targetPart)
			local reached = humanoid.MoveToFinished:Wait()
			if not reached then
				break
			end
		end

		if pathsCreated == currentPathNumber then
			pathfindingTo = false
			pathStarted = false
		end
	end

	local function getClosestPlayer()
		local closestPlayer = nil
		local closestRoot = nil
		local closestDistance = FOLLOW_RANGE

		for _, player in ipairs(Players:GetPlayers()) do
			local playerCharacter = player.Character
			if playerCharacter then
				local playerRoot = playerCharacter:FindFirstChild("HumanoidRootPart")
				local playerHumanoid = playerCharacter:FindFirstChildOfClass("Humanoid")

				if playerRoot and playerHumanoid and playerHumanoid.Health > 0 then
					local distance = (root.Position - playerRoot.Position).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestPlayer = player
						closestRoot = playerRoot
					end
				end
			end
		end

		return closestPlayer, closestRoot, closestDistance
	end

	local function shouldReturnHome(currentPosition)
		return (currentPosition - spawnPosition).Magnitude > MAX_RADIUS
	end

	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			if not character.Parent or not humanoid or humanoid.Health <= 0 then
				break
			end

			if not root or not root.Parent then
				root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
				if not root then
					break
				end
			end

			if attacking then
				humanoid:MoveTo(root.Position)
			end

			local position = root.Position
			local distanceFromSpawn = (position - spawnPosition).Magnitude
			local atSpawn = distanceFromSpawn <= 5

			if returningHome and atSpawn then
				returningHome = false
			end

			local maxHealth = math.max(humanoid.MaxHealth, 1)
			local healthPercent = humanoid.Health / maxHealth
			local shouldFlee = FLEE_HEALTH_THRESHOLD > 0 and healthPercent <= FLEE_HEALTH_THRESHOLD

			if shouldFlee and not fleeing then
				if isPointing and animations.point and animations.point.IsPlaying then
					pcall(function() animations.point:Stop(0.05) end)
				end
				if attacking and attackTrack and attackTrack.IsPlaying then
					pcall(function() attackTrack:Stop(0.05) end)
				end
				isPointing = false
				attacking = false
				movementLocked = false
			end

			fleeing = shouldFlee

			local previousTargetPlayer = currentTargetPlayer

			if not returningHome then
				local player, targetRoot, distance = getClosestPlayer()

				if player and targetRoot then
					currentTargetPlayer = player
					currentTargetRoot = targetRoot

					local isNewTarget = previousTargetPlayer ~= player

					if atSpawn and isNewTarget and not attacking and distance > ATTACK_RANGE and not fleeing then
						playPointAnimation(targetRoot)
					end

					timeSinceTarget = 0
				else
					currentTargetPlayer = nil
					currentTargetRoot = nil
				end
			end

			if currentTargetRoot and currentTargetPlayer then
				local targetCharacter = currentTargetPlayer.Character
				local targetDistance = (currentTargetRoot.Position - position).Magnitude
				local targetDistanceFromSpawn = (currentTargetRoot.Position - spawnPosition).Magnitude

				if targetDistanceFromSpawn > RETURN_RADIUS then
					currentTargetRoot = nil
					currentTargetPlayer = nil
					returningHome = true
					cancelPath()
				elseif fleeing then
					cancelPath()
					returningHome = false
					if not attacking and not isPointing then
						resetNetworkOwner()
						local fleeVector = position - currentTargetRoot.Position
						fleeVector = Vector3.new(fleeVector.X, 0, fleeVector.Z)
						if fleeVector.Magnitude < 1 then
							fleeVector = -root.CFrame.LookVector
							fleeVector = Vector3.new(fleeVector.X, 0, fleeVector.Z)
						end
						if fleeVector.Magnitude > 0 then
							fleeVector = fleeVector.Unit
							local fleeTarget = position + (fleeVector * FLEE_DISTANCE)
							fleeTarget = Vector3.new(fleeTarget.X, spawnPosition.Y, fleeTarget.Z)
							humanoid:MoveTo(fleeTarget)
							setMovementTrack(animations.run, 0.1)
						end
					end
				elseif targetDistance <= ATTACK_RANGE then
					cancelPath()
					if not attacking and not isPointing and not fleeing then
						playAttack()
					end
				else
					if not attacking and not isPointing and not fleeing then
						if blocked(currentTargetRoot.Position, targetCharacter) or stuck() then
							if not pathfindingTo then
								task.spawn(pathfindTo, currentTargetRoot.Position, currentTargetRoot)
							end
						else
							if pathfindingTo then
								cancelPath()
							end
							resetNetworkOwner()
							humanoid:MoveTo(currentTargetRoot.Position, currentTargetRoot)
						end
					end
				end
			else
				timeSinceTarget += UPDATE_RATE
				if timeSinceTarget >= RETURN_WAIT then
					returningHome = true
					timeSinceTarget = 0
				end
			end

			if returningHome then
				if pathfindingTo then
					cancelPath()
				end
				if not attacking then
					resetNetworkOwner()
					humanoid:MoveTo(spawnPosition)
				end
				if atSpawn then
					returningHome = false
					if not currentTargetRoot and not attacking and not isPointing and not fleeing then
						setMovementTrack(animations.idle)
					end
				end
			else
				if not currentTargetRoot and distanceFromSpawn > 5 and not attacking then
					resetNetworkOwner()
					humanoid:MoveTo(spawnPosition)
				elseif not currentTargetRoot and atSpawn and not attacking and not isPointing and not fleeing then
					setMovementTrack(animations.idle)
				end
			end
		end
	end)
end

local HumanProjectileAIModule = {}

function HumanProjectileAIModule.initializeHumanProjectile(model, variantName)
	initializeHumanProjectile(model, variantName)
end

function HumanProjectileAIModule.isInitialized(_model)
	return false
end

return HumanProjectileAIModule


