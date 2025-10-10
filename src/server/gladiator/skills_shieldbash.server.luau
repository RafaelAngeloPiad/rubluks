-- ========================================
-- SHIELD BASH SKILL SERVER
-- Raw and procedural implementation
-- Based on original Shield Bash.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://124154885589921"

-- SHIELD BASH HITBOX CONFIG
local SHIELDBASH_CONFIG = {
	hitboxSize = Vector3.new(15, 15, 15), -- Hitbox size
	hitboxDamage = 25, -- Damage per hit
	hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
}

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle shieldbash skill requests
	if skillType ~= "shieldbash" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "shieldbash") then
		local remainingTime = _G.getRemainingCooldown(player, "shieldbash")
		_G.sendCooldownStatus(player, "shieldbash", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "shieldbash")
	local cooldownTime = _G.GLADIATOR_COOLDOWNS["shieldbash"]
	_G.sendCooldownStatus(player, "shieldbash", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "shieldbash", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyGladiatorAnimationSpeed(animTrack, "shieldbash")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setGladiatorWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
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
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, -10),
			size = SHIELDBASH_CONFIG.hitboxSize,
			damage = SHIELDBASH_CONFIG.hitboxDamage,
			character = character,
			name = "ShieldBash",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0),
			delay = SHIELDBASH_CONFIG.hitboxDelay
		})

	end)
	
end)
