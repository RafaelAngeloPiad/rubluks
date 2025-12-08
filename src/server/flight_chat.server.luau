-- flight_chat.server.luau
-- Handles /flight and /flightoff chat commands

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FLIGHT_COMMAND = "/flight"
local FLIGHT_OFF_COMMAND = "/flightoff"

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Create RemoteEvent for flight control
local FlightEvent = ReplicatedStorage:FindFirstChild("FlightEvent")
if not FlightEvent then
	FlightEvent = Instance.new("RemoteEvent")
	FlightEvent.Name = "FlightEvent"
	FlightEvent.Parent = ReplicatedStorage
end

-- Listen for server events from buttons
FlightEvent.OnServerEvent:Connect(function(player, action)
	-- Check if player has unlocked access
	if not ChatAccessControl.hasAccess(player) then
		return
	end
	
	if action == "enable" then
		-- Enable flight for player
		FlightEvent:FireClient(player, "enable")
		print("[Flight] Enabled flight for", player.Name)
	elseif action == "disable" then
		-- Disable flight for player
		FlightEvent:FireClient(player, "disable")
		print("[Flight] Disabled flight for", player.Name)
	end
end)

-- Listen for player chat
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local lowerMessage = string.lower(message)
		
		-- Check if player has unlocked access
		if not ChatAccessControl.hasAccess(player) then
			return
		end
		
		-- Check for /flight command
		if lowerMessage == FLIGHT_COMMAND then
			-- Enable flight for player
			FlightEvent:FireClient(player, "enable")
			print("[Flight] Enabled flight for", player.Name)
			
		-- Check for /flightoff command
		elseif lowerMessage == FLIGHT_OFF_COMMAND then
			-- Disable flight for player
			FlightEvent:FireClient(player, "disable")
			print("[Flight] Disabled flight for", player.Name)
		end
	end)
end)

print("[Flight] Flight system initialized")
