-- flight_control.client.luau
-- Client-side flight control system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Wait for FlightEvent
local FlightEvent = ReplicatedStorage:WaitForChild("FlightEvent", 10)
if not FlightEvent then
	warn("[Flight] FlightEvent not found")
	return
end

-- Flight settings
local Speed = 50
local isFlying = false
local FlyForce = nil
local renderConnection = nil
local GetMoveVector = nil

-- Function to setup flight
local function setupFlight()
	if not player.Character then
		return false
	end
	
	local HRP = player.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then
		return false
	end
	
	-- Get ControlModule for movement input
	local playerScripts = player:WaitForChild("PlayerScripts", 5)
	if not playerScripts then
		return false
	end
	
	local playerModule = playerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return false
	end
	
	local controlModule = playerModule:FindFirstChild("ControlModule")
	if not controlModule then
		return false
	end
	
	GetMoveVector = require(controlModule)
	
	-- Create BodyVelocity
	FlyForce = Instance.new("BodyVelocity")
	FlyForce.MaxForce = Vector3.new(100000, 100000, 100000)
	FlyForce.Velocity = Vector3.new(0, 0, 0)
	FlyForce.Parent = HRP
	
	return true
end

-- Function to enable flight
local function enableFlight()
	if isFlying then
		return
	end
	
	if not setupFlight() then
		warn("[Flight] Failed to setup flight")
		return
	end
	
	isFlying = true
	
	-- Detect if on mobile
	local UserInputService = game:GetService("UserInputService")
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	
	-- Start flight loop
	renderConnection = RunService.RenderStepped:Connect(function()
		if not isFlying or not FlyForce or not FlyForce.Parent then
			return
		end
		
		local character = player.Character
		if not character then
			return
		end
		
		-- Reset velocity
		FlyForce.Velocity = Vector3.new()
		
		-- Get movement direction
		local MoveDir = Vector3.new()
		
		if isMobile then
			-- Mobile: Use Humanoid.MoveDirection (from thumbstick)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.MoveDirection.Magnitude > 0 then
				-- Convert world-space MoveDirection to camera-relative
				local worldMoveDir = humanoid.MoveDirection
				local cameraCFrame = Camera.CFrame
				
				-- Get camera's right and look vectors (ignore Y component for horizontal movement)
				local cameraRight = cameraCFrame.RightVector
				local cameraLook = cameraCFrame.LookVector
				
				-- Project movement onto camera axes
				local rightAmount = worldMoveDir:Dot(cameraRight)
				local forwardAmount = worldMoveDir:Dot(cameraLook)
				
				-- Create camera-relative move vector
				MoveDir = Vector3.new(rightAmount, 0, -forwardAmount)
			end
		else
			-- Desktop: Use ControlModule
			if GetMoveVector then
				MoveDir = GetMoveVector:GetMoveVector()
			end
		end
		
		-- Apply movement based on camera direction
		if MoveDir.X > 0 then
			FlyForce.Velocity = FlyForce.Velocity + Camera.CFrame.RightVector * MoveDir.X * Speed
		end
		if MoveDir.X < 0 then
			FlyForce.Velocity = FlyForce.Velocity + Camera.CFrame.RightVector * MoveDir.X * Speed
		end
		if MoveDir.Z > 0 then
			FlyForce.Velocity = FlyForce.Velocity - Camera.CFrame.LookVector * MoveDir.Z * Speed
		end
		if MoveDir.Z < 0 then
			FlyForce.Velocity = FlyForce.Velocity - Camera.CFrame.LookVector * MoveDir.Z * Speed
		end
	end)
	
	print("[Flight] Flight enabled" .. (isMobile and " (Mobile)" or " (Desktop)"))
end

-- Function to disable flight
local function disableFlight()
	if not isFlying then
		return
	end
	
	isFlying = false
	
	-- Disconnect render loop
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	
	-- Remove BodyVelocity
	if FlyForce and FlyForce.Parent then
		FlyForce:Destroy()
	end
	FlyForce = nil
	
	print("[Flight] Flight disabled")
end

-- Listen for flight events from server
FlightEvent.OnClientEvent:Connect(function(action)
	if action == "enable" then
		enableFlight()
	elseif action == "disable" then
		disableFlight()
	end
end)

-- Cleanup on character respawn
player.CharacterAdded:Connect(function()
	-- Disable flight when character respawns
	if isFlying then
		disableFlight()
	end
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		disableFlight()
	end
end)

print("[Flight] Flight control initialized")
