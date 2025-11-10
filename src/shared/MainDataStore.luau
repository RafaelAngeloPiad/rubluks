local DataStoreService = game:GetService("DataStoreService")
local PlayerStoreData = DataStoreService:GetDataStore("PlayerStoreData")
local InventoryStore = DataStoreService:GetDataStore("InventoryStore")
local SunfireStore = DataStoreService:GetDataStore("SunfireStore")

local MainDataStore = {}

function MainDataStore.LoadPlayerData(userId)
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return PlayerStoreData:GetAsync(key)
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
		PlayerStoreData:SetAsync(key, data)
	end)

	if not success then
		warn("Failed saving PlayerStoreData:", err)
	end

	return success, err
end

function MainDataStore.LoadInventory(userId)
	local key = "Player_" .. userId
	local success, data = pcall(function()
		return InventoryStore:GetAsync(key)
	end)
	if success then
		if typeof(data) == "table" then
			data.inventory = data.inventory or {}
			data.equipped = data.equipped or {}
			data.consumables = data.consumables or {}
			return data
		elseif data == nil then
			return {inventory = {}, equipped = {}, consumables = {}}
		else
			return {inventory = {}, equipped = {}, consumables = {}}
		end
	else
		return {inventory = {}, equipped = {}, consumables = {}}
	end
end

function MainDataStore.SaveInventory(userId, inventoryTable)
	local key = "Player_" .. userId
	local filteredInventory = {}
	local filteredEquipped = {}
	local filteredConsumables = {}
	if typeof(inventoryTable) == "table" then
		if typeof(inventoryTable.inventory) == "table" then
			for _, v in inventoryTable.inventory do
				if typeof(v) == "string" then
					table.insert(filteredInventory, v)
				end
			end
		end
		if typeof(inventoryTable.equipped) == "table" then
			for _, v in inventoryTable.equipped do
				if typeof(v) == "string" then
					table.insert(filteredEquipped, v)
				end
			end
		end
		if typeof(inventoryTable.consumables) == "table" then
			for _, v in inventoryTable.consumables do
				if typeof(v) == "string" then
					table.insert(filteredConsumables, v)
				end
			end
		end
	end
	local saveData = {
		inventory = filteredInventory,
		equipped = filteredEquipped,
		consumables = filteredConsumables,
	}

	local success, err = pcall(function()
		InventoryStore:SetAsync(key, saveData)
	end)

	if not success then
		warn("Failed saving InventoryStore:", err)
	end

	return success, err
end

-- SUNFIRE MAINDATASTORE

function MainDataStore.LoadSunfireProgress(userId)
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return SunfireStore:GetAsync(key)
	end)

	if success and data then
		return data
	else
		return nil
	end
end

function MainDataStore.SaveSunfireProgress(userId, data)
	local key = "Player_" .. userId

	local success, err = pcall(function()
		SunfireStore:SetAsync(key, data)
	end)

	if not success then
		warn("Failed saving SunfireStore:", err)
	end

	return success, err
end

return MainDataStore