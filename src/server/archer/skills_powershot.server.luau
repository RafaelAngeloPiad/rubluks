-- ========================================
-- POWER SHOT SKILL SERVER
-- Raw and procedural implementation
-- Based on original PowerShot.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Helper function to get player's MaxAttack stat
local function getPlayerMaxAttack(player)
	if not player then return 0 end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end
	
	local maxAttack = leaderstats:FindFirstChild("MaxAttack")
	if not maxAttack then return 0 end
	
	return maxAttack.Value or 0
end

-- Helper function to calculate actual damage from multiplier with crit chance
-- @param player: Player instance
-- @param classType: Class name (e.g., "Archer")
-- @param damageMultiplier: Damage multiplier (e.g., 0.2 = 20% of MaxAttack)
-- @return: actualDamage, isCrit - the final damage value and whether it was a critical hit
local function calculateDamageForHitbox(player, classType, damageMultiplier)
	-- Check if calculateDamageWithCrit function exists (fallback for module caching issues)
	if ServerConfigs.calculateDamageWithCrit then
		return ServerConfigs.calculateDamageWithCrit(damageMultiplier, player)
	else
		-- Fallback: if function doesn't exist, use base damage calculation
		local maxAttack = getPlayerMaxAttack(player)
		if ServerConfigs.calculateDamage then
			return ServerConfigs.calculateDamage(damageMultiplier, maxAttack), false
		else
			warn("[PowerShot] ServerConfigs.calculateDamageWithCrit not found, using fallback.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

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
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[PowerShot] Skill blocked: Player " .. player.Name .. " tried to use Archer skill with mismatched weapon.")
			return
		end
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
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "powerShot", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "powerShot")
	
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

		-- Determine shooting direction based on aim lock state (not first-person state)
		local shootDirection
		if aimLockEnabled then
			-- Aim lock enabled (first or third person): use full camera direction (vertical + horizontal)
			shootDirection = cameraDirection or root.CFrame.LookVector
		else
			-- Aim lock disabled (first or third person): use character direction (horizontal only)
			shootDirection = root.CFrame.LookVector
		end

		-- Gagalaw forward gamit BodyVelocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = shootDirection * 200 -- adjust speed (reduced from 550 for better visibility)
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Parent = arrowPart

		-- Calculate actual damage based on player's MaxAttack stat (skill2Damage is now a multiplier)
		local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skill2Damage or 0.4
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Archer", damageMultiplier)
		
		-- Use projectile hitbox system for power arrow
		_G.createTravelingHitbox({
			attachTo = arrowPart,
			offset = CFrame.new(0, 0, 0),
			size = ServerConfigs.ArcherSkills.PowerShot.hitboxSize,
			damage = actualDamage, -- Use calculated damage based on MaxAttack
			character = character,
			name = "PowerArrow",
			showVisual = true,
			visualColor = Color3.new(1, 1, 0), -- Yellow for power arrow
			delay = ServerConfigs.ArcherSkills.PowerShot.hitboxDelay
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
		game:GetService("Debris"):AddItem(bodyVelocity, 2)
	end)
	
	-- PowerTrail marker (from original PowerShot.lua)
	animTrack:GetMarkerReachedSignal("PowerTrail"):Connect(function()
		local root = character:WaitForChild("HumanoidRootPart")
		
		-- Determine shooting direction based on aim lock state (not first-person state)
		local shootDirection
		if aimLockEnabled then
			-- Aim lock enabled (first or third person): use full camera direction (vertical + horizontal)
			shootDirection = cameraDirection or root.CFrame.LookVector
		else
			-- Aim lock disabled (first or third person): use character direction (horizontal only)
			shootDirection = root.CFrame.LookVector
		end
		
		-- Configuration for 6 PowerTrails
		local forwardOffset = 5 -- Starting distance from player
		local gap = 20 -- Distance between each trail
		local numTrails = 5 -- Number of trails to generate
		
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

			-- Calculate DOT damage based on player's MaxAttack stat (skill2Damage multiplier for trail)
			-- Trail damage is a percentage of the skill damage (adjust multiplier as needed)
			-- Note: Each DOT tick rolls crit independently
			local trailDamageMultiplier = (ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skill2Damage or 0.4) * 0.05 -- 5% of skill damage per tick (nerfed from 12.5%)
			local trailDamage, trailIsCrit = calculateDamageForHitbox(player, "Archer", trailDamageMultiplier)
			
			-- Add static DOT hitbox to PowerTrail (horizontal fire trail)
			_G.createStaticDOTHitbox({
				cframe = CFrame.lookAt(trailPosition, trailPosition + shootDirection),
				offset = CFrame.new(0, 0, 0), -- Center of trail
				size = Vector3.new(10, 10, 10), -- Smaller size for individual trails
				damage = trailDamage, -- Scaled damage per tick
				damageTickTime = ServerConfigs.ArcherSkills.PowerShot.damageTickTime or 0.3,
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
