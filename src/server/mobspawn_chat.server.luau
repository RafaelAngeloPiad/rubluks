local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/mobspawn"
local MAX_SPAWN_COUNT = 20

local mobsFolder = ReplicatedStorage:FindFirstChild("Mobs")
if not mobsFolder then
	warn("[MobSpawnChat] ReplicatedStorage.Mobs folder not found. Chat spawn command disabled.")
	return
end

local rng = Random.new()

local function resolveTemplate(path: string): Model?
	local current: Instance = mobsFolder

	for segment in string.gmatch(path, "[^/]+") do
		current = current:FindFirstChild(segment)
		if not current then
			return nil
		end
	end

	if current and current:IsA("Model") then
		return current
	end

	return nil
end

local function parseCommand(message: string)
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

local function spawnMobAtPosition(template: Model, position: Vector3, lookVector: Vector3)
	local clone = template:Clone()
	clone.Name = template.Name
	clone.Parent = workspace

	local primary = ensurePrimaryPart(clone)
	if primary then
		local forward = lookVector.Magnitude > 0 and lookVector.Unit or Vector3.new(0, 0, -1)
		local spawnCFrame = CFrame.new(position, position + forward)
		clone:PivotTo(spawnCFrame)
	else
		clone:MoveTo(position)
	end

	return clone
end

local function spawnMobs(player: Player, mobPath: string, amount: number)
	local template = resolveTemplate(mobPath)
	if not template then
		warn(("[MobSpawnChat] No mob template found for path '%s'"):format(mobPath))
		return
	end

	local character = player.Character
	if not character then
		warn("[MobSpawnChat] Cannot spawn mobs: player has no character.")
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root or not root:IsA("BasePart") then
		warn("[MobSpawnChat] Cannot spawn mobs: character missing HumanoidRootPart/PrimaryPart.")
		return
	end

	local forward = root.CFrame.LookVector
	local right = root.CFrame.RightVector
	local origin = root.Position

	for _ = 1, amount do
		local distance = 10 + rng:NextNumber(-2, 6)
		local lateral = rng:NextNumber(-6, 6)
		local depthVariance = rng:NextNumber(-2, 2)

		local spawnPos = origin + forward * (distance + depthVariance) + right * lateral
		spawnPos += Vector3.new(0, rng:NextNumber(0, 2), 0)

		spawnMobAtPosition(template, spawnPos, forward)
	end
end

local function onPlayerChatted(player: Player, message: string)
	local path, amount = parseCommand(message)
	if not path then
		return
	end

	spawnMobs(player, path, amount or 1)
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

if RunService:IsStudio() then
	print("[MobSpawnChat] Mob spawn chat command ready. Use /mobspawn <MobName> [count]")
end


