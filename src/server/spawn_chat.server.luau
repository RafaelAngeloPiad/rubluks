local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/spawn"
local MAX_SPAWN_COUNT = 100

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
local mobsFolder = ReplicatedStorage:FindFirstChild("Mobs")

if not assetsFolder and not mobsFolder then
	warn("[SpawnChat] No assets or mobs folder found in ReplicatedStorage. Chat spawn command disabled.")
	return
end

local rng = Random.new()

local function resolveFromFolder(root: Instance?, path: string): Instance?
	if not root or path == "" then
		return nil
	end

	local current: Instance? = root

	for segment in string.gmatch(path, "[^/]+") do
		if not current then
			return nil
		end

		current = current:FindFirstChild(segment)
	end

	return current
end

local function resolveTemplate(path: string): (Instance?, string?)
	local assetInstance = resolveFromFolder(assetsFolder, path)
	if assetInstance then
		return assetInstance, "asset"
	end

	local mobInstance = resolveFromFolder(mobsFolder, path)
	if mobInstance and mobInstance:IsA("Model") then
		return mobInstance, "mob"
	end

	return nil, nil
end

local function parseCommand(message: string): (string?, number?)
	if #message < #COMMAND_PREFIX then
		return nil, nil
	end

	if string.sub(string.lower(message), 1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
		return nil, nil
	end

	local remainder = string.sub(message, #COMMAND_PREFIX + 1)
	remainder = string.gsub(remainder, "^%s+", "")
	remainder = string.gsub(remainder, "%s+$", "")

	if remainder == "" then
		return nil, nil
		end

	local count = 1
	local countMatch = remainder:match("(%d+)$")
	if countMatch then
		count = tonumber(countMatch) or 1
		remainder = string.gsub(remainder, "%s*" .. countMatch .. "%s*$", "")
		remainder = string.gsub(remainder, "%s+$", "")
	end

	if remainder == "" then
		return nil, nil
	end

	count = math.clamp(count, 1, MAX_SPAWN_COUNT)

	return remainder, count
end

local function ensurePrimaryPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local humanoidRoot = model:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and humanoidRoot:IsA("BasePart") then
		model.PrimaryPart = humanoidRoot
		return humanoidRoot
	end

	local basePart = model:FindFirstChildWhichIsA("BasePart")
	if basePart then
		model.PrimaryPart = basePart
		return basePart
	end

	return nil
end

local function spawnInstanceAtPosition(template: Instance, templateType: string?, position: Vector3, lookVector: Vector3, player: Player)
	local clone = template:Clone()
	clone.Name = template.Name
	
	-- Tag the spawned instance as a generic spawned object
	clone:SetAttribute("SpawnedObject", true)

	if clone:IsA("Tool") then
		clone.Parent = workspace
		local handle = clone:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local forward = lookVector.Magnitude > 0 and lookVector.Unit or Vector3.new(0, 0, -1)
			local spawnCFrame = CFrame.new(position, position + forward)
			handle.CFrame = spawnCFrame
		end
	elseif clone:IsA("Model") then
		clone.Parent = workspace
		local primary = ensurePrimaryPart(clone)
		if primary then
			local forward = lookVector.Magnitude > 0 and lookVector.Unit or Vector3.new(0, 0, -1)
			local spawnCFrame = CFrame.new(position, position + forward)
			clone:PivotTo(spawnCFrame)
		else
			clone:MoveTo(position)
		end
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new(position)
		clone.Parent = workspace
	else
		clone.Parent = workspace
	end

	return clone
end

local GOLDEN_ANGLE = math.pi * (3 - math.sqrt(5))

local function computeSpawnPosition(origin: Vector3, forward: Vector3, right: Vector3, baseDistance: number, index: number, total: number)
	local forwardUnit = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
	local rightUnit = right.Magnitude > 0 and right.Unit or Vector3.new(1, 0, 0)

	local angle = index * GOLDEN_ANGLE + rng:NextNumber(-0.25, 0.25)
	local radialStep = math.max(total, 1)
	local radius = baseDistance + math.sqrt(index / radialStep) * 10 + rng:NextNumber(-1, 1)

	local planarOffset = (rightUnit * math.cos(angle) + forwardUnit * math.sin(angle)) * radius
	local heightOffset = rng:NextNumber(-1, 3)

	-- small random jitter to avoid perfect patterns
	local jitter = Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))

	return origin + planarOffset + Vector3.new(0, heightOffset, 0) + jitter
end

local function spawnTemplates(player: Player, path: string, amount: number)
	local template, templateType = resolveTemplate(path)
	if not template then
		warn(("[SpawnChat] No template found for path '%s'"):format(path))
		return
	end

	local character = player.Character
	if not character then
		warn("[SpawnChat] Cannot spawn: player has no character.")
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root or not root:IsA("BasePart") then
		warn("[SpawnChat] Cannot spawn: character missing HumanoidRootPart/PrimaryPart.")
		return
	end

	local forward = root.CFrame.LookVector
	local right = root.CFrame.RightVector
	local origin = root.Position
	local baseDistance = templateType == "mob" and 10 or 8

	for index = 1, amount do
		local spawnPosition = computeSpawnPosition(origin, forward, right, baseDistance, index, amount)
		spawnInstanceAtPosition(template, templateType, spawnPosition, forward, player)
	end
end

local function onPlayerChatted(player: Player, message: string)
	-- Check if player has unlocked access
	if not ChatAccessControl.hasAccess(player) then
		return
	end
	
	local path, amount = parseCommand(message)
	if not path then
		return
	end

	spawnTemplates(player, path, amount or 1)
end

local function connectPlayer(player: Player)
	player.Chatted:Connect(function(message: string)
		onPlayerChatted(player, message)
	end)
end

Players.PlayerAdded:Connect(connectPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end
