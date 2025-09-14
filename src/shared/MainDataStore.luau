local DataStoreService = game:GetService("DataStoreService")
local XPStore = DataStoreService:GetDataStore("XPStore")
local InventoryStore = DataStoreService:GetDataStore("InventoryStore")

local MainDataStore = {}

function MainDataStore.LoadPlayerData(userId)
    local key = "Player_" .. userId
    local success, data = pcall(function()
        return XPStore:GetAsync(key)
    end)
    if success and data then
        return data
    else
        warn("[MainDataStore] Failed to load XP for key:", key, "Error:", data)
        return nil
    end
end

function MainDataStore.SavePlayerData(userId, data)
    local key = "Player_" .. userId
    local success, err = pcall(function()
        XPStore:SetAsync(key, data)
    end)
    if not success then
        warn("[MainDataStore] Failed to save XP for key:", key, "Error:", err)
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
            print("[MainDataStore] Loaded inventory for key:", key, "Inventory:", data)
            -- Ensure both inventory and equipped arrays exist
            data.inventory = data.inventory or {}
            data.equipped = data.equipped or {}
            return data
        elseif data == nil then
            print("[MainDataStore] No inventory found for key:", key)
            return {inventory = {}, equipped = {}}
        else
            warn("[MainDataStore] Unexpected inventory format for key:", key, "Data:", data)
            return {inventory = {}, equipped = {}}
        end
    else
        warn("[MainDataStore] Failed to load inventory for key:", key, "Error:", data)
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
    print("[MainDataStore] Attempting to save inventory for key:", key, "Inventory:", saveData)
    local success, err = pcall(function()
        InventoryStore:SetAsync(key, saveData)
    end)
    if not success then
        warn("[MainDataStore] Failed to save inventory for key:", key, "Error:", err)
    else
        print("[MainDataStore] Saved inventory for key:", key, "Inventory:", saveData)
    end
    return success, err
end

return MainDataStore

