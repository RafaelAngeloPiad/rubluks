-- ========================================
-- BERSERKER'S ROAR SKILL SERVER
-- Raw and procedural implementation
-- Based on original Berserker's Roar.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

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
-- @param damageMultiplier: Damage multiplier (e.g., 0.222 = 22.2% of MaxAttack)
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
			warn("[Brawler BrawlersRoar] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://132356955410856"

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle brawlersroar skill requests
	if skillType ~= "brawlersroar" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[BrawlersRoar] Skill blocked: Player " .. player.Name .. " tried to use Brawler skill with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "brawlersroar") then
		local remainingTime = _G.getRemainingCooldown(player, "brawlersroar")
		_G.sendCooldownStatus(player, "brawlersroar", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "brawlersroar")
	local cooldownTime = _G.BRAWLER_COOLDOWNS["brawlersroar"]
	_G.sendCooldownStatus(player, "brawlersroar", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "brawlersroar", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applyBrawlerAnimationSpeed(animTrack, "brawlersroar")
	
	-- Lock input only when skill starts
	remote:FireClient(player, "lock_input")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
	end)

	-- Roar marker (from original Berserker's Roar.lua)
	animTrack:GetMarkerReachedSignal("Roar"):Connect(function()

		local vfx = ReplicatedStorage.BerserkerRoar:WaitForChild("Roar"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, 10, -20)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 2.5)
		
		-- Hitbox for roar
		-- Calculate actual damage from multiplier (damage is now a multiplier)
		local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill1Damage or ServerConfigs.BrawlerSkills.BrawlersRoar.hitboxDamage
		local actualDamage, isCrit = calculateDamageForHitbox(player, "Brawler", damageMultiplier)
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 10, -20),
			size = ServerConfigs.BrawlerSkills.BrawlersRoar.hitboxSize,
			damage = actualDamage,
			character = character,
			name = "BrawlersRoar",
			showVisual = true,
			visualColor = Color3.new(1, 0.3, 0),
			delay = ServerConfigs.BrawlerSkills.BrawlersRoar.hitboxDelay
		})
	end)

end)
