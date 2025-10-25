-- Centralized Spider AI System
-- Looks for models with "spider_entity" tag and initializes them
-- Enhanced with pole system and proper leg grouping for better movement

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

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

function ProceduralModule:IkLegStep(ikTarget, ikRayPart, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams)
	stepWait = stepWait or 0.05
	stepForward = stepForward or 0
	stepHeight = stepHeight or 2

	local rayCast = workspace:Raycast(ikRayPart.Position, Vector3.new(0, -1000, 0), rayCastParams)

	if not ikTarget:GetAttribute("PreviousPos") then
		ikTarget:SetAttribute("PreviousPos", ikTarget.Position)
	end

	local previousFootPos = ikTarget:GetAttribute("PreviousPos")

	if rayCast then
		local groundPos = rayCast.Position
		local diff = (groundPos - previousFootPos).Magnitude

		if diff > stepDistance then
			local finalFootPos = groundPos + root.CFrame.LookVector * stepForward
			local middleFootPos = ((finalFootPos - previousFootPos) * 0.5 + previousFootPos) + Vector3.new(0, stepHeight, 0)

			coroutine.wrap(function()
				ikTarget.Position = middleFootPos
				task.wait(stepWait)
				ikTarget.Position = finalFootPos
				ikTarget:SetAttribute("PreviousPos", ikTarget.Position)
			end)()
		end
	else
		ikTarget.Position = previousFootPos
	end
end


-- ========== TRACKING ==========
local initializedSpiders = {}

-- ========== MAIN SPIDER SCRIPT ==========
local function InitializeSpider(enemy)
	-- Use model reference as unique identifier
	local spiderId = enemy
	
	print("[SpiderAI] Initializing spider:", enemy.Name)
	local root = enemy:WaitForChild("HumanoidRootPart")
	local hum = enemy:WaitForChild("Humanoid")
	local alignOrientation = root:FindFirstChild("AlignOrientation")

	local ikTargets = enemy:WaitForChild("IkTargets")
	local rayCastParts = enemy:WaitForChild("RayCastParts")

	for _, v in ipairs(ikTargets:GetChildren()) do if v:IsA("BasePart") then v.Transparency = 1 end end
	for _, v in ipairs(rayCastParts:GetChildren()) do if v:IsA("BasePart") then v.Transparency = 1 end end

	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterDescendantsInstances = { enemy }
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude

	local spawnPosition = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
	local spottingRadius = 40
	local attackRange = 8
	local maxRadius = 200
	local excludeTags = { "spider_entity" }

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

	local function playAttack()
		if attacking then return end
		attacking = true
		ikPaused = true  -- 🧠 Pause IK while attacking
		coroutine.wrap(function()
			pcall(function()
				attackTrack:Play(0.1)
				local stopped = false
				attackTrack.Stopped:Connect(function() stopped = true end)

				local t = 0
				while not stopped and t < 5 do
					task.wait(0.1)
					t += 0.1
				end
				task.wait(attackCooldown)
			end)
			ikPaused = false  -- ✅ Resume IK after attack ends
			attacking = false
		end)()
	end

	local function HasAnyExcludedTag(model)
		for _, tag in ipairs(excludeTags) do
			if CollectionService:HasTag(model, tag) then return true end
		end
		return false
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
			-- Check if model still exists or spider died
			if not enemy.Parent or not hum or hum.Health <= 0 then 
				print("[SpiderAI] Spider removed or died:", enemy.Name)
				break 
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
	RunService.Heartbeat:Connect(function()
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

	-- === Manual stepping cycle with proper grouping (skips when attacking) ===
	coroutine.wrap(function()
		while true do
			if not ikPaused then
				-- Group 1: LeftLeg1 + RightLeg4
				ProceduralModule:IkLegStep(Ik_LeftLeg1, Ray_LeftLeg1, root, 2, 2, 1, 0.01, rayCastParams)
				ProceduralModule:IkLegStep(Ik_RightLeg4, Ray_RightLeg4, root, 2, 2, 1, 0.01, rayCastParams)
				task.wait(0.1)

				-- Group 2: LeftLeg4 + RightLeg1
				ProceduralModule:IkLegStep(Ik_LeftLeg4, Ray_LeftLeg4, root, 2, 2, 1, 0.01, rayCastParams)
				ProceduralModule:IkLegStep(Ik_RightLeg1, Ray_RightLeg1, root, 2, 2, 1, 0.01, rayCastParams)
				task.wait(0.1)

				-- Group 3: LeftLeg2 + RightLeg3
				ProceduralModule:IkLegStep(Ik_LeftLeg2, Ray_LeftLeg2, root, 2, 2, 1, 0.01, rayCastParams)
				ProceduralModule:IkLegStep(Ik_RightLeg3, Ray_RightLeg3, root, 2, 2, 1, 0.01, rayCastParams)
				task.wait(0.1)

				-- Group 4: LeftLeg3 + RightLeg2
				ProceduralModule:IkLegStep(Ik_LeftLeg3, Ray_LeftLeg3, root, 2, 2, 1, 0.01, rayCastParams)
				ProceduralModule:IkLegStep(Ik_RightLeg2, Ray_RightLeg2, root, 2, 2, 1, 0.01, rayCastParams)
				task.wait(0.1)
			else
				task.wait(0.05)
			end
		end
	end)()
end

-- === TRACKING ===
-- No need for tracking since each model has its own initializer

-- === MODULE EXPORTS ===
local SpiderAIModule = {}

function SpiderAIModule.initializeSpider(model)
	InitializeSpider(model)
end

function SpiderAIModule.isInitialized(model)
	-- Always return false since we don't track initialization
	-- Each model has its own initializer that only runs once
	return false
end

-- === AUTO-INITIALIZATION (Optional) ===
-- This function can be called to automatically find and initialize all spiders with tags
function SpiderAIModule.autoInitializeSpiders()
	print("[SpiderAI] Looking for spiders with 'spider_entity' tag...")
	
	-- Initialize existing spiders
	for _, spider in ipairs(CollectionService:GetTagged("spider_entity")) do
		InitializeSpider(spider)
	end
	
	-- Listen for new spiders
	CollectionService:GetInstanceAddedSignal("spider_entity"):Connect(function(spider)
		InitializeSpider(spider)
	end)
	
	print("[SpiderAI] Spider AI system ready!")
end

return SpiderAIModule
