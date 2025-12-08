--[[
	WaterPool.server.luau
	---------------------
	Server script to be placed inside a Part that acts as a pool/river.
	While a player is touching this part, their thirst will be continuously
	restored by adding 10 water every interval until full.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get or create the SunfireWaterEvent
local SunfireWaterEvent = ReplicatedStorage:FindFirstChild("SunfireWaterEvent")
if not SunfireWaterEvent then
	SunfireWaterEvent = Instance.new("RemoteEvent")
	SunfireWaterEvent.Name = "SunfireWaterEvent"
	SunfireWaterEvent.Parent = ReplicatedStorage
end

-- Configuration
local WATER_RESTORE_AMOUNT = 10  -- Amount of water to add per interval
local RESTORE_INTERVAL = 0.5      -- How often to restore water (in seconds)

-- Get the part this script is in
local part = script.Parent
if not part:IsA("BasePart") then
	warn("[WaterPool] Script must be placed inside a BasePart!")
	return
end

-- Track which players are currently touching the part
local playersTouching: {[Player]: boolean} = {}

-- Function to restore water for a player
local function restoreWater(player: Player)
	if not player or not player.Parent then
		return false
	end

	local sunfire = player:FindFirstChild("sunfireprogress")
	if not sunfire then
		return false
	end

	local currentValueObj = sunfire:FindFirstChild("CurrentWaterLevel")
	local maxValueObj = sunfire:FindFirstChild("MaxWaterLevel")
	if not currentValueObj or not maxValueObj then
		return false
	end

	local currentValue = tonumber(currentValueObj.Value) or 0
	local maxValue = tonumber(maxValueObj.Value) or 0

	-- Check if already at max
	if currentValue >= maxValue then
		return false
	end

	-- Add water and clamp to max
	local newValue = math.min(currentValue + WATER_RESTORE_AMOUNT, maxValue)
	currentValueObj.Value = newValue

	-- Notify client to update UI
	SunfireWaterEvent:FireClient(player, "restore", newValue, maxValue)
	return true
end

-- Function to start water restoration loop for a player
local function startWaterRestore(player: Player)
	if playersTouching[player] then
		return -- Already restoring
	end

	-- Mark player as touching
	playersTouching[player] = true

	task.spawn(function()
		while playersTouching[player] do
			if not restoreWater(player) then
				-- Water is full, stop restoring
				break
			end
			task.wait(RESTORE_INTERVAL)
		end
		
		-- Clean up when done
		playersTouching[player] = nil
	end)
end

-- Function to stop water restoration for a player
local function stopWaterRestore(player: Player)
	playersTouching[player] = nil
end

-- Handle player touching the part
local function onTouched(hit: BasePart)
	local character = hit.Parent
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Start restoring water for this player
	startWaterRestore(player)
end

-- Handle player leaving the part
local function onTouchEnded(hit: BasePart)
	local character = hit.Parent
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Stop restoring water for this player
	stopWaterRestore(player)
end

-- Connect touch events
part.Touched:Connect(onTouched)
part.TouchEnded:Connect(onTouchEnded)

-- Clean up when players leave
game:GetService("Players").PlayerRemoving:Connect(function(player)
	stopWaterRestore(player)
end)

