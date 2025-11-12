local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local PLACE_ID = 113520176475008
local COMMAND_PREFIX = "/secretRoom"
local RESTART_COMMAND = "/restartplace"

local function getTodayKeyword()
	local dateString = os.date("!*t")
	return string.format("%s%04d%02d", COMMAND_PREFIX, dateString.year, dateString.day)
end

local function matchesTeleportKeyword(message)
	return string.lower(message) == string.lower(getTodayKeyword())
end

local function onPlayerChatted(player, message)
	local normalized = string.lower(message)

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

