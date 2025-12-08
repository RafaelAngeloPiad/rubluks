-- command_help_chat.server.luau
-- Handles /commands chat command to show help (requires admin access)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Create or get RemoteEvent for command help
local CommandHelpEvent = ReplicatedStorage:FindFirstChild("CommandHelpEvent")
if not CommandHelpEvent then
	CommandHelpEvent = Instance.new("RemoteEvent")
	CommandHelpEvent.Name = "CommandHelpEvent"
	CommandHelpEvent.Parent = ReplicatedStorage
end

-- Listen for player chat
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local lowerMessage = string.lower(message)
		
		-- Check for /commands command
		if lowerMessage == "/commands" then
			-- Check if player has unlocked access
			if not ChatAccessControl.hasAccess(player) then
				return -- Player doesn't have access
			end
			
			-- Toggle commands UI
			CommandHelpEvent:FireClient(player, "toggle")
		end
	end)
end)

print("[CommandHelp] Command help system initialized")
