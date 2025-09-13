-- InventorySync
-- Keeps player's inventory in sync with InventoryStore whenever Backpack or Character is updated
-- Also restores inventory from InventoryStore on player join

local Players = game:GetService("Players")
local InventoryManager = require(game.ServerScriptService.InventoryManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assetsFolder = ReplicatedStorage:FindFirstChild("assets")

-- Helper function to get current inventory (tool names) from Backpack and Character
local function getPlayerInventory(player)
    local inventory = {}
    local backpack = player:FindFirstChild("Backpack") or player.Backpack
    if backpack then
        for i, item in backpack:GetChildren() do
            if item:IsA("Tool") then
                table.insert(inventory, item.Name)
            end
        end
    end
    if player.Character then
        for i, item in player.Character:GetChildren() do
            if item:IsA("Tool") then
                -- Avoid duplicates if already in inventory
                local found = false
                for j, name in inventory do
                    if name == item.Name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(inventory, item.Name)
                end
            end
        end
    end
    return inventory
end

-- Helper function to restore saved inventory to player's Backpack
local function restoreInventory(player)
    local backpack = player:FindFirstChild("Backpack") or player.Backpack
    if not backpack then return end

    local savedInventory = InventoryManager.LoadPlayerInventory(player.UserId)
    if type(savedInventory) ~= "table" then return end

    for i, toolName in savedInventory do
        if assetsFolder then
            local tool = assetsFolder:FindFirstChild(toolName)
            if tool and tool:IsA("Tool") then
                -- Only add if not already in backpack or character
                local alreadyHas = backpack:FindFirstChild(toolName)
                if player.Character then
                    if player.Character:FindFirstChild(toolName) then
                        alreadyHas = true
                    end
                end
                if not alreadyHas then
                    local clonedTool = tool:Clone()
                    clonedTool.Parent = backpack
                end
            end
        end
    end
end

-- Sets up listeners for Backpack and Character changes for a player
local function setupInventorySync(player)
    local backpackConnections = {}
    local characterConnections = {}

    local function disconnectConnections(connections)
        for i, conn in connections do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        for i in connections do
            connections[i] = nil
        end
    end

    local function updateInventory()
        local inventory = getPlayerInventory(player)
        InventoryManager.SavePlayerInventory(player.UserId, inventory)
    end

    local function connectBackpackEvents(backpack)
        disconnectConnections(backpackConnections)
        if backpack then
            table.insert(backpackConnections, backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    updateInventory()
                end
            end))
            table.insert(backpackConnections, backpack.ChildRemoved:Connect(function(child)
                if child:IsA("Tool") then
                    updateInventory()
                end
            end))
            table.insert(backpackConnections, backpack.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("Tool") then
                    updateInventory()
                end
            end))
            table.insert(backpackConnections, backpack.DescendantRemoving:Connect(function(descendant)
                if descendant:IsA("Tool") then
                    updateInventory()
                end
            end))
        end
    end

    local function connectCharacterEvents(character)
        disconnectConnections(characterConnections)
        if character then
            table.insert(characterConnections, character.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    updateInventory()
                end
            end))
            table.insert(characterConnections, character.ChildRemoved:Connect(function(child)
                if child:IsA("Tool") then
                    updateInventory()
                end
            end))
            table.insert(characterConnections, character.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("Tool") then
                    updateInventory()
                end
            end))
            table.insert(characterConnections, character.DescendantRemoving:Connect(function(descendant)
                if descendant:IsA("Tool") then
                    updateInventory()
                end
            end))
        end
    end

    -- Listen for character spawn to ensure Backpack and Character exist
    player.CharacterAdded:Connect(function(character)
        local backpack = player:FindFirstChild("Backpack") or player.Backpack
        connectBackpackEvents(backpack)
        connectCharacterEvents(character)
        restoreInventory(player)
    end)

    -- If character already exists, connect immediately
    if player.Character then
        local backpack = player:FindFirstChild("Backpack") or player.Backpack
        connectBackpackEvents(backpack)
        connectCharacterEvents(player.Character)
        restoreInventory(player)
    end

    -- Listen for backpack changes (rare, but possible)
    player.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" and child:IsA("Backpack") then
            connectBackpackEvents(child)
        end
    end)
end

-- Set up sync for all current players
for i, player in Players:GetPlayers() do
    setupInventorySync(player)
end

-- Set up sync for players who join later
Players.PlayerAdded:Connect(function(player)
    setupInventorySync(player)
end)

-- This script ensures inventory is saved whenever Backpack or Character changes,
-- and restores inventory from InventoryStore when player joins.
-- Uses DescendantAdded/DescendantRemoving to catch all tool movements.

