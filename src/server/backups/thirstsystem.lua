local TS = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local WaterGUI = PlayerGui:WaitForChild("WaterGui")
local WaterText = WaterGUI.Background:WaitForChild("WaterText")
local thirstText = WaterGUI.Background.WaterFrame.waterBackground.WaterStatus
local bar = WaterGUI.Background.WaterFrame.waterBackground.bar

local caveThirst = workspace.Tickbox:WaitForChild("CaveThirst")
local playersTouching = {}

-- Thirst settings
local thirstDamage = 1
local thirstInterval = 1
local activeThirstConnection = nil
local thirstLoopRunning = false

-- Function to get updated stats every respawn
local function getSunfireStats()
	local sunfireprogress = player:WaitForChild("sunfireprogress")
	return {
		current = sunfireprogress:WaitForChild("CurrentWaterLevel"),
		max = sunfireprogress:WaitForChild("MaxWaterLevel"),
		basins = {
			sunfireprogress:WaitForChild("WaterBasinOne"),
			sunfireprogress:WaitForChild("WaterBasinTwo"),
			sunfireprogress:WaitForChild("WaterBasinThree"),
			sunfireprogress:WaitForChild("WaterBasinFourth"),
			sunfireprogress:WaitForChild("WaterBasinFifth")
		}
	}
end

-- Function to update GUI
local function updateWaterUI(currentWaterLevel, maxWaterLevel, humanoid)
	local ratio = math.clamp(currentWaterLevel.Value / maxWaterLevel.Value, 0, 1)
	local percent = ratio * 100
	WaterText.Text = string.format("%d / %d", currentWaterLevel.Value, maxWaterLevel.Value)

	if percent >= 70 then
		thirstText.Text = "Hydrated"
		thirstText.TextColor3 = Color3.fromRGB(0, 255, 0)
	elseif percent >= 40 then
		thirstText.Text = "Thirsty"
		thirstText.TextColor3 = Color3.fromRGB(255, 255, 0)
	elseif percent >= 10 then
		thirstText.Text = "Danger"
		thirstText.TextColor3 = Color3.fromRGB(255, 128, 0)
	elseif currentWaterLevel.Value == 0 then
		thirstText.Text = "Dehydrated"
		thirstText.TextColor3 = Color3.fromRGB(255, 0, 0)
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end

	local targetSize = UDim2.new(ratio, 0, 1, 0)
	TS:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = targetSize }):Play()
end

-- Function to update basin icons
local function updateWaterBasin(basins, icons)
	for i, basin in ipairs(basins) do
		if basin.Value then
			icons[i].Visible = true
		end
	end
end

-- Function to start thirst system
local function startThirstSystem(character)
	local humanoid = character:WaitForChild("Humanoid")
	local stats = getSunfireStats()
	local currentWaterLevel, maxWaterLevel = stats.current, stats.max
	local basins = stats.basins

	local icons = {
		WaterGUI.Background:WaitForChild("WaterBasin1"),
		WaterGUI.Background:WaitForChild("WaterBasin2"),
		WaterGUI.Background:WaitForChild("WaterBasin3"),
		WaterGUI.Background:WaitForChild("WaterBasin4"),
		WaterGUI.Background:WaitForChild("WaterBasin5"),
	}

	-- Reset to full water when respawn
	currentWaterLevel.Value = maxWaterLevel.Value
	updateWaterUI(currentWaterLevel, maxWaterLevel, humanoid)
	updateWaterBasin(basins, icons)

	-- Prevent multiple loops
	if thirstLoopRunning then return end
	thirstLoopRunning = true

	-- Cave logic
	caveThirst.Touched:Connect(function(hit)
		local h = hit.Parent:FindFirstChild("Humanoid")
		if h and not playersTouching[h] then
			playersTouching[h] = true
			thirstDamage = 2
		end
	end)

	caveThirst.TouchEnded:Connect(function(hit)
		local h = hit.Parent:FindFirstChild("Humanoid")
		if h and playersTouching[h] then
			playersTouching[h] = nil
			thirstDamage = 1
		end
	end)

	-- Loop to reduce thirst
	task.spawn(function()
		while humanoid.Health > 0 do
			task.wait(thirstInterval)
			if currentWaterLevel.Value > 0 then
				currentWaterLevel.Value = math.max(0, currentWaterLevel.Value - thirstDamage)
			else
				updateWaterUI(currentWaterLevel, maxWaterLevel, humanoid)
				break
			end
		end
		thirstLoopRunning = false
	end)

	-- Reconnect listeners
	currentWaterLevel.Changed:Connect(function()
		updateWaterUI(currentWaterLevel, maxWaterLevel, humanoid)
		updateWaterBasin(basins, icons)
	end)

	maxWaterLevel.Changed:Connect(function()
		updateWaterUI(currentWaterLevel, maxWaterLevel, humanoid)
		updateWaterBasin(basins, icons)
	end)
end

-- Respawn listener
player.CharacterAdded:Connect(function(character)
	task.wait(1)
	startThirstSystem(character)
end)

-- Initial spawn
if player.Character then
	task.wait(1)
	startThirstSystem(player.Character)
end
