local DataStoreService = game:GetService("DataStoreService")
local PlayerStoreData = DataStoreService:GetDataStore("PlayerStoreData") -- Player Manager
local InventoryStore = DataStoreService:GetDataStore("InventoryStore") -- Inventory Manager
local SunfireStore = DataStoreService:GetDataStore("SunfireStore") -- Sunfire Manager

local MainDataStore = {}

function MainDataStore.LoadPlayerData(userId)

	local key = "Player_" .. userId

	-- Player Manager
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

	-- Player Manager
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
	local attempts = 0
	local success, data

	repeat
		attempts += 1
		success, data = pcall(function()
			return InventoryStore:GetAsync(key)
		end)

		if not success then
			warn("[InventoryStore] LoadInventory failed (attempt " .. attempts .. ") for userId", userId, ":", data)
			if attempts < 3 then
				task.wait(0.5)
			end
		end
	until success or attempts >= 3

	if not success then
		warn("[InventoryStore] LoadInventory giving up for userId", userId, "- returning empty state")
		return {
			inventory = {},
			equipped = {},
			consumables = {},
			helmet = nil,
		}
	end

	if data == nil then
		print("[InventoryStore] LoadInventory: no data for userId", userId, "- returning new empty state")
		return {
			inventory = {},
			equipped = {},
			consumables = {},
			helmet = nil,
		}
	end

	if typeof(data) ~= "table" then
		warn("[InventoryStore] LoadInventory: unexpected data type for userId", userId, ":", typeof(data))
		return {
			inventory = {},
			equipped = {},
			consumables = {},
			helmet = nil,
		}
	end

	-- Backwards compatibility: older format may have been a plain array of strings
	if data.inventory == nil and data.equipped == nil then
		-- Treat the root table as the inventory list
		local legacyInventory = {}
		for index, value in ipairs(data) do
			if typeof(value) == "string" then
				table.insert(legacyInventory, value)
			end
		end
		data = {
			inventory = legacyInventory,
			equipped = {},
			consumables = {},
			helmet = nil,
		}
	end

	-- Normalise expected fields
	data.inventory = data.inventory or {}
	data.equipped = data.equipped or {}
	data.consumables = data.consumables or {}
	data.helmet = data.helmet

	print(
		"[InventoryStore] LoadInventory OK for userId",
		userId,
		"| inventory =", #data.inventory,
		"equipped =", #data.equipped,
		"consumables =", #data.consumables,
		"helmet =", data.helmet
	)

	return data
end

function MainDataStore.SaveInventory(userId, inventoryTable)
	local key = "Player_" .. userId
	-- Ensure inventoryTable is a table with inventory/equipped arrays (and optional consumables/helmet)
	local filteredInventory = {}
	local filteredEquipped = {}
	local filteredConsumables = {}
	local helmet: string? = nil

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
		if typeof(inventoryTable.consumables) == "table" then
			for i, v in inventoryTable.consumables do
				if typeof(v) == "string" then
					table.insert(filteredConsumables, v)
				end
			end
		end
		if typeof(inventoryTable.helmet) == "string" then
			helmet = inventoryTable.helmet
		end
	end
	local saveData = {
		inventory = filteredInventory,
		equipped = filteredEquipped,
		consumables = filteredConsumables,
		helmet = helmet,
	}
	local success, err = pcall(function()
		InventoryStore:SetAsync(key, saveData)
	end)
	if success then
		print(
			"[InventoryStore] SaveInventory OK for userId",
			userId,
			"| inventory =", #filteredInventory,
			"equipped =", #filteredEquipped,
			"consumables =", #filteredConsumables,
			"helmet =", helmet
		)
	else
		warn("[InventoryStore] SaveInventory failed for userId", userId, ":", err)
	end
	return success, err
end

---------- SUNFIRE MAINDATASTORE

function MainDataStore.LoadSunfireProgress(userId)

	local key = "Player_" .. userId

	-- Sunfire Manager
	local success2, data2 = pcall(function()
		return SunfireStore:GetAsync(key)
	end)

	if success2 and data2 then
		return data2
	else
		return nil
	end

end

function MainDataStore.SaveSunfireProgress(userId, data)

	local key = "Player_" .. userId

	-- Sunfire Manager
	local success2, err2 = pcall(function()
		SunfireStore:SetAsync(key, data)
	end)

	if not success2 then
		warn("Failed saving SunfireStore:", err2)
	end

	return success2, err2
end

return MainDataStore