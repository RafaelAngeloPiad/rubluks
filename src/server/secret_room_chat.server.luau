local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLACE_ID = 113520176475008
local COMMAND_PREFIX = "/secretRoom"
local RESTART_COMMAND = "/restartplace"

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

local function matchesTeleportKeyword(message)
	return string.lower(message) == string.lower(COMMAND_PREFIX)
end

local function onPlayerChatted(player, message)
	-- Check if player has unlocked access
	if not ChatAccessControl.hasAccess(player) then
		return
	end
	
	local normalized = string.lower(message)

	-- Allow switching to SLAVKO class
	if normalized == "/become slavko" then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local class = leaderstats:FindFirstChild("Class")
			if not class then
				class = Instance.new("StringValue")
				class.Name = "Class"
				class.Parent = leaderstats
			end
			class.Value = "SLAVKO"
		end
		return
	end
	
	if normalized == RESTART_COMMAND then
		local players = Players:GetPlayers()
		if #players > 0 then
			local success, err = pcall(function()
				TeleportService:TeleportAsync(game.PlaceId, players)
			end)
			if not success then
				warn("Failed to restart place:", err)
			end
		end
	elseif matchesTeleportKeyword(normalized) then
		TeleportService:Teleport(PLACE_ID, player)
	end
end

local function connectPlayer(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end

Players.PlayerAdded:Connect(connectPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

