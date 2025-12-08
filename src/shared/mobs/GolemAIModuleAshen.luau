-- Golem AI Module
-- Centralized AI logic that can be called from anywhere

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local BGMusic = SoundService:WaitForChild("BGMusic")
local BossMusic = SoundService:WaitForChild("BossMusic")
local VictoryBG = SoundService:WaitForChild("VictoryFanfare")
local BossDefeatedEvent = ReplicatedStorage:WaitForChild("BossDefeatedEvent")

-- Import global exclusions
local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfigz = require(script.Parent.MobStatsConfigz)
local MobSoundConfig = require(script.Parent.Parent.MobSoundConfig)

-- Try to require MobStatsDisplay module
local MobStatsDisplay = nil
local success, displayModule = pcall(function()
	return require(game.ReplicatedStorage.MobStatsDisplay)
end)
if success then
	MobStatsDisplay = displayModule
end

-- === CONFIG ===
local WALK_ANIMATION_ID = "rbxassetid://107172094908325" -- walk
local ATTACK_ANIMATION_ID = "rbxassetid://128682464782625" -- replace with your attack anim ID
local ATTACK_RANGE = 8             -- distance at which attack animation starts
local FOLLOW_RANGE = 300
local MAX_RADIUS = 40
local RETURN_RADIUS = 60
local UPDATE_RATE = 0.4
local RETURN_WAIT = 2
local WALK_SPEED_SCALE = 16
local MIN_WALK_SPEED = 0.5
local STOP_DELAY = 0.25

local PLAYER_CONTROL_TAG = "player_transformed"
local PLAYER_ATTACK_ATTRIBUTE = "PlayerAttackRequest"

local function isPlayerControlled(monster)
	return CollectionService:HasTag(monster, PLAYER_CONTROL_TAG)
end

local function bindPlayerControl(monster, humanoid, attackCallback)
	if not isPlayerControlled(monster) then
		return false
	end

	humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)

	humanoid:GetAttributeChangedSignal(PLAYER_ATTACK_ATTRIBUTE):Connect(function()
		if not isPlayerControlled(monster) then
			return
		end

		if humanoid:GetAttribute(PLAYER_ATTACK_ATTRIBUTE) then
			humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)
			attackCallback()
		end
	end)

	return true
end

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
local function FindNearestTarget(monster, origin)
	local targetModel, targetRoot = HitboxExclusions.findClosestHostile(monster, origin, FOLLOW_RANGE)
	if targetModel and targetRoot then
		return targetRoot
	end
	return nil
end

-- === GOLEM INITIALIZATION ===
local function initializeGolem(monster, variantName)
	-- Use model reference as unique identifier
	local golemId = monster
	
	-- Default variant if not provided
	variantName = variantName or "Golem_Sand"
	
	-- Apply stats to the golem (sets attributes for DynamicHitboxV3 defense system)
	-- NOTE: Stats are applied BEFORE anything else so defense/health work correctly
	local statsApplied = MobStatsConfigz.applyStats(monster, variantName)
	if not statsApplied then
		warn("Golem: Failed to apply stats for variant:", variantName)
	end
	
	local humanoid = monster:WaitForChild("Humanoid")
	local root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
	
	if not root then
		warn("Golem missing HumanoidRootPart:", monster.Name)
		return
	end
	
	-- Add exclusion tag so golems don't damage each other
	CollectionService:AddTag(monster, "golem_entity")
	
	-- Create floating stats display GUI (if enabled in config)
	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(monster)
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
	local walkSound = nil
	
	-- Sound helper function
	local function playSound(soundId, shouldLoop)
		if not root or not root.Parent then return nil end
		
		local soundPart = monster:FindFirstChild("Head") or root
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
	
	-- Animation functions for this golem
	local function playWalk()
		if not isWalking then
			isWalking = true
			pcall(function() walkTrack:Play(0.15) end)
			
			-- Play walking sound
			if not walkSound or not walkSound.IsPlaying then
				local walkSoundId = MobSoundConfig.getSound("golemMove")
				walkSound = playSound(walkSoundId, true)
			end
		end
	end
	
	-- Emergency attack reset function
	local function forceResetAttack()
		if attacking then
			warn("Force resetting golem attack!")
			attacking = false
			pcall(function()
				if attackTrack.IsPlaying then
					attackTrack:Stop(0)
				end
			end)
		end
	end
	
	local function stopWalk()
		if isWalking then
			isWalking = false
			pcall(function() walkTrack:Stop(0.15) end)
			
			-- Stop walking sound
			if walkSound then
				walkSound:Stop()
				walkSound:Destroy()
				walkSound = nil
			end
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
					
					-- Play attack sound
					local attackSoundId = MobSoundConfig.getSound("golemAttack")
					playSound(attackSoundId, false)
					
					-- Create static hitbox when attack animation plays
					if _G.createStaticHitbox then
						-- Get damage from mob's attribute
						local damage = monster:GetAttribute("Damage") or 25
						
						-- Get status ailment config from MobStatsConfigz
						local stats = MobStatsConfigz.getStats(variantName)
						local statusAilment = stats and stats.StatusAilment or nil
						local lifesteal = stats and stats.Lifesteal or nil
						
						local hitboxConfig = {
							attachTo = root,
							offset = CFrame.new(0, 0, -4), -- Hitbox in front of golem
							size = Vector3.new(8, 8, 8), -- 8x8x8 stud hitbox
							damage = damage,
							character = monster, -- Exclude the golem itself
							name = "GolemAttack",
							showVisual = false,
							visualColor = Color3.new(1, 0.5, 0), -- Orange color
							delay = 0.3, -- Delay to sync with animation
							visualDuration = 0.8
						}
						
						-- Add status ailment if configured
						if statusAilment then
							hitboxConfig.statusAilment = statusAilment
						end
						if lifesteal then
							hitboxConfig.lifesteal = lifesteal
						end
						
						_G.createStaticHitbox(hitboxConfig)
					end
					
					-- Wait for animation to stop with timeout (same as spider)
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
						
						-- Check if golem is still alive and active in workspace
						if not monster.Parent or not monster:IsDescendantOf(workspace) or not humanoid or humanoid.Health <= 0 then
							break
						end
					end
					
					-- Cleanup connection
					if stopConnection then
						stopConnection:Disconnect()
					end
				end)
				
				-- Always reset attacking state
				attacking = false
			end)()
		end
	end

	local playerControlled = bindPlayerControl(monster, humanoid, playAttack)
	
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
		if walkSound then
			walkSound:Stop()
			walkSound:Destroy()
			walkSound = nil
		end
		
		-- Play death sound
		local deathSoundId = MobSoundConfig.getSound("golemDeath")
		playSound(deathSoundId, false)
		
		-- Disable movement/AI scripts
		for _, child in ipairs(monster:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") then
				child.Disabled = true
			end
		end
		
		-- Make all parts fall naturally and be collidable
		for _, part in ipairs(monster:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true -- ensure collision so it doesn't fall through map
			end
		end
		
		-- Detach limbs
		breakJoints(monster)
		
		BossMusic:Stop()
		-- Wait a few seconds then completely remove from map
		task.wait(3) -- Wait 3 seconds bago mag victory
		
		VictoryBG:Play()
		for _, player in pairs(game.Players:GetPlayers()) do
			BossDefeatedEvent:FireClient(player)
		end
		
		task.wait(8) -- wait 8 seconds para di sabay sa victory sounds
		
		BGMusic:Play()
		
		if monster and monster.Parent then
			monster:Destroy() -- Completely removes the mob from the game
		end
	end)

	if playerControlled then
		humanoid.Running:Connect(function(speed)
			if attacking then
				if speed <= MIN_WALK_SPEED then
					stopWalk()
				end
				return
			end

			if speed > MIN_WALK_SPEED then
				playWalk()
				setWalkSpeed(speed)
			else
				stopWalk()
			end
		end)

		return
	end
	
	-- Main AI loop for this golem
	task.spawn(function()
		while task.wait(UPDATE_RATE) do
			-- Check if model still exists, is in workspace, or golem died
			if not monster.Parent or not monster:IsDescendantOf(workspace) or not humanoid or humanoid.Health <= 0 then 
				break 
			end
			if not root then root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart end
			if not root then continue end

			-- Safety check: reset attacking state if stuck for too long
			if attacking and tick() - lastAttackTime > 3 then
				forceResetAttack()
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
				-- Check if current target is still valid (alive and in range)
				if target then
					local targetModel = target:FindFirstAncestorOfClass("Model")
					local targetHum = targetModel and targetModel:FindFirstChild("Humanoid")
					-- Invalidate target if it died or is too far
					local stillValid = targetModel and HitboxExclusions.shouldAttack(monster, targetModel)
					if not targetHum or targetHum.Health <= 0 or (target.Position - position).Magnitude > FOLLOW_RANGE or not stillValid then
						target = nil
						currentTarget = nil
					end
				end
				
				-- Find new target if needed
				if not target then
					target = FindNearestTarget(monster, position)
					currentTarget = target
				end

				if target then
					local targetDist = (target.Position - position).Magnitude
					local targetDistFromSpawn = (target.Position - spawnPosition).Magnitude

					if targetDistFromSpawn <= RETURN_RADIUS then
						-- Attack or follow
						if targetDist <= ATTACK_RANGE and not attacking then
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

function GolemAIModule.initializeGolem(model, variantName)
	initializeGolem(model, variantName)
end

function GolemAIModule.isInitialized(model)
	-- Always return false since we don't track initialization
	-- Each model has its own initializer that only runs once
	return false
end

return GolemAIModule
