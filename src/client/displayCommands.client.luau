-- displayCommands.client.luau
-- Displays available chat commands in a UI similar to displayStats

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Wait for CommandHelpEvent
local CommandHelpEvent = ReplicatedStorage:WaitForChild("CommandHelpEvent", 10)
if not CommandHelpEvent then
	warn("[CommandsDisplay] CommandHelpEvent not found")
	return
end

local BASE_FRAME_SIZE = Vector2.new(400, 450)
local BASE_MARGIN = 10
local BASE_POSITION = UDim2.new(1, -BASE_MARGIN, 0.5, 0)
local BASE_ANCHOR_POINT = Vector2.new(1, 0.5)
local hasCustomPosition = false
local cameraViewportConn = nil

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CommandsDisplay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, BASE_FRAME_SIZE.X, 0, BASE_FRAME_SIZE.Y)
mainFrame.AnchorPoint = BASE_ANCHOR_POINT
mainFrame.Position = BASE_POSITION
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.3
mainFrame.Visible = false
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = mainFrame
local currentScale = 1

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title (draggable handle)
local title = Instance.new("TextButton")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "📋 COMMANDS (Drag to Move)"
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

-- Scrolling frame for commands
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "CommandsScroll"
scrollFrame.Size = UDim2.new(1, -10, 1, -85)
scrollFrame.Position = UDim2.new(0, 5, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = mainFrame

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingBottom = UDim.new(0, 28)
scrollPadding.PaddingTop = UDim.new(0, 8)
scrollPadding.PaddingLeft = UDim.new(0, 8)
scrollPadding.PaddingRight = UDim.new(0, 8)
scrollPadding.Parent = scrollFrame

-- UI List Layout
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local CANVAS_EXTRA_PADDING = 80

local function updateCanvasSize()
	local contentHeight = listLayout.AbsoluteContentSize.Y
	local scale = uiScale and uiScale.Scale or currentScale or 1
	if scale and scale < 1 then
		contentHeight = math.ceil(contentHeight / math.max(scale, 1e-3))
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + CANVAS_EXTRA_PADDING)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

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

-- UI Scaling
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

	scrollFrame.ScrollBarThickness = math.max(3, math.floor(5 * currentScale))
	updateCanvasSize()
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

-- Function to create a command entry
local function createCommandEntry(command, description, example, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = "Command_" .. command
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.LayoutOrder = layoutOrder or 0
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = scrollFrame

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 6)
	frameCorner.Parent = frame

	local framePadding = Instance.new("UIPadding")
	framePadding.PaddingLeft = UDim.new(0, 10)
	framePadding.PaddingRight = UDim.new(0, 10)
	framePadding.PaddingTop = UDim.new(0, 8)
	framePadding.PaddingBottom = UDim.new(0, 8)
	framePadding.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = frame

	-- Command name
	local commandLabel = Instance.new("TextLabel")
	commandLabel.Name = "CommandName"
	commandLabel.Size = UDim2.new(1, 0, 0, 0)
	commandLabel.BackgroundTransparency = 1
	commandLabel.Text = command
	commandLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	commandLabel.TextSize = 14
	commandLabel.Font = Enum.Font.GothamBold
	commandLabel.TextXAlignment = Enum.TextXAlignment.Left
	commandLabel.TextYAlignment = Enum.TextYAlignment.Top
	commandLabel.TextWrapped = true
	commandLabel.AutomaticSize = Enum.AutomaticSize.Y
	commandLabel.LayoutOrder = 1
	commandLabel.Parent = frame

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, 0, 0, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 12
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.AutomaticSize = Enum.AutomaticSize.Y
	descLabel.LayoutOrder = 2
	descLabel.Parent = frame

	-- Example (if provided)
	if example and example ~= "" then
		local exampleLabel = Instance.new("TextLabel")
		exampleLabel.Name = "Example"
		exampleLabel.Size = UDim2.new(1, 0, 0, 0)
		exampleLabel.BackgroundTransparency = 1
		exampleLabel.Text = "Example: " .. example
		exampleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		exampleLabel.TextSize = 11
		exampleLabel.Font = Enum.Font.Gotham
		exampleLabel.TextXAlignment = Enum.TextXAlignment.Left
		exampleLabel.TextYAlignment = Enum.TextYAlignment.Top
		exampleLabel.TextWrapped = true
		exampleLabel.AutomaticSize = Enum.AutomaticSize.Y
		exampleLabel.LayoutOrder = 3
		exampleLabel.Parent = frame
	end

	return frame
end

-- Create command list
local function populateCommands()
	-- Clear existing
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local layoutOrder = 1

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	header.BorderSizePixel = 0
	header.Text = "AVAILABLE COMMANDS"
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextSize = 13
	header.Font = Enum.Font.GothamBold
	header.LayoutOrder = layoutOrder
	header.Parent = scrollFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 6)
	headerCorner.Parent = header

	layoutOrder = layoutOrder + 1

	-- Commands list
	local commands = {
		{
			command = "/spawn [object]",
			description = "Spawn an object or mob at your location",
			example = "/spawn tree"
		},
		{
			command = "/transform [Mob]",
			description = "Transform into a different class temporarily.",
			example = "/transform Arabandit"
		},
		{
			command = "/transform myself",
			description = "Return to your original form.",
			example = "/transform myself"
		},
		{
			command = "/slabura",
			description = "Clear Spawned Objects/Mobs",
			example = "/slabura"
		},
		{
			command = "/restartplace",
			description = "Respawn Everyone",
			example = "/restartplace"
		},
		{
			command = "/flight",
			description = "Enable flight mode to fly around the map",
			example = "/flight"
		},
		{
			command = "/flightoff",
			description = "Disable flight mode and return to normal movement",
			example = "/flightoff"
		},
		{
			command = "/slavko (Admin)",
			description = "Access Master Control Panel. Admins must type this every time they join a place. Click 'Show Controls' to reveal toggles: PVP (player vs player, default OFF), Mob Mode (Excluded=normal/Versus=faction wars/Frenzy=chaos/Peaceful=no combat), Mob FF (friendly fire), God Mode (invincibility), Status Immunity (bypass stun/slow/freeze/burn).",
			example = "/slavko"
		},
		{
			command = "/commands",
			description = "Toggle this commands help window.",
			example = "/commands"
		}
	}

	for _, cmd in ipairs(commands) do
		createCommandEntry(cmd.command, cmd.description, cmd.example, layoutOrder)
		layoutOrder = layoutOrder + 1
	end	

	updateCanvasSize()
end

-- Populate commands on load
populateCommands()

-- Listen for events from server
CommandHelpEvent.OnClientEvent:Connect(function(action, data)
	if action == "toggle" then
		mainFrame.Visible = not mainFrame.Visible
		screenGui.Enabled = mainFrame.Visible

	elseif action == "hint" then
		-- Show top-center notification
		print("[CommandsDisplay] Received hint event, showing notification")
		local message = data or "Type /commands to see all available commands!"
		
		-- Create notification banner
		local notifGui = Instance.new("ScreenGui")
		notifGui.Name = "CommandHintNotification"
		notifGui.ResetOnSpawn = false
		notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		notifGui.Parent = player:WaitForChild("PlayerGui")
		
		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(0, 400, 0, 50)
		notifFrame.Position = UDim2.new(0.5, 0, 0, -60)
		notifFrame.AnchorPoint = Vector2.new(0.5, 0)
		notifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		notifFrame.BackgroundTransparency = 0.2
		notifFrame.BorderSizePixel = 0
		notifFrame.Parent = notifGui
		
		local notifCorner = Instance.new("UICorner")
		notifCorner.CornerRadius = UDim.new(0, 8)
		notifCorner.Parent = notifFrame
		
		local notifLabel = Instance.new("TextLabel")
		notifLabel.Size = UDim2.new(1, -20, 1, 0)
		notifLabel.Position = UDim2.new(0, 10, 0, 0)
		notifLabel.BackgroundTransparency = 1
		notifLabel.Text = "💡 " .. message
		notifLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		notifLabel.TextSize = 16
		notifLabel.Font = Enum.Font.GothamBold
		notifLabel.TextWrapped = true
		notifLabel.Parent = notifFrame
		
		-- Animate in
		notifFrame:TweenPosition(
			UDim2.new(0.5, 0, 0, 10),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Back,
			0.5,
			true
		)
		
		-- Wait and animate out
		task.wait(4)
		notifFrame:TweenPosition(
			UDim2.new(0.5, 0, 0, -60),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.3,
			true,
			function()
				notifGui:Destroy()
			end
		)
	end
end)

print("[CommandsDisplay] Commands display initialized")
