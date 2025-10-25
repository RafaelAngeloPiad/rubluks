-- Golem AI Module
-- Centralized AI logic that can be called from anywhere

-- Import global exclusions
local HitboxExclusions = require(script.Parent.HitboxExclusions)

-- === CONFIG ===
local WALK_ANIMATION_ID = "rbxassetid://107172094908325" -- walk
local ATTACK_ANIMATION_ID = "rbxassetid://128682464782625" -- replace with your attack anim ID
local ATTACK_RANGE = 8             -- distance at which attack animation starts
local FOLLOW_RANGE = 100
local MAX_RADIUS = 40
local RETURN_RADIUS = 60
local UPDATE_RATE = 0.4
local RETURN_WAIT = 2
local WALK_SPEED_SCALE = 16
local MIN_WALK_SPEED = 0.5
local STOP_DELAY = 0.25
-- === TRACKING ===
-- No need for tracking since each model has its own initializer

-- === ANIMATION FUNCTIONS ===
local function createAnimations(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	
	local walkAnim = Instance.new("Animation")
	walkAnim.AnimationId = WALK_ANIMATION_ID
	local walkTrack = animator:LoadAnimation(walkAnim)
	walkTrack.Looped = true
	walkTrack.Priority = Enum.AnimationPriority.Core
	
	local attackAnim = Instance.new("Animation")
	attackAnim.AnimationId = ATTACK_ANIMATION_ID
	local attackTrack = animator:LoadAnimation(attackAnim)
	attackTrack.Looped = false
	attackTrack.Priority = Enum.AnimationPriority.Action
	
	return walkTrack, attackTrack
end

-- === HELPERS ===
local function HasAnyExcludedTag(model)
	return HitboxExclusions.hasExcludedTag(model)
end

local function FindNearestTarget(origin)
	local nearest, nearestDist = nil, FOLLOW_RANGE
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and not HasAnyExcludedTag(model) then
			local root = model:FindFirstChild("HumanoidRootPart")
			local hum = model:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = (root.Position - origin).Magnitude
				if dist < nearestDist then
					nearest = root
					nearestDist = dist
				end
			end
		end
	end
	return nearest
end

-- === GOLEM INITIALIZATION ===
local function initializeGolem(monster)
	-- Use model reference as unique identifier
	local golemId = monster
	
	
	local humanoid = monster:WaitForChild("Humanoid")
	local root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
	
	if not root then
		warn("Golem missing HumanoidRootPart:", monster.Name)
		return
	end
	
	-- Create animations
	local walkTrack, attackTrack = createAnimations(humanoid)
	
	-- Setup ragdoll disable
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false
		end
	end)
	
	-- Internal variables for this golem
	local spawnPosition = monster:GetPivot().Position
	local currentTarget = nil
	local timeSinceTarget = 0
	local lastMoveTick = 0
	local returningHome = false
	local attacking = false
	local isWalking = false
	local lastAttackTime = 0
	
	-- Animation functions for this golem
	local function playWalk()
		if not isWalking then
			isWalking = true
			pcall(function() walkTrack:Play(0.15) end)
		end
	end
	
	local function stopWalk()
		if isWalking then
			isWalking = false
			pcall(function() walkTrack:Stop(0.15) end)
		end
	end
	
	local function setWalkSpeed(speed)
		pcall(function() walkTrack:AdjustSpeed(math.clamp(speed / WALK_SPEED_SCALE, 0.1, 2)) end)
	end
	
	local function playAttack()
		if not attacking then
			attacking = true
			lastAttackTime = tick() -- Track when attack started
			stopWalk()
			if root then
				root.Velocity = Vector3.new(0, 0, 0)
			end
			humanoid:MoveTo(root.Position)
			humanoid.PlatformStand = false
			
			-- Use coroutine to handle attack with timeout
			coroutine.wrap(function()
				pcall(function()
					attackTrack:Play(0.1)
					
					-- Create static hitbox when attack animation plays
					if _G.createStaticHitbox then
						_G.createStaticHitbox({
							attachTo = root,
							offset = CFrame.new(0, 0, -4), -- Hitbox in front of golem
							size = Vector3.new(8, 8, 8), -- 8x8x8 stud hitbox
							damage = 25, -- Adjust damage as needed
							character = monster, -- Exclude the golem itself
							name = "GolemAttack",
							showVisual = true,
							visualColor = Color3.new(1, 0.5, 0), -- Orange color
							delay = 0.3, -- Delay to sync with animation
							visualDuration = 0.8
						})
					end
					
					-- Wait for animation to stop with timeout
					local animationStopped = false
					local timeout = 0
					local maxTimeout = 3 -- 3 second timeout
					
					-- Listen for animation stop
					local stopConnection
					stopConnection = attackTrack.Stopped:Connect(function()
						animationStopped = true
						if stopConnection then
							stopConnection:Disconnect()
						end
					end)
					
					-- Wait for either animation stop or timeout
					while not animationStopped and timeout < maxTimeout do
						task.wait(0.1)
						timeout = timeout + 0.1
						
						-- Check if golem is still alive and in workspace
						if not monster.Parent or monster.Parent ~= workspace or not humanoid or humanoid.Health <= 0 then
							break
						end
					end
					
					-- Cleanup
					if stopConnection then
						stopConnection:Disconnect()
					end
					
					-- Force stop animation if it's still playing
					if attackTrack.IsPlaying then
						attackTrack:Stop(0.1)
					end
				end)
				
				-- Always reset attacking state
				attacking = false
			end)()
		end
	end
	
	-- Main AI loop for this golem
	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			-- Check if model still exists, is in workspace, or golem died
			if not monster.Parent or monster.Parent ~= workspace or not humanoid or humanoid.Health <= 0 then 
				break 
			end
			if not root then root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart end
			if not root then continue end

			-- Safety check: reset attacking state if stuck for too long
			if attacking and tick() - lastAttackTime > 5 then
				attacking = false
				if attackTrack.IsPlaying then
					attackTrack:Stop(0.1)
				end
			end

			local position = root.Position
			local distFromSpawn = (position - spawnPosition).Magnitude

			-- Return logic
			if returningHome then
				if distFromSpawn <= MAX_RADIUS * 0.8 then
					returningHome = false
				else
					if not attacking then
						humanoid:MoveTo(spawnPosition)
					end
				end
			else
				local target = currentTarget
				if not target or (target.Position - position).Magnitude > FOLLOW_RANGE then
					target = FindNearestTarget(position)
					currentTarget = target
				end

				if target then
					local targetDist = (target.Position - position).Magnitude
					local targetDistFromSpawn = (target.Position - spawnPosition).Magnitude

					if targetDistFromSpawn <= RETURN_RADIUS then
						-- Attack or follow
						if targetDist <= ATTACK_RANGE then
							stopWalk()
							playAttack()
						else
							if not attacking then
								humanoid:MoveTo(target.Position)
								playWalk()
								setWalkSpeed(humanoid.WalkSpeed)
							end
						end
						timeSinceTarget = 0
					else
						-- Target too far, return home
						currentTarget = nil
						returningHome = true
						if not attacking then
							humanoid:MoveTo(spawnPosition)
						end
					end
				else
					timeSinceTarget += UPDATE_RATE
					if timeSinceTarget >= RETURN_WAIT then
						returningHome = true
						if not attacking then
							humanoid:MoveTo(spawnPosition)
						end
						timeSinceTarget = 0
					end
				end
			end

			-- Walk stop detection
			local speed = (root.Velocity * Vector3.new(1, 0, 1)).Magnitude
			if speed > MIN_WALK_SPEED then
				lastMoveTick = tick()
				if not attacking then playWalk() end
				setWalkSpeed(speed)
			elseif tick() - lastMoveTick > STOP_DELAY and not attacking then
				stopWalk()
			end
		end
	end)
end

-- === MODULE EXPORTS ===
local GolemAIModule = {}

function GolemAIModule.initializeGolem(model)
	initializeGolem(model)
end

function GolemAIModule.isInitialized(model)
	-- Always return false since we don't track initialization
	-- Each model has its own initializer that only runs once
	return false
end

return GolemAIModule
