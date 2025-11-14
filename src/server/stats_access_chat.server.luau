local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COMMAND_PREFIX = "/slavkosecretaccess"

-- Create or get RemoteEvent for panel unlock
local PanelUnlockEvent = ReplicatedStorage:FindFirstChild("PanelUnlockEvent")
if not PanelUnlockEvent then
	PanelUnlockEvent = Instance.new("RemoteEvent")
	PanelUnlockEvent.Name = "PanelUnlockEvent"
	PanelUnlockEvent.Parent = ReplicatedStorage
end

local function checkAccessCommand(message: string): boolean
	local lowerMessage = string.lower(message)
	return lowerMessage == string.lower(COMMAND_PREFIX) or string.sub(lowerMessage, 1, #COMMAND_PREFIX + 1) == string.lower(COMMAND_PREFIX) .. " "
end

local function onPlayerChatted(player: Player, message: string)
	if checkAccessCommand(message) then
		-- Unlock panels for this player
		PanelUnlockEvent:FireClient(player, true)
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
	print("[StatsAccessChat] Stats access chat listener ready. Use /access to unlock panels.")
end

