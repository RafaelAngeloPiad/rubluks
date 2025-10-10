-- ========================================
-- KOZUKI SKILL SERVER
-- Raw and procedural implementation
-- Based on original Kozuki.client.luau
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://101344605319771"

local function ResizeVFX(vfx, scale)
	for _, obj in ipairs(vfx:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- Liitan mismo part
			obj.Size = obj.Size * scale

			-- Kung may mesh sa loob ng part
			local mesh = obj:FindFirstChildWhichIsA("SpecialMesh")
			if mesh then
				mesh.Scale = mesh.Scale * scale
			end

		elseif obj:IsA("ParticleEmitter") then
			-- Scale particle size
			local newSize = {}
			for _, keypoint in ipairs(obj.Size.Keypoints) do
				table.insert(newSize, NumberSequenceKeypoint.new(
					keypoint.Time,
					keypoint.Value * scale
					))
			end
			obj.Size = NumberSequence.new(newSize)

			-- Optional din i-scale ang speed, lifetime, spread
			obj.Speed = NumberRange.new(obj.Speed.Min * scale, obj.Speed.Max * scale)
		end
	end
end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle kozuki skill requests
	if skillType ~= "kozuki" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "kozuki") then
		local remainingTime = _G.getRemainingCooldown(player, "kozuki")
		_G.sendCooldownStatus(player, "kozuki", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "kozuki")
	local cooldownTime = _G.SAMURAI_COOLDOWNS["kozuki"]
	_G.sendCooldownStatus(player, "kozuki", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "kozuki", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack, "kozuki")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setSamuraiWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

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
		ResizeVFX(vfx, 0.3) -- kalahati ng laki
		
		--[[ Palitin yung buong VFX model
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
		]]

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

		-- HITBOX V3: Static hitbox at root position (after dash)
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(12, 12, 15), -- Increased from 8x8x10 to 12x12x15
			damage = 30,
			-- duration removed - visual will last as long as VFX (1 second via Debris)
			delay = 0, -- delay before hitbox appears (in seconds)
			character = character,
			name = "Kozuki",
			showVisual = true,
			visualColor = Color3.new(1, 0, 0) -- Red
		})

		-- Auto cleanup
		Debris:AddItem(vfx, 1)
		
	end)

	-- ? AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		
		local vfx = ReplicatedStorage.KozukiAura:WaitForChild("AuraStance"):Clone()
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

		game:GetService("Debris"):AddItem(vfx, 1.8)
	end)

end)
