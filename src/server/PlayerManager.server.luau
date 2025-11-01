local MainDataStore

local success, err = pcall(function()
	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
end)

if not success or not MainDataStore then
	--warn("MainDataStore module not found or failed to load: " .. tostring(err))
end

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))


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
	level.Value = ServerConfigs.BaseStats.XP.startLevel

	local currxp = Instance.new("NumberValue", leaderstats)
	currxp.Name = "CurrentXP"
	currxp.Value = ServerConfigs.BaseStats.XP.startXP

	local maxxp = Instance.new("NumberValue", leaderstats)
	maxxp.Name = "MaximumXP"
	maxxp.Value = ServerConfigs.BaseStats.XP.startMaxXP

	local class = Instance.new("StringValue", leaderstats)
	class.Name = "Class"
	class.Value = "Slavkorian"

	local maxAttack = Instance.new("NumberValue", leaderstats)
	maxAttack.Name = "MaxAttack"
	maxAttack.Value = 0 -- Will be set based on class

	local maxDefense = Instance.new("NumberValue", leaderstats)
	maxDefense.Name = "MaxDefense"
	maxDefense.Value = 0 -- Will be set based on class
	
	local maxMagicDefense = Instance.new("NumberValue", leaderstats)
	maxMagicDefense.Name = "MaxMagicDefense"
	maxMagicDefense.Value = 0 -- Will be set based on class

	local slavkoins = Instance.new("NumberValue", leaderstats)
	slavkoins.Name = "Slavkoins"
	slavkoins.Value = 0
	
	local maxHealth = Instance.new("NumberValue", leaderstats)
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = 0 -- Will be set based on class
	
	-- loads progress data
	if data then
		level.Value = data.Level or ServerConfigs.BaseStats.XP.startLevel
		currxp.Value = data.CurrentXP or ServerConfigs.BaseStats.XP.startXP
		maxxp.Value = data.MaximumXP or ServerConfigs.BaseStats.XP.startMaxXP
		class.Value = data.Class or "Slavkorian"
		maxAttack.Value = data.MaxAttack or 0
		maxDefense.Value = data.MaxDefense or 0
		maxMagicDefense.Value = data.MaxMagicDefense or 0
		slavkoins.Value = data.Slavkoins or 0
		maxHealth.Value = data.MaxHealth or 0

		-- LEVEL CAP: Clamp loaded level to max level from config
		level.Value = math.min(level.Value, ServerConfigs.BaseStats.XP.maxLevel)
	end
	
	-- Sa spawn
	plr.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")

		local function applyStats()
			-- Get base stats from config based on class
			local baseStats = ServerConfigs.BaseStats[class.Value]
			
			-- If no base stats found for class, use Slavkorian defaults
			if not baseStats then
				baseStats = { HP = 1000, ATK = 100, D = 0, MD = 0 }
			end
			
			-- Set base stats if not already set
			if leaderstats:FindFirstChild("MaxHealth").Value == 0 then
				leaderstats.MaxHealth.Value = baseStats.HP
			end
			
			if leaderstats:FindFirstChild("MaxAttack").Value == 0 then
				leaderstats.MaxAttack.Value = baseStats.ATK
			end
			
			if leaderstats:FindFirstChild("MaxDefense").Value == 0 then
				leaderstats.MaxDefense.Value = baseStats.D
			end
			
			if leaderstats:FindFirstChild("MaxMagicDefense").Value == 0 then
				leaderstats.MaxMagicDefense.Value = baseStats.MD or 0
			end

			-- Apply stored MaxHealth to humanoid
			humanoid.MaxHealth = leaderstats.MaxHealth.Value
			humanoid.Health = humanoid.MaxHealth
			
			-- Apply Movement Speed if configured
			if baseStats.Mspd then
				humanoid.WalkSpeed = baseStats.Mspd
			end
		end

		-- apply pag spawn
		applyStats()

		-- apply din pag class nagbago
		class.Changed:Connect(function()
			leaderstats.MaxHealth.Value = 0 -- reset so ma-trigger ulit yung base assign
			leaderstats.MaxAttack.Value = 0
			leaderstats.MaxDefense.Value = 0
			leaderstats.MaxMagicDefense.Value = 0
			applyStats()
		end)

		-- kapag level up, dagdagan at i-store
		level.Changed:Connect(function()
			-- Get level-up multipliers from config
			local multipliers = ServerConfigs.BaseStats.LevelUpMultipliers[class.Value]
			
			-- Apply multipliers if available and below max level
			if multipliers and level.Value <= ServerConfigs.BaseStats.XP.maxLevel then
				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * multipliers.HP)
				maxAttack.Value = math.floor(maxAttack.Value * multipliers.ATK)
				maxDefense.Value = math.floor(maxDefense.Value * multipliers.D)
				if multipliers.MD then
					maxMagicDefense.Value = math.floor(maxMagicDefense.Value * multipliers.MD)
				end

				-- update humanoid din habang buhay pa siya
				humanoid.MaxHealth = leaderstats.MaxHealth.Value
				humanoid.Health = humanoid.MaxHealth
			end
		end)
		
		-- LEVEL CAP: Clamp level after any increment
		currxp.Changed:Connect(function(newv)
			if newv >= maxxp.Value then
				local overtop = newv - maxxp.Value
				--print("LEVELED UP! Excess XP: " .. overtop)
				currxp.Value = overtop

				-- Harder to level up after 40
				if level.Value > 40 then
					maxxp.Value = maxxp.Value + 0
				else
					maxxp.Value = maxxp.Value + 0 
				end

				level.Value = level.Value + 1
				-- LEVEL CAP: Clamp level to max level from config
				level.Value = math.min(level.Value, ServerConfigs.BaseStats.XP.maxLevel)
			end
		end)
		
		
	end)
	
end)

game.Players.PlayerRemoving:Connect(function(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	local character = plr.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

	if leaderstats and MainDataStore then
		-- LEVEL CAP: Clamp level before saving
		leaderstats.Level.Value = math.min(leaderstats.Level.Value, ServerConfigs.BaseStats.XP.maxLevel)

		local dataToSave = {
			Level = leaderstats.Level.Value,
			CurrentXP = leaderstats.CurrentXP.Value,
			MaximumXP = leaderstats.MaximumXP.Value,
			Class = leaderstats.Class.Value,
			MaxAttack = leaderstats.MaxAttack.Value,
			MaxDefense = leaderstats.MaxDefense.Value,
			MaxMagicDefense = leaderstats.MaxMagicDefense.Value,
			Slavkoins = leaderstats.Slavkoins.value,
			MaxHealth = leaderstats.MaxHealth.Value
		}

		local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
		if not success then
			--warn("Failed to save data for " .. plr.Name .. ": " .. tostring(err))
		end
	else
		--warn("MainDataStore not available, cannot save player data for " .. plr.Name)
	end
end)

