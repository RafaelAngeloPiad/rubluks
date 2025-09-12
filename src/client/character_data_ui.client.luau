-- Character Data Display UI
-- Top-right toggleable UI for viewing detailed character data

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterData = require(ReplicatedStorage.Shared.character_data)

-- Font settings
local FONT_SIZE = 15
local FONT = Enum.Font.SourceSans

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote events
local remoteEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
local getCharacterDataEvent = remoteEvents:WaitForChild("GetCharacterData")

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterDataUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main container (initially hidden)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Position = UDim2.new(1, -370, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Toggle button (always visible)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(1, -70, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "DATA"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = false
toggleButton.TextSize = FONT_SIZE
toggleButton.Font = FONT
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 10)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Character Data Viewer"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = false
titleLabel.TextSize = FONT_SIZE
titleLabel.Font = FONT
titleLabel.Parent = mainFrame

-- Character slots frame
local slotsFrame = Instance.new("Frame")
slotsFrame.Name = "SlotsFrame"
slotsFrame.Size = UDim2.new(1, -20, 0, 80)
slotsFrame.Position = UDim2.new(0, 10, 0, 50)
slotsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
slotsFrame.BorderSizePixel = 0
slotsFrame.Parent = mainFrame

local slotsCorner = Instance.new("UICorner")
slotsCorner.CornerRadius = UDim.new(0, 6)
slotsCorner.Parent = slotsFrame

-- Slots label
local slotsLabel = Instance.new("TextLabel")
slotsLabel.Name = "SlotsLabel"
slotsLabel.Size = UDim2.new(1, 0, 0, 10)
slotsLabel.Position = UDim2.new(0, 0, 0, 0)
slotsLabel.BackgroundTransparency = 1
slotsLabel.Text = "Select Character:"
slotsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
slotsLabel.TextScaled = false
slotsLabel.TextSize = FONT_SIZE
slotsLabel.Font = FONT
slotsLabel.TextXAlignment = Enum.TextXAlignment.Left
slotsLabel.Parent = slotsFrame

-- Slot buttons container
local slotButtonsFrame = Instance.new("Frame")
slotButtonsFrame.Name = "SlotButtonsFrame"
slotButtonsFrame.Size = UDim2.new(1, -10, 1, -20)
slotButtonsFrame.Position = UDim2.new(0, 5, 0, 15)
slotButtonsFrame.BackgroundTransparency = 1
slotButtonsFrame.Parent = slotsFrame

-- Character data display frame
local dataFrame = Instance.new("Frame")
dataFrame.Name = "DataFrame"
dataFrame.Size = UDim2.new(1, -20, 1, -140)
dataFrame.Position = UDim2.new(0, 10, 0, 140)
dataFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dataFrame.BorderSizePixel = 0
dataFrame.Parent = mainFrame

local dataCorner = Instance.new("UICorner")
dataCorner.CornerRadius = UDim.new(0, 6)
dataCorner.Parent = dataFrame

-- Character data label
local dataLabel = Instance.new("TextLabel")
dataLabel.Name = "DataLabel"
dataLabel.Size = UDim2.new(1, 0, 0, 10)
dataLabel.Position = UDim2.new(0, 0, 0, 0)
dataLabel.BackgroundTransparency = 1
dataLabel.Text = "Character Data:"
dataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dataLabel.TextScaled = false
dataLabel.TextSize = FONT_SIZE
dataLabel.Font = FONT
dataLabel.TextXAlignment = Enum.TextXAlignment.Left
dataLabel.Parent = dataFrame

-- Character data text
local dataText = Instance.new("TextLabel")
dataText.Name = "DataText"
dataText.Size = UDim2.new(1, -10, 1, -20)
dataText.Position = UDim2.new(0, 5, 0, 15)
dataText.BackgroundTransparency = 1
dataText.Text = "No character selected"
dataText.TextColor3 = Color3.fromRGB(200, 200, 200)
dataText.TextScaled = true
dataText.Font = FONT
dataText.TextXAlignment = Enum.TextXAlignment.Left
dataText.TextYAlignment = Enum.TextYAlignment.Top
dataText.TextWrapped = true
dataText.Parent = dataFrame

-- State variables
local isUIOpen = false
local currentSlot = 1
local characterSlots = {}

-- Update character display
local function updateCharacterDisplay()
	local slot = characterSlots[currentSlot]
	
	if CharacterData.isSlotEmpty(slot) then
		dataText.Text = "Empty Slot " .. currentSlot .. "\n\nThis slot has no character created yet."
	else
		local displayText = string.format([[
Slot: %d
Class: %s
Level: %d
Experience: %d

Stats:
HP: %d
Mana: %d
Attack: %d
Defense: %d
Magic Resist: %d
Speed: %d

Status Ailments:
]], 
			slot.slotIndex,
			slot.className,
			slot.level,
			slot.experience,
			slot.stats.hp,
			slot.stats.mana,
			slot.stats.attack,
			slot.stats.defense,
			slot.stats.magicResist,
			slot.stats.speed
		)
		
		for ailment, active in pairs(slot.stats.statusAilments) do
			displayText = displayText .. string.format("%s: %s\n", ailment, active and "Active" or "Inactive")
		end
		
		dataText.Text = displayText
	end
end

-- Animation functions
local function animateUI(open)
	local targetSize = open and UDim2.new(0, 350, 0, 400) or UDim2.new(0, 0, 0, 0)
	local targetPosition = open and UDim2.new(1, -370, 0, 20) or UDim2.new(1, -20, 0, 20)
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainFrame, tweenInfo, {
		Size = targetSize,
		Position = targetPosition
	})
	
	tween:Play()
end

-- Create slot buttons
local function createSlotButtons()
	-- Clear existing buttons
	for _, child in pairs(slotButtonsFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	
	for i = 1, 3 do
		local slot = characterSlots[i]
		local isEmpty = CharacterData.isSlotEmpty(slot)
		
		local button = Instance.new("TextButton")
		button.Name = "Slot" .. i .. "Button"
		button.Size = UDim2.new(1/3, -2, 1, -5)
		button.Position = UDim2.new((i-1) * (1/3), 0, 0, 0)
		button.BackgroundColor3 = currentSlot == i and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(60, 60, 60)
		button.BorderSizePixel = 0
		button.Text = isEmpty and "Empty" or slot.className
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = false
		button.TextSize = FONT_SIZE
		button.Font = FONT
		button.Parent = slotButtonsFrame
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 4)
		buttonCorner.Parent = button
		
		button.MouseButton1Click:Connect(function()
			currentSlot = i
			createSlotButtons()
			updateCharacterDisplay()
		end)
	end
end

-- Toggle UI
local function toggleUI()
	isUIOpen = not isUIOpen
	mainFrame.Visible = isUIOpen
	
	if isUIOpen then
		animateUI(true)
		-- Load current character slots
		getCharacterDataEvent:FireServer()
	end
end

-- Event connections
toggleButton.MouseButton1Click:Connect(toggleUI)

-- Handle character slots from server
getCharacterDataEvent.OnClientEvent:Connect(function(slots)
	if slots then
		characterSlots = slots
		
		-- Update UI
		createSlotButtons()
		updateCharacterDisplay()
	end
end)

-- Initialize UI
createSlotButtons()

print("Character Data Viewer loaded! Press the DATA button in the top-right to view character details.")
