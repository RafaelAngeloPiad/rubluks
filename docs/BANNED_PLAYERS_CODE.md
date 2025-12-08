# Admin Panel - Banned Players Tab Code

## IMPORTANT: Add these sections to adminPanel.client.luau

### 1. After line 665 (after ban dialog code), add scrollFrame and listLayout:

```lua
-- Player list container (scrolling frame)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "PlayerListFrame"
scrollFrame.Size = UDim2.new(1, -10, 1, -85)
scrollFrame.Position = UDim2.new(0, 5, 0, 45)
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
bannedScrollFrame.Position = UDim2.new(0, 5, 0, 45)
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

-- Tab buttons (after title, before scrollframes)
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
```

### 2. After createPlayerRow function (after line 828), add createBannedRow:

```lua
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
```

### 3. In the AdminPanelRequest.OnClientEvent handler (around line 925), add:

```lua
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
```

## Summary
This adds:
1. Tab buttons to switch between Active/Banned players
2. Separate ScrollingFrame for banned players
3. createBannedRow function to display banned player info
4. Event handler for BannedPlayersList
5. Unban button functionality
