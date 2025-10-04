-- ========================================
-- PIERCING SHOT SKILL SERVER
-- Raw and procedural implementation
-- Based on original PiercingShot.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation (from original PiercingShot.lua)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://108417542929570"

remote.OnServerEvent:Connect(function(player, skillType, ...)
	-- Only handle piercingShot skill requests
	if skillType ~= "piercingShot" then
		return
	end
	
	-- Get camera direction if provided
	local args = {...}
	local cameraDirection = args[1]
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "piercingShot") then
		local remainingTime = _G.getRemainingCooldown(player, "piercingShot")
		_G.sendCooldownStatus(player, "piercingShot", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "piercingShot")
	local cooldownTime = _G.ARCHER_COOLDOWNS["piercingShot"]
	_G.sendCooldownStatus(player, "piercingShot", true, cooldownTime)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "piercingShot")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setArcherWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- BackDash marker (from original PiercingShot.lua)
	animTrack:GetMarkerReachedSignal("BackDash"):Connect(function()
		-- Use camera direction if provided, otherwise fallback to character direction
		local shootDirection = cameraDirection or root.CFrame.LookVector
		
		-- Gagalaw backward gamit BodyVelocity - move backward relative to camera direction
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = -shootDirection * 40 -- adjust speed
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = root

		game:GetService("Debris"):AddItem(bodyVelocity, 0.25)
	end)

	-- ArrowSpark marker (from original PiercingShot.lua)
	animTrack:GetMarkerReachedSignal("ArrowSpark"):Connect(function()
		local vfx = ReplicatedStorage.PiercingShot:WaitForChild("FlamingSpark"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Use camera direction if provided, otherwise fallback to character direction
		local shootDirection = cameraDirection or root.CFrame.LookVector

		-- Position sa harap ng player (independent, no weld) - follow camera direction
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(90) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

		-- Position spark effect in camera direction
		vfx:PivotTo(root.CFrame * CFrame.new(shootDirection.X * forwardOffset, 0, shootDirection.Z * forwardOffset) * rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1.27)
	end)

	-- FlamingArrow marker (from original PiercingShot.lua)
	animTrack:GetMarkerReachedSignal("FlamingArrow"):Connect(function()
		local vfx = ReplicatedStorage.PiercingShot:WaitForChild("FlamingArrow"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
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

		-- Kukunin natin yung main mesh (arrow)
		local arrowPart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

		-- Use camera direction if provided, otherwise fallback to character direction
		local shootDirection = cameraDirection or root.CFrame.LookVector

		-- Gagalaw forward gamit BodyVelocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = shootDirection * 160 -- adjust speed
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = arrowPart

		-- Use projectile hitbox system for piercing arrow
		_G.createTravelingHitbox({
			attachTo = arrowPart,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(3, 3, 3),
			damage = 25,
			character = character,
			name = "PiercingArrow",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0), -- Orange for flaming arrow
			delay = 0
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
		game:GetService("Debris"):AddItem(bodyVelocity, 2)
	end)

end)
