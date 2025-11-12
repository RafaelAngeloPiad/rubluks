local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/weaponspawn"

local assetsFolder = ReplicatedStorage:FindFirstChild("assets") or ReplicatedStorage:FindFirstChild("Assets")
if not assetsFolder then
	warn("[ItemSpawnChat] ReplicatedStorage.assets folder not found. Chat spawn command disabled.")
	return
end

local function resolveTemplate(path: string): Instance?
	local current: Instance = assetsFolder

	for segment in string.gmatch(path, "[^/]+") do
		current = current:FindFirstChild(segment)
		if not current then
			return nil
		end
	end

	return current
end

local function parseCommand(message: string)
	if #message < #COMMAND_PREFIX then
		return nil
	end

	if string.sub(string.lower(message), 1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
		return nil
	end

	local remainder = string.sub(message, #COMMAND_PREFIX + 1)
	remainder = string.gsub(remainder, "^%s+", "")
	remainder = string.gsub(remainder, "%s+$", "")

	if remainder == "" then
		return nil
	end

	return remainder
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

local function spawnItemAtPosition(template: Instance, position: Vector3, lookVector: Vector3)
	local clone = template:Clone()
	clone.Name = template.Name

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
	else
		if clone:IsA("BasePart") then
			clone.CFrame = CFrame.new(position)
		end
		clone.Parent = workspace
	end

	return clone
end

local function spawnItem(player: Player, itemPath: string)
	local template = resolveTemplate(itemPath)
	if not template then
		warn(("[ItemSpawnChat] No asset template found for path '%s'"):format(itemPath))
		return
	end

	local character = player.Character
	if not character then
		warn("[ItemSpawnChat] Cannot spawn item: player has no character.")
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root or not root:IsA("BasePart") then
		warn("[ItemSpawnChat] Cannot spawn item: character missing HumanoidRootPart/PrimaryPart.")
		return
	end

	local forward = root.CFrame.LookVector
	local origin = root.Position

	local spawnDistance = 8
	local spawnHeightOffset = Vector3.new(0, 2, 0)
	local spawnPosition = origin + forward * spawnDistance + spawnHeightOffset

	spawnItemAtPosition(template, spawnPosition, forward)
end

local function onPlayerChatted(player: Player, message: string)
	local path = parseCommand(message)
	if not path then
		return
	end

	spawnItem(player, path)
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
	print("[ItemSpawnChat] Item spawn chat command ready. Use /weaponspawn <ItemName or path>")
end


