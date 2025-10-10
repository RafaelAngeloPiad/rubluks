-- ========================================
-- BERSERKER'S ROAR SKILL SERVER
-- Raw and procedural implementation
-- Based on original Berserker's Roar.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://132356955410856"

-- BERSERKER'S ROAR HITBOX CONFIG
local BRAWLERSROAR_CONFIG = {
	hitboxSize = Vector3.new(25, 25, 25), -- Hitbox size for roar
	hitboxDamage = 20, -- Damage per hit
	hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
}

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle brawlersroar skill requests
	if skillType ~= "brawlersroar" then
		return
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
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, 10, -20),
			size = BRAWLERSROAR_CONFIG.hitboxSize,
			damage = BRAWLERSROAR_CONFIG.hitboxDamage,
			character = character,
			name = "BrawlersRoar",
			showVisual = true,
			visualColor = Color3.new(1, 0.3, 0),
			delay = BRAWLERSROAR_CONFIG.hitboxDelay
		})
	end)

end)
