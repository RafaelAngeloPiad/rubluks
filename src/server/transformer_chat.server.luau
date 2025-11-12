local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/transform"

local mobsFolder = ReplicatedStorage:FindFirstChild("Mobs")
if not mobsFolder then
	warn("[TransformerChat] ReplicatedStorage.Mobs folder not found. Chat transform command disabled.")
	return
end

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

local function extractModelName(message: string): string?
	if #message < #COMMAND_PREFIX then
		return nil
	end

	local lowerMessage = string.lower(message)
	if string.sub(lowerMessage, 1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
		return nil
	end

	local remainder = string.sub(message, #COMMAND_PREFIX + 1)
	remainder = string.gsub(remainder, "^%s+", "")
	if remainder == "" then
		return nil
	end

	return remainder
end

local function transformPlayer(player: Player, modelPath: string)
	local template = resolveTemplate(modelPath)
	if not template then
		warn(("[TransformerChat] No mob template found for path '%s'"):format(modelPath))
		return
	end

	local humanoidTemplate = template:FindFirstChildOfClass("Humanoid")
	if not humanoidTemplate then
		warn(("[TransformerChat] Template '%s' missing Humanoid."):format(template:GetFullName()))
		return
	end

	local spawnCFrame
	local currentCharacter = player.Character
	if currentCharacter and currentCharacter:IsA("Model") and currentCharacter.PrimaryPart then
		spawnCFrame = currentCharacter:GetPivot()
	end

	local cloned = template:Clone()
	cloned.Name = player.Name
	cloned.Parent = workspace

	if not cloned.PrimaryPart then
		local humanoidRoot = cloned:FindFirstChild("HumanoidRootPart")
		if humanoidRoot and humanoidRoot:IsA("BasePart") then
			cloned.PrimaryPart = humanoidRoot
		end
	end

	if spawnCFrame and cloned.PrimaryPart then
		cloned:PivotTo(spawnCFrame)
	else
		local basePart = cloned.PrimaryPart or cloned:FindFirstChildWhichIsA("BasePart")
		if basePart then
			basePart.CFrame += Vector3.new(0, 5, 0)
		end
	end

	if currentCharacter then
		currentCharacter:Destroy()
	end

	player.Character = cloned

	local newHumanoid = cloned:FindFirstChildOfClass("Humanoid")
	if newHumanoid and cloned.PrimaryPart then
		pcall(function()
			cloned.PrimaryPart:SetNetworkOwner(player)
		end)
		newHumanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
	end
end

local function onPlayerChatted(player: Player, message: string)
	local modelName = extractModelName(message)
	if not modelName then
		return
	end

	transformPlayer(player, modelName)
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
	print("[TransformerChat] Transformer chat command ready. Use /transform <MobName>")
end


