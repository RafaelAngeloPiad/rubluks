-- ========================================
-- BANZAI BUFF SERVER
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
-- @param damageMultiplier: Damage multiplier (e.g., 0.1 = 10% of MaxAttack)
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
			warn("[Banzai] ServerConfigs.calculateDamageWithCrit not found, using fallback.")
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
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://115710510666189"

remote.OnServerEvent:Connect(function(player, skillType)
	
	-- Only handle banzai buff requests
	if skillType ~= "banzai" then
		return
	end
	
	-- Prevent buff usage if weapon does not match player's class (respect allowSkills flag)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Banzai] Buff blocked: Player " .. player.Name .. " tried to use Samurai buff with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.samuraiIsSkillOnCooldown(player, "banzai") then
		local remainingTime = _G.samuraiGetRemainingCooldown(player, "banzai")
		_G.samuraiSendCooldownStatus(player, "banzai", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.samuraiSetSkillCooldown(player, "banzai")
	local cooldownTime = _G.SAMURAI_COOLDOWNS["banzai"]
	_G.samuraiSendCooldownStatus(player, "banzai", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.samuraiSendCooldownStatus(player, "banzai", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack, "banzai")
	
	-- Lock input when buff starts
	remote:FireClient(player, "lock_input")
	_G.setSamuraiWalkingSpeed(player, "blocking") -- Stop movement during buff
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal movement
	end)

	-- ⚡ AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		
		local vfx = ReplicatedStorage.Banzai:WaitForChild("Aura"):Clone()
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

		Debris:AddItem(vfx, 1.5)
		
		-- Apply Banzai buff (provides immunity to damage)
		if _G.applyBuff then
			_G.applyBuff(player, "Banzai")
		end
		
		-- Create static hitbox with small damage (upon usage)
		local leaderstats = player:FindFirstChild("leaderstats")
		local level = leaderstats and leaderstats:FindFirstChild("Level")
		if level and ServerConfigs then
			local buffConfig = ServerConfigs.getBuffConfig("Banzai", level.Value)
			if buffConfig and buffConfig.damageMultiplier then
				-- Calculate damage based on player's MaxAttack
				local actualDamage, isCrit = calculateDamageForHitbox(player, buffConfig.damageMultiplier)
				
				-- Play attack sound
				playAttackSound(player, "banzai")
				
				-- Create static hitbox around player (small AoE damage)
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 0, 0),
					size = Vector3.new(15, 15, 15), -- Small hitbox around player
					damage = actualDamage,
					character = character,
					name = "Banzai",
					showVisual = false,
					visualColor = Color3.new(1, 0.5, 0), -- Orange for Banzai
					delay = 0,
					actionType = "banzai",
					classType = "Samurai"
				})
			end
		end
	end)

end)
