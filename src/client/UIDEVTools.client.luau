--[[
    UIDevTools
    Clean, expandable developer tools GUI for EXP management.
    Appears in the bottom right corner. Click to expand/collapse.
    Buttons: Get 1 EXP, Get 5 EXP, Get 10 EXP, Reset EXP.
    Easily extendable for future dev tools.
    Now uses RemoteEvent to request XP changes via EXPManager/MainDataStore.
--]]

-- MAKE SURE TO CHREATE A REMOTE EVENT IN REPLICATEDSTORAGE CALLED "RequestXPChange"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- RemoteEvent for requesting XP changes
local RequestXPChange = ReplicatedStorage:WaitForChild("RequestXPChange")

-- Create ScreenGui in PlayerGui (not StarterGui!)
local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UIDevTools"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	return screenGui
end

local screenGui = createGui()

-- Main frame (bottom right, static)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(1, 1)
mainFrame.Position = UDim2.new(1, -20, 1, -20)
mainFrame.Size = UDim2.new(0, 160, 0, 35)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Add corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Expand/collapse button (covers entire main frame)
local expandButton = Instance.new("TextButton")
expandButton.Name = "ExpandButton"
expandButton.Size = UDim2.new(1, 0, 1, 0)
expandButton.BackgroundTransparency = 1
expandButton.Text = "DEV TOOLS ▾"
expandButton.TextColor3 = Color3.fromRGB(200, 255, 200)
expandButton.Font = Enum.Font.SourceSansBold
expandButton.TextSize = 16
expandButton.Parent = mainFrame

-- Expanded panel (bottom right, static)
local panelFrame = Instance.new("Frame")
panelFrame.Name = "PanelFrame"
panelFrame.AnchorPoint = Vector2.new(1, 1)
panelFrame.Position = UDim2.new(1, 0, 1, -45)
panelFrame.Size = UDim2.new(0, 160, 0, 140)
panelFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
panelFrame.BorderSizePixel = 0
panelFrame.Visible = false
panelFrame.Active = true
panelFrame.Parent = mainFrame

-- Add corner rounding to panel
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panelFrame

-- Layout for buttons
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Parent = panelFrame

-- Button factory
local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(70, 110, 70)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Parent = panelFrame
	
	-- Add corner rounding to buttons
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn
	
	return btn
end

-- EXP Buttons
local btn1 = createButton("Get 1 EXP")
local btn5 = createButton("Get 5 EXP")
local btn10 = createButton("Get 10 EXP")
local btnReset = createButton("Reset EXP")

-- Hide button (different style)
local btnHide = Instance.new("TextButton")
btnHide.Size = UDim2.new(1, -16, 0, 24)
btnHide.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
btnHide.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHide.Font = Enum.Font.SourceSansBold
btnHide.TextSize = 12
btnHide.Text = "HIDE ▴"
btnHide.BorderSizePixel = 0
btnHide.AutoButtonColor = true
btnHide.Parent = panelFrame

-- Add corner rounding to hide button
local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = btnHide

-- Button callbacks (use RemoteEvent)
btn1.MouseButton1Click:Connect(function()
	RequestXPChange:FireServer(1)
end)

btn5.MouseButton1Click:Connect(function()
	RequestXPChange:FireServer(5)
end)

btn10.MouseButton1Click:Connect(function()
	RequestXPChange:FireServer(10)
end)

btnReset.MouseButton1Click:Connect(function()
	RequestXPChange:FireServer("reset")
end)

-- Hide button callback
btnHide.MouseButton1Click:Connect(function()
	expanded = false
	panelFrame.Visible = false
	expandButton.Text = "DEV TOOLS ▾"
	mainFrame.Size = UDim2.new(0, 160, 0, 35)
end)

-- Expand/collapse logic
local expanded = false
expandButton.MouseButton1Click:Connect(function()
	expanded = not expanded
	panelFrame.Visible = expanded
	expandButton.Text = "DEV TOOLS ▾" -- Always show the same text since we have a separate hide button
	mainFrame.Size = expanded and UDim2.new(0, 160, 0, 185) or UDim2.new(0, 160, 0, 35)
end)

--[[
    To add more dev tools, simply add more buttons to panelFrame and connect their logic.
    Example:
        local btnClass = createButton("Class Manager")
        btnClass.MouseButton1Click:Connect(function()
            -- Open class manager UI
        end)
--]]

