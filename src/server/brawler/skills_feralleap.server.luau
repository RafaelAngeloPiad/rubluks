-- ========================================
-- FERAL LEAP SKILL SERVER
-- Raw and procedural implementation
-- Based on original Feral Leap.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- Track feral leap connections for each player
local feralLeapConnections = {}

-- preload animations
local leapAnim = Instance.new("Animation")
leapAnim.AnimationId = "rbxassetid://76859592290622"

local leapAttackAnim = Instance.new("Animation")
leapAttackAnim.AnimationId = "rbxassetid://98157070007403"

-- FERAL LEAP HITBOX CONFIG
local FERALLEAP_CONFIG = {
	hitboxSize = Vector3.new(70, 70, 70), -- Hitbox size for claw mark
	hitboxDamage = 35, -- Damage on landing
	hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
}

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle feralleap skill requests
	if skillType ~= "feralleap" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "feralleap") then
		local remainingTime = _G.getRemainingCooldown(player, "feralleap")
		_G.sendCooldownStatus(player, "feralleap", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "feralleap")
	local cooldownTime = _G.BRAWLER_COOLDOWNS["feralleap"]
	_G.sendCooldownStatus(player, "feralleap", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "feralleap", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(leapAnim)
	local animTrack2 = animator:LoadAnimation(leapAttackAnim)
	
	animTrack:Play()
	_G.applyBrawlerAnimationSpeed(animTrack, "feralleap")
	
	-- Tell client to start leap control
	remote:FireClient(player, "feralleap_start")
	
	-- Store the connection for this player
	local stoppedConnection = animTrack.Stopped:Connect(function()
		-- Only proceed if this is a natural stop (not client-triggered)
		if not feralLeapConnections[player.UserId] or not feralLeapConnections[player.UserId].wasStoppedEarly then
			-- Stop first anim and play second
			animTrack:Stop()
			animTrack2:Play()
			_G.applyBrawlerAnimationSpeed(animTrack2, "feralleap")
			
			-- Tell client to stop leap control
			remote:FireClient(player, "feralleap_stop")
			
			-- Trigger VFX at "ClawMark"
			animTrack2:GetMarkerReachedSignal("ClawMark"):Once(function()
				local vfx = ReplicatedStorage.FeralLeap:WaitForChild("FeralLeap"):Clone()
				vfx.Parent = workspace
				vfx:PivotTo(root.CFrame * CFrame.new(0, 1, 0))

				for _, part in ipairs(vfx:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
					end
				end

				Debris:AddItem(vfx, 1)
				
				-- Hitbox for claw mark
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 1, -25),
					size = FERALLEAP_CONFIG.hitboxSize,
					damage = FERALLEAP_CONFIG.hitboxDamage,
					character = character,
					name = "FeralLeapClaw",
					showVisual = true,
					visualColor = Color3.new(1, 0, 0),
					delay = FERALLEAP_CONFIG.hitboxDelay
				})
			end)
		end
		
		-- Clean up connection
		if feralLeapConnections[player.UserId] then
			feralLeapConnections[player.UserId] = nil
		end
	end)
	
	-- Store connection info
	feralLeapConnections[player.UserId] = {
		connection = stoppedConnection,
		wasStoppedEarly = false
	}
	
end)

-- Listen for client stop signal
remote.OnServerEvent:Connect(function(player, actionName)
	if actionName == "feralleap_client_stop" then
		-- Client requested to stop leap early
		local character = player.Character
		if not character then return end
		local animator = character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
		if not animator then return end
		
		-- Mark as stopped early BEFORE stopping the animation
		if feralLeapConnections[player.UserId] then
			feralLeapConnections[player.UserId].wasStoppedEarly = true
		end
		
		-- Find and stop the leap animation
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			if track.Animation.AnimationId == leapAnim.AnimationId then
				track:Stop()
			end
		end
		
		-- Tell client to stop leap control immediately
		remote:FireClient(player, "feralleap_stop")
	end
end)
