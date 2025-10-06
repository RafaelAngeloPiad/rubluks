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
	
	-- Get camera direction, aim lock state, and first-person state if provided
	local args = {...}
	local cameraDirection = args[1]
	local aimLockEnabled = args[2] or false
	local isFirstPerson = args[3] or false
	
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
	
	-- Sync aim lock state to client
	_G.syncAimLockState(player, aimLockEnabled)
	
	-- Handle movement based on aim lock state
	if aimLockEnabled then
		-- Lock movement only when skill starts (allows camera/aiming)
		remote:FireClient(player, "lock_movement")
		_G.setArcherWalkingSpeed(player, "slow") -- Set slow walking speed
		
		-- Unlock movement when animation ends
		animTrack.Stopped:Connect(function()
			remote:FireClient(player, "unlock_movement")
			_G.setArcherWalkingSpeed(player, "normal") -- Restore normal walking speed
		end)
	else
		-- Only cleanup archer aiming system (hides crosshair) - allow free movement
		remote:FireClient(player, "cleanup_archer_aiming")
		
		-- Restore archer aiming system when done (shows crosshair)
		animTrack.Stopped:Connect(function()
			-- Restore archer aiming system (shows crosshair)
			remote:FireClient(player, "setup_archer_aiming")
		end)
	end

	-- PowerAura marker (from original PowerShot.lua)
	animTrack:GetMarkerReachedSignal("PowerAura"):Connect(function()
		local vfx = ReplicatedStorage.PowerShot:WaitForChild("PowerAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld) - match original
		local forwardOffset = 0 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

		vfx:PivotTo(root.CFrame * CFrame.new(0, 13, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable and non-physical (if enabled)
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				if _G.ARCHER_ARROW_HITBOX.preventPhysicsPush then
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
				end
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

		-- Position sa harap ng player (independent, no weld) - match original
		local forwardOffset = 5 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
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

		-- Kukunin natin yung main mesh (arrow)
		local arrowPart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

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

		-- Gagalaw forward gamit BodyVelocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = shootDirection * 120 -- adjust speed (reduced from 550 for better visibility)
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = arrowPart

		-- Use projectile hitbox system for power arrow
		_G.createTravelingHitbox({
			attachTo = arrowPart,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(35, 35, 35), -- Increased from 25x25x25 to 35x35x35
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
		local root = character:WaitForChild("HumanoidRootPart")
		
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
		
		-- Configuration for 6 PowerTrails
		local forwardOffset = 5 -- Starting distance from player
		local gap = 15 -- Distance between each trail
		local numTrails = 6 -- Number of trails to generate
		
		-- Generate 6 PowerTrails in a line
		for i = 1, numTrails do
			local vfx = ReplicatedStorage.PowerShot:WaitForChild("PowerTrail"):Clone()
			vfx.Parent = workspace

			-- Calculate position for this trail (each one further forward)
			local trailOffset = forwardOffset + (i - 1) * gap
			local trailPosition = root.Position + shootDirection * trailOffset
			
			-- Position trail in the shooting direction
			vfx:PivotTo(CFrame.lookAt(trailPosition, trailPosition + shootDirection))

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

			-- Add static DOT hitbox to PowerTrail (horizontal fire trail)
			_G.createStaticDOTHitbox({
				cframe = CFrame.lookAt(trailPosition, trailPosition + shootDirection),
				offset = CFrame.new(0, 0, 0), -- Center of trail
				size = Vector3.new(12, 12, 20), -- Smaller size for individual trails
				damage = 5, -- Damage per tick
				damageTickTime = 0.3, -- Damage every 0.3 seconds
				character = character,
				name = "PowerTrail" .. i,
				showVisual = true,
				visualColor = Color3.new(1, 0.5, 0), -- Orange for trail
				attachTo = vfx -- Will stop when VFX is destroyed
			})

			-- Auto cleanup
			game:GetService("Debris"):AddItem(vfx, 5)
		end
	end)

end)
