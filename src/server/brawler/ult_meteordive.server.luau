-- ========================================
-- METEOR DIVE ULTIMATE SERVER
-- Raw and procedural implementation
-- Based on original Meteor Dive.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

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
-- @param classType: Class name (e.g., "Brawler")
-- @param damageMultiplier: Damage multiplier (e.g., 0.089 = 8.9% of MaxAttack)
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
			warn("[Brawler MeteorDive] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://95054632322392"

local function createTemporaryHitboxAnchor(character, offsetCFrame, lifetime)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	offsetCFrame = offsetCFrame or CFrame.new()
	lifetime = lifetime or 4

	local anchor = Instance.new("Part")
	anchor.Name = "MeteorDiveHitboxAnchor"
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

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle meteordive ultimate requests
	if skillType ~= "meteordive" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[MeteorDive] Skill blocked: Player " .. player.Name .. " tried to use Brawler skill with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.brawlerIsSkillOnCooldown(player, "meteordive") then
		local remainingTime = _G.brawlerGetRemainingCooldown(player, "meteordive")
		_G.brawlerSendCooldownStatus(player, "meteordive", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.brawlerSetSkillCooldown(player, "meteordive")
	local cooldownTime = _G.BRAWLER_COOLDOWNS["meteordive"]
	_G.brawlerSendCooldownStatus(player, "meteordive", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.brawlerSendCooldownStatus(player, "meteordive", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyBrawlerAnimationSpeed(animTrack, "meteordive")
	
	-- Enable invincibility (freeze health during ultimate)
	_G.enablePlayerInvincibility(player)
	
	-- Lock movement and stop player during ultimate
	remote:FireClient(player, "lock_movement")
	_G.setBrawlerWalkingSpeed(player, "blocking") -- Stop movement completely
	
	-- Tell client to play camera sequence
	remote:FireClient(player, "play_camera_sequence", "meteordive")
	
	-- Unlock movement and restore walk speed when animation ends
	animTrack.Stopped:Connect(function()
		-- Disable invincibility (allow damage again)
		_G.disablePlayerInvincibility(player)
		
		remote:FireClient(player, "unlock_movement")
		_G.setBrawlerWalkingSpeed(player, "normal") -- Restore normal movement
	end)

	-- Meteor Explosion marker
	animTrack:GetMarkerReachedSignal("MeteorExplosion"):Connect(function()

		local vfx = ReplicatedStorage.MeteorDive:WaitForChild("MeteorExplosion"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -1, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 4)
		
		-- MASSIVE CENTER DOT HITBOX for MeteorDive
		-- Calculate actual damage from multiplier (damage is now a multiplier)
		local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.ultDamage or ServerConfigs.BrawlerSkills.MeteorDive.hitboxDamage
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Brawler", damageMultiplier)
		local hitboxDuration = 4
		local hitboxAnchor = createTemporaryHitboxAnchor(character, CFrame.new(0, -1, 0), hitboxDuration)
		_G.createStaticDOTHitbox({
			attachTo = hitboxAnchor or root,
			offset = CFrame.new(0, -1, 0),
			size = ServerConfigs.BrawlerSkills.MeteorDive.hitboxSize,
			damage = actualDamage, -- Damage per tick (calculated from multiplier)
			damageTickTime = ServerConfigs.BrawlerSkills.MeteorDive.damageTickTime or ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.ultTickTime,
			duration = hitboxDuration, -- Duration in seconds (matches VFX cleanup time)
			character = character,
			name = "MeteorDive Center DOT",
			showVisual = false,
			visualColor = Color3.new(1, 0.5, 0), -- Orange color
			delay = ServerConfigs.BrawlerSkills.MeteorDive.hitboxDelay,
			actionType = "meteordive",
			classType = "Brawler"
		})
	end)
	
	-- Meteor Drop marker (welded meteor that follows player)
	animTrack:GetMarkerReachedSignal("MeteorDrop"):Connect(function()

		local torso = character:WaitForChild("UpperTorso")

		-- Clone VFX
		local vfx = ReplicatedStorage.MeteorDive:WaitForChild("MeteorDrop"):Clone()
		vfx.Parent = workspace

		-- Position the VFX first (below the torso)
		vfx:PivotTo(torso.CFrame * CFrame.new(0, 0, 0)* CFrame.Angles(math.rad(180), 0, 0))

		-- Unanchor everything para gumalaw
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end
		
		local mainPart = vfx
		if mainPart then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, -150, 0) -- mas malaki = mas mabilis bagsak
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.Parent = mainPart
		end

		-- No welding needed - meteor falls independently

		game:GetService("Debris"):AddItem(vfx, 1)
	end)

end)
