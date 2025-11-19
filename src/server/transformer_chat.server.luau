local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local COMMAND_PREFIX = "/transform"

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Try to require R15AIModule
local R15AIModule = nil
local successR15, moduleR15 = pcall(function()
	local mobsFolder = ReplicatedStorage:FindFirstChild("mobs") or ReplicatedStorage:FindFirstChild("Mobs")
	if mobsFolder then
		return require(mobsFolder:WaitForChild("R15AIModule"))
	end
	return nil
end)
if successR15 and moduleR15 then
	R15AIModule = moduleR15
end

-- Try to require R6AIModule
local R6AIModule = nil
local successR6, moduleR6 = pcall(function()
	local mobsFolder = ReplicatedStorage:FindFirstChild("mobs") or ReplicatedStorage:FindFirstChild("Mobs")
	if mobsFolder then
		return require(mobsFolder:WaitForChild("R6AIModule"))
	end
	return nil
end)
if successR6 and moduleR6 then
	R6AIModule = moduleR6
end

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
	-- Check if player wants to transform back to themselves
	local lowerPath = string.lower(modelPath)
	if lowerPath == "myself" or lowerPath == "self" or lowerPath == "original" then
		-- Respawn player to restore original character
		local currentCharacter = player.Character
		if currentCharacter then
			currentCharacter:Destroy()
		end
		player:LoadCharacter()
		return
	end

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

	CollectionService:AddTag(cloned, "player_transformed")
	cloned:SetAttribute("ControlledByPlayer", player.UserId)

	-- Check if template or cloned model has r15_entity or r6_entity tag
	local hasR15Tag = CollectionService:HasTag(template, "r15_entity") or CollectionService:HasTag(cloned, "r15_entity")
	local hasR6Tag = CollectionService:HasTag(template, "r6_entity") or CollectionService:HasTag(cloned, "r6_entity")
	
	-- If template has the tag, add it to cloned as well
	if CollectionService:HasTag(template, "r15_entity") then
		CollectionService:AddTag(cloned, "r15_entity")
	end
	if CollectionService:HasTag(template, "r6_entity") then
		CollectionService:AddTag(cloned, "r6_entity")
	end

	if not cloned.PrimaryPart then
		-- Try HumanoidRootPart first (R15), then Torso (R6)
		local humanoidRoot = cloned:FindFirstChild("HumanoidRootPart")
		if not humanoidRoot then
			humanoidRoot = cloned:FindFirstChild("Torso")
		end
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
	
	-- Initialize R15 or R6 AI module if model has the corresponding tag
	if hasR15Tag and R15AIModule then
		-- Wait a frame to ensure character is fully set up
		task.wait(0.1)
		R15AIModule.initializeR15(cloned, cloned:GetAttribute("MobVariant") or "R15_Default")
	elseif hasR6Tag and R6AIModule then
		-- Wait a frame to ensure character is fully set up
		task.wait(0.1)
		R6AIModule.initializeR6(cloned, cloned:GetAttribute("MobVariant") or "R6_Default")
	end
end

local function onPlayerChatted(player: Player, message: string)
	-- Check if player has unlocked access
	if not ChatAccessControl.hasAccess(player) then
		return
	end
	
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



