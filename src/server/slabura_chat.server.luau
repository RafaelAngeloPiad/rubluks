local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COMMAND_PREFIX = "/slabura"
local DEFAULT_RADIUS = 200 -- Default radius in studs

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Create or get RemoteEvent for button support
local ClearSpawnedEvent = ReplicatedStorage:FindFirstChild("ClearSpawnedEvent")
if not ClearSpawnedEvent then
	ClearSpawnedEvent = Instance.new("RemoteEvent")
	ClearSpawnedEvent.Name = "ClearSpawnedEvent"
	ClearSpawnedEvent.Parent = ReplicatedStorage
end

-- Function to parse the command and extract optional radius
local function parseCommand(message: string): number?
	if #message < #COMMAND_PREFIX then
		return nil
	end

	local lowerMessage = string.lower(message)
	if string.sub(lowerMessage, 1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
		return nil
	end

	local remainder = string.sub(message, #COMMAND_PREFIX + 1)
	remainder = string.gsub(remainder, "^%s+", "")
	remainder = string.gsub(remainder, "%s+$", "")

	-- If no radius specified, use default
	if remainder == "" then
		return DEFAULT_RADIUS
	end

	-- Try to parse radius from remainder
	local radius = tonumber(remainder)
	if radius then
		-- Clamp radius between 10 and 2000 studs for safety
		return math.clamp(radius, 10, 2000)
	end

	-- Invalid radius, use default
	return DEFAULT_RADIUS
end

-- Function to clear models spawned by the player in radius
local function clearModelsInRadius(player: Player, radius: number)
	local character = player.Character
	if not character then
		warn("[SLaburaChat] Cannot clear: player has no character.")
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root or not root:IsA("BasePart") then
		warn("[SLaburaChat] Cannot clear: character missing HumanoidRootPart/PrimaryPart.")
		return
	end

	local playerPosition = root.Position
	local clearedCount = 0

	-- Iterate through all instances in workspace
	for _, instance in ipairs(workspace:GetChildren()) do
		-- Check if this instance is a spawned object
		if instance:GetAttribute("SpawnedObject") == true then
			-- Check if it's a model or has a position we can check
			local instancePosition = nil
			
			if instance:IsA("Model") then
				local modelRoot = instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso")
				if modelRoot and modelRoot:IsA("BasePart") then
					instancePosition = modelRoot.Position
				end
			elseif instance:IsA("BasePart") then
				instancePosition = instance.Position
			elseif instance:IsA("Tool") then
				local handle = instance:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then
					instancePosition = handle.Position
				end
			end
			
			-- If we found a position, check distance
			if instancePosition then
				local distance = (instancePosition - playerPosition).Magnitude
				
				-- If within radius, delete it
				if distance <= radius then
					instance:Destroy()
					clearedCount = clearedCount + 1
				end
			end
		end
	end

	print(string.format("[SLaburaChat] Player '%s' cleared %d spawned instances within %d studs.", player.Name, clearedCount, radius))
end

-- Function to handle player chat
local function onPlayerChatted(player: Player, message: string)
	-- Check if player has unlocked access
	if not ChatAccessControl.hasAccess(player) then
		return
	end

	local radius = parseCommand(message)
	if not radius then
		return
	end

	clearModelsInRadius(player, radius)
end

-- Function to connect player chat events
local function connectPlayer(player: Player)
	player.Chatted:Connect(function(message: string)
		onPlayerChatted(player, message)
	end)
end

-- Connect existing and new players
Players.PlayerAdded:Connect(connectPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

-- Listen for server events from buttons
ClearSpawnedEvent.OnServerEvent:Connect(function(player)
	-- Check if player has access
	if not ChatAccessControl.hasAccess(player) then
		return
	end
	
	-- Clear with default radius
	clearModelsInRadius(player, DEFAULT_RADIUS)
end)
