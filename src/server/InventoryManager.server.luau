local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainDataStore = require(ReplicatedStorage:FindFirstChild("MainDataStore"))

-- Debounce table for inventory saves per player
local inventorySaveDebounce = {}
local DEBOUNCE_TIME = 1 -- seconds

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
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		print("[InventoryManager] Backpack not found for", player.Name, "when loading inventory, waiting for Backpack...")
		backpack = player:WaitForChild("Backpack")
	end

	-- Wait for character if we need to load equipped items
	local character = player.Character
	if not character then
		print("[InventoryManager] Character not found for", player.Name, "when loading inventory, waiting for Character...")
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

	-- Load Backpack tools (allow duplicates)
	for i, toolName in inventory do
		local asset = assetsFolder:FindFirstChild(toolName)
		if asset and asset:IsA("Tool") then
			asset:Clone().Parent = backpack
		else
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
			else
			end
		end
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
			if child:IsA("Tool") then
				SavePlayerInventory(player)
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
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

local function MoveEquippedToBackpack(player)
	-- Get equipped items from MainDataStore
	local inventoryData = MainDataStore.LoadInventory(player.UserId)
	local equipped = inventoryData.equipped or {}
	local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
	local backpack = player:FindFirstChild("Backpack")
	if not backpack or not assetsFolder then return end

	for i, toolName in equipped do
		-- Only move if not already in Backpack
		if not backpack:FindFirstChild(toolName) then
			local asset = assetsFolder:FindFirstChild(toolName)
			if asset and asset:IsA("Tool") then
				asset:Clone().Parent = backpack
			end
		end
	end
end

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
			-- Add small delay to ensure equipped tools are still there
			task.wait(0.1)
			-- Move equipped items from MainDataStore to Backpack BEFORE saving inventory
			MoveEquippedToBackpack(player)
			SavePlayerInventory(player)
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