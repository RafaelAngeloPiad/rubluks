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
	table.sort(list) -- Sort for deterministic logging
	return "[" .. table.concat(list, ", ") .. "]"
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

local function getConsumableCanonicalName(name)
	if not name then return nil end
	if ConsumableCanonicalLookup and ConsumableCanonicalLookup[name] then return ConsumableCanonicalLookup[name] end
	if ConsumableEntries and ConsumableEntries[name] then return name end
	local assetEntry = ConsumableAssetLookup and ConsumableAssetLookup[name]
	if assetEntry and assetEntry.canonicalName then return assetEntry.canonicalName end
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
	if not tool or not tool:IsA("Tool") then return false, nil end
	if CollectionService:HasTag(tool, CONSUMABLE_TAG) then
		local canonicalName = getConsumableCanonicalName(tool.Name)
		return true, canonicalName
	end
	return isConsumableToolName(tool.Name)
end

local function resolveAsset(assetsFolder, toolName)
	if not assetsFolder then return nil end
	local asset = assetsFolder:FindFirstChild(toolName)
	if asset then return asset end
	local entry = EquipmentBonusEntries[toolName]
	if entry and entry.assetName then
		asset = assetsFolder:FindFirstChild(entry.assetName)
		if asset then return asset end
	end
	local aliasEntry = EquipmentBonusAssetLookup[toolName]
	if aliasEntry and aliasEntry.assetName then
		asset = assetsFolder:FindFirstChild(aliasEntry.assetName)
		if asset then return asset end
	end
	return nil
end

-- Debounce table for inventory saves per player
local inventorySaveDebounce = {}
local DEBOUNCE_TIME = 1 -- seconds

-- Save: READS World State -> WRITES DataStore
local function SavePlayerInventory(player)
	local userId = player.UserId
	local now = os.clock()

	-- 1. DEBOUNCE CHECK
	if inventorySaveDebounce[userId] and (now - inventorySaveDebounce[userId].lastSave < DEBOUNCE_TIME) then
		inventorySaveDebounce[userId].pending = true
		return
	end

	local function doSave()
		-- 2. SAFETY CHECKS (The "Death Stopper")
		-- If character is missing, detached, or dead, DO NOT SAVE.
		-- This prevents overwriting good data with empty data during teleport/death.
		local character = player.Character
		if not character or not character.Parent then
			print("[InventoryManager] Save blocked: Character missing/detached for", player.Name)
			return 
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			print("[InventoryManager] Save blocked: Character dead for", player.Name)
			return
		end

		-- 3. GATHER DATA
		local backpack = player:FindFirstChild("Backpack")
		local inventory = {}
		local equipped = {}
		local consumables = {} -- We allow other systems to handle this via _G usually

		-- Track instances to avoid duplicates if Roblox moves things around
		local seenInstances = {}

		-- Scan Character (Equipped)
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				local isConsumable, consName = isConsumableToolInstance(item)
				if isConsumable then
					-- Managed by Consumable system mostly, but we can track if needed
				else
					local canonicalName = getCanonicalToolName(item.Name)
					table.insert(equipped, canonicalName)
					seenInstances[item] = true
				end
			end
		end

		-- Scan Backpack (Inventory)
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					-- If it's already in character (rare race condition), skip
					if not seenInstances[item] then
						local isConsumable, consName = isConsumableToolInstance(item)
						if isConsumable then
							-- Managed by Consumable system
						else
							local canonicalName = getCanonicalToolName(item.Name)
							table.insert(inventory, canonicalName)
						end
					end
				end
			end
		end

		-- Consumables & Helmet External Sources
		-- (Preserving existing integration patterns)
		if typeof(_G.getPlayerConsumables) == "function" then
			consumables = _G.getPlayerConsumables(player) or {}
		end

		local helmet = nil
		if typeof(_G.getPlayerHelmet) == "function" then
			helmet = _G.getPlayerHelmet(player)
		end

		-- 4. SAVE TO DATASTORE
		-- We do NOT merge with old data. We trust the current ALIVE world state.
		local success, err = MainDataStore.SaveInventory(player.UserId, {
			inventory = inventory,
			equipped = equipped,
			consumables = consumables,
			helmet = helmet,
		})

		print("[DEBUG] Saved Linear for", player.Name, "Inv:", listToString(inventory), "Eq:", listToString(equipped))

		if not success then
			warn("[InventoryManager] Save failed:", err)
		end

		inventorySaveDebounce[userId].lastSave = os.clock()
		inventorySaveDebounce[userId].pending = false
	end

	-- Debounce Init
	if not inventorySaveDebounce[userId] then
		inventorySaveDebounce[userId] = {lastSave = 0, pending = false}
	end

	-- Debounce Execution Logic
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

-- Load: READS DataStore -> WRITES World State
local function LoadPlayerInventory(player)
	-- Safety wait
	local character = player.Character or player.CharacterAdded:Wait()
	local backpack = player:WaitForChild("Backpack")
	local assetsFolder = ReplicatedStorage:WaitForChild("assets")

	-- We wait a bit to ensure Client is ready (optional but safer)
	task.wait(2) -- Slightly reduced from 12s/4s, user wanted "simple" but reliable

	local data = MainDataStore.LoadInventory(player.UserId)
	print("[DEBUG] Loading Linear for", player.Name, "Inv:", listToString(data.inventory), "Eq:", listToString(data.equipped))

	-- 1. CLEAR EXISTING (Prevents duplication on reload)
	-- We assume DataStore is the Single Source of Truth on Load.
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") and not isConsumableToolInstance(child) then
			child:Destroy()
		end
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and not isConsumableToolInstance(child) then
			child:Destroy()
		end
	end

	-- 2. INSTANTIATE INVENTORY
	if data.inventory then
		for _, toolName in ipairs(data.inventory) do
			local asset = resolveAsset(assetsFolder, toolName)
			if asset then
				local clone = asset:Clone()
				clone.Name = toolName -- CRITICAL FIX: Rename to Item Name
				clone.Parent = backpack
			else
				warn("[InventoryManager] Missing asset for:", toolName)
			end
		end
	end

	-- 3. INSTANTIATE EQUIPPED
	if data.equipped then
		for _, toolName in ipairs(data.equipped) do
			local asset = resolveAsset(assetsFolder, toolName)
			if asset then
				local clone = asset:Clone()
				clone.Name = toolName -- CRITICAL FIX: Rename to Item Name
				clone.Parent = character
			else
				warn("[InventoryManager] Missing asset for:", toolName)
			end
		end
	end

	-- 4. RESTORE EXTERNALS
	if data.consumables and typeof(_G.setPlayerConsumablesFromData) == "function" then
		_G.setPlayerConsumablesFromData(player, data.consumables)
	end
	if data.helmet and typeof(_G.setPlayerHelmetFromData) == "function" then
		_G.setPlayerHelmetFromData(player, data.helmet)
	end

	-- Initial Refresh
	if _G.refreshEquipmentBonuses then
		_G.refreshEquipmentBonuses(player)
	end
end

local function BindInventoryEvents(player)
	local backpack = player:WaitForChild("Backpack")

	-- Save on any change (debounced)
	backpack.ChildAdded:Connect(function(child) if child:IsA("Tool") then SavePlayerInventory(player) end end)
	backpack.ChildRemoved:Connect(function(child) if child:IsA("Tool") then SavePlayerInventory(player) end end)

	local function bindCharacter(char)
		char.ChildAdded:Connect(function(child) 
			if child:IsA("Tool") then 
				SavePlayerInventory(player) 
				if _G.refreshEquipmentBonuses then task.defer(_G.refreshEquipmentBonuses, player) end
			end 
		end)
		char.ChildRemoved:Connect(function(child) 
			if child:IsA("Tool") then 
				SavePlayerInventory(player)
				if _G.refreshEquipmentBonuses then task.defer(_G.refreshEquipmentBonuses, player) end
			end 
		end)
	end

	if player.Character then bindCharacter(player.Character) end
	player.CharacterAdded:Connect(bindCharacter)
end

local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		LoadPlayerInventory(player)
		BindInventoryEvents(player)
	end)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

_G.requestInventorySave = function(player)
	SavePlayerInventory(player)
end