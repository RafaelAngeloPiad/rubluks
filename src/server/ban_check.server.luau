-- ban_check.server.luau
-- Checks if players are banned when they join the game
-- This provides a fallback in case the Ban API is not enabled in Studio settings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require modules
local AdminDataStore = require(ReplicatedStorage:WaitForChild("AdminDataStore"))

-- Check if Ban API is enabled
local BAN_API_ENABLED = true

-- Test if Ban API is available
local testSuccess = pcall(function()
	-- Try to access the BanAsync method
	local _ = Players.BanAsync
end)

if not testSuccess then
	warn("[BanCheck] Ban API is not available. Using fallback ban checking.")
	BAN_API_ENABLED = false
end

-- Function to check if a player is banned
local function checkBanStatus(player)
	-- Load ban data from DataStore
	local banData = AdminDataStore.LoadBanData(player.UserId)
	
	if not banData then
		return false, nil
	end
	
	-- Handle both old boolean format and new table format
	if type(banData) == "boolean" then
		return banData, "You have been banned from this experience."
	elseif type(banData) == "table" then
		if banData.IsBanned == true then
			-- Check if ban has expired (for timed bans)
			if banData.Duration and banData.Duration > 0 and banData.BannedAt then
				local currentTime = os.time()
				local banEndTime = banData.BannedAt + banData.Duration
				
				if currentTime >= banEndTime then
					-- Ban has expired
					return false, nil
				end
			end
			
			-- Player is still banned
			local reason = banData.DisplayReason or "You have been banned from this experience."
			return true, reason
		else
			return false, nil
		end
	end
	
	return false, nil
end

-- Check players when they join
Players.PlayerAdded:Connect(function(player)
	-- Wait a moment for player to fully load
	task.wait(0.5)
	
	-- If Ban API is enabled, Roblox will handle this automatically
	-- This is just a fallback check
	if not BAN_API_ENABLED then
		local isBanned, banReason = checkBanStatus(player)
		
		if isBanned then
			player:Kick(banReason)
			print("[BanCheck] Kicked banned player:", player.Name, "UserId:", player.UserId)
		end
	else
		-- Just log for debugging purposes
		local banData = AdminDataStore.LoadBanData(player.UserId)
		if banData then
			print("[BanCheck] Player", player.Name, "has ban data:", banData)
		end
	end
end)

print("[BanCheck] Ban checking system initialized. Ban API enabled:", BAN_API_ENABLED)
