local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- RemoteEvent for dev stat changes
local DevStatEvent = ReplicatedStorage:WaitForChild("DevStatEvent", 10)

-- Wait for player and leaderstats
local leaderstats = player:WaitForChild("leaderstats")

-- Wait for config (optional, for base stats display)
local ServerConfigs = ReplicatedStorage:WaitForChild("SlavkosConfigs", 10)
local BaseStats = nil
local ConfigModule = nil
if ServerConfigs then
	local success, config = pcall(function()
		return require(ServerConfigs)
	end)
	if success then
		BaseStats = config.BaseStats
		ConfigModule = config
	end
end

-- Available classes
local AvailableClasses = {"Knight", "Samurai", "Gladiator", "Brawler", "Archer"}

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevStatsDisplay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame in bottom right corner
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 700)
mainFrame.Position = UDim2.new(1, -360, 1, -710)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.3
mainFrame.Parent = screenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title (draggable handle)
local title = Instance.new("TextButton")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "📊 DEV STATS (Drag to Move)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.AutoButtonColor = false
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Make title draggable
local isDragging = false
title.MouseButton1Down:Connect(function()
	isDragging = true
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
		local mousePos = UserInputService:GetMouseLocation()
		local newPos = UDim2.new(0, mousePos.X - mainFrame.AbsoluteSize.X/2, 0, mousePos.Y - mainFrame.AbsoluteSize.Y/2)
		mainFrame.Position = newPos
	end
end)

-- Scrolling frame for all stats
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "StatsScroll"
scrollFrame.Size = UDim2.new(1, -10, 1, -220)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = mainFrame

-- UI List Layout
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- Control buttons frame at bottom
local controlFrame = Instance.new("Frame")
controlFrame.Name = "Controls"
controlFrame.Size = UDim2.new(1, -10, 0, 180)
controlFrame.Position = UDim2.new(0, 5, 1, -185)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = mainFrame

local controlLayout = Instance.new("UIGridLayout")
controlLayout.CellSize = UDim2.new(0.49, 0, 0, 25)
controlLayout.CellPadding = UDim2.new(0.01, 0, 0.02, 0)
controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
controlLayout.FillDirection = Enum.FillDirection.Horizontal
controlLayout.Parent = controlFrame

-- Function to create a button
local function createButton(text, color, layoutOrder, onClick)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = layoutOrder
	button.Parent = controlFrame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = button
	
	button.MouseButton1Click:Connect(onClick)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
	end)
	
	return button
end

-- Function to create a stat row with better spacing
local function createStatRow(statName, value, color, layoutOrder)
	local statFrame = Instance.new("Frame")
	statFrame.Name = HttpService:GenerateGUID(false)
	statFrame.Size = UDim2.new(1, -10, 0, 22)
	statFrame.BackgroundTransparency = 1
	statFrame.LayoutOrder = layoutOrder
	statFrame.Parent = scrollFrame
	
	local statNameLabel = Instance.new("TextLabel")
	statNameLabel.Name = "Name"
	statNameLabel.Size = UDim2.new(0.65, -5, 1, 0)
	statNameLabel.Position = UDim2.new(0, 5, 0, 0)
	statNameLabel.BackgroundTransparency = 1
	statNameLabel.Text = statName .. ":"
	statNameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statNameLabel.TextSize = 12
	statNameLabel.Font = Enum.Font.Gotham
	statNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	statNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	statNameLabel.Parent = statFrame
	
	local statValueLabel = Instance.new("TextLabel")
	statValueLabel.Name = "Value"
	statValueLabel.Size = UDim2.new(0.35, -5, 1, 0)
	statValueLabel.Position = UDim2.new(0.65, 5, 0, 0)
	statValueLabel.BackgroundTransparency = 1
	statValueLabel.Text = tostring(value)
	statValueLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	statValueLabel.TextSize = 12
	statValueLabel.Font = Enum.Font.GothamBold
	statValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	statValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	statValueLabel.Parent = statFrame
	
	return statValueLabel
end

-- Color coding
local function getStatColor(statName)
	local colors = {
		Level = Color3.fromRGB(255, 215, 0),
		CurrentXP = Color3.fromRGB(100, 200, 255),
		MaximumXP = Color3.fromRGB(100, 200, 255),
		MaxHealth = Color3.fromRGB(255, 100, 100),
		MaxAttack = Color3.fromRGB(255, 150, 100),
		MaxDefense = Color3.fromRGB(100, 150, 255),
		DefensePenetration = Color3.fromRGB(255, 150, 200),  -- Pink for DP
		HealthRegen = Color3.fromRGB(100, 255, 150),          -- Green for Health Regen
		Slavkoins = Color3.fromRGB(255, 215, 0)
	}
	return colors[statName] or Color3.fromRGB(255, 255, 255)
end

-- Track stat labels
local statLabels = {}

-- Initialize stat display
local function updateStatsDisplay()
	-- Clear existing stats (keep only UIListLayout)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and (child:IsA("Frame") or child:IsA("TextLabel")) then
			child:Destroy()
		end
	end
	statLabels = {}
	
	local layoutOrder = 1
	
	-- Display live stats first
	local liveHeader = Instance.new("TextLabel")
	liveHeader.Name = "LiveHeader"
	liveHeader.Size = UDim2.new(1, -10, 0, 25)
	liveHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	liveHeader.BorderSizePixel = 0
	liveHeader.Text = "LIVE STATS"
	liveHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	liveHeader.TextSize = 11
	liveHeader.Font = Enum.Font.GothamBold
	liveHeader.LayoutOrder = layoutOrder
	liveHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Display live stats from leaderstats
	if leaderstats:FindFirstChild("Level") then
		statLabels["Level"] = createStatRow("Level", leaderstats.Level.Value, getStatColor("Level"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("CurrentXP") and leaderstats:FindFirstChild("MaximumXP") then
		local xpText = string.format("%d / %d", leaderstats.CurrentXP.Value, leaderstats.MaximumXP.Value)
		statLabels["CurrentXP"] = createStatRow("XP", xpText, getStatColor("CurrentXP"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("Class") then
		statLabels["Class"] = createStatRow("Class", leaderstats.Class.Value, Color3.fromRGB(255, 255, 255), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("MaxHealth") then
		statLabels["MaxHealth"] = createStatRow("HP", leaderstats.MaxHealth.Value, getStatColor("MaxHealth"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("MaxAttack") then
		statLabels["MaxAttack"] = createStatRow("Attack", leaderstats.MaxAttack.Value, getStatColor("MaxAttack"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("MaxDefense") then
		statLabels["MaxDefense"] = createStatRow("Defense", leaderstats.MaxDefense.Value, getStatColor("MaxDefense"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("DefensePenetration") then
		statLabels["DefensePenetration"] = createStatRow("DP", leaderstats.DefensePenetration.Value, getStatColor("DefensePenetration"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("CritRate") then
		statLabels["CritRate"] = createStatRow("Crit Rate", leaderstats.CritRate.Value, Color3.fromRGB(255, 255, 255), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("CritMultiplier") then
		statLabels["CritMultiplier"] = createStatRow("Crit Mult", leaderstats.CritMultiplier.Value, Color3.fromRGB(255, 255, 255), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("HealthRegen") then
		statLabels["HealthRegen"] = createStatRow("Health Regen", leaderstats.HealthRegen.Value, getStatColor("HealthRegen"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("MovementSpeed") then
		statLabels["MovementSpeed"] = createStatRow("Move Speed", leaderstats.MovementSpeed.Value, Color3.fromRGB(255, 255, 255), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("AttackSpeed") then
		statLabels["AttackSpeed"] = createStatRow("Atk Speed", leaderstats.AttackSpeed.Value, Color3.fromRGB(255, 255, 255), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("Slavkoins") then
		statLabels["Slavkoins"] = createStatRow("Slavkoins", leaderstats.Slavkoins.Value, getStatColor("Slavkoins"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	-- Add divider
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -10, 0, 2)
	divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	divider.BorderSizePixel = 0
	divider.LayoutOrder = layoutOrder
	divider.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Base Stats header
	local baseHeader = Instance.new("TextLabel")
	baseHeader.Name = "BaseHeader"
	baseHeader.Size = UDim2.new(1, -10, 0, 25)
	baseHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	baseHeader.BorderSizePixel = 0
	baseHeader.Text = "BASE STATS (Config)"
	baseHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	baseHeader.TextSize = 11
	baseHeader.Font = Enum.Font.GothamBold
	baseHeader.LayoutOrder = layoutOrder
	baseHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Display base stats from config if available
	if BaseStats and leaderstats:FindFirstChild("Class") then
		local className = leaderstats.Class.Value
		local classStats = BaseStats[className]
		
		if classStats then
			statLabels["BaseHP"] = createStatRow("Base HP", classStats.HP, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseAttack"] = createStatRow("Base ATK", classStats.ATK, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseDefense"] = createStatRow("Base DEF", classStats.D, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseDP"] = createStatRow("Base DP", classStats.DP or 0, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseCR"] = createStatRow("Base CR", classStats.CR or 5, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseCM"] = createStatRow("Base CM", classStats.CM or 150, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseHR"] = createStatRow("Base HR", classStats.HR or 0, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseMspd"] = createStatRow("Base Mspd", classStats.Mspd or 18, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
			
			statLabels["BaseAspd"] = createStatRow("Base Aspd", classStats.Aspd or 1, Color3.fromRGB(100, 255, 100), layoutOrder)
			layoutOrder = layoutOrder + 1
		end
	end
	
	-- Add divider
	local divider2 = Instance.new("Frame")
	divider2.Size = UDim2.new(1, -10, 0, 2)
	divider2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	divider2.BorderSizePixel = 0
	divider2.LayoutOrder = layoutOrder
	divider2.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Calculated Damage header
	local damageHeader = Instance.new("TextLabel")
	damageHeader.Name = "DamageHeader"
	damageHeader.Size = UDim2.new(1, -10, 0, 25)
	damageHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	damageHeader.BorderSizePixel = 0
	damageHeader.Text = "CALCULATED DAMAGE (Current MaxAttack)"
	damageHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	damageHeader.TextSize = 11
	damageHeader.Font = Enum.Font.GothamBold
	damageHeader.LayoutOrder = layoutOrder
	damageHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Display calculated damage values
	if ConfigModule and ConfigModule.Hitboxes and ConfigModule.Hitboxes.UnifiedAttacks and leaderstats:FindFirstChild("Class") and leaderstats:FindFirstChild("MaxAttack") then
		local className = leaderstats.Class.Value
		local maxAttack = leaderstats.MaxAttack.Value
		
		-- Skip if class is Slavkorian (no damage config for Slavkorian)
		if className == "Slavkorian" then
			local noDamageLabel = Instance.new("TextLabel")
			noDamageLabel.Name = "NoDamageLabel"
			noDamageLabel.Size = UDim2.new(1, -10, 0, 20)
			noDamageLabel.BackgroundTransparency = 1
			noDamageLabel.Text = "Select a class to see damage"
			noDamageLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			noDamageLabel.TextSize = 11
			noDamageLabel.Font = Enum.Font.Gotham
			noDamageLabel.LayoutOrder = layoutOrder
			noDamageLabel.Parent = scrollFrame
			layoutOrder = layoutOrder + 1
		else
			local classConfig = ConfigModule.Hitboxes.UnifiedAttacks[className]
			
			if classConfig and maxAttack > 0 then
				-- Get CritMultiplier for crit damage calculation
				local critMultiplier = 150 -- Default
				if leaderstats:FindFirstChild("CritMultiplier") then
					critMultiplier = leaderstats.CritMultiplier.Value
				end
				
				-- Normal attack damage
				local normalMultiplier = classConfig.damage or 0
				local normalDamage = math.floor(maxAttack * normalMultiplier)
				local normalCritDamage = math.floor(normalDamage * (critMultiplier / 100))
				statLabels["DamageNormal"] = createStatRow("Normal Attack", normalDamage .. " (Crit: " .. normalCritDamage .. ")", Color3.fromRGB(255, 200, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
				
				-- Skill 1 damage
				if classConfig.skill1Damage then
					local skill1Multiplier = classConfig.skill1Damage
					local skill1Damage = math.floor(maxAttack * skill1Multiplier)
					local skill1CritDamage = math.floor(skill1Damage * (critMultiplier / 100))
					statLabels["DamageSkill1"] = createStatRow("Skill 1", skill1Damage .. " (Crit: " .. skill1CritDamage .. ")", Color3.fromRGB(200, 150, 255), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
				
				-- Skill 2 damage
				if classConfig.skill2Damage then
					local skill2Multiplier = classConfig.skill2Damage
					local skill2Damage = math.floor(maxAttack * skill2Multiplier)
					local skill2CritDamage = math.floor(skill2Damage * (critMultiplier / 100))
					statLabels["DamageSkill2"] = createStatRow("Skill 2", skill2Damage .. " (Crit: " .. skill2CritDamage .. ")", Color3.fromRGB(200, 150, 255), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
				
				-- Ult damage
				if classConfig.ultDamage then
					local ultMultiplier = classConfig.ultDamage
					local ultDamage = math.floor(maxAttack * ultMultiplier)
					local ultCritDamage = math.floor(ultDamage * (critMultiplier / 100))
					statLabels["DamageUlt"] = createStatRow("Ultimate", ultDamage .. " (Crit: " .. ultCritDamage .. ")", Color3.fromRGB(255, 100, 100), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			else
				-- Class config exists but MaxAttack is 0 or invalid
				local noDamageLabel = Instance.new("TextLabel")
				noDamageLabel.Name = "NoDamageLabel"
				noDamageLabel.Size = UDim2.new(1, -10, 0, 20)
				noDamageLabel.BackgroundTransparency = 1
				noDamageLabel.Text = "Waiting for stats to initialize..."
				noDamageLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				noDamageLabel.TextSize = 11
				noDamageLabel.Font = Enum.Font.Gotham
				noDamageLabel.LayoutOrder = layoutOrder
				noDamageLabel.Parent = scrollFrame
				layoutOrder = layoutOrder + 1
			end
		end
	end
	
	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, (layoutOrder - 1) * 27)
end

-- Function to update calculated damage values without rebuilding entire display
local function updateCalculatedDamage()
	if not ConfigModule or not ConfigModule.Hitboxes or not ConfigModule.Hitboxes.UnifiedAttacks then
		return
	end
	
	if not leaderstats:FindFirstChild("Class") or not leaderstats:FindFirstChild("MaxAttack") then
		return
	end
	
	local className = leaderstats.Class.Value
	local maxAttack = leaderstats.MaxAttack.Value
	local classConfig = ConfigModule.Hitboxes.UnifiedAttacks[className]
	
	if not classConfig or maxAttack <= 0 then
		return
	end
	
	-- Get CritMultiplier for crit damage calculation
	local critMultiplier = 150 -- Default
	if leaderstats:FindFirstChild("CritMultiplier") then
		critMultiplier = leaderstats.CritMultiplier.Value
	end
	
	-- Update Normal Attack damage
	if statLabels["DamageNormal"] then
		local normalMultiplier = classConfig.damage or 0
		local normalDamage = math.floor(maxAttack * normalMultiplier)
		local normalCritDamage = math.floor(normalDamage * (critMultiplier / 100))
		statLabels["DamageNormal"].Text = normalDamage .. " (Crit: " .. normalCritDamage .. ")"
	end
	
	-- Update Skill 1 damage
	if statLabels["DamageSkill1"] and classConfig.skill1Damage then
		local skill1Multiplier = classConfig.skill1Damage
		local skill1Damage = math.floor(maxAttack * skill1Multiplier)
		local skill1CritDamage = math.floor(skill1Damage * (critMultiplier / 100))
		statLabels["DamageSkill1"].Text = skill1Damage .. " (Crit: " .. skill1CritDamage .. ")"
	end
	
	-- Update Skill 2 damage
	if statLabels["DamageSkill2"] and classConfig.skill2Damage then
		local skill2Multiplier = classConfig.skill2Damage
		local skill2Damage = math.floor(maxAttack * skill2Multiplier)
		local skill2CritDamage = math.floor(skill2Damage * (critMultiplier / 100))
		statLabels["DamageSkill2"].Text = skill2Damage .. " (Crit: " .. skill2CritDamage .. ")"
	end
	
	-- Update Ult damage
	if statLabels["DamageUlt"] and classConfig.ultDamage then
		local ultMultiplier = classConfig.ultDamage
		local ultDamage = math.floor(maxAttack * ultMultiplier)
		local ultCritDamage = math.floor(ultDamage * (critMultiplier / 100))
		statLabels["DamageUlt"].Text = ultDamage .. " (Crit: " .. ultCritDamage .. ")"
	end
end

-- UI Hidden state
local isVisible = true

-- Control buttons
local buttonLayoutOrder = 1

-- Row 1: Control buttons
-- Hide/Show button
createButton("👁️ Hide", Color3.fromRGB(60, 60, 60), buttonLayoutOrder, function()
	isVisible = not isVisible
	mainFrame.Visible = isVisible
end)
buttonLayoutOrder = buttonLayoutOrder + 1

-- Reset button - resets everything to defaults (level 1, XP 0, base stats)
createButton("Reset", Color3.fromRGB(150, 50, 50), buttonLayoutOrder, function()
	if DevStatEvent then
		-- Use fullReset action which handles everything in the correct order
		DevStatEvent:FireServer("fullReset")
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

-- Row 2: XP buttons
-- Add 5 XP button
createButton("+5 XP", Color3.fromRGB(50, 150, 50), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("addCurrentXP", 5)
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

-- Add 10 XP button
createButton("+10 XP", Color3.fromRGB(50, 180, 50), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("addCurrentXP", 10)
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

-- Row 3: Class selection buttons
createButton("Knight", Color3.fromRGB(100, 150, 200), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("setClass", "Knight")
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

createButton("Samurai", Color3.fromRGB(150, 150, 150), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("setClass", "Samurai")
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

createButton("Gladiator", Color3.fromRGB(200, 100, 100), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("setClass", "Gladiator")
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

createButton("Brawler", Color3.fromRGB(150, 100, 50), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("setClass", "Brawler")
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

createButton("Archer", Color3.fromRGB(100, 200, 100), buttonLayoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("setClass", "Archer")
	end
end)
buttonLayoutOrder = buttonLayoutOrder + 1

-- Track connections to prevent duplicates
local statConnections = {}

-- Connect to stat changes for real-time updates
local function setupStatConnections()
	-- Clear old connections
	for _, connection in pairs(statConnections) do
		connection:Disconnect()
	end
	statConnections = {}
	
	-- Connect to all leaderstats changes
	for _, stat in ipairs(leaderstats:GetChildren()) do
		if stat:IsA("ValueBase") then
			local conn = stat:GetPropertyChangedSignal("Value"):Connect(function()
				if stat.Name == "CurrentXP" and statLabels["CurrentXP"] and leaderstats:FindFirstChild("MaximumXP") then
					statLabels["CurrentXP"].Text = string.format("%d / %d", stat.Value, leaderstats.MaximumXP.Value)
				elseif statLabels[stat.Name] then
					statLabels[stat.Name].Text = tostring(stat.Value)
				end
				
				-- Update calculated damage when MaxAttack or CritMultiplier changes
				-- Note: Class changes are handled separately with full display refresh
				if stat.Name == "MaxAttack" or stat.Name == "CritMultiplier" then
					updateCalculatedDamage()
				end
			end)
			statConnections[stat] = conn
		end
	end
	
	-- Special handling for class change to refresh base stats
	if leaderstats:FindFirstChild("Class") then
		local conn = leaderstats.Class:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1) -- Small delay to let server update complete
			updateStatsDisplay() -- Force full refresh when class changes
		end)
		statConnections[leaderstats.Class] = conn
	end
end

-- Reconnect when player respawns
player.CharacterAdded:Connect(function()
	task.wait(1)
	updateStatsDisplay()
end)

-- Initial setup
updateStatsDisplay()
setupStatConnections()

-- Keybind to toggle visibility
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.PageDown then
		isVisible = not isVisible
		mainFrame.Visible = isVisible
	end
end)

-- Class switching via Pick Class button prints to console
-- Use the button to see available classes and follow the printed instructions
