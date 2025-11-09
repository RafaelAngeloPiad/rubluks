-- ========================================
-- BUSHIDO BUFF SERVER
-- Raw and procedural implementation
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://111377142829522"

remote.OnServerEvent:Connect(function(player, skillType)
	
	-- Only handle bushido buff requests
	if skillType ~= "bushido" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.samuraiIsSkillOnCooldown(player, "bushido") then
		local remainingTime = _G.samuraiGetRemainingCooldown(player, "bushido")
		_G.samuraiSendCooldownStatus(player, "bushido", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.samuraiSetSkillCooldown(player, "bushido")
	local cooldownTime = _G.SAMURAI_COOLDOWNS["bushido"]
	_G.samuraiSendCooldownStatus(player, "bushido", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.samuraiSendCooldownStatus(player, "bushido", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack, "bushido")
	
	-- Lock input when buff starts
	remote:FireClient(player, "lock_input")
	_G.setSamuraiWalkingSpeed(player, "blocking") -- Stop movement during buff
	
	-- Camera sequence (added system)
	remote:FireClient(player, "play_camera_sequence", "bushido")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
		_G.setSamuraiWalkingSpeed(player, "normal") -- Restore normal movement
	end)

	-- ⚡ AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("Aura"):Connect(function()

		local vfx = ReplicatedStorage.Bushido:WaitForChild("Aura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
		--local forwardOffset = -10 -- gaano kalayo sa harap magsimula
		local rotationX = 0 -- ikot pataas/pababa
		local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
		local rotationZ = 0 -- ikot paikot

		local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

		vfx:PivotTo(root.CFrame * CFrame.new(0, -2, 0)* rotation)

		-- Ensure lahat ng parts ay hindi naka-anchor pero stable
		for _, part in ipairs(vfx:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
			end
		end
		
		Debris:AddItem(vfx, 4.5)
		
		-- Apply Bushido buff (prevents HP from hitting 0)
		if _G.applyBuff then
			_G.applyBuff(player, "Bushido")
		end
	end)

end)
