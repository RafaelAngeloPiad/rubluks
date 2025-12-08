-- ChatAccessControl.luau
-- Shared module to track which players have unlocked chat commands via the secret password

local ChatAccessControl = {}

-- Super admin user IDs - these players can always access admin panel and have permanent admin rights
local SUPER_ADMIN_IDS = {
	4322011820, -- slavko
	4492443366, -- Carrotman raf
	9385662654, -- RGD_Ross
	10076858241, -- ivan
	9377157057, -- roblocksdev13
	9385483308, -- notallan237
	9774226514 -- raphelios
}

-- Table to track unlocked players by UserId (basic access)
local unlockedPlayers: {[number]: boolean} = {}

-- Table to track players with advanced access (second unlock)
local advancedAccessPlayers: {[number]: boolean} = {}

-- Table to track players with admin access (can use commands)
local adminPlayers: {[number]: boolean} = {}

-- Check if a player has unlocked basic access
function ChatAccessControl.hasAccess(player: Player): boolean
	return unlockedPlayers[player.UserId] == true
end

-- Check if a player has unlocked advanced access (for sensitive features)
function ChatAccessControl.hasAdvancedAccess(player: Player): boolean
	return advancedAccessPlayers[player.UserId] == true
end

-- Unlock basic access for a player
function ChatAccessControl.unlockAccess(player: Player)
	unlockedPlayers[player.UserId] = true
end

-- Unlock advanced access for a player (requires basic access first)
function ChatAccessControl.unlockAdvancedAccess(player: Player)
	advancedAccessPlayers[player.UserId] = true
end

-- Lock access for a player (optional, for future use)
function ChatAccessControl.lockAccess(player: Player)
	unlockedPlayers[player.UserId] = nil
	advancedAccessPlayers[player.UserId] = nil -- Also remove advanced access
end

-- Check if a player is a super admin (hardcoded list)
function ChatAccessControl.isSuperAdmin(player: Player): boolean
	return table.find(SUPER_ADMIN_IDS, player.UserId) ~= nil
end

-- Check if a player has admin access (can use commands)
-- Super admins always have access, others need to be granted access
function ChatAccessControl.hasAdminAccess(player: Player): boolean
	-- Super admins always have admin access
	if ChatAccessControl.isSuperAdmin(player) then
		return true
	end
	-- Check runtime admin status
	return adminPlayers[player.UserId] == true
end

-- Set admin access for a player (grant or revoke)
function ChatAccessControl.setAdminAccess(player: Player, isAdmin: boolean)
	adminPlayers[player.UserId] = isAdmin
end

-- Get all admin player user IDs (for UI display)
function ChatAccessControl.getAdminPlayers(): {[number]: boolean}
	return adminPlayers
end

-- Clean up when player leaves
local Players = game:GetService("Players")

Players.PlayerRemoving:Connect(function(player)
	unlockedPlayers[player.UserId] = nil
	advancedAccessPlayers[player.UserId] = nil
	adminPlayers[player.UserId] = nil
end)

-- Also clean up existing players who may have left
for _, player in ipairs(Players:GetPlayers()) do
	-- Don't clear on startup, just ensure cleanup works
end

return ChatAccessControl

