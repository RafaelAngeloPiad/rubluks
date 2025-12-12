-- ========================================
-- STATUS DISPLAY
-- Visualizes active buffs, equipment bonuses, and consumable bonuses
-- Tag: status_display_label
-- Uses RichText for detailed styling
-- ========================================

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local TAG_NAME = "status_display_label"
local player = Players.LocalPlayer

-- Colors (Hex for RichText)
local COLOR_HEADER = "#FFFFFF"    -- White for Headers
local COLOR_BUFF = "#64FF64"      -- rgb(100, 255, 100)
local COLOR_PASSIVE_ACTIVE = "#FF6464" -- Red-ish for triggered passives
local COLOR_PASSIVE_UNLOCKED = "#96C8FF" -- Blue-ish for static/unlocked passives
local COLOR_EQUIPMENT = "#B4FFB4" -- rgb(180, 255, 180)
local COLOR_CONSUMABLE = "#FFDC96"-- rgb(255, 220, 150)
local COLOR_AILMENT = "#FF6464"   -- rgb(255, 100, 100)
local COLOR_TIMER = "#96C8FF"     -- rgb(150, 200, 255)

-- Config Loading
local EquipmentBonusConfig = nil
local EquipmentBonusEntries = {}
local EquipmentBonusAssetLookup = {}
local EquipmentBonusCanonicalLookup = {}

local HelmetConfigModule = ReplicatedStorage:FindFirstChild("HelmetConfig")
local HelmetEntries = {}

local ConfigModule = nil -- SlavkosConfigs

-- Helper to safely require modules
local function safeRequire(module)
	if module then
		local success, result = pcall(require, module)
		if success then return result end
	end
	return nil
end

-- Load Configs
local function loadConfigs()
	-- Equipment Config
	local equipModule = ReplicatedStorage:FindFirstChild("EquipmentBonusConfig") 
		or ReplicatedStorage:WaitForChild("EquipmentBonusConfig", 5)
	
	if equipModule then
		EquipmentBonusConfig = safeRequire(equipModule)
		if EquipmentBonusConfig then
			EquipmentBonusEntries = EquipmentBonusConfig.Entries or {}
			EquipmentBonusAssetLookup = EquipmentBonusConfig.AssetLookup or {}
			EquipmentBonusCanonicalLookup = EquipmentBonusConfig.CanonicalLookup or {}
		end
	end
	
	-- Helmet Config
	if HelmetConfigModule then
		local cfg = safeRequire(HelmetConfigModule)
		if cfg and cfg.Entries then
			HelmetEntries = cfg.Entries
		end
	end
	
	-- Main Config (SlavkosConfigs)
	local serverConfigs = ReplicatedStorage:FindFirstChild("SlavkosConfigs") 
		or ReplicatedStorage:WaitForChild("SlavkosConfigs", 5)
	if serverConfigs then
		ConfigModule = safeRequire(serverConfigs)
	end
end
task.spawn(loadConfigs)

-- Helmet tracking
local currentHelmet = nil
local HelmetEvent = ReplicatedStorage:FindFirstChild("HelmetEvent")
if HelmetEvent then
	HelmetEvent.OnClientEvent:Connect(function(action, payload)
		if action == "updateHelmet" then
			currentHelmet = payload
		end
	end)
end

local RELEVANT_STATS = {
	"MaxHealth", "MaxAttack", "MaxDefense", 
	"DefensePenetration", "CritRate", "CritMultiplier"
}

local STAT_LABELS = {
	MaxHealth = "HP",
	MaxAttack = "ATK",
	MaxDefense = "DEF",
	DefensePenetration = "DEF PEN",
	CritRate = "CRIT Rate",
	CritMultiplier = "CRIT Dmg"
}

local function formatBonus(amount)
	if math.abs(amount - math.floor(amount)) < 1e-3 then
		return string.format("%+d", amount)
	end
	return string.format("%+.1f", amount)
end

local function formatDuration(seconds)
	if not seconds then return "" end
	local remaining = math.max(0, math.floor(seconds + 0.5))
	local minutes = math.floor(remaining / 60)
	local secs = remaining % 60
	if minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	end
	return string.format("%ds", secs)
end

local function getLeaderstats()
	return player:FindFirstChild("leaderstats")
end

-- ========================================
-- GENERATOR
-- ========================================

local function generateStatusText()
	local leaderstats = getLeaderstats()
	if not leaderstats then return "Loading stats..." end

	local sections = {}
	
	-- Data needed for calculations
	local baseStats = leaderstats:FindFirstChild("BaseStats")
	local currentStats = {
		MaxHealth = leaderstats:FindFirstChild("MaxHealth") and leaderstats.MaxHealth.Value or 0,
		MaxAttack = leaderstats:FindFirstChild("MaxAttack") and leaderstats.MaxAttack.Value or 0,
		MaxDefense = leaderstats:FindFirstChild("MaxDefense") and leaderstats.MaxDefense.Value or 0,
	}
	local baseValues = {
		MaxHealth = baseStats and baseStats:FindFirstChild("BaseMaxHealth") and baseStats.BaseMaxHealth.Value or currentStats.MaxHealth,
		MaxAttack = baseStats and baseStats:FindFirstChild("BaseMaxAttack") and baseStats.BaseMaxAttack.Value or currentStats.MaxAttack,
		MaxDefense = baseStats and baseStats:FindFirstChild("BaseMaxDefense") and baseStats.BaseMaxDefense.Value or currentStats.MaxDefense,
	}
	
	local level = leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or 1
	local className = leaderstats:FindFirstChild("Class") and leaderstats.Class.Value or ""

	-- === CONSUMABLES ===
	local consumableLines = {}
	local activeConsumables = leaderstats:FindFirstChild("ActiveConsumables")
	if activeConsumables then
		local now = tick()
		for _, val in ipairs(activeConsumables:GetChildren()) do
			if val:IsA("StringValue") then
				local success, data = pcall(function() return HttpService:JSONDecode(val.Value) end)
				if success and data then
					local name = data.displayName or data.name or val.Name
					local timer = data.endTime and formatDuration(data.endTime - now) or "Perm"
					
					local stats = {}
					if data.bonuses then
						for k, v in pairs(data.bonuses) do
							table.insert(stats, string.format("%s %s", STAT_LABELS[k] or k, formatBonus(v)))
						end
					end
					
					local line = string.format("<font color='%s'>%s</font>", COLOR_CONSUMABLE, name)
					if #stats > 0 then
						-- Smaller font for details
						line = line .. "\n<font color='#CCCCCC'>" .. table.concat(stats, ", ") .. "</font>"
					end
					-- Timer on new line
					line = line .. string.format("\n<font color='%s'>Timer: %s</font>", COLOR_TIMER, timer)
					table.insert(consumableLines, line)
				end
			end
		end
	end
	
	if #consumableLines > 0 then
		table.insert(sections, string.format("<b><font color='%s'>CONSUMABLE BONUS</font></b>", COLOR_HEADER))
		for _, l in ipairs(consumableLines) do table.insert(sections, l) end
		table.insert(sections, "") -- Spacer
	end

	-- === EQUIPMENT ===
	local equipmentLines = {}
	
	-- Ailments (Weapon/Accessory)
	if player.Character and EquipmentBonusEntries then
		for _, child in ipairs(player.Character:GetChildren()) do
			if child:IsA("Tool") or child:IsA("Accessory") then
				local entry = EquipmentBonusAssetLookup[child.Name]
				if not entry then
					local cName = EquipmentBonusCanonicalLookup[child.Name] or child:GetAttribute("canonicalName")
					if cName then entry = EquipmentBonusEntries[cName] end
				end
				
				if entry and entry.statusAilment then
					local a = entry.statusAilment
					local parts = {}
					if a.type then table.insert(parts, a.type:gsub("^%l", string.upper)) end
					if a.chance and a.chance < 100 then table.insert(parts, a.chance .. "% Chance") end
					if a.duration then table.insert(parts, string.format("%.1fs", a.duration)) end
					if a.dps and a.dps > 0 then table.insert(parts, a.dps .. " DPS") end
					if a.slowMultiplier then table.insert(parts, math.floor((1 - a.slowMultiplier)*100) .. "% Slow") end
					
					table.insert(equipmentLines, string.format("<font color='%s'>%s Effect:</font> %s", COLOR_AILMENT, child.Name, table.concat(parts, ", ")))
				end
			end
		end
	end
	
	-- Helmet Ailment
	if currentHelmet and currentHelmet.canonicalName and HelmetEntries[currentHelmet.canonicalName] then
		local entry = HelmetEntries[currentHelmet.canonicalName]
		if entry.statusAilment then
			local a = entry.statusAilment
			local parts = {}
			if a.type then table.insert(parts, a.type:gsub("^%l", string.upper)) end
			table.insert(equipmentLines, string.format("<font color='%s'>Helmet Effect:</font> %s", COLOR_AILMENT, table.concat(parts, ", ")))
		end
	end

	-- Stats (EquipmentBonuses)
	local equipmentBonuses = leaderstats:FindFirstChild("EquipmentBonuses")
	if equipmentBonuses then
		local stats = {}
		for _, statName in ipairs(RELEVANT_STATS) do
			local valObj = equipmentBonuses:FindFirstChild(statName)
			if valObj and math.abs(valObj.Value) > 0 then
				local label = STAT_LABELS[statName] or statName
				table.insert(stats, string.format("%s %s", label, formatBonus(valObj.Value)))
			end
		end
		if #stats > 0 then
			table.insert(equipmentLines, string.format("<font color='%s'>Stats:</font>\n<font color='#CCCCCC'>%s</font>", COLOR_EQUIPMENT, table.concat(stats, "\n")))
		end
	end
	
	if #equipmentLines > 0 then
		table.insert(sections, string.format("<b><font color='%s'>EQUIPMENT BONUS</font></b>", COLOR_HEADER))
		for _, l in ipairs(equipmentLines) do table.insert(sections, l) end
		table.insert(sections, "")
	end

	-- === BUFFS & PASSIVES ===
	local buffLines = {}
	
	-- 1. Active Buffs
	local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
	if activeBuffs and activeBuffs.Value ~= "" then
		for buffName in string.gmatch(activeBuffs.Value, "([^,]+)") do
			buffName = buffName:match("^%s*(.-)%s*$")
			if buffName ~= "" then
				local buffDetails = ""
				local timerText = ""
				
				local buffDurations = leaderstats:FindFirstChild("BuffDurations")
				if buffDurations then
					local bd = buffDurations:FindFirstChild(buffName)
					if bd then timerText = formatDuration(bd.Value) end
				end
				
				if ConfigModule then
					if buffName == "Warcry" and ConfigModule.KnightBuffs then
						local cfg = ConfigModule.getBuffConfig("Warcry", level)
						if cfg then
							local atkAdd = math.floor(baseValues.MaxAttack * cfg.attackMultiplier) - baseValues.MaxAttack
							local defAdd = math.floor(baseValues.MaxDefense * cfg.defenseMultiplier) - baseValues.MaxDefense
							if not baseStats then 
								local estimatedBaseATK = math.floor(currentStats.MaxAttack / cfg.attackMultiplier)
								local estimatedBaseDEF = math.floor(currentStats.MaxDefense / cfg.defenseMultiplier)
								atkAdd = currentStats.MaxAttack - estimatedBaseATK
								defAdd = currentStats.MaxDefense - estimatedBaseDEF
							end
							local parts = {}
							if atkAdd > 0 then table.insert(parts, string.format("+%.0f ATK", atkAdd)) end
							if defAdd > 0 then table.insert(parts, string.format("+%.0f DEF", defAdd)) end
							buffDetails = table.concat(parts, ", ")
						end
					elseif buffName == "WarriorMight" and ConfigModule.KnightBuffs then
						local cfg = ConfigModule.getBuffConfig("WarriorMight", level)
						if cfg then buffDetails = string.format("+%.0f HP", cfg.hpIncrease) end
					elseif buffName == "BloodThirst" and ConfigModule.BrawlerBuffs then
						local cfg = ConfigModule.getBuffConfig("BloodThirst", level)
						if cfg then buffDetails = string.format("%d%% Lifesteal", math.floor(cfg.lifestealPercentage * 100)) end
					elseif buffName == "LastChance" and ConfigModule.BrawlerBuffs then
						local cfg = ConfigModule.getBuffConfig("LastChance", level)
						if cfg then buffDetails = string.format("%d%% HP/s, %ds Immunity", math.floor((cfg.hpRegenPercentage or 0)*100), cfg.immunityDuration or 0) end
					elseif buffName == "ChampionsCheer" and ConfigModule.GladiatorBuffs then
						local cfg = ConfigModule.getBuffConfig("ChampionsCheer", level)
						if cfg then
							local hpAdd = math.floor(baseValues.MaxHealth * cfg.hpMultiplier)
							local defAdd = math.floor(baseValues.MaxDefense * cfg.defenseMultiplier)
							local regen = math.floor((cfg.hpRegenPercentage or 0) * 100)
							local parts = {}
							if hpAdd > 0 then table.insert(parts, string.format("+%.0f HP", hpAdd)) end
							if defAdd > 0 then table.insert(parts, string.format("+%.0f DEF", defAdd)) end
							if regen > 0 then table.insert(parts, string.format("%d%% HP/s", regen)) end
							buffDetails = table.concat(parts, ", ")
						end
					elseif buffName == "ChampionsBlood" and ConfigModule.GladiatorBuffs then
						local cfg = ConfigModule.getBuffConfig("ChampionsBlood", level)
						if cfg then buffDetails = string.format("+%.0f DEF, %ds Immunity", cfg.defenseIncrease, cfg.immunityDuration or 0) end
					elseif buffName == "HuntersInstinct" and ConfigModule.ArcherBuffs then
						local cfg = ConfigModule.getBuffConfig("HuntersInstinct", level)
						if cfg then
							local mspd = math.floor((cfg.mspdMultiplier or 0) * 100)
							local immune = cfg.immunityDuration or 0
							if mspd > 0 and immune > 0 then buffDetails = string.format("%d%% Mspd, %ds Immunity", mspd, immune)
							elseif mspd > 0 then buffDetails = string.format("%d%% Mspd", mspd)
							elseif immune > 0 then buffDetails = string.format("%ds Immunity", immune) end
						end
					elseif buffName == "HuntersMark" and ConfigModule.ArcherBuffs then
						local cfg = ConfigModule.getBuffConfig("HuntersMark", level)
						if cfg then
							buffDetails = string.format("+%.0f ATK, +%.1f Aspd", cfg.attackIncrease or 0, cfg.attackSpeedIncrease or 0)
						end
					elseif buffName == "Banzai" then
						buffDetails = "Immune to Damage"
					elseif buffName == "Bushido" then
						buffDetails = "HP Cannot Hit 0"
					end
				end
				
				local line = string.format("<font color='%s'>%s</font>", COLOR_BUFF, buffName)
				if buffDetails ~= "" then
					line = line .. "\n<font color='#CCCCCC'>" .. buffDetails .. "</font>"
				end
				if timerText ~= "" then
					line = line .. string.format("\n<font color='%s'>Timer: %s</font>", COLOR_TIMER, timerText)
				end
				table.insert(buffLines, line)
			end
		end
	end
	
	-- 2. Triggered Passives (ACTIVE)
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	if activePassives and activePassives.Value ~= "" then
		for passiveName in string.gmatch(activePassives.Value, "([^,]+)") do
			passiveName = passiveName:match("^%s*(.-)%s*$")
			if passiveName ~= "" then
				local details = ""
				if ConfigModule then
					-- Knight
					if passiveName == "Tenacity" and ConfigModule.KnightPassives then
						local cfg = ConfigModule.getPassiveConfig("Tenacity", level)
						if cfg then details = string.format("When HP<30%%: +%.0f DEF", cfg.defenseIncrease) end
					end
					-- Brawler
					if passiveName == "Rage" and ConfigModule.BrawlerPassives then
						local cfg = ConfigModule.getBrawlerPassiveConfig("Rage", level)
						if cfg then details = string.format("When HP<30%%: +%.0f ATK, +%.1f Aspd", cfg.attackIncrease, cfg.attackSpeedIncrease) end
					elseif passiveName == "Madness" and ConfigModule.BrawlerPassives then
						local cfg = ConfigModule.getBrawlerPassiveConfig("Madness", level)
						if cfg then details = string.format("When HP<30%%: %d%% chance to stun", cfg.stunChance) end
					end
					-- Gladiator
					if passiveName == "ChampionsRebuke" and ConfigModule.GladiatorPassives then
						local cfg = ConfigModule.getGladiatorPassiveConfig("ChampionsRebuke", level)
						if cfg then details = string.format("Combo2: %d%% chance for 2x damage", cfg.chance) end
					elseif passiveName == "OneLastChance" and ConfigModule.GladiatorPassives then
						local cfg = ConfigModule.getGladiatorPassiveConfig("OneLastChance", level)
						if cfg then details = string.format("Resurrects with %d%% HP", math.floor((cfg.resurrectHPPercentage or 0)*100)) end
					end
					-- Archer
					if passiveName == "Headshot" and ConfigModule.ArcherPassives then
						local cfg = ConfigModule.getArcherPassiveConfig("Headshot", level)
						if cfg then details = string.format("%d%% chance for 2x damage", cfg.chance) end
					elseif passiveName == "Immobilize" and ConfigModule.ArcherPassives then
						local cfg = ConfigModule.getArcherPassiveConfig("Immobilize", level)
						if cfg then details = string.format("%d%% chance to stun", cfg.stunChance) end
					end
					-- Samurai
					if passiveName == "BladeDance" and ConfigModule.SamuraiPassives then
						local cfg = ConfigModule.getSamuraiPassiveConfig("BladeDance", level)
						if cfg then details = string.format("+%d ATK on hits", cfg.attackIncrease) end
					elseif passiveName == "Burst" and ConfigModule.SamuraiPassives then
						local cfg = ConfigModule.getSamuraiPassiveConfig("Burst", level)
						if cfg then details = string.format("Combo2: Chance for 2x damage") end
					end
				end
				
				local row = string.format("<font color='%s'>%s</font>", COLOR_PASSIVE_ACTIVE, passiveName)
				if details ~= "" then row = row .. "\n<font color='#CCCCCC'>" .. details .. "</font>" end
				table.insert(buffLines, row)
			end
		end
	end
	
	-- 3. Unlocked Passives (STATIC)
	if ConfigModule and className ~= "" then
		local function getHighestUnlocked(levelsMap)
			local highest = nil
			for reqLvl, cfg in pairs(levelsMap) do
				if level >= reqLvl then
					if not highest or reqLvl > highest then highest = reqLvl end
				end
			end
			return highest and levelsMap[highest]
		end
		
		-- Helper to add unlocked row
		local function addUnlocked(name, desc)
			table.insert(buffLines, string.format("<font color='%s'>%s [Unlocked]</font>\n<font color='#999999'>%s</font>", COLOR_PASSIVE_UNLOCKED, name, desc))
		end
		
		if className == "Knight" and ConfigModule.KnightPassives then
			if ConfigModule.KnightPassives.KnightsBlade then
				local cfg = getHighestUnlocked(ConfigModule.KnightPassives.KnightsBlade.levels)
				if cfg then addUnlocked("Knight's Blade", string.format("Combo2: %d%% chance for 2x damage", cfg.chance)) end
			end
		elseif className == "Brawler" and ConfigModule.BrawlerPassives then
			if ConfigModule.BrawlerPassives.Rage then
				local cfg = getHighestUnlocked(ConfigModule.BrawlerPassives.Rage.levels)
				if cfg then addUnlocked("Rage", string.format("When HP<30%%: +%d ATK, +%.1f Aspd", cfg.attackIncrease, cfg.attackSpeedIncrease)) end
			end
			if ConfigModule.BrawlerPassives.Madness then
				local cfg = getHighestUnlocked(ConfigModule.BrawlerPassives.Madness.levels)
				if cfg then addUnlocked("Madness", string.format("When HP<30%%: %d%% chance to stun", cfg.stunChance)) end
			end
		elseif className == "Gladiator" and ConfigModule.GladiatorPassives then
			if ConfigModule.GladiatorPassives.ChampionsRebuke then
				local cfg = getHighestUnlocked(ConfigModule.GladiatorPassives.ChampionsRebuke.levels)
				if cfg then addUnlocked("Champion's Rebuke", string.format("Combo2: %d%% chance for 2x damage", cfg.chance)) end
			end
			if ConfigModule.GladiatorPassives.OneLastChance then
				local cfg = getHighestUnlocked(ConfigModule.GladiatorPassives.OneLastChance.levels)
				if cfg then addUnlocked("One Last Chance", string.format("Resurrects with %d%% HP", math.floor(cfg.resurrectHPPercentage*100))) end
			end
		elseif className == "Archer" and ConfigModule.ArcherPassives then
			if ConfigModule.ArcherPassives.Headshot then
				local cfg = getHighestUnlocked(ConfigModule.ArcherPassives.Headshot.levels)
				if cfg then addUnlocked("Headshot", string.format("%d%% chance for 2x damage", cfg.chance)) end
			end
			if ConfigModule.ArcherPassives.Immobilize then
				local cfg = getHighestUnlocked(ConfigModule.ArcherPassives.Immobilize.levels)
				if cfg then addUnlocked("Immobilize", string.format("%d%% chance to stun", cfg.stunChance)) end
			end
		elseif className == "Samurai" and ConfigModule.SamuraiPassives then
			if ConfigModule.SamuraiPassives.BladeDance then
				local cfg = getHighestUnlocked(ConfigModule.SamuraiPassives.BladeDance.levels)
				if cfg then 
					local full = ConfigModule.SamuraiPassives.BladeDance
					local lowMult = full.lowHPChanceMultiplier or 2
					addUnlocked("Blade Dance", string.format("%d%% (+HP) / %d%% (-HP) chance of +%d ATK", cfg.chance, math.floor(cfg.chance*lowMult), cfg.attackIncrease)) 
				end
			end
			if ConfigModule.SamuraiPassives.Burst then
				local cfg = getHighestUnlocked(ConfigModule.SamuraiPassives.Burst.levels)
				if cfg then addUnlocked("Burst", string.format("Combo2: %d%% (High HP) / %d%% (Low HP) chance for 2x damage", cfg.chanceHighHP, cfg.chanceLowHP)) end
			end
		end
	end

	if #buffLines > 0 then
		table.insert(sections, string.format("<b><font color='%s'>BUFFS & PASSIVES</font></b>", COLOR_HEADER))
		for _, l in ipairs(buffLines) do table.insert(sections, l) end
	end

	if #sections == 0 then
		return "<font color='#888888'>No Active Effects</font>"
	end

	return table.concat(sections, "\n")
end

local function updateLabel(label)
	if not label or not label.Parent then return end
	
	-- Ensure RichText and AutomaticSize
	label.RichText = true
	label.AutomaticSize = Enum.AutomaticSize.XY
	
	label.Text = generateStatusText()
end

local function setupLabel(label)
	if not label:IsA("TextLabel") then return end
	
	updateLabel(label)
	
	task.spawn(function()
		while label and label.Parent do
			updateLabel(label)
			task.wait(0.5)
		end
	end)
end

-- Initialization
local function initialize()
	for _, label in ipairs(CollectionService:GetTagged(TAG_NAME)) do
		setupLabel(label)
	end
	
	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupLabel)
end

-- Wait for data to be somewhat ready
task.spawn(function()
	player:WaitForChild("leaderstats", 20)
	initialize()
end)
