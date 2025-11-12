-- ========================================
-- BLOODTHIRST BUFF SERVER
-- Raw and procedural implementation
-- Based on original Bloodthirst.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://109703526340788"

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle bloodthirst buff requests
	if skillType ~= "bloodthirst" then
		return
	end
	
	-- Prevent buff usage if weapon does not match player's class (respect allowSkills flag)
	local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[BloodThirst] Buff blocked: Player " .. player.Name .. " tried to use Brawler buff with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.brawlerIsSkillOnCooldown(player, "bloodthirst") then
		local remainingTime = _G.brawlerGetRemainingCooldown(player, "bloodthirst")
		_G.brawlerSendCooldownStatus(player, "bloodthirst", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.brawlerSetSkillCooldown(player, "bloodthirst")
	local cooldownTime = _G.BRAWLER_COOLDOWNS["bloodthirst"]
	_G.brawlerSendCooldownStatus(player, "bloodthirst", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.brawlerSendCooldownStatus(player, "bloodthirst", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applyBrawlerAnimationSpeed(animTrack, "bloodthirst")
	
	-- Lock input only when buff starts
	remote:FireClient(player, "lock_input")
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
	end)

	-- AURA marker (from original Bloodthirst.lua)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		-- Apply buff when aura starts
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local level = leaderstats:FindFirstChild("Level")
			if level then
				local buffConfig = ServerConfigs.getBuffConfig("BloodThirst", level.Value)
				if buffConfig then
					-- Apply buff using global function
					_G.applyBuff(player, "BloodThirst", buffConfig)
				else
					-- Buff not unlocked - send warning to client
					local minLevel = ServerConfigs.getBuffMinLevel("BloodThirst")
					if minLevel then
						-- Use StarterGui to show notification
						local StarterGui = game:GetService("StarterGui")
						StarterGui:SetCore("SendNotification", {
							Title = "Blood Thirst Not Unlocked",
							Text = string.format("Blood Thirst requires Level %d. You are Level %d.", minLevel, level.Value),
							Duration = 5,
							Button1 = "OK"
						})
					end
				end
			end
		end

		local vfx = ReplicatedStorage.Bloodthirst:WaitForChild("Bloodthirst"):Clone()
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
