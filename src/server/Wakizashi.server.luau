-- Script (ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--local RockModule = require(ReplicatedStorage:WaitForChild("RockModule"))

-- Remote setup
local remote = ReplicatedStorage:FindFirstChild("AttackEvent") 
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AttackEvent"
	remote.Parent = ReplicatedStorage
end

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://121133581854383"

remote.OnServerEvent:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()

	-- ? DASH marker
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

	-- ? AURA marker
	animTrack:GetMarkerReachedSignal("SonicBlade"):Connect(function()
		local vfx = ReplicatedStorage.WakizashiAura:WaitForChild("Slash"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(90) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		-- Kukunin natin yung main mesh (blade)
		local bladePart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

		-- Gagalaw forward gamit BodyVelocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = root.CFrame.LookVector * 160 -- adjust speed
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = bladePart

		

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
		game:GetService("Debris"):AddItem(bodyVelocity, 2)
	end)


	
end)
