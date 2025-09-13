-- -- Dev UI for character slot selection and class management
-- -- Bottom-right toggleable UI with 3 character slots and class selection

-- local Players = game:GetService("Players")
-- local TweenService = game:GetService("TweenService")
-- local UserInputService = game:GetService("UserInputService")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- local CharacterData = require(ReplicatedStorage.Shared.character_data)

-- -- Font settings
-- local FONT_SIZE = 15
-- local FONT = Enum.Font.SourceSans

-- local player = Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui")

-- -- Remote events
-- local remoteEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
-- local loadCharacterEvent = remoteEvents:WaitForChild("LoadCharacter")
-- local saveCharacterEvent = remoteEvents:WaitForChild("SaveCharacter")
-- local getCharacterDataEvent = remoteEvents:WaitForChild("GetCharacterData")

-- -- UI Creation
-- local screenGui = Instance.new("ScreenGui")
-- screenGui.Name = "DevUI"
-- screenGui.ResetOnSpawn = false
-- screenGui.Parent = playerGui

-- -- Main container (initially hidden)
-- local mainFrame = Instance.new("Frame")
-- mainFrame.Name = "MainFrame"
-- mainFrame.Size = UDim2.new(0, 350, 0, 250)
-- mainFrame.Position = UDim2.new(1, -370, 1, -270)
-- mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
-- mainFrame.BorderSizePixel = 0
-- mainFrame.Visible = false
-- mainFrame.Parent = screenGui

-- -- Corner radius
-- local corner = Instance.new("UICorner")
-- corner.CornerRadius = UDim.new(0, 8)
-- corner.Parent = mainFrame

-- -- Toggle button (always visible)
-- local toggleButton = Instance.new("TextButton")
-- toggleButton.Name = "ToggleButton"
-- toggleButton.Size = UDim2.new(0, 60, 0, 60)
-- toggleButton.Position = UDim2.new(1, -70, 1, -70)
-- toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
-- toggleButton.BorderSizePixel = 0
-- toggleButton.Text = "DEV"
-- toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
-- toggleButton.TextScaled = false
-- toggleButton.TextSize = FONT_SIZE
-- toggleButton.Font = FONT
-- toggleButton.Parent = screenGui

-- local toggleCorner = Instance.new("UICorner")
-- toggleCorner.CornerRadius = UDim.new(0, 8)
-- toggleCorner.Parent = toggleButton

-- -- Title
-- local titleLabel = Instance.new("TextLabel")
-- titleLabel.Name = "TitleLabel"
-- titleLabel.Size = UDim2.new(1, 0, 0, 10)
-- titleLabel.Position = UDim2.new(0, 0, 0, 0)
-- titleLabel.BackgroundTransparency = 1
-- titleLabel.Text = "Character Manager"
-- titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- titleLabel.TextScaled = false
-- titleLabel.TextSize = FONT_SIZE
-- titleLabel.Font = FONT
-- titleLabel.Parent = mainFrame

-- -- Character slots frame
-- local slotsFrame = Instance.new("Frame")
-- slotsFrame.Name = "SlotsFrame"
-- slotsFrame.Size = UDim2.new(1, -20, 0, 80)
-- slotsFrame.Position = UDim2.new(0, 10, 0, 30)
-- slotsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
-- slotsFrame.BorderSizePixel = 0
-- slotsFrame.Parent = mainFrame

-- local slotsCorner = Instance.new("UICorner")
-- slotsCorner.CornerRadius = UDim.new(0, 6)
-- slotsCorner.Parent = slotsFrame

-- -- Slots label
-- local slotsLabel = Instance.new("TextLabel")
-- slotsLabel.Name = "SlotsLabel"
-- slotsLabel.Size = UDim2.new(1, 0, 0, 10)
-- slotsLabel.Position = UDim2.new(0, 0, 0, 0)
-- slotsLabel.BackgroundTransparency = 1
-- slotsLabel.Text = "Character Slots:"
-- slotsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- slotsLabel.TextScaled = false
-- slotsLabel.TextSize = FONT_SIZE
-- slotsLabel.Font = FONT
-- slotsLabel.TextXAlignment = Enum.TextXAlignment.Left
-- slotsLabel.Parent = slotsFrame

-- -- Slot buttons container
-- local slotButtonsFrame = Instance.new("Frame")
-- slotButtonsFrame.Name = "SlotButtonsFrame"
-- slotButtonsFrame.Size = UDim2.new(1, -10, 1, -20)
-- slotButtonsFrame.Position = UDim2.new(0, 5, 0, 15)
-- slotButtonsFrame.BackgroundTransparency = 1
-- slotButtonsFrame.Parent = slotsFrame

-- -- Class selection frame
-- local classFrame = Instance.new("Frame")
-- classFrame.Name = "ClassFrame"
-- classFrame.Size = UDim2.new(1, -20, 0, 80)
-- classFrame.Position = UDim2.new(0, 10, 0, 120)
-- classFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
-- classFrame.BorderSizePixel = 0
-- classFrame.Parent = mainFrame

-- local classCorner = Instance.new("UICorner")
-- classCorner.CornerRadius = UDim.new(0, 6)
-- classCorner.Parent = classFrame

-- -- Class selection label
-- local classLabel = Instance.new("TextLabel")
-- classLabel.Name = "ClassLabel"
-- classLabel.Size = UDim2.new(1, 0, 0, 10)
-- classLabel.Position = UDim2.new(0, 0, 0, 0)
-- classLabel.BackgroundTransparency = 1
-- classLabel.Text = "Select Class:"
-- classLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- classLabel.TextScaled = false
-- classLabel.TextSize = FONT_SIZE
-- classLabel.Font = FONT
-- classLabel.TextXAlignment = Enum.TextXAlignment.Left
-- classLabel.Parent = classFrame

-- -- Class buttons container
-- local classButtonsFrame = Instance.new("Frame")
-- classButtonsFrame.Name = "ClassButtonsFrame"
-- classButtonsFrame.Size = UDim2.new(1, -10, 1, -20)
-- classButtonsFrame.Position = UDim2.new(0, 5, 0, 15)
-- classButtonsFrame.BackgroundTransparency = 1
-- classButtonsFrame.Parent = classFrame

-- -- Action buttons frame
-- local actionButtonsFrame = Instance.new("Frame")
-- actionButtonsFrame.Name = "ActionButtonsFrame"
-- actionButtonsFrame.Size = UDim2.new(1, -20, 0, 40)
-- actionButtonsFrame.Position = UDim2.new(0, 10, 1, -50)
-- actionButtonsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
-- actionButtonsFrame.BorderSizePixel = 0
-- actionButtonsFrame.Parent = mainFrame

-- local actionCorner = Instance.new("UICorner")
-- actionCorner.CornerRadius = UDim.new(0, 6)
-- actionCorner.Parent = actionButtonsFrame

-- -- Create character button
-- local createButton = Instance.new("TextButton")
-- createButton.Name = "CreateButton"
-- createButton.Size = UDim2.new(0.5, -5, 1, -10)
-- createButton.Position = UDim2.new(0, 5, 0, 5)
-- createButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
-- createButton.BorderSizePixel = 0
-- createButton.Text = "Create Character"
-- createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
-- createButton.TextScaled = false
-- createButton.TextSize = FONT_SIZE
-- createButton.Font = FONT
-- createButton.Parent = actionButtonsFrame

-- local createCorner = Instance.new("UICorner")
-- createCorner.CornerRadius = UDim.new(0, 4)
-- createCorner.Parent = createButton

-- -- Delete character button
-- local deleteButton = Instance.new("TextButton")
-- deleteButton.Name = "DeleteButton"
-- deleteButton.Size = UDim2.new(0.5, -5, 1, -10)
-- deleteButton.Position = UDim2.new(0.5, 0, 0, 5)
-- deleteButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
-- deleteButton.BorderSizePixel = 0
-- deleteButton.Text = "Delete Character"
-- deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
-- deleteButton.TextScaled = false
-- deleteButton.TextSize = FONT_SIZE
-- deleteButton.Font = FONT
-- deleteButton.Parent = actionButtonsFrame

-- local deleteCorner = Instance.new("UICorner")
-- deleteCorner.CornerRadius = UDim.new(0, 4)
-- deleteCorner.Parent = deleteButton

-- -- State variables
-- local isUIOpen = false
-- local currentSlot = 1
-- local selectedClass = "Berserker"
-- local characterSlots = {}

-- -- Animation functions
-- local function animateUI(open)
-- 	local targetSize = open and UDim2.new(0, 350, 0, 250) or UDim2.new(0, 0, 0, 0)
-- 	local targetPosition = open and UDim2.new(1, -370, 1, -270) or UDim2.new(1, -20, 1, -70)
	
-- 	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- 	local tween = TweenService:Create(mainFrame, tweenInfo, {
-- 		Size = targetSize,
-- 		Position = targetPosition
-- 	})
	
-- 	tween:Play()
-- end

-- -- Create slot buttons
-- local function createSlotButtons()
-- 	-- Clear existing buttons
-- 	for _, child in pairs(slotButtonsFrame:GetChildren()) do
-- 		if child:IsA("GuiObject") then
-- 			child:Destroy()
-- 		end
-- 	end
	
-- 	for i = 1, 3 do
-- 		local slot = characterSlots[i]
-- 		local isEmpty = CharacterData.isSlotEmpty(slot)
		
-- 		local button = Instance.new("TextButton")
-- 		button.Name = "Slot" .. i .. "Button"
-- 		button.Size = UDim2.new(1/3, -2, 1, -5)
-- 		button.Position = UDim2.new((i-1) * (1/3), 0, 0, 0)
-- 		button.BackgroundColor3 = currentSlot == i and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(60, 60, 60)
-- 		button.BorderSizePixel = 0
-- 		button.Text = isEmpty and "Empty Slot " .. i or (slot.className .. " (Slot " .. i .. ")")
-- 		button.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 		button.TextScaled = false
-- 		button.TextSize = FONT_SIZE
-- 		button.Font = FONT
-- 		button.Parent = slotButtonsFrame
		
-- 		local buttonCorner = Instance.new("UICorner")
-- 		buttonCorner.CornerRadius = UDim.new(0, 4)
-- 		buttonCorner.Parent = button
		
-- 		button.MouseButton1Click:Connect(function()
-- 			currentSlot = i
-- 			createSlotButtons()
-- 		end)
-- 	end
-- end

-- -- Create class buttons
-- local function createClassButtons()
-- 	-- Clear existing buttons
-- 	for _, child in pairs(classButtonsFrame:GetChildren()) do
-- 		if child:IsA("GuiObject") then
-- 			child:Destroy()
-- 		end
-- 	end
	
-- 	local classes = CharacterData.getClasses()
-- 	local buttonWidth = 1 / #classes
	
-- 	for i, className in ipairs(classes) do
-- 		local button = Instance.new("TextButton")
-- 		button.Name = className .. "Button"
-- 		button.Size = UDim2.new(buttonWidth, -2, 1, -5)
-- 		button.Position = UDim2.new((i-1) * buttonWidth, 0, 0, 0)
-- 		button.BackgroundColor3 = selectedClass == className and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(60, 60, 60)
-- 		button.BorderSizePixel = 0
-- 		button.Text = className
-- 		button.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 		button.TextScaled = false
-- 		button.TextSize = FONT_SIZE
-- 		button.Font = FONT
-- 		button.Parent = classButtonsFrame
		
-- 		local buttonCorner = Instance.new("UICorner")
-- 		buttonCorner.CornerRadius = UDim.new(0, 4)
-- 		buttonCorner.Parent = button
		
-- 		button.MouseButton1Click:Connect(function()
-- 			selectedClass = className
-- 			createClassButtons()
-- 		end)
-- 	end
-- end

-- -- Update slot display
-- local function updateSlotDisplay()
-- 	createSlotButtons()
-- end

-- -- Create character in current slot
-- local function createCharacter()
-- 	local slot = characterSlots[currentSlot]
	
-- 	if not CharacterData.isSlotEmpty(slot) then
-- 		warn("Slot " .. currentSlot .. " is already occupied!")
-- 		return
-- 	end
	
-- 	-- Create character (this would normally call server)
-- 	local newCharacter = CharacterData.createCharacter(currentSlot, selectedClass)
-- 	characterSlots[currentSlot] = newCharacter
	
-- 	-- Update UI
-- 	createSlotButtons()
	
-- 	-- Save to server
-- 	saveCharacterEvent:FireServer(characterSlots)
	
-- 	print("Created", selectedClass, "in slot", currentSlot)
-- end

-- -- Delete character from current slot
-- local function deleteCharacter()
-- 	local slot = characterSlots[currentSlot]
	
-- 	if CharacterData.isSlotEmpty(slot) then
-- 		warn("Slot " .. currentSlot .. " is already empty!")
-- 		return
-- 	end
	
-- 	-- Delete character
-- 	characterSlots[currentSlot] = CharacterData.createEmptySlot(currentSlot)
	
-- 	-- Update UI
-- 	createSlotButtons()
	
-- 	-- Save to server
-- 	saveCharacterEvent:FireServer(characterSlots)
	
-- 	print("Deleted character from slot", currentSlot)
-- end

-- -- Toggle UI
-- local function toggleUI()
-- 	isUIOpen = not isUIOpen
-- 	mainFrame.Visible = isUIOpen
	
-- 	if isUIOpen then
-- 		animateUI(true)
-- 		-- Load current character slots
-- 		getCharacterDataEvent:FireServer()
-- 	end
-- end

-- -- Event connections
-- toggleButton.MouseButton1Click:Connect(toggleUI)
-- createButton.MouseButton1Click:Connect(createCharacter)
-- deleteButton.MouseButton1Click:Connect(deleteCharacter)

-- -- Handle character slots from server
-- getCharacterDataEvent.OnClientEvent:Connect(function(slots)
-- 	if slots then
-- 		characterSlots = slots
		
-- 		-- Update UI
-- 		createSlotButtons()
-- 		createClassButtons()
-- 	end
-- end)

-- -- Initialize UI
-- createSlotButtons()
-- createClassButtons()

-- print("Character Slot Manager loaded! Press the DEV button in the bottom-right to open the character management interface.")