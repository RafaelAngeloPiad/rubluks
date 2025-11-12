local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
screenGui.Parent = player:WaitForChild("PlayerGui")

local BASE_FRAME_SIZE = Vector2.new(350, 320)
local BASE_MARGIN = 10
local BASE_POSITION_OFFSET = Vector2.new(BASE_FRAME_SIZE.X + BASE_MARGIN, BASE_FRAME_SIZE.Y + BASE_MARGIN)
local hasCustomPosition = false
local cameraViewportConn = nil

local mainFrame = Instance.new("Frame")
mainFrame.Name = "ControlFrame"
mainFrame.Size = UDim2.new(0, BASE_FRAME_SIZE.X, 0, BASE_FRAME_SIZE.Y)
mainFrame.Position = UDim2.new(1, -BASE_POSITION_OFFSET.X, 1, -BASE_POSITION_OFFSET.Y)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
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
local dragOffset = Vector2.zero
local dragInput = nil

local function getInputPosition(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local position = input.Position
		return Vector2.new(position.X, position.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function beginDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	isDragging = true
	hasCustomPosition = true
	dragInput = input

	local inputPos = getInputPosition(input)
	local framePos = mainFrame.AbsolutePosition
	dragOffset = inputPos - Vector2.new(framePos.X, framePos.Y)

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			isDragging = false
			if dragInput == input then
				dragInput = nil
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

	if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local inputPos = getInputPosition(input)
	local newPos = UDim2.new(0, inputPos.X - dragOffset.X, 0, inputPos.Y - dragOffset.Y)
	mainFrame.Position = newPos
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
		end
	end
end)

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ButtonContainer"
contentFrame.Size = UDim2.new(1, -10, 1, -40)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local buttonLayout = Instance.new("UIGridLayout")
buttonLayout.CellSize = UDim2.new(0.49, 0, 0, 25)
buttonLayout.CellPadding = UDim2.new(0.01, 0, 0.02, 0)
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.Parent = contentFrame

local function determineUIScale()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local minDimension = math.min(viewport.X, viewport.Y)

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		if minDimension <= 720 then
			return 0.5
		elseif minDimension <= 900 then
			return 0.6
		end
		return 0.7
	end

	if viewport.X <= 1440 then
		return 0.85
	end

	return 0.9
end

local function applyUIScaling()
	local newScale = determineUIScale()
	if math.abs(newScale - currentScale) > 1e-3 then
		currentScale = newScale
		uiScale.Scale = newScale
	end

	if not hasCustomPosition then
		local scaledOffset = BASE_POSITION_OFFSET * currentScale
		mainFrame.Position = UDim2.new(1, -math.round(scaledOffset.X), 1, -math.round(scaledOffset.Y))
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

local function createButton(text, color, layoutOrder, onClick)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
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
local isVisible = true

createButton("👁️ Hide", Color3.fromRGB(60, 60, 60), layoutOrder, function()
	isVisible = not isVisible
	mainFrame.Visible = isVisible
end)
layoutOrder += 1

createButton("Reset", Color3.fromRGB(150, 50, 50), layoutOrder, function()
	if DevStatEvent then
		DevStatEvent:FireServer("fullReset")
	end
end)
layoutOrder += 1

local xpButtons = {
	{label = "+5 XP", color = Color3.fromRGB(50, 150, 50), amount = 5},
	{label = "+10 XP", color = Color3.fromRGB(50, 180, 50), amount = 10},
	{label = "+500 XP", color = Color3.fromRGB(100, 200, 100), amount = 500},
	{label = "+5000 XP", color = Color3.fromRGB(120, 220, 120), amount = 5000},
	{label = "+100000 XP", color = Color3.fromRGB(90, 200, 90), amount = 100000},
}

for _, entry in ipairs(xpButtons) do
	createButton(entry.label, entry.color, layoutOrder, function()
		if DevStatEvent then
			DevStatEvent:FireServer("addCurrentXP", entry.amount)
		end
	end)
	layoutOrder += 1
end

local classButtons = {
	{label = "Knight", class = "Knight", color = Color3.fromRGB(100, 150, 200)},
	{label = "Samurai", class = "Samurai", color = Color3.fromRGB(150, 150, 150)},
	{label = "Gladiator", class = "Gladiator", color = Color3.fromRGB(200, 100, 100)},
	{label = "Brawler", class = "Brawler", color = Color3.fromRGB(150, 100, 50)},
	{label = "Archer", class = "Archer", color = Color3.fromRGB(100, 200, 100)},
}

for _, entry in ipairs(classButtons) do
	createButton(entry.label, entry.color, layoutOrder, function()
		if DevStatEvent then
			DevStatEvent:FireServer("setClass", entry.class)
		end
	end)
	layoutOrder += 1
end

local playerFriendlyLocalState = playerFriendlyFireValue and playerFriendlyFireValue.Value or false
local mobFriendlyLocalState = mobFriendlyFireValue and mobFriendlyFireValue.Value or false
local mobCombatModeLocalState = mobCombatModeValue and mobCombatModeValue.Value or "excluded"
local godModeLocalState = godModeValue and godModeValue.Value or false
local statusImmuneLocalState = statusImmunityValue and statusImmunityValue.Value or false

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
end)
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
end)
layoutOrder += 1

local MobCombatModeOrder = {"excluded", "versus", "frenzy"}
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
end)
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
end)
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
end)
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.PageUp then
		isVisible = not isVisible
		mainFrame.Visible = isVisible
	end
end)

