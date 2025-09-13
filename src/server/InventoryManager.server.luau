-- InventoryManager
-- Handles saving and loading player's inventory (tools) using InventoryStore DataStore

local DataStoreService = game:GetService("DataStoreService")
local InventoryStore = DataStoreService:GetDataStore("InventoryStore")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assetsFolder = ReplicatedStorage:FindFirstChild("assets")

local InventoryManager = {}

-- Loads the player's inventory from InventoryStore
-- Returns a table of tool names, or an empty table if none found
function InventoryManager.LoadPlayerInventory(userId)
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

-- Saves the player's inventory (table of tool names) to InventoryStore
function InventoryManager.SavePlayerInventory(userId, inventoryTable)
    local key = "Player_" .. userId
    local success, err = pcall(function()
        InventoryStore:SetAsync(key, inventoryTable)
    end)
    return success, err
end

-- Gets all available tool names from assets folder in ReplicatedStorage
function InventoryManager.GetAvailableTools()
    local tools = {}
    if assetsFolder then
        for i, item in assetsFolder:GetChildren() do
            if item:IsA("Tool") then
                table.insert(tools, item.Name)
            end
        end
    end
    return tools
end

return InventoryManager

