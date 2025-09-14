-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local MainDataStore = require(ReplicatedStorage:FindFirstChild("MainDataStore"))

-- -- Debounce table for inventory saves per player
-- local inventorySaveDebounce = {}
-- local DEBOUNCE_TIME = 1 -- seconds

-- -- Save backpack tool names AND equipped tool names to DataStore, with debounce
-- local function SavePlayerInventory(player)
--     local userId = player.UserId
--     local now = os.clock()
--     if inventorySaveDebounce[userId] and (now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME) then
--         inventorySaveDebounce[userId].pending = true
--         return
--     end

--     local function doSave()
--         local backpack = player:FindFirstChild("Backpack")
--         local character = player.Character
--         local inventory = {}
--         local equipped = {}

--         if backpack then
--             for i, item in backpack:GetChildren() do
--                 if item:IsA("Tool") then
--                     table.insert(inventory, item.Name)
--                 end
--             end
--         end

--         if character then
--             for i, item in character:GetChildren() do
--                 if item:IsA("Tool") then
--                     table.insert(equipped, item.Name)
--                 end
--             end
--         end

--         print("[InventoryManager] Saving inventory for", player.Name, "Inventory:", inventory, "Equipped:", equipped)
--         if #inventory == 0 and #equipped == 0 then
--             print("[InventoryManager] WARNING: Inventory and equipped are empty when saving for", player.Name)
--         end
--         MainDataStore.SaveInventory(player.UserId, {inventory = inventory, equipped = equipped})
--         inventorySaveDebounce[userId].lastSave = os.clock()
--         inventorySaveDebounce[userId].pending = false
--     end

--     if not inventorySaveDebounce[userId] then
--         inventorySaveDebounce[userId] = {lastSave = 0, pending = false}
--     end

--     if now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME then
--         if not inventorySaveDebounce[userId].pending then
--             inventorySaveDebounce[userId].pending = true
--             task.delay(DEBOUNCE_TIME - (now - inventorySaveDebounce[userId].lastSave), function()
--                 if inventorySaveDebounce[userId] and inventorySaveDebounce[userId].pending then
--                     doSave()
--                 end
--             end)
--         end
--     else
--         doSave()
--     end
-- end

-- -- Load inventory (tool names) and give corresponding tools from Workspace
-- local function LoadPlayerInventory(player)
--     local backpack = player:FindFirstChild("Backpack")
--     if not backpack then
--         print("[InventoryManager] Backpack not found for", player.Name, "when loading inventory, waiting for Backpack...")
--         backpack = player:WaitForChild("Backpack")
--     end
    
--     -- Wait for character if we need to load equipped items
--     local character = player.Character
--     if not character then
--         print("[InventoryManager] Character not found for", player.Name, "when loading inventory, waiting for Character...")
--         character = player:WaitForChild("Character")
--     end
    
--     local inventoryData = MainDataStore.LoadInventory(player.UserId)
--     local inventory = inventoryData.inventory or {}
--     local equipped = inventoryData.equipped or {}
--     print("[InventoryManager] Loading inventory for", player.Name, "Inventory:", inventory, "Equipped:", equipped)
--     local workspaceFolder = game:GetService("Workspace")

--     -- Load Backpack tools
--     for i, toolName in inventory do
--         local asset = workspaceFolder:FindFirstChild(toolName)
--         if asset and asset:IsA("Tool") then
--             if not backpack:FindFirstChild(toolName) then
--                 asset:Clone().Parent = backpack
--                 print("[InventoryManager] Cloned tool to Backpack from Workspace:", toolName)
--             end
--         else
--             print("[InventoryManager] Tool asset not found in Workspace for Backpack:", toolName)
--         end
--     end

--     -- Load Equipped tools (to Character)
--     if character and #equipped > 0 then
--         for i, toolName in equipped do
--             local asset = workspaceFolder:FindFirstChild(toolName)
--             if asset and asset:IsA("Tool") then
--                 if not character:FindFirstChild(toolName) then
--                     asset:Clone().Parent = character
--                     print("[InventoryManager] Cloned tool to Character from Workspace:", toolName)
--                 end
--             else
--                 print("[InventoryManager] Tool asset not found in Workspace for Equipped:", toolName)
--             end
--         end
--     end
-- end

-- -- Bind events to save inventory ONLY when tools are added/removed from Backpack or Character
-- local function BindInventoryEvents(player)
--     local backpack = player:WaitForChild("Backpack")
--     backpack.ChildAdded:Connect(function(child)
--         if child:IsA("Tool") then
--             print("[InventoryManager] Backpack ChildAdded:", child.Name)
--             SavePlayerInventory(player)
--         end
--     end)
--     backpack.ChildRemoved:Connect(function(child)
--         if child:IsA("Tool") then
--             print("[InventoryManager] Backpack ChildRemoved:", child.Name)
--             SavePlayerInventory(player)
--         end
--     end)
--     -- Bind Character tool events
--     local function bindCharacter(character)
--         character.ChildAdded:Connect(function(child)
--             if child:IsA("Tool") then
--                 print("[InventoryManager] Character ChildAdded (Equipped):", child.Name)
--                 SavePlayerInventory(player)
--             end
--         end)
--         character.ChildRemoved:Connect(function(child)
--             if child:IsA("Tool") then
--                 print("[InventoryManager] Character ChildRemoved (Unequipped):", child.Name)
--                 SavePlayerInventory(player)
--             end
--         end)
--     end
--     if player.Character then
--         bindCharacter(player.Character)
--     end
--     player.CharacterAdded:Connect(function(character)
--         bindCharacter(character)
--     end)
-- end

-- local function OnCharacterAdded(character, player)
--     -- Wait for Backpack to exist before loading inventory
--     local backpack = player:WaitForChild("Backpack")
--     LoadPlayerInventory(player)
--     BindInventoryEvents(player)
-- end

-- local function OnPlayerAdded(player)
--     print("[InventoryManager] Player added:", player.Name)
--     player.CharacterAdded:Connect(function(character)
--         OnCharacterAdded(character, player)
--     end)
--     if player.Character then
--         OnCharacterAdded(player.Character, player)
--     end
-- end

-- Players.PlayerAdded:Connect(OnPlayerAdded)
-- for i, player in Players:GetPlayers() do
--     OnPlayerAdded(player)
-- end

