local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainDataStore = require(ReplicatedStorage:WaitForChild("MainDataStore"))
local ConsumableConfig = require(ReplicatedStorage:WaitForChild("ConsumableConfig"))
local EquipmentBonusConfig = require(ReplicatedStorage:WaitForChild("EquipmentBonusConfig"))

local ConsumableEvent = ReplicatedStorage:FindFirstChild("ConsumableEvent")
if not ConsumableEvent then
	ConsumableEvent = Instance.new("RemoteEvent")
	ConsumableEvent.Name = "ConsumableEvent"
	ConsumableEvent.Parent = ReplicatedStorage
end

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

local MAX_CONSUMABLE_SLOTS = 5
local CONSUMABLE_TAG = "consumable_entity"
local DEBOUNCE_TIME = 1

local ConsumableEntries = ConsumableConfig.Entries or {}
local ConsumableAssetLookup = ConsumableConfig.AssetLookup or {}
local ConsumableCanonicalLookup = ConsumableConfig.CanonicalLookup or {}

local EquipmentEntries = EquipmentBonusConfig.Entries or EquipmentBonusConfig
local EquipmentAssetLookup = EquipmentBonusConfig.AssetLookup or {}
local EquipmentCanonicalLookup = EquipmentBonusConfig.CanonicalLookup or {}

local playerConsumables: {[Player]: {[number]: string?}} = {}

local assignConsumables
local characterConnections: {[Player]: {RBXScriptConnection}} = {}
local inventorySaveDebounce: {[number]: {lastSave: number, pending: boolean}} = {}

local function getConsumableEntryFromName(name: string)
	if not name then
		return nil, nil
	end

	local explicitEntry = ConsumableAssetLookup[name]
	if explicitEntry then
		return explicitEntry, explicitEntry.canonicalName
	end

	local canonicalName = ConsumableCanonicalLookup[name] or name
	local entry = ConsumableEntries[canonicalName]
	return entry, canonicalName
end

local function getEquipmentCanonicalName(toolName: string)
	if not toolName then
		return nil
	end

	if EquipmentCanonicalLookup and EquipmentCanonicalLookup[toolName] then
		return EquipmentCanonicalLookup[toolName]
	end

	local entry = EquipmentAssetLookup and EquipmentAssetLookup[toolName]
	if entry and entry.canonicalName then
		return entry.canonicalName
	end

	if EquipmentEntries and EquipmentEntries[toolName] then
		return toolName
	end

	return toolName
end

local function buildInventorySnapshot(player: Player)
	local inventory: {string} = {}
	local equipped: {string} = {}

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(inventory, getEquipmentCanonicalName(item.Name))
			end
		end
	end

	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(equipped, getEquipmentCanonicalName(item.Name))
			end
		end
	end

	return inventory, equipped
end

local function saveInventory(player: Player)
	-- Delegate actual DataStore writes to InventoryManager so that inventory,
	-- equipped tools, consumables and helmet are saved in one coherent snapshot.
	if typeof(_G.requestInventorySave) == "function" then
		_G.requestInventorySave(player)
	end
end

local function queueInventorySave(player: Player)
	local userId = player.UserId
	local now = os.clock()
	local record = inventorySaveDebounce[userId]

	if not record then
		record = { lastSave = 0, pending = false }
		inventorySaveDebounce[userId] = record
	end

	if now - record.lastSave < DEBOUNCE_TIME then
		if record.pending then
			return
		end

		record.pending = true
		task.delay(DEBOUNCE_TIME - (now - record.lastSave), function()
			local currentRecord = inventorySaveDebounce[userId]
			if not currentRecord or not currentRecord.pending then
				return
			end

			currentRecord.pending = false
			currentRecord.lastSave = os.clock()
			if player.Parent then
				saveInventory(player)
			end
		end)
	else
		record.lastSave = now
		record.pending = false
		saveInventory(player)
	end
end

local function sendConsumableUpdate(player: Player)
	local consumableList = playerConsumables[player]
	if not consumableList then
		return
	end
	local payload = {}
	for index = 1, MAX_CONSUMABLE_SLOTS do
		local canonicalName = consumableList[index]
		if canonicalName then
			local entry = ConsumableEntries[canonicalName]
			payload[index] = {
				canonicalName = canonicalName,
				displayName = entry and (entry.displayName or canonicalName) or canonicalName,
			}
		else
			payload[index] = nil
		end
	end
	ConsumableEvent:FireClient(player, "updateSlots", payload)
end

local function ensurePlayerTables(player: Player)
	if not playerConsumables[player] then
		playerConsumables[player] = {}
		for index = 1, MAX_CONSUMABLE_SLOTS do
			playerConsumables[player][index] = nil
		end
	end
	if not characterConnections[player] then
		characterConnections[player] = {}
	end
end

assignConsumables = function(player: Player, sourceList: {any}?)
	ensurePlayerTables(player)
	sourceList = sourceList or {}

	local consumableList = playerConsumables[player]
	for index = 1, MAX_CONSUMABLE_SLOTS do
		consumableList[index] = nil
	end

	for _, name in ipairs(sourceList) do
		local _, canonicalName = getConsumableEntryFromName(name)
		if canonicalName and ConsumableEntries[canonicalName] then
			for slotIndex = 1, MAX_CONSUMABLE_SLOTS do
				if not consumableList[slotIndex] then
					consumableList[slotIndex] = canonicalName
					break
				end
			end
		end
	end

	sendConsumableUpdate(player)
end

local function setToolTouchEnabled(tool: Tool, enabled: boolean)
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanTouch = enabled
		end
	end
end

local function dropToolNearPlayer(player: Player, tool: Tool)
	setToolTouchEnabled(tool, false)

	local pivotCFrame = nil
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			pivotCFrame = root.CFrame * CFrame.new(0, 2, -6)
		end
	end

	tool.Parent = workspace
	if pivotCFrame then
		pcall(function()
			tool:PivotTo(pivotCFrame)
		end)
	end

	task.delay(0.35, function()
		if tool.Parent == workspace then
			setToolTouchEnabled(tool, true)
			tool:SetAttribute("ConsumableCollected", nil)
		end
	end)
end
local function loadConsumables(player: Player)
	local inventoryData = MainDataStore.LoadInventory(player.UserId) or {}
	local storedConsumables = inventoryData.consumables or {}

	assignConsumables(player, storedConsumables)
end

local function collectConsumable(player: Player, tool: Tool)
	if not player or not tool or not tool:IsA("Tool") then
		return
	end
	if tool:GetAttribute("ConsumableCollected") then
		return
	end

	tool:SetAttribute("ConsumableCollected", true)

	local entry, canonicalName = getConsumableEntryFromName(tool.Name)
	if not entry or not canonicalName then
		warn("[ConsumableManager] Unknown consumable:", tool.Name)
		dropToolNearPlayer(player, tool)
		return
	end

	ensurePlayerTables(player)
	local consumableList = playerConsumables[player]

	local targetSlot = nil
	for slotIndex = 1, MAX_CONSUMABLE_SLOTS do
		if not consumableList[slotIndex] then
			targetSlot = slotIndex
			break
		end
	end

	if not targetSlot then
		-- Inventory full, drop consumable silently (could be enhanced with player feedback)
		warn("[ConsumableManager] Consumable slots full for player:", player.Name)
		dropToolNearPlayer(player, tool)
		return
	end

	consumableList[targetSlot] = canonicalName
	tool:Destroy()

	sendConsumableUpdate(player)
	queueInventorySave(player)
end

local function bindCharacter(player: Player, character: Model)
	ensurePlayerTables(player)

	local connections = characterConnections[player]

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		table.insert(connections, backpack.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and CollectionService:HasTag(child, CONSUMABLE_TAG) then
				task.defer(function()
					if child.Parent then
						collectConsumable(player, child)
					end
				end)
			end
		end))
	end

	table.insert(connections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and CollectionService:HasTag(child, CONSUMABLE_TAG) then
			task.defer(function()
				if child.Parent then
					collectConsumable(player, child)
				end
			end)
		end
	end))
end

local function clearConnections(player: Player)
	local connections = characterConnections[player]
	if not connections then
		return
	end

	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	characterConnections[player] = nil
end

local function handleConsumableUse(player: Player, slotIndex: number)
	ensurePlayerTables(player)
	local consumableList = playerConsumables[player]
	if not consumableList or slotIndex < 1 or slotIndex > MAX_CONSUMABLE_SLOTS then
		return
	end

	local canonicalName = consumableList[slotIndex]
	if not canonicalName then
		return
	end

	local entry = ConsumableEntries[canonicalName]
	if not entry then
		warn("[ConsumableManager] Missing config entry for consumable:", canonicalName)
		table.remove(consumableList, slotIndex)
		sendConsumableUpdate(player)
		queueInventorySave(player)
		return
	end

	local applyFn = _G.applyConsumableEffect
	if typeof(applyFn) ~= "function" then
		warn("[ConsumableManager] Consumable application function unavailable.")
		return
	end

	local success, err = applyFn(player, canonicalName)
	if not success then
		if err then
			warn("[ConsumableManager] Failed to apply consumable:", canonicalName, err)
		end
		return
	end

	consumableList[slotIndex] = nil
	sendConsumableUpdate(player)
	queueInventorySave(player)
end

ConsumableEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "use" then
		local slotIndex = ...
		if typeof(slotIndex) == "number" then
			handleConsumableUse(player, slotIndex)
		end
	elseif action == "sync" then
		sendConsumableUpdate(player)
	end
end)

local function initialisePlayer(player: Player)
	clearConnections(player)
	ensurePlayerTables(player)
	loadConsumables(player)

	player.CharacterAdded:Connect(function(character)
		clearConnections(player)
		bindCharacter(player, character)

		if typeof(_G.applyConsumableTotalsToCharacter) == "function" then
			task.defer(_G.applyConsumableTotalsToCharacter, player)
		end
	end)

	if player.Character then
		bindCharacter(player, player.Character)
		if typeof(_G.applyConsumableTotalsToCharacter) == "function" then
			task.defer(_G.applyConsumableTotalsToCharacter, player)
		end
	end
end

Players.PlayerAdded:Connect(initialisePlayer)
for _, player in ipairs(Players:GetPlayers()) do
	initialisePlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	clearConnections(player)
	saveInventory(player)
	playerConsumables[player] = nil
	inventorySaveDebounce[player.UserId] = nil
end)

_G.getPlayerConsumables = function(player: Player)
	local list = playerConsumables[player]
	if not list then
		return {}
	end
	local sequential = {}
	for index = 1, MAX_CONSUMABLE_SLOTS do
		local canonicalName = list[index]
		if canonicalName then
			table.insert(sequential, canonicalName)
		end
	end
	return sequential
end

_G.setPlayerConsumablesFromData = function(player: Player, sourceList)
	if not player then
		return
	end

	assignConsumables(player, sourceList or {})
end

