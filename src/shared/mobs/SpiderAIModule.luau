-- Spider AI Module
-- Centralized AI logic that can be called from anywhere
-- Enhanced with pole system and proper leg grouping for better movement

local RunService = game:GetService("RunService")

-- Import global exclusions
local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfig = require(script.Parent.MobStatsConfig)

-- Try to require MobStatsDisplay module
local MobStatsDisplay = nil
local success, displayModule = pcall(function()
	return require(game.ReplicatedStorage.MobStatsDisplay)
end)
if success then
	MobStatsDisplay = displayModule
end

-- ========== PROCEDURAL MODULE ==========
local ProceduralModule = {}

function ProceduralModule:getRotationBetween(u, v)
	local randomAxis = Vector3.new(1, 0, 0)
	local dot = u:Dot(v)
	if dot > 0.99999 then
		return CFrame.new()
	elseif dot < -0.99999 then
		return CFrame.fromAxisAngle(randomAxis, math.pi)
	end
	return CFrame.fromAxisAngle(u:Cross(v), math.acos(dot))
end

function ProceduralModule:IkLegStep(ikTarget, ikRayPart, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, isSteppingRef)
	stepWait = stepWait or 0.05
	stepForward = stepForward or 0
	stepHeight = stepHeight or 2

	-- Safety: Prevent overlapping steps on the same leg
	if isSteppingRef and isSteppingRef.Value then
		return false -- Leg is already stepping
	end

	local rayCast = workspace:Raycast(ikRayPart.Position, Vector3.new(0, -1000, 0), rayCastParams)

	if not ikTarget:GetAttribute("PreviousPos") then
		ikTarget:SetAttribute("PreviousPos", ikTarget.Position)
	end

	local previousFootPos = ikTarget:GetAttribute("PreviousPos")

	if rayCast then
		local groundPos = rayCast.Position
		-- Calculate distance from previous position to new ground position
		-- Account for body movement by using relative position
		local bodyOffset = root.CFrame:PointToObjectSpace(groundPos)
		local prevBodyOffset = root.CFrame:PointToObjectSpace(previousFootPos)
		local diff = (bodyOffset - prevBodyOffset).Magnitude

		-- Also check absolute distance as fallback
		local absoluteDiff = (groundPos - previousFootPos).Magnitude
		diff = math.max(diff, absoluteDiff)

		if diff > stepDistance then
			-- Mark leg as stepping
			if isSteppingRef then
				isSteppingRef.Value = true
			end

			-- Predictive stepping: Step in direction of movement
			local rootVelocity = root.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
			local movementDirection = rootVelocity.Magnitude > 0.1 and rootVelocity.Unit or root.CFrame.LookVector
			local finalFootPos = groundPos + movementDirection * stepForward
			
			-- Ensure final position is on ground
			local groundCheck = workspace:Raycast(finalFootPos + Vector3.new(0, 1, 0), Vector3.new(0, -10, 0), rayCastParams)
			if groundCheck then
				finalFootPos = groundCheck.Position
			end

			local middleFootPos = ((finalFootPos - previousFootPos) * 0.5 + previousFootPos) + Vector3.new(0, stepHeight, 0)

			coroutine.wrap(function()
				-- Set initial position
				ikTarget.Position = middleFootPos
				local startTime = tick()
				
				-- Smooth step animation
				task.wait(stepWait)
				
				-- Verify step completed in reasonable time (only warn if significantly delayed)
				local elapsed = tick() - startTime
				if elapsed > stepWait * 10 then -- Only warn if step takes 10x longer than expected
					-- Step took too long, might be stuck
					warn("Spider leg step took too long:", elapsed, "expected:", stepWait)
				end
				
				-- Final position
				ikTarget.Position = finalFootPos
				ikTarget:SetAttribute("PreviousPos", ikTarget.Position)
				
				-- Mark step as complete
				if isSteppingRef then
					isSteppingRef.Value = false
				end
			end)()
			
			return true -- Step initiated
		else
			-- No step needed, but update position slightly to follow body
			ikTarget.Position = groundPos
		end
	else
		-- No ground found, keep leg at previous position
		ikTarget.Position = previousFootPos
		return false
	end
	
	return false
end


-- ========== TRACKING ==========
-- No need for tracking since each model has its own initializer

-- ========== MAIN SPIDER SCRIPT ==========
local function initializeSpider(enemy, variantName)
	-- Default variant if not provided
	variantName = variantName or "Spider_Sand"
	
	-- Apply stats to the spider (sets attributes for DynamicHitboxV3 defense system)
	-- NOTE: Stats are applied BEFORE anything else so defense/health work correctly
	local statsApplied = MobStatsConfig.applyStats(enemy, variantName)
	if not statsApplied then
		warn("Spider: Failed to apply stats for variant:", variantName)
	end
	
	local root = enemy:WaitForChild("HumanoidRootPart")
	local hum = enemy:WaitForChild("Humanoid")
	
	local alignOrientation = root:FindFirstChild("AlignOrientation")
	local alignmentConnection

	local ikTargets = enemy:WaitForChild("IkTargets")
	local rayCastParts = enemy:WaitForChild("RayCastParts")
	
	-- Create floating stats display GUI (if enabled in config)
	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(enemy)
	end

	-- for _, v in ipairs(ikTargets:GetChildren()) do if v:IsA("BasePart") then v.Transparency = 1 end end
	-- for _, v in ipairs(rayCastParts:GetChildren()) do if v:IsA("BasePart") then v.Transparency = 1 end end

	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterDescendantsInstances = { enemy }
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude

	local spawnPosition = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
	local spottingRadius = 40
	local attackRange = 8
	local maxRadius = 200

	-- === Attack animation setup (smooth and synced) ===
	local ATTACK_ANIMATION_ID = "rbxassetid://132697102857784"
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local attackAnim = Instance.new("Animation")
	attackAnim.AnimationId = ATTACK_ANIMATION_ID
	local attackTrack = animator:LoadAnimation(attackAnim)
	attackTrack.Looped = false
	attackTrack.Priority = Enum.AnimationPriority.Action

	local attacking = false
	local ikPaused = false
	local attackCooldown = 0.5
	local lastAttackTime = 0

	local function playAttack()
		if attacking then return end
		attacking = true
		lastAttackTime = tick() -- Track when attack started
		ikPaused = true  -- 🧠 Pause IK while attacking
		coroutine.wrap(function()
			pcall(function()
				attackTrack:Play(0.1)
				
				-- Create static hitbox when attack animation plays
				if _G.createStaticHitbox then
					-- Get damage from mob's attribute
					local damage = enemy:GetAttribute("Damage") or 50
					
					-- Get status ailment config from MobStatsConfig
					local stats = MobStatsConfig.getStats(variantName)
					local statusAilment = stats and stats.StatusAilment or nil
					
					local hitboxConfig = {
						attachTo = root,
						offset = CFrame.new(0, 0, -3), -- Hitbox in front of spider
						size = Vector3.new(6, 6, 6), -- 6x6x6 stud hitbox
						damage = damage,
						character = enemy, -- Exclude the spider itself
						name = "SpiderAttack",
						showVisual = true,
						visualColor = Color3.new(0.8, 0, 0.8), -- Purple color
						delay = 0.2, -- Delay to sync with animation
						visualDuration = 0.6
					}
					
					-- Add status ailment if configured
					if statusAilment then
						hitboxConfig.statusAilment = statusAilment
					end
					
					_G.createStaticHitbox(hitboxConfig)
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
					
					-- Check if spider is still alive and in workspace
					if not enemy.Parent or enemy.Parent ~= workspace or not hum or hum.Health <= 0 then
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
				
				task.wait(attackCooldown)
			end)
			ikPaused = false  -- ✅ Resume IK after attack ends
			attacking = false
		end)()
	end

	local function HasAnyExcludedTag(model)
		return HitboxExclusions.hasExcludedTag(model)
	end

	local function FindClosestPlayer(position)
		local nearest, nearestDist = nil, spottingRadius
		for _, candidate in ipairs(workspace:GetChildren()) do
			if candidate:IsA("Model") and candidate ~= enemy and not HasAnyExcludedTag(candidate) then
				local hrp = candidate:FindFirstChild("HumanoidRootPart")
				local humCan = candidate:FindFirstChild("Humanoid")
				if hrp and humCan and humCan.Health > 0 then
					local d = (hrp.Position - position).Magnitude
					if d < nearestDist then
						nearestDist = d
						nearest = hrp
					end
				end
			end
		end
		return nearest
	end

	-- === MOVEMENT & ATTACK AI ===
	coroutine.wrap(function()
		while task.wait(0.25) do
			-- Check if model still exists, is in workspace, or spider died
			if not enemy.Parent or enemy.Parent ~= workspace or not hum or hum.Health <= 0 then 
				-- Force cleanup of all connections and threads
				if alignmentConnection then
					alignmentConnection:Disconnect()
				end
				break 
			end
			
			-- Safety check: reset attacking state if stuck for too long
			if attacking and tick() - lastAttackTime > 5 then
				attacking = false
				ikPaused = false
				if attackTrack.IsPlaying then
					attackTrack:Stop(0.1)
				end
			end
			
			local curPos = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
			local dist = (curPos - spawnPosition).Magnitude
			local target = FindClosestPlayer(curPos)

			if dist > maxRadius then
				hum:MoveTo(spawnPosition)
			elseif target then
				local tDist = (target.Position - curPos).Magnitude
				if tDist <= attackRange then
					hum:MoveTo(root.Position)
					playAttack()
				elseif not attacking then
					hum:MoveTo(target.Position, target)
				end
			end
		end
	end)()

	-- === LEG IK CONTROL WITH POLES ===
	-- IK Targets
	local Ik_LeftLeg1 = ikTargets:WaitForChild("IkTarget_LeftLeg1")
	local Ik_LeftLeg2 = ikTargets:WaitForChild("IkTarget_LeftLeg2")
	local Ik_LeftLeg3 = ikTargets:WaitForChild("IkTarget_LeftLeg3")
	local Ik_LeftLeg4 = ikTargets:WaitForChild("IkTarget_LeftLeg4")

	local Ik_RightLeg1 = ikTargets:WaitForChild("IkTarget_RightLeg1")
	local Ik_RightLeg2 = ikTargets:WaitForChild("IkTarget_RightLeg2")
	local Ik_RightLeg3 = ikTargets:WaitForChild("IkTarget_RightLeg3")
	local Ik_RightLeg4 = ikTargets:WaitForChild("IkTarget_RightLeg4")

	-- Ray Cast Parts
	local Ray_LeftLeg1 = rayCastParts:WaitForChild("RayCastPart_LeftLeg1")
	local Ray_LeftLeg2 = rayCastParts:WaitForChild("RayCastPart_LeftLeg2")
	local Ray_LeftLeg3 = rayCastParts:WaitForChild("RayCastPart_LeftLeg3")
	local Ray_LeftLeg4 = rayCastParts:WaitForChild("RayCastPart_LeftLeg4")

	local Ray_RightLeg1 = rayCastParts:WaitForChild("RayCastPart_RightLeg1")
	local Ray_RightLeg2 = rayCastParts:WaitForChild("RayCastPart_RightLeg2")
	local Ray_RightLeg3 = rayCastParts:WaitForChild("RayCastPart_RightLeg3")
	local Ray_RightLeg4 = rayCastParts:WaitForChild("RayCastPart_RightLeg4")

	-- IK Controls with Poles
	local IK_LeftLeg1 = hum:FindFirstChild("IKControl_LeftLeg1")
	local IK_LeftLeg2 = hum:FindFirstChild("IKControl_LeftLeg2")
	local IK_LeftLeg3 = hum:FindFirstChild("IKControl_LeftLeg3")
	local IK_LeftLeg4 = hum:FindFirstChild("IKControl_LeftLeg4")

	local IK_RightLeg1 = hum:FindFirstChild("IKControl_RightLeg1")
	local IK_RightLeg2 = hum:FindFirstChild("IKControl_RightLeg2")
	local IK_RightLeg3 = hum:FindFirstChild("IKControl_RightLeg3")
	local IK_RightLeg4 = hum:FindFirstChild("IKControl_RightLeg4")

	-- Assign poles to IK controls
	if IK_LeftLeg1 then IK_LeftLeg1.Pole = root:FindFirstChild("Pole_LeftLeg1") end
	if IK_LeftLeg2 then IK_LeftLeg2.Pole = root:FindFirstChild("Pole_LeftLeg2") end
	if IK_LeftLeg3 then IK_LeftLeg3.Pole = root:FindFirstChild("Pole_LeftLeg3") end
	if IK_LeftLeg4 then IK_LeftLeg4.Pole = root:FindFirstChild("Pole_LeftLeg4") end
	if IK_RightLeg1 then IK_RightLeg1.Pole = root:FindFirstChild("Pole_RightLeg1") end
	if IK_RightLeg2 then IK_RightLeg2.Pole = root:FindFirstChild("Pole_RightLeg2") end
	if IK_RightLeg3 then IK_RightLeg3.Pole = root:FindFirstChild("Pole_RightLeg3") end
	if IK_RightLeg4 then IK_RightLeg4.Pole = root:FindFirstChild("Pole_RightLeg4") end

	-- === Root alignment ===
	alignmentConnection = RunService.Heartbeat:Connect(function()
		-- Check if model still exists in workspace
		if not enemy.Parent or enemy.Parent ~= workspace then
			alignmentConnection:Disconnect()
			alignmentConnection = nil
			return
		end
		
		local ray = workspace:Raycast(root.Position, -1000 * root.CFrame.UpVector, rayCastParams)
		local target = workspace:FindFirstChild("Target")
		if ray and target then
			local rotateToFloorCFrame = ProceduralModule:getRotationBetween(root.CFrame.UpVector, ray.Normal)
			local floorOrientedCFrame = rotateToFloorCFrame * CFrame.new(root.Position)
			local dz = (root.Position.Z - target.Position.Z)
			local dx = (root.Position.X - target.Position.X)
			local horizontalAngle = math.atan2(dx, dz)
			alignOrientation.CFrame = floorOrientedCFrame.Rotation * CFrame.fromOrientation(0, horizontalAngle, 0)
		end
	end)

	-- === Step tracking for each leg (prevents overlapping steps) ===
	local legSteppingStates = {
		LeftLeg1 = {Value = false},
		LeftLeg2 = {Value = false},
		LeftLeg3 = {Value = false},
		LeftLeg4 = {Value = false},
		RightLeg1 = {Value = false},
		RightLeg2 = {Value = false},
		RightLeg3 = {Value = false},
		RightLeg4 = {Value = false},
	}

	-- Initialize all leg positions before starting cycle
	local function initializeLegs()
		for _, legName in ipairs({"LeftLeg1", "LeftLeg2", "LeftLeg3", "LeftLeg4", "RightLeg1", "RightLeg2", "RightLeg3", "RightLeg4"}) do
			local ikTarget = ikTargets:FindFirstChild("IkTarget_" .. legName)
			local rayPart = rayCastParts:FindFirstChild("RayCastPart_" .. legName)
			if ikTarget and rayPart then
				local rayCast = workspace:Raycast(rayPart.Position, Vector3.new(0, -1000, 0), rayCastParams)
				if rayCast then
					ikTarget.Position = rayCast.Position
					ikTarget:SetAttribute("PreviousPos", rayCast.Position)
				end
			end
		end
	end
	
	-- Initialize legs immediately
	initializeLegs()
	task.wait(0.1) -- Small delay to ensure initialization

	-- === Calculate spider scale factor (used for all distance-based parameters) ===
	-- Calculate once at initialization to scale all step distances proportionally
	local referenceSize = 8 -- Reference size for a "normal" sized spider
	local rootSize = root.Size
	local spiderScaleFactor = ((rootSize.X + rootSize.Z) / 2) / referenceSize
	-- Clamp scale factor to reasonable bounds (0.1 to 2.0)
	spiderScaleFactor = math.clamp(spiderScaleFactor, 0.1, 2.0)
	
	-- === Continuous leg position update (keeps legs aligned with body) ===
	coroutine.wrap(function()
		while true do
			if not enemy.Parent or enemy.Parent ~= workspace then
				return
			end
			
			-- Only update if not paused and legs exist
			if not ikPaused then
				for _, legName in ipairs({"LeftLeg1", "LeftLeg2", "LeftLeg3", "LeftLeg4", "RightLeg1", "RightLeg2", "RightLeg3", "RightLeg4"}) do
					local legState = legSteppingStates[legName]
					-- Only update legs that aren't currently stepping
					if legState and not legState.Value then
						local ikTarget = ikTargets:FindFirstChild("IkTarget_" .. legName)
						local rayPart = rayCastParts:FindFirstChild("RayCastPart_" .. legName)
						if ikTarget and rayPart then
							local rayCast = workspace:Raycast(rayPart.Position, Vector3.new(0, -1000, 0), rayCastParams)
							if rayCast then
								-- Small adjustment to follow body without triggering a step
								local currentPos = ikTarget.Position
								local groundPos = rayCast.Position
								local distance = (currentPos - groundPos).Magnitude
								
								-- Only make small adjustments (scaled thresholds) to prevent dragging
								local minAdjustDist = 0.5 * spiderScaleFactor
								local maxAdjustDist = 1.0 * spiderScaleFactor
								if distance > minAdjustDist and distance < maxAdjustDist then
									-- Smoothly adjust position to follow body
									ikTarget.Position = currentPos:Lerp(groundPos, 0.3)
								end
							end
						end
					end
				end
			end
			
			task.wait(0.1) -- Update every 0.1 seconds
		end
	end)()

	-- === Manual stepping cycle with proper grouping (skips when attacking) ===
	coroutine.wrap(function()
		local lastRootPosition = root.Position
		local lastPositionUpdateTime = tick()
		
		while true do
			-- Check if model still exists in workspace
			if not enemy.Parent or enemy.Parent ~= workspace then
				-- Force cleanup and exit
				return
			end
			
			if not ikPaused then
				-- Calculate body velocity for adaptive stepping
				local currentTime = tick()
				local timeDelta = math.max(currentTime - lastPositionUpdateTime, 0.016) -- Minimum 16ms
				local currentRootPos = root.Position
				local bodyVelocity = (currentRootPos - lastRootPosition) / timeDelta
				local bodySpeed = bodyVelocity.Magnitude
				
				-- Update position tracking
				lastRootPosition = currentRootPos
				lastPositionUpdateTime = currentTime
				
				-- Adaptive step distance: smaller when moving fast, larger when slow
				-- Base step distance of 1.5, reduces to 1.0 when moving fast, increases to 2.5 when stationary
				-- All distances are scaled by the spider's size
				local baseStepDistance = 1.5 * spiderScaleFactor
				local stepDistance = baseStepDistance
				if bodySpeed > 5 then
					-- Moving fast: reduce step distance to trigger steps more frequently
					stepDistance = math.max(0.8 * spiderScaleFactor, baseStepDistance - (bodySpeed - 5) * 0.1 * spiderScaleFactor)
				elseif bodySpeed < 0.5 then
					-- Moving slow/stationary: increase step distance
					stepDistance = baseStepDistance + 1.0 * spiderScaleFactor
				end
				
				-- Adaptive step forward: more when moving fast
				local stepForward = 2 * spiderScaleFactor
				if bodySpeed > 5 then
					stepForward = (2 + math.min(bodySpeed * 0.2, 2)) * spiderScaleFactor -- Max 4 studs forward (scaled)
				end
				
				-- Adaptive step height: Higher lift for more visible spider-like movement
				local stepHeight = 2.5 * spiderScaleFactor -- Scaled by spider size
				if bodySpeed > 5 then
					stepHeight = 2.0 * spiderScaleFactor -- Slightly lower when moving fast
				elseif bodySpeed < 0.5 then
					stepHeight = 3.0 * spiderScaleFactor -- Higher when stationary/slow
				end
				
				-- Adaptive wait time: Slower, more deliberate steps
				local stepWait = 0.08 -- Increased from 0.01 for slower, more visible steps
				if bodySpeed > 5 then
					stepWait = 0.06 -- Faster steps when moving, but still slower than before
				elseif bodySpeed < 0.5 then
					stepWait = 0.12 -- Slower steps when stationary
				end
				
				-- Natural spider gait: Alternating tripod pattern with staggered timing
				-- This creates a more organic, less mechanical movement
				-- Base timing between individual leg steps (longer delays for more spider-like movement)
				local baseStepDelay = 0.15 -- Increased delay between legs
				if bodySpeed > 5 then
					baseStepDelay = 0.12 -- Faster when moving
				elseif bodySpeed < 0.5 then
					baseStepDelay = 0.20 -- Slower when stationary
				end
				
				-- Add random variation to make it less mechanical (0-25% variation)
				local randomVariation = math.random() * 0.25
				local stepDelay = baseStepDelay * (1 + randomVariation)
				
				-- Alternating tripod gait pattern:
				-- Tripod 1: LeftLeg1, RightLeg2, LeftLeg3, RightLeg4 (3 legs alternating)
				-- Tripod 2: RightLeg1, LeftLeg2, RightLeg3, LeftLeg4 (opposite 3 legs)
				-- Stagger each leg slightly to create natural flow
				
				-- Step 1: Front Left
				ProceduralModule:IkLegStep(Ik_LeftLeg1, Ray_LeftLeg1, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.LeftLeg1)
				task.wait(stepDelay * 0.4) -- Longer delay for more deliberate movement
				
				-- Step 2: Mid-Right Front
				ProceduralModule:IkLegStep(Ik_RightLeg2, Ray_RightLeg2, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.RightLeg2)
				task.wait(stepDelay * 0.5)
				
				-- Step 3: Mid-Left Back
				ProceduralModule:IkLegStep(Ik_LeftLeg3, Ray_LeftLeg3, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.LeftLeg3)
				task.wait(stepDelay * 0.4)
				
				-- Step 4: Back Right
				ProceduralModule:IkLegStep(Ik_RightLeg4, Ray_RightLeg4, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.RightLeg4)
				task.wait(stepDelay * 0.7) -- Longer pause before opposite tripod
				
				-- Opposite tripod starts
				-- Step 5: Front Right
				ProceduralModule:IkLegStep(Ik_RightLeg1, Ray_RightLeg1, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.RightLeg1)
				task.wait(stepDelay * 0.4)
				
				-- Step 6: Mid-Left Front
				ProceduralModule:IkLegStep(Ik_LeftLeg2, Ray_LeftLeg2, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.LeftLeg2)
				task.wait(stepDelay * 0.5)
				
				-- Step 7: Mid-Right Back
				ProceduralModule:IkLegStep(Ik_RightLeg3, Ray_RightLeg3, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.RightLeg3)
				task.wait(stepDelay * 0.4)
				
				-- Step 8: Back Left
				ProceduralModule:IkLegStep(Ik_LeftLeg4, Ray_LeftLeg4, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams, legSteppingStates.LeftLeg4)
				
				-- Wait before next cycle starts (ensures all legs have time to complete)
				local cycleWait = stepWait * 1.5 + stepDelay * 0.8
				task.wait(cycleWait)
			else
				-- IK paused (during attack), just wait
				task.wait(0.05)
			end
		end
	end)()
end

-- === MODULE EXPORTS ===
local SpiderAIModule = {}

function SpiderAIModule.initializeSpider(model, variantName)
	initializeSpider(model, variantName)
end

function SpiderAIModule.isInitialized(model)
	-- Always return false since we don't track initialization
	-- Each model has its own initializer that only runs once
	return false
end

return SpiderAIModule
