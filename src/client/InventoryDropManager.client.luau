local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local dropItemRemote = remoteEvents:WaitForChild("DropItemRemote")

-- Configuration
local DROP_CONFIG = {
    LONG_PRESS_TIME = 1.0, -- seconds for mobile long press
    HOTKEY = Enum.KeyCode.G, -- Desktop hotkey for dropping
    SHOW_DROP_CONFIRMATION = true, -- Show confirmation for drops
}

-- State tracking
local selectedTool = nil
local longPressStart = 0
local isLongPressing = false
local dropUI = nil

-- Utility functions
local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function isDesktop()
    return UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
end

-- Create drop confirmation UI
local function createDropUI()
    if dropUI then
        dropUI:Destroy()
    end
    
    -- Main frame
    dropUI = Instance.new("ScreenGui")
    dropUI.Name = "DropItemUI"
    dropUI.ResetOnSpawn = false
    dropUI.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Name = "DropFrame"
    frame.Size = UDim2.new(0, 250, 0, 120)
    frame.Position = UDim2.new(0.5, -125, 0.5, -60)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = dropUI
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Drop Item"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Item name label
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Name = "ItemLabel"
    itemLabel.Size = UDim2.new(1, -20, 0, 25)
    itemLabel.Position = UDim2.new(0, 10, 0, 35)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = selectedTool and selectedTool.Name or "No item selected"
    itemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemLabel.TextScaled = true
    itemLabel.Font = Enum.Font.SourceSans
    itemLabel.Parent = frame
    
    -- Button container
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -20, 0, 30)
    buttonFrame.Position = UDim2.new(0, 10, 1, -40)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = frame
    
    -- Drop button
    local dropButton = Instance.new("TextButton")
    dropButton.Name = "DropButton"
    dropButton.Size = UDim2.new(0.45, 0, 1, 0)
    dropButton.Position = UDim2.new(0, 0, 0, 0)
    dropButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    dropButton.BorderSizePixel = 0
    dropButton.Text = "Drop"
    dropButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropButton.TextScaled = true
    dropButton.Font = Enum.Font.SourceSansBold
    dropButton.Parent = buttonFrame
    
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 4)
    dropCorner.Parent = dropButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0.45, 0, 1, 0)
    cancelButton.Position = UDim2.new(0.55, 0, 0, 0)
    cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    cancelButton.BorderSizePixel = 0
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextScaled = true
    cancelButton.Font = Enum.Font.SourceSans
    cancelButton.Parent = buttonFrame
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 4)
    cancelCorner.Parent = cancelButton
    
    -- Button events
    dropButton.Activated:Connect(function()
        if selectedTool then
            dropItemRemote:FireServer(selectedTool.Name)
            print("[InventoryDropManager] Requested drop for:", selectedTool.Name)
        end
        hideDropUI()
    end)
    
    cancelButton.Activated:Connect(function()
        hideDropUI()
    end)
    
    -- Add fade in animation
    frame.BackgroundTransparency = 1
    title.TextTransparency = 1
    itemLabel.TextTransparency = 1
    dropButton.BackgroundTransparency = 1
    dropButton.TextTransparency = 1
    cancelButton.BackgroundTransparency = 1
    cancelButton.TextTransparency = 1
    
    -- Tween in
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(title, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(itemLabel, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(dropButton, tweenInfo, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
    TweenService:Create(cancelButton, tweenInfo, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
end

function hideDropUI()
    if dropUI then
        dropUI:Destroy()
        dropUI = nil
    end
    selectedTool = nil
end

-- Show drop UI for selected tool
local function showDropUI(tool)
    selectedTool = tool
    createDropUI()
end

-- Handle desktop input (keyboard/mouse)
local function handleDesktopInput()
    print("[InventoryDropManager] Setting up desktop input handlers")
    
    -- Hotkey drop (G key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == DROP_CONFIG.HOTKEY then
            print("[InventoryDropManager] G key pressed, looking for tool to drop")
            
            -- Try to drop currently equipped tool first
            local character = player.Character
            if character then
                local equippedTool = character:FindFirstChildOfClass("Tool")
                if equippedTool then
                    print("[InventoryDropManager] Found equipped tool:", equippedTool.Name)
                    if DROP_CONFIG.SHOW_DROP_CONFIRMATION then
                        showDropUI(equippedTool)
                    else
                        dropItemRemote:FireServer(equippedTool.Name)
                    end
                    return
                end
            end
            
            -- If no equipped tool, drop first backpack tool
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                local firstTool = backpack:FindFirstChildOfClass("Tool")
                if firstTool then
                    print("[InventoryDropManager] Found backpack tool:", firstTool.Name)
                    if DROP_CONFIG.SHOW_DROP_CONFIRMATION then
                        showDropUI(firstTool)
                    else
                        dropItemRemote:FireServer(firstTool.Name)
                    end
                else
                    print("[InventoryDropManager] No tools found in backpack")
                end
            else
                print("[InventoryDropManager] No backpack found")
            end
        end
    end)
    
    print("[InventoryDropManager] Desktop input handlers set up successfully")
end

-- Create universal drop button (works for both mobile and desktop)
local function createDropButton()
    print("[InventoryDropManager] Creating drop button")
    
    local dropButtonGui = Instance.new("ScreenGui")
    dropButtonGui.Name = "DropButtonGui"
    dropButtonGui.ResetOnSpawn = false
    dropButtonGui.Parent = playerGui
    
    local button = Instance.new("TextButton")
    button.Name = "DropButton"
    button.Size = UDim2.new(0, 80, 0, 40)
    button.Position = UDim2.new(1, -90, 0, 10)
    button.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Text = "Drop Item (G)"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Parent = dropButtonGui
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = button
    
    button.Activated:Connect(function()
        print("[InventoryDropManager] Drop button clicked")
        
        -- Drop currently equipped tool or first backpack tool
        local character = player.Character
        local toolToDrop = nil
        
        if character then
            toolToDrop = character:FindFirstChildOfClass("Tool")
            if toolToDrop then
                print("[InventoryDropManager] Found equipped tool for button drop:", toolToDrop.Name)
            end
        end
        
        if not toolToDrop then
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                toolToDrop = backpack:FindFirstChildOfClass("Tool")
                if toolToDrop then
                    print("[InventoryDropManager] Found backpack tool for button drop:", toolToDrop.Name)
                end
            end
        end
        
        if toolToDrop then
            showDropUI(toolToDrop)
        else
            print("[InventoryDropManager] No tools found to drop")
        end
    end)
    
    print("[InventoryDropManager] Drop button created successfully")
end

-- Initialize based on platform
local function initialize()
    print("[InventoryDropManager] Client initialized for", isMobile() and "mobile" or "desktop", "platform")
    
    -- Always create the drop button (works for both platforms)
    createDropButton()
    
    -- Set up desktop keyboard input
    if not isMobile() then
        handleDesktopInput()
    end
    
    print("[InventoryDropManager] Initialization complete")
end

-- Start the system
player.CharacterAdded:Connect(function()
    wait(1) -- Wait for backpack to load
    initialize()
end)

if player.Character then
    initialize()
end

print("[InventoryDropManager] Client script loaded with configuration:", DROP_CONFIG)
