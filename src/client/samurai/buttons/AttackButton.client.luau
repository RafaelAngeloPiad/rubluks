-- ========================================
-- ATTACK BUTTON (Auto-Detects Attack Type)
-- Place this script inside your Attack button
-- This handles: Regular Attack, Move Attack, AND Jump Attack
-- The server automatically detects which attack to perform based on player state
-- ========================================

local button = script.Parent

-- Require the action module from PlayerScripts
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local SamuraiActions = require(player.PlayerScripts.samurai.SamuraiActionModule)

-- Button click handler
-- Just like left-clicking, the server will auto-detect:
-- - Regular attack (standing still)
-- - Move attack (while moving)
-- - Jump attack (while in air)
button.MouseButton1Click:Connect(function()
	SamuraiActions.basicAttack()
end)

-- Optional: Update button transparency when weapon is not equipped
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

