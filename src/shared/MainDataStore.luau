local DataStoreService = game:GetService("DataStoreService")
local XPStore = DataStoreService:GetDataStore("XPStore")

local MainDataStore = {}

function MainDataStore.LoadPlayerData(userId)
	local key = "Player_" .. userId
	local success, data = pcall(function()
		return XPStore:GetAsync(key)
	end)
	if success and data then
		return data
	else
		return nil
	end
end

function MainDataStore.SavePlayerData(userId, data)
	local key = "Player_" .. userId
	local success, err = pcall(function()
		XPStore:SetAsync(key, data)
	end)
	return success, err
end

return MainDataStore

