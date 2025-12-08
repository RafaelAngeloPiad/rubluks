-- AdminDataStore.luau
-- Handles persistence of admin permissions and ban status for players

local DataStoreService = game:GetService("DataStoreService")
local AdminStore = DataStoreService:GetDataStore("AdminStore")

local AdminDataStore = {}

-- Load admin status for a player
function AdminDataStore.LoadAdminData(userId: number): boolean
	local key = "Admin_" .. userId
	
	local success, data = pcall(function()
		return AdminStore:GetAsync(key)
	end)
	
	if success and data ~= nil then
		return data == true
	else
		return false
	end
end

-- Save admin status for a player
function AdminDataStore.SaveAdminData(userId: number, isAdmin: boolean): (boolean, string?)
	local key = "Admin_" .. userId
	
	local success, err = pcall(function()
		AdminStore:SetAsync(key, isAdmin)
	end)
	
	if not success then
		warn("[AdminDataStore] Failed saving admin data for userId", userId, ":", err)
	end
	
	return success, err
end

-- Load ban status for a player
function AdminDataStore.LoadBanData(userId: number): any
	local key = "Ban_" .. userId
	
	local success, data = pcall(function()
		return AdminStore:GetAsync(key)
	end)
	
	if success and data ~= nil then
		return data
	else
		return nil
	end
end

-- Save ban status for a player
function AdminDataStore.SaveBanData(userId: number, banData: boolean | table): (boolean, string?)
	local key = "Ban_" .. userId
	
	local success, err = pcall(function()
		AdminStore:SetAsync(key, banData)
	end)
	
	if not success then
		warn("[AdminDataStore] Failed saving ban data for userId", userId, ":", err)
	end
	
	return success, err
end

-- Get all banned players
function AdminDataStore.GetAllBannedPlayers(): {any}
	local bannedPlayers = {}
	
	local success, pages = pcall(function()
		return AdminStore:ListKeysAsync("Ban_")
	end)
	
	if not success then
		warn("[AdminDataStore] Failed to list banned players")
		return bannedPlayers
	end
	
	while true do
		local keys = pages:GetCurrentPage()
		
		for _, keyInfo in ipairs(keys) do
			local userId = tonumber(string.match(keyInfo.KeyName, "Ban_(%d+)"))
			if userId then
				local banData = AdminDataStore.LoadBanData(userId)
				if banData and banData.IsBanned then
					table.insert(bannedPlayers, {
						UserId = userId,
						BanData = banData
					})
				end
			end
		end
		
		if pages.IsFinished then
			break
		end
		
		pages:AdvanceToNextPageAsync()
	end
	
	return bannedPlayers
end

return AdminDataStore
