local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera

local tool = script.Parent
local player = Players.LocalPlayer

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://133910790786834"

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
		{cf = root.CFrame * CFrame.new(0, 2, 4) * CFrame.Angles(0, math.rad(0), 0), tweenTime = 0, holdTime = 1},
		{cf = root.CFrame * CFrame.new(-5, -0.5, -1.5) * CFrame.Angles(0, math.rad(-90), 0), tweenTime = 1, holdTime = 2},
		{cf = root.CFrame * CFrame.new(8, -0.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), tweenTime = 0, holdTime = 1},
		{cf = root.CFrame * CFrame.new(0, -0.5, 8) * CFrame.Angles(0, math.rad(0), 0), tweenTime = 0, holdTime = 1},
		{cf = root.CFrame * CFrame.new(0, -0.5, -8) * CFrame.Angles(0, math.rad(-180), 0), tweenTime = 0, holdTime = 1},
		{cf = root.CFrame * CFrame.new(0, 8, 8) * CFrame.Angles(math.rad(-40), math.rad(0), 0), tweenTime = 0, holdTime = 1},
		
		
		
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


-- params
--local forwardOffset = 5     -- gaano kalayo magsimula mula sa center
--local bladeSpeed = 160      -- bilis ng blade
--local bladeTiltYawDeg = -45 -- negative = pakaliwa, positive = pakanan (deg)

-- kung tinatawag sa loob ng function kung saan meron 'character' at 'angle'
local function createSlash(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.WakizashiAura:WaitForChild("Slash"):Clone()
	vfx.Parent = workspace

	-- Distance mula sa player
	local forwardOffset = 5  

	-- Rotation para sa direksyon palabas
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Rotation para sa itsura lang (ikot ng blade mismo)
	local tiltRotation = CFrame.Angles(0, math.rad(90), 0) -- pwede mo gawing 45

	-- Final spawn position (may tilt sa visual)
	local spawnCF = root.CFrame * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Ensure lahat ng parts ay hindi naka-anchor pero stable
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Kukunin yung main mesh (blade)
	local bladePart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

	-- Lipad palabas (base lang sa outwardRotation, walang tilt)
	local moveCF = root.CFrame * outwardRotation
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = moveCF.LookVector * 160
	bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bodyVelocity.Parent = bladePart

	-- Cleanup
	Debris:AddItem(vfx, 2)
	Debris:AddItem(bodyVelocity, 2)


end


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.Zantetsuken:WaitForChild("AuraTrigger"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 7.5)
	end)
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.Zantetsuken:WaitForChild("ZantetsukenAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -2, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 7.5)
	end)

	-- ⚡ DASH marker
	animTrack:GetMarkerReachedSignal("ElectricAura"):Connect(function()

		-- left hand lightning
		local vfxLeft = ReplicatedStorage.WakizashiAura:WaitForChild("lightningLeft"):Clone()
		vfxLeft.Parent = workspace

		local leftHand = character:FindFirstChild("LeftHand") or root
		local offsetLeft = CFrame.new(-3, 0, 0)-- X = left/right, Y = harap/likod, Z = taas/baba

		vfxLeft:PivotTo(leftHand.CFrame * offsetLeft)

		for _, part in ipairs(vfxLeft:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = leftHand
				weld.Part1 = part
				weld.Parent = part
				part.Anchored = false
			end
		end

		-- right hand lightning
		local vfxRight = ReplicatedStorage.WakizashiAura:WaitForChild("lightningRight"):Clone()
		vfxRight.Parent = workspace

		local rightHand = character:FindFirstChild("RightHand") or root
		local offsetRight = CFrame.new(3, 0, 0)-- X = left/right, Y = harap/likod, Z = taas/baba

		vfxRight:PivotTo(rightHand.CFrame * offsetRight)

		for _, part in ipairs(vfxRight:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = rightHand
				weld.Part1 = part
				weld.Parent = part
				part.Anchored = false
			end
		end

		game:GetService("Debris"):AddItem(vfxLeft, 2)
		game:GetService("Debris"):AddItem(vfxRight, 2)

	end)

	-- ⚡ AURA marker
	animTrack:GetMarkerReachedSignal("SonicBlade"):Connect(function()
		local angles = {0, 45, 90, 135, 180, 225, 270, 315}
		for _, a in ipairs(angles) do
			createSlash(character, a)
		end
	end)


	-- 🔹 Left click handler
	tool.Activated:Connect(function()
		animTrack:Play()
		playSkillCamera()

	end)
end)
