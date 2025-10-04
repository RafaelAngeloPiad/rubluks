-- ========================================
-- STARFALL ULTIMATE SERVER
-- Raw and procedural implementation
-- Based on original Starfall.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation (from original Starfall.lua)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://136486872917927"

-- kung tinatawag sa loob ng function kung saan meron 'character' at 'angle'
local function createSlash(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.Starfall:WaitForChild("Starfall"):Clone()
	vfx.Parent = workspace

	-- Distance mula sa player
	local forwardOffset = 0  

	-- Rotation para sa direksyon palabas
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Rotation para sa itsura lang (ikot ng blade mismo)
	local tiltRotation = CFrame.Angles(0, math.rad(0), 0) -- pwede mo gawing 45

	-- Final spawn position (may tilt sa visual)
	local spawnCF = root.CFrame * outwardRotation * CFrame.new(0, 35, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Ensure lahat ng parts ay hindi naka-anchor pero stable
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Cleanup
	Debris:AddItem(vfx, 0.3)
end

local function createExplosionNear(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage:WaitForChild("Starfall"):WaitForChild("StarfallExplosion"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 50

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Position in circle
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset)
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Attach static hitbox to explosion position
	_G.createStaticHitbox({
		cframe = spawnCF,
		size = Vector3.new(15, 15, 15), -- Large explosion radius
		damage = 25,
		character = character,
		name = "Starfall Explosion Near",
		showVisual = true,
		visualColor = Color3.new(1, 0.5, 0), -- Orange
		delay = 0.1, -- Slight delay before hitbox appears
	})
	
	-- Attach static hitbox to player center
	_G.createStaticHitbox({
		cframe = root.CFrame,
		size = Vector3.new(15, 15, 15), -- Same size as explosion
		damage = 25,
		character = character,
		name = "Starfall Center Near",
		showVisual = true,
		visualColor = Color3.new(0, 1, 0), -- Green for center hitbox
		delay = 0.1, -- Slight delay before hitbox appears
	})

	Debris:AddItem(vfx, 1.2)
end

local function createExplosionFar(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage:WaitForChild("Starfall"):WaitForChild("StarfallExplosion"):Clone()
	vfx.Parent = workspace

	local forwardOffset = 100

	-- Rotation based on global Y axis (not root.CFrame orientation)
	local baseCF = CFrame.new(root.Position)
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Position in circle
	local spawnCF = baseCF * outwardRotation * CFrame.new(0, 0, -forwardOffset)
	vfx:PivotTo(spawnCF)

	-- Lock parts
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Attach static hitbox to explosion position
	_G.createStaticHitbox({
		cframe = spawnCF,
		size = Vector3.new(20, 20, 20), -- Larger explosion radius for far explosions
		damage = 30,
		character = character,
		name = "Starfall Explosion Far",
		showVisual = true,
		visualColor = Color3.new(1, 0.3, 0), -- Darker orange for far explosions
		delay = 0.1, -- Slight delay before hitbox appears
	})
	
	-- Attach static hitbox to player center
	_G.createStaticHitbox({
		cframe = root.CFrame,
		size = Vector3.new(20, 20, 20), -- Same size as explosion
		damage = 30,
		character = character,
		name = "Starfall Center Far",
		showVisual = true,
		visualColor = Color3.new(0, 0.5, 1), -- Blue for center hitbox
		delay = 0.1, -- Slight delay before hitbox appears
	})

	Debris:AddItem(vfx, 1.2)
end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle starfall ultimate requests
	if skillType ~= "starfall" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "starfall") then
		local remainingTime = _G.getRemainingCooldown(player, "starfall")
		_G.sendCooldownStatus(player, "starfall", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "starfall")
	local cooldownTime = _G.ARCHER_COOLDOWNS["starfall"]
	_G.sendCooldownStatus(player, "starfall", true, cooldownTime)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "starfall")
	
	-- Lock input when ultimate starts
	remote:FireClient(player, "lock_input")
	_G.setArcherWalkingSpeed(player, "blocking") -- Stop movement during ultimate
	
	-- Trigger camera sequence for starfall ultimate
	remote:FireClient(player, "play_camera_sequence", "starfall")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal movement
	end)
	
	-- AuraStart marker (from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		local vfx = ReplicatedStorage.Starfall:WaitForChild("StarfallAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
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

		game:GetService("Debris"):AddItem(vfx, 10)
	end)
	
	-- Starfall marker (from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("Starfall"):Connect(function()
		--local angles = {0, 45, 90, 135, 180, 225, 270, 315}
		local angles = {0}
		for _, a in ipairs(angles) do
			createSlash(character, a)
		end
	end)
	
	-- StarExplosionNear marker (from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("StarExplosionNear"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			createExplosionNear(character, angle)
		end
	end)
	
	-- StarExplosionFar marker (from original Starfall.lua)
	animTrack:GetMarkerReachedSignal("StarExplosionFar"):Connect(function()
		for angle = 0, 315, 45 do -- 8 directions
			createExplosionFar(character, angle)
		end
		
		-- Create massive center hitbox to cover all blind spots
		local root = character:WaitForChild("HumanoidRootPart")
		_G.createStaticHitbox({
			cframe = root.CFrame,
			size = Vector3.new(200, 50, 200), -- Massive hitbox covering entire area
			damage = 40, -- High damage for center area
			character = character,
			name = "Starfall Center Massive",
			showVisual = true,
			visualColor = Color3.new(1, 0, 0), -- Red for center area
			delay = 0.2 -- Slight delay after explosions
		})
	end)

end)
