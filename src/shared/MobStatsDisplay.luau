-- ========================================
-- MOB STATS DISPLAY MODULE
-- Floating GUI above mobs showing real-time stats
-- ========================================

local Players = game:GetService("Players")
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
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Name = "HeaderLabel"
	headerLabel.Size = UDim2.new(1, 0, 0, statsConfig.headerSize + 4)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = "Loading..."
	headerLabel.TextColor3 = statsConfig.headerColor
	headerLabel.TextSize = statsConfig.headerSize
	headerLabel.Font = statsConfig.font
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.LayoutOrder = 1
	headerLabel.Parent = mainFrame
	
	-- Create stat labels container
	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(1, 0, 1, -statsConfig.headerSize - 6)
	statsContainer.BackgroundTransparency = 1
	statsContainer.LayoutOrder = 2
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
		
		return label
	end
	
	-- Create stat rows
	local healthLabel = createStatRow("HP: --/--", 1)
	local defenseLabel = createStatRow("Defense: --/--", 2)
	local critRateLabel = createStatRow("Crit: --%", 3)
	local critMultLabel = createStatRow("Crit Mult: --x", 4)
	local dmgLabel = createStatRow("Damage: --", 5)
	local defensePenLabel = createStatRow("DP: --", 6)
	
	-- Update function
	local lastUpdate = 0
	local function updateStats()
		-- Check if model still exists
		if not model.Parent or not humanoid.Parent then
			billboardGui:Destroy()
			return
		end
		
		local now = tick()
		if now - lastUpdate < statsConfig.updateRate then
			return
		end
		lastUpdate = now
		
		-- Get mob variant
		local variant = model:GetAttribute("MobVariant") or "Unknown"
		headerLabel.Text = variant
		
		-- Get current health/max health
		local currentHealth = humanoid.Health
		local maxHealth = humanoid.MaxHealth
		healthLabel.Text = string.format("HP: %.0f/%.0f", currentHealth, maxHealth)
		
		-- Color health based on percentage
		local healthPercent = currentHealth / maxHealth
		if healthPercent > 0.5 then
			healthLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
		elseif healthPercent > 0.2 then
			healthLabel.TextColor3 = Color3.new(1, 1, 0) -- Yellow
		else
			healthLabel.TextColor3 = Color3.new(1, 0, 0) -- Red
		end
		
		-- Get defense stats from attributes
		local currentDefense = model:GetAttribute("CurrentDefense") or 0
		local maxDefense = model:GetAttribute("MaxDefense") or 0
		
		if maxDefense > 0 then
			defenseLabel.Text = string.format("Defense: %.0f/%.0f", currentDefense, maxDefense)
			defenseLabel.TextColor3 = statsConfig.textColor
		else
			defenseLabel.Text = "Defense: None"
			defenseLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5) -- Gray
		end
		
		-- Get crit stats
		local critRate = model:GetAttribute("CritRate") or 0
		local critMult = model:GetAttribute("CritMultiplier") or 100
		critRateLabel.Text = string.format("Crit: %.0f%%", critRate)
		critMultLabel.Text = string.format("Crit Mult: %.1fx", critMult / 100)
		
		-- Get damage
		local damage = model:GetAttribute("Damage") or 0
		dmgLabel.Text = string.format("Damage: %.0f", damage)
		
		-- Get defense penetration
		local defensePen = model:GetAttribute("DefensePenetration") or 0
		defensePenLabel.Text = string.format("DP: %.0f", defensePen)
	end
	
	-- Initial update
	updateStats()
	
	-- Set up update loop
	local connection
	connection = RunService.Heartbeat:Connect(function()
		updateStats()
	end)
	
	-- Cleanup on model removal
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			if connection then
				connection:Disconnect()
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

