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
local ConsumableEvent = ReplicatedStorage:WaitForChild("ConsumableEvent")

-- ========================================
-- GLOBAL KEYBINDS CONFIGURATION
-- These work without any weapon equipped
-- ========================================

local GLOBAL_KEYBINDS = {
	wave = Enum.KeyCode.L, -- L key for wave emote (works globally)
	platformerSpecial = Enum.KeyCode.LeftShift, -- Shift key for platformer dash/roll
	point = Enum.KeyCode.P, -- P key for point emote
}

-- ========================================
-- GLOBAL ACTIONS
-- ========================================

local function wave()
	-- Fire wave event to server (works without weapon)
	remote:FireServer("global_wave")
end

local function point()
	remote:FireServer("global_point")
end

local function triggerPlatformerSpecial()
	if typeof(_G.performPlatformerSpecial) == "function" then
		_G.performPlatformerSpecial()
	end
end

local consumableSlots = {}

local function tryUseConsumable(slotIndex)
	if consumableSlots[slotIndex] then
		ConsumableEvent:FireServer("use", slotIndex)
	end
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
		
		if input.KeyCode == GLOBAL_KEYBINDS.point then
			point()
			return
		end

		if input.KeyCode == GLOBAL_KEYBINDS.platformerSpecial then
			triggerPlatformerSpecial()
			return
		end

		if input.KeyCode == Enum.KeyCode.One then
			tryUseConsumable(1)
			return
		elseif input.KeyCode == Enum.KeyCode.Two then
			tryUseConsumable(2)
			return
		elseif input.KeyCode == Enum.KeyCode.Three then
			tryUseConsumable(3)
			return
		elseif input.KeyCode == Enum.KeyCode.Four then
			tryUseConsumable(4)
			return
		elseif input.KeyCode == Enum.KeyCode.Five then
			tryUseConsumable(5)
			return
		end
	end
end

-- ========================================
-- INITIALIZE
-- ========================================

-- Listen for all inputs (global, always active)
UserInputService.InputBegan:Connect(onInputBegan)

ConsumableEvent.OnClientEvent:Connect(function(action, payload)
	if action == "updateSlots" then
		for index = 1, 5 do
			if payload then
				consumableSlots[index] = payload[index]
			else
				consumableSlots[index] = nil
			end
		end
	end
end)

