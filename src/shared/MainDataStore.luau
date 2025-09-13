local DataStoreService = game:GetService("DataStoreService")
local XPStore = DataStoreService:GetDataStore("XPStore")
local InventoryStore = DataStoreService:GetDataStore("InventoryStore")

local MainDataStore = {}

-- Loads XP data for a player
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

-- Saves XP data for a player
function MainDataStore.SavePlayerData(userId, data)
    local key = "Player_" .. userId
    local success, err = pcall(function()
        XPStore:SetAsync(key, data)
    end)
    return success, err
end

-- Loads inventory data for a player
function MainDataStore.LoadPlayerInventory(userId)
    local key = "Player_" .. userId
    local success, data = pcall(function()
        return InventoryStore:GetAsync(key)
    end)
    if success and data then
        return data
    else
        return {}
    end
end

-- Saves inventory data for a player
function MainDataStore.SavePlayerInventory(userId, inventoryTable)
    local key = "Player_" .. userId
    local success, err = pcall(function()
        InventoryStore:SetAsync(key, inventoryTable)
    end)
    return success, err
end

return MainDataStore
