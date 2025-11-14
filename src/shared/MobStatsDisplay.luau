-- ========================================
-- MOB STATS DISPLAY MODULE
-- Floating GUI above mobs showing real-time stats
-- ========================================

local RunService = game:GetService("RunService")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

local IS_CLIENT = RunService:IsClient()
local trackedDisplays = {}
local visibilityUpdateConnection = nil

local function getFocusPart(model)
	if not model then
		return nil
	end

	if model.PrimaryPart then
		return model.PrimaryPart
	end

	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
end

local function computeScale(distance, config)
	local referenceDistance = config.scaleReferenceDistance or 45
	local minScale = config.minScale or 0.6
	local maxScale = config.maxScale or 1.1
	local falloff = config.scaleFalloff or 1

	distance = math.max(distance, 1)
	local scale = referenceDistance / (distance ^ falloff)
	return math.clamp(scale, minScale, maxScale)
end

local function applyScale(displayInfo, scale)
	local billboard = displayInfo.billboard
	if not billboard or not billboard.Parent then
		return
	end

	local baseSize = displayInfo.baseSize
	if baseSize then
		billboard.Size = UDim2.new(0, math.floor(baseSize.X * scale), 0, math.floor(baseSize.Y * scale))
	end

	for _, entry in ipairs(displayInfo.textElements) do
		local label = entry.label
		if label and label.Parent then
			label.TextSize = math.max(8, math.floor(entry.baseSize * scale))
		end
	end
end

local function cleanupTracking(billboard)
	trackedDisplays[billboard] = nil
	if visibilityUpdateConnection and next(trackedDisplays) == nil then
		visibilityUpdateConnection:Disconnect()
		visibilityUpdateConnection = nil
	end
end

local function updateClientDisplayVisibility()
	if not IS_CLIENT then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local statsConfig = ServerConfigs.Hitbox.mobStatsDisplay
	if not statsConfig then
		return
	end

	local maxVisible = math.max(0, statsConfig.maxVisible or 10)
	local visibilityRadius = statsConfig.visibilityRadius or statsConfig.maxDistance or 120
	local distanceScalingEnabled = statsConfig.distanceScaling ~= false

	local entries = {}
	local toRemove = {}

	for billboard, info in pairs(trackedDisplays) do
		if billboard.Parent and info.model and info.model.Parent then
			local focusPart = info.focusPart
			if not focusPart or not focusPart.Parent then
				focusPart = getFocusPart(info.model)
				info.focusPart = focusPart
			end

			if focusPart then
				local distance = (camera.CFrame.Position - focusPart.Position).Magnitude
				info.distance = distance
				table.insert(entries, info)
			else
				table.insert(toRemove, billboard)
			end
		else
			table.insert(toRemove, billboard)
		end
	end

	for _, billboard in ipairs(toRemove) do
		local info = trackedDisplays[billboard]
		if billboard then
			billboard.Enabled = false
		end
		cleanupTracking(billboard)
		if info then
			info.distance = nil
		end
	end

	table.sort(entries, function(a, b)
		return (a.distance or math.huge) < (b.distance or math.huge)
	end)

	for index, info in ipairs(entries) do
		local visible = false
		if info.distance then
			if info.distance <= visibilityRadius and index <= maxVisible then
				visible = true
			end
		end

		info.billboard.Enabled = visible
		if visible then
			if distanceScalingEnabled then
				local scale = computeScale(info.distance, statsConfig)
				applyScale(info, scale)
			else
				applyScale(info, 1)
			end
		end
	end

	for i = maxVisible + 1, #entries do
		local info = entries[i]
		if info and info.billboard then
			info.billboard.Enabled = false
		end
	end
end

local function registerClientDisplay(billboardGui, model, focusPart, textElements)
	if not IS_CLIENT then
		return
	end

	local statsConfig = ServerConfigs.Hitbox.mobStatsDisplay
	if not statsConfig then
		return
	end

	local baseSize = statsConfig.size or Vector2.new(170, 120)

	trackedDisplays[billboardGui] = {
		billboard = billboardGui,
		model = model,
		focusPart = focusPart,
		textElements = textElements,
		baseSize = baseSize,
	}

	if not visibilityUpdateConnection then
		visibilityUpdateConnection = RunService.RenderStepped:Connect(updateClientDisplayVisibility)
	end

	updateClientDisplayVisibility()

	billboardGui.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanupTracking(billboardGui)
		end
	end)
end

-- ========================================
-- MOB STATS DISPLAY CREATION
-- ========================================

-- Create floating stats display GUI above a mob
-- @param model: The mob model to attach the GUI to
local function createMobStatsDisplay(model)
	-- Check if enabled in config
	if not ServerConfigs.Hitbox.mobStatsDisplay.enabled then
		return
	end
	
	-- Get configuration
	local statsConfig = ServerConfigs.Hitbox.mobStatsDisplay
	local showStatDetails = statsConfig.showStatDetails ~= false
	
	-- Validate model
	if not model or not model:IsA("Model") then
		warn("[MobStatsDisplay] Invalid model provided")
		return
	end
	
	-- Get required parts
	local head = model:FindFirstChild("Head")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	
	if not head or not humanoid then
		warn("[MobStatsDisplay] Model missing Head or Humanoid:", model.Name)
		return
	end
	
	-- Create BillboardGui
	-- Remove any existing stats display to prevent duplicates (standalone mobs may add their own)
	local existingDisplay = head:FindFirstChild("MobStatsDisplay")
	if existingDisplay then
		existingDisplay:Destroy()
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "MobStatsDisplay"
	billboardGui.Size = UDim2.new(0, statsConfig.size.X, 0, statsConfig.size.Y)
	local offsetY = statsConfig.offsetY
	if not showStatDetails and statsConfig.offsetYNoStat then
		offsetY = statsConfig.offsetYNoStat
	end
	billboardGui.StudsOffset = Vector3.new(0, offsetY, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 1
	billboardGui.MaxDistance = 10000 -- Set very high so our custom visibility logic controls it
	billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboardGui.Enabled = false -- Start disabled, visibility function will enable it
	billboardGui.Parent = head
	
	local textElements = {}
	local function addTextElement(label, baseSize)
		if label then
			table.insert(textElements, {
				label = label,
				baseSize = baseSize or statsConfig.textSize
			})
		end
	end

	-- Create main frame with rounded corners
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = statsConfig.backgroundColor
	mainFrame.BackgroundTransparency = statsConfig.backgroundTransparency
	mainFrame.BorderSizePixel = statsConfig.borderSizePixel
	mainFrame.BorderColor3 = statsConfig.borderColor
	mainFrame.Parent = billboardGui
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, statsConfig.cornerRadius)
	corner.Parent = mainFrame
	
	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.Parent = mainFrame
	
	-- Create layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = mainFrame
	
	-- Create header (mob name/variant)
	local textStrokeColor = statsConfig.textStrokeColor or Color3.new(0, 0, 0)
	local textStrokeTransparency = statsConfig.textStrokeTransparency or 0
	local textStrokeThickness = statsConfig.textStrokeThickness or 0
	local defenseBarBackground, defenseBarFill, defenseBarLabel

	local function applyStrokeToLabel(label, strokeTransparency)
		local effectiveTransparency
		if textStrokeThickness <= 0 then
			effectiveTransparency = 1
		else
			effectiveTransparency = strokeTransparency
			if effectiveTransparency == nil then
				effectiveTransparency = textStrokeTransparency
			end
		end

		label.TextStrokeColor3 = textStrokeColor
		label.TextStrokeTransparency = effectiveTransparency or 1

		local existing = label:FindFirstChild("TextStroke")
		if existing then
			existing:Destroy()
		end

		if textStrokeThickness > 0 then
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Name = "TextStroke"
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Color = textStrokeColor
			uiStroke.Thickness = textStrokeThickness
			uiStroke.Transparency = effectiveTransparency or textStrokeTransparency
			uiStroke.Parent = label
		end
	end

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Name = "HeaderLabel"
	headerLabel.Size = UDim2.new(1, 0, 0, statsConfig.headerSize + 4)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = "Loading..."
	headerLabel.TextColor3 = statsConfig.headerColor or statsConfig.textColor
	headerLabel.TextSize = statsConfig.headerSize
	headerLabel.Font = statsConfig.font
	headerLabel.TextXAlignment = Enum.TextXAlignment.Center
	headerLabel.TextYAlignment = Enum.TextYAlignment.Center
	headerLabel.LayoutOrder = 1
	headerLabel.Parent = mainFrame
	applyStrokeToLabel(headerLabel, statsConfig.headerStrokeTransparency or textStrokeTransparency)
	addTextElement(headerLabel, statsConfig.headerSize)

	local healthBarHeight = statsConfig.healthBarHeight or 12
	local healthBarBackground = Instance.new("Frame")
	healthBarBackground.Name = "HealthBar"
	healthBarBackground.Size = UDim2.new(1, 0, 0, healthBarHeight)
	healthBarBackground.BackgroundColor3 = statsConfig.healthBarBackgroundColor or Color3.fromRGB(35, 35, 35)
	healthBarBackground.BackgroundTransparency = 0
	healthBarBackground.BorderSizePixel = 0
	healthBarBackground.LayoutOrder = 2
	healthBarBackground.Parent = mainFrame

	local healthBarStroke = Instance.new("UIStroke")
	healthBarStroke.Name = "HealthBarStroke"
	healthBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	healthBarStroke.Thickness = 1
	healthBarStroke.Color = statsConfig.healthBarBorderColor or Color3.fromRGB(10, 10, 10)
	healthBarStroke.Parent = healthBarBackground

	local healthBarCorner = Instance.new("UICorner")
	healthBarCorner.CornerRadius = UDim.new(0, statsConfig.healthBarCornerRadius or 4)
	healthBarCorner.Parent = healthBarBackground

	local healthBarFill = Instance.new("Frame")
	healthBarFill.Name = "Fill"
	healthBarFill.Size = UDim2.new(1, 0, 1, 0)
	healthBarFill.BackgroundColor3 = statsConfig.healthBarDefaultColor or Color3.fromRGB(120, 220, 120)
	healthBarFill.BorderSizePixel = 0
	healthBarFill.Parent = healthBarBackground

	local healthBarFillCorner = Instance.new("UICorner")
	healthBarFillCorner.CornerRadius = UDim.new(0, statsConfig.healthBarCornerRadius or 4)
	healthBarFillCorner.Parent = healthBarFill

	local healthBarLabel = Instance.new("TextLabel")
	healthBarLabel.Name = "HealthText"
	healthBarLabel.Size = UDim2.new(1, 0, 1, 0)
	healthBarLabel.BackgroundTransparency = 1
	healthBarLabel.Text = "HP: --/--"
	healthBarLabel.TextColor3 = statsConfig.healthBarTextColor or Color3.new(0, 0, 0)
	healthBarLabel.TextSize = statsConfig.textSize
	healthBarLabel.Font = statsConfig.font
	healthBarLabel.TextXAlignment = Enum.TextXAlignment.Center
	healthBarLabel.TextYAlignment = Enum.TextYAlignment.Center
	healthBarLabel.Parent = healthBarBackground
	addTextElement(healthBarLabel, statsConfig.textSize)

	local defenseBarHeight = statsConfig.defenseBarHeight or math.max((statsConfig.healthBarHeight or 10) - 1, 6)
	defenseBarBackground = Instance.new("Frame")
	defenseBarBackground.Name = "DefenseBar"
	defenseBarBackground.Size = UDim2.new(1, 0, 0, defenseBarHeight)
	defenseBarBackground.BackgroundColor3 = statsConfig.defenseBarBackgroundColor or Color3.fromRGB(40, 40, 40)
	defenseBarBackground.BackgroundTransparency = 0
	defenseBarBackground.BorderSizePixel = 0
	defenseBarBackground.LayoutOrder = 3
	defenseBarBackground.Parent = mainFrame

	local defenseBarStroke = Instance.new("UIStroke")
	defenseBarStroke.Name = "DefenseBarStroke"
	defenseBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	defenseBarStroke.Thickness = 1
	defenseBarStroke.Color = statsConfig.defenseBarBorderColor or Color3.fromRGB(15, 15, 15)
	defenseBarStroke.Parent = defenseBarBackground

	local defenseBarCorner = Instance.new("UICorner")
	defenseBarCorner.CornerRadius = UDim.new(0, statsConfig.defenseBarCornerRadius or statsConfig.healthBarCornerRadius or 4)
	defenseBarCorner.Parent = defenseBarBackground

	defenseBarFill = Instance.new("Frame")
	defenseBarFill.Name = "Fill"
	defenseBarFill.Size = UDim2.new(0, 0, 1, 0)
	defenseBarFill.BackgroundColor3 = statsConfig.defenseBarDefaultColor or Color3.fromRGB(120, 170, 220)
	defenseBarFill.BorderSizePixel = 0
	defenseBarFill.Parent = defenseBarBackground

	local defenseBarFillCorner = Instance.new("UICorner")
	defenseBarFillCorner.CornerRadius = UDim.new(0, statsConfig.defenseBarCornerRadius or statsConfig.healthBarCornerRadius or 4)
	defenseBarFillCorner.Parent = defenseBarFill

	defenseBarLabel = Instance.new("TextLabel")
	defenseBarLabel.Name = "DefenseText"
	defenseBarLabel.Size = UDim2.new(1, 0, 1, 0)
	defenseBarLabel.BackgroundTransparency = 1
	defenseBarLabel.Text = "Defense: --/--"
	defenseBarLabel.TextColor3 = statsConfig.defenseBarTextColor or statsConfig.textColor or Color3.new(1, 1, 1)
	defenseBarLabel.TextSize = statsConfig.textSize
	defenseBarLabel.Font = statsConfig.font
	defenseBarLabel.TextXAlignment = Enum.TextXAlignment.Center
	defenseBarLabel.TextYAlignment = Enum.TextYAlignment.Center
	defenseBarLabel.Parent = defenseBarBackground
	addTextElement(defenseBarLabel, statsConfig.textSize)

	local statsContainerOffset = statsConfig.headerSize + healthBarHeight + defenseBarHeight + 12
	local levelLabel, defenseLabel, critRateLabel, critMultLabel, dmgLabel, defensePenLabel, xpLabel
	if showStatDetails then
		-- Create stat labels container
		local statsContainer = Instance.new("Frame")
		statsContainer.Name = "StatsContainer"
		statsContainer.Size = UDim2.new(1, 0, 1, -statsContainerOffset)
		statsContainer.BackgroundTransparency = 1
		statsContainer.LayoutOrder = 4
		statsContainer.Parent = mainFrame

		local statsLayout = Instance.new("UIListLayout")
		statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		statsLayout.Padding = UDim.new(0, 1)
		statsLayout.FillDirection = Enum.FillDirection.Vertical
		statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		statsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		statsLayout.Parent = statsContainer

		-- Helper function to create a stat row
		local function createStatRow(labelText, layoutOrder)
			local row = Instance.new("Frame")
			row.Name = "StatRow_" .. labelText
			row.Size = UDim2.new(1, 0, 0, statsConfig.textSize + 2)
			row.BackgroundTransparency = 1
			row.LayoutOrder = layoutOrder
			row.Parent = statsContainer
			
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = labelText
			label.TextColor3 = statsConfig.textColor
			label.TextSize = statsConfig.textSize
			label.Font = statsConfig.font
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = row
			applyStrokeToLabel(label)
			addTextElement(label, statsConfig.textSize)
			
			return label
		end

		-- Create stat rows
		levelLabel = createStatRow("Level: --", 1)
		defenseLabel = createStatRow("Defense: --/--", 2)
		critRateLabel = createStatRow("Crit: --%", 3)
		critMultLabel = createStatRow("Crit Mult: --x", 4)
		dmgLabel = createStatRow("Damage: --", 5)
		defensePenLabel = createStatRow("DP: --", 6)
		xpLabel = createStatRow("XP Gain: --", 7)
	end
	
	-- Update function (reads current values from attributes and humanoid)
	local function updateStats()
		-- Check if model still exists
		if not model.Parent or not humanoid.Parent then
			billboardGui:Destroy()
			cleanupTracking(billboardGui)
			return
		end
		
		-- Get mob display name / colors
		local displayName = model:GetAttribute("MobDisplayName") or model:GetAttribute("MobVariant") or "Unknown"
		headerLabel.Text = displayName
		headerLabel.TextColor3 = statsConfig.headerColor or statsConfig.textColor

		if showStatDetails and levelLabel then
			local levelValue = model:GetAttribute("MobLevel")
			if typeof(levelValue) == "number" and levelValue > 0 then
				levelLabel.Text = string.format("Level: %d", levelValue)
				levelLabel.TextColor3 = statsConfig.levelLabelColor or statsConfig.textColor
			else
				levelLabel.Text = "Level: --"
				levelLabel.TextColor3 = statsConfig.textColor
			end
		end

		-- Get current health/max health
		local currentHealth = humanoid.Health
		local maxHealth = humanoid.MaxHealth
		local healthPercent = maxHealth > 0 and math.clamp(currentHealth / maxHealth, 0, 1) or 0
		healthBarFill.Size = UDim2.new(healthPercent, 0, 1, 0)
		healthBarLabel.Text = string.format("HP: %.0f/%.0f", currentHealth, maxHealth)
		local barColor = model:GetAttribute("MobHealthBarColor")
		if typeof(barColor) == "Color3" then
			healthBarFill.BackgroundColor3 = barColor
		else
			healthBarFill.BackgroundColor3 = statsConfig.healthBarDefaultColor or Color3.fromRGB(120, 220, 120)
		end
		
		local currentDefenseAttr = model:GetAttribute("CurrentDefense")
		local maxDefenseAttr = model:GetAttribute("MaxDefense")
		local currentDefense = (typeof(currentDefenseAttr) == "number" and currentDefenseAttr) or 0
		local maxDefense = (typeof(maxDefenseAttr) == "number" and maxDefenseAttr) or 0

		if defenseBarFill and defenseBarLabel and defenseBarBackground then
			if maxDefense > 0 then
				local defensePercent = math.clamp(currentDefense / maxDefense, 0, 1)
				defenseBarFill.Size = UDim2.new(defensePercent, 0, 1, 0)
				local defenseBarColor = model:GetAttribute("MobDefenseBarColor")
				if typeof(defenseBarColor) == "Color3" then
					defenseBarFill.BackgroundColor3 = defenseBarColor
				else
					defenseBarFill.BackgroundColor3 = statsConfig.defenseBarDefaultColor or Color3.fromRGB(120, 170, 220)
				end
				defenseBarLabel.Text = string.format("Defense: %.0f/%.0f", currentDefense, maxDefense)
				defenseBarLabel.TextColor3 = statsConfig.defenseBarTextColor or statsConfig.textColor or Color3.new(1, 1, 1)
			else
				defenseBarFill.Size = UDim2.new(0, 0, 1, 0)
				defenseBarFill.BackgroundColor3 = statsConfig.defenseBarDefaultColor or Color3.fromRGB(120, 170, 220)
				defenseBarLabel.Text = "Defense: None"
				defenseBarLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
			end
			defenseBarBackground.Visible = true
		end

		-- Get defense stats from attributes (these are updated by DynamicHitboxV3 when defense is damaged)
		if showStatDetails then
			if defenseLabel then
				if maxDefense > 0 then
					defenseLabel.Text = string.format("Defense: %.0f/%.0f", currentDefense, maxDefense)
					defenseLabel.TextColor3 = statsConfig.textColor
				else
					defenseLabel.Text = "Defense: None"
					defenseLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5) -- Gray
				end
			end
			
			if critRateLabel then
				local critRate = model:GetAttribute("CritRate") or 0
				critRateLabel.Text = string.format("Crit: %.0f%%", critRate)
			end
			
			if critMultLabel then
				local critMult = model:GetAttribute("CritMultiplier") or 150
				critMultLabel.Text = string.format("Crit Mult: %.1fx", critMult / 100)
			end
			
			if dmgLabel then
				local damage = model:GetAttribute("Damage") or 0
				dmgLabel.Text = string.format("Damage: %.0f", damage)
			end
			
			if defensePenLabel then
				local defensePen = model:GetAttribute("DefensePenetration") or 0
				defensePenLabel.Text = string.format("DP: %.0f", defensePen)
			end

			if xpLabel then
				local xpGain = model:GetAttribute("XPGain")
				if xpGain then
					xpLabel.Text = string.format("XP Gain: %.0f", xpGain)
				else
					xpLabel.Text = "XP Gain: --"
				end
			end
		end
	end
	
	-- Initial update
	updateStats()
	
	-- Set up update loop with throttling (to avoid excessive updates)
	local lastUpdate = 0
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local now = tick()
		-- Only update if enough time has passed (throttle updates)
		if now - lastUpdate >= statsConfig.updateRate then
			updateStats()
			lastUpdate = now
		end
	end)
	
	-- Also listen to attribute changes for immediate updates (especially for CurrentDefense)
	-- Use GetAttributeChangedSignal for each attribute we care about
	local attributeConnections = {}
	local function setupAttributeListeners()
		local attributesToWatch = {
			"MobVariant",
			"MobDisplayName",
			"MobHealthBarColor",
			"MobDefenseBarColor",
			"MobLevel",
			"XPGain",
			"CurrentDefense",
			"MaxDefense"
		}
		if showStatDetails then
			table.insert(attributesToWatch, "Damage")
			table.insert(attributesToWatch, "DefensePenetration")
			table.insert(attributesToWatch, "CritRate")
			table.insert(attributesToWatch, "CritMultiplier")
		end
		for _, attrName in ipairs(attributesToWatch) do
			local connection = model:GetAttributeChangedSignal(attrName):Connect(function()
				updateStats()
			end)
			table.insert(attributeConnections, connection)
		end
	end
	setupAttributeListeners()
	
	-- Cleanup on model removal
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			cleanupTracking(billboardGui)
			if connection then
				connection:Disconnect()
			end
			-- Disconnect all attribute listeners
			for _, conn in ipairs(attributeConnections) do
				if conn then
					conn:Disconnect()
				end
			end
			billboardGui:Destroy()
		end
	end)

	local focusPart = getFocusPart(model) or head
	registerClientDisplay(billboardGui, model, focusPart, textElements)
end

-- ========================================
-- MODULE EXPORTS
-- ========================================

local MobStatsDisplay = {}

MobStatsDisplay.createMobStatsDisplay = createMobStatsDisplay

-- Make globally available for AI modules
_G.createMobStatsDisplay = createMobStatsDisplay

return MobStatsDisplay

