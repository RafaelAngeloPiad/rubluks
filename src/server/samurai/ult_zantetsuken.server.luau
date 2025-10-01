-- ========================================
-- ZANTETSUKEN ULTIMATE SERVER
-- Raw and procedural implementation
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://133910790786834"

-- kung tinatawag sa loob ng function kung saan meron 'character' at 'angle'
local function createSlash(character, angle)
	local root = character:WaitForChild("HumanoidRootPart")

	local vfx = ReplicatedStorage.WakizashiAura:WaitForChild("Slash"):Clone()
	vfx.Parent = workspace

	-- Distance mula sa player
	local forwardOffset = 5  

	-- Rotation para sa direksyon palabas
	local outwardRotation = CFrame.Angles(0, math.rad(angle), 0)

	-- Rotation para sa itsura lang (ikot ng blade mismo)
	local tiltRotation = CFrame.Angles(0, math.rad(90), 0) -- pwede mo gawing 45

	-- Final spawn position (may tilt sa visual)
	local spawnCF = root.CFrame * outwardRotation * CFrame.new(0, 0, -forwardOffset) * tiltRotation
	vfx:PivotTo(spawnCF)

	-- Ensure lahat ng parts ay hindi naka-anchor pero stable
	for _, part in ipairs(vfx:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Kukunin yung main mesh (blade)
	local bladePart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

	-- Lipad palabas (base lang sa outwardRotation, walang tilt)
	local moveCF = root.CFrame * outwardRotation
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = moveCF.LookVector * 160
	bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bodyVelocity.Parent = bladePart

	-- HITBOX V3: Attach traveling hitbox to blade
	_G.createTravelingHitbox({
		attachTo = bladePart,
		offset = CFrame.new(-30, 0, 0), -- tagilid kasi yung blade so x - up down  y - left / right  z - up down
		size = Vector3.new(8, 30, 8), -- width, height, depth
		damage = 30,
		-- duration removed - will last as long as bladePart exists (2 seconds via Debris)
		delay = 0, -- delay before hitbox appears (in seconds)
		character = character,
		name = "Zantetsuken",
		showVisual = true,
		visualColor = Color3.new(1, 0, 1) -- Purple
	})

	-- Cleanup
	Debris:AddItem(vfx, 2)
	Debris:AddItem(bodyVelocity, 2)


end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle zantetsuken ultimate requests
	if skillType ~= "zantetsuken" then
		return
	end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.Zantetsuken:WaitForChild("AuraTrigger"):Clone()
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

		game:GetService("Debris"):AddItem(vfx, 7.5)
	end)
	
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()

		local vfx = ReplicatedStorage.Zantetsuken:WaitForChild("ZantetsukenAura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = math.rad(0) -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)


		vfx:PivotTo(root.CFrame * CFrame.new(0, -2, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end

		game:GetService("Debris"):AddItem(vfx, 7.5)
	end)

	-- ⚡ DASH marker
	animTrack:GetMarkerReachedSignal("ElectricAura"):Connect(function()

		-- left hand lightning
		local vfxLeft = ReplicatedStorage.WakizashiAura:WaitForChild("lightningLeft"):Clone()
		vfxLeft.Parent = workspace

		local leftHand = character:FindFirstChild("LeftHand") or root
		local offsetLeft = CFrame.new(-3, 0, 0)-- X = left/right, Y = harap/likod, Z = taas/baba

		vfxLeft:PivotTo(leftHand.CFrame * offsetLeft)

		for _, part in ipairs(vfxLeft:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = leftHand
				weld.Part1 = part
				weld.Parent = part
				part.Anchored = false
			end
		end

		-- right hand lightning
		local vfxRight = ReplicatedStorage.WakizashiAura:WaitForChild("lightningRight"):Clone()
		vfxRight.Parent = workspace

		local rightHand = character:FindFirstChild("RightHand") or root
		local offsetRight = CFrame.new(3, 0, 0)-- X = left/right, Y = harap/likod, Z = taas/baba

		vfxRight:PivotTo(rightHand.CFrame * offsetRight)

		for _, part in ipairs(vfxRight:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = rightHand
				weld.Part1 = part
				weld.Parent = part
				part.Anchored = false
			end
		end

		game:GetService("Debris"):AddItem(vfxLeft, 2)
		game:GetService("Debris"):AddItem(vfxRight, 2)

	end)

	-- ⚡ SONIC BLADE marker
	animTrack:GetMarkerReachedSignal("SonicBlade"):Connect(function()
		local angles = {0, 45, 90, 135, 180, 225, 270, 315}
		for _, a in ipairs(angles) do
			createSlash(character, a)
		end
	end)

end)
