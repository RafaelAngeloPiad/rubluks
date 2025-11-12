local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- RemoteEvent for dev stat changes
local DevStatEvent = ReplicatedStorage:WaitForChild("DevStatEvent", 10)

-- Shared developer settings (for replicated toggles)
local DevSettingsFolder = ReplicatedStorage:FindFirstChild("DevSettings") or ReplicatedStorage:WaitForChild("DevSettings", 5)
local FriendlyFireFolder = DevSettingsFolder and (DevSettingsFolder:FindFirstChild("FriendlyFire") or DevSettingsFolder:WaitForChild("FriendlyFire", 5))
local playerFriendlyFireValue = FriendlyFireFolder and (FriendlyFireFolder:FindFirstChild("Players") or FriendlyFireFolder:WaitForChild("Players", 5))
local mobFriendlyFireValue = FriendlyFireFolder and (FriendlyFireFolder:FindFirstChild("Mobs") or FriendlyFireFolder:WaitForChild("Mobs", 5))
local mobCombatModeValue = FriendlyFireFolder and (FriendlyFireFolder:FindFirstChild("MobCombatMode") or FriendlyFireFolder:WaitForChild("MobCombatMode", 5))

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

local StatsUIConfig = ConfigModule and ConfigModule.ControlUI and ConfigModule.ControlUI.displayStats
local statsDisplayEnabled = not (StatsUIConfig and StatsUIConfig.enabled == false)

if not statsDisplayEnabled then
	return
end

-- Available classes
local AvailableClasses = {"Knight", "Samurai", "Gladiator", "Brawler", "Archer"}

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatsDisplay"
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
title.Text = "📊 STATS DASHBOARD (Drag to Move)"
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
local dragOffset = Vector2.zero
title.MouseButton1Down:Connect(function()
	isDragging = true
	local mousePos = UserInputService:GetMouseLocation()
	local framePos = mainFrame.AbsolutePosition
	dragOffset = mousePos - Vector2.new(framePos.X, framePos.Y)
end)

title.MouseButton1Up:Connect(function()
	isDragging = false
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
		local offsetX = mousePos.X - dragOffset.X
		local offsetY = mousePos.Y - dragOffset.Y
		local newPos = UDim2.new(0, offsetX, 0, offsetY)
		mainFrame.Position = newPos
	end
end)

-- Scrolling frame for all stats
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "StatsScroll"
scrollFrame.Size = UDim2.new(1, -10, 1, -45)
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

local function updateCanvasSize()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 40)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

-- Function to create a stat row with vertical layout (name on top, value on bottom) to prevent truncation
local function createStatRow(statName, value, color, layoutOrder, parent)
	parent = parent or scrollFrame
	local statFrame = Instance.new("Frame")
	statFrame.Name = HttpService:GenerateGUID(false)
	statFrame.Size = UDim2.new(1, -10, 0, 0) -- Height will be set automatically based on content
	statFrame.BackgroundTransparency = 1
	statFrame.LayoutOrder = layoutOrder or 0
	statFrame.Parent = parent
	
	-- Use automatic sizing
	local statFrameLayout = Instance.new("UIListLayout")
	statFrameLayout.FillDirection = Enum.FillDirection.Vertical
	statFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statFrameLayout.Padding = UDim.new(0, 2)
	statFrameLayout.Parent = statFrame
	
	local statNameLabel = Instance.new("TextLabel")
	statNameLabel.Name = "Name"
	statNameLabel.Size = UDim2.new(1, -10, 0, 0) -- Auto size height
	statNameLabel.Position = UDim2.new(0, 5, 0, 0)
	statNameLabel.BackgroundTransparency = 1
	statNameLabel.Text = statName .. ":"
	statNameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statNameLabel.TextSize = 12
	statNameLabel.Font = Enum.Font.Gotham
	statNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	statNameLabel.TextYAlignment = Enum.TextYAlignment.Top
	statNameLabel.TextWrapped = true -- Allow text wrapping
	statNameLabel.TextScaled = false
	statNameLabel.AutomaticSize = Enum.AutomaticSize.Y -- Auto size to fit content
	statNameLabel.LayoutOrder = 1
	statNameLabel.Parent = statFrame
	
	local statValueLabel = Instance.new("TextLabel")
	statValueLabel.Name = "Value"
	statValueLabel.Size = UDim2.new(1, -10, 0, 0) -- Auto size height
	statValueLabel.Position = UDim2.new(0, 5, 0, 0)
	statValueLabel.BackgroundTransparency = 1
	statValueLabel.Text = tostring(value)
	statValueLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	statValueLabel.TextSize = 12
	statValueLabel.Font = Enum.Font.GothamBold
	statValueLabel.TextXAlignment = Enum.TextXAlignment.Left
	statValueLabel.TextYAlignment = Enum.TextYAlignment.Top
	statValueLabel.TextWrapped = true -- Allow text wrapping
	statValueLabel.TextScaled = false
	statValueLabel.AutomaticSize = Enum.AutomaticSize.Y -- Auto size to fit content
	statValueLabel.LayoutOrder = 2
	statValueLabel.Parent = statFrame
	
	-- Update frame size to fit content
	statFrameLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		statFrame.Size = UDim2.new(1, -10, 0, statFrameLayout.AbsoluteContentSize.Y)
	end)
	
	return statValueLabel
end

local function createStatPairRow(entries, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = "StatPairRow_" .. tostring(layoutOrder or 0)
	rowFrame.Size = UDim2.new(1, -10, 0, 0)
	rowFrame.BackgroundTransparency = 1
	rowFrame.LayoutOrder = layoutOrder or 0
	rowFrame.AutomaticSize = Enum.AutomaticSize.Y
	rowFrame.Parent = scrollFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = rowFrame

	local valueLabels = {}
	local count = #entries

	for index, entry in ipairs(entries) do
		local widthScale = 1 / math.max(1, count)
		local columnFrame = Instance.new("Frame")
		columnFrame.Name = (entry.key or ("Column" .. index)) .. "_Column"
		columnFrame.Size = UDim2.new(widthScale, count == 1 and 0 or -5, 0, 0)
		columnFrame.BackgroundTransparency = 1
		columnFrame.AutomaticSize = Enum.AutomaticSize.Y
		columnFrame.Parent = rowFrame

		local columnLayout = Instance.new("UIListLayout")
		columnLayout.FillDirection = Enum.FillDirection.Vertical
		columnLayout.SortOrder = Enum.SortOrder.LayoutOrder
		columnLayout.Padding = UDim.new(0, 2)
		columnLayout.Parent = columnFrame

		local statNameLabel = Instance.new("TextLabel")
		statNameLabel.Name = (entry.key or ("Column" .. index)) .. "_Name"
		statNameLabel.Size = UDim2.new(1, -10, 0, 0)
		statNameLabel.Position = UDim2.new(0, 5, 0, 0)
		statNameLabel.BackgroundTransparency = 1
		local labelText = entry.label
		if labelText == nil then
			labelText = "Stat"
		end
		if labelText == "" then
			statNameLabel.Text = ""
		else
			statNameLabel.Text = tostring(labelText) .. ":"
		end
		statNameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		statNameLabel.TextSize = 12
		statNameLabel.Font = Enum.Font.Gotham
		statNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		statNameLabel.TextYAlignment = Enum.TextYAlignment.Top
		statNameLabel.TextWrapped = true
		statNameLabel.TextScaled = false
		statNameLabel.AutomaticSize = Enum.AutomaticSize.Y
		statNameLabel.LayoutOrder = 1
		statNameLabel.Parent = columnFrame

		local statValueLabel = Instance.new("TextLabel")
		statValueLabel.Name = (entry.key or ("Column" .. index)) .. "_Value"
		statValueLabel.Size = UDim2.new(1, -10, 0, 0)
		statValueLabel.Position = UDim2.new(0, 5, 0, 0)
		statValueLabel.BackgroundTransparency = 1
		statValueLabel.Text = entry.value ~= nil and tostring(entry.value) or "—"
		statValueLabel.TextColor3 = entry.color or Color3.fromRGB(255, 255, 255)
		statValueLabel.TextSize = 12
		statValueLabel.Font = Enum.Font.GothamBold
		statValueLabel.TextXAlignment = Enum.TextXAlignment.Left
		statValueLabel.TextYAlignment = Enum.TextYAlignment.Top
		statValueLabel.TextWrapped = true
		statValueLabel.TextScaled = false
		statValueLabel.AutomaticSize = Enum.AutomaticSize.Y
		statValueLabel.LayoutOrder = 2
		statValueLabel.Parent = columnFrame

		valueLabels[entry.key or ("Column" .. index)] = statValueLabel
	end

	return valueLabels
end

local function formatBonus(amount)
	if math.abs(amount - math.floor(amount)) < 1e-3 then
		return string.format("%+d", amount)
	end
	return string.format("%+.2f", amount)
end

local function formatDuration(seconds)
	if not seconds then
		return "Permanent"
	end

	local remaining = math.max(0, math.floor(seconds + 0.5))
	local minutes = math.floor(remaining / 60)
	local secs = remaining % 60

	if minutes > 0 then
		return string.format("%dm %02ds", minutes, secs)
	end

	return string.format("%ds", secs)
end

local EquipmentStatDisplayOrder = {
	{stat = "MaxHealth", label = "HP"},
	{stat = "MaxAttack", label = "Attack"},
	{stat = "MaxDefense", label = "Defense"},
	{stat = "DefensePenetration", label = "Defense Penetration"},
	{stat = "CritRate", label = "Crit Rate"},
	{stat = "CritMultiplier", label = "Crit Multiplier"},
}

local StatLabelLookup = {}
for _, entry in ipairs(EquipmentStatDisplayOrder) do
	StatLabelLookup[entry.stat] = entry.label
end

local activeConsumableTimers = {}

local mobCombatModeLocalState = mobCombatModeValue and mobCombatModeValue.Value or "excluded"
local MobCombatModeMetadata = {
	excluded = {
		label = "Excluded (Same-tag safe)",
		color = Color3.fromRGB(200, 200, 200),
	},
	versus = {
		label = "Versus (Cross-tag fights)",
		color = Color3.fromRGB(255, 200, 140),
	},
	frenzy = {
		label = "Frenzy (All mobs hostile)",
		color = Color3.fromRGB(255, 140, 140),
	},
}

local function createConsumableRow(valueObj, payload, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = "Consumable_" .. (payload.displayName or payload.name or valueObj.Name)
	frame.Size = UDim2.new(1, -10, 0, 0)
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = layoutOrder
	frame.Parent = scrollFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 0)
	nameLabel.Position = UDim2.new(0, 5, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = payload.displayName or payload.name or "Consumable"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Top
	nameLabel.TextWrapped = true
	nameLabel.AutomaticSize = Enum.AutomaticSize.Y
	nameLabel.LayoutOrder = 1
	nameLabel.Parent = frame

	local bonusLines = {}
	if payload.bonuses then
		for statName, amount in pairs(payload.bonuses) do
			local label = StatLabelLookup[statName] or statName
			table.insert(bonusLines, string.format("%s %s", label, formatBonus(amount)))
		end
	end
	table.sort(bonusLines)

	local bonusLabel = Instance.new("TextLabel")
	bonusLabel.Size = UDim2.new(1, -10, 0, 0)
	bonusLabel.Position = UDim2.new(0, 5, 0, 0)
	bonusLabel.BackgroundTransparency = 1
	bonusLabel.Text = (#bonusLines > 0) and table.concat(bonusLines, ", ") or "No stat bonuses"
	bonusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	bonusLabel.TextSize = 11
	bonusLabel.Font = Enum.Font.Gotham
	bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
	bonusLabel.TextYAlignment = Enum.TextYAlignment.Top
	bonusLabel.TextWrapped = true
	bonusLabel.AutomaticSize = Enum.AutomaticSize.Y
	bonusLabel.LayoutOrder = 2
	bonusLabel.Parent = frame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(1, -10, 0, 0)
	timerLabel.Position = UDim2.new(0, 5, 0, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	timerLabel.TextSize = 11
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.TextYAlignment = Enum.TextYAlignment.Top
	timerLabel.TextWrapped = true
	timerLabel.AutomaticSize = Enum.AutomaticSize.Y
	timerLabel.LayoutOrder = 3
	timerLabel.Parent = frame

	local now = tick()
	if payload.endTime then
		timerLabel.Text = formatDuration(payload.endTime - now)
	else
		timerLabel.Text = "Permanent"
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		frame.Size = UDim2.new(1, -10, 0, layout.AbsoluteContentSize.Y)
	end)

	activeConsumableTimers[valueObj] = {
		label = timerLabel,
		payload = payload,
	}

	return frame
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
	activeConsumableTimers = {}
	
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

	local mobModeMeta = MobCombatModeMetadata[mobCombatModeValue and mobCombatModeValue.Value or mobCombatModeLocalState] or MobCombatModeMetadata.excluded
	mobCombatModeLocalState = mobCombatModeValue and mobCombatModeValue.Value or mobCombatModeLocalState
	statLabels["MobCombatMode"] = createStatRow("Mob Combat Mode", mobModeMeta.label, mobModeMeta.color, layoutOrder)
	layoutOrder = layoutOrder + 1
	
	-- Display live stats from leaderstats
	local classValue = leaderstats:FindFirstChild("Class") and leaderstats.Class.Value or "N/A"
	local levelValue = leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or "N/A"

	local xpText = "N/A"
	if leaderstats:FindFirstChild("CurrentXP") and leaderstats:FindFirstChild("MaximumXP") then
		xpText = string.format("%d / %d", leaderstats.CurrentXP.Value, leaderstats.MaximumXP.Value)
	end

	local slavkoinsText = leaderstats:FindFirstChild("Slavkoins") and leaderstats.Slavkoins.Value or 0

	local healthText = "N/A"
	if leaderstats:FindFirstChild("MaxHealth") then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			healthText = string.format("%.0f / %.0f", humanoid.Health, humanoid.MaxHealth)
		else
			healthText = tostring(leaderstats.MaxHealth.Value)
		end
	end

	local defenseText = "N/A"
	if leaderstats:FindFirstChild("MaxDefense") then
		if leaderstats:FindFirstChild("CurrentDefense") then
			local currentDef = leaderstats.CurrentDefense.Value
			local maxDef = leaderstats.MaxDefense.Value
			defenseText = string.format("%.0f / %.0f", currentDef, maxDef)
		else
			defenseText = tostring(leaderstats.MaxDefense.Value)
		end
	end

	local dpText = leaderstats:FindFirstChild("DefensePenetration") and leaderstats.DefensePenetration.Value or 0
	local healthRegenText = leaderstats:FindFirstChild("HealthRegen") and leaderstats.HealthRegen.Value or 0

	local classLevelLabels = createStatPairRow({
		{key = "Class", label = "Class", value = classValue, color = Color3.fromRGB(255, 255, 255)},
		{key = "Level", label = "Level", value = levelValue, color = getStatColor("Level")}
	}, layoutOrder)
	for key, label in pairs(classLevelLabels) do
		statLabels[key] = label
	end
	layoutOrder = layoutOrder + 1

	local xpCoinLabels = createStatPairRow({
		{key = "CurrentXP", label = "XP", value = xpText, color = getStatColor("CurrentXP")},
		{key = "Slavkoins", label = "Slavkoins", value = slavkoinsText, color = getStatColor("Slavkoins")}
	}, layoutOrder)
	for key, label in pairs(xpCoinLabels) do
		statLabels[key] = label
	end
	layoutOrder = layoutOrder + 1

	local hpDefenseLabels = createStatPairRow({
		{key = "MaxHealth", label = "HP", value = healthText, color = getStatColor("MaxHealth")},
		{key = "MaxDefense", label = "Defense", value = defenseText, color = getStatColor("MaxDefense")}
	}, layoutOrder)
	for key, label in pairs(hpDefenseLabels) do
		statLabels[key] = label
	end
	layoutOrder = layoutOrder + 1

	local dpRegenLabels = createStatPairRow({
		{key = "DefensePenetration", label = "Defense Pen", value = dpText, color = getStatColor("DefensePenetration")},
		{key = "HealthRegen", label = "Health Regen", value = healthRegenText, color = getStatColor("HealthRegen")}
	}, layoutOrder)
	for key, label in pairs(dpRegenLabels) do
		statLabels[key] = label
	end
	layoutOrder = layoutOrder + 1

	local damageTexts = {
		normal = "Select a class to see damage",
		skill1 = "Select a class to see damage",
		skill2 = "Select a class to see damage",
		ult = "Select a class to see damage"
	}

	local className = leaderstats:FindFirstChild("Class") and leaderstats.Class.Value or nil
	local maxAttackValue = leaderstats:FindFirstChild("MaxAttack") and leaderstats.MaxAttack.Value or 0
	local critMultiplierValue = leaderstats:FindFirstChild("CritMultiplier") and leaderstats.CritMultiplier.Value or 150

	if className and className ~= "" and className ~= "Slavkorian" then
		local classConfig = ConfigModule and ConfigModule.Hitboxes and ConfigModule.Hitboxes.UnifiedAttacks and ConfigModule.Hitboxes.UnifiedAttacks[className]
		if classConfig then
			if maxAttackValue > 0 then
				if classConfig.damage then
					local normalDamage = math.floor(maxAttackValue * classConfig.damage)
					local normalCritDamage = math.floor(normalDamage * (critMultiplierValue / 100))
					damageTexts.normal = string.format("%d (Crit: %d)", normalDamage, normalCritDamage)
				else
					damageTexts.normal = "N/A"
				end

				if classConfig.skill1Damage then
					local skill1Damage = math.floor(maxAttackValue * classConfig.skill1Damage)
					local skill1CritDamage = math.floor(skill1Damage * (critMultiplierValue / 100))
					damageTexts.skill1 = string.format("%d (Crit: %d)", skill1Damage, skill1CritDamage)
				else
					damageTexts.skill1 = "N/A"
				end

				if classConfig.skill2Damage then
					local skill2Damage = math.floor(maxAttackValue * classConfig.skill2Damage)
					local skill2CritDamage = math.floor(skill2Damage * (critMultiplierValue / 100))
					damageTexts.skill2 = string.format("%d (Crit: %d)", skill2Damage, skill2CritDamage)
				else
					damageTexts.skill2 = "N/A"
				end

				if classConfig.ultDamage then
					local ultDamage = math.floor(maxAttackValue * classConfig.ultDamage)
					local ultCritDamage = math.floor(ultDamage * (critMultiplierValue / 100))
					damageTexts.ult = string.format("%d (Crit: %d)", ultDamage, ultCritDamage)
				else
					damageTexts.ult = "N/A"
				end
			else
				damageTexts.normal = "Waiting for stats..."
				damageTexts.skill1 = "Waiting for stats..."
				damageTexts.skill2 = "Waiting for stats..."
				damageTexts.ult = "Waiting for stats..."
			end
		else
			damageTexts.normal = "Unavailable for class"
			damageTexts.skill1 = "Unavailable for class"
			damageTexts.skill2 = "Unavailable for class"
			damageTexts.ult = "Unavailable for class"
		end
	elseif className == "Slavkorian" then
		damageTexts.normal = "Select a class to see damage"
		damageTexts.skill1 = "Select a class to see damage"
		damageTexts.skill2 = "Select a class to see damage"
		damageTexts.ult = "Select a class to see damage"
	end

	local skillDamageLabels = createStatPairRow({
		{key = "DamageSkill1", label = "Skill 1", value = damageTexts.skill1, color = Color3.fromRGB(200, 150, 255)},
		{key = "DamageSkill2", label = "Skill 2", value = damageTexts.skill2, color = Color3.fromRGB(200, 150, 255)}
	}, layoutOrder)
	for key, label in pairs(skillDamageLabels) do
		statLabels[key] = label
	end
	layoutOrder = layoutOrder + 1

	local normalUltDamageLabels = createStatPairRow({
		{key = "DamageNormal", label = "Normal Attack", value = damageTexts.normal, color = Color3.fromRGB(255, 200, 100)},
		{key = "DamageUlt", label = "Ultimate", value = damageTexts.ult, color = Color3.fromRGB(255, 100, 100)}
	}, layoutOrder)
	for key, label in pairs(normalUltDamageLabels) do
		statLabels[key] = label
	end
	layoutOrder = layoutOrder + 1
	
	-- Add divider
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -10, 0, 2)
	divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	divider.BorderSizePixel = 0
	divider.LayoutOrder = layoutOrder
	divider.Parent = scrollFrame
	layoutOrder = layoutOrder + 1

	-- Equipment bonuses header
	local equipmentHeader = Instance.new("TextLabel")
	equipmentHeader.Name = "EquipmentHeader"
	equipmentHeader.Size = UDim2.new(1, -10, 0, 25)
	equipmentHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	equipmentHeader.BorderSizePixel = 0
	equipmentHeader.Text = "WEAPON & ACCESSORY BONUSES"
	equipmentHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipmentHeader.TextSize = 11
	equipmentHeader.Font = Enum.Font.GothamBold
	equipmentHeader.LayoutOrder = layoutOrder
	equipmentHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1

	local equipmentBonusesFolder = leaderstats:FindFirstChild("EquipmentBonuses")
	local equipmentDetailsFolder = leaderstats:FindFirstChild("EquipmentBonusDetails")
	local hasEquipmentBonuses = false

	if equipmentBonusesFolder then
		for _, entry in ipairs(EquipmentStatDisplayOrder) do
			local valueObj = equipmentBonusesFolder:FindFirstChild(entry.stat)
			if valueObj and math.abs(valueObj.Value) > 0 then
				hasEquipmentBonuses = true
				local bonusText = formatBonus(valueObj.Value)

				if equipmentDetailsFolder then
					local detailObj = equipmentDetailsFolder:FindFirstChild(entry.stat)
					if detailObj and detailObj.Value ~= "" then
						bonusText = string.format("%s  (%s)", bonusText, detailObj.Value)
					end
				end

				local labelKey = "Equipment_" .. entry.stat
				statLabels[labelKey] = createStatRow(entry.label, bonusText, Color3.fromRGB(180, 255, 180), layoutOrder)
				layoutOrder = layoutOrder + 1
			end
		end
	end

	if not hasEquipmentBonuses then
		local noEquipmentLabel = Instance.new("TextLabel")
		noEquipmentLabel.Name = "NoEquipmentBonuses"
		noEquipmentLabel.Size = UDim2.new(1, -10, 0, 20)
		noEquipmentLabel.BackgroundTransparency = 1
		noEquipmentLabel.Text = "No weapon/accessory bonuses"
		noEquipmentLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noEquipmentLabel.TextSize = 11
		noEquipmentLabel.Font = Enum.Font.Gotham
		noEquipmentLabel.LayoutOrder = layoutOrder
		noEquipmentLabel.Parent = scrollFrame
		layoutOrder = layoutOrder + 1
	end

	-- Consumable bonuses header
	local consumableHeader = Instance.new("TextLabel")
	consumableHeader.Name = "ConsumableHeader"
	consumableHeader.Size = UDim2.new(1, -10, 0, 25)
	consumableHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	consumableHeader.BorderSizePixel = 0
	consumableHeader.Text = "CONSUMABLE BONUSES"
	consumableHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	consumableHeader.TextSize = 11
	consumableHeader.Font = Enum.Font.GothamBold
	consumableHeader.LayoutOrder = layoutOrder
	consumableHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1

	local consumableBonusesFolder = leaderstats:FindFirstChild("ConsumableBonuses")
	local consumableDetailsFolder = leaderstats:FindFirstChild("ConsumableBonusDetails")
	local hasConsumableBonuses = false

	if consumableBonusesFolder then
		for _, entry in ipairs(EquipmentStatDisplayOrder) do
			local valueObj = consumableBonusesFolder:FindFirstChild(entry.stat)
			if valueObj and math.abs(valueObj.Value) > 0 then
				hasConsumableBonuses = true
				local bonusText = formatBonus(valueObj.Value)

				if consumableDetailsFolder then
					local detailObj = consumableDetailsFolder:FindFirstChild(entry.stat)
					if detailObj and detailObj.Value ~= "" then
						bonusText = string.format("%s  (%s)", bonusText, detailObj.Value)
					end
				end

				local labelKey = "Consumable_" .. entry.stat
				statLabels[labelKey] = createStatRow("Consumable " .. entry.label, bonusText, Color3.fromRGB(255, 220, 150), layoutOrder)
				layoutOrder = layoutOrder + 1
			end
		end
	end

	if not hasConsumableBonuses then
		local noConsumableLabel = Instance.new("TextLabel")
		noConsumableLabel.Name = "NoConsumableBonuses"
		noConsumableLabel.Size = UDim2.new(1, -10, 0, 20)
		noConsumableLabel.BackgroundTransparency = 1
		noConsumableLabel.Text = "No consumable bonuses"
		noConsumableLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noConsumableLabel.TextSize = 11
		noConsumableLabel.Font = Enum.Font.Gotham
		noConsumableLabel.LayoutOrder = layoutOrder
		noConsumableLabel.Parent = scrollFrame
		layoutOrder = layoutOrder + 1
	end

	-- Active consumables header
	local activeConsumablesHeader = Instance.new("TextLabel")
	activeConsumablesHeader.Name = "ActiveConsumablesHeader"
	activeConsumablesHeader.Size = UDim2.new(1, -10, 0, 25)
	activeConsumablesHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	activeConsumablesHeader.BorderSizePixel = 0
	activeConsumablesHeader.Text = "ACTIVE CONSUMABLES"
	activeConsumablesHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	activeConsumablesHeader.TextSize = 11
	activeConsumablesHeader.Font = Enum.Font.GothamBold
	activeConsumablesHeader.LayoutOrder = layoutOrder
	activeConsumablesHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1

	local activeConsumablesFolder = leaderstats:FindFirstChild("ActiveConsumables")
	local activeConsumables = activeConsumablesFolder and activeConsumablesFolder:GetChildren() or {}

	if #activeConsumables > 0 then
		table.sort(activeConsumables, function(a, b)
			if not a:IsA("StringValue") then
				return false
			end
			if not b:IsA("StringValue") then
				return true
			end

			local successA, payloadA = pcall(function()
				return HttpService:JSONDecode(a.Value)
			end)
			local successB, payloadB = pcall(function()
				return HttpService:JSONDecode(b.Value)
			end)

			local nameA = successA and payloadA and (payloadA.displayName or payloadA.name) or a.Name
			local nameB = successB and payloadB and (payloadB.displayName or payloadB.name) or b.Name

			return tostring(nameA) < tostring(nameB)
		end)

		for _, valueObj in ipairs(activeConsumables) do
			if valueObj:IsA("StringValue") then
				local success, payload = pcall(function()
					return HttpService:JSONDecode(valueObj.Value)
				end)

				if success and typeof(payload) == "table" then
					createConsumableRow(valueObj, payload, layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
		end
	else
		local noActiveConsumablesLabel = Instance.new("TextLabel")
		noActiveConsumablesLabel.Name = "NoActiveConsumables"
		noActiveConsumablesLabel.Size = UDim2.new(1, -10, 0, 20)
		noActiveConsumablesLabel.BackgroundTransparency = 1
		noActiveConsumablesLabel.Text = "No active consumables"
		noActiveConsumablesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noActiveConsumablesLabel.TextSize = 11
		noActiveConsumablesLabel.Font = Enum.Font.Gotham
		noActiveConsumablesLabel.LayoutOrder = layoutOrder
		noActiveConsumablesLabel.Parent = scrollFrame
		layoutOrder = layoutOrder + 1
	end

	-- Divider before buffs/passives section
	local equipmentDivider = Instance.new("Frame")
	equipmentDivider.Size = UDim2.new(1, -10, 0, 2)
	equipmentDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	equipmentDivider.BorderSizePixel = 0
	equipmentDivider.LayoutOrder = layoutOrder
	equipmentDivider.Parent = scrollFrame
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
			elseif buffName == "ChampionsCheer" then
				hasBuffsOrPassives = true
				-- Calculate ChampionsCheer bonuses
				local championsCheerHpBonus = 0
				local championsCheerDefBonus = 0
				local championsCheerHpRegen = 0
				
				-- Get current level to calculate bonuses
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.GladiatorBuffs then
					local buffConfig = ConfigModule.getBuffConfig("ChampionsCheer", level.Value)
					if buffConfig then
						-- Get base stats from BaseStats (if available)
						local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
						local baseMaxHealth = baseStatsFolder and baseStatsFolder:FindFirstChild("BaseMaxHealth")
						local baseMaxDefense = baseStatsFolder and baseStatsFolder:FindFirstChild("BaseMaxDefense")
						
						if baseMaxHealth and baseMaxDefense then
							-- Calculate what ChampionsCheer adds (multiplier-based)
							local baseHP = baseMaxHealth.Value
							local baseDEF = baseMaxDefense.Value
							championsCheerHpBonus = math.floor(baseHP * buffConfig.hpMultiplier)
							championsCheerDefBonus = math.floor(baseDEF * buffConfig.defenseMultiplier)
							championsCheerHpRegen = buffConfig.hpRegenPercentage or 0
						else
							-- Fallback: Calculate from current stats
							local currentMaxHealth = leaderstats:FindFirstChild("MaxHealth") and leaderstats.MaxHealth.Value or 0
							local currentMaxDefense = leaderstats:FindFirstChild("MaxDefense") and leaderstats.MaxDefense.Value or 0
							-- Estimate base by reversing the multiplier
							local estimatedBaseHP = math.floor(currentMaxHealth / (1 + buffConfig.hpMultiplier))
							local estimatedBaseDEF = math.floor(currentMaxDefense / (1 + buffConfig.defenseMultiplier))
							championsCheerHpBonus = currentMaxHealth - estimatedBaseHP
							championsCheerDefBonus = currentMaxDefense - estimatedBaseDEF
							championsCheerHpRegen = buffConfig.hpRegenPercentage or 0
						end
					end
				end
				
				-- Display stat bonuses (separate from timer)
				local buffText = ""
				local hpRegenPercent = math.floor(championsCheerHpRegen * 100)
				if championsCheerHpBonus > 0 and championsCheerDefBonus > 0 and hpRegenPercent > 0 then
					buffText = string.format("+%.0f HP, +%.0f DEF, %d%% HP/s", championsCheerHpBonus, championsCheerDefBonus, hpRegenPercent)
				elseif championsCheerHpBonus > 0 and championsCheerDefBonus > 0 then
					buffText = string.format("+%.0f HP, +%.0f DEF", championsCheerHpBonus, championsCheerDefBonus)
				elseif championsCheerHpBonus > 0 then
					buffText = string.format("+%.0f HP", championsCheerHpBonus)
				elseif championsCheerDefBonus > 0 then
					buffText = string.format("+%.0f DEF", championsCheerDefBonus)
				else
					buffText = "Active"
				end
				
				statLabels["Buff_ChampionsCheer"] = createStatRow("Champion's Cheer", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
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
						
						statLabels["Buff_ChampionsCheer_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "ChampionsBlood" then
				hasBuffsOrPassives = true
				-- Calculate ChampionsBlood bonus
				local championsBloodDefenseBonus = 0
				local immunityDuration = 0
				
				-- Get current level to calculate Defense increase
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.GladiatorBuffs then
					local buffConfig = ConfigModule.getBuffConfig("ChampionsBlood", level.Value)
					if buffConfig then
						-- ChampionsBlood adds flat Defense
						championsBloodDefenseBonus = buffConfig.defenseIncrease
						immunityDuration = buffConfig.immunityDuration or 0
					end
				end
				
				-- Display stat bonus (separate from timer)
				local buffText = ""
				if championsBloodDefenseBonus > 0 and immunityDuration > 0 then
					buffText = string.format("+%.0f DEF, %ds Immunity", championsBloodDefenseBonus, immunityDuration)
				elseif championsBloodDefenseBonus > 0 then
					buffText = string.format("+%.0f DEF", championsBloodDefenseBonus)
				else
					buffText = "Active"
				end
				
				statLabels["Buff_ChampionsBlood"] = createStatRow("Champion's Blood", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
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
						
						statLabels["Buff_ChampionsBlood_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "HuntersInstinct" then
				hasBuffsOrPassives = true
				-- Calculate HuntersInstinct bonuses
				local immunityDuration = 0
				
				-- Get current level to calculate Movement Speed increase and immunity duration
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.ArcherBuffs then
					local buffConfig = ConfigModule.getBuffConfig("HuntersInstinct", level.Value)
					if buffConfig then
						-- HuntersInstinct provides Movement Speed multiplier and immunity duration
						-- mspdMultiplier is already a percentage (0.06 = 6%)
						local mspdMultiplier = buffConfig.mspdMultiplier or 0
						immunityDuration = buffConfig.immunityDuration or 0
						
						-- Convert multiplier to percentage for display
						local mspdPercent = math.floor(mspdMultiplier * 100)
						
						-- Display stat bonuses (separate from timer)
						local buffText = ""
						if mspdPercent > 0 and immunityDuration > 0 then
							buffText = string.format("%d%% Mspd, %ds Immunity", mspdPercent, immunityDuration)
						elseif mspdPercent > 0 then
							buffText = string.format("%d%% Mspd", mspdPercent)
						elseif immunityDuration > 0 then
							buffText = string.format("%ds Immunity", immunityDuration)
						else
							buffText = "Active"
						end
						
						statLabels["Buff_HuntersInstinct"] = createStatRow("Hunter's Instinct", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
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
								
								statLabels["Buff_HuntersInstinct_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
								layoutOrder = layoutOrder + 1
							end
						end
					end
				end
			elseif buffName == "HuntersMark" then
				hasBuffsOrPassives = true
				-- Calculate HuntersMark bonuses
				local huntersMarkAttackBonus = 0
				local huntersMarkAttackSpeedBonus = 0
				
				-- Get current level to calculate Attack and Attack Speed increase
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.ArcherBuffs then
					local buffConfig = ConfigModule.getBuffConfig("HuntersMark", level.Value)
					if buffConfig then
						-- HuntersMark adds flat Attack and Attack Speed
						huntersMarkAttackBonus = buffConfig.attackIncrease or 0
						huntersMarkAttackSpeedBonus = buffConfig.attackSpeedIncrease or 0
					end
				end
				
				-- Display stat bonuses (separate from timer)
				local buffText = ""
				if huntersMarkAttackBonus > 0 and huntersMarkAttackSpeedBonus > 0 then
					buffText = string.format("+%.0f ATK, +%.1f Aspd", huntersMarkAttackBonus, huntersMarkAttackSpeedBonus)
				elseif huntersMarkAttackBonus > 0 then
					buffText = string.format("+%.0f ATK", huntersMarkAttackBonus)
				elseif huntersMarkAttackSpeedBonus > 0 then
					buffText = string.format("+%.1f Aspd", huntersMarkAttackSpeedBonus)
				else
					buffText = "Active"
				end
				
				statLabels["Buff_HuntersMark"] = createStatRow("Hunter's Mark", buffText, Color3.fromRGB(100, 255, 100), layoutOrder)
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
						
						statLabels["Buff_HuntersMark_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "Banzai" then
				hasBuffsOrPassives = true
				-- Banzai provides immunity to damage
				local buffText = "Immune to Damage"
				
				statLabels["Buff_Banzai"] = createStatRow("Banzai", buffText, Color3.fromRGB(255, 200, 100), layoutOrder)
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
						
						statLabels["Buff_Banzai_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
					end
				end
			elseif buffName == "Bushido" then
				hasBuffsOrPassives = true
				-- Bushido prevents HP from hitting 0
				local buffText = "HP Cannot Hit 0"
				
				statLabels["Buff_Bushido"] = createStatRow("Bushido", buffText, Color3.fromRGB(255, 200, 100), layoutOrder)
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
						
						statLabels["Buff_Bushido_Timer"] = createStatRow("  └ Timer", durationText, Color3.fromRGB(150, 200, 255), layoutOrder)
						layoutOrder = layoutOrder + 1
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
					passiveText = string.format("When HP<30%%: +%.0f DEF", tenacityDefenseBonus)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Tenacity"] = createStatRow("Tenacity", passiveText, Color3.fromRGB(150, 200, 255), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "Rage" then
				hasBuffsOrPassives = true
				-- Calculate Rage bonuses
				local rageAttackBonus = 0
				local rageAttackSpeedBonus = 0
				
				-- Get current level to get bonuses
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.BrawlerPassives then
					local passiveConfig = ConfigModule.getBrawlerPassiveConfig("Rage", level.Value)
					if passiveConfig then
						rageAttackBonus = passiveConfig.attackIncrease
						rageAttackSpeedBonus = passiveConfig.attackSpeedIncrease
					end
				end
				
				local passiveText = ""
				if rageAttackBonus > 0 and rageAttackSpeedBonus > 0 then
					passiveText = string.format("When HP<30%%: +%.0f ATK, +%.1f Aspd", rageAttackBonus, rageAttackSpeedBonus)
				elseif rageAttackBonus > 0 then
					passiveText = string.format("When HP<30%%: +%.0f ATK", rageAttackBonus)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Rage"] = createStatRow("Rage", passiveText, Color3.fromRGB(255, 100, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "Madness" then
				hasBuffsOrPassives = true
				-- Calculate Madness stun chance
				local madnessStunChance = 0
				
				-- Get current level to get stun chance
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.BrawlerPassives then
					local passiveConfig = ConfigModule.getBrawlerPassiveConfig("Madness", level.Value)
					if passiveConfig then
						madnessStunChance = passiveConfig.stunChance
					end
				end
				
				local passiveText = ""
				if madnessStunChance > 0 then
					passiveText = string.format("When HP<30%%: %d%% chance to stun on attacks", madnessStunChance)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Madness"] = createStatRow("Madness", passiveText, Color3.fromRGB(200, 100, 255), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "ChampionsRebuke" then
				hasBuffsOrPassives = true
				-- Calculate Champion's Rebuke chance
				local championsRebukeChance = 0
				
				-- Get current level to get chance
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.GladiatorPassives then
					local passiveConfig = ConfigModule.getGladiatorPassiveConfig("ChampionsRebuke", level.Value)
					if passiveConfig then
						championsRebukeChance = passiveConfig.chance
					end
				end
				
				local passiveText = ""
				if championsRebukeChance > 0 then
					passiveText = string.format("Combo2: %d%% chance for double damage", championsRebukeChance)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_ChampionsRebuke"] = createStatRow("Champion's Rebuke", passiveText, Color3.fromRGB(255, 200, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "OneLastChance" then
				hasBuffsOrPassives = true
				-- Calculate One Last Chance resurrect HP
				local oneLastChanceHPPercent = 0
				
				-- Get current level to get resurrect HP percentage
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.GladiatorPassives then
					local passiveConfig = ConfigModule.getGladiatorPassiveConfig("OneLastChance", level.Value)
					if passiveConfig then
						oneLastChanceHPPercent = passiveConfig.resurrectHPPercentage or 0
					end
				end
				
				local passiveText = ""
				if oneLastChanceHPPercent > 0 then
					local hpPercent = math.floor(oneLastChanceHPPercent * 100)
					passiveText = string.format("Resurrects with %d%% HP when HP=0", hpPercent)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_OneLastChance"] = createStatRow("One Last Chance", passiveText, Color3.fromRGB(255, 150, 150), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "Headshot" then
				hasBuffsOrPassives = true
				-- Calculate Headshot chance
				local headshotChance = 0
				
				-- Get current level to get chance
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.ArcherPassives then
					local passiveConfig = ConfigModule.getArcherPassiveConfig("Headshot", level.Value)
					if passiveConfig then
						headshotChance = passiveConfig.chance or 0
					end
				end
				
				local passiveText = ""
				if headshotChance > 0 then
					passiveText = string.format("%d%% chance for 2x damage on attacks", headshotChance)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Headshot"] = createStatRow("Headshot", passiveText, Color3.fromRGB(255, 200, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "Immobilize" then
				hasBuffsOrPassives = true
				-- Calculate Immobilize stun chance
				local immobilizeStunChance = 0
				
				-- Get current level to get stun chance
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.ArcherPassives then
					local passiveConfig = ConfigModule.getArcherPassiveConfig("Immobilize", level.Value)
					if passiveConfig then
						immobilizeStunChance = passiveConfig.stunChance or 0
					end
				end
				
				local passiveText = ""
				if immobilizeStunChance > 0 then
					passiveText = string.format("%d%% chance to stun on attacks", immobilizeStunChance)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Immobilize"] = createStatRow("Immobilize", passiveText, Color3.fromRGB(255, 200, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "BladeDance" then
				hasBuffsOrPassives = true
				-- Calculate Blade Dance attack increase and chance
				local bladeDanceAttackIncrease = 0
				local bladeDanceChance = 0
				local bladeDanceChanceLowHP = 0
				
				-- Get current level to get attack increase and chance
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.SamuraiPassives then
					local passiveConfig = ConfigModule.getSamuraiPassiveConfig("BladeDance", level.Value)
					if passiveConfig then
						bladeDanceAttackIncrease = passiveConfig.attackIncrease or 0
						bladeDanceChance = passiveConfig.chance or 0
						-- Calculate low HP chance (2x multiplier)
						if bladeDanceChance > 0 then
							local bladeDanceConfig = ConfigModule.SamuraiPassives.BladeDance
							local lowHPChanceMultiplier = bladeDanceConfig and bladeDanceConfig.lowHPChanceMultiplier or 2.0
							bladeDanceChanceLowHP = math.floor(bladeDanceChance * lowHPChanceMultiplier)
						end
					end
				end
				
				local passiveText = ""
				if bladeDanceAttackIncrease > 0 and bladeDanceChance > 0 then
					if bladeDanceChanceLowHP > 0 then
						passiveText = string.format("%d%% (HP>30%%) / %d%% (HP<30%%) chance of +%d ATK on attacks", bladeDanceChance, bladeDanceChanceLowHP, bladeDanceAttackIncrease)
					else
						passiveText = string.format("%d%% chance of +%d ATK on attacks", bladeDanceChance, bladeDanceAttackIncrease)
					end
				elseif bladeDanceAttackIncrease > 0 then
					passiveText = string.format("+%d ATK", bladeDanceAttackIncrease)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_BladeDance"] = createStatRow("Blade Dance", passiveText, Color3.fromRGB(255, 200, 100), layoutOrder)
				layoutOrder = layoutOrder + 1
			elseif passiveName == "Burst" then
				hasBuffsOrPassives = true
				-- Calculate Burst chance (HP-based)
				local burstChanceHighHP = 0
				local burstChanceLowHP = 0
				
				-- Get current level to get chance
				local level = leaderstats:FindFirstChild("Level")
				if level and ConfigModule and ConfigModule.SamuraiPassives then
					local passiveConfig = ConfigModule.getSamuraiPassiveConfig("Burst", level.Value)
					if passiveConfig then
						burstChanceHighHP = passiveConfig.chanceHighHP or 0
						burstChanceLowHP = passiveConfig.chanceLowHP or 0
					end
				end
				
				local passiveText = ""
				if burstChanceHighHP > 0 and burstChanceLowHP > 0 then
					passiveText = string.format("Combo2: %d%% (HP>30%%) / %d%% (HP<30%%) chance for 2x damage", burstChanceHighHP, burstChanceLowHP)
				else
					passiveText = "Active"
				end
				
				statLabels["Passive_Burst"] = createStatRow("Burst", passiveText, Color3.fromRGB(255, 200, 100), layoutOrder)
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
					local statusText = string.format("Unlocked (Combo2: %d%% chance for double damage)", knightsBladeConfig.chance)
					
					statLabels["Passive_KnightsBlade"] = createStatRow(displayName, statusText, Color3.fromRGB(150, 200, 255), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
		end
		
		-- Only show passives for Brawler class
		if className == "Brawler" and ConfigModule and ConfigModule.BrawlerPassives then
			local passivesConfig = ConfigModule.BrawlerPassives
			
			-- Check Rage passive (unlocks at level 1)
			if passivesConfig.Rage then
				local rageLevels = passivesConfig.Rage.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(rageLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local rageConfig = rageLevels[highestUnlocked]
					local displayName = "Rage"
					local statusText = string.format("Unlocked (When HP<30%%: +%d ATK, +%.1f Aspd)", rageConfig.attackIncrease, rageConfig.attackSpeedIncrease)
					
					statLabels["Passive_Rage_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 150, 150), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
			
			-- Check Madness passive (unlocks at level 5)
			if passivesConfig.Madness then
				local madnessLevels = passivesConfig.Madness.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(madnessLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local madnessConfig = madnessLevels[highestUnlocked]
					local displayName = "Madness"
					local statusText = string.format("Unlocked (When HP<30%%: %d%% chance to stun on attacks)", madnessConfig.stunChance)
					
					statLabels["Passive_Madness_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(200, 150, 255), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
		end
		
		-- Only show passives for Gladiator class
		if className == "Gladiator" and ConfigModule and ConfigModule.GladiatorPassives then
			local passivesConfig = ConfigModule.GladiatorPassives
			
			-- Check Champion's Rebuke passive (unlocks at level 5)
			if passivesConfig.ChampionsRebuke then
				local championsRebukeLevels = passivesConfig.ChampionsRebuke.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(championsRebukeLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local championsRebukeConfig = championsRebukeLevels[highestUnlocked]
					local displayName = "Champion's Rebuke"
					local statusText = string.format("Unlocked (Combo2: %d%% chance for double damage)", championsRebukeConfig.chance)
					
					statLabels["Passive_ChampionsRebuke_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 200, 150), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
			
			-- Check One Last Chance passive (unlocks at level 1)
			if passivesConfig.OneLastChance then
				local oneLastChanceLevels = passivesConfig.OneLastChance.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(oneLastChanceLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local oneLastChanceConfig = oneLastChanceLevels[highestUnlocked]
					local displayName = "One Last Chance"
					local hpPercent = math.floor(oneLastChanceConfig.resurrectHPPercentage * 100)
					local statusText = string.format("Unlocked (Resurrects with %d%% HP when HP=0)", hpPercent)
					
					statLabels["Passive_OneLastChance_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 150, 150), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
		end
		
		-- Only show passives for Archer class
		if className == "Archer" and ConfigModule and ConfigModule.ArcherPassives then
			local passivesConfig = ConfigModule.ArcherPassives
			
			-- Check Headshot passive (unlocks at level 1)
			if passivesConfig.Headshot then
				local headshotLevels = passivesConfig.Headshot.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(headshotLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local headshotConfig = headshotLevels[highestUnlocked]
					local displayName = "Headshot"
					local statusText = string.format("Unlocked (%d%% chance for 2x damage on attacks)", headshotConfig.chance)
					
					statLabels["Passive_Headshot_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 200, 150), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
			
			-- Check Immobilize passive (unlocks at level 5)
			if passivesConfig.Immobilize then
				local immobilizeLevels = passivesConfig.Immobilize.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(immobilizeLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local immobilizeConfig = immobilizeLevels[highestUnlocked]
					local displayName = "Immobilize"
					local statusText = string.format("Unlocked (%d%% chance to stun on attacks)", immobilizeConfig.stunChance)
					
					statLabels["Passive_Immobilize_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 200, 150), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
		end
		
		-- Only show passives for Samurai class
		if className == "Samurai" and ConfigModule and ConfigModule.SamuraiPassives then
			local passivesConfig = ConfigModule.SamuraiPassives
			
			-- Check Blade Dance passive (unlocks at level 1)
			if passivesConfig.BladeDance then
				local bladeDanceLevels = passivesConfig.BladeDance.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(bladeDanceLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local bladeDanceConfig = bladeDanceLevels[highestUnlocked]
					local displayName = "Blade Dance"
					local bladeDanceConfigFull = ConfigModule.SamuraiPassives.BladeDance
					local lowHPChanceMultiplier = bladeDanceConfigFull and bladeDanceConfigFull.lowHPChanceMultiplier or 2.0
					local lowHPChance = math.floor(bladeDanceConfig.chance * lowHPChanceMultiplier)
					local statusText = string.format("Unlocked (%d%% (HP>30%%) / %d%% (HP<30%%) chance of +%d ATK on attacks)", bladeDanceConfig.chance, lowHPChance, bladeDanceConfig.attackIncrease)
					
					statLabels["Passive_BladeDance_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 200, 150), layoutOrder)
					layoutOrder = layoutOrder + 1
				end
			end
			
			-- Check Burst passive (unlocks at level 5)
			if passivesConfig.Burst then
				local burstLevels = passivesConfig.Burst.levels
				local highestUnlocked = nil
				for passiveLevel, config in pairs(burstLevels) do
					if level >= passiveLevel then
						if not highestUnlocked or passiveLevel > highestUnlocked then
							highestUnlocked = passiveLevel
						end
					end
				end
				
				if highestUnlocked then
					hasBuffsOrPassives = true
					local burstConfig = burstLevels[highestUnlocked]
					local displayName = "Burst"
					local statusText = string.format("Unlocked (Combo2: %d%% (HP>30%%) / %d%% (HP<30%%) chance for 2x damage)", burstConfig.chanceHighHP, burstConfig.chanceLowHP)
					
					statLabels["Passive_Burst_Unlocked"] = createStatRow(displayName, statusText, Color3.fromRGB(255, 200, 150), layoutOrder)
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

	-- Base stats section
	local baseDivider = Instance.new("Frame")
	baseDivider.Size = UDim2.new(1, -10, 0, 2)
	baseDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	baseDivider.BorderSizePixel = 0
	baseDivider.LayoutOrder = layoutOrder
	baseDivider.Parent = scrollFrame
	layoutOrder = layoutOrder + 1

	local baseHeader = Instance.new("TextLabel")
	baseHeader.Name = "BaseStatsHeader"
	baseHeader.Size = UDim2.new(1, -10, 0, 25)
	baseHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	baseHeader.BorderSizePixel = 0
	baseHeader.Text = "BASE STATS"
	baseHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	baseHeader.TextSize = 11
	baseHeader.Font = Enum.Font.GothamBold
	baseHeader.LayoutOrder = layoutOrder
	baseHeader.Parent = scrollFrame
	layoutOrder = layoutOrder + 1

	local baseRowOneEntries = {}
	if leaderstats:FindFirstChild("MaxAttack") then
		table.insert(baseRowOneEntries, {
			key = "MaxAttack",
			label = "Attack",
			value = leaderstats.MaxAttack.Value,
			color = getStatColor("MaxAttack"),
		})
	end
	if leaderstats:FindFirstChild("CritRate") then
		table.insert(baseRowOneEntries, {
			key = "CritRate",
			label = "Crit Rate",
			value = leaderstats.CritRate.Value,
			color = Color3.fromRGB(255, 255, 255),
		})
	end
	if leaderstats:FindFirstChild("CritMultiplier") then
		table.insert(baseRowOneEntries, {
			key = "CritMultiplier",
			label = "Crit Mult",
			value = leaderstats.CritMultiplier.Value,
			color = Color3.fromRGB(255, 255, 255),
		})
	end

	if #baseRowOneEntries > 0 then
		local baseRowOneLabels = createStatPairRow(baseRowOneEntries, layoutOrder)
		for key, label in pairs(baseRowOneLabels) do
			statLabels[key] = label
		end
		layoutOrder = layoutOrder + 1
	end

	local baseRowTwoEntries = {}
	if leaderstats:FindFirstChild("MovementSpeed") then
		table.insert(baseRowTwoEntries, {
			key = "MovementSpeed",
			label = "Move Speed",
			value = leaderstats.MovementSpeed.Value,
			color = Color3.fromRGB(255, 255, 255),
		})
	end
	if leaderstats:FindFirstChild("AttackSpeed") then
		table.insert(baseRowTwoEntries, {
			key = "AttackSpeed",
			label = "Atk Speed",
			value = leaderstats.AttackSpeed.Value,
			color = Color3.fromRGB(255, 255, 255),
		})
	end

	if #baseRowTwoEntries > 0 then
		local baseRowTwoLabels = createStatPairRow(baseRowTwoEntries, layoutOrder)
		for key, label in pairs(baseRowTwoLabels) do
			statLabels[key] = label
		end
		layoutOrder = layoutOrder + 1
	end

	-- Add divider
	local divider2 = Instance.new("Frame")
	divider2.Size = UDim2.new(1, -10, 0, 2)
	divider2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	divider2.BorderSizePixel = 0
	divider2.LayoutOrder = layoutOrder
	divider2.Parent = scrollFrame
	layoutOrder = layoutOrder + 1
	
	-- Update canvas size
	updateCanvasSize()
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
		
	local function connectEquipmentFolder(folder, keyPrefix)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("ValueBase") then
				local conn = child:GetPropertyChangedSignal("Value"):Connect(function()
					task.wait(0.05)
					updateStatsDisplay()
				end)
				statConnections[child] = conn
			end
		end

		local addedConn = folder.ChildAdded:Connect(function(child)
			if child:IsA("ValueBase") then
				local conn = child:GetPropertyChangedSignal("Value"):Connect(function()
					task.wait(0.05)
					updateStatsDisplay()
				end)
				statConnections[child] = conn
				task.wait(0.05)
				updateStatsDisplay()
			end
		end)
		statConnections[keyPrefix .. "_ChildAdded"] = addedConn

		local removedConn = folder.ChildRemoved:Connect(function()
			task.wait(0.05)
			updateStatsDisplay()
		end)
		statConnections[keyPrefix .. "_ChildRemoved"] = removedConn
	end

	local equipmentBonuses = leaderstats:FindFirstChild("EquipmentBonuses")
	if equipmentBonuses then
		connectEquipmentFolder(equipmentBonuses, "EquipmentBonuses")
	end

	local equipmentBonusDetails = leaderstats:FindFirstChild("EquipmentBonusDetails")
	if equipmentBonusDetails then
		connectEquipmentFolder(equipmentBonusDetails, "EquipmentBonusDetails")
	end

	local consumableBonuses = leaderstats:FindFirstChild("ConsumableBonuses")
	if consumableBonuses then
		connectEquipmentFolder(consumableBonuses, "ConsumableBonuses")
	end

	local consumableBonusDetails = leaderstats:FindFirstChild("ConsumableBonusDetails")
	if consumableBonusDetails then
		connectEquipmentFolder(consumableBonusDetails, "ConsumableBonusDetails")
	end

	local activeConsumablesFolder = leaderstats:FindFirstChild("ActiveConsumables")
	if activeConsumablesFolder then
		local function connectActive(child)
			if child:IsA("StringValue") then
				local conn = child:GetPropertyChangedSignal("Value"):Connect(function()
					task.wait(0.05)
					updateStatsDisplay()
				end)
				statConnections[child] = conn
			end
		end

		for _, child in ipairs(activeConsumablesFolder:GetChildren()) do
			connectActive(child)
		end

		local addedConn = activeConsumablesFolder.ChildAdded:Connect(function(child)
			connectActive(child)
			task.wait(0.05)
			updateStatsDisplay()
		end)
		statConnections["ActiveConsumablesAdded"] = addedConn

		local removedConn = activeConsumablesFolder.ChildRemoved:Connect(function(child)
			if statConnections[child] then
				statConnections[child]:Disconnect()
				statConnections[child] = nil
			end
			task.wait(0.05)
			updateStatsDisplay()
		end)
		statConnections["ActiveConsumablesRemoved"] = removedConn
	end

	local childAddedConn = leaderstats.ChildAdded:Connect(function(child)
		if child.Name == "EquipmentBonuses"
			or child.Name == "EquipmentBonusDetails"
			or child.Name == "ConsumableBonuses"
			or child.Name == "ConsumableBonusDetails"
			or child.Name == "ActiveConsumables" then
			task.wait(0.1)
			updateStatsDisplay()
			task.defer(setupStatConnections)
		end
	end)
	statConnections["LeaderstatsChildAdded"] = childAddedConn

	local childRemovedConn = leaderstats.ChildRemoved:Connect(function(child)
		if child.Name == "EquipmentBonuses"
			or child.Name == "EquipmentBonusDetails"
			or child.Name == "ConsumableBonuses"
			or child.Name == "ConsumableBonusDetails"
			or child.Name == "ActiveConsumables" then
			task.wait(0.1)
			updateStatsDisplay()
			task.defer(setupStatConnections)
		end
	end)
	statConnections["LeaderstatsChildRemoved"] = childRemovedConn

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
setupStatConnections()
updateStatsDisplay()
task.defer(function()
	task.wait(0.2)
	updateStatsDisplay()
end)

if mobCombatModeValue then
	mobCombatModeValue:GetPropertyChangedSignal("Value"):Connect(function()
		mobCombatModeLocalState = mobCombatModeValue.Value ~= "" and mobCombatModeValue.Value or "excluded"
		task.defer(updateStatsDisplay)
	end)
end

RunService.RenderStepped:Connect(function()
	local now = tick()
	for valueObj, data in pairs(activeConsumableTimers) do
		if valueObj.Parent and data.label then
			local payload = data.payload
			if payload and payload.endTime then
				local remaining = payload.endTime - now
				if remaining < 0 then
					remaining = 0
				end
				data.label.Text = formatDuration(remaining)
			else
				data.label.Text = "Permanent"
			end
		else
			activeConsumableTimers[valueObj] = nil
		end
	end
end)

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

