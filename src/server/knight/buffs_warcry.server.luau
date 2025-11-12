-- ========================================
-- WAR CRY BUFF SERVER
-- Raw and procedural implementation
-- Based on original Warcry.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://115710510666189"

remote.OnServerEvent:Connect(function(player, skillType)
	
	-- Only handle warcry buff requests
	if skillType ~= "warcry" then
		return
	end
	
	-- Prevent buff usage if weapon does not match player's class (respect allowSkills flag)
	if not ServerConfigs.isWeaponClassMatch(player) then
		if ServerConfigs.Client.MismatchedWeaponPenalty.allowSkills == false then
			warn("[Warcry] Buff blocked: Player " .. player.Name .. " tried to use Knight buff with mismatched weapon.")
			return
		end
	end
	
	-- Check cooldown using centralized system
	if _G.knightIsSkillOnCooldown(player, "warcry") then
		local remainingTime = _G.knightGetRemainingCooldown(player, "warcry")
		_G.knightSendCooldownStatus(player, "warcry", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.knightSetSkillCooldown(player, "warcry")
	local cooldownTime = _G.KNIGHT_COOLDOWNS["warcry"]
	_G.knightSendCooldownStatus(player, "warcry", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.knightSendCooldownStatus(player, "warcry", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applyKnightAnimationSpeed(animTrack, "warcry")
	
	-- Lock input when buff starts
	remote:FireClient(player, "lock_input")
	_G.setKnightWalkingSpeed(player, "blocking") -- Stop movement during buff
	
	-- Unlock input when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_input")
		_G.setKnightWalkingSpeed(player, "normal") -- Restore normal movement
	end)

	-- ⚡ AURA marker (one-time connection lang)
	animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
		-- Apply buff when aura starts
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local level = leaderstats:FindFirstChild("Level")
			if level then
				local buffConfig = ServerConfigs.getBuffConfig("Warcry", level.Value)
				if buffConfig then
					-- Apply buff using global function
					_G.applyBuff(player, "Warcry", buffConfig)
				else
					-- Buff not unlocked - send warning to client
					local minLevel = ServerConfigs.getBuffMinLevel("Warcry")
					if minLevel then
						-- Use StarterGui to show notification
						local StarterGui = game:GetService("StarterGui")
						StarterGui:SetCore("SendNotification", {
							Title = "Warcry Not Unlocked",
							Text = string.format("Warcry requires Level %d. You are Level %d.", minLevel, level.Value),
							Duration = 5,
							Button1 = "OK"
						})
					end
				end
			end
		end
		
		local vfx = ReplicatedStorage.Warcry:WaitForChild("Aura"):Clone()
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

		Debris:AddItem(vfx, 1.5)
	end)

end)
