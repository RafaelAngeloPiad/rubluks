local MainDataStore

local success2, err2 = pcall(function()
	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
end)

if not success2 or not MainDataStore then
	warn("MainDataStore module not found or failed to load: " .. tostring(err2))
end

local function applySunfireWaterConsumable(player, definition)
	definition = definition or {}

	if not player or not player:IsA("Player") then
		return false, "invalid player"
	end

	local sunfireprogress = player:FindFirstChild("sunfireprogress")
	if not sunfireprogress then
		return false, "sunfireprogress not ready"
	end

	local currentWater = sunfireprogress:FindFirstChild("CurrentWaterLevel")
	local maxWater = sunfireprogress:FindFirstChild("MaxWaterLevel")
	if not currentWater or not maxWater then
		return false, "sunfire water stats missing"
	end

	local maxValue = tonumber(maxWater.Value) or 0
	local currentValue = tonumber(currentWater.Value) or 0

	local mode = definition.mode
	if typeof(mode) == "string" then
		mode = string.lower(mode)
	else
		mode = nil
	end

	if definition.setToMax or definition.fillToMax then
		mode = "settomax"
	end

	local newValue = currentValue

	if mode == "settomax" or mode == "max" then
		newValue = maxValue
	elseif mode == "set" or mode == "replace" then
		local target = tonumber(definition.amount) or maxValue
		newValue = math.clamp(target, 0, maxValue)
	elseif mode == "percentage" or mode == "percent" or mode == "ratio" then
		local ratio = tonumber(definition.amount) or 0
		if math.abs(ratio) > 1 then
			ratio = ratio / 100
		end
		ratio = math.clamp(ratio, 0, 1)
		newValue = math.max(currentValue, maxValue * ratio)
	else
		local delta = tonumber(definition.amount)
		if delta == nil then
			delta = maxValue
		end
		newValue = currentValue + delta
	end

	if definition.clampToMax ~= false then
		newValue = math.clamp(newValue, 0, maxValue)
	end

	if definition.minimumResult then
		newValue = math.max(newValue, math.min(maxValue, tonumber(definition.minimumResult) or newValue))
	end

	currentWater.Value = newValue

	if definition.logResult then
		print(string.format("[SunfireManager] Applied water consumable for %s -> %d/%d", player.Name, math.floor(newValue), math.floor(maxValue)))
	end

	return true
end

local function tryRegisterSunfireConsumableHandler()
	if typeof(_G.registerConsumableHandler) ~= "function" then
		return false
	end

	_G.registerConsumableHandler("SunfireWaterRestore", applySunfireWaterConsumable)
	return true
end

if not tryRegisterSunfireConsumableHandler() then
	task.spawn(function()
		while not tryRegisterSunfireConsumableHandler() do
			task.wait(1)
		end
	end)
end

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(plr)

	local teleportData2 = plr:GetJoinData().TeleportData
	--print("PlayerAdded: TeleportData =", teleportData)
	local data2

	if teleportData2 then
		-- Use TeleportData if present
		data2 = teleportData2
		--print("Loaded data from TeleportData:", data)
	else
		-- Otherwise, load from MainDataStore
		if MainDataStore then
			data2 = MainDataStore.LoadSunfireProgress(plr.UserId)
			--print("Loaded data from MainDataStore:", data)
		else
			--warn("MainDataStore not available, cannot load player data.")
		end
	end


	local sunfireprogress = Instance.new("Folder")
	sunfireprogress.Name = "sunfireprogress"
	sunfireprogress.Parent = plr

	local currentWaterLevel = Instance.new("NumberValue", sunfireprogress)
	currentWaterLevel.Name = "CurrentWaterLevel"
	currentWaterLevel.Value = 0

	local maxWaterLevel = Instance.new("NumberValue", sunfireprogress)
	maxWaterLevel.Name = "MaxWaterLevel"
	maxWaterLevel.Value = 300

	local waterBasinOne = Instance.new("BoolValue", sunfireprogress)
	waterBasinOne.Name = "WaterBasinOne"
	waterBasinOne.Value = false

	local waterBasinTwo = Instance.new("BoolValue", sunfireprogress)
	waterBasinTwo.Name = "WaterBasinTwo"
	waterBasinTwo.Value = false

	local waterBasinThree = Instance.new("BoolValue", sunfireprogress)
	waterBasinThree.Name = "WaterBasinThree"
	waterBasinThree.Value = false

	local waterBasinFourth = Instance.new("BoolValue", sunfireprogress)
	waterBasinFourth.Name = "WaterBasinFourth"
	waterBasinFourth.Value = false

	local waterBasinFifth = Instance.new("BoolValue", sunfireprogress)
	waterBasinFifth.Name = "WaterBasinFifth"
	waterBasinFifth.Value = false
	
	--------------- MINI BOSS KILL ----------------------
	local miniBossKill = Instance.new("Folder")
	miniBossKill.Name = "MiniBossKill"
	miniBossKill.Parent = sunfireprogress
	
	local miniBossKillOne = Instance.new("BoolValue", miniBossKill)
	miniBossKillOne.Name = "MiniBossKillOne"
	miniBossKillOne.Value = false
	
	local miniBossKillTwo = Instance.new("BoolValue", miniBossKill)
	miniBossKillTwo.Name = "MiniBossKillTwo"
	miniBossKillTwo.Value = false
	
	local miniBossKillThree = Instance.new("BoolValue", miniBossKill)
	miniBossKillThree.Name = "MiniBossKillThree"
	miniBossKillThree.Value = false
	
	local miniBossKillFourth = Instance.new("BoolValue", miniBossKill)
	miniBossKillFourth.Name = "MiniBossKillFourth"
	miniBossKillFourth.Value = false
	
	local miniBossKillFifth = Instance.new("BoolValue", miniBossKill)
	miniBossKillFifth.Name = "MiniBossKillFifth"
	miniBossKillFifth.Value = false
	
	------------- Damaged Key -------------------
	
	local currentDamagedKey = Instance.new("IntValue", sunfireprogress)
	currentDamagedKey.Name = "CurrentDamagedKey"
	currentDamagedKey.Value = 0
	
	------------- Refined Key -------------------
	
	local currentRefinedKey = Instance.new("IntValue", sunfireprogress)
	currentRefinedKey.Name = "CurrentRefinedKey"
	currentRefinedKey.Value = 0

	
	plr.CharacterAdded:Connect(function(character)
		-- only run once on initial spawn, not every respawn
		if data2 and not plr:GetAttribute("SunfireLoaded") then
			local sf = plr:WaitForChild("sunfireprogress")
			sf.CurrentWaterLevel.Value = data2.CurrentWaterLevel or 0
			sf.MaxWaterLevel.Value = data2.MaxWaterLevel or 300
			sf.WaterBasinOne.Value = data2.WaterBasinOne or false
			sf.WaterBasinTwo.Value = data2.WaterBasinTwo or false
			sf.WaterBasinThree.Value = data2.WaterBasinThree or false
			sf.WaterBasinFourth.Value = data2.WaterBasinFourth or false
			sf.WaterBasinFifth.Value = data2.WaterBasinFifth or false
			sf.MiniBossKillOne.Value = data2.MiniBossKillOne or false
			sf.MiniBossKillTwo.Value = data2.MiniBossKillTwo or false
			sf.MiniBossKillThree.Value = data2.MiniBossKillThree or false
			sf.MiniBossKillFourth.Value = data2.MiniBossKillFourth or false
			sf.MiniBossKillFifth.Value = data2.MiniBossKillFifth or false
			sf.CurrentDamagedKey.Value = data2.CurrentDamagedKey or 0
			sf.CurrentRefinedKey.Value = data2.CurrentRefinedKey or 0
			plr:SetAttribute("SunfireLoaded", true)
		end
	end)
	
	while task.wait(60) do
		local success2, err2
		local sunfireprogress = plr:FindFirstChild("sunfireprogress")
		local character = plr.Character
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

		if sunfireprogress and MainDataStore then

			local dataToSave = {
				--HighScore = leaderstats.HighScore.Value,
				CurrentWaterLevel = sunfireprogress.CurrentWaterLevel.Value,
				MaxWaterLevel = sunfireprogress.MaxWaterLevel.Value,
				WaterBasinOne = sunfireprogress.WaterBasinOne.Value,
				WaterBasinTwo = sunfireprogress.WaterBasinTwo.Value,
				WaterBasinThree = sunfireprogress.WaterBasinThree.Value,
				WaterBasinFourth = sunfireprogress.WaterBasinFourth.Value,
				WaterBasinFifth = sunfireprogress.WaterBasinFifth.Value
			}

			--x3 magta-try magsave
			for i = 1, 3 do
				success2, err2 = MainDataStore.SaveSunfireProgress(plr.UserId, dataToSave)
				if success2 then break end
				task.wait(2)
			end

		else
			warn("MainDataStore not available, cannot save player data for " .. plr.Name)
		end
	end
	
end)

local function saveSunfireProgress(plr)
	local success2, err2
	local sunfireprogress = plr:FindFirstChild("sunfireprogress")
	local character = plr.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

	if sunfireprogress and MainDataStore then

		local dataToSave = {
			--HighScore = leaderstats.HighScore.Value,
			CurrentWaterLevel = sunfireprogress.CurrentWaterLevel.Value,
			MaxWaterLevel = sunfireprogress.MaxWaterLevel.Value,
			WaterBasinOne = sunfireprogress.WaterBasinOne.Value,
			WaterBasinTwo = sunfireprogress.WaterBasinTwo.Value,
			WaterBasinThree = sunfireprogress.WaterBasinThree.Value,
			WaterBasinFourth = sunfireprogress.WaterBasinFourth.Value,
			WaterBasinFifth = sunfireprogress.WaterBasinFifth.Value
		}

		--x3 magta-try magsave
		for i = 1, 3 do
			success2, err2 = MainDataStore.SaveSunfireProgress(plr.UserId, dataToSave)
			if success2 then break end
			task.wait(2)
		end

	else
		warn("MainDataStore not available, cannot save player data for " .. plr.Name)
	end
end

game.Players.PlayerRemoving:Connect(function(plr)
	saveSunfireProgress(plr)
end)