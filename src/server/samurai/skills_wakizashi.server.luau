-- ========================================
-- WAKIZASHI SKILL SERVER
-- Raw and procedural implementation
-- Based on original Wakizashi.server.luau
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown tracking (temporary variable system)
local playerCooldowns = {}
local WAKIZASHI_COOLDOWN = 8 -- 8 seconds cooldown

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://121133581854383"

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle wakizashi skill requests
	if skillType ~= "wakizashi" then
		return
	end
	
	-- Check cooldown
	local currentTime = tick()
	if playerCooldowns[player.UserId] and (currentTime - playerCooldowns[player.UserId]) < WAKIZASHI_COOLDOWN then
		local remainingTime = WAKIZASHI_COOLDOWN - (currentTime - playerCooldowns[player.UserId])
		-- Send cooldown status to client
		local remote = ReplicatedStorage:WaitForChild("ActionEvent")
		remote:FireClient(player, "cooldown_status", "wakizashi", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown
	playerCooldowns[player.UserId] = currentTime
	-- Send cooldown status to client (skill is now on cooldown)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireClient(player, "cooldown_status", "wakizashi", true, WAKIZASHI_COOLDOWN)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack)
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setSamuraiWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- ? DASH marker
	animTrack:GetMarkerReachedSignal("ElectricAura"):Connect(function()

		-- left hand lightning
		local vfxLeft = ReplicatedStorage.WakizashiAura:WaitForChild("lightningLeft"):Clone()
		vfxLeft.Parent = workspace

		local leftHand = character:FindFirstChild("LeftHand") or root
		local offsetLeft = CFrame.new(-3, 0, 0)-- X = left/right, Y = taas/baba, Z = harap/likod

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
		local offsetRight = CFrame.new(3, 0, 0)-- X = left/right, Y = taas/baba, Z = harap/likod

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

		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, -forwardOffset) * rotation)

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

		-- HITBOX V3: Attach traveling hitbox to blade
		-- Note: delay now automatically scales with animation speed multiplier
		_G.createTravelingHitbox({
			attachTo = bladePart,
			offset = CFrame.new(-30, 0, 0), -- tagilid kasi yung blade so x - up down  y - left / right  z - up down
			size = Vector3.new(8, 30, 8), -- width, height, depth
			damage = 25,
			-- duration removed - will last as long as bladePart exists (2 seconds via Debris)
			delay = 0.25, -- Base delay (will auto-scale with animation speed: 0.25s at 1x speed, 0.125s at 2x speed)
			character = character,
			name = "Wakizashi",
			showVisual = true,
			visualColor = Color3.new(0, 0.5, 1) -- Light blue
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
		game:GetService("Debris"):AddItem(bodyVelocity, 2)
	end)

end)
