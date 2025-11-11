-- ========================================
-- STARFALL ULTIMATE SERVER
-- Simple procedural implementation matching original Starfall.lua
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
			warn("[Starfall] ServerConfigs.calculateDamageWithCrit not found, using fallback.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- preload animation (from original Starfall.lua)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://136486872917927"

local function createTemporaryHitboxAnchor(character, offsetCFrame, lifetime)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	offsetCFrame = offsetCFrame or CFrame.new()
	lifetime = lifetime or 3

	local anchor = Instance.new("Part")
	anchor.Name = "StarfallHitboxAnchor"
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

-- kung tinatawag sa loob ng function kung saan meron 'character' at 'angle'
local function createSlash(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.Starfall:WaitForChild("Starfall"):Clone()
	vfx.Parent = workspace

	-- Distance mula sa player
	local forwardOffset = 0  

	-- Rotation para sa direksyon palabas
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Rotation para sa itsura lang (ikot ng blade mismo)
	local tiltRotation = CFrame.Angles(0, math.rad(0), 0) -- pwede mo gawing 45

	-- Final spawn position (may tilt sa visual)
	local spawnCF = root.CFrame * outwardRotation * CFrame.new(0, 35, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Ensure lahat ng parts ay hindi naka-anchor pero stable
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Cleanup
	Debris:AddItem(vfx, 0.3)
end

local function createExplosionNear(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage:WaitForChild("Starfall"):WaitForChild("StarfallExplosion"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Position in circle
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset)
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

local function createExplosionFar(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage:WaitForChild("Starfall"):WaitForChild("StarfallExplosion"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 100

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Position in circle
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset)
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

remote.OnServerEvent:Connect(function(player, skillType)
	if skillType ~= "starfall" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Starfall] Skill blocked: Player " .. player.Name .. " tried to use Archer skill with mismatched weapon.")
			return
		end
	end
	
	-- Cooldown check (added system)
	if _G.archerIsSkillOnCooldown(player, "starfall") then
		local remainingTime = _G.archerGetRemainingCooldown(player, "starfall")
		_G.archerSendCooldownStatus(player, "starfall", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown (added system)
	_G.archerSetSkillCooldown(player, "starfall")
	local cooldownTime = _G.ARCHER_COOLDOWNS["starfall"]
	_G.archerSendCooldownStatus(player, "starfall", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.archerSendCooldownStatus(player, "starfall", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "starfall")
	
	-- Enable invincibility (freeze health during ultimate)
	_G.enablePlayerInvincibility(player)
	
	-- Input lock (added system)
	remote:FireClient(player, "lock_input")
	_G.setArcherWalkingSpeed(player, "blocking")
	
	-- Camera sequence (added system)
	remote:FireClient(player, "play_camera_sequence", "starfall")
	
	-- Unlock when done (added system)
	animTrack.Stopped:Connect(function()
		-- Disable invincibility (allow damage again)
		_G.disablePlayerInvincibility(player)
		
		remote:FireClient(player, "unlock_input")
		_G.setArcherWalkingSpeed(player, "normal")
		-- Restore archer aiming system (will respect current aim lock state)
		remote:FireClient(player, "setup_archer_aiming")
	end)
	
	-- AuraStart marker (exact copy from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		local vfx = ReplicatedStorage.Starfall:WaitForChild("StarfallAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
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

		game:GetService("Debris"):AddItem(vfx, 10)
	end)
	
	-- Starfall marker (exact copy from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("Starfall"):Connect(function()
		--local angles = {0, 45, 90, 135, 180, 225, 270, 315}
		local angles = {0}
		for _, a in ipairs(angles) do
			createSlash(character, a)
		end
	end)
	
	-- StarExplosionNear marker (exact copy from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("StarExplosionNear"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			createExplosionNear(character, angle)
		end
	end)
	
	-- StarExplosionFar marker (exact copy from original Starfall.lua + hitbox)
	animTrack:GetMarkerReachedSignal("StarExplosionFar"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			createExplosionFar(character, angle)
		end
		
		-- Calculate DOT damage based on player's MaxAttack stat (ultDamage is now a multiplier)
		local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.ultDamage or 0.1
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Archer", damageMultiplier)
		
		-- Massive center DOT hitbox
		local root = character:WaitForChild("HumanoidRootPart")
		local anchorLifetime = math.max((ServerConfigs.ArcherSkills.Starfall.damageTickTime or 0.5) * 6, 2)
		local hitboxAnchor = createTemporaryHitboxAnchor(character, CFrame.new(), anchorLifetime)
		_G.createStaticDOTHitbox({
			attachTo = hitboxAnchor or root,
			offset = CFrame.new(0, 0, 0),
			size = ServerConfigs.ArcherSkills.Starfall.hitboxSize,
			damage = actualDamage, -- Use calculated damage based on MaxAttack
			damageTickTime = ServerConfigs.ArcherSkills.Starfall.damageTickTime or 0.5,
			duration = anchorLifetime,
			character = character,
			name = "Starfall Center DOT",
			showVisual = false,
			visualColor = Color3.new(1, 0, 0),
			delay = ServerConfigs.ArcherSkills.Starfall.hitboxDelay or 0.2,
			actionType = "starfall",
			classType = "Archer"
		})
	end)

end)
