-- Human Melee AI Module
-- Handles pathfinding, animation control, and attack logic for human-style melee mobs

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfigz = require(script.Parent.MobStatsConfigz)
local MobSoundConfig = require(script.Parent.Parent.MobSoundConfig)

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
	attack = "108607323782800",
}

-- Core behaviour tuning
local HUMAN_TAG = "human_melee_entity"
local DEFAULT_VARIANT = "Arabandit_Sand"

local FOLLOW_RANGE = 50
local ATTACK_RANGE = 3
local MAX_RADIUS = 50
local RETURN_RADIUS = 50
local RETURN_WAIT = 2
local UPDATE_RATE = 0.2

local ATTACK_COOLDOWN = 1.4
local POINT_COOLDOWN = 4

local WALK_SPEED_THRESHOLD = 9
local RUN_SPEED_THRESHOLD = 14
local SWIM_SPEED_THRESHOLD = 6
local FLEE_HEALTH_THRESHOLD = 0.3
local FLEE_DISTANCE = 40

local HITBOX_OFFSET = CFrame.new(0, 0, -4)
local HITBOX_SIZE = Vector3.new(8, 8, 8)
local HITBOX_VISUAL_COLOR = Color3.new(1, 0.2, 0.2)

local PLAYER_CONTROL_TAG = "player_transformed"
local PLAYER_ATTACK_ATTRIBUTE = "PlayerAttackRequest"

local function isPlayerControlled(character)
	return CollectionService:HasTag(character, PLAYER_CONTROL_TAG)
end

local function bindPlayerControl(character, humanoid, attackCallback)
	if not isPlayerControlled(character) then
		return false
	end

	humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)

	humanoid:GetAttributeChangedSignal(PLAYER_ATTACK_ATTRIBUTE):Connect(function()
		if not isPlayerControlled(character) then
			return
		end

		if humanoid:GetAttribute(PLAYER_ATTACK_ATTRIBUTE) then
			humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)
			attackCallback()
		end
	end)

	return true
end

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
		warn("[HumanMelee] Failed to load animation", id)
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
		warn("[HumanMelee] Failed to play animation:", err)
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
		warn("[HumanMelee] Failed to stop animation:", err)
	end
end

local function initializeHumanMelee(character, variantName)
	variantName = variantName or DEFAULT_VARIANT

	if not character or not character:IsA("Model") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

	if not humanoid or not root then
		warn("[HumanMelee] Missing humanoid or root part for", character.Name)
		return
	end

	local statsApplied = MobStatsConfigz.applyStats(character, variantName)
	if not statsApplied then
		warn("[HumanMelee] Failed to apply stats for variant:", variantName)
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
	local movementSound = nil
	
	-- Sound helper function
	local function playSound(soundId, shouldLoop)
		if not root or not root.Parent then return nil end
		
		local soundPart = character:FindFirstChild("Head") or root
		if not soundPart then return nil end
		
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0.5
		sound.Looped = shouldLoop or false
		sound.Parent = soundPart
		sound:Play()
		
		if not shouldLoop then
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end
		
		return sound
	end
	
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
			
			-- Play movement sound based on animation
			if movementSound then
				movementSound:Stop()
				movementSound:Destroy()
				movementSound = nil
			end
			
			-- Play movement sound (same for walk and run)
			if track == animations.walk or track == animations.run then
				local moveSoundId = MobSoundConfig.getSound("humanMeleeMove")
				movementSound = playSound(moveSoundId, true)
			end
		end
	end
	
	local function stopMovement()
		if currentMovementTrack then
			stopTrack(currentMovementTrack, 0.1)
			currentMovementTrack = nil
		end
		
		-- Stop movement sound
		if movementSound then
			movementSound:Stop()
			movementSound:Destroy()
			movementSound = nil
		end
	end

	local function unlockMovement()
		movementLocked = false
	end

	if animations.idle then
		setMovementTrack(animations.idle, 0)
	end

	local function spawnAttackHitbox(markerName)
		if not attacking then
			return
		end

		if not _G or not _G.createStaticHitbox then
			return
		end

		local damage = character:GetAttribute("Damage") or 25
		local stats = MobStatsConfigz.getStats(variantName)
		local hitboxName = string.format("HumanMelee_%s", markerName or "Attack")

		local hitboxConfig = {
			attachTo = root,
			offset = HITBOX_OFFSET,
			size = HITBOX_SIZE,
			damage = damage,
			character = character,
			name = hitboxName,
			showVisual = false,
			visualColor = HITBOX_VISUAL_COLOR,
			delay = 0,
		}

		if stats and stats.StatusAilment then
			hitboxConfig.statusAilment = stats.StatusAilment
		end
		if stats and stats.Lifesteal then
			hitboxConfig.lifesteal = stats.Lifesteal
		end

		_G.createStaticHitbox(hitboxConfig)
	end

	local attackTrack = animations.attack
	if attackTrack then
		attackTrack:GetMarkerReachedSignal("slash1"):Connect(function()
			spawnAttackHitbox("slash1")
		end)

		attackTrack:GetMarkerReachedSignal("slash2"):Connect(function()
			spawnAttackHitbox("slash2")
		end)
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
		
		-- Play attack sound
		local attackSoundId = MobSoundConfig.getSound("humanMeleeAttack")
		playSound(attackSoundId, false)

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

	local playerControlled = bindPlayerControl(character, humanoid, playAttack)

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
	
	-- Function to break Motor6Ds so the rig collapses
	local function breakJoints(model)
		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("Motor6D") then
				obj:Destroy()
			end
		end
	end
	
	-- Death handler - integrated from MobDeathHandler
	humanoid.Died:Connect(function()
		-- Stop movement sounds if playing
		if movementSound then
			movementSound:Stop()
			movementSound:Destroy()
			movementSound = nil
		end
		
		-- Play death sound
		local deathSoundId = MobSoundConfig.getSound("humanMeleeDeath")
		playSound(deathSoundId, false)
		
		-- Disable movement/AI scripts
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") then
				child.Disabled = true
			end
		end
		
		-- Make all parts fall naturally and be collidable
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true -- ensure collision so it doesn't fall through map
			end
		end
		
		-- Detach limbs
		breakJoints(character)
		
		-- Wait a few seconds then completely remove from map
		task.wait(3) -- Wait 3 seconds
		
		if character and character.Parent then
			character:Destroy() -- Completely removes the mob from the game
		end
	end)

	if playerControlled then
		return
	end

	local spawnPosition = character:GetPivot().Position
	local timeSinceTarget = 0
	local returningHome = false
	local currentTargetModel = nil
	local currentTargetRoot = nil
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

	local function getClosestTarget()
		if not root or not root.Parent then
			return nil, nil, FOLLOW_RANGE
		end

		local targetModel, targetRoot, _, distance = HitboxExclusions.findClosestHostile(character, root.Position, FOLLOW_RANGE)
		if targetModel and targetRoot then
			return targetModel, targetRoot, distance or FOLLOW_RANGE
		end

		return nil, nil, FOLLOW_RANGE
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
				-- interrupt point or attack animations when switching to flee state
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

			local previousTargetModel = currentTargetModel

			if not returningHome then
				local targetModel, targetRoot, distance = getClosestTarget()

				if targetModel and targetRoot then
					currentTargetModel = targetModel
					currentTargetRoot = targetRoot

					local isNewTarget = previousTargetModel ~= targetModel

					if atSpawn and isNewTarget and not attacking and distance > ATTACK_RANGE and not fleeing then
						playPointAnimation(targetRoot)
					end

					timeSinceTarget = 0
				else
					currentTargetModel = nil
					currentTargetRoot = nil
				end
			end

			if currentTargetRoot and currentTargetModel then
				local targetCharacter = currentTargetModel
				local targetDistance = (currentTargetRoot.Position - position).Magnitude
				local targetDistanceFromSpawn = (currentTargetRoot.Position - spawnPosition).Magnitude

				if targetDistanceFromSpawn > RETURN_RADIUS then
					currentTargetRoot = nil
					currentTargetModel = nil
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

local HumanMeleeAIModule = {}

function HumanMeleeAIModule.initializeHumanMelee(model, variantName)
	initializeHumanMelee(model, variantName)
end

function HumanMeleeAIModule.isInitialized(_model)
	return false
end

return HumanMeleeAIModule


