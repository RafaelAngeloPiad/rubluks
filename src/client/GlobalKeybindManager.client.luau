-- ========================================
-- GLOBAL KEYBIND MANAGER
-- Handles keybinds that work regardless of weapon state
-- These are always active (wave, etc.)
-- ========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- ========================================
-- GLOBAL KEYBINDS CONFIGURATION
-- These work without any weapon equipped
-- ========================================

local GLOBAL_KEYBINDS = {
	wave = Enum.KeyCode.L, -- L key for wave emote (works globally)
}

-- ========================================
-- GLOBAL ACTIONS
-- ========================================

local function wave()
	-- Fire wave event to server (works without weapon)
	remote:FireServer("global_wave")
end

-- ========================================
-- INPUT HANDLING
-- ========================================

local function onInputBegan(input, isProcessed)
	if isProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		-- Handle wave (L key)
		if input.KeyCode == GLOBAL_KEYBINDS.wave then
			wave()
			return
		end
	end
end

-- ========================================
-- INITIALIZE
-- ========================================

-- Listen for all inputs (global, always active)
UserInputService.InputBegan:Connect(onInputBegan)

