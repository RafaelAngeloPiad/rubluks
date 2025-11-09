-- ========================================
-- CHAMPIONS BLOOD BUFF SERVER
-- Raw and procedural implementation
-- Based on original Champions Blood.lua
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
auraAnim.AnimationId = "rbxassetid://130327931088371"

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle championsblood buff requests
	if skillType ~= "championsblood" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.gladiatorIsSkillOnCooldown(player, "championsblood") then
		local remainingTime = _G.gladiatorGetRemainingCooldown(player, "championsblood")
		_G.gladiatorSendCooldownStatus(player, "championsblood", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.gladiatorSetSkillCooldown(player, "championsblood")
	local cooldownTime = _G.GLADIATOR_COOLDOWNS["championsblood"]
	_G.gladiatorSendCooldownStatus(player, "championsblood", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.gladiatorSendCooldownStatus(player, "championsblood", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applyGladiatorAnimationSpeed(animTrack, "championsblood")
	
	-- Lock input only when buff starts
	remote:FireClient(player, "lock_input")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
	end)

	-- AURA marker (from original Champions Blood.lua)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		-- Apply buff when aura starts
		local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local level = leaderstats:FindFirstChild("Level")
			if level then
				local buffConfig = ServerConfigs.getBuffConfig("ChampionsBlood", level.Value)
				if buffConfig then
					-- Apply buff using global function
					_G.applyBuff(player, "ChampionsBlood", buffConfig)
				else
					-- Buff not unlocked - send warning to client
					local minLevel = ServerConfigs.getBuffMinLevel("ChampionsBlood")
					if minLevel then
						-- Use StarterGui to show notification
						local StarterGui = game:GetService("StarterGui")
						StarterGui:SetCore("SendNotification", {
							Title = "Champion's Blood Not Unlocked",
							Text = string.format("Champion's Blood requires Level %d. You are Level %d.", minLevel, level.Value),
							Duration = 5,
							Button1 = "OK"
						})
					end
				end
			end
		end

		local vfx = ReplicatedStorage.ChampionBlood:WaitForChild("ChampionBlood"):Clone()
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

		game:GetService("Debris"):AddItem(vfx, 1.5)
	end)

end)
