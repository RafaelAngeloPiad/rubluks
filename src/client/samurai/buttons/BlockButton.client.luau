-- ========================================
-- BLOCK BUTTON (V key)
-- Place this script inside your Block button
-- Note: This handles both press and release
-- ========================================

local button = script.Parent
local UserInputService = game:GetService("UserInputService")

-- Require the action module from PlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local SamuraiActions = require(player.PlayerScripts.samurai.SamuraiActionModule)

local isBlocking = false

-- Button press handler
button.MouseButton1Down:Connect(function()
	if not isBlocking then
		SamuraiActions.blockStart()
		isBlocking = true
		-- Visual feedback: change button color while blocking
		button.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	end
end)

-- Button release handler
button.MouseButton1Up:Connect(function()
	if isBlocking then
		SamuraiActions.blockEnd()
		isBlocking = false
		-- Reset button color
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

-- Handle case where mouse leaves button while holding
button.MouseLeave:Connect(function()
	if isBlocking then
		SamuraiActions.blockEnd()
		isBlocking = false
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

-- Update button transparency when weapon is not equipped
task.spawn(function()
	while button and button.Parent do
		if SamuraiActions.isWeaponEquipped() then
			button.TextTransparency = 0
			if not isBlocking then
				button.BackgroundTransparency = 0
			end
		else
			button.TextTransparency = 1
			button.BackgroundTransparency = 1
		end
		task.wait(0.5)
	end
end)

