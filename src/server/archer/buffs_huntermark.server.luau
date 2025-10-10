-- ========================================
-- HUNTER MARK BUFF SERVER
-- Raw and procedural implementation
-- Based on original HunterMark.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation (from original HunterMark.lua)
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://103808169554095"

remote.OnServerEvent:Connect(function(player, skillType)
	
	-- Only handle hunterMark buff requests
	if skillType ~= "hunterMark" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "hunterMark") then
		local remainingTime = _G.getRemainingCooldown(player, "hunterMark")
		_G.sendCooldownStatus(player, "hunterMark", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "hunterMark")
	local cooldownTime = _G.ARCHER_COOLDOWNS["hunterMark"]
	_G.sendCooldownStatus(player, "hunterMark", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "hunterMark", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applyArcherAnimationSpeed(animTrack, "hunterMark")
	
	-- Lock input when buff starts
	remote:FireClient(player, "lock_input")
	_G.setArcherWalkingSpeed(player, "blocking") -- Stop movement during buff
	
	-- Trigger camera sequence for hunterMark buff
	remote:FireClient(player, "play_camera_sequence", "hunterMark")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
		_G.setArcherWalkingSpeed(player, "normal") -- Restore normal movement
		-- Restore archer aiming system (will respect current aim lock state)
		remote:FireClient(player, "setup_archer_aiming")
	end)

	-- Aura marker (from original HunterMark.lua)
	animTrack:GetMarkerReachedSignal("Aura"):Connect(function()
		local vfx = ReplicatedStorage.HunterMark:WaitForChild("Aura"):Clone()
		vfx.Parent = workspace

		local root = character:WaitForChild("HumanoidRootPart")

		-- Position sa harap ng player (independent, no weld)
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

		game:GetService("Debris"):AddItem(vfx, 2.5)
	end)

end)
