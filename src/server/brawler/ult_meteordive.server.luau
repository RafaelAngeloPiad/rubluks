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

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://95054632322392"

-- METEOR DIVE HITBOX CONFIG
local METEORDIVE_CONFIG = {
	explosionHitboxSize = Vector3.new(40, 40, 40), -- Hitbox size for meteor explosion
	explosionHitboxDamage = 50, -- Damage on meteor impact
	hitboxDelay = 0.2, -- Delay before hitbox activates (in seconds)
}

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle meteordive ultimate requests
	if skillType ~= "meteordive" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "meteordive") then
		local remainingTime = _G.getRemainingCooldown(player, "meteordive")
		_G.sendCooldownStatus(player, "meteordive", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "meteordive")
	local cooldownTime = _G.BRAWLER_COOLDOWNS["meteordive"]
	_G.sendCooldownStatus(player, "meteordive", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "meteordive", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyBrawlerAnimationSpeed(animTrack, "meteordive")
	
	-- Lock input for the ultimate
	remote:FireClient(player, "lock_input")
	
	-- Tell client to play camera sequence
	remote:FireClient(player, "play_camera_sequence", "meteordive")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
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
		_G.createStaticDOTHitbox({
			attachTo = root,
			offset = CFrame.new(0, -1, 0),
			size = Vector3.new(250, 60, 250), -- Massive center hitbox
			damage = 8, -- Damage per tick
			damageTickTime = 0.5, -- Damage every 0.5 seconds
			character = character,
			name = "MeteorDive Center DOT",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0), -- Orange color
			delay = METEORDIVE_CONFIG.hitboxDelay
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
