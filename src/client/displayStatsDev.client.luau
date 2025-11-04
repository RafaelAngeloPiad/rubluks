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
		local healthText = leaderstats.MaxHealth.Value
		
		-- Try to get current health from humanoid
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			local currentHealth = humanoid.Health
			local maxHealth = humanoid.MaxHealth
			healthText = string.format("%.0f / %.0f", currentHealth, maxHealth)
		else
			-- No character yet, just show max health
			healthText = tostring(leaderstats.MaxHealth.Value)
		end
		statLabels["MaxHealth"] = createStatRow("HP", healthText, getStatColor("MaxHealth"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("MaxAttack") then
		local attackText = tostring(leaderstats.MaxAttack.Value)
		statLabels["MaxAttack"] = createStatRow("Attack", attackText, getStatColor("MaxAttack"), layoutOrder)
		layoutOrder = layoutOrder + 1
	end
	
	if leaderstats:FindFirstChild("MaxDefense") then
		local defenseText = leaderstats.MaxDefense.Value
		
		-- Add current defense if it exists
		if leaderstats:FindFirstChild("CurrentDefense") then
			local currentDef = leaderstats.CurrentDefense.Value
			local maxDef = leaderstats.MaxDefense.Value
			defenseText = string.format("%.0f / %.0f", currentDef, maxDef)
		else
			-- No current defense, just show max
			defenseText = tostring(leaderstats.MaxDefense.Value)
		end
		statLabels["MaxDefense"] = createStatRow("Defense", defenseText, getStatColor("MaxDefense"), layoutOrder)
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
	
	-- Buffs and Passives header
	local buffsPassivesHeader = Instance.new("TextLabel")
	buffsPassivesHeader.Name = "BuffsPassivesHeader"
	buffsPassivesHeader.Size = UDim2.new(1, -10, 0, 25)
	buffsPassivesHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	buffsPassivesHeader.BorderSizePixel = 0
	buffsPassivesHeader.Text = "BUFFS AND PASSIVES"
	buffsPassivesHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	buffsPassivesHeader.TextSize = 11
	buffsPassivesHeader.Font = Enum.Font.GothamBold
	buffsPassivesHeader.LayoutOrder = layoutOrder
	buffsPassivesHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Get base stats folder for calculating bonuses
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	local baseMaxAttack = baseStatsFolder and baseStatsFolder:FindFirstChild("BaseMaxAttack")
	local baseMaxDefense = baseStatsFolder and baseStatsFolder:FindFirstChild("BaseMaxDefense")
	local baseMaxHealth = baseStatsFolder and baseStatsFolder:FindFirstChild("BaseMaxHealth")
	
	-- Get current stats
	local currentMaxAttack = leaderstats:FindFirstChild("MaxAttack") and leaderstats.MaxAttack.Value or 0
	local currentMaxDefense = leaderstats:FindFirstChild("MaxDefense") and leaderstats.MaxDefense.Value or 0
	local currentMaxHealth = leaderstats:FindFirstChild("MaxHealth") and leaderstats.MaxHealth.Value or 0
	
	-- Calculate bonuses
	local baseATK = baseMaxAttack and baseMaxAttack.Value or currentMaxAttack
	local baseDEF = baseMaxDefense and baseMaxDefense.Value or currentMaxDefense
	local baseHP = baseMaxHealth and baseMaxHealth.Value or currentMaxHealth
	
	local attackBonus = currentMaxAttack - baseATK
	local defenseBonus = currentMaxDefense - baseDEF
	local healthBonus = currentMaxHealth - baseHP
	
	-- Get active buffs and passives
	local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	local hasBuffsOrPassives = false
	
	-- Display active buffs with their contributions
	if activeBuffs and activeBuffs.Value ~= "" then
		-- Parse active buffs
		for buffName in string.gmatch(activeBuffs.Value, "([^,]+)") do
			buffName = buffName:match("^%s*(.-)%s*$") -- Trim whitespace
			
			if buffName == "Warcry" then
				hasBuffsOrPassives = true
				-- Calculate Warcry bonuses
				local warcryAttackBonus = 0
				local warcryDefenseBonus = 0
				
				-- Get current level to calculate multiplier
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.KnightBuffs then
					local buffConfig = ConfigModule.getBuffConfig("Warcry", level.Value)
					if buffConfig then
						-- Get base attack and defense from BaseStats (if available)
						if baseMaxAttack and baseMaxDefense then
							-- Calculate what Warcry adds (multiplier-based)
							local baseATK = baseMaxAttack.Value
							local baseDEF = baseMaxDefense.Value
							warcryAttackBonus = math.floor(baseATK * buffConfig.attackMultiplier) - baseATK
							warcryDefenseBonus = math.floor(baseDEF * buffConfig.defenseMultiplier) - baseDEF
						else
							-- Fallback: Calculate from current stats (if BaseStats not available yet)
							-- This shouldn't happen normally, but handle it gracefully
							local currentMaxAttack = leaderstats:FindFirstChild("MaxAttack") and leaderstats.MaxAttack.Value or 0
							local currentMaxDefense = leaderstats:FindFirstChild("MaxDefense") and leaderstats.MaxDefense.Value or 0
							-- Estimate base by reversing the multiplier
							local estimatedBaseATK = math.floor(currentMaxAttack / buffConfig.attackMultiplier)
							local estimatedBaseDEF = math.floor(currentMaxDefense / buffConfig.defenseMultiplier)
							warcryAttackBonus = currentMaxAttack - estimatedBaseATK
							warcryDefenseBonus = currentMaxDefense - estimatedBaseDEF
						end
					end
				end
				
				-- Display stat bonus (separate from timer)
				local buffText = ""
				if warcryAttackBonus > 0 and warcryDefenseBonus > 0 then
					buffText = string.format("+%.0f ATK, +%.0f DEF", warcryAttackBonus, warcryDefenseBonus)
				elseif warcryAttackBonus > 0 then
					buffText = string.format("+%.0f ATK", warcryAttackBonus)
				elseif warcryDefenseBonus > 0 then
					buffText = string.format("+%.0f DEF", warcryDefenseBonus)
				else
					buffText = "Active"
				end
				
				statLabels["Buff_Warcry"] = createStatRow("Warcry", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
				
				-- Display timer separately (if available)
				local buffDurations = leaderstats:FindFirstChild("BuffDurations")
				if buffDurations then
					local buffDuration = buffDurations:FindFirstChild(buffName)
					if buffDuration then
						local remaining = math.max(0, math.floor(buffDuration.Value))
						local minutes = math.floor(remaining / 60)
						local seconds = remaining % 60
						local durationText = ""
						
						if minutes > 0 then
							durationText = string.format("%dm %ds", minutes, seconds)
						else
							durationText = string.format("%ds", seconds)
						end
						
						statLabels["Buff_Warcry_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "WarriorMight" then
				hasBuffsOrPassives = true
				-- Calculate WarriorMight bonus
				local warriorMightHealthBonus = 0
				
				-- Get current level to calculate HP increase
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.KnightBuffs then
					local buffConfig = ConfigModule.getBuffConfig("WarriorMight", level.Value)
					if buffConfig then
						-- WarriorMight adds flat HP - use config directly
						warriorMightHealthBonus = buffConfig.hpIncrease
					end
				end
				
				-- Display stat bonus (separate from timer)
				local buffText = ""
				if warriorMightHealthBonus > 0 then
					buffText = string.format("+%.0f HP", warriorMightHealthBonus)
				else
					buffText = "Active"
				end
				
				statLabels["Buff_WarriorMight"] = createStatRow("Warrior's Might", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
				
				-- Display timer separately (if available)
				local buffDurations = leaderstats:FindFirstChild("BuffDurations")
				if buffDurations then
					local buffDuration = buffDurations:FindFirstChild(buffName)
					if buffDuration then
						local remaining = math.max(0, math.floor(buffDuration.Value))
						local minutes = math.floor(remaining / 60)
						local seconds = remaining % 60
						local durationText = ""
						
						if minutes > 0 then
							durationText = string.format("%dm %ds", minutes, seconds)
						else
							durationText = string.format("%ds", seconds)
						end
						
						statLabels["Buff_WarriorMight_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "BloodThirst" then
				hasBuffsOrPassives = true
				-- Calculate BloodThirst lifesteal percentage
				local bloodThirstLifesteal = 0
				
				-- Get current level to get lifesteal percentage
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.BrawlerBuffs then
					local buffConfig = ConfigModule.getBuffConfig("BloodThirst", level.Value)
					if buffConfig then
						-- BloodThirst provides lifesteal percentage
						bloodThirstLifesteal = buffConfig.lifestealPercentage
					end
				end
				
				-- Display lifesteal percentage (separate from timer)
				local buffText = ""
				if bloodThirstLifesteal > 0 then
					local lifestealPercent = math.floor(bloodThirstLifesteal * 100)
					buffText = string.format("%d%% Lifesteal", lifestealPercent)
				else
					buffText = "Active"
				end
				
				statLabels["Buff_BloodThirst"] = createStatRow("Blood Thirst", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
				
				-- Display timer separately (if available)
				local buffDurations = leaderstats:FindFirstChild("BuffDurations")
				if buffDurations then
					local buffDuration = buffDurations:FindFirstChild(buffName)
					if buffDuration then
						local remaining = math.max(0, math.floor(buffDuration.Value))
						local minutes = math.floor(remaining / 60)
						local seconds = remaining % 60
						local durationText = ""
						
						if minutes > 0 then
							durationText = string.format("%dm %ds", minutes, seconds)
						else
							durationText = string.format("%ds", seconds)
						end
						
						statLabels["Buff_BloodThirst_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "LastChance" then
				hasBuffsOrPassives = true
				-- Calculate LastChance status immunity and HP regen
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.BrawlerBuffs then
					local buffConfig = ConfigModule.getBuffConfig("LastChance", level.Value)
					if buffConfig then
						-- LastChance provides status immunity and HP regen
						local hpRegenPercentage = buffConfig.hpRegenPercentage or 0
						local immunityDuration = buffConfig.immunityDuration or 0
						local hpRegenPercent = math.floor(hpRegenPercentage * 100)
						local buffText = string.format("%d%% HP/s, %ds Immunity", hpRegenPercent, immunityDuration)
						
						statLabels["Buff_LastChance"] = createStatRow("Last Chance", buffText, Color3.fromRGB(255, 200, 100), layoutOrder)
						layoutOrder = layoutOrder + 1
						
						-- Display timer separately (if available)
						local buffDurations = leaderstats:FindFirstChild("BuffDurations")
						if buffDurations then
							local buffDuration = buffDurations:FindFirstChild(buffName)
							if buffDuration then
								local remaining = math.max(0, math.floor(buffDuration.Value))
								local minutes = math.floor(remaining / 60)
								local seconds = remaining % 60
								local durationText = ""
								
								if minutes > 0 then
									durationText = string.format("%dm %ds", minutes, seconds)
								else
									durationText = string.format("%ds", seconds)
								end
								
								statLabels["Buff_LastChance_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
								layoutOrder = layoutOrder + 1
							end
						end
					end
				end
			end
		end
	end
	
	-- Display active passives with their contributions
	if activePassives and activePassives.Value ~= "" then
		-- Parse active passives
		for passiveName in string.gmatch(activePassives.Value, "([^,]+)") do
			passiveName = passiveName:match("^%s*(.-)%s*$") -- Trim whitespace
			
			if passiveName == "Tenacity" then
				hasBuffsOrPassives = true
				-- Calculate Tenacity bonus
				local tenacityDefenseBonus = 0
				
				-- Get current level to get defense increase
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.KnightPassives then
					local passiveConfig = ConfigModule.getPassiveConfig("Tenacity", level.Value)
					if passiveConfig then
						tenacityDefenseBonus = passiveConfig.defenseIncrease
					end
				end
				
				local passiveText = ""
				if tenacityDefenseBonus > 0 then
					passiveText = string.format("+%.0f DEF", tenacityDefenseBonus)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Tenacity"] = createStatRow("Tenacity", passiveText, Color3.fromRGB(150, 200, 255), layoutOrder)
				layoutOrder = layoutOrder + 1
			end
		end
	end
	
	-- Display unlocked passives (even if not active)
	if leaderstats:FindFirstChild("Class") and leaderstats:FindFirstChild("Level") then
		local className = leaderstats.Class.Value
		local level = leaderstats.Level.Value
		
		-- Only show passives for Knight class
		if className == "Knight" and ConfigModule and ConfigModule.KnightPassives then
			local passivesConfig = ConfigModule.KnightPassives
			
			-- Check Knights Blade passive (unlocks at level 5)
			if passivesConfig.KnightsBlade then
				local knightsBladeLevels = passivesConfig.KnightsBlade.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(knightsBladeLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local knightsBladeConfig = knightsBladeLevels[highestUnlocked]
					local displayName = "Knight's Blade"
					local statusText = string.format("Unlocked (%d%% chance)", knightsBladeConfig.chance)
					
					statLabels["Passive_KnightsBlade"] = createStatRow(displayName, statusText, Color3.fromRGB(150, 200, 255), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
		end
	end
	
	if not hasBuffsOrPassives then
		-- No active buffs or passives
		local noBuffsPassivesLabel = Instance.new("TextLabel")
		noBuffsPassivesLabel.Name = "NoBuffsPassivesLabel"
		noBuffsPassivesLabel.Size = UDim2.new(1, -10, 0, 20)
		noBuffsPassivesLabel.BackgroundTransparency = 1
		noBuffsPassivesLabel.Text = "No active buffs or passives"
		noBuffsPassivesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noBuffsPassivesLabel.TextSize = 11
		noBuffsPassivesLabel.Font = Enum.Font.Gotham
		noBuffsPassivesLabel.LayoutOrder = layoutOrder
		noBuffsPassivesLabel.Parent = scrollFrame
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
					elseif stat.Name == "CurrentDefense" and statLabels["MaxDefense"] and leaderstats:FindFirstChild("MaxDefense") then
						-- Update defense (simple display)
						local currentDef = stat.Value
						local maxDef = leaderstats.MaxDefense.Value
						statLabels["MaxDefense"].Text = string.format("%.0f / %.0f", currentDef, maxDef)
					elseif stat.Name == "MaxDefense" and statLabels["MaxDefense"] then
						-- Update defense (simple display)
						local currentDef = leaderstats:FindFirstChild("CurrentDefense") and leaderstats.CurrentDefense.Value or stat.Value
						local maxDef = stat.Value
						statLabels["MaxDefense"].Text = string.format("%.0f / %.0f", currentDef, maxDef)
					elseif stat.Name == "MaxAttack" and statLabels["MaxAttack"] then
						-- Update attack (simple display)
						statLabels["MaxAttack"].Text = tostring(stat.Value)
						-- Update calculated damage when MaxAttack changes
						updateCalculatedDamage()
					elseif stat.Name == "MaxHealth" and statLabels["MaxHealth"] then
						-- Update health (simple display)
						if player.Character and player.Character:FindFirstChild("Humanoid") then
							local humanoid = player.Character.Humanoid
							local currentHealth = humanoid.Health
							local maxHealth = humanoid.MaxHealth
							statLabels["MaxHealth"].Text = string.format("%.0f / %.0f", currentHealth, maxHealth)
						else
							statLabels["MaxHealth"].Text = tostring(stat.Value)
						end
					elseif statLabels[stat.Name] then
						statLabels[stat.Name].Text = tostring(stat.Value)
					end
					
					-- Update calculated damage when CritMultiplier changes
					-- Note: Class changes are handled separately with full display refresh
					if stat.Name == "CritMultiplier" then
						updateCalculatedDamage()
					end
				end)
				statConnections[stat] = conn
			end
		end
		
		-- Connect to ActiveBuffs changes for real-time buff display updates
		if leaderstats:FindFirstChild("ActiveBuffs") then
			local conn = leaderstats.ActiveBuffs:GetPropertyChangedSignal("Value"):Connect(function()
				task.wait(0.1) -- Small delay to let server update complete
				updateStatsDisplay() -- Refresh display when buffs change (to update buffs and passives section)
			end)
			statConnections["ActiveBuffs"] = conn
		end
		
		-- Connect to ActivePassives changes for real-time passive display updates
		if leaderstats:FindFirstChild("ActivePassives") then
			local conn = leaderstats.ActivePassives:GetPropertyChangedSignal("Value"):Connect(function()
				task.wait(0.1) -- Small delay to let server update complete
				updateStatsDisplay() -- Refresh display when passives change (to update buffs and passives section)
			end)
			statConnections["ActivePassives"] = conn
		end
		
		-- Connect to BaseStats changes (when buffs/passives are applied/removed)
		local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
		if baseStatsFolder then
			baseStatsFolder.ChildAdded:Connect(function()
				task.wait(0.1) -- Small delay to let server update complete
				updateStatsDisplay() -- Refresh display when BaseStats change
			end)
			baseStatsFolder.ChildRemoved:Connect(function()
				task.wait(0.1) -- Small delay to let server update complete
				updateStatsDisplay() -- Refresh display when BaseStats change
			end)
		end
		
		-- Connect to buff duration changes for real-time countdown updates
		local buffDurations = leaderstats:FindFirstChild("BuffDurations")
		if buffDurations then
			-- Track existing connections to avoid duplicates
			local buffDurationConnections = {}
			
			local function setupBuffDurationConnections()
				-- Clean up old connections
				for _, conn in pairs(buffDurationConnections) do
					conn:Disconnect()
				end
				buffDurationConnections = {}
				
				-- Connect to all buff duration values
				for _, buffDuration in ipairs(buffDurations:GetChildren()) do
					if buffDuration:IsA("ValueBase") then
						local conn = buffDuration:GetPropertyChangedSignal("Value"):Connect(function()
							local buffName = buffDuration.Name
							local timerLabelKey = "Buff_" .. buffName .. "_Timer"
							
							-- Update timer label (separate from stat bonus)
							if statLabels[timerLabelKey] then
								local remaining = math.max(0, math.floor(buffDuration.Value))
								local minutes = math.floor(remaining / 60)
								local seconds = remaining % 60
								local durationText = ""
								
								if minutes > 0 then
									durationText = string.format("%dm %ds", minutes, seconds)
								else
									durationText = string.format("%ds", seconds)
								end
								
								statLabels[timerLabelKey].Text = durationText
							end
						end)
						buffDurationConnections[buffDuration] = conn
					end
				end
			end
			
			setupBuffDurationConnections()
			
			-- Reconnect when buffs are added/removed
			buffDurations.ChildAdded:Connect(function()
				setupBuffDurationConnections()
				task.wait(0.1)
				updateStatsDisplay() -- Refresh display when buff duration is added (to show timer row)
			end)
			
			buffDurations.ChildRemoved:Connect(function()
				setupBuffDurationConnections()
				task.wait(0.1)
				updateStatsDisplay() -- Refresh display when buff expires
			end)
		end
		
		-- Connect to humanoid health changes for real-time health display
		-- Wait for character to load if needed
		local function setupHumanoidConnection()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				local humanoid = player.Character.Humanoid
				-- Disconnect old connection if it exists
				if statConnections["HumanoidHealth"] then
					statConnections["HumanoidHealth"]:Disconnect()
				end
				local conn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
					if statLabels["MaxHealth"] and humanoid.MaxHealth then
						-- Update health (simple display)
						local currentHealth = humanoid.Health
						local maxHealth = humanoid.MaxHealth
						statLabels["MaxHealth"].Text = string.format("%.0f / %.0f", currentHealth, maxHealth)
					end
					
					-- Refresh buffs and passives display when health changes (Tenacity might activate/deactivate)
					if leaderstats:FindFirstChild("ActivePassives") then
						task.wait(0.1) -- Small delay to let server update ActivePassives
						updateStatsDisplay() -- Refresh to show updated passives
					end
				end)
				statConnections["HumanoidHealth"] = conn
			end
		end
		
		setupHumanoidConnection()
	
	-- Special handling for class change to refresh base stats
	if leaderstats:FindFirstChild("Class") then
		local conn = leaderstats.Class:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1) -- Small delay to let server update complete
			updateStatsDisplay() -- Force full refresh when class changes
		end)
		statConnections[leaderstats.Class] = conn
	end
	
	-- Special handling for level change to refresh passives (so unlocked passives show up)
	if leaderstats:FindFirstChild("Level") then
		local conn = leaderstats.Level:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1) -- Small delay to let server update complete
			updateStatsDisplay() -- Force full refresh when level changes (to show newly unlocked passives)
		end)
		statConnections[leaderstats.Level] = conn
	end
end

-- Reconnect when player respawns
player.CharacterAdded:Connect(function()
	task.wait(1)
	updateStatsDisplay()
	setupStatConnections() -- Reconnect stat change listeners on respawn
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

