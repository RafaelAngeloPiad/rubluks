-- adminPanel.client.luau
-- Admin panel UI for managing player permissions and banning players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Wait for RemoteEvents
local AdminPanelToggle = ReplicatedStorage:WaitForChild("AdminPanelToggle", 10)
local AdminPanelRequest = ReplicatedStorage:WaitForChild("AdminPanelRequest", 10)

if not AdminPanelToggle or not AdminPanelRequest then
	warn("[AdminPanel] Required RemoteEvents not found")
	return
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanelDisplay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 101
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local BASE_FRAME_SIZE = Vector2.new(450, 500)
local BASE_MARGIN = 10
local BASE_POSITION = UDim2.new(0.5, 0, 0.5, 0)
local BASE_ANCHOR_POINT = Vector2.new(0.5, 0.5)
local hasCustomPosition = false
local cameraViewportConn = nil

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "AdminFrame"
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

-- Title bar (draggable)
local title = Instance.new("TextButton")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "👑 ADMIN PANEL (Drag to Move)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.AutoButtonColor = false
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Dragging functionality
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

-- ScrollingFrame for player list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "PlayerListScroll"
scrollFrame.Size = UDim2.new(1, -20, 1, -90)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 5)
scrollCorner.Parent = scrollFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Exit button
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(1, -20, 0, 30)
exitButton.Position = UDim2.new(0, 10, 1, -40)
exitButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
exitButton.BorderSizePixel = 0
exitButton.Text = "❌ CLOSE"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextSize = 14
exitButton.Font = Enum.Font.GothamBold
exitButton.ZIndex = 15
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

-- Ban Dialog (Responsive)
local banDialog = Instance.new("Frame")
banDialog.Name = "BanDialog"
banDialog.Size = UDim2.new(0.9, 0, 0.8, 0)
banDialog.AnchorPoint = Vector2.new(0.5, 0.5)
banDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
banDialog.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
banDialog.BorderSizePixel = 0
banDialog.Visible = false
banDialog.ZIndex = 10
banDialog.Parent = screenGui

local banDialogConstraint = Instance.new("UISizeConstraint")
banDialogConstraint.MaxSize = Vector2.new(400, 500)
banDialogConstraint.MinSize = Vector2.new(300, 400)
banDialogConstraint.Parent = banDialog

local banDialogCorner = Instance.new("UICorner")
banDialogCorner.CornerRadius = UDim.new(0, 10)
banDialogCorner.Parent = banDialog

-- Ban Dialog Title
local banDialogTitle = Instance.new("TextLabel")
banDialogTitle.Name = "Title"
banDialogTitle.Size = UDim2.new(1, -20, 0, 40)
banDialogTitle.Position = UDim2.new(0, 10, 0, 10)
banDialogTitle.BackgroundTransparency = 1
banDialogTitle.Text = "🔨 BAN PLAYER"
banDialogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
banDialogTitle.TextSize = 18
banDialogTitle.Font = Enum.Font.GothamBold
banDialogTitle.TextXAlignment = Enum.TextXAlignment.Left
banDialogTitle.Parent = banDialog

-- Ban Type Label
local banTypeLabel = Instance.new("TextLabel")
banTypeLabel.Size = UDim2.new(1, -20, 0, 20)
banTypeLabel.Position = UDim2.new(0, 10, 0, 60)
banTypeLabel.BackgroundTransparency = 1
banTypeLabel.Text = "Ban Type:"
banTypeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
banTypeLabel.TextSize = 14
banTypeLabel.Font = Enum.Font.Gotham
banTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
banTypeLabel.Parent = banDialog

-- Ban Type Buttons Container
local banTypeContainer = Instance.new("Frame")
banTypeContainer.Size = UDim2.new(1, -20, 0, 35)
banTypeContainer.Position = UDim2.new(0, 10, 0, 85)
banTypeContainer.BackgroundTransparency = 1
banTypeContainer.Parent = banDialog

local banTypeLayout = Instance.new("UIListLayout")
banTypeLayout.FillDirection = Enum.FillDirection.Horizontal
banTypeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
banTypeLayout.Padding = UDim.new(0, 5)
banTypeLayout.Parent = banTypeContainer

local selectedBanType = "permanent"

local function createBanTypeButton(text, banType)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.32, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.Parent = banTypeContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button
	
	button.MouseButton1Click:Connect(function()
		selectedBanType = banType
		-- Update all buttons
		for _, child in ipairs(banTypeContainer:GetChildren()) do
			if child:IsA("TextButton") then
				if child == button then
					child.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					child.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
		
		-- Show/hide duration controls
		durationContainer.Visible = (banType == "timed")
	end)
	
	return button
end

local permaBanBtn = createBanTypeButton("PERMANENT", "permanent")
permaBanBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
permaBanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local timedBanBtn = createBanTypeButton("TIMED", "timed")
local unbanBtn = createBanTypeButton("UNBAN", "unban")

-- Duration Container
local durationContainer = Instance.new("Frame")
durationContainer.Size = UDim2.new(1, -20, 0, 70)
durationContainer.Position = UDim2.new(0, 10, 0, 130)
durationContainer.BackgroundTransparency = 1
durationContainer.Visible = false
durationContainer.Parent = banDialog

local durationLabel = Instance.new("TextLabel")
durationLabel.Size = UDim2.new(1, 0, 0, 20)
durationLabel.BackgroundTransparency = 1
durationLabel.Text = "Duration:"
durationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
durationLabel.TextSize = 14
durationLabel.Font = Enum.Font.Gotham
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = durationContainer

local durationInputContainer = Instance.new("Frame")
durationInputContainer.Size = UDim2.new(1, 0, 0, 35)
durationInputContainer.Position = UDim2.new(0, 0, 0, 25)
durationInputContainer.BackgroundTransparency = 1
durationInputContainer.Parent = durationContainer

local durationInput = Instance.new("TextBox")
durationInput.Size = UDim2.new(0.4, -5, 1, 0)
durationInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
durationInput.BorderSizePixel = 0
durationInput.Text = "1"
durationInput.TextColor3 = Color3.fromRGB(255, 255, 255)
durationInput.TextSize = 14
durationInput.Font = Enum.Font.Gotham
durationInput.PlaceholderText = "Amount"
durationInput.Parent = durationInputContainer

local durationInputCorner = Instance.new("UICorner")
durationInputCorner.CornerRadius = UDim.new(0, 5)
durationInputCorner.Parent = durationInput

local durationUnitContainer = Instance.new("Frame")
durationUnitContainer.Size = UDim2.new(0.6, -5, 1, 0)
durationUnitContainer.Position = UDim2.new(0.4, 5, 0, 0)
durationUnitContainer.BackgroundTransparency = 1
durationUnitContainer.Parent = durationInputContainer

local durationUnitLayout = Instance.new("UIListLayout")
durationUnitLayout.FillDirection = Enum.FillDirection.Horizontal
durationUnitLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
durationUnitLayout.Padding = UDim.new(0, 3)
durationUnitLayout.Parent = durationUnitContainer

local selectedDurationUnit = "days"

local function createDurationUnitButton(text, unit)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.32, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.TextSize = 11
	button.Font = Enum.Font.Gotham
	button.Parent = durationUnitContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = button
	
	button.MouseButton1Click:Connect(function()
		selectedDurationUnit = unit
		for _, child in ipairs(durationUnitContainer:GetChildren()) do
			if child:IsA("TextButton") then
				if child == button then
					child.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					child.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
	end)
	
	return button
end

local hoursBtn = createDurationUnitButton("Hours", "hours")
local daysBtn = createDurationUnitButton("Days", "days")
daysBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
daysBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
local weeksBtn = createDurationUnitButton("Weeks", "weeks")

-- Alt Accounts Checkbox
local altAccountsContainer = Instance.new("Frame")
altAccountsContainer.Size = UDim2.new(1, -20, 0, 30)
altAccountsContainer.Position = UDim2.new(0, 10, 0, 210)
altAccountsContainer.BackgroundTransparency = 1
altAccountsContainer.Parent = banDialog

local altAccountsCheckbox = Instance.new("TextButton")
altAccountsCheckbox.Size = UDim2.new(0, 20, 0, 20)
altAccountsCheckbox.Position = UDim2.new(0, 0, 0, 5)
altAccountsCheckbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
altAccountsCheckbox.BorderSizePixel = 0
altAccountsCheckbox.Text = ""
altAccountsCheckbox.Parent = altAccountsContainer

local altCheckboxCorner = Instance.new("UICorner")
altCheckboxCorner.CornerRadius = UDim.new(0, 4)
altCheckboxCorner.Parent = altAccountsCheckbox

local altCheckboxCheck = Instance.new("TextLabel")
altCheckboxCheck.Size = UDim2.new(1, 0, 1, 0)
altCheckboxCheck.BackgroundTransparency = 1
altCheckboxCheck.Text = "✓"
altCheckboxCheck.TextColor3 = Color3.fromRGB(100, 200, 100)
altCheckboxCheck.TextSize = 16
altCheckboxCheck.Font = Enum.Font.GothamBold
altCheckboxCheck.Visible = true
altCheckboxCheck.Parent = altAccountsCheckbox

local altAccountsLabel = Instance.new("TextLabel")
altAccountsLabel.Size = UDim2.new(1, -30, 1, 0)
altAccountsLabel.Position = UDim2.new(0, 30, 0, 0)
altAccountsLabel.BackgroundTransparency = 1
altAccountsLabel.Text = "Apply ban to all known alt accounts"
altAccountsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
altAccountsLabel.TextSize = 12
altAccountsLabel.Font = Enum.Font.Gotham
altAccountsLabel.TextXAlignment = Enum.TextXAlignment.Left
altAccountsLabel.Parent = altAccountsContainer

local applyToAlts = true
altAccountsCheckbox.MouseButton1Click:Connect(function()
	applyToAlts = not applyToAlts
	altCheckboxCheck.Visible = applyToAlts
end)

-- Public Reason
local publicReasonLabel = Instance.new("TextLabel")
publicReasonLabel.Size = UDim2.new(1, -20, 0, 20)
publicReasonLabel.Position = UDim2.new(0, 10, 0, 250)
publicReasonLabel.BackgroundTransparency = 1
publicReasonLabel.Text = "Public Ban Reason (visible to user):"
publicReasonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
publicReasonLabel.TextSize = 12
publicReasonLabel.Font = Enum.Font.Gotham
publicReasonLabel.TextXAlignment = Enum.TextXAlignment.Left
publicReasonLabel.Parent = banDialog

local publicReasonInput = Instance.new("TextBox")
publicReasonInput.Size = UDim2.new(1, -20, 0, 40)
publicReasonInput.Position = UDim2.new(0, 10, 0, 275)
publicReasonInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
publicReasonInput.BorderSizePixel = 0
publicReasonInput.Text = ""
publicReasonInput.TextColor3 = Color3.fromRGB(255, 255, 255)
publicReasonInput.TextSize = 12
publicReasonInput.Font = Enum.Font.Gotham
publicReasonInput.PlaceholderText = "Violation of experience rules"
publicReasonInput.TextWrapped = true
publicReasonInput.MultiLine = true
publicReasonInput.ClearTextOnFocus = false
publicReasonInput.Parent = banDialog

local publicReasonCorner = Instance.new("UICorner")
publicReasonCorner.CornerRadius = UDim.new(0, 5)
publicReasonCorner.Parent = publicReasonInput

-- Private Reason
local privateReasonLabel = Instance.new("TextLabel")
privateReasonLabel.Size = UDim2.new(1, -20, 0, 20)
privateReasonLabel.Position = UDim2.new(0, 10, 0, 325)
privateReasonLabel.BackgroundTransparency = 1
privateReasonLabel.Text = "Private Ban Reason (visible only to you):"
privateReasonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
privateReasonLabel.TextSize = 12
privateReasonLabel.Font = Enum.Font.Gotham
privateReasonLabel.TextXAlignment = Enum.TextXAlignment.Left
privateReasonLabel.Parent = banDialog

local privateReasonInput = Instance.new("TextBox")
privateReasonInput.Size = UDim2.new(1, -20, 0, 40)
privateReasonInput.Position = UDim2.new(0, 10, 0, 350)
privateReasonInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
privateReasonInput.BorderSizePixel = 0
privateReasonInput.Text = ""
privateReasonInput.TextColor3 = Color3.fromRGB(255, 255, 255)
privateReasonInput.TextSize = 12
privateReasonInput.Font = Enum.Font.Gotham
privateReasonInput.PlaceholderText = "Internal notes..."
privateReasonInput.TextWrapped = true
privateReasonInput.MultiLine = true
privateReasonInput.ClearTextOnFocus = false
privateReasonInput.Parent = banDialog

local privateReasonCorner = Instance.new("UICorner")
privateReasonCorner.CornerRadius = UDim.new(0, 5)
privateReasonCorner.Parent = privateReasonInput

-- Dialog Buttons
local dialogButtonsContainer = Instance.new("Frame")
dialogButtonsContainer.Size = UDim2.new(1, -20, 0, 35)
dialogButtonsContainer.Position = UDim2.new(0, 10, 1, -45)
dialogButtonsContainer.BackgroundTransparency = 1
dialogButtonsContainer.Parent = banDialog

local confirmButton = Instance.new("TextButton")
confirmButton.Size = UDim2.new(0.48, 0, 1, 0)
confirmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
confirmButton.BorderSizePixel = 0
confirmButton.Text = "CONFIRM"
confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmButton.TextSize = 14
confirmButton.Font = Enum.Font.GothamBold
confirmButton.Parent = dialogButtonsContainer

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 5)
confirmCorner.Parent = confirmButton

local cancelButton = Instance.new("TextButton")
cancelButton.Size = UDim2.new(0.48, 0, 1, 0)
cancelButton.Position = UDim2.new(0.52, 0, 0, 0)
cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
cancelButton.BorderSizePixel = 0
cancelButton.Text = "CANCEL"
cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelButton.TextSize = 14
cancelButton.Font = Enum.Font.GothamBold
cancelButton.Parent = dialogButtonsContainer

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 5)
cancelCorner.Parent = cancelButton

-- Function to show ban dialog
local function showBanDialog(playerData)
	-- Reset dialog
	selectedBanType = "permanent"
	selectedDurationUnit = "days"
	applyToAlts = true
	durationInput.Text = "1"
	publicReasonInput.Text = ""
	privateReasonInput.Text = ""
	durationContainer.Visible = false
	altCheckboxCheck.Visible = true
	
	-- Update button states
	permaBanBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	permaBanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	timedBanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	timedBanBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	unbanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	unbanBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	daysBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	daysBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	hoursBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	hoursBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	weeksBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	weeksBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	banDialogTitle.Text = "🔨 BAN PLAYER: " .. playerData.Name
	banDialog.Visible = true
end

confirmButton.MouseButton1Click:Connect(function()
	local targetUserId = nil
	local targetName = nil
	
	-- Get player data from dialog title
	local titleText = banDialogTitle.Text
	local nameMatch = titleText:match("🔨 BAN PLAYER: (.+)")
	if nameMatch then
		targetName = nameMatch
		-- Find player by name
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name == targetName then
				targetUserId = p.UserId
				break
			end
		end
	end
	
	if not targetUserId then
		warn("Could not find target player")
		banDialog.Visible = false
		return
	end
	
	-- Calculate duration in seconds
	local durationSeconds = -1 -- Default to permanent
	
	if selectedBanType == "timed" then
		local amount = tonumber(durationInput.Text) or 1
		if selectedDurationUnit == "hours" then
			durationSeconds = amount * 3600
		elseif selectedDurationUnit == "days" then
			durationSeconds = amount * 86400
		elseif selectedDurationUnit == "weeks" then
			durationSeconds = amount * 604800
		end
	elseif selectedBanType == "unban" then
		-- Send unban request
		AdminPanelRequest:FireServer("UnbanPlayer", targetUserId)
		banDialog.Visible = false
		return
	end
	
	-- Send ban request
	local banConfig = {
		UserId = targetUserId,
		Duration = durationSeconds,
		DisplayReason = publicReasonInput.Text ~= "" and publicReasonInput.Text or "Violation of experience rules",
		PrivateReason = privateReasonInput.Text,
		ExcludeAltAccounts = not applyToAlts
	}
	
	AdminPanelRequest:FireServer("BanPlayer", banConfig)
	banDialog.Visible = false
end)

cancelButton.MouseButton1Click:Connect(function()
	banDialog.Visible = false
end)

confirmButton.MouseEnter:Connect(function()
	confirmButton.BackgroundColor3 = Color3.fromRGB(90, 150, 200)
end)

confirmButton.MouseLeave:Connect(function()
	confirmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
end)

cancelButton.MouseEnter:Connect(function()
	cancelButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
end)

cancelButton.MouseLeave:Connect(function()
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

-- Tab buttons
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -10, 0, 30)
tabContainer.Position = UDim2.new(0, 5, 0, 40)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

local activeTab = Instance.new("TextButton")
activeTab.Name = "ActiveTab"
activeTab.Size = UDim2.new(0.48, 0, 1, 0)
activeTab.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
activeTab.BorderSizePixel = 0
activeTab.Text = "👥 ACTIVE PLAYERS"
activeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
activeTab.Font = Enum.Font.GothamBold
activeTab.TextSize = 12
activeTab.Parent = tabContainer

local activeTabCorner = Instance.new("UICorner")
activeTabCorner.CornerRadius = UDim.new(0, 5)
activeTabCorner.Parent = activeTab

local bannedTab = Instance.new("TextButton")
bannedTab.Name = "BannedTab"
bannedTab.Size = UDim2.new(0.48, 0, 1, 0)
bannedTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
bannedTab.BorderSizePixel = 0
bannedTab.Text = "🔨 BANNED PLAYERS"
bannedTab.TextColor3 = Color3.fromRGB(255, 255, 255)
bannedTab.Font = Enum.Font.GothamBold
bannedTab.TextSize = 12
bannedTab.Parent = tabContainer

local bannedTabCorner = Instance.new("UICorner")
bannedTabCorner.CornerRadius = UDim.new(0, 5)
bannedTabCorner.Parent = bannedTab

-- Player list container (scrolling frame)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "PlayerListFrame"
scrollFrame.Size = UDim2.new(1, -10, 1, -85)
scrollFrame.Position = UDim2.new(0, 5, 0, 75)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- Banned players container (hidden by default)
local bannedScrollFrame = Instance.new("ScrollingFrame")
bannedScrollFrame.Name = "BannedListFrame"
bannedScrollFrame.Size = UDim2.new(1, -10, 1, -85)
bannedScrollFrame.Position = UDim2.new(0, 5, 0, 75)
bannedScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bannedScrollFrame.BackgroundTransparency = 0.5
bannedScrollFrame.BorderSizePixel = 0
bannedScrollFrame.ScrollBarThickness = 6
bannedScrollFrame.Visible = false
bannedScrollFrame.Parent = mainFrame

local bannedScrollCorner = Instance.new("UICorner")
bannedScrollCorner.CornerRadius = UDim.new(0, 6)
bannedScrollCorner.Parent = bannedScrollFrame

local bannedListLayout = Instance.new("UIListLayout")
bannedListLayout.Padding = UDim.new(0, 5)
bannedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
bannedListLayout.Parent = bannedScrollFrame

-- Tab switching logic
local currentTab = "active"

activeTab.MouseButton1Click:Connect(function()
	currentTab = "active"
	activeTab.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	bannedTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	scrollFrame.Visible = true
	bannedScrollFrame.Visible = false
end)

bannedTab.MouseButton1Click:Connect(function()
	currentTab = "banned"
	activeTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	bannedTab.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	scrollFrame.Visible = false
	bannedScrollFrame.Visible = true
	-- Request banned players list
	AdminPanelRequest:FireServer("GetBannedPlayers")
end)

-- Function to create player row
local function createPlayerRow(playerData)
	local row = Instance.new("Frame")
	row.Name = "PlayerRow_" .. playerData.UserId
	row.Size = UDim2.new(1, -10, 0, 60)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.BorderSizePixel = 0
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 5)
	rowCorner.Parent = row
	
	-- Player name label (on top)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = playerData.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	
	-- Buttons container (below name)
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, -10, 0, 28)
	buttonsContainer.Position = UDim2.new(0, 5, 0, 27)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = row
	
	-- Admin toggle button
	local adminButton = Instance.new("TextButton")
	adminButton.Name = "AdminButton"
	adminButton.Size = UDim2.new(0.32, -3, 1, 0)
	adminButton.Position = UDim2.new(0, 0, 0, 0)
	adminButton.BorderSizePixel = 0
	adminButton.TextSize = 11
	adminButton.Font = Enum.Font.GothamBold
	adminButton.Parent = buttonsContainer
	
	local adminCorner = Instance.new("UICorner")
	adminCorner.CornerRadius = UDim.new(0, 4)
	adminCorner.Parent = adminButton
	
	-- Update admin button appearance
	local function updateAdminButton()
		if playerData.IsSuperAdmin then
			adminButton.Text = "SUPER"
			adminButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
			adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		elseif playerData.IsAdmin then
			adminButton.Text = "ADMIN"
			adminButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			adminButton.Text = "ADMIN"
			adminButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			adminButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
	
	updateAdminButton()
	
	-- Admin button click handler
	adminButton.MouseButton1Click:Connect(function()
		if playerData.IsSuperAdmin then
			return -- Can't toggle super admins
		end
		
		-- Request toggle
		AdminPanelRequest:FireServer("ToggleAdmin", playerData.UserId)
	end)
	
	adminButton.MouseEnter:Connect(function()
		if not playerData.IsSuperAdmin then
			adminButton.BackgroundColor3 = adminButton.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
		end
	end)
	
	adminButton.MouseLeave:Connect(function()
		updateAdminButton()
	end)
	
	-- Kick button
	local kickButton = Instance.new("TextButton")
	kickButton.Name = "KickButton"
	kickButton.Size = UDim2.new(0.32, -3, 1, 0)
	kickButton.Position = UDim2.new(0.34, 0, 0, 0)
	kickButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	kickButton.BorderSizePixel = 0
	kickButton.Text = "KICK"
	kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	kickButton.TextSize = 11
	kickButton.Font = Enum.Font.GothamBold
	kickButton.Parent = buttonsContainer
	
	local kickCorner = Instance.new("UICorner")
	kickCorner.CornerRadius = UDim.new(0, 4)
	kickCorner.Parent = kickButton
	
	-- Kick button click handler
	kickButton.MouseButton1Click:Connect(function()
		if playerData.IsSuperAdmin then
			return -- Can't kick super admins
		end
		
		-- Request kick
		AdminPanelRequest:FireServer("KickPlayer", playerData.UserId)
	end)
	
	kickButton.MouseEnter:Connect(function()
		if not playerData.IsSuperAdmin then
			kickButton.BackgroundColor3 = Color3.fromRGB(230, 120, 70)
		end
	end)
	
	kickButton.MouseLeave:Connect(function()
		kickButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	end)
	
	-- Ban button
	local banButton = Instance.new("TextButton")
	banButton.Name = "BanButton"
	banButton.Size = UDim2.new(0.32, -3, 1, 0)
	banButton.Position = UDim2.new(0.68, 0, 0, 0)
	banButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	banButton.BorderSizePixel = 0
	banButton.Text = "BAN"
	banButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	banButton.TextSize = 11
	banButton.Font = Enum.Font.GothamBold
	banButton.Parent = buttonsContainer
	
	local banCorner = Instance.new("UICorner")
	banCorner.CornerRadius = UDim.new(0, 4)
	banCorner.Parent = banButton
	
	-- Ban button click handler
	banButton.MouseButton1Click:Connect(function()
		if playerData.IsSuperAdmin then
			return -- Can't ban super admins
		end
		
		-- Open ban dialog
		showBanDialog(playerData)
	end)
	
	banButton.MouseEnter:Connect(function()
		if not playerData.IsSuperAdmin then
			banButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
		end
	end)
	
	banButton.MouseLeave:Connect(function()
		banButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	end)
	
	return row
end

-- Function to create banned player row
local function createBannedRow(bannedData)
	local row = Instance.new("Frame")
	row.Name = "BannedRow_" .. bannedData.UserId
	row.Size = UDim2.new(1, -10, 0, 80)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.BorderSizePixel = 0
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 5)
	rowCorner.Parent = row
	
	-- Username
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 18)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = bannedData.Username or "Unknown"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	
	-- Ban info
	local banDate = os.date("%Y-%m-%d %H:%M", bannedData.BanData.BannedAt)
	local duration = bannedData.BanData.Duration
	local durationText = duration == -1 and "Permanent" or (math.floor(duration / 86400) .. " days")
	
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -10, 0, 14)
	infoLabel.Position = UDim2.new(0, 5, 0, 23)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Banned: " .. banDate .. " | Duration: " .. durationText
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextSize = 11
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = row
	
	-- Reason
	local reasonLabel = Instance.new("TextLabel")
	reasonLabel.Size = UDim2.new(1, -10, 0, 14)
	reasonLabel.Position = UDim2.new(0, 5, 0, 37)
	reasonLabel.BackgroundTransparency = 1
	reasonLabel.Text = "Reason: " .. (bannedData.BanData.DisplayReason or "No reason")
	reasonLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	reasonLabel.TextSize = 10
	reasonLabel.Font = Enum.Font.Gotham
	reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
	reasonLabel.Parent = row
	
	-- Unban button
	local unbanButton = Instance.new("TextButton")
	unbanButton.Size = UDim2.new(0.3, 0, 0, 22)
	unbanButton.Position = UDim2.new(0, 5, 1, -27)
	unbanButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	unbanButton.BorderSizePixel = 0
	unbanButton.Text = "UNBAN"
	unbanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	unbanButton.TextSize = 11
	unbanButton.Font = Enum.Font.GothamBold
	unbanButton.Parent = row
	
	local unbanCorner = Instance.new("UICorner")
	unbanCorner.CornerRadius = UDim.new(0, 4)
	unbanCorner.Parent = unbanButton
	
	unbanButton.MouseButton1Click:Connect(function()
		-- Send unban request
		AdminPanelRequest:FireServer("UnbanPlayer", bannedData.UserId)
		-- Remove row
		row:Destroy()
	end)
	
	unbanButton.MouseEnter:Connect(function()
		unbanButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	end)
	
	unbanButton.MouseLeave:Connect(function()
		unbanButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	end)
	
	return row
end

-- Function to update player list
local function updatePlayerList(playerList)
	-- Clear existing rows
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^PlayerRow_") then
			child:Destroy()
		end
	end
	
	-- Create new rows
	for _, playerData in ipairs(playerList) do
		local row = createPlayerRow(playerData)
		row.Parent = scrollFrame
	end
	
	-- Update canvas size
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- UI scaling
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

-- Listen for panel toggle
AdminPanelToggle.OnClientEvent:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	screenGui.Enabled = mainFrame.Visible
	
	if mainFrame.Visible then
		-- Request player list
		AdminPanelRequest:FireServer("GetPlayerList")
	end
end)

-- Listen for player list updates
AdminPanelRequest.OnClientEvent:Connect(function(action, data)
	if action == "PlayerList" then
		updatePlayerList(data)
	elseif action == "BannedPlayersList" then
		-- Clear existing banned rows
		for _, child in ipairs(bannedScrollFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^BannedRow_") then
				child:Destroy()
			end
		end
		
		-- Create new banned rows
		for _, bannedData in ipairs(data) do
			local row = createBannedRow(bannedData)
			row.Parent = bannedScrollFrame
		end
		
		-- Update canvas size
		bannedScrollFrame.CanvasSize = UDim2.new(0, 0, 0, bannedListLayout.AbsoluteContentSize.Y + 10)
	end
end)
