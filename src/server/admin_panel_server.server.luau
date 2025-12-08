-- admin_panel_server.server.luau
-- Handles server-side logic for the admin panel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require modules
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))
local AdminDataStore = require(ReplicatedStorage:WaitForChild("AdminDataStore"))

-- Create RemoteEvents
local AdminPanelRequest = ReplicatedStorage:FindFirstChild("AdminPanelRequest")
if not AdminPanelRequest then
	AdminPanelRequest = Instance.new("RemoteEvent")
	AdminPanelRequest.Name = "AdminPanelRequest"
	AdminPanelRequest.Parent = ReplicatedStorage
end

local AdminPanelUpdate = ReplicatedStorage:FindFirstChild("AdminPanelUpdate")
if not AdminPanelUpdate then
	AdminPanelUpdate = Instance.new("RemoteEvent")
	AdminPanelUpdate.Name = "AdminPanelUpdate"
	AdminPanelUpdate.Parent = ReplicatedStorage
end

-- Function to get player list with admin status
local function getPlayerList()
	local playerList = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(playerList, {
			UserId = player.UserId,
			Name = player.Name,
			DisplayName = player.DisplayName,
			IsAdmin = ChatAccessControl.hasAdminAccess(player),
			IsSuperAdmin = ChatAccessControl.isSuperAdmin(player)
		})
	end
	
	return playerList
end

-- Handle client requests
AdminPanelRequest.OnServerEvent:Connect(function(player, action, targetUserId)
	-- Verify player is a super admin
	if not ChatAccessControl.isSuperAdmin(player) then
		warn("[AdminPanel] Unauthorized access attempt from", player.Name)
		return
	end
	
	if action == "GetPlayerList" then
		-- Send player list to requesting player
		local playerList = getPlayerList()
		AdminPanelRequest:FireClient(player, "PlayerList", playerList)
		
	elseif action == "GetBannedPlayers" then
		-- Get list of all banned players
		local bannedList = AdminDataStore.GetAllBannedPlayers()
		
		-- Enrich with usernames
		for _, bannedPlayer in ipairs(bannedList) do
			local success, username = pcall(function()
				return Players:GetNameFromUserIdAsync(bannedPlayer.UserId)
			end)
			bannedPlayer.Username = success and username or "Unknown"
		end
		
		AdminPanelRequest:FireClient(player, "BannedPlayersList", bannedList)
		
	elseif action == "ToggleAdmin" then
		-- Toggle admin status for target player
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then
			warn("[AdminPanel] Target player not found:", targetUserId)
			return
		end
		
		-- Don't allow toggling super admins
		if ChatAccessControl.isSuperAdmin(targetPlayer) then
			warn("[AdminPanel] Cannot toggle super admin status")
			return
		end
		
		-- Toggle admin status
		local currentStatus = ChatAccessControl.hasAdminAccess(targetPlayer)
		local newStatus = not currentStatus
		ChatAccessControl.setAdminAccess(targetPlayer, newStatus)
		
		-- Save to DataStore
		AdminDataStore.SaveAdminData(targetUserId, newStatus)
		
		-- Notify all super admins of the change
		for _, superAdmin in ipairs(Players:GetPlayers()) do
			if ChatAccessControl.isSuperAdmin(superAdmin) then
				local playerList = getPlayerList()
				AdminPanelRequest:FireClient(superAdmin, "PlayerList", playerList)
			end
		end
		
	elseif action == "BanPlayer" then
		-- Ban target player using Roblox Ban API
		local banConfig = targetUserId -- This is actually the banConfig table
		
		if not banConfig or type(banConfig) ~= "table" then
			warn("[AdminPanel] Invalid ban configuration")
			return
		end
		
		local targetPlayer = Players:GetPlayerByUserId(banConfig.UserId)
		
		-- Don't allow banning super admins
		if targetPlayer and ChatAccessControl.isSuperAdmin(targetPlayer) then
			warn("[AdminPanel] Cannot ban super admin")
			return
		end
		
		-- Prepare ban configuration for Roblox API
		local banApiConfig = {
			UserIds = {banConfig.UserId},
			Duration = banConfig.Duration or -1, -- -1 for permanent
			DisplayReason = banConfig.DisplayReason or "Violation of experience rules",
			PrivateReason = banConfig.PrivateReason or "",
			ExcludeAltAccounts = banConfig.ExcludeAltAccounts or false,
			ApplyToUniverse = true -- Apply to entire universe
		}
		
		-- Call Roblox Ban API
		local success, errorMsg = pcall(function()
			Players:BanAsync(banApiConfig)
		end)
		
		if success then
			print("[AdminPanel] Successfully banned user:", banConfig.UserId)
			
			-- Save ban info to DataStore for tracking
			AdminDataStore.SaveBanData(banConfig.UserId, {
				IsBanned = true,
				Duration = banConfig.Duration,
				DisplayReason = banConfig.DisplayReason,
				PrivateReason = banConfig.PrivateReason,
				BannedAt = os.time(),
				BannedBy = player.UserId
			})
			
			-- If player is still in game, they will be kicked automatically by Roblox
		else
			warn("[AdminPanel] Failed to ban user:", banConfig.UserId, "Error:", errorMsg)
		end
		
	elseif action == "UnbanPlayer" then
		-- Unban target player using Roblox Ban API
		local targetUserId = targetUserId
		
		-- Call Roblox Unban API
		local success, errorMsg = pcall(function()
			Players:UnbanAsync({
				UserIds = {targetUserId},
				ApplyToUniverse = true
			})
		end)
		
		if success then
			print("[AdminPanel] Successfully unbanned user:", targetUserId)
			
			-- Update DataStore
			AdminDataStore.SaveBanData(targetUserId, {
				IsBanned = false,
				UnbannedAt = os.time(),
				UnbannedBy = player.UserId
			})
		else
			warn("[AdminPanel] Failed to unban user:", targetUserId, "Error:", errorMsg)
		end
		
	elseif action == "KickPlayer" then
		-- Legacy kick functionality (kept for backward compatibility)
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then
			warn("[AdminPanel] Target player not found:", targetUserId)
			return
		end
		
		-- Don't allow kicking super admins
		if ChatAccessControl.isSuperAdmin(targetPlayer) then
			warn("[AdminPanel] Cannot kick super admin")
			return
		end
		
		-- Kick the player
		targetPlayer:Kick("You have been kicked by an administrator.")
	end
end)

-- Notify all super admins when a player joins
Players.PlayerAdded:Connect(function(newPlayer)
	-- Load admin status from DataStore
	local isAdmin = AdminDataStore.LoadAdminData(newPlayer.UserId)
	if isAdmin then
		ChatAccessControl.setAdminAccess(newPlayer, true)
	end
	
	-- Wait a moment for player to fully load
	task.wait(0.5)
	
	-- Notify all super admins
	for _, player in ipairs(Players:GetPlayers()) do
		if ChatAccessControl.isSuperAdmin(player) then
			local playerList = getPlayerList()
			AdminPanelRequest:FireClient(player, "PlayerList", playerList)
		end
	end
end)

-- Notify all super admins when a player leaves
Players.PlayerRemoving:Connect(function(removingPlayer)
	-- Wait a moment
	task.wait(0.1)
	
	-- Notify all super admins
	for _, player in ipairs(Players:GetPlayers()) do
		if ChatAccessControl.isSuperAdmin(player) then
			local playerList = getPlayerList()
			AdminPanelRequest:FireClient(player, "PlayerList", playerList)
		end
	end
end)
