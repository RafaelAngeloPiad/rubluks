local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/slavko"

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Create or get RemoteEvent for panel unlock
local PanelUnlockEvent = ReplicatedStorage:FindFirstChild("PanelUnlockEvent")
if not PanelUnlockEvent then
	PanelUnlockEvent = Instance.new("RemoteEvent")
	PanelUnlockEvent.Name = "PanelUnlockEvent"
	PanelUnlockEvent.Parent = ReplicatedStorage
end

-- Create or get RemoteEvent for command help
local CommandHelpEvent = ReplicatedStorage:FindFirstChild("CommandHelpEvent")
if not CommandHelpEvent then
	CommandHelpEvent = Instance.new("RemoteEvent")
	CommandHelpEvent.Name = "CommandHelpEvent"
	CommandHelpEvent.Parent = ReplicatedStorage
end

-- Generate the current password with year and month
local function getCurrentPassword(): string
	local dateString = os.date("!*t")
	return COMMAND_PREFIX
end

local function checkAccessCommand(message: string): boolean
	local lowerMessage = string.lower(message)
	local currentPassword = string.lower(getCurrentPassword())
	return lowerMessage == currentPassword
end

local function onPlayerChatted(player: Player, message: string)
	if checkAccessCommand(message) then
		-- Send helpful notification to ALL players (admin or not)
		print("[StatsAccess] Player", player.Name, "typed /slavko, sending notification")
		CommandHelpEvent:FireClient(player, "hint", "Type /commands to see all available commands!")
		
		-- Check if player has admin access
		if not ChatAccessControl.hasAdminAccess(player) then
			return -- Player doesn't have admin permissions, just show notification
		end
		
		-- Unlock panels for admin players
		ChatAccessControl.unlockAccess(player)
		PanelUnlockEvent:FireClient(player, true)

		return
	end

	-- Second unlock command for advanced features (Reset, XP, Class changing)
	local lowerMessage = string.lower(message)
	if lowerMessage == "/sarapmosirlouie" then
		-- Check if player has basic access first
		if not ChatAccessControl.hasAccess(player) then
			return -- Must unlock basic access first
		end

		-- Unlock advanced features
		ChatAccessControl.unlockAdvancedAccess(player)
		PanelUnlockEvent:FireClient(player, true, true) -- Second parameter = advanced unlock

		return
	end

	-- Handle become SLAVKO command (requires unlocked access)
	local lower = string.lower(message)
	if lower == "/become slavko" then
		if not ChatAccessControl.hasAccess(player) then
			return
		end
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

