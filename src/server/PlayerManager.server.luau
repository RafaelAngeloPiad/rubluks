-- local MainDataStore

-- local success, err = pcall(function()
-- 	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
-- end)

-- if not success or not MainDataStore then
-- 	--warn("MainDataStore module not found or failed to load: " .. tostring(err))
-- end


-- game.Players.PlayerAdded:Connect(function(plr)
	
-- 	local teleportData = plr:GetJoinData().TeleportData
-- 	--print("PlayerAdded: TeleportData =", teleportData)
-- 	local data

-- 	if teleportData then
-- 		-- Use TeleportData if present
-- 		data = teleportData
-- 		--print("Loaded data from TeleportData:", data)
-- 	else
-- 		-- Otherwise, load from MainDataStore
-- 		if MainDataStore then
-- 			data = MainDataStore.LoadPlayerData(plr.UserId)
-- 			--print("Loaded data from MainDataStore:", data)
-- 		else
-- 			--warn("MainDataStore not available, cannot load player data.")
-- 		end
-- 	end


-- 	local leaderstats = Instance.new("Folder")
-- 	leaderstats.Name = "leaderstats"
-- 	leaderstats.Parent = plr

-- 	local level = Instance.new("IntValue", leaderstats)
-- 	level.Name = "Level"
-- 	level.Value = 1

-- 	local currxp = Instance.new("NumberValue", leaderstats)
-- 	currxp.Name = "CurrentXP"
-- 	currxp.Value = 0

-- 	local maxxp = Instance.new("NumberValue", leaderstats)
-- 	maxxp.Name = "MaximumXP"
-- 	maxxp.Value = 5

-- 	local class = Instance.new("StringValue", leaderstats)
-- 	class.Name = "Class"
-- 	class.Value = "Slavkorian"

-- 	local maxAttack = Instance.new("NumberValue", leaderstats)
-- 	maxAttack.Name = "MaxAttack"
-- 	maxAttack.Value = 100

-- 	local maxDefense = Instance.new("NumberValue", leaderstats)
-- 	maxDefense.Name = "MaxDefense"
-- 	maxDefense.Value = 100

-- 	local slavkoins = Instance.new("NumberValue", leaderstats)
-- 	slavkoins.Name = "Slavkoins"
-- 	slavkoins.Value = 0
	
-- 	local maxHealth = Instance.new("NumberValue", leaderstats)
-- 	maxHealth.Name = "MaxHealth"
-- 	maxHealth.Value = 1000
	
-- 	-- loads progress data
-- 	if data then
-- 		level.Value = data.Level or 1
-- 		currxp.Value = data.CurrentXP or 0
-- 		maxxp.Value = data.MaximumXP or 5
-- 		class.Value = data.Class or "Slavkorian"
-- 		maxAttack.Value = data.MaxAttack or 100
-- 		maxDefense.Value = data.MaxDefense or 100
-- 		slavkoins.Value = data.Slavkoins or 0
-- 		maxHealth.Value = data.MaxHealth or 1000

-- 		-- LEVEL CAP: Clamp loaded level to 50
-- 		level.Value = math.min(level.Value, 50)
-- 	end
	
-- 	-- Sa spawn
-- 	plr.CharacterAdded:Connect(function(char)
-- 		local humanoid = char:WaitForChild("Humanoid")

-- 		local function applyStats()
-- 			-- kung wala pang value, i-set base class value
-- 			if leaderstats:FindFirstChild("MaxHealth").Value == 0 then
-- 				if class.Value == "Samurai" then
-- 					leaderstats.MaxHealth.Value = 1600
-- 				elseif class.Value == "Archer" then
-- 					leaderstats.MaxHealth.Value = 1200
-- 				elseif class.Value == "Gladiator" then
-- 					leaderstats.MaxHealth.Value = 2000
-- 				elseif class.Value == "Brawler" then
-- 					leaderstats.MaxHealth.Value = 1400
-- 				elseif class.Value == "Knight" then
-- 					leaderstats.MaxHealth.Value = 1400
-- 				else
-- 					leaderstats.MaxHealth.Value = 1000
-- 				end
-- 			end

-- 			-- apply stored MaxHealth sa humanoid
-- 			humanoid.MaxHealth = leaderstats.MaxHealth.Value
-- 			humanoid.Health = humanoid.MaxHealth
-- 		end

-- 		-- apply pag spawn
-- 		applyStats()

-- 		-- apply din pag class nagbago
-- 		class.Changed:Connect(function()
-- 			leaderstats.MaxHealth.Value = 0 -- reset so ma-trigger ulit yung base assign
-- 			applyStats()
-- 		end)

-- 		-- kapag level up, dagdagan at i-store
-- 		level.Changed:Connect(function()
-- 			if class.Value == "Samurai" and level.Value < 50 then
-- 				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * 1.08)
-- 				maxAttack.Value = math.floor(maxAttack.Value * 1.05)
-- 				maxDefense.Value = math.floor(maxDefense.Value * 1.05)

-- 				-- update humanoid din habang buhay pa siya
-- 				humanoid.MaxHealth = leaderstats.MaxHealth.Value
-- 				humanoid.Health = humanoid.MaxHealth
			
-- 			elseif class.Value == "Archer" and level.Value < 50 then
-- 				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * 1.06)
-- 				maxAttack.Value = math.floor(maxAttack.Value * 1.1)
-- 				maxDefense.Value = math.floor(maxDefense.Value * 1.05)

-- 				-- update humanoid din habang buhay pa siya
-- 				humanoid.MaxHealth = leaderstats.MaxHealth.Value
-- 				humanoid.Health = humanoid.MaxHealth
				
-- 			elseif class.Value == "Gladiator" and level.Value < 50 then
-- 				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * 1.1)
-- 				maxAttack.Value = math.floor(maxAttack.Value * 1.03)
-- 				maxDefense.Value = math.floor(maxDefense.Value * 1.08)

-- 				-- update humanoid din habang buhay pa siya
-- 				humanoid.MaxHealth = leaderstats.MaxHealth.Value
-- 				humanoid.Health = humanoid.MaxHealth
				
-- 			elseif class.Value == "Brawler" and level.Value < 50 then
-- 				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * 1.07)
-- 				maxAttack.Value = math.floor(maxAttack.Value * 1.09)
-- 				maxDefense.Value = math.floor(maxDefense.Value * 1.05)

-- 				-- update humanoid din habang buhay pa siya
-- 				humanoid.MaxHealth = leaderstats.MaxHealth.Value
-- 				humanoid.Health = humanoid.MaxHealth
				
-- 			elseif class.Value == "Knight" and level.Value < 50 then
-- 				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * 1.07)
-- 				maxAttack.Value = math.floor(maxAttack.Value * 1.07)
-- 				maxDefense.Value = math.floor(maxDefense.Value * 1.07)

-- 				-- update humanoid din habang buhay pa siya
-- 				humanoid.MaxHealth = leaderstats.MaxHealth.Value
-- 				humanoid.Health = humanoid.MaxHealth
-- 			end
	

-- 		end)
		
-- 		-- LEVEL CAP: Clamp level after any increment
-- 		currxp.Changed:Connect(function(newv)
-- 			if newv >= maxxp.Value then
-- 				local overtop = newv - maxxp.Value
-- 				--print("LEVELED UP! Excess XP: " .. overtop)
-- 				currxp.Value = overtop

-- 				-- Harder to level up after 40
-- 				if level.Value > 40 then
-- 					maxxp.Value = maxxp.Value + 0
-- 				else
-- 					maxxp.Value = maxxp.Value + 0 
-- 				end

-- 				level.Value = level.Value + 1
-- 				-- LEVEL CAP: Clamp level to 50 after increment
-- 				level.Value = math.min(level.Value, 50)
-- 			end
-- 		end)
		
		
-- 	end)
	
-- end)

-- game.Players.PlayerRemoving:Connect(function(plr)
-- 	local leaderstats = plr:FindFirstChild("leaderstats")
-- 	local character = plr.Character
-- 	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

-- 	if leaderstats and MainDataStore then
-- 		-- LEVEL CAP: Clamp level before saving
-- 		leaderstats.Level.Value = math.min(leaderstats.Level.Value, 50)

-- 		local dataToSave = {
-- 			Level = leaderstats.Level.Value,
-- 			CurrentXP = leaderstats.CurrentXP.Value,
-- 			MaximumXP = leaderstats.MaximumXP.Value,
-- 			Class = leaderstats.Class.Value,
-- 			MaxAttack = leaderstats.MaxAttack.Value,
-- 			MaxDefense = leaderstats.MaxDefense.Value,
-- 			Slavkoins = leaderstats.Slavkoins.value,
-- 			MaxHealth = leaderstats.MaxHealth.Value
-- 		}

-- 		local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
-- 		if not success then
-- 			--warn("Failed to save data for " .. plr.Name .. ": " .. tostring(err))
-- 		end
-- 	else
-- 		--warn("MainDataStore not available, cannot save player data for " .. plr.Name)
-- 	end
-- end)

