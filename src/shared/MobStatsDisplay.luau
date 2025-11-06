-- ========================================
-- MOB STATS DISPLAY MODULE
-- Floating GUI above mobs showing real-time stats
-- ========================================

local RunService = game:GetService("RunService")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

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
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "MobStatsDisplay"
	billboardGui.Size = UDim2.new(0, statsConfig.size.X, 0, statsConfig.size.Y)
	billboardGui.StudsOffset = Vector3.new(0, statsConfig.offsetY, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 1
	billboardGui.MaxDistance = 50 -- Hide beyond this distance
	billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboardGui.Enabled = true
	billboardGui.Parent = head
	
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
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.LayoutOrder = 1
	headerLabel.Parent = mainFrame
	applyStrokeToLabel(headerLabel, statsConfig.headerStrokeTransparency or textStrokeTransparency)

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

	local levelLabel, defenseLabel, critRateLabel, critMultLabel, dmgLabel, defensePenLabel, xpLabel
	if showStatDetails then
		-- Create stat labels container
		local statsContainer = Instance.new("Frame")
		statsContainer.Name = "StatsContainer"
		statsContainer.Size = UDim2.new(1, 0, 1, -statsConfig.headerSize - healthBarHeight - 10)
		statsContainer.BackgroundTransparency = 1
		statsContainer.LayoutOrder = 3
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
		
		-- Get defense stats from attributes (these are updated by DynamicHitboxV3 when defense is damaged)
		if showStatDetails then
			local currentDefense = model:GetAttribute("CurrentDefense") or 0
			local maxDefense = model:GetAttribute("MaxDefense") or 0
			
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
			"MobLevel",
			"XPGain"
		}
		if showStatDetails then
			table.insert(attributesToWatch, "CurrentDefense")
			table.insert(attributesToWatch, "MaxDefense")
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
end

-- ========================================
-- MODULE EXPORTS
-- ========================================

local MobStatsDisplay = {}

MobStatsDisplay.createMobStatsDisplay = createMobStatsDisplay

-- Make globally available for AI modules
_G.createMobStatsDisplay = createMobStatsDisplay

return MobStatsDisplay

