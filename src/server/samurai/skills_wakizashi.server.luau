-- ========================================
-- WAKIZASHI SKILL SERVER
-- Raw and procedural implementation
-- Based on original Wakizashi.server.luau
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
-- @param damageMultiplier: Damage multiplier (e.g., 0.5 = 50% of MaxAttack)
-- @return: actualDamage, isCrit - the final damage value and whether it was a critical hit
local function calculateDamageForHitbox(player, damageMultiplier)
	-- Check if calculateDamageWithCrit function exists (fallback for module caching issues)
	if ServerConfigs.calculateDamageWithCrit then
		return ServerConfigs.calculateDamageWithCrit(damageMultiplier, player)
	else
		-- Fallback: if function doesn't exist, use base damage calculation
		local maxAttack = getPlayerMaxAttack(player)
		if ServerConfigs.calculateDamage then
			return ServerConfigs.calculateDamage(damageMultiplier, maxAttack), false
		else
			warn("[Samurai Wakizashi] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://121133581854383"

-- WAKIZASHI CONFIG (using centralized config)
local WAKIZASHI_CONFIG = ServerConfigs.SamuraiSkills.Wakizashi

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle wakizashi skill requests
	if skillType ~= "wakizashi" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Wakizashi] Skill blocked: Player " .. player.Name .. " tried to use Samurai skill with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "wakizashi") then
		local remainingTime = _G.getRemainingCooldown(player, "wakizashi")
		_G.sendCooldownStatus(player, "wakizashi", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "wakizashi")
	local cooldownTime = _G.SAMURAI_COOLDOWNS["wakizashi"]
	_G.sendCooldownStatus(player, "wakizashi", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "wakizashi", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack, "wakizashi")
	
	-- Enable invincibility (freeze health during skill)
	_G.enablePlayerInvincibility(player)
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setSamuraiWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		-- Disable invincibility (allow damage again)
		_G.disablePlayerInvincibility(player)
		
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
		local damageMultiplier = WAKIZASHI_CONFIG.hitboxDamage
		local actualDamage, isCrit = calculateDamageForHitbox(player, damageMultiplier)
		_G.createTravelingHitbox({
			attachTo = bladePart,
			offset = CFrame.new(-30, 0, 0), -- tagilid kasi yung blade so x - up down  y - left / right  z - up down
			size = WAKIZASHI_CONFIG.hitboxSize,
			damage = actualDamage,
			-- duration removed - will last as long as bladePart exists (2 seconds via Debris)
			delay = WAKIZASHI_CONFIG.hitboxDelay, -- Base delay (will auto-scale with animation speed: 0.25s at 1x speed, 0.125s at 2x speed)
			character = character,
			name = "Wakizashi",
			showVisual = true,
			visualColor = Color3.new(0, 0.5, 1), -- Light blue
			actionType = "wakizashi",
			classType = "Samurai"
		})

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 2)
		game:GetService("Debris"):AddItem(bodyVelocity, 2)
	end)

end)
