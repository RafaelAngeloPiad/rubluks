-- ========================================
-- DRAGOON JUMP SKILL SERVER
-- Raw and procedural implementation
-- Based on original Dragoon Jump.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://102537581819156"

-- DRAGOON JUMP HITBOX CONFIG
local DRAGOONJUMP_CONFIG = {
	hitboxSize = Vector3.new(20, 20, 20), -- Hitbox size for each explosion
	hitboxDamage = 15, -- Damage per explosion hit
	hitboxDelay = 1, -- Delay before hitbox activates (in seconds) - synced with explosion VFX
}

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle dragoonjump skill requests
	if skillType ~= "dragoonjump" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "dragoonjump") then
		local remainingTime = _G.getRemainingCooldown(player, "dragoonjump")
		_G.sendCooldownStatus(player, "dragoonjump", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "dragoonjump")
	local cooldownTime = _G.GLADIATOR_COOLDOWNS["dragoonjump"]
	_G.sendCooldownStatus(player, "dragoonjump", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "dragoonjump", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyGladiatorAnimationSpeed(animTrack, "dragoonjump")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setGladiatorWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setGladiatorWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- 1st explosion
	animTrack:GetMarkerReachedSignal("Explosion1"):Connect(function()

		local vfx = ReplicatedStorage.Jump:WaitForChild("JumpImpact"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 20 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1.5)
		
		-- Hitbox for explosion 1
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -3, -20),
			size = DRAGOONJUMP_CONFIG.hitboxSize,
			damage = DRAGOONJUMP_CONFIG.hitboxDamage,
			character = character,
			name = "DragoonJump1",
			showVisual = true,
			visualColor = Color3.new(0, 1, 1),
			delay = DRAGOONJUMP_CONFIG.hitboxDelay
		})

	end)
	
	-- 2nd explosion
	animTrack:GetMarkerReachedSignal("Explosion2"):Connect(function()

		local vfx = ReplicatedStorage.Jump:WaitForChild("JumpImpact"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 40 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1.5)
		
		-- Hitbox for explosion 2
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -3, -40),
			size = DRAGOONJUMP_CONFIG.hitboxSize,
			damage = DRAGOONJUMP_CONFIG.hitboxDamage,
			character = character,
			name = "DragoonJump2",
			showVisual = true,
			visualColor = Color3.new(0, 1, 1),
			delay = DRAGOONJUMP_CONFIG.hitboxDelay
		})

	end)
	
	-- 3rd explosion
	animTrack:GetMarkerReachedSignal("Explosion3"):Connect(function()

		local vfx = ReplicatedStorage.Jump:WaitForChild("JumpImpact"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 60-- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1.5)
		
		-- Hitbox for explosion 3
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -3, -60),
			size = DRAGOONJUMP_CONFIG.hitboxSize,
			damage = DRAGOONJUMP_CONFIG.hitboxDamage,
			character = character,
			name = "DragoonJump3",
			showVisual = true,
			visualColor = Color3.new(0, 1, 1),
			delay = DRAGOONJUMP_CONFIG.hitboxDelay
		})

	end)
	
	-- 4th explosion
	animTrack:GetMarkerReachedSignal("Explosion4"):Connect(function()

		local vfx = ReplicatedStorage.Jump:WaitForChild("JumpImpact"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 80 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1.5)
		
		-- Hitbox for explosion 4
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -3, -80),
			size = DRAGOONJUMP_CONFIG.hitboxSize,
			damage = DRAGOONJUMP_CONFIG.hitboxDamage,
			character = character,
			name = "DragoonJump4",
			showVisual = true,
			visualColor = Color3.new(0, 1, 1),
			delay = DRAGOONJUMP_CONFIG.hitboxDelay
		})

	end)
	
	-- 5th explosion
	animTrack:GetMarkerReachedSignal("Explosion5"):Connect(function()

		local vfx = ReplicatedStorage.Jump:WaitForChild("JumpImpact"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 100 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, -forwardOffset)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 1.5)
		
		-- Hitbox for explosion 5
		_G.createStaticHitbox({
			attachTo = root,
			offset = CFrame.new(0, -3, -100),
			size = DRAGOONJUMP_CONFIG.hitboxSize,
			damage = DRAGOONJUMP_CONFIG.hitboxDamage,
			character = character,
			name = "DragoonJump5",
			showVisual = true,
			visualColor = Color3.new(0, 1, 1),
			delay = DRAGOONJUMP_CONFIG.hitboxDelay
		})

	end)

end)
