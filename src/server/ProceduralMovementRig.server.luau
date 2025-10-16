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

local taggedModels = CollectionService:GetTagged("spider_enemy")

-- Wait for a spider_enemy tagged model in workspace
local enemy = nil
for i, model in ipairs(taggedModels) do
	if model:IsA("Model") and model:IsDescendantOf(workspace) then
		enemy = model
		break
	end
end

if not enemy then
	warn("[SPIDER] ✗ No spider_enemy tagged model found in workspace!")
	warn("[SPIDER] Make sure your spider model has the 'spider_enemy' tag!")
	return
end

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

print("[SPIDER] Starting movement coroutine...")
coroutine.wrap(function()
	local tickCount = 0
	while task.wait(0.25) do
		tickCount += 1
		local curPos = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
		local dist = (curPos - spawnPosition).Magnitude
		local target = FindClosestPlayer(curPos)
		
		if tickCount % 20 == 1 then -- Log every 5 seconds
			print("[SPIDER] Movement tick - Dist from spawn:", math.floor(dist), "Target found:", target ~= nil)
		end
		
		if hum then
			if dist > maxRadius then
				print("[SPIDER] Too far from spawn! Returning to spawn point")
				hum:MoveTo(spawnPosition)
			elseif target then
				if tickCount % 20 == 1 then
					print("[SPIDER] Moving toward target")
				end
				hum:MoveTo(target.Position, target)
			end
		end
	end
end)()

-- Simple horizontal-only orientation (no vertical tilt)
if alignOrientation then
	RunService.Heartbeat:Connect(function()
		local curPos = (enemy:GetPivot() and enemy:GetPivot().Position) or root.Position
		local target = FindClosestPlayer(curPos)
		if target then
			-- Calculate horizontal angle only - no vertical tilt
			local dz = (target.Position.Z - root.Position.Z)
			local dx = (target.Position.X - root.Position.X)
			local horizontalAngle = math.atan2(dx, dz)
			
			-- Keep spider upright - only rotate horizontally
			alignOrientation.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, horizontalAngle, 0)
		end
	end)
else
	warn("[SPIDER] No AlignOrientation found - spider won't rotate toward targets")
end

-- Robust matching for RightLeg1 etc. - FIXED to handle exact matches better
local function canonicalLegName(name)
	-- Remove common prefixes like "IKTarget", "IkTarget", etc.
	local s = name:gsub("^[Ii][Kk][Tt]arget[_%-]?", "")
	-- Keep numbers and letters, normalize
	s = s:gsub("[^%w]", "")
	return s:lower()
end

local function findRayForLeg(legName)
	local targetLower = legName:lower()
	
	-- First pass: try exact match
	for _, c in ipairs(rayCastParts:GetChildren()) do
		local cleanRay = c.Name:gsub("[^%w]", ""):lower()
		if cleanRay == targetLower then
			return c
		end
	end
	
	-- Second pass: try contains match
	for _, c in ipairs(rayCastParts:GetChildren()) do
		local cleanRay = c.Name:gsub("[^%w]", ""):lower()
		if cleanRay:find(targetLower, 1, true) or targetLower:find(cleanRay, 1, true) then
			return c
		end
	end
	
	return nil
end

-- Build leg list with better debugging
local legs = {}
for _, ik in ipairs(ikTargets:GetChildren()) do
	if not ik:IsA("BasePart") then 
		continue 
	end
	local legName = canonicalLegName(ik.Name)
	local ray = findRayForLeg(legName)
	if ray then
		table.insert(legs, { ikTarget = ik, rayPart = ray, name = legName })
	else
		warn("[SPIDER] ✗ No matching ray found for leg:", ik.Name, "canonical:", legName)
	end
end

table.sort(legs, function(a, b) return a.name < b.name end)

-- Main stepping loop - simplified like original
while true do
	-- Process all legs in sequence like the original
	for _, leg in ipairs(legs) do
		ProceduralModule:IkLegStep(leg.ikTarget, leg.rayPart, root, 2, 2, 1, 0.05, rayCastParams)
	end
	task.wait(0.1) -- Wait between cycles like original
end
