local tool = script.Parent
tool.RequiresHandle = false -- wag pakialaman ni Grip

-- Animations
local idleAnim = Instance.new("Animation")
idleAnim.AnimationId = "rbxassetid://132322083369838"

local runAnim = Instance.new("Animation")
runAnim.AnimationId = "rbxassetid://112708480600525"

local idleTrack, runTrack
local weld

tool.Equipped:Connect(function()
	local char = tool.Parent
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local rightHand = char:FindFirstChild("RightHand")
	local handle = tool:FindFirstChild("Handle")

	-- Weapon weld
	if rightHand and handle then
		weld = Instance.new("Motor6D")
		weld.Part0 = rightHand
		weld.Part1 = handle
		weld.C0 = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0) 
		weld.Name = "WeaponWeld"
		weld.Parent = rightHand

		handle.CanCollide = false
		handle.Massless = true
	end

	-- Animations
	if animator then
		idleTrack = animator:LoadAnimation(idleAnim)
		idleTrack.Looped = true
		idleTrack.Priority = Enum.AnimationPriority.Idle

		runTrack = animator:LoadAnimation(runAnim)
		runTrack.Looped = true
		runTrack.Priority = Enum.AnimationPriority.Movement

		idleTrack:Play()

		-- Switch run/idle instantly
		hum.Running:Connect(function(speed)
			if speed > 1 then -- lagyan threshold, e.g. >1 studs/sec
				if idleTrack.IsPlaying then idleTrack:Stop() end
				if not runTrack.IsPlaying then runTrack:Play() end
			else
				if runTrack.IsPlaying then runTrack:Stop() end
				if not idleTrack.IsPlaying then idleTrack:Play() end
			end
		end)
	end
end)

tool.Unequipped:Connect(function()
	if weld then
		weld:Destroy()
		weld = nil
	end
	if idleTrack then idleTrack:Stop() idleTrack = nil end
	if runTrack then runTrack:Stop() runTrack = nil end
end)
