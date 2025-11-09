-- ========================================
-- SHIELD BASH SKILL SERVER
-- Raw and procedural implementation
-- Based on original Shield Bash.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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
-- @param damageMultiplier: Damage multiplier (e.g., 0.833 = 83.3% of MaxAttack)
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
			warn("[Gladiator ShieldBash] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://124154885589921"

-- SHIELD BASH HITBOX CONFIG (using centralized config)
local SHIELDBASH_CONFIG = ServerConfigs.GladiatorSkills.ShieldBash

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle shieldbash skill requests
	if skillType ~= "shieldbash" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[ShieldBash] Skill blocked: Player " .. player.Name .. " tried to use Gladiator skill with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.gladiatorIsSkillOnCooldown(player, "shieldbash") then
		local remainingTime = _G.gladiatorGetRemainingCooldown(player, "shieldbash")
		_G.gladiatorSendCooldownStatus(player, "shieldbash", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.gladiatorSetSkillCooldown(player, "shieldbash")
	local cooldownTime = _G.GLADIATOR_COOLDOWNS["shieldbash"]
	_G.gladiatorSendCooldownStatus(player, "shieldbash", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.gladiatorSendCooldownStatus(player, "shieldbash", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyGladiatorAnimationSpeed(animTrack, "shieldbash")
	
	-- Enable invincibility (freeze health during skill)
	_G.enablePlayerInvincibility(player)
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setGladiatorWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		-- Disable invincibility (allow damage again)
		_G.disablePlayerInvincibility(player)
		
		remote:FireClient(player, "unlock_movement")
		_G.setGladiatorWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- Shield Bash marker (from original Shield Bash.lua)
	animTrack:GetMarkerReachedSignal("ShieldBash"):Connect(function()

		local vfx = ReplicatedStorage.ShieldBash:WaitForChild("ShieldBash"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 5, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1)
		
		-- Hitbox for Shield Bash
		local damageMultiplier = SHIELDBASH_CONFIG.hitboxDamage
		local actualDamage, isCrit = calculateDamageForHitbox(player, damageMultiplier)
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, -10),
			size = SHIELDBASH_CONFIG.hitboxSize,
			damage = actualDamage,
			character = character,
			name = "ShieldBash",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0),
			delay = SHIELDBASH_CONFIG.hitboxDelay,
			actionType = "shieldbash",
			classType = "Gladiator"
		})

	end)
	
end)
