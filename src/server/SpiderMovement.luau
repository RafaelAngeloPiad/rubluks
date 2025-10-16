-- Author: Roox4 (simplified 8-leg version based on original)
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- ========== PROCEDURAL MODULE (EMBEDDED) ==========
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

-- Simple stepping function based on original
function ProceduralModule:IkLegStep(ikTarget, ikRayPart, root, stepDistance, stepForward, stepHeight, stepWait, rayCastParams)
	stepWait = stepWait or 0.05
	stepForward = stepForward or 0
	stepHeight = stepHeight or 2
	
	local rayCast = workspace:Raycast(ikRayPart.Position, Vector3.new(0, -1000, 0), rayCastParams)
	
	if rayCast then
		if not ikTarget:GetAttribute("PreviousPos") then
			ikTarget:SetAttribute("PreviousPos", Vector3.new(0, 0, 0))
		end
		
		local previousFootPos = ikTarget:GetAttribute("PreviousPos")
		local defaultFootPos = rayCast.Position
		local diff = (defaultFootPos - previousFootPos).Magnitude
		
		-- Do a step
		if diff > stepDistance then
			local finalFootPos = rayCast.Position + root.CFrame.LookVector * stepForward
			local middleFootPos = ((finalFootPos - previousFootPos) * 0.5 + previousFootPos) + Vector3.new(0, stepHeight, 0)
			
			coroutine.wrap(function()
				ikTarget.Position = middleFootPos
				task.wait(stepWait)
				ikTarget.Position = finalFootPos
				ikTarget:SetAttribute("PreviousPos", ikTarget.Position)
			end)()
		end
	end
end

-- ========== MAIN SPIDER SCRIPT ==========

-- Function to initialize a single spider model
local function InitializeSpider(enemy)
	local root = enemy:WaitForChild("HumanoidRootPart")
	local hum = enemy:WaitForChild("Humanoid")
	local alignOrientation = root:FindFirstChild("AlignOrientation")
	local rayCastParts = enemy:WaitForChild("RayCastParts")
	local ikTargets = enemy:WaitForChild("IkTargets")

	-- Hide helper parts
	for _, v in ipairs(ikTargets:GetChildren()) do
		if v:IsA("BasePart") then v.Transparency = 1 end
	end
	for _, v in ipairs(rayCastParts:GetChildren()) do
		if v:IsA("BasePart") then v.Transparency = 1 end
	end

	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterDescendantsInstances = { enemy }
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude

	local spawnPosition = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position

	local spottingRadius = 40
	local maxRadius = 500
	local excludeTags = {"massive_sand_entity", "sand_entity", "smoldering_sand_entity", "spider_enemy"}

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

	-- Movement coroutine for this spider
	coroutine.wrap(function()
		local tickCount = 0
		while task.wait(0.25) do
			tickCount += 1
			local curPos = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
			local dist = (curPos - spawnPosition).Magnitude
			local target = FindClosestPlayer(curPos)

			if hum then
				if dist > maxRadius then
					hum:MoveTo(spawnPosition)
				elseif target then
					hum:MoveTo(target.Position, target)
				end
			end
		end
	end)()

	-- Simple leg matching - direct name matching
	local legs = {}

	-- Get all ray cast parts for quick lookup
	local rayParts = {}
	for _, part in ipairs(rayCastParts:GetChildren()) do
		if part:IsA("BasePart") then
			rayParts[part.Name] = part
		end
	end

	-- Match IK targets to ray cast parts by simple name matching
	for _, ik in ipairs(ikTargets:GetChildren()) do
		if ik:IsA("BasePart") then
			-- Convert "IkTarget_RightLeg1" to "RayCastPart_RightLeg1"
			local rayName = ik.Name:gsub("^IkTarget", "RayCastPart")
			local ray = rayParts[rayName]
			
			if ray then
				table.insert(legs, { ikTarget = ik, rayPart = ray })
			else
				warn("[SPIDER] ✗ No matching ray found for leg:", ik.Name, "looking for:", rayName)
			end
		end
	end

	-- Main stepping loop for this spider
	coroutine.wrap(function()
		while true do
			-- Process all legs in sequence like the original
			for _, leg in ipairs(legs) do
				ProceduralModule:IkLegStep(leg.ikTarget, leg.rayPart, root, 2, 2, 1, 0.01, rayCastParams)
			end
			task.wait(0.1) -- Wait between cycles like original
		end
	end)()
end

-- Function to find the parent model that contains this script
local function FindParentModel()
	local current = script.Parent
	while current do
		if current:IsA("Model") then
			-- Check if this model has the required components
			local hasRoot = current:FindFirstChild("HumanoidRootPart")
			local hasRayCastParts = current:FindFirstChild("RayCastParts")
			local hasIkTargets = current:FindFirstChild("IkTargets")
			
			if hasRoot and hasRayCastParts and hasIkTargets then
				return current
			end
		end
		current = current.Parent
	end
	return nil
end

-- Wait a bit for the model to be fully loaded, then initialize
task.wait(1) -- Small delay to ensure model is loaded
local parentModel = FindParentModel()

if parentModel then
	InitializeSpider(parentModel)
end
