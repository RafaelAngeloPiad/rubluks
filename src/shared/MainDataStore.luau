local DataStoreService = game:GetService("DataStoreService")
local PlayerStoreData = DataStoreService:GetDataStore("PlayerStoreData") -- Player Manager
local InventoryStore = DataStoreService:GetDataStore("InventoryStore") -- Inventory Manager

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
	end

	return success, err
end

-- InventoryStore now stores a table: {inventory = {...}, equipped = {...}}
function MainDataStore.LoadInventory(userId)
	local key = "Player_" .. userId
	local success, data = pcall(function()
		return InventoryStore:GetAsync(key)
	end)
	if success then
		if typeof(data) == "table" then
			-- Ensure both inventory and equipped arrays exist
			data.inventory = data.inventory or {}
			data.equipped = data.equipped or {}
			return data
		elseif data == nil then
			return {inventory = {}, equipped = {}}
		else
			return {inventory = {}, equipped = {}}
		end
	else
		return {inventory = {}, equipped = {}}
	end
end

function MainDataStore.SaveInventory(userId, inventoryTable)
	local key = "Player_" .. userId
	-- Ensure inventoryTable is a table with inventory and equipped arrays
	local filteredInventory = {}
	local filteredEquipped = {}
	if typeof(inventoryTable) == "table" then
		if typeof(inventoryTable.inventory) == "table" then
			for i, v in inventoryTable.inventory do
				if typeof(v) == "string" then
					table.insert(filteredInventory, v)
				end
			end
		end
		if typeof(inventoryTable.equipped) == "table" then
			for i, v in inventoryTable.equipped do
				if typeof(v) == "string" then
					table.insert(filteredEquipped, v)
				end
			end
		end
	end
	local saveData = {
		inventory = filteredInventory,
		equipped = filteredEquipped
	}
	local success, err = pcall(function()
		InventoryStore:SetAsync(key, saveData)
	end)
	return success, err
end

return MainDataStore

