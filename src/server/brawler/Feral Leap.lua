local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local tool = script.Parent
local player = Players.LocalPlayer

-- preload animations
local leapAnim = Instance.new("Animation")
leapAnim.AnimationId = "rbxassetid://76859592290622"

local leapAttackAnim = Instance.new("Animation")
leapAttackAnim.AnimationId = "rbxassetid://98157070007403"

tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(leapAnim)
	local animTrack2 = animator:LoadAnimation(leapAttackAnim)

	local isLeaping = false
	local leapConnection
	local currentVelocity
	local baseDirection = Vector3.zero
	local wallConnection -- for collision detection

	-- Function to safely stop leap
	local function stopLeap()
		if not isLeaping then return end
		isLeaping = false

		-- Disconnect movement loop
		if leapConnection then
			leapConnection:Disconnect()
			leapConnection = nil
		end

		-- Destroy velocity so it stops instantly
		if currentVelocity then
			currentVelocity:Destroy()
			currentVelocity = nil
		end

		-- Stop first anim and play second
		animTrack:Stop()
		animTrack2:Play()

		-- Trigger VFX at "ClawMark"
		animTrack2:GetMarkerReachedSignal("ClawMark"):Once(function()
			local vfx = ReplicatedStorage.FeralLeap:WaitForChild("FeralLeap"):Clone()
			vfx.Parent = workspace
			vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -25))

			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
				end
			end

			Debris:AddItem(vfx, 1)
		end)
	end

	animTrack:GetMarkerReachedSignal("Leap"):Connect(function()
		isLeaping = true

		-- Direction forward by default
		baseDirection = root.CFrame.LookVector

		currentVelocity = Instance.new("BodyVelocity")
		currentVelocity.MaxForce = Vector3.new(1e6, 0, 1e6)
		currentVelocity.Velocity = baseDirection * 170
		currentVelocity.Parent = root
		
		-- Detect wall collision
		wallConnection = root.Touched:Connect(function(hit)
			if not isLeaping then return end
			-- ignore self and character parts
			if hit:IsDescendantOf(character) then return end

			-- Optional: ignore very small parts or triggers
			if hit.CanCollide and hit.Transparency < 1 then
				stopLeap()
			end
		end)

		-- Update direction every frame
		leapConnection = RunService.Heartbeat:Connect(function()
			if not isLeaping or not currentVelocity or not root then return end

			local moveDir = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				moveDir += root.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				moveDir -= root.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				moveDir -= root.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				moveDir += root.CFrame.RightVector
			end

			if moveDir.Magnitude > 0 then
				moveDir = moveDir.Unit
				currentVelocity.Velocity = moveDir * 170
			else
				currentVelocity.Velocity = baseDirection * 170
			end
		end)
	end)

	-- kapag natapos ang animation
	animTrack.Stopped:Connect(stopLeap)

	-- G = stop leap
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.G and isLeaping then
			stopLeap()
		end
	end)

	-- left click = start leap
	tool.Activated:Connect(function()
		if not isLeaping then
			animTrack:Play()
		end
	end)
end)
