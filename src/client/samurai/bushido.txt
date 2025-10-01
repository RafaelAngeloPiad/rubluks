local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer
local tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
		{cf = root.CFrame * CFrame.new(-5, 1.5, -1.5) * CFrame.Angles(0, math.rad(-80), 0), tweenTime = 1, holdTime = 2.5},
		{cf = root.CFrame * CFrame.new(0, 2, -3.5) * CFrame.Angles(0, math.rad(-180), 0), tweenTime = 0, holdTime = 1.5},
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

local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://111377142829522"


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)

	-- ⚡ AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("Aura"):Connect(function()

		local vfx = ReplicatedStorage.Bushido:WaitForChild("Aura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -2, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end
		
		game:GetService("Debris"):AddItem(vfx, 4.5)
	end)

	-- 🔹 Left click handler (ito lang uulit-ulit)
	tool.Activated:Connect(function()
		animTrack:Play()
		playSkillCamera()
	end)
end)


--[[ Example trigger (left click)
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		--playSkillCamera()
	end
end)
]]