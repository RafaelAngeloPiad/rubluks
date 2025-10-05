-- ========================================
-- POWER SHOT SKILL SERVER
-- Raw and procedural implementation
-- Based on original PowerShot.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload anim (from original PowerShot.lua)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://104928487278221"

remote.OnServerEvent:Connect(function(player, skillType, ...)
	-- Only handle powerShot skill requests
	if skillType ~= "powerShot" then
		return
	end
	
	-- Get camera direction if provided (use camera direction for aiming)
	local args = {...}
	local cameraDirection = args[1]
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "powerShot") then
		local remainingTime = _G.getRemainingCooldown(player, "powerShot")
		_G.sendCooldownStatus(player, "powerShot", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "powerShot")
	local cooldownTime = _G.ARCHER_COOLDOWNS["powerShot"]
	_G.sendCooldownStatus(player, "powerShot", true, cooldownTime)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "powerShot")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setArcherWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- PowerAura marker (from original PowerShot.lua)
	animTrack:GetMarkerReachedSignal("PowerAura"):Connect(function()
		local vfx = ReplicatedStorage.PowerShot:WaitForChild("PowerAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 0 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

		vfx:PivotTo(root.CFrame * CFrame.new(0, 13, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2.5)
	end)

	-- PowerShot marker (from original PowerShot.lua)
	animTrack:GetMarkerReachedSignal("PowerShot"):Connect(function()
		local vfx = ReplicatedStorage.PowerShot:WaitForChild("PowerShot"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
		
		-- Calculate rotation to make arrow face the shooting direction
		local shootDirection = cameraDirection or root.CFrame.LookVector
		local rotationX = math.asin(-shootDirection.Y) -- Vertical rotation based on Y component
		local rotationY = math.atan2(shootDirection.X, shootDirection.Z) -- Horizontal rotation
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

		-- Kukunin natin yung main mesh (arrow)
		local arrowPart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

		-- Use camera direction if provided, otherwise fallback to character direction
		local shootDirection = cameraDirection or root.CFrame.LookVector

		-- Gagalaw forward gamit BodyVelocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = shootDirection * 550 -- adjust speed
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = arrowPart

		-- Use projectile hitbox system for power arrow
		_G.createTravelingHitbox({
			attachTo = arrowPart,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(25, 25, 25), -- Greatly increased from 8x8x8 to 25x25x25
			damage = 35,
			character = character,
			name = "PowerArrow",
			showVisual = true,
			visualColor = Color3.new(1, 1, 0), -- Yellow for power arrow
			delay = 0
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
		game:GetService("Debris"):AddItem(bodyVelocity, 2)
	end)
	
	-- PowerTrail marker (from original PowerShot.lua)
	animTrack:GetMarkerReachedSignal("PowerTrail"):Connect(function()
		local vfx = ReplicatedStorage.PowerShot:WaitForChild("PowerTrail"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 85 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
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

		-- Add static DOT hitbox to PowerTrail (horizontal fire trail)
		_G.createStaticDOTHitbox({
			cframe = root.CFrame * CFrame.new(0, 0, -forwardOffset/2), -- Center of trail
			size = Vector3.new(8, 8, 120), -- Long trail hitbox
			damage = 5, -- Damage per tick
			damageTickTime = 0.3, -- Damage every 0.3 seconds
			character = character,
			name = "PowerTrail",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0), -- Orange for trail
			attachTo = vfx -- Will stop when VFX is destroyed
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 5)
	end)

end)
