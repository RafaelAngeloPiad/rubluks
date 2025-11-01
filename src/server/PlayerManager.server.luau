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
		xpMultiplier = 1.2  -- Each level requires 20% more XP than the previous
	},
	
	-- Level-up multipliers per class (from spreadsheet)
	LevelUpMultipliers = {
		Samurai = {
			HP = 1.08,     -- 8% growth
			ATK = 1.05,    -- 5% growth
			D = 1.08       -- 8% growth
		},
		Archer = {
			HP = 1.06,     -- 6% growth
			ATK = 1.10,    -- 10% growth
			D = 1.05       -- 5% growth
		},
		Gladiator = {
			HP = 1.10,     -- 10% growth
			ATK = 1.03,    -- 3% growth
			D = 1.08       -- 8% growth
		},
		Brawler = {  -- Berserker in spreadsheet
			HP = 1.07,     -- 7% growth
			ATK = 1.09,    -- 9% growth
			D = 1.05       -- 5% growth
		},
		Knight = {
			HP = 1.07,     -- 7% growth
			ATK = 1.07,    -- 7% growth
			D = 1.07       -- 7% growth
		}
	},
	
	Archer = {
		-- Offense Stats
		ATK = 100,        -- Attack: Directly affects Health points
		DP = 0,           -- Defense Penetration: Directly affects Defense
		CR = 5,           -- Crit Rate: Rate of Critical Chance up to 100%
		CM = 150,         -- Crit Multiplier: Attack Multiplier (percentage)
		SD = 0,           -- Skill Damage: Damage from Skill Based Attack
		
		-- Defense Stats
		HP = 1200,        -- Health Points: Life pool (dies if ≤ 0)
		D = 50,           -- Defense: Reduces Penetration
		HR = 0,           -- Health Regeneration: Health Points gained per second
		Mspd = 18,        -- Movement Speed: Displacement per second
		Aspd = 1,         -- Attack Speed: Amount of hits per second
	},
	
	Samurai = {
		-- Offense Stats
		ATK = 50,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 1600,
		D = 80,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Brawler = {
		-- Offense Stats
		ATK = 90,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 1400,
		D = 50,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Knight = {
		-- Offense Stats
		ATK = 70,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 1400,
		D = 70,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Gladiator = {
		-- Offense Stats
		ATK = 30,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 2000,
		D = 80,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	}
}

-- Export BaseStats to ServerConfigs so other modules can access it
ServerConfigs.BaseStats = BaseStats

-- Helper function to calculate MaximumXP based on level
local function calculateMaximumXP(level)
	local startMaxXP = BaseStats.XP.startMaxXP
	local xpMultiplier = BaseStats.XP.xpMultiplier
	-- Formula: startMaxXP * (xpMultiplier ^ (level - 1))
	-- For level 1: startMaxXP * (xpMultiplier ^ 0) = startMaxXP * 1 = startMaxXP
	-- For level 2: startMaxXP * (xpMultiplier ^ 1) = startMaxXP * xpMultiplier
	-- For level 22: startMaxXP * (xpMultiplier ^ 21)
	local calculatedMaxXP = startMaxXP * (xpMultiplier ^ (level - 1))
	return math.floor(calculatedMaxXP)
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
	
	local skillDamage = Instance.new("NumberValue", leaderstats)
	skillDamage.Name = "SkillDamage"
	skillDamage.Value = 0

	-- Defense Stats
	local maxDefense = Instance.new("NumberValue", leaderstats)
	maxDefense.Name = "MaxDefense"
	maxDefense.Value = 0 -- Will be set based on class

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
		skillDamage.Value = convertDataType(data.SkillDamage, 0)
		maxDefense.Value = convertDataType(data.MaxDefense, 0)
		maxHealth.Value = convertDataType(data.MaxHealth, 0)
		healthRegen.Value = convertDataType(data.HealthRegen, 0)
		movementSpeed.Value = convertDataType(data.MovementSpeed, 0)
		attackSpeed.Value = convertDataType(data.AttackSpeed, 0)
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
		
		-- Ensure MaximumXP is valid
		if not maxxp or not maxxp.Value then
			return
		end
		
		print("[XP Debug] CurrentXP changed to: " .. newv .. ", MaximumXP: " .. maxxp.Value .. ", Level: " .. level.Value)
		
		-- Check if we should level up (handle multiple level-ups in one go)
		-- Level increases ONLY when XP reaches MaximumXP threshold
		isLevelingUp = true
		while newv >= maxxp.Value and level.Value < BaseStats.XP.maxLevel do
			local overtop = newv - maxxp.Value
			local currentLevel = level.Value
			
			print("[LEVEL UP] Excess XP: " .. overtop .. ", Current Level: " .. currentLevel .. ", Next Level: " .. (currentLevel + 1))
			
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

	-- kapag level up, dagdagan at i-store
	-- Connect this OUTSIDE CharacterAdded so it works even before character spawns
	level.Changed:Connect(function()
		local newLevel = level.Value
		print("[Level Debug] Level changed to: " .. newLevel)
		
		-- Recalculate MaximumXP when level changes (always, for resets too)
		local newMaxXP = calculateMaximumXP(newLevel)
		maxxp.Value = newMaxXP
		print("[Level Debug] MaximumXP recalculated to: " .. newMaxXP .. " for level " .. newLevel)
		
		-- Only apply multipliers if stats are initialized AND level actually increased (not decreased/reset)
		-- This prevents applying multipliers during initial load or reset
		if statsInitialized and newLevel > previousLevel then
			local multipliers = BaseStats.LevelUpMultipliers[class.Value]
			
			-- Apply multipliers if available and below max level
			if multipliers and newLevel <= BaseStats.XP.maxLevel then
				-- Apply level-up multipliers
				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * multipliers.HP)
				maxAttack.Value = math.floor(maxAttack.Value * multipliers.ATK)
				maxDefense.Value = math.floor(maxDefense.Value * multipliers.D)

				print("[Level Debug] Applied multipliers - HP: " .. leaderstats.MaxHealth.Value .. ", ATK: " .. maxAttack.Value .. ", DEF: " .. maxDefense.Value)

				-- update humanoid din habang buhay pa siya (if character exists)
				if plr.Character then
					local humanoid = plr.Character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.MaxHealth = leaderstats.MaxHealth.Value
						humanoid.Health = humanoid.MaxHealth
					end
				end
			end
		end
		
		-- Update previous level (important for detecting resets)
		previousLevel = newLevel
	end)
	
	-- Function to apply base stats (works before character spawns)
	local function applyBaseStats()
		-- Get base stats from BaseStats based on class
		local baseStats = BaseStats[class.Value]
		
		-- If no base stats found for class, use Slavkorian defaults
		if not baseStats then
			baseStats = { HP = 1000, ATK = 100, D = 0, DP = 0, CR = 5, CM = 150, SD = 0, HR = 0, Mspd = 18, Aspd = 1 }
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
		
		if leaderstats:FindFirstChild("DefensePenetration").Value == 0 then
			leaderstats.DefensePenetration.Value = baseStats.DP or 0
		end
		
		if leaderstats:FindFirstChild("CritRate").Value == 0 then
			leaderstats.CritRate.Value = baseStats.CR or 5
		end
		
		if leaderstats:FindFirstChild("CritMultiplier").Value == 0 then
			leaderstats.CritMultiplier.Value = baseStats.CM or 150
		end
		
		if leaderstats:FindFirstChild("SkillDamage").Value == 0 then
			leaderstats.SkillDamage.Value = baseStats.SD or 0
		end
		
		if leaderstats:FindFirstChild("HealthRegen").Value == 0 then
			leaderstats.HealthRegen.Value = baseStats.HR or 0
		end
		
		if leaderstats:FindFirstChild("MovementSpeed").Value == 0 then
			leaderstats.MovementSpeed.Value = baseStats.Mspd or 18
		end
		
		if leaderstats:FindFirstChild("AttackSpeed").Value == 0 then
			leaderstats.AttackSpeed.Value = baseStats.Aspd or 1
		end
	end
	
	-- Apply base stats when class changes (works immediately, even before character spawns)
	class.Changed:Connect(function()
		-- Reset all stats to 0 so base stats get applied
		leaderstats.MaxHealth.Value = 0
		leaderstats.MaxAttack.Value = 0
		leaderstats.MaxDefense.Value = 0
		leaderstats.DefensePenetration.Value = 0
		leaderstats.CritRate.Value = 0
		leaderstats.CritMultiplier.Value = 0
		leaderstats.SkillDamage.Value = 0
		leaderstats.HealthRegen.Value = 0
		leaderstats.MovementSpeed.Value = 0
		leaderstats.AttackSpeed.Value = 0
		-- Apply base stats immediately
		applyBaseStats()
	end)
	
	-- Apply base stats on initial load (if no saved data or if class was selected)
	if not data or (data and class.Value ~= "Slavkorian") then
		applyBaseStats()
	end

	-- Sa spawn
	plr.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")

		-- Apply base stats if not already set
		applyBaseStats()

		-- Apply stored MaxHealth to humanoid
		humanoid.MaxHealth = leaderstats.MaxHealth.Value
		humanoid.Health = humanoid.MaxHealth
		
		-- Apply Movement Speed if configured
		local baseStats = BaseStats[class.Value]
		if baseStats and baseStats.Mspd then
			humanoid.WalkSpeed = baseStats.Mspd
		end
		
		-- Mark stats as initialized after first spawn
		statsInitialized = true
		
		
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

	local dataToSave = {
		Level = tonumber(leaderstats.Level.Value) or 1,
		CurrentXP = tonumber(leaderstats.CurrentXP.Value) or 0,
		MaximumXP = tonumber(leaderstats.MaximumXP.Value) or BaseStats.XP.startMaxXP,
		Class = tostring(leaderstats.Class.Value) or "Slavkorian",
		MaxAttack = tonumber(leaderstats.MaxAttack.Value) or 0,
		DefensePenetration = tonumber(leaderstats.DefensePenetration.Value) or 0,
		CritRate = tonumber(leaderstats.CritRate.Value) or 0,
		CritMultiplier = tonumber(leaderstats.CritMultiplier.Value) or 0,
		SkillDamage = tonumber(leaderstats.SkillDamage.Value) or 0,
		MaxDefense = tonumber(leaderstats.MaxDefense.Value) or 0,
		MaxHealth = tonumber(leaderstats.MaxHealth.Value) or 0,
		HealthRegen = tonumber(leaderstats.HealthRegen.Value) or 0,
		MovementSpeed = tonumber(leaderstats.MovementSpeed.Value) or 0,
		AttackSpeed = tonumber(leaderstats.AttackSpeed.Value) or 0,
		Slavkoins = tonumber(leaderstats.Slavkoins.Value) or 0
	}

	local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
	if not success then
		warn("Failed to save data for " .. plr.Name .. ": " .. tostring(err))
	else
		print("Saved data for " .. plr.Name .. " - Level: " .. dataToSave.Level .. ", XP: " .. dataToSave.CurrentXP .. "/" .. dataToSave.MaximumXP)
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
	
	print("[DevStatEvent] Player " .. plr.Name .. " requested: " .. action .. " = " .. tostring(value))
	
	if action == "setCurrentXP" then
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = tonumber(value) or 0
			print("[DevStatEvent] Set CurrentXP to: " .. leaderstats.CurrentXP.Value)
		end
	elseif action == "addCurrentXP" then
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = leaderstats.CurrentXP.Value + (tonumber(value) or 0)
			print("[DevStatEvent] Added " .. value .. " XP, new CurrentXP: " .. leaderstats.CurrentXP.Value)
		end
	elseif action == "setLevel" then
		if leaderstats:FindFirstChild("Level") then
			leaderstats.Level.Value = tonumber(value) or 1
			-- Recalculate MaximumXP for the new level
			if leaderstats:FindFirstChild("MaximumXP") then
				leaderstats.MaximumXP.Value = calculateMaximumXP(leaderstats.Level.Value)
				print("[DevStatEvent] Set Level to: " .. leaderstats.Level.Value .. ", MaximumXP recalculated to: " .. leaderstats.MaximumXP.Value)
			else
				print("[DevStatEvent] Set Level to: " .. leaderstats.Level.Value)
			end
		end
	elseif action == "setClass" then
		if leaderstats:FindFirstChild("Class") then
			local newClass = tostring(value) or "Slavkorian"
			print("[DevStatEvent] Changing class to: " .. newClass .. " - Resetting to level 1 and base stats")
			
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
			local statsToReset = {"MaxAttack", "MaxDefense", "MaxHealth", "DefensePenetration", 
				"CritRate", "CritMultiplier", "SkillDamage", "HealthRegen", "MovementSpeed", "AttackSpeed"}
			
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
				leaderstats.MaxHealth.Value = baseStats.HP or 0
				leaderstats.MaxAttack.Value = baseStats.ATK or 0
				leaderstats.MaxDefense.Value = baseStats.D or 0
				leaderstats.DefensePenetration.Value = baseStats.DP or 0
				leaderstats.CritRate.Value = baseStats.CR or 5
				leaderstats.CritMultiplier.Value = baseStats.CM or 150
				leaderstats.SkillDamage.Value = baseStats.SD or 0
				leaderstats.HealthRegen.Value = baseStats.HR or 0
				leaderstats.MovementSpeed.Value = baseStats.Mspd or 18
				leaderstats.AttackSpeed.Value = baseStats.Aspd or 1
				print("[DevStatEvent] Applied base stats for " .. newClass .. " - HP: " .. baseStats.HP .. ", ATK: " .. baseStats.ATK .. ", DEF: " .. baseStats.D)
			else
				-- Default Slavkorian stats if class not found
				leaderstats.MaxHealth.Value = 1000
				leaderstats.MaxAttack.Value = 100
				leaderstats.MaxDefense.Value = 0
				leaderstats.DefensePenetration.Value = 0
				leaderstats.CritRate.Value = 5
				leaderstats.CritMultiplier.Value = 150
				leaderstats.SkillDamage.Value = 0
				leaderstats.HealthRegen.Value = 0
				leaderstats.MovementSpeed.Value = 18
				leaderstats.AttackSpeed.Value = 1
				print("[DevStatEvent] Applied default Slavkorian stats (class " .. newClass .. " not found)")
			end
			
			print("[DevStatEvent] Class change complete - Level: 1, XP: 0/" .. (leaderstats.MaximumXP and leaderstats.MaximumXP.Value or "?") .. ", Class: " .. newClass)
		end
	elseif action == "resetStat" then
		local statName = tostring(value)
		if leaderstats:FindFirstChild(statName) then
			leaderstats[statName].Value = 0
			print("[DevStatEvent] Reset stat: " .. statName)
		end
	elseif action == "fullReset" then
		-- Full reset: Level 1, XP 0, MaximumXP recalculated, Class Slavkorian, all stats reset
		print("[DevStatEvent] Performing full reset for " .. plr.Name)
		
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
		local statsToReset = {"MaxAttack", "MaxDefense", "MaxHealth", "DefensePenetration", 
			"CritRate", "CritMultiplier", "SkillDamage", "HealthRegen", "MovementSpeed", "AttackSpeed"}
		
		for _, statName in ipairs(statsToReset) do
			if leaderstats:FindFirstChild(statName) then
				leaderstats[statName].Value = 0
			end
		end
		
		print("[DevStatEvent] Full reset complete - Level: 1, XP: 0/" .. (leaderstats.MaximumXP and leaderstats.MaximumXP.Value or "?") .. ", Class: Slavkorian")
	end
end)

