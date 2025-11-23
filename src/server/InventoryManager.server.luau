local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainDataStore = require(ReplicatedStorage:FindFirstChild("MainDataStore"))
local ActionEvent = ReplicatedStorage:WaitForChild("ActionEvent")
local EquipmentBonusConfig = require(ReplicatedStorage:WaitForChild("EquipmentBonusConfig"))
local ConsumableConfig = require(ReplicatedStorage:WaitForChild("ConsumableConfig"))
local HelmetConfig = require(ReplicatedStorage:WaitForChild("HelmetConfig"))

local function listToString(list)
	if not list or #list == 0 then
		return "[]"
	end
	local parts = {}
	for _, value in ipairs(list) do
		table.insert(parts, tostring(value))
	end
	return "[" .. table.concat(parts, ", ") .. "]"
end

local function shallowCopy(source)
	local copy = {}
	if source then
		for key, value in pairs(source) do
			copy[key] = value
		end
	end
	return copy
end

local EquipmentBonusEntries = EquipmentBonusConfig.Entries or EquipmentBonusConfig
local EquipmentBonusAssetLookup = shallowCopy(EquipmentBonusConfig.AssetLookup)
local EquipmentBonusCanonicalLookup = shallowCopy(EquipmentBonusConfig.CanonicalLookup)

local ConsumableEntries = ConsumableConfig.Entries or {}
local ConsumableAssetLookup = ConsumableConfig.AssetLookup or {}
local ConsumableCanonicalLookup = ConsumableConfig.CanonicalLookup or {}

local HelmetEntries = HelmetConfig.Entries or {}
local HelmetAssetLookup = HelmetConfig.AssetLookup or {}
local HelmetCanonicalLookup = HelmetConfig.CanonicalLookup or {}

local CONSUMABLE_TAG = "consumable_entity"
local MAX_CONSUMABLE_SLOTS = 5

if next(EquipmentBonusAssetLookup) == nil then
	for canonicalName, entry in pairs(EquipmentBonusEntries) do
		entry.assetName = entry.assetName or canonicalName
		entry.canonicalName = entry.canonicalName or canonicalName

		EquipmentBonusAssetLookup[canonicalName] = entry
		EquipmentBonusAssetLookup[entry.assetName] = entry
		EquipmentBonusCanonicalLookup[canonicalName] = canonicalName
		EquipmentBonusCanonicalLookup[entry.assetName] = canonicalName
	end
else
	for canonicalName, entry in pairs(EquipmentBonusEntries) do
		entry.assetName = entry.assetName or canonicalName
		entry.canonicalName = entry.canonicalName or canonicalName
	end
end

local function getCanonicalToolName(toolName)
	return EquipmentBonusCanonicalLookup[toolName] or toolName
end

local function normaliseEquipmentList(list)
	local result = {}
	for _, toolName in ipairs(list) do
		table.insert(result, getCanonicalToolName(toolName))
	end
	return result
end

local function getConsumableCanonicalName(name)
	if not name then
		return nil
	end

	if ConsumableCanonicalLookup and ConsumableCanonicalLookup[name] then
		return ConsumableCanonicalLookup[name]
	end

	if ConsumableEntries and ConsumableEntries[name] then
		return name
	end

	local assetEntry = ConsumableAssetLookup and ConsumableAssetLookup[name]
	if assetEntry and assetEntry.canonicalName then
		return assetEntry.canonicalName
	end

	return nil
end

local function getHelmetCanonicalName(name: string?)
	if not name then
		return nil
	end

	-- Explicit asset lookup
	local explicitEntry = HelmetAssetLookup[name]
	if explicitEntry and explicitEntry.canonicalName then
		return explicitEntry.canonicalName
	end

	-- Direct entry
	if HelmetEntries[name] then
		return name
	end

	-- Canonical alias
	local canonical = HelmetCanonicalLookup[name]
	if canonical and HelmetEntries[canonical] then
		return canonical
	end

	return nil
end

local function isConsumableToolName(name)
	local canonicalName = getConsumableCanonicalName(name)
	if canonicalName and ConsumableEntries[canonicalName] then
		return true, canonicalName
	end
	return false, nil
end

local function isConsumableToolInstance(tool)
	if not tool or not tool:IsA("Tool") then
		return false, nil
	end

	if CollectionService:HasTag(tool, CONSUMABLE_TAG) then
		local canonicalName = getConsumableCanonicalName(tool.Name)
		return true, canonicalName
	end

	return isConsumableToolName(tool.Name)
end

local function partitionConsumables(list)
	local filtered = {}
	local consumables = {}

	for _, name in ipairs(list) do
		local isConsumable, consumableCanonical = isConsumableToolName(name)
		if isConsumable then
			if consumableCanonical then
				table.insert(consumables, consumableCanonical)
			end
		else
			table.insert(filtered, getCanonicalToolName(name))
		end
	end

	return filtered, consumables
end

local function mergeConsumableLists(...)
	local result = {}

	for _, sourceList in ipairs({...}) do
		for _, name in ipairs(sourceList) do
			if #result >= MAX_CONSUMABLE_SLOTS then
				return result
			end

			local canonical = getConsumableCanonicalName(name)
			if canonical and ConsumableEntries[canonical] then
				table.insert(result, canonical)
			end
		end
	end

	return result
end

-- Remove helmet items from inventory/equipped lists and determine canonical helmet name.
-- This keeps the DataStore schema as:
--   inventory = { non-helmet tools }
--   equipped  = { non-helmet tools }
--   helmet    = "Some Helmet" (single slot)
local function stripHelmetFromLists(
	inventory: {string},
	equipped: {string},
	storedHelmet: string?
): ({string}, {string}, string?)
	local detectedHelmet = storedHelmet

	-- If DataStore didn't already provide a helmet field, try to detect it
	-- from equipped first (preferred) then inventory.
	if not detectedHelmet then
		for _, name in ipairs(equipped) do
			local canonical = getHelmetCanonicalName(name)
			if canonical then
				detectedHelmet = canonical
				break
			end
		end
	end

	if not detectedHelmet then
		for _, name in ipairs(inventory) do
			local canonical = getHelmetCanonicalName(name)
			if canonical then
				detectedHelmet = canonical
				break
			end
		end
	end

	-- If we still don't have a helmet, nothing to strip.
	if not detectedHelmet then
		return inventory, equipped, storedHelmet
	end

	local function isThisHelmet(name: string): boolean
		local canonical = getHelmetCanonicalName(name)
		return canonical == detectedHelmet
	end

	local cleanedInventory = {}
	for _, name in ipairs(inventory) do
		if not isThisHelmet(name) then
			table.insert(cleanedInventory, name)
		end
	end

	local cleanedEquipped = {}
	for _, name in ipairs(equipped) do
		if not isThisHelmet(name) then
			table.insert(cleanedEquipped, name)
		end
	end

	return cleanedInventory, cleanedEquipped, detectedHelmet
end

local function arraysDifferent(a, b)
	if #a ~= #b then
		return true
	end

	for index = 1, #a do
		if a[index] ~= b[index] then
			return true
		end
	end

	return false
end

local function cloneArray(list)
	local copy = {}
	for index, value in ipairs(list) do
		copy[index] = value
	end
	return copy
end

local function resolveAsset(assetsFolder, toolName)
	if not assetsFolder then
		return nil
	end

	local asset = assetsFolder:FindFirstChild(toolName)
	if asset then
		return asset
	end

	local entry = EquipmentBonusEntries[toolName]
	if entry and entry.assetName then
		asset = assetsFolder:FindFirstChild(entry.assetName)
		if asset then
			return asset
		end
	end

	local aliasEntry = EquipmentBonusAssetLookup[toolName]
	if aliasEntry and aliasEntry.assetName then
		asset = assetsFolder:FindFirstChild(aliasEntry.assetName)
		if asset then
			return asset
		end
	end

	return nil
end

-- Debounce table for inventory saves per player
local inventorySaveDebounce = {}
local DEBOUNCE_TIME = 1 -- seconds

-- Track when players are dying to prevent saving unequipped state
local playerDying = {}

-- Save backpack tool names AND equipped tool names to DataStore, with debounce
local function SavePlayerInventory(player)
	local userId = player.UserId
	local now = os.clock()

	-- If the character is currently dead (or in the process of dying),
	-- avoid saving. Roblox unequips tools on death by moving them back
	-- to the Backpack; if we save during that transition we will
	-- accidentally overwrite the "equipped" list in DataStore with an
	-- empty one. We only want to persist the last *living* state.
	local characterForHealthCheck = player.Character
	if characterForHealthCheck then
		local humanoidForHealthCheck = characterForHealthCheck:FindFirstChild("Humanoid")
		if humanoidForHealthCheck and humanoidForHealthCheck.Health <= 0 then
			-- Skip this save; LoadPlayerInventory will restore from the
			-- last good DataStore snapshot after respawn.
			return
		end
	end

	if inventorySaveDebounce[userId] and (now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME) then
		inventorySaveDebounce[userId].pending = true
		return
	end

	local function doSave()
		local backpack = player:FindFirstChild("Backpack")
		local character = player.Character
		local inventory = {}
		local equipped = {}
		local consumables = {}

		if backpack then
			for i, item in backpack:GetChildren() do
				if item:IsA("Tool") then
					local isConsumable = isConsumableToolInstance(item)
					if not isConsumable then
						table.insert(inventory, getCanonicalToolName(item.Name))
					end
				end
			end
		end

		if character then
			for i, item in character:GetChildren() do
				if item:IsA("Tool") then
					local isConsumable = isConsumableToolInstance(item)
					if not isConsumable then
						table.insert(equipped, getCanonicalToolName(item.Name))
					end
				end
			end
		end

		-- If both are empty, try to load from DataStore first to preserve existing data
		if #inventory == 0 and #equipped == 0 then
			local existingData = MainDataStore.LoadInventory(player.UserId)
			if existingData and (existingData.inventory and #existingData.inventory > 0 or existingData.equipped and #existingData.equipped > 0) then
				-- Normalise and strip any helmet entries that may have been stored
				-- in inventory/equipped from older versions.
				local existingInventoryCanonical = normaliseEquipmentList(existingData.inventory or {})
				local existingEquippedCanonical = normaliseEquipmentList(existingData.equipped or {})
				local cleanedInventory, cleanedEquipped, _ = stripHelmetFromLists(
					existingInventoryCanonical,
					existingEquippedCanonical,
					existingData.helmet
				)

				inventory = cleanedInventory
				equipped = cleanedEquipped
				consumables = existingData.consumables or consumables or {}
			end
		end

		local inventoryFiltered, inventoryConsumables = partitionConsumables(inventory)
		local equippedFiltered, equippedConsumables = partitionConsumables(equipped)

		inventory = inventoryFiltered
		equipped = equippedFiltered
		consumables = mergeConsumableLists(consumables, inventoryConsumables, equippedConsumables)

		if typeof(_G.getPlayerConsumables) == "function" then
			consumables = _G.getPlayerConsumables(player)
		end

		consumables = consumables or {}
		consumables = mergeConsumableLists(consumables)

		-- Helmet: prefer live runtime slot. Only preserve existing helmet from
		-- DataStore if we're in a transition state (no character or dead).
		-- If player has a living character and runtime helmet is nil, trust that
		-- nil (it's an intentional drop) and save it.
		local helmet = nil
		local existingForHelmet = MainDataStore.LoadInventory(player.UserId) or {}
		if typeof(_G.getPlayerHelmet) == "function" then
			helmet = _G.getPlayerHelmet(player)
		end
		
		-- Only preserve existing helmet if we're in a transition state
		-- (no character, or character is dead). Otherwise, trust the runtime value.
		if helmet == nil then
			local isInTransition = false
			if not character then
				isInTransition = true
			else
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health <= 0 then
					isInTransition = true
				end
			end
			
			if isInTransition then
				-- Preserve existing helmet during transitions
				helmet = existingForHelmet.helmet
			else
				-- Player has a living character and no helmet - this is intentional, save nil
				helmet = nil
			end
		end

		local success, err = MainDataStore.SaveInventory(player.UserId, {
			inventory = inventory,
			equipped = equipped,
			consumables = consumables,
			helmet = helmet,
		})
		if not success then
			warn("[InventoryManager] SavePlayerInventory failed for", player.Name, ":", err)
		end
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

	-- Additional wait to ensure everything is properly loaded.
	-- Increased further to give even more time for character/other systems to initialise.
	task.wait(3)

	local userId = player.UserId
	local inventoryData = MainDataStore.LoadInventory(userId) or {}

	local originalInventory = inventoryData.inventory or {}
	local originalEquipped = inventoryData.equipped or {}
	local storedHelmet = inventoryData.helmet
	local storedConsumablesRaw = inventoryData.consumables or {}

	local originalInventoryCanonical = normaliseEquipmentList(originalInventory)
	local originalEquippedCanonical = normaliseEquipmentList(originalEquipped)

	-- Strip helmet entries out of the inventory/equipped arrays and determine
	-- the canonical helmet name (migration path for old saves).
	local cleanedInventoryCanonical, cleanedEquippedCanonical, resolvedHelmet = stripHelmetFromLists(
		originalInventoryCanonical,
		originalEquippedCanonical,
		storedHelmet
	)

	local inventory = cloneArray(cleanedInventoryCanonical)
	local equipped = cloneArray(cleanedEquippedCanonical)

	local inventoryFiltered, inventoryConsumables = partitionConsumables(inventory)
	local equippedFiltered, equippedConsumables = partitionConsumables(equipped)

	inventory = inventoryFiltered
	equipped = equippedFiltered

	local storedConsumablesCanonical = {}
	for _, name in ipairs(storedConsumablesRaw) do
		local canonical = getConsumableCanonicalName(name)
		if canonical and ConsumableEntries[canonical] then
			table.insert(storedConsumablesCanonical, canonical)
		end
	end

	local mergedConsumables = mergeConsumableLists(storedConsumablesCanonical, inventoryConsumables, equippedConsumables)

	-- Restore helmet from DataStore into the runtime helmet system (if available)
	if resolvedHelmet and typeof(_G.setPlayerHelmetFromData) == "function" then
		_G.setPlayerHelmetFromData(player, resolvedHelmet)
	end

	if typeof(_G.setPlayerConsumablesFromData) == "function" then
		_G.setPlayerConsumablesFromData(player, mergedConsumables)
	end

	-- If DataStore reports no equipped tools but we have tools in inventory, try to
	-- "recover" a sensible equipped state. This handles cases where a late save
	-- (e.g. unequip before leaving / teleport) cleared the equipped array even
	-- though the player effectively has a primary weapon.
	if #equipped == 0 and #inventory > 0 then
		-- Prefer something that was historically equipped (if present in inventory).
		local recovered = nil
		if #originalEquippedCanonical > 0 then
			for _, historicalName in ipairs(originalEquippedCanonical) do
				for _, invName in ipairs(inventory) do
					if invName == historicalName then
						recovered = historicalName
						break
					end
				end
				if recovered then
					break
				end
			end
		end

		-- Fallback: just use the first non-consumable tool from inventory.
		if not recovered then
			recovered = inventory[1]
		end

		if recovered then
			equipped = {recovered}
		end
	end

	local shouldResaveInventory = arraysDifferent(inventory, originalInventoryCanonical)
		or arraysDifferent(equipped, originalEquippedCanonical)
		or arraysDifferent(mergedConsumables, storedConsumablesCanonical)

	if shouldResaveInventory then
		local helmet = resolvedHelmet
		if typeof(_G.getPlayerHelmet) == "function" then
			helmet = _G.getPlayerHelmet(player) or resolvedHelmet
		end

		MainDataStore.SaveInventory(userId, {
			inventory = inventory,
			equipped = equipped,
			consumables = mergedConsumables,
			helmet = helmet,
		})

		inventorySaveDebounce[userId] = inventorySaveDebounce[userId] or {lastSave = 0, pending = false}
		inventorySaveDebounce[userId].lastSave = os.clock()
		inventorySaveDebounce[userId].pending = false
	end

	local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
	if not assetsFolder then
		warn("[InventoryManager] Assets folder not found in ReplicatedStorage for", player.Name)
		return
	end

	local missingWarnings = {}

	-- Load Backpack tools (allow duplicates - these come from DataStore)
	for i, toolName in inventory do
		local asset = resolveAsset(assetsFolder, toolName)
		if asset and asset:IsA("Tool") then
			local clone = asset:Clone()
			clone.Parent = backpack
		else
			if not missingWarnings[toolName] then
				warn("[InventoryManager] Tool not found:", toolName)
				missingWarnings[toolName] = true
			end
		end
	end

	-- Load Equipped tools (to Character) - prevent duplicates for equipped items
	if character and #equipped > 0 then
		for i, toolName in equipped do
			local asset = resolveAsset(assetsFolder, toolName)
			if asset and asset:IsA("Tool") then
				if not character:FindFirstChild(asset.Name) then
					local clone = asset:Clone()
					clone.Parent = character
				end
			else
				if not missingWarnings[toolName] then
					warn("[InventoryManager] Tool not found:", toolName)
					missingWarnings[toolName] = true
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
	-- Immediately lock input on first character spawn/respawn so the player
	-- can't move while we are still restoring DataStore-backed inventory.
	ActionEvent:FireClient(player, "global_lock_input")
	-- Wait for Backpack to exist before loading inventory
	local backpack = player:WaitForChild("Backpack")

	-- Add delay after respawn to prevent inventory loss (like rejoining server)
	-- Increased slightly to make sure everything (character, remotes, configs)
	-- has time to initialise before we touch the DataStore-backed inventory.
	task.wait(4)

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
				local existingData = MainDataStore.LoadInventory(player.UserId) or {}
				local inventory = existingData.inventory or {}
				local equipped = existingData.equipped or {}
				
				-- Get current backpack items and merge with existing inventory
				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					local currentBackpack = {}
					for i, item in backpack:GetChildren() do
						if item:IsA("Tool") then
							local isConsumable = isConsumableToolInstance(item)
							if not isConsumable then
								table.insert(currentBackpack, getCanonicalToolName(item.Name))
							end
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
							local isConsumable = isConsumableToolInstance(item)
							if not isConsumable then
								table.insert(currentEquipped, getCanonicalToolName(item.Name))
							end
						end
					end
					-- Only update if we have equipped items (to preserve existing equipped)
					if #currentEquipped > 0 then
						equipped = currentEquipped
					end
				end

				local baseConsumables = (existingData and existingData.consumables) or {}
				local consumables = {}
				if typeof(_G.getPlayerConsumables) == "function" then
					consumables = _G.getPlayerConsumables(player)
				else
					consumables = baseConsumables
				end
				consumables = mergeConsumableLists(consumables or {})

				-- Preserve helmet slot across death. Prefer the live runtime helmet
				-- value; if that is nil, fall back to whatever is already in DataStore
				-- so we never accidentally overwrite a stored helmet with nil.
				local helmet = nil
				if typeof(_G.getPlayerHelmet) == "function" then
					helmet = _G.getPlayerHelmet(player)
				end
				if helmet == nil then
					helmet = existingData.helmet
				end

				MainDataStore.SaveInventory(player.UserId, {
					inventory = inventory,
					equipped = equipped,
					consumables = consumables,
					helmet = helmet,
				})
				
				-- Reset dying flag after a delay
				task.delay(2, function()
					playerDying[player.UserId] = false
				end)
			end
		end)

		-- At this point Backpack, equipped tools, consumables and helmet have been
		-- restored to match the InventoryStore payload and death handling is wired.
		-- It is now safe to unlock input.
		ActionEvent:FireClient(player, "global_unlock_input")
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

-- Expose a global helper so other systems (ConsumableManager, HelmetManager, etc.)
-- can request a coherent inventory save without writing to DataStore themselves.
_G.requestInventorySave = function(player: Player)
	if not player or not player:IsA("Player") then
		return
	end
	SavePlayerInventory(player)
end