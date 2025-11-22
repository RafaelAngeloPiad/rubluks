local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local MainDataStore

local success, err = pcall(function()
	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
end)

if not success or not MainDataStore then
	--warn("MainDataStore module not found or failed to load: " .. tostring(err))
end

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Create RemoteEvent for dev stat changes (client->server communication)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevStatEvent = Instance.new("RemoteEvent")
DevStatEvent.Name = "DevStatEvent"
DevStatEvent.Parent = ReplicatedStorage

local SunfireWaterEvent = ReplicatedStorage:FindFirstChild("SunfireWaterEvent")
if not SunfireWaterEvent then
	SunfireWaterEvent = Instance.new("RemoteEvent")
	SunfireWaterEvent.Name = "SunfireWaterEvent"
	SunfireWaterEvent.Parent = ReplicatedStorage
end

local EquipmentBonusConfig = require(ReplicatedStorage:WaitForChild("EquipmentBonusConfig"))
local ConsumableConfig = require(ReplicatedStorage:WaitForChild("ConsumableConfig"))

-- ========================================
-- EQUIPMENT BONUS CONFIGURATION
-- ========================================

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

local EquipmentStatMappings = {
	HPPlus = {leaderstat = "MaxHealth", displayName = "HP"},
	AttackPlus = {leaderstat = "MaxAttack", displayName = "Attack"},
	DefensePlus = {leaderstat = "MaxDefense", displayName = "Defense"},
	DefensePenPlus = {leaderstat = "DefensePenetration", displayName = "Defense Penetration"},
	CritRatePlus = {leaderstat = "CritRate", displayName = "Crit Rate"},
	CritMultiplierPlus = {leaderstat = "CritMultiplier", displayName = "Crit Multiplier"},
}

local playerEquipmentBonuses = {} -- player -> { statName = totalBonus }
local playerEquipmentBonusDetails = {} -- player -> { statName = { "Item +Value", ... } }

local playerConsumableEffects = {} -- player -> { effectId = { bonuses, permanent, endTime } }
local playerConsumableTotals = {} -- player -> aggregated bonuses
local playerConsumableTemporaryTotals = {} -- player -> aggregated temporary bonuses
local playerConsumableTotalsApplied = {} -- player -> boolean indicating if totals are currently applied to leaderstats
local playerConsumableDetails = {} -- player -> { statName = { "Consumable +Value", ... } }
local consumableEffectCounter = 0

local updateConsumableBonusFolders
local setActiveConsumableValue
local synchronizeMovementAndAttackSpeeds
local enforceStatCaps

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function formatBonus(amount)
	if math.abs(amount - math.floor(amount)) < 1e-3 then
		return string.format("%+d", amount)
	end
	return string.format("%+.2f", amount)
end

local function applyEquipmentBonusesToLeaderstats(leaderstats, bonuses, multiplier)
	if not leaderstats or not bonuses then
		return
	end

	local player = leaderstats.Parent
	local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local humanoidPrevMaxHealth = humanoid and humanoid.MaxHealth or nil
	local humanoidPrevHealth = humanoid and humanoid.Health or nil
	local maxHealthChanged = false

	for statName, amount in pairs(bonuses) do
		if amount ~= 0 then
			local stat = leaderstats:FindFirstChild(statName)
			if stat and typeof(stat.Value) == "number" then
				stat.Value = stat.Value + (amount * multiplier)

				if statName == "MaxHealth" then
					maxHealthChanged = true
				end

				if statName == "MaxDefense" then
					local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
					if currentDefense then
						currentDefense.Value = math.max(0, currentDefense.Value + (amount * multiplier))
					end
				end
			end
		end
	end

	if humanoid and maxHealthChanged then
		local maxHealthStat = leaderstats:FindFirstChild("MaxHealth")
		if maxHealthStat then
			local newMax = math.max(0, maxHealthStat.Value)
			humanoid.MaxHealth = newMax

			if humanoidPrevMaxHealth and humanoidPrevMaxHealth > 0 then
				local ratio = humanoidPrevHealth and (humanoidPrevHealth / humanoidPrevMaxHealth) or 1
				ratio = math.clamp(ratio, 0, 1)
				humanoid.Health = math.max(0, math.min(newMax, newMax * ratio))
			else
				humanoid.Health = newMax
			end
		end
	end

	enforceStatCaps(leaderstats)
end

local function extractConsumableBonuses(entry)
	if not entry then
		return nil
	end

	local effects = entry.effects or entry.Effects or entry
	if typeof(effects) ~= "table" then
		return nil
	end

	local bonuses = {}
	for key, value in pairs(effects) do
		local mapping = EquipmentStatMappings[key]
		if mapping and typeof(value) == "number" and value ~= 0 then
			local statName = mapping.leaderstat
			bonuses[statName] = (bonuses[statName] or 0) + value
		end
	end

	return next(bonuses) and bonuses or nil
end

local function applySunfireWaterRestore(player, effectConfig)
	if not player or typeof(effectConfig) ~= "table" then
		return false
	end

	local amount = tonumber(effectConfig.amount)
	if not amount then
		return false
	end

	local sunfire = player:FindFirstChild("sunfireprogress")
	if not sunfire then
		return false
	end

	local currentValueObj = sunfire:FindFirstChild("CurrentWaterLevel")
	local maxValueObj = sunfire:FindFirstChild("MaxWaterLevel")
	if not currentValueObj or not maxValueObj then
		return false
	end

	local currentValue = tonumber(currentValueObj.Value) or 0
	local maxValue = tonumber(maxValueObj.Value) or 0

	local mode = typeof(effectConfig.mode) == "string" and effectConfig.mode:lower() or "add"
	local newValue = currentValue

	if mode == "set" then
		newValue = amount
	elseif mode == "add" then
		newValue = currentValue + amount
	elseif mode == "percent" or mode == "percentage" then
		newValue = currentValue + (maxValue * amount)
	elseif mode == "multiply" or mode == "mult" then
		newValue = currentValue * amount
	else
		newValue = currentValue + amount
	end

	local clampToMax = effectConfig.clampToMax
	if clampToMax == nil or clampToMax == true then
		newValue = math.min(newValue, maxValue)
	end

	local clampToMin = effectConfig.clampToMin
	if clampToMin == nil or clampToMin == true then
		newValue = math.max(newValue, 0)
	end

	currentValueObj.Value = newValue
	SunfireWaterEvent:FireClient(player, "restore", newValue, maxValue)
	return true
end

local function applySpecialConsumableEffects(player, entry)
	if not entry then
		return false
	end

	local specialEffects = entry.specialEffects
	if typeof(specialEffects) ~= "table" then
		return false
	end

	local applied = false

	for _, effectConfig in ipairs(specialEffects) do
		if typeof(effectConfig) == "table" then
			local effectType = effectConfig.type or effectConfig.Type
			if effectType == "SunfireWaterRestore" then
				if applySunfireWaterRestore(player, effectConfig) then
					applied = true
				end
			end
		end
	end

	return applied
end

local function ensureConsumableTables(player)
	if not playerConsumableEffects[player] then
		playerConsumableEffects[player] = {}
	end
	if not playerConsumableTotals[player] then
		playerConsumableTotals[player] = {}
	end
	if not playerConsumableTotalsApplied[player] then
		playerConsumableTotalsApplied[player] = false
	end
end

local function applyConsumableTotalsToLeaderstats(player, leaderstats)
	leaderstats = leaderstats or (player and player:FindFirstChild("leaderstats"))
	if not leaderstats then
		return
	end

	local totals = playerConsumableTotals[player]
	if not totals or not next(totals) then
		playerConsumableTotalsApplied[player] = false
		return
	end

	applyEquipmentBonusesToLeaderstats(leaderstats, totals, 1)
	playerConsumableTotalsApplied[player] = true

	updateConsumableBonusFolders(leaderstats, totals, playerConsumableDetails[player])
	enforceStatCaps(leaderstats)
end

local function removeConsumableTotalsFromLeaderstats(player, leaderstats)
	if not playerConsumableTotalsApplied[player] then
		return
	end

	leaderstats = leaderstats or (player and player:FindFirstChild("leaderstats"))
	if not leaderstats then
		playerConsumableTotalsApplied[player] = false
		return
	end

	local totals = playerConsumableTotals[player]
	if not totals or not next(totals) then
		playerConsumableTotalsApplied[player] = false
		return
	end

	applyEquipmentBonusesToLeaderstats(leaderstats, totals, -1)
	playerConsumableTotalsApplied[player] = false

	updateConsumableBonusFolders(leaderstats, playerConsumableTotals[player], playerConsumableDetails[player])
	enforceStatCaps(leaderstats)
end

local function addBonusesToTotals(targetTotals, bonuses, multiplier)
	if not targetTotals or not bonuses then
		return
	end

	for statName, amount in pairs(bonuses) do
		local current = targetTotals[statName] or 0
		local newValue = current + (amount * multiplier)
		if math.abs(newValue) < 1e-4 then
			targetTotals[statName] = nil
		else
			targetTotals[statName] = newValue
		end
	end
end

local function clearConsumableState(player)
	removeConsumableTotalsFromLeaderstats(player)
	playerConsumableEffects[player] = nil
	playerConsumableTotals[player] = nil
	playerConsumableTemporaryTotals[player] = nil
	playerConsumableTotalsApplied[player] = nil
	playerConsumableDetails[player] = nil

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		updateConsumableBonusFolders(leaderstats, nil, nil)
		local folder = leaderstats:FindFirstChild("ActiveConsumables")
		if folder then
			folder:ClearAllChildren()
		end
	end
end

local function removeConsumableEffect(player, effectId)
	local effects = playerConsumableEffects[player]
	if not effects then
		return
	end

	local effect = effects[effectId]
	if not effect then
		return
	end

	effects[effectId] = nil

	local hadTotalsApplied = playerConsumableTotalsApplied[player] == true

	local totals = playerConsumableTotals[player]
	if totals then
		addBonusesToTotals(totals, effect.bonuses, -1)
		if not next(totals) then
			playerConsumableTotals[player] = nil
		end
	end

	if not effect.permanent then
		local temporaryTotals = playerConsumableTemporaryTotals[player]
		if temporaryTotals then
			addBonusesToTotals(temporaryTotals, effect.bonuses, -1)
			if not next(temporaryTotals) then
				playerConsumableTemporaryTotals[player] = nil
			end
		end
	end

	local details = playerConsumableDetails[player]
	if details and effect.detailStrings then
		for statName, label in pairs(effect.detailStrings) do
			local list = details[statName]
			if list then
				for index = #list, 1, -1 do
					if list[index] == label then
						table.remove(list, index)
					end
				end
				if #list == 0 then
					details[statName] = nil
				end
			end
		end
		if not next(details) then
			playerConsumableDetails[player] = nil
		end
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and hadTotalsApplied then
		applyEquipmentBonusesToLeaderstats(leaderstats, effect.bonuses, -1)
		if playerConsumableTotals[player] and not next(playerConsumableTotals[player]) then
			playerConsumableTotalsApplied[player] = false
		elseif not playerConsumableTotals[player] then
			playerConsumableTotalsApplied[player] = false
		end
	end

	playerConsumableTotalsApplied[player] = playerConsumableTotalsApplied[player] or false

	if leaderstats then
		updateConsumableBonusFolders(leaderstats, playerConsumableTotals[player], playerConsumableDetails[player])
	end

	setActiveConsumableValue(player, effectId, nil)
end

local function applyConsumableEffect(player, consumableName)
	if not player or not consumableName then
		return false, "invalid parameters"
	end

	local entry = ConsumableEntries[consumableName]
	if not entry then
		entry = ConsumableAssetLookup[consumableName]
		if entry and entry.canonicalName then
			entry = ConsumableEntries[entry.canonicalName]
		end
	end

	if not entry then
		return false, "consumable not found"
	end

	local bonuses = extractConsumableBonuses(entry)
	local specialApplied = applySpecialConsumableEffects(player, entry)

	if bonuses then
		ensureConsumableTables(player)

		local duration = tonumber(entry.duration)
		local permanent = entry.permanent == true
		if not permanent then
			permanent = duration == nil or duration <= 0
		end

		if not permanent then
			playerConsumableTemporaryTotals[player] = playerConsumableTemporaryTotals[player] or {}
			addBonusesToTotals(playerConsumableTemporaryTotals[player], bonuses, 1)
		end

		playerConsumableTotals[player] = playerConsumableTotals[player] or {}
		addBonusesToTotals(playerConsumableTotals[player], bonuses, 1)
		playerConsumableDetails[player] = playerConsumableDetails[player] or {}

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			if playerConsumableTotalsApplied[player] then
				applyEquipmentBonusesToLeaderstats(leaderstats, bonuses, 1)
			else
				applyConsumableTotalsToLeaderstats(player, leaderstats)
			end
		else
			playerConsumableTotalsApplied[player] = false
		end

		consumableEffectCounter = consumableEffectCounter + 1
		local effectId = consumableEffectCounter

		local displayName = entry.displayName or consumableName
		local effectLabels = {}
		for statName, amount in pairs(bonuses) do
			local label = string.format("%s %s", displayName, formatBonus(amount))
			if not permanent and duration and duration > 0 then
				label = string.format("%s (%ds)", label, math.floor(duration))
			end
			effectLabels[statName] = label

			playerConsumableDetails[player][statName] = playerConsumableDetails[player][statName] or {}
			table.insert(playerConsumableDetails[player][statName], label)
		end

		local endTime = (not permanent and duration and duration > 0) and (tick() + duration) or nil

		playerConsumableEffects[player][effectId] = {
			name = consumableName,
			displayName = displayName,
			bonuses = bonuses,
			permanent = permanent,
			duration = duration,
			endTime = endTime,
			detailStrings = effectLabels,
		}

		if not permanent and duration and duration > 0 then
			task.delay(duration, function()
				local effects = playerConsumableEffects[player]
				if not effects then
					return
				end

				local effect = effects[effectId]
				if not effect or effect.permanent then
					return
				end

				if effect.endTime and tick() >= effect.endTime - 0.05 then
					removeConsumableEffect(player, effectId)
				end
			end)
		end

		if leaderstats then
			updateConsumableBonusFolders(leaderstats, playerConsumableTotals[player], playerConsumableDetails[player])
		end

		setActiveConsumableValue(player, effectId, {
			id = effectId,
			name = consumableName,
			displayName = displayName,
			bonuses = bonuses,
			permanent = permanent,
			duration = (not permanent and duration and duration > 0) and duration or nil,
			endTime = endTime,
		})

		if leaderstats then
			enforceStatCaps(leaderstats)
		end

		return true
	end

	if specialApplied then
		return true
	end

	return false, "consumable has no applicable effects"
end

local function applyConsumableTotalsToCharacter(player)
	if not player then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	if playerConsumableTotalsApplied[player] then
		removeConsumableTotalsFromLeaderstats(player, leaderstats)
	end

	applyConsumableTotalsToLeaderstats(player, leaderstats)
	updateConsumableBonusFolders(leaderstats, playerConsumableTotals[player], playerConsumableDetails[player])
	enforceStatCaps(leaderstats)
end

_G.applyConsumableEffect = applyConsumableEffect
_G.applyConsumableTotalsToCharacter = applyConsumableTotalsToCharacter

local function updateEquipmentBonusFolders(leaderstats, aggregated, details)
	if not leaderstats then
		return
	end

	aggregated = aggregated or {}
	details = details or {}

	local bonusesFolder = ensureFolder(leaderstats, "EquipmentBonuses")
	local detailsFolder = ensureFolder(leaderstats, "EquipmentBonusDetails")

	local seen = {}

	for statName, value in pairs(aggregated) do
		seen[statName] = true

		local valueObj = bonusesFolder:FindFirstChild(statName)
		if not valueObj then
			valueObj = Instance.new("NumberValue")
			valueObj.Name = statName
			valueObj.Parent = bonusesFolder
		end
		valueObj.Value = value

		local detailText = ""
		if details[statName] and #details[statName] > 0 then
			detailText = table.concat(details[statName], ", ")
		end

		local detailObj = detailsFolder:FindFirstChild(statName)
		if not detailObj then
			detailObj = Instance.new("StringValue")
			detailObj.Name = statName
			detailObj.Parent = detailsFolder
		end
		detailObj.Value = detailText
	end

	for _, valueObj in ipairs(bonusesFolder:GetChildren()) do
		if not seen[valueObj.Name] and valueObj:IsA("NumberValue") then
			valueObj.Value = 0
		end
	end

	for _, detailObj in ipairs(detailsFolder:GetChildren()) do
		if not seen[detailObj.Name] and detailObj:IsA("StringValue") then
			detailObj.Value = ""
		end
	end
end

updateConsumableBonusFolders = function(leaderstats, aggregated, details)
	if not leaderstats then
		return
	end

	aggregated = aggregated or {}
	details = details or {}

	local bonusesFolder = ensureFolder(leaderstats, "ConsumableBonuses")
	local detailsFolder = ensureFolder(leaderstats, "ConsumableBonusDetails")

	local seenStats = {}

	for statName, value in pairs(aggregated) do
		seenStats[statName] = true

		local valueObj = bonusesFolder:FindFirstChild(statName)
		if not valueObj then
			valueObj = Instance.new("NumberValue")
			valueObj.Name = statName
			valueObj.Parent = bonusesFolder
		end
		valueObj.Value = value

		local detailList = details[statName]
		local detailText = ""
		if detailList and #detailList > 0 then
			detailText = table.concat(detailList, ", ")
		end

		local detailObj = detailsFolder:FindFirstChild(statName)
		if not detailObj then
			detailObj = Instance.new("StringValue")
			detailObj.Name = statName
			detailObj.Parent = detailsFolder
		end
		detailObj.Value = detailText
	end

	for _, valueObj in ipairs(bonusesFolder:GetChildren()) do
		if valueObj:IsA("NumberValue") and not seenStats[valueObj.Name] then
			valueObj.Value = 0
		end
	end

	for _, detailObj in ipairs(detailsFolder:GetChildren()) do
		if detailObj:IsA("StringValue") and not seenStats[detailObj.Name] then
			detailObj.Value = ""
		end
	end
end

setActiveConsumableValue = function(player, effectId, payload)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local activeFolder = ensureFolder(leaderstats, "ActiveConsumables")
	local name = tostring(effectId)
	local valueObj = activeFolder:FindFirstChild(name)

	if not payload then
		if valueObj then
			valueObj:Destroy()
		end
		return
	end

	if not valueObj then
		valueObj = Instance.new("StringValue")
		valueObj.Name = name
		valueObj.Parent = activeFolder
	end

	valueObj.Value = HttpService:JSONEncode(payload)
end

local StatCapsConfig = ServerConfigs.StatCaps or {}

local function getEffectiveStatCaps(className)
	local effectiveCaps = nil

	if StatCapsConfig.Default then
		effectiveCaps = effectiveCaps or {}
		for statName, capEntry in pairs(StatCapsConfig.Default) do
			effectiveCaps[statName] = capEntry
		end
	end

	if className and className ~= "" then
		local classCaps = StatCapsConfig[className]
		if classCaps then
			effectiveCaps = effectiveCaps or {}
			for statName, capEntry in pairs(classCaps) do
				effectiveCaps[statName] = capEntry
			end
		end
	end

	return effectiveCaps
end

local function clampValueWithEntry(value, capEntry)
	if typeof(capEntry) == "number" then
		if value > capEntry then
			return capEntry
		end
		return value
	elseif typeof(capEntry) == "table" then
		local newValue = value
		local minValue = capEntry.min
		local maxValue = capEntry.max

		if typeof(maxValue) == "number" and newValue > maxValue then
			newValue = maxValue
		end
		if typeof(minValue) == "number" and newValue < minValue then
			newValue = minValue
		end

		return newValue
	end

	return value
end

enforceStatCaps = function(leaderstats)
	if not leaderstats then
		return false
	end

	local classValue = leaderstats:FindFirstChild("Class")
	local className = classValue and classValue.Value or nil
	local effectiveCaps = getEffectiveStatCaps(className)

	if not effectiveCaps then
		return false
	end

	local changed = false

	for statName, capEntry in pairs(effectiveCaps) do
		local statObject = leaderstats:FindFirstChild(statName)
		if statObject and typeof(statObject.Value) == "number" then
			local clamped = clampValueWithEntry(statObject.Value, capEntry)
			if clamped ~= statObject.Value then
				statObject.Value = clamped
				changed = true
			end
		end
	end

	local maxDefense = leaderstats:FindFirstChild("MaxDefense")
	local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
	if maxDefense and currentDefense and typeof(maxDefense.Value) == "number" and typeof(currentDefense.Value) == "number" then
		local newCurrentDefense = math.min(currentDefense.Value, maxDefense.Value)
		if newCurrentDefense ~= currentDefense.Value then
			currentDefense.Value = newCurrentDefense
			changed = true
		end
	end

	return changed
end

local function computeEquipmentBonuses(player)
	local aggregated = {}
	local details = {}

	local character = player and player.Character
	if not character then
		return aggregated, details
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") or child:IsA("Accessory") or child:IsA("Model") then
			local itemTotals = {}

			local function accumulateFromInstance(instance)
				for attributeName, mapping in pairs(EquipmentStatMappings) do
					local attrValue = instance:GetAttribute(attributeName)
					if typeof(attrValue) == "number" and attrValue ~= 0 then
						local statName = mapping.leaderstat
						aggregated[statName] = (aggregated[statName] or 0) + attrValue
						itemTotals[statName] = (itemTotals[statName] or 0) + attrValue
					end
				end
			end

			accumulateFromInstance(child)
			for _, descendant in ipairs(child:GetDescendants()) do
				accumulateFromInstance(descendant)
			end

			local configEntry = EquipmentBonusAssetLookup[child.Name]
			if not configEntry then
				local canonicalName = EquipmentBonusCanonicalLookup[child.Name]
				if canonicalName then
					configEntry = EquipmentBonusEntries[canonicalName]
				end
			end
			if configEntry then
				for key, value in pairs(configEntry) do
					if key ~= "assetName" and key ~= "canonicalName" then
						local mapping = EquipmentStatMappings[key]
						if mapping and typeof(value) == "number" and value ~= 0 then
							local statName = mapping.leaderstat
							aggregated[statName] = (aggregated[statName] or 0) + value
							itemTotals[statName] = (itemTotals[statName] or 0) + value
						end
					end
				end
			end

			for statName, amount in pairs(itemTotals) do
				details[statName] = details[statName] or {}
				table.insert(details[statName], string.format("%s %s", child.Name, formatBonus(amount)))
			end
		end
	end

	return aggregated, details
end
local function clearEquipmentBonuses(player)
	if not player then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local currentBonuses = playerEquipmentBonuses[player]

	if leaderstats then
		removeConsumableTotalsFromLeaderstats(player, leaderstats)

		if currentBonuses then
			applyEquipmentBonusesToLeaderstats(leaderstats, currentBonuses, -1)
		end
		updateEquipmentBonusFolders(leaderstats, {}, {})
		synchronizeMovementAndAttackSpeeds(player, leaderstats)
		enforceStatCaps(leaderstats)
	end

	playerEquipmentBonuses[player] = nil
	playerEquipmentBonusDetails[player] = nil
end

local function refreshEquipmentBonuses(player)
	if not player then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	removeConsumableTotalsFromLeaderstats(player, leaderstats)

	local existing = playerEquipmentBonuses[player]
	if existing then
		applyEquipmentBonusesToLeaderstats(leaderstats, existing, -1)
	end

	local aggregated, details = computeEquipmentBonuses(player)
	playerEquipmentBonuses[player] = aggregated
	playerEquipmentBonusDetails[player] = details

	applyEquipmentBonusesToLeaderstats(leaderstats, aggregated, 1)
	updateEquipmentBonusFolders(leaderstats, aggregated, details)

	applyConsumableTotalsToLeaderstats(player, leaderstats)
	synchronizeMovementAndAttackSpeeds(player, leaderstats)
	enforceStatCaps(leaderstats)
end

function _G.refreshEquipmentBonuses(player)
	refreshEquipmentBonuses(player)
end

function _G.clearEquipmentBonuses(player)
	clearEquipmentBonuses(player)
end

-- ========================================
-- BASE PLAYER STATS (Classes)
-- Moved from SlavkosConfigs to be managed here
-- ========================================

local BaseStats = {
	-- XP/Level Configuration (shared across all classes)
	XP = {
		startLevel = 1,
		startXP = 0,
		startMaxXP = 5,
		maxLevel = 50,
		xpMultiplier = 1.2,  -- Fallback multiplier (used before first breakpoint)
		levelMultipliers = { -- Level-based multipliers (editable)
			{ level = 1, multiplier = 1.15 },  -- Levels 1-6
			{ level = 7, multiplier = 1.3 }, -- Levels 7-12
			{ level = 13, multiplier = 1.45 }, -- Levels 13-18
			{ level = 19, multiplier = 1.6 }, -- Levels 19-24
			{ level = 25, multiplier = 1.75 }, -- Levels 25-30
			{ level = 31, multiplier = 1.9 }, -- Levels 31-36
			{ level = 37, multiplier = 2.05 }, -- Levels 37-42
			{ level = 43, multiplier = 2.2 } -- Levels 43+
		}
	},
	
	-- Level-up multipliers per class (from spreadsheet)
	LevelUpMultipliers = {
		Samurai = {
			HP = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			ATK = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			D = {
				{ level = 1, multiplier = 1.06 },
				{ level = 7, multiplier = 1.06 },
				{ level = 13, multiplier = 1.12 },
				{ level = 19, multiplier = 1.12 },
				{ level = 25, multiplier = 1.18 },
				{ level = 31, multiplier = 1.18 },
				{ level = 37, multiplier = 1.24 },
				{ level = 43, multiplier = 1.3 },
			},
			DP = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			CR = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.08 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.08 },
				{ level = 31, multiplier = 1.08 },
				{ level = 37, multiplier = 1.08 },
				{ level = 43, multiplier = 1.08 },
			},
			CM = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.005 },
				{ level = 13, multiplier = 1.01 },
				{ level = 19, multiplier = 1.01 },
				{ level = 25, multiplier = 1.015 },
				{ level = 31, multiplier = 1.015 },
				{ level = 37, multiplier = 1.02 },
				{ level = 43, multiplier = 1.025 },
			},
			HR = {
				{ level = 1, multiplier = 1.12 },
				{ level = 7, multiplier = 1.12 },
				{ level = 13, multiplier = 1.12 },
				{ level = 19, multiplier = 1.12 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.12 },
				{ level = 43, multiplier = 1.12 },
			},
			Mspd = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.0 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
			Aspd = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
		},
		Archer = {
			HP = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			ATK = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			D = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			DP = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			CR = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.14 },
				{ level = 13, multiplier = 1.14 },
				{ level = 19, multiplier = 1.14 },
				{ level = 25, multiplier = 1.14 },
				{ level = 31, multiplier = 1.14 },
				{ level = 37, multiplier = 1.08 },
				{ level = 43, multiplier = 1.02 },
			},
			CM = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.005 },
				{ level = 13, multiplier = 1.01 },
				{ level = 19, multiplier = 1.01 },
				{ level = 25, multiplier = 1.015 },
				{ level = 31, multiplier = 1.015 },
				{ level = 37, multiplier = 1.02 },
				{ level = 43, multiplier = 1.025 },
			},
			HR = {
				{ level = 1, multiplier = 1.08 },
				{ level = 7, multiplier = 1.08 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.08 },
				{ level = 31, multiplier = 1.08 },
				{ level = 37, multiplier = 1.08 },
				{ level = 43, multiplier = 1.08 },
			},
			Mspd = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.0 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
			Aspd = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			}
		},
		Gladiator = {
			HP = {
				{ level = 1, multiplier = 1.07 },
				{ level = 7, multiplier = 1.07 },
				{ level = 13, multiplier = 1.14 },
				{ level = 19, multiplier = 1.14 },
				{ level = 25, multiplier = 1.21 },
				{ level = 31, multiplier = 1.21 },
				{ level = 37, multiplier = 1.28 },
				{ level = 43, multiplier = 1.35 },
			},
			ATK = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			D = {
				{ level = 1, multiplier = 1.07 },
				{ level = 7, multiplier = 1.07 },
				{ level = 13, multiplier = 1.14 },
				{ level = 19, multiplier = 1.14 },
				{ level = 25, multiplier = 1.21 },
				{ level = 31, multiplier = 1.21 },
				{ level = 37, multiplier = 1.28 },
				{ level = 43, multiplier = 1.35 },
			},
			DP = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			CR = {
				{ level = 1, multiplier = 1.08 },
				{ level = 7, multiplier = 1.08 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.08 },
				{ level = 31, multiplier = 1.08 },
				{ level = 37, multiplier = 1.08 },
				{ level = 43, multiplier = 1.08 },
			},
			CM = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.005 },
				{ level = 13, multiplier = 1.01 },
				{ level = 19, multiplier = 1.01 },
				{ level = 25, multiplier = 1.015 },
				{ level = 31, multiplier = 1.015 },
				{ level = 37, multiplier = 1.02 },
				{ level = 43, multiplier = 1.025 },
			},
			HR = {
				{ level = 1, multiplier = 1.12 },
				{ level = 7, multiplier = 1.12 },
				{ level = 13, multiplier = 1.12 },
				{ level = 19, multiplier = 1.12 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.12 },
				{ level = 43, multiplier = 1.12 },
			},
			Mspd = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.0 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
			Aspd = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
		},
		Brawler = {  -- Berserker in spreadsheet
			HP = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			ATK = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			D = {
				{ level = 1, multiplier = 1.04 },
				{ level = 7, multiplier = 1.04 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.16 },
				{ level = 43, multiplier = 1.2 },
			},
			DP = {
				{ level = 1, multiplier = 1.06 },
				{ level = 7, multiplier = 1.06 },
				{ level = 13, multiplier = 1.12 },
				{ level = 19, multiplier = 1.12 },
				{ level = 25, multiplier = 1.18 },
				{ level = 31, multiplier = 1.18 },
				{ level = 37, multiplier = 1.24 },
				{ level = 43, multiplier = 1.3 },
			},
			CR = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.12 },
				{ level = 13, multiplier = 1.12 },
				{ level = 19, multiplier = 1.12 },
				{ level = 25, multiplier = 1.12 },
				{ level = 31, multiplier = 1.12 },
				{ level = 37, multiplier = 1.08 },
				{ level = 43, multiplier = 1.08 },
			},
			CM = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.005 },
				{ level = 13, multiplier = 1.01 },
				{ level = 19, multiplier = 1.01 },
				{ level = 25, multiplier = 1.015 },
				{ level = 31, multiplier = 1.015 },
				{ level = 37, multiplier = 1.02 },
				{ level = 43, multiplier = 1.025 },
			},
			HR = {
				{ level = 1, multiplier = 1.08 },
				{ level = 7, multiplier = 1.08 },
				{ level = 13, multiplier = 1.08 },
				{ level = 19, multiplier = 1.08 },
				{ level = 25, multiplier = 1.08 },
				{ level = 31, multiplier = 1.08 },
				{ level = 37, multiplier = 1.08 },
				{ level = 43, multiplier = 1.08 },
			},
			Mspd = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.0 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
			Aspd = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.0 },
				{ level = 19, multiplier = 1.0 },
				{ level = 25, multiplier = 1.0 },
				{ level = 31, multiplier = 1.0 },
				{ level = 37, multiplier = 1.0 },
				{ level = 43, multiplier = 1.0 },
			},
		},
		Knight = {
			HP = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			ATK = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			D = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			DP = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.15 },
				{ level = 31, multiplier = 1.15 },
				{ level = 37, multiplier = 1.2 },
				{ level = 43, multiplier = 1.25 },
			},
			CR = {
				{ level = 1, multiplier = 1.1 },
				{ level = 7, multiplier = 1.1 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.1 },
				{ level = 31, multiplier = 1.1 },
				{ level = 37, multiplier = 1.1 },
				{ level = 43, multiplier = 1.1 },
			},
			CM = {
				{ level = 1, multiplier = 1.0 },
				{ level = 7, multiplier = 1.005 },
				{ level = 13, multiplier = 1.01 },
				{ level = 19, multiplier = 1.01 },
				{ level = 25, multiplier = 1.015 },
				{ level = 31, multiplier = 1.015 },
				{ level = 37, multiplier = 1.02 },
				{ level = 43, multiplier = 1.025 },
			},
			HR = {
				{ level = 1, multiplier = 1.1 },
				{ level = 7, multiplier = 1.1 },
				{ level = 13, multiplier = 1.1 },
				{ level = 19, multiplier = 1.1 },
				{ level = 25, multiplier = 1.1 },
				{ level = 31, multiplier = 1.1 },
				{ level = 37, multiplier = 1.1 },
				{ level = 43, multiplier = 1.1 },
			},
			Mspd = {
				{ level = 1, multiplier = 1.00 },
				{ level = 7, multiplier = 1.00 },
				{ level = 13, multiplier = 1.00 },
				{ level = 19, multiplier = 1.00 },
				{ level = 25, multiplier = 1.00 },
				{ level = 31, multiplier = 1.00 },
				{ level = 37, multiplier = 1.00 },
				{ level = 43, multiplier = 1.00 },
			},
			Aspd = {
				{ level = 1, multiplier = 1.05 },
				{ level = 7, multiplier = 1.05 },
				{ level = 13, multiplier = 1.00 },
				{ level = 19, multiplier = 1.00 },
				{ level = 25, multiplier = 1.00 },
				{ level = 31, multiplier = 1.00 },
				{ level = 37, multiplier = 1.00 },
				{ level = 43, multiplier = 1.00 },
			},
		}
	},
	
	Archer = {
		-- Offense Stats
		ATK = 20,        -- Attack: Directly affects Health points
		DP = 20,           -- Defense Penetration: Directly affects Defense
		CR = 1,           -- Crit Rate: Rate of Critical Chance up to 100%
		CM = 2,         -- Crit Multiplier: Attack Multiplier (percentage)
		
		-- Defense Stats
		HP = 400,        -- Health Points: Life pool (dies if ≤ 0)
		D = 20,           -- Defense: Reduces Penetration
		HR = 20,           -- Health Regeneration: Health Points gained per second
		Mspd = 30,        -- Base walk speed in studs per second
		Aspd = 1,         -- Attack speed multiplier baseline for normal attacks
		SkillAspd = 1,    -- Attack speed baseline for skills/buffs/ultimates
	},
	
	Samurai = {
		-- Offense Stats
		ATK = 20,
		DP = 25,
		CR = 1,
		CM = 4,
		
		-- Defense Stats
		HP = 400,
		D = 30,
		HR = 30,
		Mspd = 15,
		Aspd = 0.5,
	},
	
	Brawler = {
		-- Offense Stats
		ATK = 20,
		DP = 30,
		CR = 1,
		CM = 150,
		
		-- Defense Stats
		HP = 400,
		D = 20,
		HR = 20,
		Mspd = 25,
		Aspd = 1,
	},
	
	Knight = {
		-- Offense Stats
		ATK = 25,
		DP = 25,
		CR = 1,
		CM = 2.5,
		
		-- Defense Stats
		HP = 500,
		D = 25,
		HR = 25,
		Mspd = 20,
		Aspd = 0.7,
	},
	
	Gladiator = {
		-- Offense Stats
		ATK = 15,
		DP = 20,
		CR = 1,
		CM = 3,
		
		-- Defense Stats
		HP = 700,
		D = 35,
		HR = 30,
		Mspd = 15,
		Aspd = 0.5,
	}
}

-- Export BaseStats to ServerConfigs so other modules can access it
ServerConfigs.BaseStats = BaseStats

-- Cache original class animation settings so base stats can scale them
local classConfigBaselines: {[string]: {
	movementSpeed: number,
	attackSpeed: number,
	skillAttackSpeedBaseline: number?,
	walking: {[string]: number}?,
	walkingSpeed: {[string]: number}?,
}} = {}

local function cloneNumericTable(source)
	if not source then
		return nil
	end

	local copy = {}
	for key, value in pairs(source) do
		if typeof(value) == "number" then
			copy[key] = value
		end
	end

	return next(copy) and copy or nil
end

local function getClassConfigBaseline(className: string)
	if classConfigBaselines[className] then
		return classConfigBaselines[className]
	end

	local unified = ServerConfigs.Hitboxes
		and ServerConfigs.Hitboxes.UnifiedAttacks
		and ServerConfigs.Hitboxes.UnifiedAttacks[className]

	if not unified then
		classConfigBaselines[className] = {
			movementSpeed = 1.0,
			attackSpeed = 1.0,
			walking = nil,
			walkingSpeed = nil,
		}
		return classConfigBaselines[className]
	end

	classConfigBaselines[className] = {
		movementSpeed = unified.movementSpeed or 1.0,
		attackSpeed = unified.attackSpeed or 1.0,
		skillAttackSpeedBaseline = unified.skillAttackSpeedBaseline or unified.attackSpeed or 1.0,
		walking = cloneNumericTable(unified.walking),
		walkingSpeed = cloneNumericTable(unified.walkingSpeed),
	}

	return classConfigBaselines[className]
end

local function updateRuntimeSpeedsFromBaseStats(className: string, baseStatsForClass)
	if not className or not baseStatsForClass then
		return nil, nil
	end

	local unified = ServerConfigs.Hitboxes
		and ServerConfigs.Hitboxes.UnifiedAttacks
		and ServerConfigs.Hitboxes.UnifiedAttacks[className]

	local classSummary = ServerConfigs[className]

	if not unified then
		return nil, nil
	end

	local baselines = getClassConfigBaseline(className)

	local baseWalkSpeed = baseStatsForClass.Mspd or 18
	local referenceWalk = 18

	if baselines.walkingSpeed and baselines.walkingSpeed.normal and baselines.walkingSpeed.normal > 0 then
		referenceWalk = baselines.walkingSpeed.normal
	elseif baselines.walking and baselines.walking.normal and baselines.walking.normal > 0 then
		referenceWalk = baselines.walking.normal
	end

	if referenceWalk <= 0 then
		referenceWalk = baseWalkSpeed ~= 0 and baseWalkSpeed or 18
	end

	local movementMultiplier = baseWalkSpeed / referenceWalk

	unified.movementSpeed = movementMultiplier

	if baselines.walking then
		unified.walking = unified.walking or {}
		for key, baselineValue in pairs(baselines.walking) do
			unified.walking[key] = baselineValue * movementMultiplier
		end
	end

	if baselines.walkingSpeed then
		unified.walkingSpeed = unified.walkingSpeed or {}
		for key, baselineValue in pairs(baselines.walkingSpeed) do
			unified.walkingSpeed[key] = baselineValue * movementMultiplier
		end
	end

	if classSummary then
		classSummary.MovementSpeed = movementMultiplier
		if classSummary.walking and baselines.walkingSpeed then
			for key, baselineValue in pairs(baselines.walkingSpeed) do
				classSummary.walking[key] = baselineValue * movementMultiplier
			end
		end
	end

	local baseAttackSpeed = baseStatsForClass.Aspd or baselines.attackSpeed or 1.0
	local referenceAttack = baselines.attackSpeed ~= 0 and baselines.attackSpeed or 1.0
	local attackMultiplier = baseAttackSpeed / referenceAttack

	local baseSkillSpeed = baseStatsForClass.SkillAspd or baseAttackSpeed
	local skillRatio = 1.0
	if baseAttackSpeed ~= 0 then
		skillRatio = baseSkillSpeed / baseAttackSpeed
	end
	local skillMultiplier = attackMultiplier * skillRatio

	unified.attackSpeed = attackMultiplier
	unified.skillAttackSpeedRatio = skillRatio
	unified.skillAttackSpeedMultiplier = skillMultiplier
	if classSummary then
		classSummary.AttackSpeed = attackMultiplier
		classSummary.SkillAttackSpeedRatio = skillRatio
		classSummary.SkillAttackSpeed = skillMultiplier
	end

	return movementMultiplier, attackMultiplier, skillMultiplier
end

for className, classStats in pairs(BaseStats) do
	if typeof(classStats) == "table" and classStats.Mspd and classStats.Aspd then
		updateRuntimeSpeedsFromBaseStats(className, classStats)
	end
end

local classAnimationUpdateFuncs = {
	Archer = _G.updateArcherAnimationSpeed,
	Samurai = _G.updateSamuraiAnimationSpeed,
	Brawler = _G.updateBrawlerAnimationSpeed,
	Knight = _G.updateKnightAnimationSpeed,
	Gladiator = _G.updateGladiatorAnimationSpeed,
}

synchronizeMovementAndAttackSpeeds = function(player, leaderstats)
	if not player or not leaderstats then
		return
	end

	local classValue = leaderstats:FindFirstChild("Class")
	local className = classValue and classValue.Value
	if not className or className == "" then
		return
	end

	local movementStat = leaderstats:FindFirstChild("MovementSpeed")
	local attackStat = leaderstats:FindFirstChild("AttackSpeed")
	local movementMultiplier = movementStat and movementStat.Value or 1.0
	local attackMultiplier = attackStat and attackStat.Value or 1.0

	if movementMultiplier <= 0 then
		movementMultiplier = 1.0
	end
	if attackMultiplier <= 0 then
		attackMultiplier = 1.0
	end

	if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[className] then
		ServerConfigs.Hitboxes.UnifiedAttacks[className].movementSpeed = movementMultiplier
		ServerConfigs.Hitboxes.UnifiedAttacks[className].attackSpeed = attackMultiplier
	end
	if ServerConfigs and ServerConfigs[className] then
		ServerConfigs[className].MovementSpeed = movementMultiplier
		ServerConfigs[className].AttackSpeed = attackMultiplier
	end

	local baseStatsForClass = BaseStats[className]
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and baseStatsForClass then
		local baseMspd = baseStatsForClass.Mspd or 18
		humanoid.WalkSpeed = baseMspd * movementMultiplier
	end

	local updateFunc = classAnimationUpdateFuncs[className]
	if updateFunc then
		updateFunc("movement", movementMultiplier)
		updateFunc("attack", attackMultiplier)
	end
end

-- Helper to resolve level-based stat multipliers for classes
local function resolveLevelUpMultiplier(multipliers, statKey, level)
	if not multipliers or not statKey or not level then
		return nil
	end

	local statDefinition = multipliers[statKey]
	if not statDefinition then
		return nil
	end

	local definitionType = typeof(statDefinition)
	if definitionType == "number" then
		return statDefinition
	elseif definitionType ~= "table" then
		return nil
	end

	-- Support shorthand table { level = X, multiplier = Y }
	if statDefinition.level and statDefinition.multiplier then
		statDefinition = { statDefinition }
	end

	local selectedMultiplier = nil
	for _, entry in ipairs(statDefinition) do
		if typeof(entry) == "table" and entry.level and entry.multiplier then
			if level >= entry.level then
				selectedMultiplier = entry.multiplier
			else
				break
			end
		end
	end

	if selectedMultiplier ~= nil then
		return selectedMultiplier
	end

	-- Fallback support for keyed defaults (e.g., { default = 1.0 })
	if typeof(statDefinition.defaultMultiplier) == "number" then
		return statDefinition.defaultMultiplier
	end
	if typeof(statDefinition.default) == "number" then
		return statDefinition.default
	end

	return nil
end

-- ========================================
-- BUFF MANAGEMENT SYSTEM
-- ========================================

-- Store active buffs for each player
local playerBuffs = {} -- player -> { buffName -> { config, startTime, endTime, baseStats } }

-- Store Bushido buff states for death prevention monitoring
local playerBushidoStates = {} -- player -> { active, character, humanoid, healthConnection, heartbeatConnection }

-- Function to get base stats before buffs (stored temporarily during buff)
local function getBaseStatsBeforeBuff(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	return {
		MaxAttack = leaderstats:FindFirstChild("MaxAttack") and leaderstats.MaxAttack.Value or 0,
		MaxDefense = leaderstats:FindFirstChild("MaxDefense") and leaderstats.MaxDefense.Value or 0,
		MaxHealth = leaderstats:FindFirstChild("MaxHealth") and leaderstats.MaxHealth.Value or 0,
		CurrentHealth = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health or 0,
		MovementSpeed = leaderstats:FindFirstChild("MovementSpeed") and leaderstats.MovementSpeed.Value or 1.0,
		AttackSpeed = leaderstats:FindFirstChild("AttackSpeed") and leaderstats.AttackSpeed.Value or 1.0
	}
end

-- Function to apply a buff to a player
-- @param player: Player instance
-- @param buffName: "Warcry" or "WarriorMight"
-- @param buffConfig: Buff configuration from ServerConfigs.getBuffConfig()
-- @return: true if buff was applied, false otherwise
function _G.applyBuff(player, buffName, buffConfig)
	if not player or not buffName or not buffConfig then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Get player's level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return false
	end
	
	-- Check if buff config is valid for player's level
	local config = ServerConfigs.getBuffConfig(buffName, level.Value)
	if not config then
		-- Buff not unlocked yet
		return false
	end
	
	-- Initialize player buffs tracking
	if not playerBuffs[player] then
		playerBuffs[player] = {}
	end
	
	-- Remove existing buff if active (stacking prevention)
	if playerBuffs[player][buffName] then
		_G.removeBuff(player, buffName)
	end
	
	-- Store base stats before applying buff
	local baseStats = getBaseStatsBeforeBuff(player)
	local equipmentSnapshot = {}
	if playerEquipmentBonuses[player] then
		for statName, amount in pairs(playerEquipmentBonuses[player]) do
			equipmentSnapshot[statName] = amount
		end
	end
	
	-- Calculate new stats with buff
	if buffName == "Warcry" then
		-- Warcry: Multiplies Attack and Defense
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxAttack and baseStats then
			-- Calculate buffed attack (multiply base by multiplier)
			local buffedAttack = math.floor(baseStats.MaxAttack * config.attackMultiplier)
			maxAttack.Value = buffedAttack
		end
		
		if maxDefense and baseStats then
			-- Calculate buffed defense (multiply base by multiplier)
			local buffedDefense = math.floor(baseStats.MaxDefense * config.defenseMultiplier)
			maxDefense.Value = buffedDefense
			
			-- Also update CurrentDefense to match MaxDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = buffedDefense
			end
		end
		
	elseif buffName == "WarriorMight" then
		-- WarriorMight: Adds flat HP
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Calculate buffed health (base + flat increase)
			local buffedHealth = baseStats.MaxHealth + config.hpIncrease
			maxHealth.Value = buffedHealth
			
			-- Update humanoid MaxHealth
			humanoid.MaxHealth = buffedHealth
			
			-- Increase current health proportionally or add flat amount (preserve health percentage)
			local healthPercentage = baseStats.MaxHealth > 0 and (baseStats.CurrentHealth / baseStats.MaxHealth) or 1
			local newHealth = math.min(buffedHealth * healthPercentage, buffedHealth)
			humanoid.Health = newHealth
		end
		
	elseif buffName == "BloodThirst" then
		-- BloodThirst: Provides lifesteal (no stat modifications, just tracking)
		-- Lifesteal is applied automatically in hitbox creation
		
	elseif buffName == "LastChance" then
		-- LastChance: Provides status immunity and HP regeneration
		-- Status immunity is checked in StatusAilmentHandler
		-- HP regeneration is handled in update loop
		
	elseif buffName == "ChampionsCheer" then
		-- ChampionsCheer: Multiplies HP and Defense, adds HP regeneration
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Calculate buffed health (base * (1 + multiplier))
			local buffedHealth = math.floor(baseStats.MaxHealth * (1 + config.hpMultiplier))
			maxHealth.Value = buffedHealth
			
			-- Update humanoid MaxHealth
			humanoid.MaxHealth = buffedHealth
			
			-- Increase current health proportionally (preserve health percentage)
			local healthPercentage = baseStats.MaxHealth > 0 and (baseStats.CurrentHealth / baseStats.MaxHealth) or 1
			local newHealth = math.min(buffedHealth * healthPercentage, buffedHealth)
			humanoid.Health = newHealth
		end
		
		if maxDefense and baseStats then
			-- Calculate buffed defense (base * (1 + multiplier))
			local buffedDefense = math.floor(baseStats.MaxDefense * (1 + config.defenseMultiplier))
			maxDefense.Value = buffedDefense
			
			-- Also update CurrentDefense to match MaxDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = buffedDefense
			end
		end
		
		-- HP regeneration is handled in update loop (similar to LastChance)
		
	elseif buffName == "ChampionsBlood" then
		-- ChampionsBlood: Adds flat Defense and provides status immunity
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxDefense and baseStats then
			-- Calculate buffed defense (base + flat increase)
			local buffedDefense = baseStats.MaxDefense + config.defenseIncrease
			maxDefense.Value = buffedDefense
			
			-- Also update CurrentDefense to match MaxDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = buffedDefense
			end
		end
		
		-- Status immunity is checked in StatusAilmentHandler (similar to LastChance)
		
	elseif buffName == "HuntersInstinct" then
		-- HuntersInstinct: Multiplies Movement Speed and provides status immunity
		local movementSpeed = leaderstats:FindFirstChild("MovementSpeed")
		
		if movementSpeed and baseStats then
			-- Calculate buffed movement speed (base * (1 + multiplier))
			local buffedMovementSpeed = baseStats.MovementSpeed * (1 + config.mspdMultiplier)
			movementSpeed.Value = buffedMovementSpeed
			
			-- Update unified movement animation speed in ServerConfigs
			local movementAnimSpeedMultiplier = movementSpeed.Value
			local classType = ServerConfigs.getPlayerClass(player)
			if classType and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
				ServerConfigs.Hitboxes.UnifiedAttacks[classType].movementSpeed = movementAnimSpeedMultiplier
			end
			if classType and ServerConfigs[classType] then
				ServerConfigs[classType].MovementSpeed = movementAnimSpeedMultiplier
			end
			
			-- Update humanoid walk speed
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid and classType then
				local baseStatsConfig = BaseStats[classType]
				local baseMspd = baseStatsConfig and baseStatsConfig.Mspd or 18
				humanoid.WalkSpeed = baseMspd * movementAnimSpeedMultiplier
			end
			
			-- Sync animation speeds with action files
			local classFuncs = {
				Archer = _G.updateArcherAnimationSpeed,
				Samurai = _G.updateSamuraiAnimationSpeed,
				Brawler = _G.updateBrawlerAnimationSpeed,
				Knight = _G.updateKnightAnimationSpeed,
				Gladiator = _G.updateGladiatorAnimationSpeed
			}
			local updateFunc = classFuncs[classType]
			if updateFunc then
				updateFunc("movement", movementAnimSpeedMultiplier)
			end
		end
		
		-- Status immunity is checked in StatusAilmentHandler (similar to LastChance/ChampionsBlood)
		
	elseif buffName == "HuntersMark" then
		-- HuntersMark: Adds flat Attack and Attack Speed
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local attackSpeed = leaderstats:FindFirstChild("AttackSpeed")
		
		if maxAttack and baseStats then
			-- Calculate buffed attack (base + flat increase)
			local buffedAttack = baseStats.MaxAttack + config.attackIncrease
			maxAttack.Value = buffedAttack
		end
		
		if attackSpeed and baseStats then
			-- Calculate buffed attack speed (base + flat increase)
			local buffedAttackSpeed = baseStats.AttackSpeed + config.attackSpeedIncrease
			attackSpeed.Value = buffedAttackSpeed
			
			-- Update unified attack animation speed in ServerConfigs
			local attackAnimSpeedMultiplier = attackSpeed.Value
			local classType = ServerConfigs.getPlayerClass(player)
			if classType and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
				ServerConfigs.Hitboxes.UnifiedAttacks[classType].attackSpeed = attackAnimSpeedMultiplier
			end
			if classType and ServerConfigs[classType] then
				ServerConfigs[classType].AttackSpeed = attackAnimSpeedMultiplier
			end
			
			-- Sync animation speeds with action files
			local classFuncs = {
				Archer = _G.updateArcherAnimationSpeed,
				Samurai = _G.updateSamuraiAnimationSpeed,
				Brawler = _G.updateBrawlerAnimationSpeed,
				Knight = _G.updateKnightAnimationSpeed,
				Gladiator = _G.updateGladiatorAnimationSpeed
			}
			local updateFunc = classFuncs[classType]
			if updateFunc then
				updateFunc("attack", attackAnimSpeedMultiplier)
			end
		end
		
	elseif buffName == "Banzai" then
		-- Banzai: Provides immunity to damage (no stat modifications needed)
		-- Enable invincibility for the entire buff duration
		if _G.enablePlayerInvincibility then
			_G.enablePlayerInvincibility(player)
		end
		-- The static hitbox creation is handled in the buff file when marker is reached
		
	elseif buffName == "Bushido" then
		-- Bushido: Prevents HP from hitting 0 (death prevention)
		-- No stat modifications needed, death prevention is handled via HealthChanged monitoring
		-- Set up death prevention monitoring
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				-- Store Bushido state for this player
				if not playerBushidoStates then
					playerBushidoStates = {}
				end
				playerBushidoStates[player] = {
					active = true,
					character = character,
					humanoid = humanoid
				}
				
				-- Monitor health changes to prevent HP from hitting 0
				local healthConnection
				healthConnection = humanoid.HealthChanged:Connect(function()
					if humanoid.Health <= 0 then
						-- Check if Bushido buff is still active
						if playerBuffs[player] and playerBuffs[player]["Bushido"] then
							local buffData = playerBuffs[player]["Bushido"]
							if buffData and buffData.endTime and tick() < buffData.endTime then
								-- Buff is still active, prevent death by setting HP to 1
								humanoid.Health = 1
							end
						end
					end
				end)
				
				-- Also use RunService.Heartbeat as backup (similar to One Last Chance)
				local RunService = game:GetService("RunService")
				local heartbeatConnection
				heartbeatConnection = RunService.Heartbeat:Connect(function()
					if not character or not character.Parent or not humanoid or not humanoid.Parent then
						if heartbeatConnection then heartbeatConnection:Disconnect() end
						return
					end
					
					-- Check if Bushido buff is still active
					if playerBuffs[player] and playerBuffs[player]["Bushido"] then
						local buffData = playerBuffs[player]["Bushido"]
						if buffData and buffData.endTime and tick() < buffData.endTime then
							-- Buff is active, prevent HP from hitting 0
							if humanoid.Health <= 0 then
								humanoid.Health = 1
							end
						else
							-- Buff expired, disconnect
							if heartbeatConnection then heartbeatConnection:Disconnect() end
						end
					else
						-- Buff removed, disconnect
						if heartbeatConnection then heartbeatConnection:Disconnect() end
					end
				end)
				
				-- Store connections for cleanup
				playerBushidoStates[player].healthConnection = healthConnection
				playerBushidoStates[player].heartbeatConnection = heartbeatConnection
			end
		end
	end
	
	-- Track buff
	local startTime = tick()
	local endTime = startTime + config.duration
	playerBuffs[player][buffName] = {
		config = config,
		startTime = startTime,
		endTime = endTime,
		baseStats = baseStats,
		equipmentSnapshot = equipmentSnapshot
	}
	
	-- Store base stats in leaderstats for UI display (only for UI, not used in calculations)
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	if not baseStatsFolder then
		baseStatsFolder = Instance.new("Folder", leaderstats)
		baseStatsFolder.Name = "BaseStats"
	end
	
	if buffName == "Warcry" then
		-- Store base Attack and Defense for UI
		if baseStats then
			local baseAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
			if not baseAttack then
				baseAttack = Instance.new("NumberValue", baseStatsFolder)
				baseAttack.Name = "BaseMaxAttack"
			end
			baseAttack.Value = baseStats.MaxAttack
			
			local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
			if not baseDefense then
				baseDefense = Instance.new("NumberValue", baseStatsFolder)
				baseDefense.Name = "BaseMaxDefense"
			end
			baseDefense.Value = baseStats.MaxDefense
		end
	elseif buffName == "WarriorMight" then
		-- Store base Health for UI
		if baseStats then
			local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
			if not baseHealth then
				baseHealth = Instance.new("NumberValue", baseStatsFolder)
				baseHealth.Name = "BaseMaxHealth"
			end
			baseHealth.Value = baseStats.MaxHealth
		end
	elseif buffName == "ChampionsCheer" then
		-- Store base Health and Defense for UI
		if baseStats then
			local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
			if not baseHealth then
				baseHealth = Instance.new("NumberValue", baseStatsFolder)
				baseHealth.Name = "BaseMaxHealth"
			end
			baseHealth.Value = baseStats.MaxHealth
			
			local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
			if not baseDefense then
				baseDefense = Instance.new("NumberValue", baseStatsFolder)
				baseDefense.Name = "BaseMaxDefense"
			end
			baseDefense.Value = baseStats.MaxDefense
		end
	elseif buffName == "ChampionsBlood" then
		-- Store base Defense for UI
		if baseStats then
			local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
			if not baseDefense then
				baseDefense = Instance.new("NumberValue", baseStatsFolder)
				baseDefense.Name = "BaseMaxDefense"
			end
			baseDefense.Value = baseStats.MaxDefense
		end
	elseif buffName == "HuntersInstinct" then
		-- Store base MovementSpeed for UI
		if baseStats then
			local baseMovementSpeed = baseStatsFolder:FindFirstChild("BaseMovementSpeed")
			if not baseMovementSpeed then
				baseMovementSpeed = Instance.new("NumberValue", baseStatsFolder)
				baseMovementSpeed.Name = "BaseMovementSpeed"
			end
			baseMovementSpeed.Value = baseStats.MovementSpeed
		end
	elseif buffName == "HuntersMark" then
		-- Store base Attack and AttackSpeed for UI
		if baseStats then
			local baseAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
			if not baseAttack then
				baseAttack = Instance.new("NumberValue", baseStatsFolder)
				baseAttack.Name = "BaseMaxAttack"
			end
			baseAttack.Value = baseStats.MaxAttack
			
			local baseAttackSpeed = baseStatsFolder:FindFirstChild("BaseAttackSpeed")
			if not baseAttackSpeed then
				baseAttackSpeed = Instance.new("NumberValue", baseStatsFolder)
				baseAttackSpeed.Name = "BaseAttackSpeed"
			end
			baseAttackSpeed.Value = baseStats.AttackSpeed
		end
	end
	
	-- Update ActiveBuffs string value
	local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
	if activeBuffs then
		local currentBuffs = activeBuffs.Value
		if currentBuffs == "" then
			activeBuffs.Value = buffName
		else
			activeBuffs.Value = currentBuffs .. "," .. buffName
		end
	end
	
	-- Create buff duration tracking value
	local buffDurations = leaderstats:FindFirstChild("BuffDurations")
	if buffDurations then
		local buffDuration = Instance.new("NumberValue", buffDurations)
		buffDuration.Name = buffName
		buffDuration.Value = math.ceil(config.duration)
		
		-- Update duration countdown
		local buffStartTime = tick()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if not buffDuration or not buffDuration.Parent then
				connection:Disconnect()
				return
			end
			local elapsed = tick() - buffStartTime
			local remaining = math.max(0, math.ceil(config.duration - elapsed))
			buffDuration.Value = remaining
			if remaining <= 0 then
				connection:Disconnect()
			end
		end)
	end
	
	-- Start HP regeneration for ChampionsCheer buff
	if buffName == "ChampionsCheer" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Start HP regeneration loop
				local regenThread = task.spawn(function()
					while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
						-- Check if buff is still active
						if not playerBuffs[player] or not playerBuffs[player]["ChampionsCheer"] then
							break
						end
						
						local buffData = playerBuffs[player]["ChampionsCheer"]
						if not buffData or not buffData.config then
							break
						end
						
						-- Check if buff expired
						local currentTime = tick()
						if currentTime >= buffData.endTime then
							break
						end
						
						-- Wait 1 second before next regeneration
						task.wait(1)
						
						-- Check again after wait (character might have been removed or buff expired)
						if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
							break
						end
						
						if not playerBuffs[player] or not playerBuffs[player]["ChampionsCheer"] then
							break
						end
						
						-- Get HP regen percentage from buff config
						local hpRegenPercentage = buffData.config.hpRegenPercentage or 0
						if hpRegenPercentage > 0 then
							-- Calculate healing amount (percentage of Max HP)
							local maxHealth = humanoid.MaxHealth
							local healingAmount = maxHealth * hpRegenPercentage
							
							-- Regenerate health (cap at MaxHealth)
							local newHealth = math.min(humanoid.Health + healingAmount, maxHealth)
							humanoid.Health = newHealth
						end
					end
				end)
			end
		end
	end
	
	-- Start HP regeneration and status immunity display for LastChance buff
	if buffName == "LastChance" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Start HP regeneration loop
				local regenThread = task.spawn(function()
					while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
						-- Check if buff is still active
						if not playerBuffs[player] or not playerBuffs[player]["LastChance"] then
							break
						end
						
						local buffData = playerBuffs[player]["LastChance"]
						if not buffData or not buffData.config then
							break
						end
						
						-- Check if buff expired
						local currentTime = tick()
						if currentTime >= buffData.endTime then
							break
						end
						
						-- Wait 1 second before next regeneration
						task.wait(1)
						
						-- Check again after wait (character might have been removed or buff expired)
						if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
							break
						end
						
						if not playerBuffs[player] or not playerBuffs[player]["LastChance"] then
							break
						end
						
						-- Get HP regen percentage from buff config
						local hpRegenPercentage = buffData.config.hpRegenPercentage or 0
						if hpRegenPercentage > 0 then
							-- Calculate healing amount (percentage of Max HP)
							local maxHealth = humanoid.MaxHealth
							local healingAmount = maxHealth * hpRegenPercentage
							
							-- Regenerate health (cap at MaxHealth)
							local newHealth = math.min(humanoid.Health + healingAmount, maxHealth)
							humanoid.Health = newHealth
						end
					end
				end)
				
				-- Show "Immune" text above head during immunity duration
				local RunService = game:GetService("RunService")
				local head = character:FindFirstChild("Head")
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				local attachPart = head or humanoidRootPart
				
				if attachPart then
					-- Create "Immune" text
					local billboardGui = Instance.new("BillboardGui")
					billboardGui.Name = "ImmuneText_" .. tostring(tick() * 1000)
					billboardGui.Size = UDim2.new(0, 200, 0, 50)
					billboardGui.StudsOffset = Vector3.new(0, 3.5, 0) -- Above head, higher than ailment text
					billboardGui.AlwaysOnTop = true
					billboardGui.LightInfluence = 0
					billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
					billboardGui.Parent = attachPart
					
					-- Create TextLabel
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.Text = "IMMUNE"
					textLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
					textLabel.TextSize = 24
					textLabel.Font = Enum.Font.GothamBold
					textLabel.TextStrokeTransparency = 0
					textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
					textLabel.TextXAlignment = Enum.TextXAlignment.Center
					textLabel.TextYAlignment = Enum.TextYAlignment.Center
					textLabel.Parent = billboardGui
					
					-- Monitor immunity status and remove text when immunity expires
					local connection
					connection = RunService.Heartbeat:Connect(function()
						if not character or not character.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
						
						if not playerBuffs[player] or not playerBuffs[player]["LastChance"] then
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
						
						local buffData = playerBuffs[player]["LastChance"]
						if not buffData or not buffData.config then
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
						
						local currentTime = tick()
						local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
						
						if currentTime >= immunityEndTime then
							-- Immunity expired, remove text
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
					end)
					
					-- Clean up when done (safety cleanup)
					local buffData = playerBuffs[player]["LastChance"]
					if buffData and buffData.config then
						task.delay(buffData.config.immunityDuration + 0.1, function()
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
						end)
					end
				end
			end
		end
	end
	
	-- Start status immunity display for HuntersInstinct buff
	if buffName == "HuntersInstinct" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local head = character:FindFirstChild("Head")
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local attachPart = head or humanoidRootPart
			
			if attachPart then
				-- Create "Immune" text above head during immunity duration
				local RunService = game:GetService("RunService")
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Name = "ImmuneText_" .. tostring(tick() * 1000)
				billboardGui.Size = UDim2.new(0, 200, 0, 50)
				billboardGui.StudsOffset = Vector3.new(0, 3.5, 0) -- Above head, higher than ailment text
				billboardGui.AlwaysOnTop = true
				billboardGui.LightInfluence = 0
				billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
				billboardGui.Parent = attachPart
				
				-- Create TextLabel
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = "IMMUNE"
				textLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
				textLabel.TextSize = 24
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextStrokeTransparency = 0
				textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
				textLabel.TextXAlignment = Enum.TextXAlignment.Center
				textLabel.TextYAlignment = Enum.TextYAlignment.Center
				textLabel.Parent = billboardGui
				
				-- Monitor immunity status and remove text when immunity expires
				local connection
				connection = RunService.Heartbeat:Connect(function()
					if not character or not character.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					if not playerBuffs[player] or not playerBuffs[player]["HuntersInstinct"] then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					local buffData = playerBuffs[player]["HuntersInstinct"]
					if not buffData or not buffData.config then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					local currentTime = tick()
					local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
					
					if currentTime >= immunityEndTime then
						-- Immunity expired, remove text
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
				end)
				
				-- Clean up when done (safety cleanup)
				local buffData = playerBuffs[player]["HuntersInstinct"]
				if buffData and buffData.config then
					task.delay(buffData.config.immunityDuration + 0.1, function()
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
					end)
				end
			end
		end
	end
	
	-- Start status immunity display for ChampionsBlood buff
	if buffName == "ChampionsBlood" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local head = character:FindFirstChild("Head")
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local attachPart = head or humanoidRootPart
			
			if attachPart then
				-- Create "Immune" text above head during immunity duration
				local RunService = game:GetService("RunService")
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Name = "ImmuneText_" .. tostring(tick() * 1000)
				billboardGui.Size = UDim2.new(0, 200, 0, 50)
				billboardGui.StudsOffset = Vector3.new(0, 3.5, 0) -- Above head, higher than ailment text
				billboardGui.AlwaysOnTop = true
				billboardGui.LightInfluence = 0
				billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
				billboardGui.Parent = attachPart
				
				-- Create TextLabel
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = "IMMUNE"
				textLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
				textLabel.TextSize = 24
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextStrokeTransparency = 0
				textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
				textLabel.TextXAlignment = Enum.TextXAlignment.Center
				textLabel.TextYAlignment = Enum.TextYAlignment.Center
				textLabel.Parent = billboardGui
				
				-- Monitor immunity status and remove text when immunity expires
				local connection
				connection = RunService.Heartbeat:Connect(function()
					if not character or not character.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					if not playerBuffs[player] or not playerBuffs[player]["ChampionsBlood"] then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					local buffData = playerBuffs[player]["ChampionsBlood"]
					if not buffData or not buffData.config then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					local currentTime = tick()
					local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
					
					if currentTime >= immunityEndTime then
						-- Immunity expired, remove text
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
				end)
				
				-- Clean up when done (safety cleanup)
				local buffData = playerBuffs[player]["ChampionsBlood"]
				if buffData and buffData.config then
					task.delay(buffData.config.immunityDuration + 0.1, function()
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
					end)
				end
			end
		end
	end
	
	-- Auto-remove buff after duration
	task.delay(config.duration, function()
		if playerBuffs[player] and playerBuffs[player][buffName] then
			_G.removeBuff(player, buffName)
		end
	end)
	
	enforceStatCaps(leaderstats)

	return true
end

-- Function to remove a buff from a player
-- @param player: Player instance
-- @param buffName: "Warcry" or "WarriorMight"
-- @return: true if buff was removed, false otherwise
function _G.removeBuff(player, buffName)
	if not player or not buffName then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	if not playerBuffs[player] or not playerBuffs[player][buffName] then
		return false
	end
	
	local buffData = playerBuffs[player][buffName]
	local baseStats = buffData.baseStats
	local equipmentSnapshot = buffData.equipmentSnapshot or {}

	local function baseWithoutEquipment(statName, value)
		if equipmentSnapshot[statName] then
			return math.max(0, value - equipmentSnapshot[statName])
		end
		return value
	end

	local aggregatedEquipmentSnapshot = {}
	do
		local currentAggregated = select(1, computeEquipmentBonuses(player))
		for statName, amount in pairs(currentAggregated) do
			aggregatedEquipmentSnapshot[statName] = amount
		end
	end

	local pendingHealthValue = nil
	
	-- Restore base stats
	if buffName == "Warcry" then
		-- Warcry: Restore Attack and Defense to base values
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxAttack and baseStats then
			maxAttack.Value = baseWithoutEquipment("MaxAttack", baseStats.MaxAttack)
		end
		
		if maxDefense and baseStats then
			local restoredDefense = baseWithoutEquipment("MaxDefense", baseStats.MaxDefense)
			maxDefense.Value = restoredDefense
			
			-- Also restore CurrentDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = restoredDefense
			end
		end
		
	elseif buffName == "WarriorMight" then
		-- WarriorMight: Restore HP to base value
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Restore base health
			local restoredHealth = baseWithoutEquipment("MaxHealth", baseStats.MaxHealth)
			maxHealth.Value = restoredHealth
			humanoid.MaxHealth = restoredHealth
			
			-- Restore health percentage (cap at max health) after reapplying equipment bonuses
			local buffedMaxHealthBeforeRemoval = baseStats.MaxHealth + (buffData.config.hpIncrease or 0)
			local finalMaxHealthAfterEquipment = restoredHealth + (aggregatedEquipmentSnapshot.MaxHealth or 0)
			local healthPercentage = buffedMaxHealthBeforeRemoval > 0 and (humanoid.Health / buffedMaxHealthBeforeRemoval) or 1
			local desiredHealth = math.min(finalMaxHealthAfterEquipment * healthPercentage, finalMaxHealthAfterEquipment)
			pendingHealthValue = desiredHealth
		end
		
	elseif buffName == "BloodThirst" then
		-- BloodThirst: No stat restoration needed (no stat modifications)
		
	elseif buffName == "LastChance" then
		-- LastChance: No stat restoration needed (no stat modifications)
		-- Status immunity and HP regen are handled automatically
		
	elseif buffName == "ChampionsCheer" then
		-- ChampionsCheer: Restore HP and Defense to base values
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Restore base health
			local restoredHealth = baseWithoutEquipment("MaxHealth", baseStats.MaxHealth)
			maxHealth.Value = restoredHealth
			humanoid.MaxHealth = restoredHealth
			
			-- Restore health percentage (cap at max health) after reapplying equipment bonuses
			local buffedMaxHealth = baseStats.MaxHealth * (1 + buffData.config.hpMultiplier)
			local finalMaxHealthAfterEquipment = restoredHealth + (aggregatedEquipmentSnapshot.MaxHealth or 0)
			local healthPercentage = buffedMaxHealth > 0 and (humanoid.Health / buffedMaxHealth) or 1
			local desiredHealth = math.min(finalMaxHealthAfterEquipment * healthPercentage, finalMaxHealthAfterEquipment)
			pendingHealthValue = desiredHealth
		end
		
		if maxDefense and baseStats then
			-- Restore base defense
			local restoredDefense = baseWithoutEquipment("MaxDefense", baseStats.MaxDefense)
			maxDefense.Value = restoredDefense
			
			-- Also restore CurrentDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = restoredDefense
			end
		end
		
	elseif buffName == "ChampionsBlood" then
		-- ChampionsBlood: Restore Defense to base value
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxDefense and baseStats then
			-- Restore base defense
			local restoredDefense = baseWithoutEquipment("MaxDefense", baseStats.MaxDefense)
			maxDefense.Value = restoredDefense
			
			-- Also restore CurrentDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = restoredDefense
			end
		end
		
		-- Status immunity is handled automatically
		
	elseif buffName == "HuntersInstinct" then
		-- HuntersInstinct: Restore Movement Speed to base value
		local movementSpeed = leaderstats:FindFirstChild("MovementSpeed")
		
	if movementSpeed and baseStats then
		-- Restore base movement speed
		movementSpeed.Value = baseWithoutEquipment("MovementSpeed", baseStats.MovementSpeed)
			
			-- Update unified movement animation speed in ServerConfigs
			local movementAnimSpeedMultiplier = movementSpeed.Value
			local classType = ServerConfigs.getPlayerClass(player)
			if classType and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
				ServerConfigs.Hitboxes.UnifiedAttacks[classType].movementSpeed = movementAnimSpeedMultiplier
			end
			if classType and ServerConfigs[classType] then
				ServerConfigs[classType].MovementSpeed = movementAnimSpeedMultiplier
			end
			
			-- Update humanoid walk speed
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid and classType then
				local baseStatsConfig = BaseStats[classType]
				local baseMspd = baseStatsConfig and baseStatsConfig.Mspd or 18
				humanoid.WalkSpeed = baseMspd * movementAnimSpeedMultiplier
			end
			
			-- Sync animation speeds with action files
			local classFuncs = {
				Archer = _G.updateArcherAnimationSpeed,
				Samurai = _G.updateSamuraiAnimationSpeed,
				Brawler = _G.updateBrawlerAnimationSpeed,
				Knight = _G.updateKnightAnimationSpeed,
				Gladiator = _G.updateGladiatorAnimationSpeed
			}
			local updateFunc = classFuncs[classType]
			if updateFunc then
				updateFunc("movement", movementAnimSpeedMultiplier)
			end
		end
		
		-- Status immunity is handled automatically
		
	elseif buffName == "HuntersMark" then
		-- HuntersMark: Restore Attack and Attack Speed to base values
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local attackSpeed = leaderstats:FindFirstChild("AttackSpeed")
		
		if maxAttack and baseStats then
			-- Restore base attack
		maxAttack.Value = baseWithoutEquipment("MaxAttack", baseStats.MaxAttack)
		end
		
		if attackSpeed and baseStats then
			-- Restore base attack speed
		attackSpeed.Value = baseWithoutEquipment("AttackSpeed", baseStats.AttackSpeed)
			
			-- Update unified attack animation speed in ServerConfigs
			local attackAnimSpeedMultiplier = attackSpeed.Value
			local classType = ServerConfigs.getPlayerClass(player)
			if classType and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
				ServerConfigs.Hitboxes.UnifiedAttacks[classType].attackSpeed = attackAnimSpeedMultiplier
			end
			if classType and ServerConfigs[classType] then
				ServerConfigs[classType].AttackSpeed = attackAnimSpeedMultiplier
			end
			
			-- Sync animation speeds with action files
			local classFuncs = {
				Archer = _G.updateArcherAnimationSpeed,
				Samurai = _G.updateSamuraiAnimationSpeed,
				Brawler = _G.updateBrawlerAnimationSpeed,
				Knight = _G.updateKnightAnimationSpeed,
				Gladiator = _G.updateGladiatorAnimationSpeed
			}
			local updateFunc = classFuncs[classType]
			if updateFunc then
				updateFunc("attack", attackAnimSpeedMultiplier)
			end
		end
		
	elseif buffName == "Banzai" then
		-- Banzai: Disable invincibility (allow damage again)
		if _G.disablePlayerInvincibility then
			_G.disablePlayerInvincibility(player)
		end
		
	elseif buffName == "Bushido" then
		-- Bushido: Clean up death prevention monitoring
		if playerBushidoStates and playerBushidoStates[player] then
			local state = playerBushidoStates[player]
			if state.healthConnection then
				state.healthConnection:Disconnect()
			end
			if state.heartbeatConnection then
				state.heartbeatConnection:Disconnect()
			end
			playerBushidoStates[player] = nil
		end
	end
	
	-- Remove buff tracking
	playerBuffs[player][buffName] = nil
	
	-- Update ActiveBuffs string value
	local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
	if activeBuffs then
		local currentBuffs = activeBuffs.Value
		local buffList = {}
		for buff in string.gmatch(currentBuffs, "([^,]+)") do
			if buff ~= buffName then
				table.insert(buffList, buff)
			end
		end
		activeBuffs.Value = table.concat(buffList, ",")
	end
	
	-- Remove buff duration tracking
	local buffDurations = leaderstats:FindFirstChild("BuffDurations")
	if buffDurations then
		local buffDuration = buffDurations:FindFirstChild(buffName)
		if buffDuration then
			buffDuration:Destroy()
		end
	end
	
	-- Remove base stats tracking when buff expires (clean up BaseStats folder)
	-- BUT: Only remove if no other buffs/passives are using it
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	if baseStatsFolder then
		-- Check if other buffs are active that might need these base stats
		local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
		local activePassives = leaderstats:FindFirstChild("ActivePassives")
		local hasOtherBuffs = false
		local hasPassives = false
		
		-- Check for other active buffs
		if activeBuffs and activeBuffs.Value ~= "" then
			for buff in string.gmatch(activeBuffs.Value, "([^,]+)") do
				if buff ~= buffName then
					hasOtherBuffs = true
					break
				end
			end
		end
		
		-- Check for active passives
		if activePassives and activePassives.Value ~= "" then
			hasPassives = true
		end
		
		-- Only remove BaseStats if no other buffs/passives are active
		if not hasOtherBuffs and not hasPassives then
			if buffName == "Warcry" then
				local baseAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
				if baseAttack then
					baseAttack:Destroy()
				end
				local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
				if baseDefense then
					baseDefense:Destroy()
				end
			elseif buffName == "WarriorMight" then
				local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
				if baseHealth then
					baseHealth:Destroy()
				end
			elseif buffName == "ChampionsCheer" then
				local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
				if baseHealth then
					baseHealth:Destroy()
				end
				local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
				if baseDefense then
					baseDefense:Destroy()
				end
			elseif buffName == "ChampionsBlood" then
				local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
				if baseDefense then
					baseDefense:Destroy()
				end
			elseif buffName == "HuntersInstinct" then
				local baseMovementSpeed = baseStatsFolder:FindFirstChild("BaseMovementSpeed")
				if baseMovementSpeed then
					baseMovementSpeed:Destroy()
				end
			elseif buffName == "HuntersMark" then
				local baseAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
				if baseAttack then
					baseAttack:Destroy()
				end
				local baseAttackSpeed = baseStatsFolder:FindFirstChild("BaseAttackSpeed")
				if baseAttackSpeed then
					baseAttackSpeed:Destroy()
				end
			end
			
			-- Clean up BaseStats folder if it's empty
			if #baseStatsFolder:GetChildren() == 0 then
				baseStatsFolder:Destroy()
			end
		end
	end
	
	-- Reapply current equipment bonuses after stats were reset
	local humanoidAfterRefresh = nil

	if leaderstats then
		if playerEquipmentBonuses[player] then
			playerEquipmentBonuses[player] = nil
		end
		if playerEquipmentBonusDetails[player] then
			playerEquipmentBonusDetails[player] = nil
		end
		refreshEquipmentBonuses(player)
		humanoidAfterRefresh = player.Character and player.Character:FindFirstChild("Humanoid")
	end

	if pendingHealthValue and humanoidAfterRefresh then
		humanoidAfterRefresh.Health = math.min(pendingHealthValue, humanoidAfterRefresh.MaxHealth)
	end

	enforceStatCaps(leaderstats)
	
	return true
end

-- Function to get active buffs for a player
-- @param player: Player instance
-- @return: Table of active buff names
function _G.getActiveBuffs(player)
	if not playerBuffs[player] then
		return {}
	end
	
	local active = {}
	for buffName, _ in pairs(playerBuffs[player]) do
		table.insert(active, buffName)
	end
	
	return active
end

-- Function to get player's active lifesteal percentage from buffs
-- @param player: Player instance
-- @return: Lifesteal percentage (0.03 = 3%) or nil if no lifesteal buff active
function _G.getPlayerLifestealPercentage(player)
	if not player or not playerBuffs[player] then
		return nil
	end
	
	-- Check for BloodThirst buff
	if playerBuffs[player]["BloodThirst"] then
		local buffData = playerBuffs[player]["BloodThirst"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Buff is still active
				return buffData.config.lifestealPercentage
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["BloodThirst"] = nil
			end
		end
	end
	
	return nil
end

-- Function to check if player has status immunity (from LastChance, ChampionsBlood, or HuntersInstinct buff)
-- @param player: Player instance
-- @return: true if player has status immunity, false otherwise
function _G.hasStatusImmunity(player)
	if not player or not playerBuffs[player] then
		return false
	end
	
	-- Check for LastChance buff
	if playerBuffs[player]["LastChance"] then
		local buffData = playerBuffs[player]["LastChance"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Check if immunity duration is still active
				local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
				if currentTime < immunityEndTime then
					-- Player has status immunity
					return true
				end
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["LastChance"] = nil
			end
		end
	end
	
	-- Check for ChampionsBlood buff
	if playerBuffs[player]["ChampionsBlood"] then
		local buffData = playerBuffs[player]["ChampionsBlood"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Check if immunity duration is still active
				local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
				if currentTime < immunityEndTime then
					-- Player has status immunity
					return true
				end
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["ChampionsBlood"] = nil
			end
		end
	end
	
	-- Check for HuntersInstinct buff
	if playerBuffs[player]["HuntersInstinct"] then
		local buffData = playerBuffs[player]["HuntersInstinct"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Check if immunity duration is still active
				local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
				if currentTime < immunityEndTime then
					-- Player has status immunity
					return true
				end
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["HuntersInstinct"] = nil
			end
		end
	end
	
	return false
end

-- Clean up buffs when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	if playerBuffs[player] then
		playerBuffs[player] = nil
	end

	clearEquipmentBonuses(player)
	clearConsumableState(player)
end)

-- ========================================
-- INVINCIBILITY / GOD MODE SYSTEM
-- ========================================

-- Track which players are currently invincible (during skill/ult execution)
-- Key: player, Value: boolean (true = invincible, false/nil = not invincible)
-- This freezes health - no damage is applied while invincible (health stays the same)
local playerInvincibility = {}

-- Function to enable invincibility for a player (freezes health, prevents damage)
-- @param player: Player instance
function _G.enablePlayerInvincibility(player)
	if not player then return end
	playerInvincibility[player] = true
end

-- Function to disable invincibility for a player (allows damage again)
-- @param player: Player instance
function _G.disablePlayerInvincibility(player)
	if not player then return end
	playerInvincibility[player] = nil
end

-- Function to check if player is invincible
-- @param player: Player instance
-- @return: true if player is invincible, false otherwise
function _G.isPlayerInvincible(player)
	if not player then return false end
	return playerInvincibility[player] == true
end

-- Clean up invincibility when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	if playerInvincibility[player] then
		playerInvincibility[player] = nil
	end
	
	-- Clean up Bushido states when player leaves
	if playerBushidoStates and playerBushidoStates[player] then
		local state = playerBushidoStates[player]
		if state.healthConnection then
			state.healthConnection:Disconnect()
		end
		if state.heartbeatConnection then
			state.heartbeatConnection:Disconnect()
		end
		playerBushidoStates[player] = nil
	end
end)

-- Helper function to get XP multiplier for a specific level
local function getXPMultiplierForLevel(level)
	local defaultMultiplier = BaseStats.XP.xpMultiplier or 1.2
	local levelMultipliers = BaseStats.XP.levelMultipliers
	
	if not levelMultipliers then
		return defaultMultiplier
	end
	
	local selectedMultiplier = defaultMultiplier
	for _, entry in ipairs(levelMultipliers) do
		if level >= entry.level then
			selectedMultiplier = entry.multiplier
		else
			break
		end
	end
	
	return selectedMultiplier
end

-- Helper function to calculate MaximumXP based on level
local function calculateMaximumXP(level)
	local startMaxXP = BaseStats.XP.startMaxXP
	if level <= 1 then
		return math.floor(startMaxXP)
	end
	
	local calculatedMaxXP = startMaxXP
	for currentLevel = 2, level do
		local xpMultiplier = getXPMultiplierForLevel(currentLevel)
		calculatedMaxXP = math.floor(calculatedMaxXP * xpMultiplier)
	end
	
	return calculatedMaxXP
end

-- Helper function to convert data values to proper types
local function convertDataType(value, defaultValue)
	if value == nil then
		return defaultValue
	end
	-- If it's a string, try to convert to number
	if typeof(value) == "string" then
		local numValue = tonumber(value)
		return numValue ~= nil and numValue or defaultValue
	end
	-- If it's already a number, return it
	if typeof(value) == "number" then
		return value
	end
	return defaultValue
end


game.Players.PlayerAdded:Connect(function(plr)
	
	local teleportData = plr:GetJoinData().TeleportData
	--print("PlayerAdded: TeleportData =", teleportData)
	local data

	if teleportData then
		-- Use TeleportData if present
		data = teleportData
		--print("Loaded data from TeleportData:", data)
	else
		-- Otherwise, load from MainDataStore
		if MainDataStore then
			data = MainDataStore.LoadPlayerData(plr.UserId)
			--print("Loaded data from MainDataStore:", data)
		else
			--warn("MainDataStore not available, cannot load player data.")
		end
	end


	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plr

	local level = Instance.new("IntValue", leaderstats)
	level.Name = "Level"
	level.Value = BaseStats.XP.startLevel

	local currxp = Instance.new("NumberValue", leaderstats)
	currxp.Name = "CurrentXP"
	currxp.Value = BaseStats.XP.startXP

	local maxxp = Instance.new("NumberValue", leaderstats)
	maxxp.Name = "MaximumXP"
	maxxp.Value = BaseStats.XP.startMaxXP

	local class = Instance.new("StringValue", leaderstats)
	class.Name = "Class"
	class.Value = "Slavkorian"

	-- Offense Stats
	local maxAttack = Instance.new("NumberValue", leaderstats)
	maxAttack.Name = "MaxAttack"
	maxAttack.Value = 0 -- Will be set based on class
	
	local defensePenetration = Instance.new("NumberValue", leaderstats)
	defensePenetration.Name = "DefensePenetration"
	defensePenetration.Value = 0
	
	local critRate = Instance.new("NumberValue", leaderstats)
	critRate.Name = "CritRate"
	critRate.Value = 0
	
	local critMultiplier = Instance.new("NumberValue", leaderstats)
	critMultiplier.Name = "CritMultiplier"
	critMultiplier.Value = 0
	

	-- Defense Stats
	local maxDefense = Instance.new("NumberValue", leaderstats)
	maxDefense.Name = "MaxDefense"
	maxDefense.Value = 0 -- Will be set based on class
	
	local currentDefense = Instance.new("NumberValue", leaderstats)
	currentDefense.Name = "CurrentDefense"
	currentDefense.Value = 0 -- Will track current defense (damaged defense)

	local maxHealth = Instance.new("NumberValue", leaderstats)
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = 0 -- Will be set based on class
	
	local healthRegen = Instance.new("NumberValue", leaderstats)
	healthRegen.Name = "HealthRegen"
	healthRegen.Value = 0
	
	local movementSpeed = Instance.new("NumberValue", leaderstats)
	movementSpeed.Name = "MovementSpeed"
	movementSpeed.Value = 0
	
	local attackSpeed = Instance.new("NumberValue", leaderstats)
	attackSpeed.Name = "AttackSpeed"
	attackSpeed.Value = 0

	local slavkoins = Instance.new("NumberValue", leaderstats)
	slavkoins.Name = "Slavkoins"
	slavkoins.Value = 0
	
	-- Buff tracking (stores active buff information)
	local activeBuffs = Instance.new("StringValue", leaderstats)
	activeBuffs.Name = "ActiveBuffs"
	activeBuffs.Value = "" -- Comma-separated list of active buffs (e.g., "Warcry,WarriorMight")
	
	-- Buff duration tracking (stores when buffs expire)
	local buffDurations = Instance.new("Folder", leaderstats)
	buffDurations.Name = "BuffDurations"
	
	-- Passive tracking (stores active passive information)
	local activePassives = Instance.new("StringValue", leaderstats)
	activePassives.Name = "ActivePassives"
	activePassives.Value = "" -- Comma-separated list of active passives (e.g., "Tenacity")
	
	-- Equipment bonus tracking (set by Inventory/Equipment systems)
	local equipmentBonusesFolder = Instance.new("Folder", leaderstats)
	equipmentBonusesFolder.Name = "EquipmentBonuses"
	
	local equipmentBonusDetailsFolder = Instance.new("Folder", leaderstats)
	equipmentBonusDetailsFolder.Name = "EquipmentBonusDetails"
	
	-- loads progress data
	if data then
		-- Convert and load level (ensure it's a number)
		local loadedLevel = convertDataType(data.Level, BaseStats.XP.startLevel)
		level.Value = math.min(math.max(loadedLevel, 1), BaseStats.XP.maxLevel)
		
		-- Load CurrentXP and ensure it's a number
		currxp.Value = convertDataType(data.CurrentXP, BaseStats.XP.startXP)
		
		-- Calculate MaximumXP based on level (don't trust saved MaximumXP as it might be outdated)
		maxxp.Value = calculateMaximumXP(level.Value)
		
		-- Load class
		class.Value = typeof(data.Class) == "string" and data.Class or "Slavkorian"
		
		-- Load all stats with proper type conversion
		maxAttack.Value = convertDataType(data.MaxAttack, 0)
		defensePenetration.Value = convertDataType(data.DefensePenetration, 0)
		critRate.Value = convertDataType(data.CritRate, 0)
		critMultiplier.Value = convertDataType(data.CritMultiplier, 0)
		maxDefense.Value = convertDataType(data.MaxDefense, 0)
		currentDefense.Value = convertDataType(data.CurrentDefense, data.MaxDefense or 0) -- Load CurrentDefense, default to MaxDefense if not saved
		maxHealth.Value = convertDataType(data.MaxHealth, 0)
		healthRegen.Value = convertDataType(data.HealthRegen, 0)
		
		-- Load MovementSpeed and AttackSpeed, but convert if they're old format (walk speed values > 1.5)
		-- MovementSpeed and AttackSpeed should be animation multipliers starting at 1.0
		local loadedMovementSpeed = convertDataType(data.MovementSpeed, 0)
		if loadedMovementSpeed >= 9 then
			-- Legacy saves stored raw WalkSpeed (e.g., 18). Convert those to animation multipliers.
			local baseMspd = 18
			local convertedMultiplier = loadedMovementSpeed / baseMspd
			movementSpeed.Value = convertedMultiplier
		else
			-- Modern saves already store the multiplier; keep it as-is (including 0 so base stats can initialize it).
			movementSpeed.Value = loadedMovementSpeed
		end
		
		local loadedAttackSpeed = convertDataType(data.AttackSpeed, 0)
		-- Use the stored attack speed multiplier as-is so we respect any custom tuning.
		attackSpeed.Value = loadedAttackSpeed
		
		slavkoins.Value = convertDataType(data.Slavkoins, 0)
		
		-- Ensure CurrentXP doesn't exceed MaximumXP
		if currxp.Value > maxxp.Value then
			-- If CurrentXP exceeds MaximumXP, trigger level up logic
			while currxp.Value >= maxxp.Value and level.Value < BaseStats.XP.maxLevel do
				local overtop = currxp.Value - maxxp.Value
				currxp.Value = overtop
				maxxp.Value = calculateMaximumXP(level.Value + 1)
				level.Value = level.Value + 1
			end
		end
	end

	enforceStatCaps(leaderstats)

	-- Ensure Slavkorian stays at starting level
	if class.Value == "Slavkorian" then
		level.Value = BaseStats.XP.startLevel
		maxxp.Value = calculateMaximumXP(BaseStats.XP.startLevel)
		if currxp.Value > maxxp.Value then
			currxp.Value = maxxp.Value
		end
	end

	-- Flag to track if stats have been initialized (to prevent applying multipliers on load)
	local statsInitialized = false
	
	-- XP-based leveling: Level only increases when CurrentXP >= MaximumXP
	-- Connect this OUTSIDE CharacterAdded so it works even before character spawns
	-- Use a flag to prevent recursive triggers
	local isLevelingUp = false
	currxp.Changed:Connect(function(newv)
		-- Prevent recursive calls
		if isLevelingUp then
			return
		end
		
		-- DISABLE LEVELING WHEN CLASS IS SLAVKORIAN
		if class.Value == "Slavkorian" then
			if maxxp and maxxp.Value and newv > maxxp.Value then
				currxp.Value = maxxp.Value
			end
			return -- Don't allow leveling up when class is Slavkorian
		end
		
		-- Ensure MaximumXP is valid
		if not maxxp or not maxxp.Value then
			return
		end
		
		-- Check if we should level up (handle multiple level-ups in one go)
		-- Level increases ONLY when XP reaches MaximumXP threshold
		isLevelingUp = true
		while newv >= maxxp.Value and level.Value < BaseStats.XP.maxLevel do
			local overtop = newv - maxxp.Value
			local currentLevel = level.Value
			
			-- Increment level (this will trigger level.Changed which recalculates MaximumXP)
			level.Value = currentLevel + 1
			-- LEVEL CAP: Clamp level to max level from config
			level.Value = math.min(level.Value, BaseStats.XP.maxLevel)
			
			-- MaximumXP should be updated by level.Changed event, but let's ensure it's correct
			-- Get the new MaximumXP for the new level
			local newMaxXP = calculateMaximumXP(level.Value)
			maxxp.Value = newMaxXP
			
			-- Set remaining XP
			currxp.Value = overtop
			newv = overtop -- Update for while loop condition
		end
		isLevelingUp = false
		
		-- If at max level, cap current XP to MaximumXP
		if level.Value >= BaseStats.XP.maxLevel then
			currxp.Value = math.min(currxp.Value, maxxp.Value)
		end
	end)
	
	-- Track previous level to detect actual level ups (not initial load)
	local previousLevel = level.Value

	-- Update MaxHealth in real-time when it changes (works even before character spawns)
	-- This ensures resets and other changes update the humanoid immediately
	maxHealth.Changed:Connect(function(newMaxHealth)
		-- Update humanoid MaxHealth in real-time if character exists
		if plr.Character then
			local humanoid = plr.Character:FindFirstChild("Humanoid")
			if humanoid then
				-- Store old MaxHealth and old health before changing it
				local oldMaxHealth = humanoid.MaxHealth
				local oldHealth = humanoid.Health
				
				-- Update MaxHealth first
				humanoid.MaxHealth = newMaxHealth
				
				-- Set health based on new MaxHealth
				if newMaxHealth > 0 then
					-- If MaxHealth is increasing or resetting (old was 0 or new >= old), set to full health
					-- If MaxHealth is decreasing, preserve health percentage (but ensure minimum 50%)
					if newMaxHealth >= oldMaxHealth or oldMaxHealth == 0 then
						-- Set to full health when resetting or increasing MaxHealth
						humanoid.Health = newMaxHealth
					else
						-- Preserve health percentage when MaxHealth decreases (but ensure it's not too low)
						local healthPercentage = oldMaxHealth > 0 and (oldHealth / oldMaxHealth) or 1
						local newHealth = math.max(newMaxHealth * healthPercentage, newMaxHealth * 0.5)
						humanoid.Health = newHealth
					end
				else
					-- If MaxHealth is being set to 0 temporarily (during reset), don't change health
					-- Health will be set when MaxHealth is set to the final value
				end
			end
		end
	end)

	-- kapag level up, dagdagan at i-store
	-- Connect this OUTSIDE CharacterAdded so it works even before character spawns
	level.Changed:Connect(function()
		local newLevel = level.Value

		-- Prevent level changes while class is Slavkorian
		if class.Value == "Slavkorian" then
			if newLevel ~= BaseStats.XP.startLevel then
				level.Value = BaseStats.XP.startLevel
				return
			end
			maxxp.Value = calculateMaximumXP(BaseStats.XP.startLevel)
			previousLevel = BaseStats.XP.startLevel
			return
		end
		
		-- Recalculate MaximumXP when level changes (always, for resets too)
		local newMaxXP = calculateMaximumXP(newLevel)
		maxxp.Value = newMaxXP
		
		-- DISABLE LEVELING WHEN CLASS IS SLAVKORIAN
		if class.Value == "Slavkorian" then
			-- Don't apply multipliers when class is Slavkorian
			return
		end
		
		-- Only apply multipliers if stats are initialized AND level actually increased (not decreased/reset)
		-- This prevents applying multipliers during initial load or reset
		if not statsInitialized then
			-- Stats not initialized yet, skipping multiplier application
		elseif newLevel <= previousLevel then
			-- Level did not increase, skipping multipliers
		else
			local multipliers = BaseStats.LevelUpMultipliers[class.Value]
			
			if not multipliers then
				-- No multipliers found for class
			elseif newLevel > BaseStats.XP.maxLevel then
				-- Level exceeds max level, skipping multipliers
			else
				-- Apply level-up multipliers for all stats
				local hpMultiplier = resolveLevelUpMultiplier(multipliers, "HP", newLevel)
				if hpMultiplier and leaderstats:FindFirstChild("MaxHealth") then
					leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * hpMultiplier)
				end

				-- For MaxAttack, use round to ensure it always increases (especially important for classes with small multipliers like Gladiator)
				-- Gladiator: 30 * 1.03 = 30.9, floor = 30 (no increase!), round = 31 (increases!)
				local atkMultiplier = resolveLevelUpMultiplier(multipliers, "ATK", newLevel)
				if atkMultiplier and leaderstats:FindFirstChild("MaxAttack") then
					local oldATK = leaderstats.MaxAttack.Value
					local newATK = oldATK * atkMultiplier
					-- Use round to ensure it always increases (math.floor(x + 0.5))
					local roundedATK = math.floor(newATK + 0.5)
					-- Ensure it increases by at least 1 (prevents stats from staying the same due to rounding)
					leaderstats.MaxAttack.Value = math.max(roundedATK, oldATK + 1)
				end

				local defMultiplier = resolveLevelUpMultiplier(multipliers, "D", newLevel)
				if defMultiplier and leaderstats:FindFirstChild("MaxDefense") then
					leaderstats.MaxDefense.Value = math.floor(leaderstats.MaxDefense.Value * defMultiplier)
				end

				-- Apply offense stat multipliers
				-- Defense Penetration: Use round to ensure it increases (important when starting at 0)
				local dpMultiplier = resolveLevelUpMultiplier(multipliers, "DP", newLevel)
				if dpMultiplier and leaderstats:FindFirstChild("DefensePenetration") then
					local oldDP = leaderstats.DefensePenetration.Value
					local newDP = oldDP * dpMultiplier
					-- Use round to ensure it increases (math.floor(x + 0.5))
					local roundedDP = math.floor(newDP + 0.5)
					-- Ensure it increases by at least 1 if it was 0 or very small (prevents staying at 0)
					if oldDP == 0 then
						-- If starting from 0, give at least 1 point on first level up
						leaderstats.DefensePenetration.Value = 1
					else
						-- Otherwise use rounded value, but ensure it increases
						leaderstats.DefensePenetration.Value = math.max(roundedDP, oldDP + 1)
					end
				end

				-- CritRate needs math.ceil because it's a small percentage stat (starts at 5)
				-- 5 * 1.03 = 5.15, floor(5.15) = 5 (stays same), ceil(5.15) = 6 (increases!)
				local critRateMultiplier = resolveLevelUpMultiplier(multipliers, "CR", newLevel)
				if critRateMultiplier and leaderstats:FindFirstChild("CritRate") then
					local oldCR = leaderstats.CritRate.Value
					local newCritRate = oldCR * critRateMultiplier
					-- Always use ceil to ensure progression (removes floating point comparison issues)
					leaderstats.CritRate.Value = math.ceil(newCritRate)
				end

				-- CritMultiplier works fine with floor since it starts at 150 (150 * 1.01 = 151.5, floor = 151 ✓)
				-- But we use round to ensure it always increases slightly
				local critMultiplier = resolveLevelUpMultiplier(multipliers, "CM", newLevel)
				if critMultiplier and leaderstats:FindFirstChild("CritMultiplier") then
					local oldCM = leaderstats.CritMultiplier.Value
					local newCritMultiplier = oldCM * critMultiplier
					-- Use round to ensure it increases (1.01 multiplier on 150 = 151.5, round = 152)
					-- math.round might not exist, so use: math.floor(x + 0.5)
					leaderstats.CritMultiplier.Value = math.floor(newCritMultiplier + 0.5)
				end

				-- Apply defense/utility stat multipliers
				-- Health Regeneration: Use round to ensure it increases (important when starting at 0)
				local healthRegenMultiplier = resolveLevelUpMultiplier(multipliers, "HR", newLevel)
				if healthRegenMultiplier and leaderstats:FindFirstChild("HealthRegen") then
					local oldHR = leaderstats.HealthRegen.Value
					local newHR = oldHR * healthRegenMultiplier
					-- Use round to ensure it increases (math.floor(x + 0.5))
					local roundedHR = math.floor(newHR + 0.5)
					-- Ensure it increases by at least 1 if it was 0 or very small (prevents staying at 0)
					if oldHR == 0 then
						-- If starting from 0, give at least 1 point on first level up
						leaderstats.HealthRegen.Value = 1
					else
						-- Otherwise use rounded value, but ensure it increases
						leaderstats.HealthRegen.Value = math.max(roundedHR, oldHR + 1)
					end
				end

				local movementMultiplier = resolveLevelUpMultiplier(multipliers, "Mspd", newLevel)
				if movementMultiplier and leaderstats:FindFirstChild("MovementSpeed") then
					local oldMspd = leaderstats.MovementSpeed.Value
					-- MovementSpeed is the animation speed multiplier, scale it with Mspd multiplier
					leaderstats.MovementSpeed.Value = oldMspd * movementMultiplier

					-- Update unified movement animation speed in ServerConfigs (MovementSpeed is already the multiplier)
					local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
					end

					-- Sync animation speeds with action files for all players of this class
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("movement", movementAnimSpeedMultiplier)
					end
				end

				local attackSpeedMultiplier = resolveLevelUpMultiplier(multipliers, "Aspd", newLevel)
				if attackSpeedMultiplier and leaderstats:FindFirstChild("AttackSpeed") then
					local oldAspd = leaderstats.AttackSpeed.Value
					-- AttackSpeed is the animation speed multiplier, scale it with Aspd multiplier
					leaderstats.AttackSpeed.Value = oldAspd * attackSpeedMultiplier

					-- Update unified attack animation speed in ServerConfigs (AttackSpeed is already the multiplier)
					local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
					end

					-- Sync animation speeds with action files for all players of this class
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("attack", attackAnimSpeedMultiplier)
					end
				end

				-- update humanoid din habang buhay pa siya (if character exists)
				if plr.Character then
					local humanoid = plr.Character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.MaxHealth = leaderstats.MaxHealth.Value
						humanoid.Health = humanoid.MaxHealth
						-- Update walk speed: base Mspd (18) * MovementSpeed animation multiplier
						if leaderstats:FindFirstChild("MovementSpeed") and multipliers.Mspd then
							local baseStats = BaseStats[class.Value]
							local baseMspd = baseStats and baseStats.Mspd or 18
							humanoid.WalkSpeed = baseMspd * leaderstats.MovementSpeed.Value
						end
					end
				end
			end
		end
		
	enforceStatCaps(leaderstats)

		-- Update previous level (important for detecting resets)
		previousLevel = newLevel
	end)
	
	-- Function to apply base stats (works before character spawns)
	local function applyBaseStats()
		-- Get base stats from BaseStats based on class
		local baseStats = BaseStats[class.Value]
		
		-- If no base stats found for class, use Slavkorian defaults
		if not baseStats then
			baseStats = { HP = 1000, ATK = 100, D = 0, DP = 0, CR = 5, CM = 150, HR = 0, Mspd = 18, Aspd = 1 }
		end
		
		-- Set all base stats if not already set (Value == 0 means uninitialized)
		if leaderstats:FindFirstChild("MaxHealth").Value == 0 then
			leaderstats.MaxHealth.Value = baseStats.HP
		end
		
		if leaderstats:FindFirstChild("MaxAttack").Value == 0 then
			leaderstats.MaxAttack.Value = baseStats.ATK
		end
		
		if leaderstats:FindFirstChild("MaxDefense").Value == 0 then
			leaderstats.MaxDefense.Value = baseStats.D
		end
		
		-- Set CurrentDefense to MaxDefense if not set
		if leaderstats:FindFirstChild("CurrentDefense") and leaderstats.CurrentDefense.Value == 0 then
			leaderstats.CurrentDefense.Value = baseStats.D
		end
		
		if leaderstats:FindFirstChild("DefensePenetration").Value == 0 then
			leaderstats.DefensePenetration.Value = baseStats.DP or 0
		end
		
		if leaderstats:FindFirstChild("CritRate").Value == 0 then
			leaderstats.CritRate.Value = baseStats.CR or 5
		end
		
		if leaderstats:FindFirstChild("CritMultiplier").Value == 0 then
			leaderstats.CritMultiplier.Value = baseStats.CM or 150
		end
		
		if leaderstats:FindFirstChild("HealthRegen").Value == 0 then
			leaderstats.HealthRegen.Value = baseStats.HR or 0
		end
		
		local movementMultiplier, attackMultiplier = updateRuntimeSpeedsFromBaseStats(class.Value, baseStats)

		if leaderstats:FindFirstChild("MovementSpeed").Value == 0 then
			leaderstats.MovementSpeed.Value = movementMultiplier or 1.0
		end
		
		if leaderstats:FindFirstChild("AttackSpeed").Value == 0 then
			leaderstats.AttackSpeed.Value = attackMultiplier or 1.0
		end
	
	-- Initialize animation speeds in ServerConfigs based on MovementSpeed and AttackSpeed (animation multipliers)
	if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
		local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
		local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
		ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
		ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
	end
	if ServerConfigs and ServerConfigs[class.Value] then
		local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
		local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
		ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
		ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
	end

	enforceStatCaps(leaderstats)
	end
	
	-- Apply base stats when class changes (works immediately, even before character spawns)
	class.Changed:Connect(function()
		-- Reset all stats to 0 so base stats get applied
		leaderstats.MaxHealth.Value = 0
		leaderstats.MaxAttack.Value = 0
		leaderstats.MaxDefense.Value = 0
		leaderstats.CurrentDefense.Value = 0
		leaderstats.DefensePenetration.Value = 0
		leaderstats.CritRate.Value = 0
		leaderstats.CritMultiplier.Value = 0
		leaderstats.HealthRegen.Value = 0
		leaderstats.MovementSpeed.Value = 0
		leaderstats.AttackSpeed.Value = 0
		-- Apply base stats immediately
		applyBaseStats()
		-- Mark stats as initialized when class is set (allows leveling before character spawns)
		if class.Value and class.Value ~= "Slavkorian" then
			statsInitialized = true
		else
			statsInitialized = false
		end

		if class.Value == "Slavkorian" then
			level.Value = BaseStats.XP.startLevel
			maxxp.Value = calculateMaximumXP(BaseStats.XP.startLevel)
			if currxp.Value > maxxp.Value then
				currxp.Value = maxxp.Value
			end
			previousLevel = BaseStats.XP.startLevel
		end

		enforceStatCaps(leaderstats)
	end)
	
	-- Apply base stats on initial load (if no saved data or if class was selected)
	if not data or (data and class.Value ~= "Slavkorian") then
		applyBaseStats()
		-- Mark stats as initialized if class is already set
		if class.Value and class.Value ~= "Slavkorian" then
			statsInitialized = true
		end
	end

	-- Health regeneration system
	local healthRegenConnections = {}
	
	-- Defense regeneration system
	local defenseRegenConnections = {}
	
	-- Function to start health regeneration for a character
	local function startHealthRegen(character, humanoid)
		-- Clean up any existing thread for this character
		if healthRegenConnections[character] then
			-- Cancel the existing thread
			task.cancel(healthRegenConnections[character])
			healthRegenConnections[character] = nil
		end
		
		-- Get HealthRegen stat
		local healthRegenStat = leaderstats:FindFirstChild("HealthRegen")
		if not healthRegenStat or healthRegenStat.Value <= 0 then
			return -- No health regen, don't start system
		end
		
		-- Run health regeneration every second
		local regenThread = task.spawn(function()
			while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
				-- Check if character and humanoid still exist before waiting
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				task.wait(1) -- Wait 1 second
				
				-- Check again after wait (character might have been removed)
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				-- Get current HealthRegen value
				local currentHealthRegen = healthRegenStat.Value
				if currentHealthRegen > 0 then
					-- Regenerate health (cap at MaxHealth)
					local newHealth = math.min(humanoid.Health + currentHealthRegen, humanoid.MaxHealth)
					humanoid.Health = newHealth
				else
					-- If HealthRegen becomes 0, stop regenerating
					break
				end
			end
			
			-- Clean up when done
			healthRegenConnections[character] = nil
		end)
		
		healthRegenConnections[character] = regenThread
	end
	
	-- Function to start defense regeneration for a character
	local function startDefenseRegen(character, humanoid)
		-- Clean up any existing thread for this character
		if defenseRegenConnections[character] then
			task.cancel(defenseRegenConnections[character])
			defenseRegenConnections[character] = nil
		end
		
		-- Get defense regen config
		local defenseRegenConfig = ServerConfigs.DefenseRegen
		if not defenseRegenConfig or not defenseRegenConfig.enabled then
			return
		end
		
		-- Run defense regeneration every tick interval
		local regenThread = task.spawn(function()
			while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
				-- Check if character and humanoid still exist before waiting
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				task.wait(defenseRegenConfig.tickInterval) -- Wait for tick interval
				
				-- Check again after wait
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				-- Defense only regenerates when health is full
				if humanoid.Health >= humanoid.MaxHealth then
					local currentDef = leaderstats.CurrentDefense.Value
					local maxDef = leaderstats.MaxDefense.Value
					
					-- Only regen if defense is not at max
					if currentDef < maxDef then
						local newDef = math.min(currentDef + defenseRegenConfig.regenRate, maxDef)
						leaderstats.CurrentDefense.Value = newDef
					end
				end
			end
			
			-- Clean up when done
			defenseRegenConnections[character] = nil
		end)
		
		defenseRegenConnections[character] = regenThread
	end
	
	-- Sa spawn
	plr.CharacterAdded:Connect(function(char)
		-- Clean up Bushido states when character is removed/respawned
		if playerBushidoStates and playerBushidoStates[plr] then
			local state = playerBushidoStates[plr]
			if state.healthConnection then
				state.healthConnection:Disconnect()
			end
			if state.heartbeatConnection then
				state.heartbeatConnection:Disconnect()
			end
			playerBushidoStates[plr] = nil
		end
		
		local humanoid = char:WaitForChild("Humanoid")

		-- Reset equipment bonuses so we can recalculate with newly equipped tools
		clearEquipmentBonuses(plr)

		-- Apply base stats if not already set
		applyBaseStats()

		-- Apply stored MaxHealth to humanoid
		humanoid.MaxHealth = leaderstats.MaxHealth.Value
		humanoid.Health = humanoid.MaxHealth
		
		-- Reset CurrentDefense to MaxDefense on respawn
		local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		if currentDefense and maxDefense then
			currentDefense.Value = maxDefense.Value
		elseif maxDefense then
			-- Create CurrentDefense if it doesn't exist
			local newCurrentDefense = Instance.new("NumberValue", leaderstats)
			newCurrentDefense.Name = "CurrentDefense"
			newCurrentDefense.Value = maxDefense.Value
		end
		
		-- Apply Movement Speed: base Mspd (18) * MovementSpeed animation multiplier
		if leaderstats:FindFirstChild("MovementSpeed") then
			local baseStats = BaseStats[class.Value]
			local baseMspd = baseStats and baseStats.Mspd or 18
			humanoid.WalkSpeed = baseMspd * leaderstats.MovementSpeed.Value
		end
		
		-- Start health regeneration system
		startHealthRegen(char, humanoid)
		
		-- Start defense regeneration system
		startDefenseRegen(char, humanoid)
		
		-- Initialize animation speeds based on MovementSpeed and AttackSpeed (animation multipliers)
		if class.Value and class.Value ~= "Slavkorian" then
			local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
			local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
			if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
				ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
				ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
			end
			if ServerConfigs and ServerConfigs[class.Value] then
				ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
				ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
			end
			
			-- Sync animation speeds with action files
			local classFuncs = {
				Archer = _G.updateArcherAnimationSpeed,
				Samurai = _G.updateSamuraiAnimationSpeed,
				Brawler = _G.updateBrawlerAnimationSpeed,
				Knight = _G.updateKnightAnimationSpeed,
				Gladiator = _G.updateGladiatorAnimationSpeed
			}
			local updateFunc = classFuncs[class.Value]
			if updateFunc then
				updateFunc("movement", movementAnimSpeedMultiplier)
				updateFunc("attack", attackAnimSpeedMultiplier)
			end
		end
		
		-- Update animation speeds when MovementSpeed or AttackSpeed change
		local movementSpeedStat = leaderstats:FindFirstChild("MovementSpeed")
		if movementSpeedStat then
			movementSpeedStat.Changed:Connect(function()
				if class.Value and class.Value ~= "Slavkorian" then
					local movementAnimSpeedMultiplier = movementSpeedStat.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
					end
					-- Update humanoid walk speed when MovementSpeed changes
					if humanoid then
						local baseStats = BaseStats[class.Value]
						local baseMspd = baseStats and baseStats.Mspd or 18
						humanoid.WalkSpeed = baseMspd * movementAnimSpeedMultiplier
					end
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("movement", movementAnimSpeedMultiplier)
					end
				end
			end)
		end
		
		local attackSpeedStat = leaderstats:FindFirstChild("AttackSpeed")
		if attackSpeedStat then
			attackSpeedStat.Changed:Connect(function()
				if class.Value and class.Value ~= "Slavkorian" then
					local attackAnimSpeedMultiplier = attackSpeedStat.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
					end
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("attack", attackAnimSpeedMultiplier)
					end
				end
			end)
		end
		
		-- Update health regen when the stat changes
		local healthRegenStat = leaderstats:FindFirstChild("HealthRegen")
		if healthRegenStat then
			healthRegenStat.Changed:Connect(function()
				-- Restart health regen system with new value
				if char.Parent and humanoid.Parent then
					startHealthRegen(char, humanoid)
				end
			end)
		end
		
		-- Update MaxHealth in real-time when it changes (so resets work immediately)
		local maxHealthStat = leaderstats:FindFirstChild("MaxHealth")
		if maxHealthStat then
			maxHealthStat.Changed:Connect(function(newMaxHealth)
				-- Update humanoid MaxHealth in real-time
				if char.Parent and humanoid.Parent then
					-- Store old MaxHealth and old health before changing it
					local oldMaxHealth = humanoid.MaxHealth
					local oldHealth = humanoid.Health
					
					-- Update MaxHealth first
					humanoid.MaxHealth = newMaxHealth
					
					-- Set health based on new MaxHealth
					if newMaxHealth > 0 then
						-- If MaxHealth is increasing or resetting (old was 0 or new >= old), set to full health
						-- If MaxHealth is decreasing, preserve health percentage (but ensure minimum 50%)
						if newMaxHealth >= oldMaxHealth or oldMaxHealth == 0 then
							-- Set to full health when resetting or increasing MaxHealth
							humanoid.Health = newMaxHealth
						else
							-- Preserve health percentage when MaxHealth decreases (but ensure it's not too low)
							local healthPercentage = oldMaxHealth > 0 and (oldHealth / oldMaxHealth) or 1
							local newHealth = math.max(newMaxHealth * healthPercentage, newMaxHealth * 0.5)
							humanoid.Health = newHealth
						end
					else
						-- If MaxHealth is being set to 0 temporarily (during reset), don't change health
						-- Health will be set when MaxHealth is set to the final value
					end
				end
			end)
		end
		
		-- Ensure equipment bonuses are applied for the current character state
		refreshEquipmentBonuses(plr)
		
		-- Mark stats as initialized after first spawn
		statsInitialized = true
		
		-- Also initialize stats immediately when class is set (before character spawns)
		-- This allows leveling up to work even before character spawns
		if class.Value and class.Value ~= "Slavkorian" then
			statsInitialized = true
		end
	end)
	
	-- Clean up health and defense regen when player leaves
	plr.CharacterRemoving:Connect(function(char)
		if healthRegenConnections[char] then
			healthRegenConnections[char] = nil
		end
		if defenseRegenConnections[char] then
			defenseRegenConnections[char] = nil
		end
	end)
	
end)

-- Function to save player data
local function savePlayerData(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats or not MainDataStore then
		return
	end
	
	-- Ensure MaximumXP is correct before saving
	local currentLevel = leaderstats.Level.Value
	leaderstats.MaximumXP.Value = calculateMaximumXP(currentLevel)
	
	-- LEVEL CAP: Clamp level before saving
	leaderstats.Level.Value = math.min(leaderstats.Level.Value, BaseStats.XP.maxLevel)

	-- Helper function to safely get a stat value
	local equipmentBonuses = playerEquipmentBonuses[plr]
	local consumableTemporaryBonuses = playerConsumableTemporaryTotals and playerConsumableTemporaryTotals[plr]

	local function getStatValue(statName, defaultValue, options)
		local stat = leaderstats:FindFirstChild(statName)
		if typeof(defaultValue) == "boolean" then
			return stat and stat.Value == true
		end

		if stat and stat:IsA("ValueBase") then
			local value = tonumber(stat.Value) or defaultValue
			local sourceStatName = (options and options.source) or statName

			if equipmentBonuses and equipmentBonuses[sourceStatName] then
				value = value - equipmentBonuses[sourceStatName]
			end

			if consumableTemporaryBonuses and consumableTemporaryBonuses[sourceStatName] then
				value = value - consumableTemporaryBonuses[sourceStatName]
			end

			return math.max(value, 0)
		end
		return defaultValue
	end
	
	local dataToSave = {
		Level = getStatValue("Level", 1),
		CurrentXP = getStatValue("CurrentXP", 0),
		MaximumXP = getStatValue("MaximumXP", BaseStats.XP.startMaxXP),
		Class = tostring(leaderstats.Class.Value) or "Slavkorian",
		MaxAttack = getStatValue("MaxAttack", 0),
		DefensePenetration = getStatValue("DefensePenetration", 0),
		CritRate = getStatValue("CritRate", 0),
		CritMultiplier = getStatValue("CritMultiplier", 0),
		MaxDefense = getStatValue("MaxDefense", 0),
		CurrentDefense = getStatValue("CurrentDefense", getStatValue("MaxDefense", 0), {source = "MaxDefense"}), -- Default to MaxDefense if not saved
		MaxHealth = getStatValue("MaxHealth", 0),
		HealthRegen = getStatValue("HealthRegen", 0),
		MovementSpeed = getStatValue("MovementSpeed", 0),
		AttackSpeed = getStatValue("AttackSpeed", 0),
		Slavkoins = getStatValue("Slavkoins", 0),
		CurrentWaterLevel = getStatValue("CurrentWaterLevel", 0),
		MaxWaterLevel = getStatValue("MaxWaterLevel", 0),
		WaterBasinOne = getStatValue("WaterBasinOne", false),
		WaterBasinTwo = getStatValue("WaterBasinTwo", false),
		WaterBasinThree = getStatValue("WaterBasinThree", false),
		WaterBasinFour = getStatValue("WaterBasinFour", false),
		WaterBasinFifth = getStatValue("WaterBasinFifth", false)
	}

	local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
	if not success then
		-- Failed to save data
	end
end

-- Save data periodically (every 60 seconds) and on player removal
game.Players.PlayerRemoving:Connect(function(plr)
	savePlayerData(plr)
end)

-- Periodic save (every 60 seconds)
spawn(function()
	while true do
		wait(60)
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr:FindFirstChild("leaderstats") then
				savePlayerData(plr)
			end
		end
	end
end)

-- Handle dev stat changes from client
DevStatEvent.OnServerEvent:Connect(function(plr, action, value)
	-- Only allow dev stat changes from the client (security: could add admin check here)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	
	if action == "setCurrentXP" then
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = tonumber(value) or 0
		end
	elseif action == "addCurrentXP" then
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = leaderstats.CurrentXP.Value + (tonumber(value) or 0)
		end
	elseif action == "setLevel" then
		if leaderstats:FindFirstChild("Level") then
			if leaderstats:FindFirstChild("Class") and leaderstats.Class.Value == "Slavkorian" then
				leaderstats.Level.Value = BaseStats.XP.startLevel
				if leaderstats:FindFirstChild("MaximumXP") then
					leaderstats.MaximumXP.Value = calculateMaximumXP(BaseStats.XP.startLevel)
				end
				return
			end
			local newLevel = tonumber(value) or 1
			-- LEVEL CAP: Clamp level to max level
			leaderstats.Level.Value = math.min(math.max(newLevel, 1), BaseStats.XP.maxLevel)
			-- Recalculate MaximumXP for the new level
			if leaderstats:FindFirstChild("MaximumXP") then
				leaderstats.MaximumXP.Value = calculateMaximumXP(leaderstats.Level.Value)
			end
		end
	elseif action == "setClass" then
		if leaderstats:FindFirstChild("Class") then
			local newClass = tostring(value) or "Slavkorian"
			
			-- Reset level to 1
			if leaderstats:FindFirstChild("Level") then
				leaderstats.Level.Value = 1
			end
			
			-- Reset XP to 0
			if leaderstats:FindFirstChild("CurrentXP") then
				leaderstats.CurrentXP.Value = 0
			end
			
			-- Recalculate MaximumXP for level 1
			if leaderstats:FindFirstChild("MaximumXP") then
				leaderstats.MaximumXP.Value = calculateMaximumXP(1)
			end
			
		-- Reset all stats to 0 first
		local statsToReset = {"MaxAttack", "MaxDefense", "CurrentDefense", "MaxHealth", "DefensePenetration", 
			"CritRate", "CritMultiplier", "HealthRegen", "MovementSpeed", "AttackSpeed"}
			
			for _, statName in ipairs(statsToReset) do
				if leaderstats:FindFirstChild(statName) then
					leaderstats[statName].Value = 0
				end
			end
			
			-- Set class (this will trigger class.Changed event which applies base stats)
			leaderstats.Class.Value = newClass
			
			-- Apply base stats immediately (don't wait for class.Changed event)
			local baseStats = BaseStats[newClass]
			if baseStats then
				local movementMultiplier, attackMultiplier = updateRuntimeSpeedsFromBaseStats(newClass, baseStats)
				leaderstats.MaxHealth.Value = baseStats.HP or 0
				leaderstats.MaxAttack.Value = baseStats.ATK or 0
				leaderstats.MaxDefense.Value = baseStats.D or 0
				leaderstats.CurrentDefense.Value = baseStats.D or 0
				leaderstats.DefensePenetration.Value = baseStats.DP or 0
				leaderstats.CritRate.Value = baseStats.CR or 5
				leaderstats.CritMultiplier.Value = baseStats.CM or 150
				leaderstats.HealthRegen.Value = baseStats.HR or 0
				leaderstats.MovementSpeed.Value = movementMultiplier or leaderstats.MovementSpeed.Value
				leaderstats.AttackSpeed.Value = attackMultiplier or leaderstats.AttackSpeed.Value
			else
				-- Default Slavkorian stats if class not found
				leaderstats.MaxHealth.Value = 1000
				leaderstats.MaxAttack.Value = 100
				leaderstats.MaxDefense.Value = 0
				leaderstats.CurrentDefense.Value = 0
				leaderstats.DefensePenetration.Value = 0
				leaderstats.CritRate.Value = 5
				leaderstats.CritMultiplier.Value = 150
				leaderstats.HealthRegen.Value = 0
				leaderstats.MovementSpeed.Value = 1.0
				leaderstats.AttackSpeed.Value = 1.0
			end
		end
	elseif action == "resetStat" then
		local statName = tostring(value)
		if leaderstats:FindFirstChild(statName) then
			leaderstats[statName].Value = 0
		end
	elseif action == "fullReset" then
		-- Full reset: Level 1, XP 0, MaximumXP recalculated, Class Slavkorian, all stats reset
		
		-- Reset level first (this will recalculate MaximumXP)
		if leaderstats:FindFirstChild("Level") then
			leaderstats.Level.Value = 1
		end
		
		-- Reset XP
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = 0
		end
		
		-- Recalculate MaximumXP for level 1
		if leaderstats:FindFirstChild("MaximumXP") then
			leaderstats.MaximumXP.Value = calculateMaximumXP(1)
		end
		
		-- Reset class (this will trigger base stats application)
		if leaderstats:FindFirstChild("Class") then
			leaderstats.Class.Value = "Slavkorian"
		end
		
		-- Reset all stats to 0 (base stats will be applied via class.Changed event)
		local statsToReset = {"MaxAttack", "MaxDefense", "CurrentDefense", "MaxHealth", "DefensePenetration", 
			"CritRate", "CritMultiplier", "HealthRegen", "MovementSpeed", "AttackSpeed"}
		
		for _, statName in ipairs(statsToReset) do
			if leaderstats:FindFirstChild(statName) then
				leaderstats[statName].Value = 0
			end
		end
	end

	enforceStatCaps(leaderstats)
end)
