local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RockModule = require(ReplicatedStorage.RockModule)

local tool = script.Parent
local player = Players.LocalPlayer

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://124154885589921"


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)

	-- 1st explosion
	animTrack:GetMarkerReachedSignal("ShieldBash"):Connect(function()

		local vfx = ReplicatedStorage.ShieldBash:WaitForChild("ShieldBash"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 5, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1)

	end)
	
	-- ?? Left click handler
	tool.Activated:Connect(function()
		animTrack:Play()

	end)
end)
