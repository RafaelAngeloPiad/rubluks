-- ========================================
-- ZANTETSUKEN ULTIMATE SERVER
-- Raw and procedural implementation
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

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
-- @param damageMultiplier: Damage multiplier (e.g., 1.0 = 100% of MaxAttack)
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
			warn("[Samurai Zantetsuken] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- ========================================
-- SOUND SYSTEM
-- Helper function to play attack sounds on client
-- ========================================

-- Import sound configuration
local SamuraiSoundConfig = require(ReplicatedStorage:WaitForChild("SamuraiSoundConfig"))

local function playAttackSound(player, attackType)
	if not player then return end
	local soundId = SamuraiSoundConfig.getSound(attackType)
	remote:FireClient(player, "play_sound", soundId)
end

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://133910790786834"

-- ZANTETSUKEN CONFIG (using centralized config)
local ZANTETSUKEN_CONFIG = ServerConfigs.SamuraiSkills.Zantetsuken

-- kung tinatawag sa loob ng function kung saan meron 'character' at 'angle'
local function createSlash(player, character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.WakizashiAura:WaitForChild("Slash"):Clone()
	vfx.Parent = workspace

	-- Distance mula sa player
	local forwardOffset = 5  

	-- Rotation para sa direksyon palabas
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Rotation para sa itsura lang (ikot ng blade mismo)
	local tiltRotation = CFrame.Angles(0, math.rad(90), 0) -- pwede mo gawing 45

	-- Final spawn position (may tilt sa visual)
	local spawnCF = root.CFrame * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Ensure lahat ng parts ay hindi naka-anchor pero stable
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Kukunin yung main mesh (blade)
	local bladePart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

	-- Lipad palabas (base lang sa outwardRotation, walang tilt)
	local moveCF = root.CFrame * outwardRotation
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = moveCF.LookVector * 160
	bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bodyVelocity.Parent = bladePart

	-- Play attack sound
	playAttackSound(player, "zantetsuken")
	
	-- HITBOX V3: Attach traveling hitbox to blade
	local damageMultiplier = ZANTETSUKEN_CONFIG.hitboxDamage
	local actualDamage, isCrit = calculateDamageForHitbox(player, damageMultiplier)
	_G.createTravelingHitbox({
		attachTo = bladePart,
		offset = CFrame.new(-30, 0, 0), -- tagilid kasi yung blade so x - up down  y - left / right  z - up down
		size = ZANTETSUKEN_CONFIG.hitboxSize,
		damage = actualDamage,
		-- duration removed - will last as long as bladePart exists (2 seconds via Debris)
		delay = ZANTETSUKEN_CONFIG.hitboxDelay, -- delay before hitbox appears (in seconds)
		character = character,
		name = "Zantetsuken",
		showVisual = false,
		visualColor = Color3.new(1, 0, 1), -- Purple
		actionType = "zantetsuken",
		classType = "Samurai"
	})

	-- Cleanup
	Debris:AddItem(vfx, 2)
	Debris:AddItem(bodyVelocity, 2)


end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle zantetsuken ultimate requests
	if skillType ~= "zantetsuken" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Zantetsuken] Skill blocked: Player " .. player.Name .. " tried to use Samurai skill with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.samuraiIsSkillOnCooldown(player, "zantetsuken") then
		local remainingTime = _G.samuraiGetRemainingCooldown(player, "zantetsuken")
		_G.samuraiSendCooldownStatus(player, "zantetsuken", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.samuraiSetSkillCooldown(player, "zantetsuken")
	local cooldownTime = _G.SAMURAI_COOLDOWNS["zantetsuken"]
	_G.samuraiSendCooldownStatus(player, "zantetsuken", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.samuraiSendCooldownStatus(player, "zantetsuken", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack, "zantetsuken")
	
	-- Enable invincibility (freeze health during ultimate)
	_G.enablePlayerInvincibility(player)
	
	-- Lock input when ultimate starts
	remote:FireClient(player, "lock_input")
	_G.setSamuraiWalkingSpeed(player, "blocking") -- Stop movement during ultimate
	
	-- Camera sequence (added system)
	remote:FireClient(player, "play_camera_sequence", "zantetsuken")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		-- Disable invincibility (allow damage again)
		_G.disablePlayerInvincibility(player)
		
		remote:FireClient(player, "unlock_input")
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal movement
	end)
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.Zantetsuken:WaitForChild("AuraTrigger"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 0, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 7.5)
	end)
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.Zantetsuken:WaitForChild("ZantetsukenAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -2, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 7.5)
	end)

	-- ⚡ DASH marker
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

	-- ⚡ SONIC BLADE marker
	animTrack:GetMarkerReachedSignal("SonicBlade"):Connect(function()
		local angles = {0, 45, 90, 135, 180, 225, 270, 315}
		for _, a in ipairs(angles) do
			createSlash(player, character, a)
		end
	end)

end)
