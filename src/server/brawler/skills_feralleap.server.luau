-- ========================================
-- FERAL LEAP SKILL SERVER
-- Raw and procedural implementation
-- Based on original Feral Leap.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
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
-- @param damageMultiplier: Damage multiplier (e.g., 0.389 = 38.9% of MaxAttack)
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
			warn("[Brawler FeralLeap] ServerConfigs.calculateDamageWithCrit not found, using fallback. Please reload ServerConfigs module.")
			return math.floor(damageMultiplier * maxAttack), false
		end
	end
end

-- Track feral leap connections for each player
local feralLeapConnections = {}

-- preload animations
local leapAnim = Instance.new("Animation")
leapAnim.AnimationId = "rbxassetid://76859592290622"

local leapAttackAnim = Instance.new("Animation")
leapAttackAnim.AnimationId = "rbxassetid://98157070007403"

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle feralleap skill requests
	if skillType ~= "feralleap" then
		return
	end
	
	-- Check if weapon matches player class (prevent skill usage for mismatched weapons)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[FeralLeap] Skill blocked: Player " .. player.Name .. " tried to use Brawler skill with mismatched weapon.")
			return
		end
	end
	
	-- Safety check: Ensure player has character and is ready
	local character = player.Character
	if not character then
		warn("Feral Leap: Player has no character")
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		warn("Feral Leap: Player has no humanoid")
		return
	end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		warn("Feral Leap: Player has no HumanoidRootPart")
		return
	end
	
	-- Check if player is already in a feral leap
	if feralLeapConnections[player.UserId] then
		warn("Feral Leap: Player is already in a feral leap")
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "feralleap") then
		local remainingTime = _G.getRemainingCooldown(player, "feralleap")
		_G.sendCooldownStatus(player, "feralleap", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "feralleap")
	local cooldownTime = _G.BRAWLER_COOLDOWNS["feralleap"]
	_G.sendCooldownStatus(player, "feralleap", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "feralleap", false, 0)
	end)
	
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(leapAnim)
	local animTrack2 = animator:LoadAnimation(leapAttackAnim)
	
	animTrack:Play()
	_G.applyBrawlerAnimationSpeed(animTrack, "feralleap")
	
	-- Tell client to start leap control
	remote:FireClient(player, "feralleap_start")
	
	-- Store the connection for this player
	local stoppedConnection = animTrack.Stopped:Connect(function()
		-- Only proceed if this is a natural stop (not client-triggered)
		if not feralLeapConnections[player.UserId] or not feralLeapConnections[player.UserId].wasStoppedEarly then
			-- Stop first anim and play second
			animTrack:Stop()
			animTrack2:Play()
			_G.applyBrawlerAnimationSpeed(animTrack2, "feralleap")
			
			-- Tell client to stop leap control
			remote:FireClient(player, "feralleap_stop")
			
			-- Trigger VFX at "ClawMark"
			animTrack2:GetMarkerReachedSignal("ClawMark"):Once(function()
				local vfx = ReplicatedStorage.FeralLeap:WaitForChild("FeralLeap"):Clone()
				vfx.Parent = workspace
				vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -25))

				for _, part in ipairs(vfx:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
					end
				end

				Debris:AddItem(vfx, 1)
				
				-- Hitbox for claw mark
				-- Calculate actual damage from multiplier (damage is now a multiplier)
				local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill2Damage or ServerConfigs.BrawlerSkills.FeralLeap.hitboxDamage
				local actualDamage, isCrit = calculateDamageForHitbox(player, "Brawler", damageMultiplier)
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 1, 0),
					size = ServerConfigs.BrawlerSkills.FeralLeap.hitboxSize,
					damage = actualDamage,
					character = character,
					name = "FeralLeapClaw",
					showVisual = true,
					visualColor = Color3.new(1, 0, 0),
					delay = ServerConfigs.BrawlerSkills.FeralLeap.hitboxDelay
				})
			end)
		end
		
		-- Clean up connection
		if feralLeapConnections[player.UserId] then
			feralLeapConnections[player.UserId] = nil
		end
	end)
	
	-- Store connection info
	feralLeapConnections[player.UserId] = {
		connection = stoppedConnection,
		wasStoppedEarly = false
	}
	
end)

-- Listen for client stop signal
remote.OnServerEvent:Connect(function(player, actionName)
	if actionName == "feralleap_client_stop" then
		-- Client requested to stop leap early
		local character = player.Character
		if not character then return end
		local animator = character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
		if not animator then return end
		
		-- Mark as stopped early BEFORE stopping the animation
		if feralLeapConnections[player.UserId] then
			feralLeapConnections[player.UserId].wasStoppedEarly = true
		end
		
		-- Find and stop the leap animation
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			if track.Animation.AnimationId == leapAnim.AnimationId then
				track:Stop()
			end
		end
		
		-- Play attack animation when stopped early (same as natural stop)
		local animTrack2 = animator:LoadAnimation(leapAttackAnim)
		animTrack2:Play()
		_G.applyBrawlerAnimationSpeed(animTrack2, "feralleap")
		
		-- Get root part for VFX and hitbox
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		-- Trigger VFX at "ClawMark" (same as natural stop)
		animTrack2:GetMarkerReachedSignal("ClawMark"):Once(function()
			local vfx = ReplicatedStorage.FeralLeap:WaitForChild("FeralLeap"):Clone()
			vfx.Parent = workspace
			vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -25))

			for _, part in ipairs(vfx:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
				end
			end

			Debris:AddItem(vfx, 1)
			
			-- Hitbox for claw mark
			-- Calculate actual damage from multiplier (damage is now a multiplier)
			local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill2Damage or ServerConfigs.BrawlerSkills.FeralLeap.hitboxDamage
			local actualDamage = calculateDamageForHitbox(player, "Brawler", damageMultiplier)
			_G.createStaticHitbox({
				attachTo = root,
				offset = CFrame.new(0, 1, 0),
				size = ServerConfigs.BrawlerSkills.FeralLeap.hitboxSize,
				damage = actualDamage,
				character = character,
				name = "FeralLeapClaw",
				showVisual = true,
				visualColor = Color3.new(1, 0, 0),
				delay = ServerConfigs.BrawlerSkills.FeralLeap.hitboxDelay
			})
		end)
		
		-- Tell client to stop leap control immediately
		remote:FireClient(player, "feralleap_stop")
	end
end)
