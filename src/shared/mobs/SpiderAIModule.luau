-- Spider AI Module
-- Simplified animation-based spider controller that relies on animations only

local CollectionService = game:GetService("CollectionService")

local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfig = require(script.Parent.MobStatsConfig)

local MobStatsDisplay = nil
pcall(function()
	MobStatsDisplay = require(game.ReplicatedStorage.MobStatsDisplay)
end)

local MOVE_ANIMATION_ID = "rbxassetid://108903327900347"
local ATTACK_ANIMATION_ID = "rbxassetid://132697102857784"

local function initializeSpider(enemy, variantName)
	variantName = variantName or "Spider_Sand"

	local statsApplied = MobStatsConfig.applyStats(enemy, variantName)
	if not statsApplied then
		warn("Spider: Failed to apply stats for variant:", variantName)
	end

	local root = enemy:WaitForChild("HumanoidRootPart")
	local hum = enemy:WaitForChild("Humanoid")

	CollectionService:AddTag(enemy, "spider_entity")

	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(enemy)
	end

	local spawnPosition = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
	local spottingRadius = 40
	local attackRange = 8
	local maxRadius = 200

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

	local moveAnim = Instance.new("Animation")
	moveAnim.AnimationId = MOVE_ANIMATION_ID
	local moveTrack = animator:LoadAnimation(moveAnim)
	moveTrack.Priority = Enum.AnimationPriority.Movement
	moveTrack.Looped = true

	local attackAnim = Instance.new("Animation")
	attackAnim.AnimationId = ATTACK_ANIMATION_ID
	local attackTrack = animator:LoadAnimation(attackAnim)
	attackTrack.Priority = Enum.AnimationPriority.Action
	attackTrack.Looped = false

	local attacking = false
	local attackCooldown = 0.5
	local lastAttackTime = 0
	local movementEnabled = true
	local lastRunningSpeed = 0

	local function playMovement()
		if movementEnabled and not moveTrack.IsPlaying then
			moveTrack:Play(0.1)
		end
	end

	local function stopMovement()
		if moveTrack.IsPlaying then
			moveTrack:Stop(0.15)
		end
	end

	local function handleRunning(speed)
		lastRunningSpeed = speed or 0

		if not movementEnabled then
			stopMovement()
			return
		end

		if lastRunningSpeed > 0.1 then
			playMovement()
		else
			stopMovement()
		end
	end

	local runningConnection = hum.Running:Connect(handleRunning)
	handleRunning(0)

	local function cleanupConnections()
		if runningConnection then
			runningConnection:Disconnect()
			runningConnection = nil
		end
	end

	local function playAttack()
		if attacking then
			return
		end

		attacking = true
		lastAttackTime = tick()
		movementEnabled = false
		stopMovement()

		coroutine.wrap(function()
			local animationStopped = false
			local stopConnection

			local success, err = pcall(function()
				attackTrack:Play(0.1)

				if _G.createStaticHitbox then
					local damage = enemy:GetAttribute("Damage") or 50
					local stats = MobStatsConfig.getStats(variantName)
					local statusAilment = stats and stats.StatusAilment or nil

					local hitboxConfig = {
						attachTo = root,
						offset = CFrame.new(0, 0, -3),
						size = Vector3.new(6, 6, 6),
						damage = damage,
						character = enemy,
						name = "SpiderAttack",
						showVisual = false,
						visualColor = Color3.new(0.8, 0, 0.8),
						delay = 0.2,
						visualDuration = 0.6,
					}

					if statusAilment then
						hitboxConfig.statusAilment = statusAilment
					end

					_G.createStaticHitbox(hitboxConfig)
				end

				stopConnection = attackTrack.Stopped:Connect(function()
					animationStopped = true
				end)

				local timeout = 0
				local maxTimeout = 3

				while not animationStopped and timeout < maxTimeout do
					task.wait(0.1)
					timeout += 0.1

					if not enemy.Parent or not enemy:IsDescendantOf(workspace) or not hum or hum.Health <= 0 then
						break
					end
				end
			end)

			if stopConnection then
				stopConnection:Disconnect()
			end

			if attackTrack.IsPlaying then
				attackTrack:Stop(0.1)
			end

			if not success then
				warn("Spider attack failed:", err)
			end

			task.wait(attackCooldown)

			movementEnabled = true
			attacking = false
			handleRunning(lastRunningSpeed)
		end)()
	end

	local function hasAnyExcludedTag(model)
		return HitboxExclusions.hasExcludedTag(model)
	end

	local function findClosestPlayer(position)
		local nearest
		local nearestDist = spottingRadius

		for _, candidate in ipairs(workspace:GetChildren()) do
			if candidate:IsA("Model") and candidate ~= enemy and not hasAnyExcludedTag(candidate) then
				local hrp = candidate:FindFirstChild("HumanoidRootPart")
				local candidateHum = candidate:FindFirstChild("Humanoid")

				if hrp and candidateHum and candidateHum.Health > 0 then
					local distance = (hrp.Position - position).Magnitude
					if distance < nearestDist then
						nearestDist = distance
						nearest = hrp
					end
				end
			end
		end

		return nearest
	end

	coroutine.wrap(function()
		while task.wait(0.25) do
			if not enemy.Parent or not enemy:IsDescendantOf(workspace) or not hum or hum.Health <= 0 then
				cleanupConnections()
				break
			end

			if attacking and tick() - lastAttackTime > 5 then
				attacking = false
				movementEnabled = true
				if attackTrack.IsPlaying then
					attackTrack:Stop(0.1)
				end
				handleRunning(lastRunningSpeed)
			end

			local currentPosition = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
			local distanceFromSpawn = (currentPosition - spawnPosition).Magnitude
			local target = findClosestPlayer(currentPosition)

			if distanceFromSpawn > maxRadius then
				hum:MoveTo(spawnPosition)
			elseif target then
				local targetDistance = (target.Position - currentPosition).Magnitude

				if targetDistance <= attackRange then
					hum:MoveTo(root.Position)
					playAttack()
				elseif not attacking then
					hum:MoveTo(target.Position, target)
				end
			end
		end
	end)()
end

local SpiderAIModule = {}

function SpiderAIModule.initializeSpider(model, variantName)
	initializeSpider(model, variantName)
end

function SpiderAIModule.isInitialized(_model)
	return false
end

return SpiderAIModule

