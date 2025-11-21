-- Spider AI Module
-- Simplified animation-based spider controller that relies on animations only

local CollectionService = game:GetService("CollectionService")

local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfigz = require(script.Parent.MobStatsConfigz)
local MobSoundConfig = require(script.Parent.Parent.MobSoundConfig)

local MobStatsDisplay = nil
pcall(function()
	MobStatsDisplay = require(game.ReplicatedStorage.MobStatsDisplay)
end)

local MOVE_ANIMATION_ID = "rbxassetid://73515999132205"
local ATTACK_ANIMATION_ID = "rbxassetid://132697102857784"

local PLAYER_CONTROL_TAG = "player_transformed"
local PLAYER_ATTACK_ATTRIBUTE = "PlayerAttackRequest"

local function isPlayerControlled(enemy)
	return CollectionService:HasTag(enemy, PLAYER_CONTROL_TAG)
end

local function bindPlayerControl(enemy, humanoid, attackCallback)
	if not isPlayerControlled(enemy) then
		return false
	end

	humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)

	humanoid:GetAttributeChangedSignal(PLAYER_ATTACK_ATTRIBUTE):Connect(function()
		if not isPlayerControlled(enemy) then
			return
		end

		if humanoid:GetAttribute(PLAYER_ATTACK_ATTRIBUTE) then
			humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)
			attackCallback()
		end
	end)

	return true
end

local function initializeSpider(enemy, variantName)
	variantName = variantName or "Spider_Sand"

	local statsApplied = MobStatsConfigz.applyStats(enemy, variantName)
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
	local moveSound = nil
	
	-- Sound helper function
	local function playSound(soundId, shouldLoop)
		if not root or not root.Parent then return nil end
		
		local soundPart = enemy:FindFirstChild("Head") or root
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
	
	local function playMovement()
		if movementEnabled and not moveTrack.IsPlaying then
			moveTrack:Play(0.1)
			
			-- Play walking sound
			if not moveSound or not moveSound.IsPlaying then
				local walkSoundId = MobSoundConfig.getSound("spiderMove")
				moveSound = playSound(walkSoundId, true)
			end
		end
	end
	
	local function stopMovement()
		if moveTrack.IsPlaying then
			moveTrack:Stop(0.15)
		end
		
		-- Stop walking sound
		if moveSound then
			moveSound:Stop()
			moveSound:Destroy()
			moveSound = nil
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
				
				-- Play attack sound
				local attackSoundId = MobSoundConfig.getSound("spiderAttack")
				playSound(attackSoundId, false)

				if _G.createStaticHitbox then
					local damage = enemy:GetAttribute("Damage") or 50
					local stats = MobStatsConfigz.getStats(variantName)
					local statusAilment = stats and stats.StatusAilment or nil
					local lifesteal = stats and stats.Lifesteal or nil

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
					if lifesteal then
						hitboxConfig.lifesteal = lifesteal
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

	local playerControlled = bindPlayerControl(enemy, hum, playAttack)
	
	-- Function to break Motor6Ds so the rig collapses
	local function breakJoints(model)
		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("Motor6D") then
				obj:Destroy()
			end
		end
	end
	
	-- Death handler - integrated from MobDeathHandler
	hum.Died:Connect(function()
		-- Stop movement sounds if playing
		if moveSound then
			moveSound:Stop()
			moveSound:Destroy()
			moveSound = nil
		end
		
		-- Play death sound
		local deathSoundId = MobSoundConfig.getSound("spiderDeath")
		playSound(deathSoundId, false)
		
		-- Disable movement/AI scripts
		for _, child in ipairs(enemy:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") then
				child.Disabled = true
			end
		end
		
		-- Make all parts fall naturally and be collidable
		for _, part in ipairs(enemy:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true -- ensure collision so it doesn't fall through map
			end
		end
		
		-- Detach limbs
		breakJoints(enemy)
		
		-- Wait a few seconds then completely remove from map
		task.wait(3) -- Wait 3 seconds
		
		if enemy and enemy.Parent then
			enemy:Destroy() -- Completely removes the mob from the game
		end
	end)

	local function findClosestPlayer(position)
		local nearest
		local nearestDist = spottingRadius

		for _, candidate in ipairs(workspace:GetChildren()) do
		if candidate:IsA("Model") and candidate ~= enemy then
				local hrp = candidate:FindFirstChild("HumanoidRootPart")
				local candidateHum = candidate:FindFirstChild("Humanoid")

				if hrp and candidateHum and candidateHum.Health > 0 then
				if HitboxExclusions.shouldAttack(enemy, candidate) then
					local distance = (hrp.Position - position).Magnitude
					if distance < nearestDist then
						nearestDist = distance
						nearest = hrp
					end
					end
				end
			end
		end

		return nearest
	end

	if not playerControlled then
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
end

local SpiderAIModule = {}

function SpiderAIModule.initializeSpider(model, variantName)
	initializeSpider(model, variantName)
end

function SpiderAIModule.isInitialized(_model)
	return false
end

return SpiderAIModule

