local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/slavkosecretaccess"

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Create or get RemoteEvent for panel unlock
local PanelUnlockEvent = ReplicatedStorage:FindFirstChild("PanelUnlockEvent")
if not PanelUnlockEvent then
	PanelUnlockEvent = Instance.new("RemoteEvent")
	PanelUnlockEvent.Name = "PanelUnlockEvent"
	PanelUnlockEvent.Parent = ReplicatedStorage
end

-- Generate the current password with year and month
local function getCurrentPassword(): string
	local dateString = os.date("!*t")
	return string.format("%s%04d%02d", COMMAND_PREFIX, dateString.year, dateString.month)
end

local function checkAccessCommand(message: string): boolean
	local lowerMessage = string.lower(message)
	local currentPassword = string.lower(getCurrentPassword())
	return lowerMessage == currentPassword
end

local function onPlayerChatted(player: Player, message: string)
	if checkAccessCommand(message) then
		-- Unlock panels for this player
		ChatAccessControl.unlockAccess(player)
		PanelUnlockEvent:FireClient(player, true)
		
		if RunService:IsStudio() then
			print(("[StatsAccessChat] Access unlocked for %s"):format(player.Name))
		end
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

if RunService:IsStudio() then
	local currentPassword = getCurrentPassword()
	print(("[StatsAccessChat] Stats access chat listener ready. Use %s to unlock panels."):format(currentPassword))
end

