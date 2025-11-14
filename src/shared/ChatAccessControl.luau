-- ChatAccessControl.luau
-- Shared module to track which players have unlocked chat commands via the secret password

local ChatAccessControl = {}

-- Table to track unlocked players by UserId
local unlockedPlayers: {[number]: boolean} = {}

-- Check if a player has unlocked access
function ChatAccessControl.hasAccess(player: Player): boolean
	return unlockedPlayers[player.UserId] == true
end

-- Unlock access for a player
function ChatAccessControl.unlockAccess(player: Player)
	unlockedPlayers[player.UserId] = true
end

-- Lock access for a player (optional, for future use)
function ChatAccessControl.lockAccess(player: Player)
	unlockedPlayers[player.UserId] = nil
end

-- Clean up when player leaves
local Players = game:GetService("Players")

Players.PlayerRemoving:Connect(function(player)
	unlockedPlayers[player.UserId] = nil
end)

-- Also clean up existing players who may have left
for _, player in ipairs(Players:GetPlayers()) do
	-- Don't clear on startup, just ensure cleanup works
end

return ChatAccessControl

