-- admin_chat.server.luau
-- Handles the /admin command to open the admin panel for authorized users

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require access control module
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))

-- Create or get RemoteEvent for admin panel toggle
local AdminPanelToggle = ReplicatedStorage:FindFirstChild("AdminPanelToggle")
if not AdminPanelToggle then
	AdminPanelToggle = Instance.new("RemoteEvent")
	AdminPanelToggle.Name = "AdminPanelToggle"
	AdminPanelToggle.Parent = ReplicatedStorage
end

-- Listen for server events from buttons
AdminPanelToggle.OnServerEvent:Connect(function(player)
	-- Check if player is a super admin
	if not ChatAccessControl.isSuperAdmin(player) then
		return
	end
	
	-- Toggle admin panel for this player
	AdminPanelToggle:FireClient(player)
	print("[AdminPanel] Toggled for", player.Name)
end)

local function onPlayerChatted(player: Player, message: string)
	-- Check if message is /admin command
	local lowerMessage = string.lower(message)
	if lowerMessage ~= "/admin" then
		return
	end
	
	-- Check if player is a super admin
	if not ChatAccessControl.isSuperAdmin(player) then
		return
	end
	
	-- Toggle admin panel for this player
	AdminPanelToggle:FireClient(player)
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
