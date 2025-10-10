-- ========================================
-- SWORD DANCE SKILL SERVER
-- Raw and procedural implementation
-- Based on original SwordDance.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload anim (server handles)
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://96753545500324"

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle sworddance skill requests
	if skillType ~= "sworddance" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "sworddance") then
		local remainingTime = _G.getRemainingCooldown(player, "sworddance")
		_G.sendCooldownStatus(player, "sworddance", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "sworddance")
	local cooldownTime = _G.KNIGHT_COOLDOWNS["sworddance"]
	_G.sendCooldownStatus(player, "sworddance", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "sworddance", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyKnightAnimationSpeed(animTrack, "sworddance")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setKnightWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setKnightWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- ? AURA marker (from original SwordDance.lua)
	animTrack:GetMarkerReachedSignal("Aura"):Connect(function()

		local vfx = ReplicatedStorage.SwordDance:WaitForChild("Aura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		local forwardOffset = 0 -- gaano kalayo sa harap magsimula
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
		game:GetService("Debris"):AddItem(vfx, 2.5)

	end)
	
	local currentSwordVFX1 -- para magamit sa parehong markers
	local currentSwordVFX2 -- para magamit sa parehong markers
	local currentSwordVFX3 -- para magamit sa parehong markers
	local currentSwordVFX4 -- para magamit sa parehong markers

	animTrack:GetMarkerReachedSignal("Sword1"):Connect(function()
		-- clone sword
		currentSwordVFX1 = ReplicatedStorage.SwordDance:WaitForChild("GoldSword"):Clone()
		currentSwordVFX1.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position (paangat at harap)
		local forwardOffset = -20
		local rotation = CFrame.Angles(math.rad(90), math.rad(100), 0)
		currentSwordVFX1:PivotTo(root.CFrame * CFrame.new(5, 10, -forwardOffset) * rotation)

		-- Anchor lahat muna habang naka-summon
		for _, part in ipairs(currentSwordVFX1:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Cleanup after ilang segundo (just in case)
		game:GetService("Debris"):AddItem(currentSwordVFX1, 1.5)
	end)
	
	animTrack:GetMarkerReachedSignal("Sword2"):Connect(function()
		-- clone sword
		currentSwordVFX2 = ReplicatedStorage.SwordDance:WaitForChild("GoldSword"):Clone()
		currentSwordVFX2.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position (paangat at harap)
		local forwardOffset = -20
		local rotation = CFrame.Angles(math.rad(90), math.rad(100), 0)
		currentSwordVFX2:PivotTo(root.CFrame * CFrame.new(10, 5, -forwardOffset) * rotation)

		-- Anchor lahat muna habang naka-summon
		for _, part in ipairs(currentSwordVFX2:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Cleanup after ilang segundo (just in case)
		game:GetService("Debris"):AddItem(currentSwordVFX2, 1.5)
	end)
	
	animTrack:GetMarkerReachedSignal("Sword3"):Connect(function()
		-- clone sword
		currentSwordVFX3 = ReplicatedStorage.SwordDance:WaitForChild("GoldSword"):Clone()
		currentSwordVFX3.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position (paangat at harap)
		local forwardOffset = -20
		local rotation = CFrame.Angles(math.rad(90), math.rad(100), 0)
		currentSwordVFX3:PivotTo(root.CFrame * CFrame.new(-10, 5, -forwardOffset) * rotation)

		-- Anchor lahat muna habang naka-summon
		for _, part in ipairs(currentSwordVFX3:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Cleanup after ilang segundo (just in case)
		game:GetService("Debris"):AddItem(currentSwordVFX3, 1.5)
	end)
	
	animTrack:GetMarkerReachedSignal("Sword4"):Connect(function()
		-- clone sword
		currentSwordVFX4 = ReplicatedStorage.SwordDance:WaitForChild("GoldSword"):Clone()
		currentSwordVFX4.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position (paangat at harap)
		local forwardOffset = -20
		local rotation = CFrame.Angles(math.rad(90), math.rad(100), 0)
		currentSwordVFX4:PivotTo(root.CFrame * CFrame.new(-5, 10, -forwardOffset) * rotation)

		-- Anchor lahat muna habang naka-summon
		for _, part in ipairs(currentSwordVFX4:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Cleanup after ilang segundo (just in case)
		game:GetService("Debris"):AddItem(currentSwordVFX4, 1.5)
	end)

	-- ? Pag "SwordStrike" marker ? lumipad na yung sword
	animTrack:GetMarkerReachedSignal("SwordStrike"):Connect(function()
		if not currentSwordVFX1 then return end

		local bladePart = currentSwordVFX1
		if bladePart then
			local tweenService = game:GetService("TweenService")
			local info = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

			local goal = {}
			goal.Position = bladePart.Position + (root.CFrame.LookVector * 300)

			local tween = tweenService:Create(bladePart, info, goal)
			tween:Play()
		end

	end)
	
	animTrack:GetMarkerReachedSignal("SwordStrike"):Connect(function()
		if not currentSwordVFX1 then return end

		local bladePart = currentSwordVFX2
		if bladePart then
			local tweenService = game:GetService("TweenService")
			local info = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

			local goal = {}
			goal.Position = bladePart.Position + (root.CFrame.LookVector * 300)

			local tween = tweenService:Create(bladePart, info, goal)
			tween:Play()
		end

	end)
	
	animTrack:GetMarkerReachedSignal("SwordStrike"):Connect(function()
		if not currentSwordVFX1 then return end

		local bladePart = currentSwordVFX3
		if bladePart then
			local tweenService = game:GetService("TweenService")
			local info = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

			local goal = {}
			goal.Position = bladePart.Position + (root.CFrame.LookVector * 300)

			local tween = tweenService:Create(bladePart, info, goal)
			tween:Play()
		end

	end)
	
	animTrack:GetMarkerReachedSignal("SwordStrike"):Connect(function()
		if not currentSwordVFX1 then return end

		local bladePart = currentSwordVFX4
		if bladePart then
			local tweenService = game:GetService("TweenService")
			local info = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

			local goal = {}
			goal.Position = bladePart.Position + (root.CFrame.LookVector * 300)

			local tween = tweenService:Create(bladePart, info, goal)
			tween:Play()
		end

	end)

end)
