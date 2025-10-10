-- ========================================
-- ZANTETSUKEN ULTIMATE BUTTON (C)
-- Place this script inside your Zantetsuken ultimate button
-- ========================================

local button = script.Parent

-- Require the action module from PlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local SamuraiActions = require(player.PlayerScripts.samurai.SamuraiActionModule)

-- Button click handler
button.MouseButton1Click:Connect(function()
	SamuraiActions.zantetsuken()
end)

-- Update button transparency when weapon is not equipped
task.spawn(function()
	while button and button.Parent do
		if SamuraiActions.isWeaponEquipped() then
			button.TextTransparency = 0
			button.BackgroundTransparency = 0
		else
			button.TextTransparency = 1
			button.BackgroundTransparency = 1
		end
		task.wait(0.5)
	end
end)

