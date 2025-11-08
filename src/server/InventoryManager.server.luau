local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainDataStore = require(ReplicatedStorage:FindFirstChild("MainDataStore"))

-- Debounce table for inventory saves per player
local inventorySaveDebounce = {}
local DEBOUNCE_TIME = 1 -- seconds

-- Track when players are dying to prevent saving unequipped state
local playerDying = {}

-- Save backpack tool names AND equipped tool names to DataStore, with debounce
local function SavePlayerInventory(player)
	local userId = player.UserId
	local now = os.clock()
	if inventorySaveDebounce[userId] and (now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME) then
		inventorySaveDebounce[userId].pending = true
		return
	end

	local function doSave()
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

		-- If both are empty, try to load from DataStore first to preserve existing data
		if #inventory == 0 and #equipped == 0 then
			local existingData = MainDataStore.LoadInventory(player.UserId)
			if existingData and (existingData.inventory and #existingData.inventory > 0 or existingData.equipped and #existingData.equipped > 0) then
				inventory = existingData.inventory or {}
				equipped = existingData.equipped or {}
			end
		end

		MainDataStore.SaveInventory(player.UserId, {inventory = inventory, equipped = equipped})
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
	-- Wait for character and backpack to be fully loaded
	local character = player.Character
	if not character then
		character = player:WaitForChild("Character")
	end
	
	-- Wait for humanoid to ensure character is fully loaded
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Wait for backpack
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack")
	end

	-- Additional wait to ensure everything is properly loaded
	task.wait(0.5)

	local inventoryData = MainDataStore.LoadInventory(player.UserId)
	local inventory = inventoryData.inventory or {}
	local equipped = inventoryData.equipped or {}
	local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
	if not assetsFolder then
		warn("[InventoryManager] Assets folder not found in ReplicatedStorage for", player.Name)
		return
	end


	-- Load Backpack tools (allow duplicates - these come from DataStore)
	for i, toolName in inventory do
		local asset = assetsFolder:FindFirstChild(toolName)
		if asset and asset:IsA("Tool") then
			asset:Clone().Parent = backpack
		else
			warn("[InventoryManager] Tool not found:", toolName)
		end
	end

	-- Load Equipped tools (to Character) - prevent duplicates for equipped items
	if character and #equipped > 0 then
		for i, toolName in equipped do
			local asset = assetsFolder:FindFirstChild(toolName)
			if asset and asset:IsA("Tool") then
				if not character:FindFirstChild(toolName) then
					asset:Clone().Parent = character
				end
			end
		end
	end

	if _G.refreshEquipmentBonuses then
		_G.refreshEquipmentBonuses(player)
	end
end

-- Bind events to save inventory ONLY when tools are added/removed from Backpack or Character
local function BindInventoryEvents(player)
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			SavePlayerInventory(player)
		end
	end)
	backpack.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			SavePlayerInventory(player)
		end
	end)
	-- Bind Character tool events
	local function bindCharacter(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") or child:IsA("Accessory") then
				SavePlayerInventory(player)
				if _G.refreshEquipmentBonuses then
					task.defer(_G.refreshEquipmentBonuses, player)
				end
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") or child:IsA("Accessory") then
				-- Only save if player is not dying (to prevent losing equipped weapon on death)
				if not playerDying[player.UserId] then
					SavePlayerInventory(player)
				end
				if _G.refreshEquipmentBonuses then
					task.defer(_G.refreshEquipmentBonuses, player)
				end
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

-- Remove MoveEquippedToBackpack function - we don't want to modify DataStore on death

local function OnCharacterAdded(character, player)
	-- Wait for Backpack to exist before loading inventory
	local backpack = player:WaitForChild("Backpack")

	-- Add delay after respawn to prevent inventory loss (like rejoining server)
	task.wait(3)

	LoadPlayerInventory(player)
	BindInventoryEvents(player)

		-- Simple death detection - save inventory when player dies
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.HealthChanged:Connect(function(health)
			if health <= 0 then
				-- Mark player as dying to prevent saving unequipped state
				playerDying[player.UserId] = true
				
				-- Add small delay to ensure equipped tools are still there
				task.wait(0.1)
				
				-- Get the current state from DataStore to preserve everything
				local existingData = MainDataStore.LoadInventory(player.UserId)
				local inventory = existingData.inventory or {}
				local equipped = existingData.equipped or {}
				
				-- Get current backpack items and merge with existing inventory
				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					local currentBackpack = {}
					for i, item in backpack:GetChildren() do
						if item:IsA("Tool") then
							table.insert(currentBackpack, item.Name)
						end
					end
					-- Only update if we have items in backpack (to preserve existing inventory)
					if #currentBackpack > 0 then
						inventory = currentBackpack
					end
				end

				-- Get current equipped items (should be empty on death, but preserve DataStore equipped)
				if character then
					local currentEquipped = {}
					for i, item in character:GetChildren() do
						if item:IsA("Tool") then
							table.insert(currentEquipped, item.Name)
						end
					end
					-- Only update if we have equipped items (to preserve existing equipped)
					if #currentEquipped > 0 then
						equipped = currentEquipped
					end
				end

				MainDataStore.SaveInventory(player.UserId, {inventory = inventory, equipped = equipped})
				
				-- Reset dying flag after a delay
				task.delay(2, function()
					playerDying[player.UserId] = false
				end)
			end
		end)
end

local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		OnCharacterAdded(character, player)
	end)
	if player.Character then
		OnCharacterAdded(player.Character, player)
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for i, player in Players:GetPlayers() do
	OnPlayerAdded(player)
end