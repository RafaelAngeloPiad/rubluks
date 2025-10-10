local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local tool = script.Parent
local player = Players.LocalPlayer

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://95054632322392"

--- Camera

-- Save original state
local function saveOriginal()
	return camera.CFrame, camera.CameraType
end

-- Tween helper
local function tweenTo(cf, time)
	local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = cf})
	tween:Play()
	tween.Completed:Wait()
end

-- Camera Sequence System
local function playSkillCamera()
	local origCFrame, origType = saveOriginal()
	camera.CameraType = Enum.CameraType.Scriptable

	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Define steps (camera position, tweenTime, holdTime)
	local sequence = {
		{cf = root.CFrame * CFrame.new(0, 1, -50) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 0, holdTime = 0.2},
		{cf = root.CFrame * CFrame.new(0, -1.5, -10) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 1, holdTime = 0.5},
		{cf = root.CFrame * CFrame.new(-8, 150, 0) * CFrame.Angles(math.rad(-90), math.rad(-20), 0), tweenTime = 0, holdTime = 6},
		{cf = root.CFrame * CFrame.new(-5, 2, -10) * CFrame.Angles(0, math.rad(210), 0), tweenTime = 0, holdTime = 2},
		--{cf = root.CFrame * CFrame.new(0, -0.5, 8) * CFrame.Angles(0, math.rad(0), 0), tweenTime = 0, holdTime = 1},
		--{cf = root.CFrame * CFrame.new(0, -0.5, -8) * CFrame.Angles(0, math.rad(-180), 0), tweenTime = 0, holdTime = 1},




		--{cf = root.CFrame * CFrame.new(0, 2, -3.5) * CFrame.Angles(0, math.rad(-180), 0), tweenTime = 0, holdTime = 1.5},
		--{cf = root.CFrame * CFrame.new(0, 10, 10) * CFrame.Angles(math.rad(-20), math.rad(180), 0), tweenTime = 1, holdTime = 2},
	}

	-- Run sequence instantly
	for _, step in ipairs(sequence) do
		tweenTo(step.cf, step.tweenTime)
		task.wait(step.holdTime)
	end

	-- Return to original
	tweenTo(origCFrame, 1)
	task.wait(0.5)
	camera.CameraType = origType
end


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)

	animTrack:GetMarkerReachedSignal("MeteorExplosion"):Connect(function()

		local vfx = ReplicatedStorage.MeteorDive:WaitForChild("MeteorExplosion"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -1, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 4)
	end)
	
	animTrack:GetMarkerReachedSignal("MeteorDrop"):Connect(function()

		local torso = character:WaitForChild("UpperTorso")

		-- Clone VFX
		local vfx = ReplicatedStorage.MeteorDive:WaitForChild("MeteorDrop"):Clone()
		vfx.Parent = workspace

		-- Position the VFX first (below the torso)
		vfx:PivotTo(torso.CFrame * CFrame.new(0, 0, 0)* CFrame.Angles(math.rad(180), 0, 0))

		-- Unanchor everything para gumalaw
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				--part.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 1) 
			end
		end
		
		local mainPart = vfx
		if mainPart then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, -150, 0) -- mas malaki = mas mabilis bagsak
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.Parent = mainPart
		end

		-- Find main part of the VFX (usually primary part)
		local vfxPrimary = vfx.PrimaryPart or vfx:FindFirstChildWhichIsA("BasePart")
		if not vfxPrimary then
			warn("?? No primary part found for MeteorDrop")
			return
		end

		-- Weld the VFX to the UpperTorso
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = vfxPrimary
		weld.Parent = torso

		game:GetService("Debris"):AddItem(vfx, 1)
	end)


	-- ?? Left click handler
	tool.Activated:Connect(function()
		animTrack:Play()
		playSkillCamera()

	end)
end)
