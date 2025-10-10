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
	
	-- Get camera direction, aim lock state, and first-person state if provided
	local args = {...}
	local cameraDirection = args[1]
	local aimLockEnabled = args[2] or false
	local isFirstPerson = args[3] or false
	
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
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "piercingShot", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "piercingShot")
	
	-- Sync aim lock state to client
	_G.syncAimLockState(player, aimLockEnabled)
	
	-- Always use slow walking speed during skill (like samurai skills)
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setArcherWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal walking speed
		-- Restore archer aiming system (will respect current aim lock state)
		remote:FireClient(player, "setup_archer_aiming")
	end)

	-- BackDash marker (from original PiercingShot.lua)
	animTrack:GetMarkerReachedSignal("BackDash"):Connect(function()
		-- Gagalaw backward gamit BodyVelocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = -root.CFrame.LookVector * 40 -- adjust speed
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = root

		game:GetService("Debris"):AddItem(bodyVelocity, 0.25)
	end)

	-- ArrowSpark marker (from original PiercingShot.lua)
	animTrack:GetMarkerReachedSignal("ArrowSpark"):Connect(function()
		local vfx = ReplicatedStorage.PiercingShot:WaitForChild("FlamingSpark"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld) - match original
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(90) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable and non-physical (if enabled)
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
				end
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

		-- Position sa harap ng player (independent, no weld) - match original
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
		
		-- Determine shooting direction based on first-person state and aim lock
		local shootDirection
		if isFirstPerson then
			-- In first-person: always use camera direction for precise aiming
			shootDirection = cameraDirection or root.CFrame.LookVector
		elseif aimLockEnabled then
			-- In third-person with aim lock: use camera direction
			shootDirection = cameraDirection or root.CFrame.LookVector
		else
			-- In third-person without aim lock: use character direction
			shootDirection = root.CFrame.LookVector
		end
		
		-- Position arrow in front of player in the shooting direction
		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, -forwardOffset) + shootDirection * forwardOffset)
		
		-- Rotate arrow to face the shooting direction
		local arrowCFrame = CFrame.lookAt(vfx:GetPivot().Position, vfx:GetPivot().Position + shootDirection)
		vfx:PivotTo(arrowCFrame)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable and non-physical (if enabled)
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
				end
			end
		end

		-- Kukunin natin yung main mesh (arrow)
		local arrowPart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

		-- Ensure all parts in the model can move together
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			end
		end

		-- Apply BodyVelocity to ALL parts so they move together
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.Velocity = shootDirection * 120 -- adjust speed (reduced from 160 for better visibility)
				bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
				bodyVelocity.Parent = part
			end
		end

		-- Use projectile hitbox system for piercing arrow
		_G.createTravelingHitbox({
			attachTo = arrowPart,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(30, 30, 30),
			damage = 25,
			character = character,
			name = "PiercingArrow",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0), -- Orange for flaming arrow
			delay = 0
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
	end)

end)
