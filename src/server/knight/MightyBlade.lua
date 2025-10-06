local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera

local tool = script.Parent
local player = Players.LocalPlayer

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://100472690161584"

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
		{cf = root.CFrame * CFrame.new(0, 1, -10) * CFrame.Angles(0, math.rad(180), 0), tweenTime = 0, holdTime = 1},
		{cf = root.CFrame * CFrame.new(8, -1.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), tweenTime = 1, holdTime = 2},
		{cf = root.CFrame * CFrame.new(0, 100, 100) * CFrame.Angles(math.rad(-40), math.rad(0), 0), tweenTime = 0, holdTime = 7}
		--{cf = root.CFrame * CFrame.new(8, -0.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), tweenTime = 0, holdTime = 1},
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


local function swordsNear(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Handle"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(70), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1.2)

end

local function explosionNear(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Ground"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, -3, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1)

end

local function swordsFar(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Handle"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 100

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(110), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1.2)

end

local function explosionFar(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Ground"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 100

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), -3, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1)

end


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)

	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Aura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 10)
	end)


	animTrack:GetMarkerReachedSignal("SwordNear"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			swordsNear(character, angle,  math.rad(-70))
			explosionNear(character, angle,  math.rad(-70))
		end
	end)

	animTrack:GetMarkerReachedSignal("Sword Far"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			swordsFar(character, angle,  math.rad(-70))
			explosionFar(character, angle,  math.rad(-70))
		end
	end)

	-- ?? Left click handler
	tool.Activated:Connect(function()
		animTrack:Play()
		playSkillCamera()

	end)
end)
