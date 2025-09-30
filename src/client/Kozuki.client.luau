local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local player = Players.LocalPlayer

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://101344605319771"


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)

	animTrack:GetMarkerReachedSignal("DashAttack"):Connect(function()
		-- DASH forward
		--[[
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(200000, 0, 200000)
		bodyVelocity.Velocity = root.CFrame.LookVector * 170
		bodyVelocity.Parent = root
		game.Debris:AddItem(bodyVelocity, 0.2)
		]]
		
		-- Teleport forward
		local char = player.Character
		local root = char:WaitForChild("HumanoidRootPart")

		-- Default offset (gusto mo pababa -5 studs)
		local localOffset = CFrame.new(0, 0, -10) 

		-- Desired target position relative to player
		local targetCFrame = root.CFrame * localOffset
		local targetPos = targetCFrame.Position

		-- Raycast params (para makita kung may tatamaan)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char} -- huwag tamaan ang sarili
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		-- Gumawa ng ray mula sa current pos papunta sa target
		local direction = targetPos - root.Position
		local rayResult = workspace:Raycast(root.Position, direction, rayParams)

		if rayResult then
			-- ? May na-hit na wall/floor bago makarating
			-- Gamitin yung position na malapit bago yung collision point
			root.CFrame = CFrame.new(rayResult.Position + rayResult.Normal * 2)
		else
			-- ? Walang sagabal, teleport direkta
			root.CFrame = targetCFrame
		end

		-- VFX
		
		
		local vfx = ReplicatedStorage.KozukiAura:WaitForChild("Slashes"):Clone()
		vfx.Parent = workspace

		--[[ Anchor sa left foot
		local foot = character:FindFirstChild("UpperTorso") or root
		local offset = CFrame.new(0, -5, 0)-- X = left/right, Y = harap/likod, Z = taas/baba

		vfx:PivotTo(foot.CFrame * offset)

		-- Weld all BaseParts to foot
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = foot
				weld.Part1 = part
				weld.Parent = part
				part.Anchored = false
			end
		end
		]]
		
		local root = character:WaitForChild("HumanoidRootPart")
		
		-- Palitin yung buong VFX model
		if vfx:IsA("Model") then
			vfx:ScaleTo(0.1) -- kalahati ng original size (0.5 = 50%, 2 = 200%)
		else
			-- Palitin lahat ng parts, meshes, particles sa loob ng VFX
			for _, obj in ipairs(vfx:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Size = obj.Size * 0.5 -- liitan basepart size
				elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
					obj.Size = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 1), -- start size
						NumberSequenceKeypoint.new(1, 10)  -- end size
					}
				elseif obj:IsA("Beam") then
					obj.Width0 = obj.Width0 * 10
					obj.Width1 = obj.Width1 * 10
				elseif obj:IsA("SpecialMesh") then
					obj.Scale = obj.Scale * 1
				end
			end

		end

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, 0)* rotation)
		
		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		Debris:AddItem(vfx, 3)
		
	end)

	-- ? AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		
			local vfx = ReplicatedStorage.KozukiAura:WaitForChild("AuraStance"):Clone()
			vfx.Parent = workspace

			-- Anchor sa left foot
			local foot = character:FindFirstChild("LowerTorso") or root
			local offset = CFrame.new(-3, -3, 0)-- X = left/right, Y = up/down, Z = forward/back
			
			vfx:PivotTo(foot.CFrame * offset)

			-- Weld all BaseParts to foot
			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = foot
					weld.Part1 = part
					weld.Parent = part
					part.Anchored = false
				end
			end

			-- Auto cleanup
			Debris:AddItem(vfx, 2)
	end)

	-- ?? Left click handler (ito lang uulit-ulit)
	tool.Activated:Connect(function()
		animTrack:Play()
	end)
end)
