-- Wraith AI Module
-- Simple: Just looks at player, stays in place, shoots homing projectiles with burn

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

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
local DETECTION_RANGE = 20
local ATTACK_COOLDOWN = 2  -- Seconds between attacks
local MISSILE_SPEED = 20   -- Speed of the homing projectile
local MISSILE_LIFETIME = 1 -- Seconds before missile despawns
local FLOAT_HEIGHT = 5  -- Height in studs to float above ground
local FLOAT_SPEED = 0.08  -- Lerp speed (0.08 = smooth, low performance)

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

-- === HELPERS ===
-- === WRAITH INITIALIZATION ===
local function initializeWraith(wraith, variantName)
	-- Default variant if not provided
	variantName = variantName or "Wraith_Sand"
	
	-- Apply stats to the wraith
	local statsApplied = MobStatsConfigz.applyStats(wraith, variantName)
	if not statsApplied then
		warn("Wraith: Failed to apply stats for variant:", variantName)
	end
	
	local humanoid = wraith:WaitForChild("Humanoid")
	local root = wraith:FindFirstChild("HumanoidRootPart") or wraith.PrimaryPart
	
	if not root then
		warn("Wraith missing HumanoidRootPart:", wraith.Name)
		return
	end
	
	-- Ensure root is set as PrimaryPart
	wraith.PrimaryPart = root
	
	-- Find Head and Fire parts
	local head = wraith:FindFirstChild("Head")
	local fire = head and head:FindFirstChild("Fire") or head and head:FindFirstChildOfClass("Fire")
	
	if not head then
		warn("Wraith missing Head part:", wraith.Name)
		return
	end
	
	if not fire then
		warn("Wraith missing Fire in Head:", wraith.Name)
	end
	
	-- Add exclusion tag so wraiths don't damage each other
	CollectionService:AddTag(wraith, "wraith_entity")
	
	-- Create floating stats display GUI
	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(wraith)
	end
	
	-- Store original ground Y position
	local groundY = root.Position.Y
	local currentY = groundY
	local targetY = groundY
	
	-- Initialize fire as off
	if fire then
		fire.Enabled = false
	end
	
	-- Get stats for damage and status ailment
	local stats = MobStatsConfigz[variantName] or MobStatsConfigz.Wraith_Sand
	if not stats then
		warn("Wraith: Invalid variant name, using default:", variantName)
		stats = MobStatsConfigz.Wraith_Sand
	end
	local damage = stats.Damage or 25
	local statusAilment = stats.StatusAilment
	local lifesteal = stats.Lifesteal
	
	-- Wait for hitbox functions to be available
	while not _G.createTravelingHitbox do
		task.wait(0.1)
	end
	
	-- Attack tracking
	local lastAttack = 0
	local currentTarget = nil
	local currentTargetModel = nil
	
	-- Sound helper function
	local function playSound(soundId, shouldLoop)
		if not root or not root.Parent then return nil end
		
		local soundPart = wraith:FindFirstChild("Head") or root
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
	
	-- Function to shoot homing projectile
	local function shootHomingProjectile(target, launchDirection)
		local resolvedTarget = target
		if resolvedTarget and not resolvedTarget.Parent then
			resolvedTarget = nil
		end

		local direction = nil
		if resolvedTarget then
			direction = (resolvedTarget.Position - root.Position)
		elseif launchDirection then
			direction = launchDirection
		else
			direction = root.CFrame.LookVector
		end

		if not direction or direction.Magnitude < 0.05 then
			direction = Vector3.new(0, 0, -1)
		end

		direction = direction.Unit
		
		-- Play attack sound
		local attackSoundId = MobSoundConfig.getSound("wraithAttack")
		playSound(attackSoundId, false)

		-- Create missile part
		local missile = Instance.new("Part")
		missile.Name = "WraithHomingMissile"
		missile.Size = Vector3.new(1, 1, 1)
		missile.CFrame = root.CFrame * CFrame.new(0, 1, -2)
		missile.Anchored = false
		missile.CanCollide = false
		missile.Material = Enum.Material.Neon
		missile.Color = Color3.new(1, 0.5, 0) -- Orange color for burn
		missile.Transparency = 0.3
		missile.Parent = workspace

		-- Add body velocity to missile
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		bodyVelocity.Velocity = direction * MISSILE_SPEED
		bodyVelocity.Parent = missile

		-- Create traveling hitbox with burn status ailment
		_G.createTravelingHitbox({
			attachTo = missile,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(6, 6, 6),
			damage = damage,
			character = wraith,
			name = "WraithHomingMissile",
			showVisual = false,
			visualColor = Color3.new(1, 0.5, 0), -- Orange color
			delay = 0,
			actionType = nil, -- Mobs don't have animation speeds
			classType = nil, -- Mobs don't have classes
			statusAilment = statusAilment, -- Add burn status ailment from stats
			lifesteal = lifesteal
		})

		if not resolvedTarget then
			return
		end

		-- Homing behavior - update direction towards target
		local homingConnection
		local startTime = tick()
		homingConnection = RunService.Heartbeat:Connect(function()
			if not missile or not missile.Parent then
				homingConnection:Disconnect()
				return
			end

			-- Check lifetime
			if tick() - startTime >= MISSILE_LIFETIME then
				homingConnection:Disconnect()
				missile:Destroy()
				return
			end

			-- Find current target (may have moved)
			local _, targetRoot = HitboxExclusions.findClosestHostile(wraith, missile.Position, DETECTION_RANGE * 2)

			if targetRoot then
				-- Update direction towards target
				local newDirection = (targetRoot.Position - missile.Position).Unit
				bodyVelocity.Velocity = newDirection * MISSILE_SPEED
			end
		end)
	end
	
	local function manualAttackCore()
		local _, nearest = HitboxExclusions.findClosestHostile(wraith, root.Position, DETECTION_RANGE)
		if nearest then
			shootHomingProjectile(nearest)
		else
			local forward = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
			shootHomingProjectile(nil, forward)
		end
	end

	local performPlayerAttack = manualAttackCore

	local playerControlled = bindPlayerControl(wraith, humanoid, function()
		performPlayerAttack()
	end)

	if playerControlled then
		local originalHipHeight = humanoid.HipHeight
		local floatHipHeight = originalHipHeight + FLOAT_HEIGHT
		local floating = false

		local function setFloating(enabled)
			if floating == enabled then
				return
			end

			floating = enabled

			if floating then
				humanoid.HipHeight = floatHipHeight
				if fire then
					fire.Enabled = true
				end
				root.CanCollide = false
			else
				humanoid.HipHeight = originalHipHeight
				if fire then
					fire.Enabled = false
				end
				root.CanCollide = true
			end
		end

		setFloating(false)

		root.Anchored = false
		root.CanCollide = true

		humanoid.Running:Connect(function(speed)
			if humanoid.Health <= 0 then
				return
			end

			if speed > 1 then
				setFloating(true)
			else
				setFloating(false)
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
		
		humanoid.Died:Connect(function()
			setFloating(false)
			
			-- Play death sound
			local deathSoundId = MobSoundConfig.getSound("wraithDeath")
			playSound(deathSoundId, false)
			
			-- Disable movement/AI scripts
			for _, child in ipairs(wraith:GetChildren()) do
				if child:IsA("Script") or child:IsA("LocalScript") then
					child.Disabled = true
				end
			end
			
			-- Make all parts fall naturally and be collidable
			for _, part in ipairs(wraith:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true -- ensure collision so it doesn't fall through map
				end
			end
			
			-- Detach limbs
			breakJoints(wraith)
			
			-- Wait a few seconds then completely remove from map
			task.wait(3) -- Wait 3 seconds
			
			if wraith and wraith.Parent then
				wraith:Destroy() -- Completely removes the mob from the game
			end
		end)

		performPlayerAttack = function()
			setFloating(true)
			manualAttackCore()
		end

		return
	else
		performPlayerAttack = manualAttackCore
		
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
			-- Play death sound
			local deathSoundId = MobSoundConfig.getSound("wraithDeath")
			playSound(deathSoundId, false)
			
			-- Disable movement/AI scripts
			for _, child in ipairs(wraith:GetChildren()) do
				if child:IsA("Script") or child:IsA("LocalScript") then
					child.Disabled = true
				end
			end
			
			-- Make all parts fall naturally and be collidable
			for _, part in ipairs(wraith:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true -- ensure collision so it doesn't fall through map
				end
			end
			
			-- Detach limbs
			breakJoints(wraith)
			
			-- Wait a few seconds then completely remove from map
			task.wait(3) -- Wait 3 seconds
			
			if wraith and wraith.Parent then
				wraith:Destroy() -- Completely removes the mob from the game
			end
		end)
		
		-- Rotation and attack loop - always face nearest player
		task.spawn(function()
			while task.wait(0.1) do
				if not wraith or not wraith.Parent or not humanoid or humanoid.Health <= 0 then
					break
				end
				
				local position = root.Position
				local targetModel, nearest, _, nearestDist = HitboxExclusions.findClosestHostile(wraith, position, DETECTION_RANGE)
				
				-- Face nearest player if found and control fire/attacks
				if nearest then
					currentTargetModel = targetModel
					-- Turn fire on when target detected
					if fire then
						fire.Enabled = true
					end
					
					-- Anchor and disable collision when floating to prevent physics interference
					root.Anchored = true
					root.CanCollide = false
					
					-- Float up
					targetY = groundY + FLOAT_HEIGHT
					
					currentTarget = nearest
					
					-- Attack if cooldown is ready
					if tick() - lastAttack >= ATTACK_COOLDOWN then
						lastAttack = tick()
						shootHomingProjectile(nearest)
					end
					
					-- Update lerp float - only affects Y position
					currentY = currentY + (targetY - currentY) * FLOAT_SPEED
					
					-- Preserve original X/Z position, only update Y
					local targetPos = Vector3.new(position.X, currentY, position.Z)
					
					local lookDirection = (nearest.Position - position).Unit
					if lookDirection.Magnitude > 0.1 then
						-- Only rotate on Y axis (horizontal rotation), preserve the floating Y position
						local lookDirection2D = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
						local lookCFrame = CFrame.lookAt(targetPos, targetPos + lookDirection2D)
						-- Lerp only the rotation part, keep the position fixed
						local currentRotation = root.CFrame - root.CFrame.Position
						local targetRotation = lookCFrame - lookCFrame.Position
						root.CFrame = CFrame.new(targetPos) * currentRotation:Lerp(targetRotation, 0.3)
					else
						-- Just update position if no rotation needed
						root.Position = targetPos
					end
				else
					-- No player detected, turn fire off
					if fire then
						fire.Enabled = false
					end
					currentTargetModel = nil
					
					-- Unanchor and enable collision before falling back down
					root.Anchored = false
					root.CanCollide = true
					
					-- Fall back down
					targetY = groundY
					
					currentTarget = nil
					
					-- Update lerp float - only affects Y position
					currentY = currentY + (targetY - currentY) * FLOAT_SPEED
					root.Position = Vector3.new(position.X, currentY, position.Z)
				end
			end
		end)
	end
end

-- === MODULE EXPORTS ===
local WraithAIModule = {}

function WraithAIModule.initializeWraith(model, variantName)
	initializeWraith(model, variantName)
end

function WraithAIModule.isInitialized(model)
	return false
end

return WraithAIModule
