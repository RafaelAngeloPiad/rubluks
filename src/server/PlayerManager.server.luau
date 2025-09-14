local MainDataStore
local success, err = pcall(function()
	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
end)
if not success or not MainDataStore then
	warn("MainDataStore module not found or failed to load: " .. tostring(err))
end

-- Table to store health upgrade connections per player
local healthConnections = {}

local function setupHealthReset(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	plr.CharacterAdded:Connect(function(character)
		local currhealth = leaderstats:FindFirstChild("CurrentHealth")
		local maxhealth = leaderstats:FindFirstChild("MaxHealth")
		if currhealth and maxhealth then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Set humanoid health to maxhealth.Value on respawn
				humanoid.Health = maxhealth.Value
				humanoid.MaxHealth = maxhealth.Value
			end
			-- Only reset CurrentHealth to maxhealth.Value, do not reset EXP or Level
			currhealth.Value = maxhealth.Value
		end
		-- No changes to EXP or Level on respawn; they persist
	end)
end

game.Players.PlayerAdded:Connect(function(plr)
	local teleportData = plr:GetJoinData().TeleportData
	print("PlayerAdded: TeleportData =", teleportData)
	local data

	if teleportData then
		-- Use TeleportData if present
		data = teleportData
		print("Loaded data from TeleportData:", data)
	else
		-- Otherwise, load from MainDataStore
		if MainDataStore then
			data = MainDataStore.LoadPlayerData(plr.UserId)
			print("Loaded data from MainDataStore:", data)
		else
			warn("MainDataStore not available, cannot load player data.")
		end
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plr

	local level = Instance.new("IntValue", leaderstats)
	level.Name = "Level"
	level.Value = 1

	local currxp = Instance.new("NumberValue", leaderstats)
	currxp.Name = "CurrentXP"
	currxp.Value = 0

	local maxxp = Instance.new("NumberValue", leaderstats)
	maxxp.Name = "MaximumXP"
	maxxp.Value = 5
	
	local class = Instance.new("StringValue", leaderstats)
	class.Name = "Class"
	class.Value = "Slavkorian"
	
	local maxhealth = Instance.new("NumberValue", leaderstats)
	maxhealth.Name = "MaxHealth"
	maxhealth.Value = 100
	
	local currhealth = Instance.new("NumberValue", leaderstats)
	currhealth.Name = "CurrentHealth"
	currhealth.Value = maxhealth.Value
	
	local maxAttack = Instance.new("NumberValue", leaderstats)
	maxAttack.Name = "MaxAttack"
	maxAttack.Value = 100
	
	local maxDefense = Instance.new("NumberValue", leaderstats)
	maxDefense.Name = "MaxDefense"
	maxDefense.Value = 100
	
	-- loads progress data
	if data then
		level.Value = data.Level or 1
		currxp.Value = data.CurrentXP or 0
		maxxp.Value = data.MaximumXP or 5
		class.Value = data.Class or "Slavkorian"
		maxhealth.Value = data.MaxHealth or 100
		maxAttack.Value = data.MaxAttack or 100
		maxDefense.Value = data.MaxDefense or 100
		currhealth.Value = data.CurrentHealth or maxhealth.Value
		-- LEVEL CAP: Clamp loaded level to 50
		level.Value = math.min(level.Value, 50)
	end
	
	-- Change Default Stats based on class
	class.Changed:Connect(function(newclass)
		-- Disconnect previous level.Changed connections if any
		if healthConnections[plr] then
			healthConnections[plr]:Disconnect()
			healthConnections[plr] = nil
		end

		-- Always reset maxhealth/currhealth to class default
		if newclass == "Samurai" then
			maxhealth.Value = 1600
			maxAttack.Value = 50
			maxDefense.Value = 80
			currhealth.Value = maxhealth.Value
			healthConnections[plr] = level.Changed:Connect(function()
				local newLevel = level.Value
				if newLevel < 50 then
					local addedHealth = math.floor(maxhealth.Value * 1.08)
					local addedAttack = math.floor(maxAttack.Value * 1.05)
					local addedDefense = math.floor(maxDefense.Value * 1.08)
					maxhealth.Value = addedHealth
					currhealth.Value = maxhealth.Value
					maxAttack.Value = addedAttack
					maxDefense.Value = addedDefense
				end
			end)
		elseif newclass == "Archer" then
			maxhealth.Value = 1200
			maxAttack.Value = 100
			maxDefense.Value = 30
			currhealth.Value = maxhealth.Value
			healthConnections[plr] = level.Changed:Connect(function()
				local newLevel = level.Value
				if newLevel < 50 then
					local addedHealth = math.floor(maxhealth.Value * 1.06)
					local addedAttack = math.floor(maxAttack.Value * 1.1)
					local addedDefense = math.floor(maxDefense.Value * 1.05)
					maxhealth.Value = addedHealth
					currhealth.Value = maxhealth.Value
					maxAttack.Value = addedAttack
					maxDefense.Value = addedDefense
				end
			end)
		elseif newclass == "Gladiator" then
			maxhealth.Value = 2000
			currhealth.Value = maxhealth.Value
			healthConnections[plr] = level.Changed:Connect(function()
				local newLevel = level.Value
				if newLevel < 50 then
					local addedHealth = math.floor(maxhealth.Value * 1.1)
					maxhealth.Value = addedHealth
					currhealth.Value = maxhealth.Value
				end
			end)
		elseif newclass == "Berserker" then
			maxhealth.Value = 1400
			currhealth.Value = maxhealth.Value
			healthConnections[plr] = level.Changed:Connect(function()
				local newLevel = level.Value
				if newLevel < 50 then
					local addedHealth = math.floor(maxhealth.Value * 1.07)
					maxhealth.Value = addedHealth
					currhealth.Value = maxhealth.Value
				end
			end)
		elseif newclass == "Knight" then
			maxhealth.Value = 1400
			currhealth.Value = maxhealth.Value
			healthConnections[plr] = level.Changed:Connect(function()
				local newLevel = level.Value
				if newLevel < 50 then
					local addedHealth = math.floor(maxhealth.Value * 1.07)
					maxhealth.Value = addedHealth
					currhealth.Value = maxhealth.Value
				end
			end)
		else
			maxhealth.Value = 100
			currhealth.Value = maxhealth.Value
			maxAttack.Value = 100
			maxDefense.Value = 100
		end
	end)

	-- LEVEL CAP: Clamp level after any increment
	currxp.Changed:Connect(function(newv)
		if newv >= maxxp.Value then
			local overtop = newv - maxxp.Value
			print("LEVELED UP! Excess XP: " .. overtop)
			currxp.Value = overtop
			
			-- Harder to level up after 40
			if level.Value > 40 then
				maxxp.Value = maxxp.Value + 0
			else
				maxxp.Value = maxxp.Value + 0 
			end
			
			level.Value = level.Value + 1
			-- LEVEL CAP: Clamp level to 50 after increment
			level.Value = math.min(level.Value, 50)
		end
	end)
	
	
	-- Health reset on respawn
	setupHealthReset(plr)
end)

-- Also handle existing players in case script is reloaded
for _, plr in game.Players:GetPlayers() do
	setupHealthReset(plr)
end

game.Players.PlayerRemoving:Connect(function(plr)
	-- Disconnect health upgrade connection for this player
	if healthConnections[plr] then
		healthConnections[plr]:Disconnect()
		healthConnections[plr] = nil
	end

	local leaderstats = plr:FindFirstChild("leaderstats")
	if leaderstats and MainDataStore then
		-- LEVEL CAP: Clamp level before saving
		leaderstats.Level.Value = math.min(leaderstats.Level.Value, 50)
		local dataToSave = {
			Level = leaderstats.Level.Value,
			CurrentXP = leaderstats.CurrentXP.Value,
			MaximumXP = leaderstats.MaximumXP.Value,
			Class = leaderstats.Class.Value,
			CurrentHealth = leaderstats.CurrentHealth.Value,
			MaxHealth = leaderstats.MaxHealth.Value,
			MaxAttack = leaderstats.MaxAttack.Value,
			MaxDefense = leaderstats.MaxDefense.Value
		}
		local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
		if not success then
			warn("Failed to save data for " .. plr.Name .. ": " .. tostring(err))
		end
	else
		warn("MainDataStore not available, cannot save player data for " .. plr.Name)
	end
end)

