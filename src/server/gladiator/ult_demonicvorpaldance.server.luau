-- ========================================
-- DEMONIC VORPAL DANCE ULTIMATE SERVER
-- Raw and procedural implementation
-- Based on original Demonic Vorpal Dance.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://117441445922611"

-- DEMONIC VORPAL DANCE HITBOX CONFIG
local DEMONICVORPAL_CONFIG = {
	nearHitboxSize = Vector3.new(35, 35, 35), -- Hitbox size for near explosions (wider to cover center)
	farHitboxSize = Vector3.new(40, 40, 40), -- Hitbox size for far explosions (wider to cover center)
	nearHitboxDamage = 20, -- Damage per near explosion
	farHitboxDamage = 25, -- Damage per far explosion
	hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
}

-- Helper function: Enter Arena (spawns demonic shields in a circle)
local function enterArena(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.DemonicVorpalDance:WaitForChild("DemonicShield"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 10, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 10)
end

-- Helper function: Explosion Near
local function explosionNear(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.DemonicVorpalDance:WaitForChild("VorpalDanceImpact"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 20

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), 0, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, -3, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1)
	
end

-- Helper function: Explosion Far
local function explosionFar(character, angle, tilt)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.DemonicVorpalDance:WaitForChild("VorpalDanceImpact"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 35

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Tilt (nakatusok pababa/forward)
	local tiltRotation = CFrame.Angles(math.rad(0), -3, 0) -- adjust mo kung gano ka-tusok

	-- Position in circle + tilt
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, -3, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	Debris:AddItem(vfx, 1)
	
end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle demonicvorpaldance ultimate requests
	if skillType ~= "demonicvorpaldance" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "demonicvorpaldance") then
		local remainingTime = _G.getRemainingCooldown(player, "demonicvorpaldance")
		_G.sendCooldownStatus(player, "demonicvorpaldance", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "demonicvorpaldance")
	local cooldownTime = _G.GLADIATOR_COOLDOWNS["demonicvorpaldance"]
	_G.sendCooldownStatus(player, "demonicvorpaldance", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "demonicvorpaldance", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyGladiatorAnimationSpeed(animTrack, "demonicvorpaldance")
	
	-- Lock input for the ultimate
	remote:FireClient(player, "lock_input")
	
	-- Tell client to play camera sequence
	remote:FireClient(player, "play_camera_sequence", "demonicvorpaldance")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
	end)

	-- Aura Start marker
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.MightyBlade:WaitForChild("Aura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -3, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 10)
	end)

	-- Arena marker (spawns 16 demonic shields in a circle)
	animTrack:GetMarkerReachedSignal("Arena"):Connect(function()
		for angle = 0, 337.5, 22.5 do -- 16 directions (360 / 16 = 22.5)
			enterArena(character, angle, math.rad(0))
		end
	end)

	-- Explosion marker (creates explosions in 8 directions, both near and far)
	animTrack:GetMarkerReachedSignal("Explosion"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			explosionNear(character, angle,  math.rad(0))
			explosionFar(character, angle,  math.rad(0))
		end
		
		-- MASSIVE CENTER DOT HITBOX for DemonicVorpalDance
		local root = character:WaitForChild("HumanoidRootPart")
		_G.createStaticDOTHitbox({
			attachTo = root,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(250, 60, 250), -- Massive center hitbox
			damage = 5, -- Damage per tick
			damageTickTime = 0.5, -- Damage every 0.5 seconds
			character = character,
			name = "DemonicVorpalDance Center DOT",
			showVisual = true,
			visualColor = Color3.new(1, 0, 0.5), -- Pink/red color
			delay = 0.2
		})
	end)

end)
