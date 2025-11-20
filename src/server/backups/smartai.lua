local character = script.Parent
character:WaitForChild("HumanoidRootPart"):SetNetworkOwner(nil) -- should make the pathfind less laggy
local humanoid = character:FindFirstChildOfClass("Humanoid")

local distanceDetection = script.AttackRange.Value
local ATTACK_RANGE = 4 -- Close range for melee attacks (separate from detection range)

script.AttackRange.Changed:Connect(function()
	distanceDetection = script.AttackRange.Value
end)

local usingToolBool = script.UsingTool

local usingTool = false

local team = script.Team
local isPlayer = script.IsPlayer

team.Parent = character
isPlayer.Parent = character

-- Wait for hitbox system to be available
while not _G.createStaticHitbox do
	wait(0.1)
end

-- ========================================
-- R15 ANIMATION SYSTEM
-- Automatically handles walk/idle animations based on movement
-- ========================================
local ANIMATION_IDS = {
	idle = {
		"507766666",
		"507766951",
		"507766388"
	},
	walk = {
		"507777826"
	},
	run = {
		"507767714"
	},
	jump = {
		"507765000"
	},
	fall = {
		"507767968"
	},
	climb = {
		"507765644"
	},
	attack = "108607323782800", -- Same as HumanMeleeAIModule
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
		return nil
	end
	
	track.Looped = looped
	track.Priority = priority
	return track
end

-- Initialize R15 animations
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local animations = {}

-- Load idle animations
for _, idleId in ipairs(ANIMATION_IDS.idle) do
	local track = loadTrack(animator, idleId, true, Enum.AnimationPriority.Core)
	if track then
		if not animations.idle then
			animations.idle = {}
		end
		table.insert(animations.idle, track)
	end
end

-- Load walk animation
if ANIMATION_IDS.walk and #ANIMATION_IDS.walk > 0 then
	animations.walk = loadTrack(animator, ANIMATION_IDS.walk[1], true, Enum.AnimationPriority.Core)
end

-- Load run animation
if ANIMATION_IDS.run and #ANIMATION_IDS.run > 0 then
	animations.run = loadTrack(animator, ANIMATION_IDS.run[1], true, Enum.AnimationPriority.Core)
end

-- Load other animations
if ANIMATION_IDS.jump and #ANIMATION_IDS.jump > 0 then
	animations.jump = loadTrack(animator, ANIMATION_IDS.jump[1], false, Enum.AnimationPriority.Movement)
end

if ANIMATION_IDS.fall and #ANIMATION_IDS.fall > 0 then
	animations.fall = loadTrack(animator, ANIMATION_IDS.fall[1], true, Enum.AnimationPriority.Movement)
end

if ANIMATION_IDS.climb and #ANIMATION_IDS.climb > 0 then
	animations.climb = loadTrack(animator, ANIMATION_IDS.climb[1], true, Enum.AnimationPriority.Movement)
end

-- Load attack animation
if ANIMATION_IDS.attack then
	animations.attack = loadTrack(animator, ANIMATION_IDS.attack, false, Enum.AnimationPriority.Action)
end

local currentMovementTrack = nil
local movementLocked = false
local attacking = false

local function setMovementTrack(track, fade)
	if movementLocked then
		return
	end
	
	if currentMovementTrack == track then
		return
	end
	
	if currentMovementTrack then
		currentMovementTrack:Stop(fade or 0.15)
	end
	
	currentMovementTrack = track
	
	if currentMovementTrack then
		currentMovementTrack:Play(fade or 0.15)
	end
end

-- Start with idle
if animations.idle and #animations.idle > 0 then
	local idleTrack = animations.idle[math.random(1, #animations.idle)]
	setMovementTrack(idleTrack, 0)
end

-- Handle movement animations automatically
humanoid.Running:Connect(function(speed)
	if movementLocked then
		return
	end
	
	if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return
	end
	
	if speed > 0.1 then
		if animations.walk then
			setMovementTrack(animations.walk, 0.2)
		elseif animations.run then
			setMovementTrack(animations.run, 0.2)
		end
	else
		if animations.idle and #animations.idle > 0 then
			local idleTrack = animations.idle[math.random(1, #animations.idle)]
			setMovementTrack(idleTrack, 0.2)
		end
	end
end)

humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	if movementLocked then
		return
	end
	
	if humanoid.MoveDirection.Magnitude < 0.05 and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		if animations.idle and #animations.idle > 0 then
			local idleTrack = animations.idle[math.random(1, #animations.idle)]
			setMovementTrack(idleTrack, 0.2)
		end
	end
end)

humanoid.StateChanged:Connect(function(_, newState)
	if movementLocked and newState ~= Enum.HumanoidStateType.Dead then
		return
	end
	
	if newState == Enum.HumanoidStateType.Jumping then
		if animations.jump then
			setMovementTrack(animations.jump, 0.05)
		end
	elseif newState == Enum.HumanoidStateType.Freefall then
		if animations.fall then
			setMovementTrack(animations.fall, 0.1)
		end
	elseif newState == Enum.HumanoidStateType.Climbing then
		if animations.climb then
			setMovementTrack(animations.climb, 0.1)
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		if animations.idle and #animations.idle > 0 then
			local idleTrack = animations.idle[math.random(1, #animations.idle)]
			setMovementTrack(idleTrack, 0.15)
		end
	elseif newState == Enum.HumanoidStateType.Dead then
		movementLocked = true
		if currentMovementTrack then
			currentMovementTrack:Stop(0.1)
			currentMovementTrack = nil
		end
	end
end)
-- ========================================
-- END R15 ANIMATION SYSTEM
-- ========================================

local useRegion = false -- uses Regions to detect character models to make it detect only in range (else it detects all children of workspace, and only children of workspace)
local ignoreWalls = true -- set true to ignore walls
local attackNonSight = true -- attack when it cant pathfind when an enemy it is tracking is not in it's vision

function raycast(blacklist, cframe, dist)
	local cantTouchTable = blacklist
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = cantTouchTable
	raycastParams.IgnoreWater = true
	local pos = cframe.Position
	local direction = cframe.LookVector * dist
	local result = workspace:Raycast(pos, direction, raycastParams)
	if result ~= nil then
		if result.Instance.CanCollide == false or result.Instance.Parent:IsA("Accessory") or result.Instance.Parent:IsA("Tool") or result.Instance.Parent:FindFirstChildWhichIsA("Humanoid") ~= nil then
			table.insert(cantTouchTable, result.Instance)
			local newResult, newBlacklist = raycast(cantTouchTable, cframe, dist)
			result = newResult
			cantTouchTable = newBlacklist
		end
	end
	return result, cantTouchTable
end

function canSeeTarget(target)
	--print("detecting if can see target")
	local cantTouchTable = {character, target}

	local cframe
	local distance
	if target:IsA("Tool") then
		cframe = CFrame.new(character.HumanoidRootPart.Position, target:FindFirstChildWhichIsA("BasePart").Position)
		distance = (character.HumanoidRootPart.Position - target:FindFirstChildWhichIsA("BasePart").Position).Magnitude
	else
		local root = target:FindFirstChild("HumanoidRootPart")
		if root == nil then
			root = target:FindFirstChildWhichIsA("BasePart")
		end
		cframe = CFrame.new(character.HumanoidRootPart.Position, root.Position)
		distance = (character.HumanoidRootPart.Position - root.Position).Magnitude
	end
	local result = raycast(cantTouchTable, cframe, distance)
	if result == nil then
		return true
	else
		return false
	end
end

local faceAtAttachment = Instance.new("Attachment", character.HumanoidRootPart)
local alignment = Instance.new("AlignOrientation", faceAtAttachment)
alignment.Attachment0 = faceAtAttachment
alignment.Responsiveness = 200
alignment.MaxTorque = 179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368
local tempAttachment
local currentEnemy

local ignoreparts = {}

function findTarget(pos, ignoreLook)
	local tool = character:FindFirstChildOfClass("Tool")
	-- Removed findAlly support - if tool has Support, just don't attack
	if tool ~= nil and (tool:FindFirstChild("Support") ~= nil or tool:FindFirstChild("support") ~= nil) then
		return nil
	else
		local list = {}
		if useRegion == true then
			local min = pos - Vector3.new(distanceDetection, distanceDetection, distanceDetection)
			local max = pos + Vector3.new(distanceDetection, distanceDetection, distanceDetection)
			local region = Region3.new(min, max)
			local partsInRegion = game.Workspace:FindPartsInRegion3WithIgnoreList(region, ignoreparts, 500)
			for _, part in pairs(partsInRegion) do
				if part.Parent:FindFirstChildOfClass("Humanoid") and table.find(list, part.Parent) == nil then
					table.insert(list, part.Parent)
				elseif not part.Parent:IsA("Tool") and part.Parent:FindFirstChildOfClass("Humanoid") == nil then
					table.insert(ignoreparts, part)
				end
			end
		else
			list = workspace:GetChildren()
		end
		local dist = distanceDetection
		local temp = nil
		local human = nil
		local temp2 = nil
		local closest = nil
		for x = 1, #list do
			temp2 = list[x]
			if (temp2.className == "Model") and temp2:FindFirstChildWhichIsA("Humanoid") and (temp2 ~= character) then
				temp = temp2:findFirstChild("HumanoidRootPart")
				human = temp2:findFirstChildOfClass("Humanoid")

				if temp == nil then
					temp = temp2:FindFirstChildWhichIsA("BasePart")
				end

				local canAttack = true
				if temp2:FindFirstChild("Team") ~= nil and temp2.Team.Value == team.Value then
					canAttack = false
				end

				if (game.Players:GetPlayerFromCharacter(temp2) ~= nil or (temp2:FindFirstChild("IsPlayer") and temp2.IsPlayer.Value == true)) and script.AttackPlayers.Value == false then
					canAttack = false
				end

				if (game.Players:GetPlayerFromCharacter(temp2) == nil or (temp2:FindFirstChild("IsPlayer") and temp2.IsPlayer.Value == false)) and script.AttackNPCs.Value == false then
					canAttack = false
				end

				if (temp ~= nil) and (human ~= nil) and (human.Health > 0) and canAttack == true and (ignoreLook or canSeeTarget(temp2)) then
					if (temp.Position - pos).magnitude < dist then
						closest = temp2
						dist = (temp.Position - pos).magnitude
					end
				end
			end
		end
		if closest ~= nil then
			if tempAttachment == nil or tempAttachment.Parent == nil then
				tempAttachment = Instance.new("Attachment", workspace.Terrain)
				alignment.Attachment1 = tempAttachment
			end
			local root = closest:FindFirstChild("HumanoidRootPart")
			if root == nil then
				root = closest:FindFirstChildWhichIsA("BasePart")
			end
			tempAttachment.CFrame = CFrame.new(character.HumanoidRootPart.Position, Vector3.new(root.Position.X, character.HumanoidRootPart.Position.Y, root.Position.Z))
		elseif tempAttachment ~= nil then
			tempAttachment:Destroy()
			tempAttachment = nil
		end
		currentEnemy = closest
		return closest
	end
end

function findTool(pos, ignoreLook)
	local list = {}
	if useRegion == true then
		local min = pos - Vector3.new(distanceDetection, distanceDetection, distanceDetection)
		local max = pos + Vector3.new(distanceDetection, distanceDetection, distanceDetection)
		local region = Region3.new(min, max)
		local partsInRegion = game.Workspace:FindPartsInRegion3WithIgnoreList(region, ignoreparts, 500)
		for _, part in pairs(partsInRegion) do
			if part.Parent:IsA("Tool") and part.Parent.Parent:FindFirstChildOfClass("Humanoid") == nil and table.find(list, part.Parent) == nil then
				table.insert(list, part.Parent)
			elseif not part.Parent:IsA("Tool") and part.Parent:FindFirstChildOfClass("Humanoid") == nil then
				table.insert(ignoreparts, part)
			end
		end
	else
		list = workspace:GetChildren()
	end
	local dist = distanceDetection
	local temp = nil
	local closest = nil
	for x = 1, #list do
		temp = list[x]
		if temp:IsA("Tool") and temp:FindFirstChildWhichIsA("BasePart") ~= nil and (ignoreLook or canSeeTarget(temp)) then
			if (temp:FindFirstChildWhichIsA("BasePart").Position - pos).magnitude < dist then
				closest = temp
				dist = (temp:FindFirstChildWhichIsA("BasePart").Position - pos).magnitude
			end
		end
	end
	return closest
end

function getPath(destination)
	local PathfindingService = game:GetService("PathfindingService")

	local pathParams = {
		["AgentRadius"] = 2,
		["AgentHeight"] = 5,
		["AgentCanJump"] = true,
		["WaypointSpacing"] = math.huge
	}

	local path = PathfindingService:CreatePath(pathParams)

	path:ComputeAsync(character.HumanoidRootPart.Position, destination)

	return path
end

function displayPath(waypoints)
	local color = BrickColor.Random()
	for index, waypoint in pairs(waypoints) do
		local part = Instance.new("Part")
		part.BrickColor = color
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(1,1,1)
		part.Position = waypoint.Position
		part.Parent = workspace
		local Debris = game:GetService("Debris")
		Debris:AddItem(part, 6)
	end
end

local walkingToTool = false

function followPath(destination)
	script.StopPath:Fire()
	local path = getPath(destination)
	if path.Status == Enum.PathStatus.Success then
		--displayPath(path:GetWaypoints()) -- To display the path if u want
		local stopping = false
		local finished = Instance.new("BindableEvent", script.StopPath)
		local st
		st = script.StopPath.Event:Connect(function()
			st:Disconnect()
			stopping = true
			finished:Fire()
			finished:Destroy()
		end)

		local waypoints = path:GetWaypoints()
		local blockedIndex = 2

		local wasBlocked = false

		local blockedConnection
		blockedConnection = path.Blocked:Connect(function(bindex)
			if bindex >= blockedIndex then
				blockedConnection:Disconnect()
				wasBlocked = true
				finished:Fire()
			end
		end)

		spawn(function()
			for index, waypoint in pairs(waypoints) do
				if wasBlocked == false then
					blockedIndex = index
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
					humanoid:MoveTo(waypoint.Position)
					humanoid.MoveToFinished:Wait()
				end
			end
			if wasBlocked == false then
				blockedConnection:Disconnect()
				finished:Fire()
			end
		end)

		finished.Event:Wait()
		if wasBlocked == true then
			followPath(destination)
		end

	else
		humanoid:MoveTo(destination)
		--humanoid.MoveToFinished:Wait()
		return false
	end
end

function walkTo(destination, isEnemy)
	local tool
	if script.Parent:FindFirstChildOfClass("Tool") == nil and script.FindTools.Value == true then
		tool = findTool(character.HumanoidRootPart.Position, ignoreWalls)
	end
	if tool ~= nil and walkingToTool == false then
		usingToolBool.Value = false
		walkingToTool = true
		-- Clear facing target when going to get weapon
		if tempAttachment ~= nil then
			tempAttachment:Destroy()
			tempAttachment = nil
		end
		followPath(tool:FindFirstChildWhichIsA("BasePart").Position)

		if tool ~= nil and tool.Parent == workspace and tool:FindFirstChild("Handle") ~= nil and (tool.Handle.Position - character.HumanoidRootPart.Position).Magnitude <= 4 then
			tool.Parent = character
		end
		walkingToTool = false
	else
		local target = findTarget(character.HumanoidRootPart.Position)
		if (script.AttackNPCs.Value == true or script.AttackPlayers.Value == true) and target and target.Humanoid.Health > 0 then
			usingToolBool.Value = true
		elseif math.random(1, 10) == 1 then
			usingToolBool.Value = false
			local stop = false
			if (script.AttackNPCs.Value == true or script.AttackPlayers.Value == true) then
				spawn(function()
					while stop == false do
						local target = findTarget(character.HumanoidRootPart.Position)
						if target and target.Humanoid.Health > 0 then
							script.StopPath:Fire()
							usingToolBool.Value = true
							break
						end
						wait(.25)
					end
				end)
			end
			local worked = followPath(destination)
			if isEnemy and worked == false and attackNonSight == true then
				usingToolBool.Value = true
			end
			stop = true
		end
	end
end

local attackDebounce = false
local attackCooldown = 1
local lastAttackTime = 0

-- Get damage value from script or attribute
local function getAttackDamage()
	if script:FindFirstChild("PunchDamage") then
		return script.PunchDamage.Value
	elseif character:GetAttribute("Damage") then
		return character:GetAttribute("Damage")
	else
		return 25 -- Default damage
	end
end

-- Spawn hitbox when attack animation markers are reached
local function spawnAttackHitbox(markerName)
	if not attacking then
		return
	end

	if not _G or not _G.createStaticHitbox then
		return
	end

	local damage = getAttackDamage()
	local root = character.HumanoidRootPart
	local hitboxName = string.format("SmartAI_%s", markerName or "Attack")

	_G.createStaticHitbox({
		attachTo = root,
		offset = CFrame.new(0, 0, -4),
		size = Vector3.new(8, 8, 8),
		damage = damage,
		character = character,
		name = hitboxName,
		showVisual = false,
		visualColor = Color3.new(1, 0.2, 0.2),
		delay = 0,
		actionType = nil,
		classType = nil,
	})
end

-- Set up attack animation markers
local attackTrack = animations.attack
if attackTrack then
	attackTrack:GetMarkerReachedSignal("slash1"):Connect(function()
		spawnAttackHitbox("slash1")
	end)

	attackTrack:GetMarkerReachedSignal("slash2"):Connect(function()
		spawnAttackHitbox("slash2")
	end)
end

function performMeleeAttack()
	if attackDebounce or attacking or movementLocked then
		return
	end

	if tick() - lastAttackTime < attackCooldown then
		return
	end

	if not attackTrack then
		-- Fallback: create hitbox immediately if no animation
		attackDebounce = true
		local damage = getAttackDamage()
		local root = character.HumanoidRootPart
		
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, -4),
			size = Vector3.new(8, 8, 8),
			damage = damage,
			character = character,
			name = "SmartAIAttack",
			showVisual = false,
			visualColor = Color3.new(1, 0.2, 0.2),
			delay = 0,
			actionType = nil,
			classType = nil,
		})
		
		wait(attackCooldown)
		attackDebounce = false
		return
	end

	lastAttackTime = tick()
	attacking = true
	movementLocked = true
	attackDebounce = true

	-- Stop movement animation
	if currentMovementTrack then
		currentMovementTrack:Stop(0.1)
	end

	-- Play attack animation
	local connection
	connection = attackTrack.Stopped:Connect(function()
		attacking = false
		movementLocked = false
		attackDebounce = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)

	attackTrack:Play(0.1)
end

usingToolBool.Changed:Connect(function()
	if usingToolBool.Value == true and usingTool == false then
		usingTool = true
		spawn(function()
			while usingToolBool.Value == true and usingTool == true and walkingToTool == false do
				if currentEnemy ~= nil then
					local tool = character:FindFirstChildOfClass("Tool")
					local isRanged = false
					local distance = nil
					if tool ~= nil then
						if tool:FindFirstChild("CustomActivate") then
							if tool.CustomActivate:FindFirstChild("ranged") then
								isRanged = true
							end
							if tool.CustomActivate:FindFirstChild("dist") then
								distance = tool.CustomActivate.dist.Value
							end
						elseif tool:FindFirstChild("Support") then
							if tool.Support:FindFirstChild("ranged") then
								isRanged = true
							end
							if tool.Support:FindFirstChild("dist") then
								distance = tool.Support.dist.Value
							end
						end
						if tool:FindFirstChild("ranged") then
							isRanged = true
						end
						if tool:FindFirstChild("dist") then
							distance = tool.dist.Value
						end
					end
					if isRanged == true or (script.PunchWhenNoTool.Value == false and tool == nil) then
						local pos = character.HumanoidRootPart.Position
						if distance ~= nil then
							local root = currentEnemy:FindFirstChild("HumanoidRootPart")
							if root == nil then
								root = currentEnemy:FindFirstChildWhichIsA("BasePart")
							end
							if root == nil then
								break
							end
							if (root.Position - pos).Magnitude < distance then
								pos = root.Position + CFrame.new(root.Position, pos).LookVector * distance
							end
						end
						if script.Wander.Value == true then
							followPath(pos + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)))
							wait(.5)
						else
							wait()
						end
					else
						-- Stop movement during attack
						if attacking then
							humanoid:MoveTo(character.HumanoidRootPart.Position)
							wait(0.1)
						else
							local root = currentEnemy:FindFirstChild("HumanoidRootPart")
							if root == nil then
								root = currentEnemy:FindFirstChildWhichIsA("BasePart")
							end
							if root == nil then
								break
							end
							local distToEnemy = (character.HumanoidRootPart.Position - root.Position).Magnitude
							-- Check if in attack range - if so, attack instead of moving
							if distToEnemy <= ATTACK_RANGE and not attacking then
								performMeleeAttack()
								wait(0.1)
							else
								local pos = root.Position
								if distance ~= nil then
									if distToEnemy > distance then
										pos = pos + CFrame.new(pos, character.HumanoidRootPart.Position).LookVector * distance
									end
								else
									pos = pos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
								end
								humanoid:MoveTo(pos)
								wait()
							end
						end
					end
				else
					wait()
				end
			end
		end)
		while usingToolBool.Value == true and usingTool == true and currentEnemy ~= nil do
			local root = currentEnemy:FindFirstChild("HumanoidRootPart")
			if root == nil then
				root = currentEnemy:FindFirstChildWhichIsA("BasePart")
			end
			if root == nil then
				break
			end
			
			local distToEnemy = (character.HumanoidRootPart.Position - root.Position).Magnitude
			
			-- Stop movement during attack
			if attacking then
				humanoid:MoveTo(character.HumanoidRootPart.Position)
			-- Check attack range FIRST - attack if in range, regardless of tool
			elseif distToEnemy <= ATTACK_RANGE then
				-- In attack range - attack!
				if not attacking then
					performMeleeAttack()
				end
			-- Not in attack range - move closer or use ranged tool
			else
				if root.Position.Y > character.HumanoidRootPart.Position.Y + 1 then
					humanoid.Jump = true
				end
				if character:FindFirstChildOfClass("Tool") ~= nil then
					local tool = character:FindFirstChildOfClass("Tool")
					local isRanged = false
					if tool:FindFirstChild("CustomActivate") then
						if tool.CustomActivate:FindFirstChild("ranged") then
							isRanged = true
						end
					elseif tool:FindFirstChild("Support") then
						if tool.Support:FindFirstChild("ranged") then
							isRanged = true
						end
					end
					if tool:FindFirstChild("ranged") then
						isRanged = true
					end
					
					-- Only use tool if it's ranged, otherwise just move closer
					if isRanged then
						if tool:FindFirstChild("CustomActivate") and currentEnemy ~= nil then
							local root = currentEnemy:FindFirstChild("HumanoidRootPart")
							if root == nil then
								root = currentEnemy:FindFirstChildWhichIsA("BasePart")
							end
							if tool.CustomActivate:FindFirstChild("pos") then
								tool.CustomActivate:Fire(root.Position)
							else
								tool.CustomActivate:Fire(root)
							end
						elseif tool:FindFirstChild("Support") and currentEnemy ~= nil then
							local root = currentEnemy:FindFirstChild("HumanoidRootPart")
							if root == nil then
								root = currentEnemy:FindFirstChildWhichIsA("BasePart")
							end
							if tool.Support:FindFirstChild("pos") then
								tool.Support:Fire(root.Position)
							else
								tool.Support:Fire(root)
							end
						end
					else
						-- Melee tool - just move closer, don't use it until in range
						humanoid:MoveTo(root.Position)
					end
				else
					-- No tool - move closer to get in attack range
					humanoid:MoveTo(root.Position)
				end
			end
			wait(.25)
		end
		usingToolBool.Value = false
		usingTool = false
	end
end)

local originalPos = character.HumanoidRootPart.Position

while humanoid.Health > 0 do
	wait(0.25)
	local destination = originalPos
	if script.Wander.Value == true then
		destination = character.HumanoidRootPart.Position + Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
	end
	local isEnemy = false
	if ignoreWalls == true then
		local torso = findTarget(character.HumanoidRootPart.Position, true)
		if torso ~= nil then
			isEnemy = true
			local root = currentEnemy:FindFirstChild("HumanoidRootPart")
			if root == nil then
				root = currentEnemy:FindFirstChildWhichIsA("BasePart")
			end
			destination = root.Position
		end
	end
	walkTo(destination, isEnemy)
end

usingToolBool.Value = false
if tempAttachment ~= nil then
	tempAttachment:Destroy()
end