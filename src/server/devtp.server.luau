local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COMMAND_PREFIX = "/teleport"
local RESTART_COMMAND = "/restartPlace"

-- Array of places with names and place IDs
local PLACES = {
	{ name = "mobFacility", placeId = 113520176475008 },
	{ name = "ashenDev", placeId = 103542783686628 },
	{ name = "crystalDev", placeId = 104617541282971 },
	{ name = "darkAbyssFrostfang", placeId = 135917777864656 },
	{ name = "darkAbyssSunfire", placeId = 113016675542265 },
	{ name = "frostfangDev", placeId = 87981506895525 },
	{ name = "lobbyDev", placeId = 74487711502949 },
	{ name = "slavkoriaDev", placeId = 124517586803775 },
	{ name = "stormbreakerDev", placeId = 122707550517432 },
	{ name = "sunfireDev", placeId = 79306413649233 },
	{ name = "toxicDev", placeId = 130213276808804 },
	{ name = "whisperingDev", placeId = 122544989275401 },
}

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

local function parseCommand(message: string): string?
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

local function findPlaceByName(name: string): number?
	local lowerName = string.lower(name)
	for _, place in ipairs(PLACES) do
		if string.lower(place.name) == lowerName then
			return place.placeId
		end
	end
	return nil
end

local function onPlayerChatted(player: Player, message: string)
	-- Check if player has unlocked access
	if not ChatAccessControl.hasAccess(player) then
		return
	end

	local normalized = string.lower(message)

	-- Handle restart command
	if normalized == string.lower(RESTART_COMMAND) then
		local players = Players:GetPlayers()
		if #players > 0 then
			local success, err = pcall(function()
				TeleportService:TeleportAsync(game.PlaceId, players)
			end)
			if not success then
				warn("[DevTP] Failed to restart place:", err)
			end
		end
		return
	end

	-- Handle teleport command
	local placeName = parseCommand(message)
	if not placeName then
		return
	end

	local placeId = findPlaceByName(placeName)
	if not placeId then
		warn(("[DevTP] No place found with name '%s'"):format(placeName))
		return
	end

	local success, err = pcall(function()
		TeleportService:Teleport(placeId, player)
	end)

	if not success then
		warn(("[DevTP] Failed to teleport player '%s' to place '%s': %s"):format(player.Name, placeName, tostring(err)))
	end
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

