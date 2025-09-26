local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainDataStore = require(ReplicatedStorage:FindFirstChild("MainDataStore"))

-- Debounce table for inventory saves per player
local inventorySaveDebounce = {}
local DEBOUNCE_TIME = 1 -- seconds

-- Track if player is respawning to prevent saving empty inventory
local respawningPlayers = {}

-- Save backpack tool names AND equipped tool names to DataStore, with debounce
local function SavePlayerInventory(player)
    local userId = player.UserId
    local now = os.clock()
    if inventorySaveDebounce[userId] and (now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME) then
        inventorySaveDebounce[userId].pending = true
        return
    end

    local function doSave()
        -- Don't save if player is respawning
        if respawningPlayers and respawningPlayers[userId] then
            print("[InventoryManager] Skipping save for", player.Name, "- player is respawning")
            return
        end
        
        local backpack = player:FindFirstChild("Backpack")
        local character = player.Character
        local inventory = {}
        local equipped = {}

        if backpack then
            for i, item in backpack:GetChildren() do
                if item:IsA("Tool") then
                    table.insert(inventory, item.Name)
                end
            end
        end

        if character then
            for i, item in character:GetChildren() do
                if item:IsA("Tool") then
                    table.insert(equipped, item.Name)
                end
            end
        end

        print("[InventoryManager] Saving inventory for", player.Name, "- Backpack:", #inventory, "items, Equipped:", #equipped, "items")
        
        -- Don't save empty inventory - this prevents overwriting good data
        if #inventory == 0 and #equipped == 0 then
            print("[InventoryManager] Skipping save for", player.Name, "- no items to save (preventing empty overwrite)")
            return
        end
        
        MainDataStore.SaveInventory(player.UserId, {inventory = inventory, equipped = equipped})
        print("[InventoryManager] Successfully saved inventory for", player.Name)
        inventorySaveDebounce[userId].lastSave = os.clock()
        inventorySaveDebounce[userId].pending = false
    end

    if not inventorySaveDebounce[userId] then
        inventorySaveDebounce[userId] = {lastSave = 0, pending = false}
    end

    if now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME then
        if not inventorySaveDebounce[userId].pending then
            inventorySaveDebounce[userId].pending = true
            task.delay(DEBOUNCE_TIME - (now - inventorySaveDebounce[userId].lastSave), function()
                if inventorySaveDebounce[userId] and inventorySaveDebounce[userId].pending then
                    doSave()
                end
            end)
        end
    else
        doSave()
    end
end

-- Load inventory (tool names) and give corresponding tools from Workspace
local function LoadPlayerInventory(player)
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        backpack = player:WaitForChild("Backpack")
    end
    
    -- Wait for character if we need to load equipped items
    local character = player.Character
    if not character then
        character = player:WaitForChild("Character")
    end
    
    local inventoryData = MainDataStore.LoadInventory(player.UserId)
    local inventory = inventoryData.inventory or {}
    local equipped = inventoryData.equipped or {}
    local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
    if not assetsFolder then
        warn("[InventoryManager] Assets folder not found in ReplicatedStorage for", player.Name)
        return
    end

    print("[InventoryManager] Loading from DataStore for", player.Name, "- Backpack:", #inventory, "items, Equipped:", #equipped, "items")

    -- Load Backpack tools first
    local loadedBackpack = 0
    for i, toolName in inventory do
        local asset = assetsFolder:FindFirstChild(toolName)
        if asset and asset:IsA("Tool") then
            asset:Clone().Parent = backpack
            loadedBackpack = loadedBackpack + 1
        else
            warn("[InventoryManager] Asset not found for backpack item:", toolName)
        end
    end

    -- Load Equipped tools (to Character) - like joining the server
    local loadedEquipped = 0
    if character and #equipped > 0 then
        -- Use task.spawn to avoid blocking
        task.spawn(function()
            -- Wait longer for character to be fully loaded before equipping
            task.wait(2)
            
            for i, toolName in equipped do
                print("[InventoryManager] Trying to equip:", toolName)
                local asset = assetsFolder:FindFirstChild(toolName)
                if asset and asset:IsA("Tool") then
                    if not character:FindFirstChild(toolName) then
                        local clonedTool = asset:Clone()
                        clonedTool.Parent = character
                        loadedEquipped = loadedEquipped + 1
                        print("[InventoryManager] Successfully equipped", toolName, "for", player.Name)
                        
                        -- Wait a moment and check if it actually got equipped
                        task.wait(0.5)
                        if character:FindFirstChild(toolName) then
                            print("[InventoryManager] Confirmed:", toolName, "is now in character")
                        else
                            print("[InventoryManager] WARNING:", toolName, "was not equipped properly")
                        end
                    else
                        -- Already equipped, put in backpack instead
                        asset:Clone().Parent = backpack
                        loadedBackpack = loadedBackpack + 1
                        print("[InventoryManager] Tool", toolName, "already equipped, moved to backpack")
                    end
                else
                    warn("[InventoryManager] Asset not found for equipped item:", toolName)
                end
            end
        end)
    end
    
    print("[InventoryManager] Successfully loaded", loadedBackpack, "backpack items and", loadedEquipped, "equipped items for", player.Name)
end

           -- Bind events to save inventory ONLY when tools are added/removed from Backpack or Character
local function BindInventoryEvents(player)
    local backpack = player:WaitForChild("Backpack")
    backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and not (respawningPlayers and respawningPlayers[player.UserId]) then
            SavePlayerInventory(player)
        end
    end)
    backpack.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and not (respawningPlayers and respawningPlayers[player.UserId]) then
            SavePlayerInventory(player)
        end
    end)
    -- Bind Character tool events
    local function bindCharacter(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and not (respawningPlayers and respawningPlayers[player.UserId]) then
                SavePlayerInventory(player)
            end
        end)
        character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and not (respawningPlayers and respawningPlayers[player.UserId]) then
                SavePlayerInventory(player)
            end
        end)
    end
    if player.Character then
        bindCharacter(player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        bindCharacter(character)
    end)
end

local function OnCharacterAdded(character, player)
    -- Check if player has existing inventory data
    local inventoryData = MainDataStore.LoadInventory(player.UserId)
    local hasInventory = (inventoryData.inventory and #inventoryData.inventory > 0) or (inventoryData.equipped and #inventoryData.equipped > 0)
    
    -- Only mark as respawning if they have inventory data to protect
    if hasInventory then
        respawningPlayers[player.UserId] = true
        print("[InventoryManager] Player", player.Name, "has inventory data - protecting from overwrite during respawn")
    else
        print("[InventoryManager] Player", player.Name, "has no inventory data - normal loading")
    end
    
    -- Use task.spawn to avoid blocking
    task.spawn(function()
        -- Wait for Backpack to exist before loading inventory
        local backpack = player:WaitForChild("Backpack")
        
        -- Add a small delay to ensure character is fully loaded
        task.wait(1)
        
        LoadPlayerInventory(player)
        BindInventoryEvents(player)
        
        -- Clear respawning flag after loading is complete
        if respawningPlayers[player.UserId] then
            task.wait(2) -- Give extra time for all tools to be loaded
            respawningPlayers[player.UserId] = false
            print("[InventoryManager] Finished respawning for", player.Name, "- inventory saving re-enabled")
        end
    end)
end

local function OnPlayerAdded(player)
    -- Handle character added (including respawns)
    player.CharacterAdded:Connect(function(character)
        print("[InventoryManager] Character added for", player.Name, "- loading inventory from DataStore")
        OnCharacterAdded(character, player)
    end)
    
    -- Handle character removing (when player dies) - save inventory and mark as respawning
    player.CharacterRemoving:Connect(function(character)
        print("[InventoryManager] Character removing for", player.Name, "- saving inventory before death")
        -- Save inventory before marking as respawning
        SavePlayerInventory(player)
        -- Mark as respawning to prevent further saves
        respawningPlayers[player.UserId] = true
    end)
    
    if player.Character then
        print("[InventoryManager] Player", player.Name, "already has character - loading inventory from DataStore")
        OnCharacterAdded(player.Character, player)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for i, player in Players:GetPlayers() do
    OnPlayerAdded(player)
end

