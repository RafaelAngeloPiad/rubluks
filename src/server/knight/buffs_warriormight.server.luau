-- ========================================
-- WARRIOR MIGHT BUFF SERVER
-- Raw and procedural implementation
-- Based on original WarriorMight.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://96555166715164"

remote.OnServerEvent:Connect(function(player, skillType)
	
	-- Only handle warriormight buff requests
	if skillType ~= "warriormight" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.knightIsSkillOnCooldown(player, "warriormight") then
		local remainingTime = _G.knightGetRemainingCooldown(player, "warriormight")
		_G.knightSendCooldownStatus(player, "warriormight", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.knightSetSkillCooldown(player, "warriormight")
	local cooldownTime = _G.KNIGHT_COOLDOWNS["warriormight"]
	_G.knightSendCooldownStatus(player, "warriormight", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.knightSendCooldownStatus(player, "warriormight", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applyKnightAnimationSpeed(animTrack, "warriormight")
	
	-- Lock input when buff starts
	remote:FireClient(player, "lock_input")
	_G.setKnightWalkingSpeed(player, "blocking") -- Stop movement during buff
	
	-- Camera sequence (added system)
	remote:FireClient(player, "play_camera_sequence", "warriormight")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
		_G.setKnightWalkingSpeed(player, "normal") -- Restore normal movement
	end)

	-- ⚡ AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("Aura"):Connect(function()
		-- Apply buff when aura starts
		local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local level = leaderstats:FindFirstChild("Level")
			if level then
				local buffConfig = ServerConfigs.getBuffConfig("WarriorMight", level.Value)
				if buffConfig then
					-- Apply buff using global function
					_G.applyBuff(player, "WarriorMight", buffConfig)
				else
					-- Buff not unlocked - send warning to client
					local minLevel = ServerConfigs.getBuffMinLevel("WarriorMight")
					if minLevel then
						-- Use StarterGui to show notification
						local StarterGui = game:GetService("StarterGui")
						StarterGui:SetCore("SendNotification", {
							Title = "Warrior's Might Not Unlocked",
							Text = string.format("Warrior's Might requires Level %d. You are Level %d.", minLevel, level.Value),
							Duration = 5,
							Button1 = "OK"
						})
					end
				end
			end
		end

		local vfx = ReplicatedStorage.HunterMark:WaitForChild("Aura"):Clone()
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
	end)

end)
