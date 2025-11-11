-- ========================================
-- MIGHTY BLADE ULTIMATE SERVER
-- Raw and procedural implementation
-- Based on original MightyBlade.lua
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
-- @param damageMultiplier: Damage multiplier (e.g., 0.143 = 14.3% of MaxAttack)
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
			warn("[Knight MightyBlade] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://100472690161584"

-- MIGHTY BLADE HITBOX CONFIG (using centralized config)
local MIGHTYBLADE_CONFIG = ServerConfigs.KnightSkills.MightyBlade

local function createTemporaryHitboxAnchor(character, offsetCFrame, lifetime)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	offsetCFrame = offsetCFrame or CFrame.new()
	lifetime = lifetime or 3

	local anchor = Instance.new("Part")
	anchor.Name = "MightyBladeHitboxAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Massless = true
	anchor.Anchored = false
	anchor.CFrame = root.CFrame * offsetCFrame
	anchor.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = anchor
	weld.Parent = anchor

	Debris:AddItem(anchor, lifetime)

	return anchor
end

-- Helper functions from original MightyBlade.lua
local function swordsNear(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Handle"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(70), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1.2)

end

local function explosionNear(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Ground"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, -3, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end


	Debris:AddItem(vfx, 1)

end

local function swordsFar(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Handle"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 100

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(110), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1.2)

end

local function explosionFar(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Ground"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 100

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), -3, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end


	Debris:AddItem(vfx, 1)

end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle mightyblade ultimate requests
	if skillType ~= "mightyblade" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[MightyBlade] Skill blocked: Player " .. player.Name .. " tried to use Knight skill with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.knightIsSkillOnCooldown(player, "mightyblade") then
		local remainingTime = _G.knightGetRemainingCooldown(player, "mightyblade")
		_G.knightSendCooldownStatus(player, "mightyblade", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.knightSetSkillCooldown(player, "mightyblade")
	local cooldownTime = _G.KNIGHT_COOLDOWNS["mightyblade"]
	_G.knightSendCooldownStatus(player, "mightyblade", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.knightSendCooldownStatus(player, "mightyblade", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyKnightAnimationSpeed(animTrack, "mightyblade")
	
	-- Enable invincibility (freeze health during ultimate)
	_G.enablePlayerInvincibility(player)
	
	-- Lock input when ultimate starts
	remote:FireClient(player, "lock_input")
	_G.setKnightWalkingSpeed(player, "blocking") -- Stop movement during ultimate
	
	-- Camera sequence (added system)
	remote:FireClient(player, "play_camera_sequence", "mightyblade")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		-- Disable invincibility (allow damage again)
		_G.disablePlayerInvincibility(player)
		
		remote:FireClient(player, "unlock_input")
		_G.setKnightWalkingSpeed(player, "normal") -- Restore normal movement
	end)
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Ground"):Clone()
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

		local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Aura"):Clone()
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
		local vfxLeft = ReplicatedStorage.MightyBlade:WaitForChild("Handle"):Clone()
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
		local vfxRight = ReplicatedStorage.MightyBlade:WaitForChild("Handle"):Clone()
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
	-- From original MightyBlade.lua
	animTrack:GetMarkerReachedSignal("SwordNear"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			swordsNear(character, angle,  math.rad(-70))
			explosionNear(character, angle,  math.rad(-70))
		end
		
		-- ONE MASSIVE CENTER DOT HITBOX for entire ultimate
		local root = character:WaitForChild("HumanoidRootPart")
		local damageMultiplier = MIGHTYBLADE_CONFIG.hitboxDamage
		local actualDamage, isCrit = calculateDamageForHitbox(player, damageMultiplier)
		local hitboxDuration = math.max((MIGHTYBLADE_CONFIG.damageTickTime or 0.5) * 6, 3)
		local hitboxAnchor = createTemporaryHitboxAnchor(character, CFrame.new(0, 0, 0), hitboxDuration)
		_G.createStaticDOTHitbox({
			attachTo = hitboxAnchor or root,
			offset = CFrame.new(0, 0, 0),
			size = MIGHTYBLADE_CONFIG.hitboxSize, -- Massive center hitbox
			damage = actualDamage, -- Damage per tick (calculated with crit)
			damageTickTime = MIGHTYBLADE_CONFIG.damageTickTime, -- Damage every 0.5 seconds
			duration = hitboxDuration,
			character = character,
			name = "MightyBlade Center DOT",
			showVisual = false,
			visualColor = Color3.new(0.8, 0.8, 0), -- Yellow
			delay = MIGHTYBLADE_CONFIG.hitboxDelay,
			actionType = "mightyblade",
			classType = "Knight"
		})
	end)

	animTrack:GetMarkerReachedSignal("Sword Far"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			swordsFar(character, angle,  math.rad(-70))
			explosionFar(character, angle,  math.rad(-70))
		end
	end)

end)
