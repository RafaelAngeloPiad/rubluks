local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")

local DevStatEvent = ReplicatedStorage:WaitForChild("DevStatEvent", 10)

local DevSettingsFolder = ReplicatedStorage:FindFirstChild("DevSettings") or ReplicatedStorage:WaitForChild("DevSettings", 5)
local FriendlyFireFolder = DevSettingsFolder and (DevSettingsFolder:FindFirstChild("FriendlyFire") or DevSettingsFolder:WaitForChild("FriendlyFire", 5))
local playerFriendlyFireValue = FriendlyFireFolder and (FriendlyFireFolder:FindFirstChild("Players") or FriendlyFireFolder:WaitForChild("Players", 5))
local mobFriendlyFireValue = FriendlyFireFolder and (FriendlyFireFolder:FindFirstChild("Mobs") or FriendlyFireFolder:WaitForChild("Mobs", 5))
local mobCombatModeValue = FriendlyFireFolder and (FriendlyFireFolder:FindFirstChild("MobCombatMode") or FriendlyFireFolder:WaitForChild("MobCombatMode", 5))
local godModeValue = leaderstats:FindFirstChild("GodMode") or leaderstats:WaitForChild("GodMode", 5)
local statusImmunityValue = leaderstats:FindFirstChild("StatusImmunity") or leaderstats:WaitForChild("StatusImmunity", 5)

local ServerConfigs = ReplicatedStorage:WaitForChild("SlavkosConfigs", 10)
local ConfigModule = nil
if ServerConfigs then
	local success, config = pcall(function()
		return require(ServerConfigs)
	end)
	if success then
		ConfigModule = config
	end
end

local MasterControlsConfig = ConfigModule and ConfigModule.ControlUI and ConfigModule.ControlUI.masterControls
local masterControlsEnabled = not (MasterControlsConfig and MasterControlsConfig.enabled == false)

if not masterControlsEnabled then
	return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasterControlDisplay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 99
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local BASE_FRAME_SIZE = Vector2.new(370, 340)
local BASE_MARGIN = 10
local BASE_POSITION = UDim2.new(1, -BASE_MARGIN, 0.5, 0)
local BASE_ANCHOR_POINT = Vector2.new(1, 0.5)
local hasCustomPosition = false
local cameraViewportConn = nil

local mainFrame = Instance.new("Frame")
mainFrame.Name = "ControlFrame"
mainFrame.Size = UDim2.new(0, BASE_FRAME_SIZE.X, 0, BASE_FRAME_SIZE.Y)
mainFrame.AnchorPoint = BASE_ANCHOR_POINT
mainFrame.Position = BASE_POSITION
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = mainFrame
local currentScale = 1

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextButton")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "🛠️ MASTER CONTROL (Drag to Move)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.AutoButtonColor = false
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local isDragging = false
local dragInput = nil
local dragStartInput = nil
local dragStartPosition = nil

local function getInputPosition(input)
	local topLeftInset = Vector2.zero
	if GuiService then
		local inset, _ = GuiService:GetGuiInset()
		topLeftInset = inset
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		local position = input.Position
		return Vector2.new(position.X, position.Y) - topLeftInset
	end

	return UserInputService:GetMouseLocation() - topLeftInset
end

local function beginDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	isDragging = true
	hasCustomPosition = true
	dragInput = input
	dragStartInput = getInputPosition(input)
	dragStartPosition = mainFrame.Position

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			isDragging = false
			if dragInput == input then
				dragInput = nil
				dragStartInput = nil
				dragStartPosition = nil
			end
		end
	end)
end

title.InputBegan:Connect(function(input)
	beginDrag(input)
end)

local function updateDragPosition(input)
	if not isDragging then
		return
	end

	if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if not dragStartInput or not dragStartPosition then
		return
	end

	local currentPos = getInputPosition(input)
	local delta = currentPos - dragStartInput

	mainFrame.Position = UDim2.new(
		dragStartPosition.X.Scale,
		dragStartPosition.X.Offset + delta.X,
		dragStartPosition.Y.Scale,
		dragStartPosition.Y.Offset + delta.Y
	)
end

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
		updateDragPosition(input)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
		if input == dragInput then
			dragInput = nil
			dragStartInput = nil
			dragStartPosition = nil
		end
	end
end)


local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ButtonContainer"
contentFrame.Size = UDim2.new(1, -10, 1, -75)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 5
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
contentFrame.Parent = mainFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingBottom = UDim.new(0, 150)
contentPadding.PaddingTop = UDim.new(0, 5)
contentPadding.Parent = contentFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Padding = UDim.new(0, 8)
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.FillDirection = Enum.FillDirection.Vertical
buttonLayout.Parent = contentFrame

-- Update canvas size when content changes
local function updateContentCanvas()
	task.wait(0.1)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, buttonLayout.AbsoluteContentSize.Y + 180)
end

buttonLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentCanvas)

-- Close/Exit button at bottom
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(1, -10, 0, 30)
exitButton.Position = UDim2.new(0, 5, 1, -35)
exitButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
exitButton.BorderSizePixel = 0
exitButton.Text = "❌ CLOSE"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextSize = 14
exitButton.Font = Enum.Font.GothamBold
exitButton.Parent = mainFrame

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 5)
exitCorner.Parent = exitButton

exitButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	screenGui.Enabled = false
end)

exitButton.MouseEnter:Connect(function()
	exitButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
end)

exitButton.MouseLeave:Connect(function()
	exitButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
end)

local function determineUIScale()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local minDimension = math.min(viewport.X, viewport.Y)

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		if minDimension <= 720 then
			return 0.55
		elseif minDimension <= 900 then
			return 0.65
		end
		return 0.75
	end

	if viewport.X <= 1440 then
		return 0.9
	end

	return 0.95
end

local function applyUIScaling()
	local newScale = determineUIScale()
	if math.abs(newScale - currentScale) > 1e-3 then
		currentScale = newScale
		uiScale.Scale = newScale
	end

	if not hasCustomPosition then
		mainFrame.Position = BASE_POSITION
	end
end

local function bindViewportListener(camera)
	if cameraViewportConn then
		cameraViewportConn:Disconnect()
		cameraViewportConn = nil
	end
	if camera then
		cameraViewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			task.defer(applyUIScaling)
		end)
	end
end

local function refreshViewportScaling()
	bindViewportListener(Workspace.CurrentCamera)
	applyUIScaling()
end

if Workspace.CurrentCamera then
	refreshViewportScaling()
else
	task.defer(applyUIScaling)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(refreshViewportScaling)
end)

local function createButton(text, color, layoutOrder, onClick, tooltip)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.95, 0, 0, 28)
	button.BackgroundTransparency = 0
	local baseColor = color or Color3.fromRGB(50, 50, 50)
	button.BackgroundColor3 = baseColor
	button:SetAttribute("BaseColor", baseColor)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = layoutOrder
	button.Parent = contentFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = button
	
	-- Add tooltip if provided
	if tooltip then
		button:SetAttribute("Tooltip", tooltip)
	end

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
	end)

	button.MouseLeave:Connect(function()
		local storedBase = button:GetAttribute("BaseColor")
		button.BackgroundColor3 = storedBase or baseColor
	end)

	return button
end

local layoutOrder = 1
local isVisible = false

-- Tables to store sensitive buttons (hidden by default)
local sensitiveButtons = {}
local hasAdvancedAccess = false

-- Reset button (HIDDEN by default - requires advanced access)
local resetButton = createButton("Reset", Color3.fromRGB(150, 50, 50), layoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("fullReset")
	end
end)
resetButton.Visible = false
table.insert(sensitiveButtons, resetButton)
layoutOrder += 1

local xpButtons = {
	{label = "+5 XP", color = Color3.fromRGB(50, 150, 50), amount = 5},
	{label = "+10 XP", color = Color3.fromRGB(50, 180, 50), amount = 10},
	{label = "+500 XP", color = Color3.fromRGB(100, 200, 100), amount = 500},
	{label = "+5000 XP", color = Color3.fromRGB(120, 220, 120), amount = 5000},
	{label = "+100000 XP", color = Color3.fromRGB(90, 200, 90), amount = 100000},
	{label = "+9999999999 XP", color = Color3.fromRGB(150, 255, 150), amount = 9999999999},
}

-- XP buttons (HIDDEN by default - require advanced access)
for _, entry in ipairs(xpButtons) do
	local xpButton = createButton(entry.label, entry.color, layoutOrder, function()
		if DevStatEvent then
			DevStatEvent:FireServer("addCurrentXP", entry.amount)
		end
	end)
	xpButton.Visible = false
	table.insert(sensitiveButtons, xpButton)
	layoutOrder += 1
end

local classButtons = {
	{label = "Knight", class = "Knight", color = Color3.fromRGB(100, 150, 200)},
	{label = "Samurai", class = "Samurai", color = Color3.fromRGB(150, 150, 150)},
	{label = "Gladiator", class = "Gladiator", color = Color3.fromRGB(200, 100, 100)},
	{label = "Brawler", class = "Brawler", color = Color3.fromRGB(150, 100, 50)},
	{label = "Archer", class = "Archer", color = Color3.fromRGB(100, 200, 100)},
}

-- Class buttons (HIDDEN by default - require advanced access)
for _, entry in ipairs(classButtons) do
	local classButton = createButton(entry.label, entry.color, layoutOrder, function()
		if DevStatEvent then
			DevStatEvent:FireServer("setClass", entry.class)
		end
	end)
	classButton.Visible = false
	table.insert(sensitiveButtons, classButton)
	layoutOrder += 1
end

local playerFriendlyLocalState = playerFriendlyFireValue and playerFriendlyFireValue.Value or false
local mobFriendlyLocalState = mobFriendlyFireValue and mobFriendlyFireValue.Value or false
local mobCombatModeLocalState = mobCombatModeValue and mobCombatModeValue.Value or "excluded"
local godModeLocalState = godModeValue and godModeValue.Value or false
local statusImmuneLocalState = statusImmunityValue and statusImmunityValue.Value or false

-- Utility buttons
local CommandHelpEvent = ReplicatedStorage:FindFirstChild("CommandHelpEvent")
local AdminPanelToggle = ReplicatedStorage:FindFirstChild("AdminPanelToggle")
local FlightEvent = ReplicatedStorage:FindFirstChild("FlightEvent")

-- Commands button - Opens /commands UI
local commandsButton = createButton("📋 Commands", Color3.fromRGB(80, 120, 200), layoutOrder, function()
	-- Find the commands display GUI
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local commandsDisplay = playerGui:FindFirstChild("CommandsDisplay")
		if commandsDisplay then
			local mainFrame = commandsDisplay:FindFirstChild("MainFrame")
			if mainFrame then
				mainFrame.Visible = not mainFrame.Visible
				commandsDisplay.Enabled = mainFrame.Visible
			end
		end
	end
end, "Open the commands help window to see all available commands.")
layoutOrder += 1

-- Admin Panel button - Super admin only
local ChatAccessControl = require(ReplicatedStorage:WaitForChild("ChatAccessControl"))
local isSuperAdmin = ChatAccessControl.isSuperAdmin(player)

if isSuperAdmin and AdminPanelToggle then
	local adminPanelButton = createButton("👑 Admin Panel", Color3.fromRGB(200, 150, 50), layoutOrder, function()
		-- Use the same toggle event as /admin command
		AdminPanelToggle:FireServer()
	end, "Open the admin panel to manage players, toggle admin status, kick, or ban.")
	layoutOrder += 1
end

-- Flight toggle button
local flightActive = false
local flightButton = nil
flightButton = createButton("✈️ Flight: OFF", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	flightActive = not flightActive
	if FlightEvent then
		if flightActive then
			FlightEvent:FireServer("enable")
			if flightButton then
				flightButton.Text = "✈️ Flight: ON"
				flightButton:SetAttribute("BaseColor", Color3.fromRGB(100, 180, 220))
				flightButton.BackgroundColor3 = Color3.fromRGB(100, 180, 220)
			end
		else
			FlightEvent:FireServer("disable")
			if flightButton then
				flightButton.Text = "✈️ Flight: OFF"
				flightButton:SetAttribute("BaseColor", Color3.fromRGB(60, 60, 60))
				flightButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			end
		end
	end
end, "Toggle flight mode on/off. Fly around the map using WASD controls.")
layoutOrder += 1

-- Clear Spawned button
local ClearSpawnedEvent = ReplicatedStorage:FindFirstChild("ClearSpawnedEvent")
if ClearSpawnedEvent then
	local clearButton = createButton("🧹 Clear Spawned", Color3.fromRGB(150, 80, 200), layoutOrder, function()
		ClearSpawnedEvent:FireServer()
	end, "Clear all spawned objects/mobs within 200 studs of your position.")
	layoutOrder += 1
end

-- Main toggle buttons
local playerFriendlyButton = createButton("PVP: OFF", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	local newValue
	if playerFriendlyFireValue then
		newValue = not playerFriendlyFireValue.Value
	else
		newValue = not playerFriendlyLocalState
		playerFriendlyLocalState = newValue
	end
	if DevStatEvent then
		DevStatEvent:FireServer("setPlayerFriendlyFire", newValue)
	end
end, "Player vs Player combat. Default OFF. Enable to let players fight each other and test their strength.")
layoutOrder += 1

local mobFriendlyButton = createButton("Mob FF: OFF", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	local newValue
	if mobFriendlyFireValue then
		newValue = not mobFriendlyFireValue.Value
	else
		newValue = not mobFriendlyLocalState
		mobFriendlyLocalState = newValue
	end
	if DevStatEvent then
		DevStatEvent:FireServer("setMobFriendlyFire", newValue)
	end
end, "Mob Friendly Fire. Default OFF. Enemies can't hurt each other when attacks overlap. Already handled by Mob Mode.")
layoutOrder += 1

local MobCombatModeOrder = {"excluded", "versus", "frenzy", "peaceful"}
local MobCombatModeMetadata = {
	excluded = {
		label = "Mob Mode: Excluded",
		color = Color3.fromRGB(60, 60, 60),
	},
	versus = {
		label = "Mob Mode: Versus",
		color = Color3.fromRGB(180, 140, 60),
	},
	frenzy = {
		label = "Mob Mode: Frenzy",
		color = Color3.fromRGB(180, 60, 60),
	},
	peaceful = {
		label = "Mob Mode: Peaceful",
		color = Color3.fromRGB(60, 180, 60),
	},
}

local function getNextMobCombatMode(current)
	local index = table.find(MobCombatModeOrder, current)
	if not index then
		return MobCombatModeOrder[1]
	end
	index += 1
	if index > #MobCombatModeOrder then
		index = 1
	end
	return MobCombatModeOrder[index]
end

local godModeButton = nil
local statusImmunityButton = nil

local function updateGodModeButton(forceState)
	if not godModeButton then
		return
	end
	local enabled = forceState
	if enabled == nil then
		enabled = godModeValue and godModeValue.Value
		if enabled == nil then
			enabled = godModeLocalState
		end
	end
	godModeLocalState = enabled and true or false

	local text = godModeLocalState and "God Mode: ON" or "God Mode: OFF"
	local color = godModeLocalState and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(60, 60, 60)

	godModeButton.Text = text
	godModeButton:SetAttribute("BaseColor", color)
	godModeButton.BackgroundColor3 = color
end

local mobModeButton
mobModeButton = createButton("Mob Mode: Excluded", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	local nextMode = getNextMobCombatMode(mobCombatModeLocalState)
	mobCombatModeLocalState = nextMode
	local metadata = MobCombatModeMetadata[nextMode] or MobCombatModeMetadata.excluded
	mobModeButton.Text = metadata.label
	mobModeButton:SetAttribute("BaseColor", metadata.color)
	mobModeButton.BackgroundColor3 = metadata.color
	if DevStatEvent then
		DevStatEvent:FireServer("setMobCombatMode", nextMode)
	end
end, "Mob behavior: Excluded=normal (attack players only), Versus=faction wars (Zombies vs Spiders), Frenzy=chaos (all fight all), Peaceful=no combat.")
layoutOrder += 1

local function updateMobModeButton()
	if not mobModeButton then
		return
	end
	local currentMode = mobCombatModeValue and mobCombatModeValue.Value or mobCombatModeLocalState
	if currentMode == nil or currentMode == "" then
		currentMode = "excluded"
	end
	mobCombatModeLocalState = currentMode
	local metadata = MobCombatModeMetadata[currentMode] or MobCombatModeMetadata.excluded
	mobModeButton.Text = metadata.label
	mobModeButton:SetAttribute("BaseColor", metadata.color)
	mobModeButton.BackgroundColor3 = metadata.color
end

updateMobModeButton()

if mobCombatModeValue then
	mobCombatModeValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateMobModeButton()
	end)
end

godModeButton = createButton("God Mode: OFF", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	local nextState = not godModeLocalState
	godModeLocalState = nextState
	if DevStatEvent then
		DevStatEvent:FireServer("setGodMode", nextState)
	end
	updateGodModeButton(nextState)
end, "Invincibility mode. Players do not die while fighting. Perfect for testing without interruption.")
layoutOrder += 1

updateGodModeButton()

if godModeValue then
	godModeValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateGodModeButton()
	end)
end

local function updateStatusImmunityButton(forceState)
	if not statusImmunityButton then
		return
	end
	local enabled = forceState
	if enabled == nil then
		enabled = statusImmunityValue and statusImmunityValue.Value
		if enabled == nil then
			enabled = statusImmuneLocalState
		end
	end
	statusImmuneLocalState = enabled and true or false

	local text = statusImmuneLocalState and "Status Immunity: ON" or "Status Immunity: OFF"
	local color = statusImmuneLocalState and Color3.fromRGB(100, 180, 220) or Color3.fromRGB(60, 60, 60)

	statusImmunityButton.Text = text
	statusImmunityButton:SetAttribute("BaseColor", color)
	statusImmunityButton.BackgroundColor3 = color
end

statusImmunityButton = createButton("Status Immunity: OFF", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	local nextState = not statusImmuneLocalState
	statusImmuneLocalState = nextState
	if DevStatEvent then
		DevStatEvent:FireServer("setStatusImmunity", nextState)
	end
	updateStatusImmunityButton(nextState)
end, "Bypass all status effects. Enemies cannot Stun, Slow, Freeze, or Burn you.")
layoutOrder += 1

updateStatusImmunityButton()

if statusImmunityValue then
	statusImmunityValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateStatusImmunityButton()
	end)
end

local function updatePlayerFriendlyButton()
	if not playerFriendlyButton then
		return
	end
	local enabled = playerFriendlyFireValue and playerFriendlyFireValue.Value or playerFriendlyLocalState
	playerFriendlyLocalState = enabled
	playerFriendlyButton.Text = enabled and "PVP: ON" or "PVP: OFF"
	local color = enabled and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 60, 60)
	playerFriendlyButton:SetAttribute("BaseColor", color)
	playerFriendlyButton.BackgroundColor3 = color
end

local function updateMobFriendlyButton()
	if not mobFriendlyButton then
		return
	end
	local enabled = mobFriendlyFireValue and mobFriendlyFireValue.Value or mobFriendlyLocalState
	mobFriendlyLocalState = enabled
	mobFriendlyButton.Text = enabled and "Mob FF: ON" or "Mob FF: OFF"
	local color = enabled and Color3.fromRGB(100, 150, 220) or Color3.fromRGB(60, 60, 60)
	mobFriendlyButton:SetAttribute("BaseColor", color)
	mobFriendlyButton.BackgroundColor3 = color
end

updatePlayerFriendlyButton()
updateMobFriendlyButton()

if playerFriendlyFireValue then
	playerFriendlyFireValue:GetPropertyChangedSignal("Value"):Connect(function()
		playerFriendlyLocalState = playerFriendlyFireValue.Value
		updatePlayerFriendlyButton()
	end)
end

if mobFriendlyFireValue then
	mobFriendlyFireValue:GetPropertyChangedSignal("Value"):Connect(function()
		mobFriendlyLocalState = mobFriendlyFireValue.Value
		updateMobFriendlyButton()
	end)
end

-- Function to show/hide sensitive buttons based on advanced access
local function updateSensitiveButtonsVisibility()
	for _, button in ipairs(sensitiveButtons) do
		button.Visible = hasAdvancedAccess
	end
end

-- Listen for panel unlock events
local PanelUnlockEvent = ReplicatedStorage:WaitForChild("PanelUnlockEvent", 10)
if PanelUnlockEvent then
	PanelUnlockEvent.OnClientEvent:Connect(function(basicUnlock, advancedUnlock)
		if basicUnlock then
			-- Basic unlock - show the panel
			screenGui.Enabled = true
		end
		
		if advancedUnlock then
			-- Advanced unlock - show sensitive buttons
			hasAdvancedAccess = true
			updateSensitiveButtonsVisibility()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.PageUp then
		isVisible = not isVisible
		mainFrame.Visible = isVisible
		screenGui.Enabled = isVisible
	end
end)

-- Help text inside the scrolling content frame (at the bottom)
local helpText = Instance.new("TextLabel")
helpText.Name = "HelpText"
helpText.Size = UDim2.new(0.95, 0, 0, 0)
helpText.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
helpText.BackgroundTransparency = 0.5
helpText.BorderSizePixel = 0
helpText.TextColor3 = Color3.fromRGB(200, 200, 200)
helpText.TextSize = 13
helpText.Font = Enum.Font.Gotham
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top
helpText.TextWrapped = true
helpText.RichText = true
helpText.AutomaticSize = Enum.AutomaticSize.Y
helpText.LayoutOrder = 9999
helpText.Text = [[📖 MASTER CONTROL PANEL GUIDE

To access these controls, admins must type /slavko every time they join a place.

🎮 TOGGLES:

PVP (Player vs Player) - Default: OFF
Enable to let players fight each other and test their strength.

Mob Mode - Default: <font color="#EBD4D4">Excluded</font>
• <font color="#EBD4D4">Excluded</font>: Normal mode - enemies only attack players
• <font color="#B48C3C">Versus</font>: Faction wars - enemies attack different types (Zombies vs Spiders)
• <font color="#B43C3C">Frenzy</font>: Total chaos - all enemies fight each other
• <font color="#3CB43C">Peaceful</font>: No combat - enemies don't hurt players or each other

Mob FF (Mob Friendly Fire) - Default: OFF
Enemies can't hurt each other when attacks overlap. Already handled by Mob Mode.

God Mode - Default: OFF
Invincibility mode. Players do not die while fighting. Perfect for testing.

Status Immunity - Default: OFF
Bypass all status effects. Enemies cannot Stun, Slow, Freeze, or Burn you.

Flight - Default: OFF
Fly around the map using WASD controls. Toggle on/off as needed.

✨ UTILITY BUTTONS:

📋 Commands - Opens the commands help window
👑 Admin Panel - Manage players, kick, ban (Super Admin only)
✈️ Flight - Quick toggle for flight mode
🧹 Clear Spawned - Clear spawned objects/mobs (200 studs)

💬 CHAT COMMANDS:

<font color="#64C8FF">/spawn</font> [object] - Spawn object/mob at your location
<font color="#64C8FF">/transform</font> [Mob] - Transform into a different class
<font color="#64C8FF">/transform</font> myself - Return to original form
<font color="#64C8FF">/slabura</font> - Clear spawned objects/mobs
<font color="#64C8FF">/restartplace</font> - Respawn everyone
<font color="#64C8FF">/flight</font> - Enable flight mode
<font color="#64C8FF">/flightoff</font> - Disable flight mode
<font color="#64C8FF">/slavko</font> - Access Master Control Panel (Admin)
<font color="#64C8FF">/commands</font> - Toggle commands help window



....









.....













....















.....
















.....

SLAVKO #1

]]
helpText.Parent = contentFrame

local helpCorner = Instance.new("UICorner")
helpCorner.CornerRadius = UDim.new(0, 6)
helpCorner.Parent = helpText

local helpPadding = Instance.new("UIPadding")
helpPadding.PaddingLeft = UDim.new(0, 10)
helpPadding.PaddingRight = UDim.new(0, 10)
helpPadding.PaddingTop = UDim.new(0, 10)
helpPadding.PaddingBottom = UDim.new(0, 30)
helpPadding.Parent = helpText

-- Update canvas size after help text is added
task.defer(updateContentCanvas)

