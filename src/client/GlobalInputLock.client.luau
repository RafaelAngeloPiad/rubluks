local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ActionEvent = ReplicatedStorage:WaitForChild("ActionEvent")

-- Initialise PlayerModule and Controls once, globally.
local function getControls()
	local playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
	return playerModule:GetControls()
end

local controls = getControls()
local lockCount = 0

local function applyLockState()
	if not controls then
		return
	end

	if lockCount > 0 then
		controls:Disable()
	else
		controls:Enable()
	end
end

-- Global input lock for systems like InventoryManager.
-- Uses its own message names so it doesn't interfere with
-- per-class action scripts that also listen for "lock_input".
ActionEvent.OnClientEvent:Connect(function(message)
	if message == "global_lock_input" then
		lockCount += 1
		applyLockState()
	elseif message == "global_unlock_input" then
		if lockCount > 0 then
			lockCount -= 1
			applyLockState()
		end
	end
end)


