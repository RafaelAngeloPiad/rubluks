local MainDataStore
local success, err = pcall(function()
	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
end)
if not success or not MainDataStore then
	warn("MainDataStore module not found or failed to load: " .. tostring(err))
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestXPChange = ReplicatedStorage:WaitForChild("RequestXPChange")

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
	

	if data then
		level.Value = data.Level or 1
		currxp.Value = data.CurrentXP or 0
		maxxp.Value = data.MaximumXP or 5
		class.Value = data.Class or "Slavkorian"
	end

	currxp.Changed:Connect(function(newv)
		if newv >= maxxp.Value then
			local overtop = newv - maxxp.Value
			print("LEVELED UP! Excess XP: " .. overtop)
			currxp.Value = overtop
			maxxp.Value = maxxp.Value + 5
			level.Value = level.Value + 1
		end
	end)

	-- Listen for XP change requests from UIDevTools
	RequestXPChange.OnServerEvent:Connect(function(requestingPlayer, amount)
		if requestingPlayer ~= plr then return end -- Only allow self
		if amount == "reset" then
			currxp.Value = 0
			level.Value = 1
			maxxp.Value = 5
			-- Save immediately
			if MainDataStore then
				local dataToSave = {
					Level = level.Value,
					CurrentXP = currxp.Value,
					MaximumXP = maxxp.Value,
					Class = class.Value
				}
				MainDataStore.SavePlayerData(plr.UserId, dataToSave)
			end
		elseif typeof(amount) == "number" then
			currxp.Value = currxp.Value + amount
			-- Save immediately
			if MainDataStore then
				local dataToSave = {
					Level = level.Value,
					CurrentXP = currxp.Value,
					MaximumXP = maxxp.Value,
					Class = class.Value
				}
				MainDataStore.SavePlayerData(plr.UserId, dataToSave)
			end
		end
	end)
end)

game.Players.PlayerRemoving:Connect(function(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if leaderstats and MainDataStore then
		local dataToSave = {
			Level = leaderstats.Level.Value,
			CurrentXP = leaderstats.CurrentXP.Value,
			MaximumXP = leaderstats.MaximumXP.Value,
			Class = leaderstats.Class.Value
		}
		local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
		if not success then
			warn("Failed to save data for " .. plr.Name .. ": " .. tostring(err))
		end
	else
		warn("MainDataStore not available, cannot save player data for " .. plr.Name)
	end
end)

