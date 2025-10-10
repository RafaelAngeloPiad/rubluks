-- ========================================
-- CYCLONE SLASH SKILL SERVER
-- Raw and procedural implementation
-- Based on original Cyclone Slash.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Cooldown system now centralized in actions.server.luau

-- preload animation
local slashAnim = Instance.new("Animation")
slashAnim.AnimationId = "rbxassetid://129607332522508"

-- CYCLONE SLASH HITBOX TIMING CONFIG
local CYCLONE_CONFIG = {
	smallHitboxDuration = 1.0, -- How long to use small hitbox before switching to big (in seconds)
}

local function ResizeVFX(vfx, scale)
	for _, obj in ipairs(vfx:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- Liitan mismo part
			obj.Size = obj.Size * scale

			-- Kung may mesh sa loob ng part
			local mesh = obj:FindFirstChildWhichIsA("SpecialMesh")
			if mesh then
				mesh.Scale = mesh.Scale * scale
			end

		elseif obj:IsA("ParticleEmitter") then
			-- Scale particle size
			local newSize = {}
			for _, keypoint in ipairs(obj.Size.Keypoints) do
				table.insert(newSize, NumberSequenceKeypoint.new(
					keypoint.Time,
					keypoint.Value * scale
					))
			end
			obj.Size = NumberSequence.new(newSize)

			-- Optional din i-scale ang speed, lifetime, spread
			obj.Speed = NumberRange.new(obj.Speed.Min * scale, obj.Speed.Max * scale)
		end
	end
end

remote.OnServerEvent:Connect(function(player, skillType)
	-- Only handle cyclone_slash skill requests
	if skillType ~= "cyclone_slash" then
		return
	end
	
	-- Check cooldown using centralized system
	if _G.isSkillOnCooldown(player, "cyclone_slash") then
		local remainingTime = _G.getRemainingCooldown(player, "cyclone_slash")
		_G.sendCooldownStatus(player, "cyclone_slash", true, math.ceil(remainingTime))
		return
	end
	
	-- Set cooldown using centralized system
	_G.setSkillCooldown(player, "cyclone_slash")
	local cooldownTime = _G.KNIGHT_COOLDOWNS["cyclone_slash"]
	_G.sendCooldownStatus(player, "cyclone_slash", true, cooldownTime)
	
	-- Clear cooldown status on client after cooldown expires
	task.delay(cooldownTime, function()
		_G.sendCooldownStatus(player, "cyclone_slash", false, 0)
	end)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(slashAnim)
	animTrack:Play()
	_G.applyKnightAnimationSpeed(animTrack, "cyclone_slash")
	
	-- Lock movement only when skill starts (allows camera/aiming)
	remote:FireClient(player, "lock_movement")
	_G.setKnightWalkingSpeed(player, "slow") -- Set slow walking speed
	
	-- Unlock movement when animation ends
	animTrack.Stopped:Connect(function()
		remote:FireClient(player, "unlock_movement")
		_G.setKnightWalkingSpeed(player, "normal") -- Restore normal walking speed
	end)

	-- ? AURA marker (from original Cyclone Slash.lua)
	animTrack:GetMarkerReachedSignal("Cyclone"):Connect(function()

		local vfx = ReplicatedStorage.CycloneSlash:WaitForChild("CycloneExplosion"):Clone()
		vfx.Parent = character -- para kasama sa character hierarchy

		local torso = character:FindFirstChild("LowerTorso") or character:WaitForChild("HumanoidRootPart")

		-- Kung yung mismong VFX ay BasePart na
		local mainPart = vfx

		-- Position muna sa torso
		mainPart.CFrame = torso.CFrame

		-- Ensure movable
		mainPart.Anchored = false
		mainPart.CanCollide = false

		-- I-weld sa torso para sumunod gumalaw
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = mainPart
		weld.Parent = mainPart

		-- PHASE 1: Small hitbox for initial duration
		_G.createStaticDOTHitbox({
			attachTo = mainPart,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(15, 15, 15), -- Small hitbox
			damage = 3,
			damageTickTime = 0.4,
			character = character,
			name = "CycloneSlashSmall",
			showVisual = true,
			visualColor = Color3.new(0.3, 0, 0.6), -- Darker purple
			delay = 0
		})
		
		-- After duration, spawn big hitbox
		task.delay(CYCLONE_CONFIG.smallHitboxDuration, function()
			_G.createStaticDOTHitbox({
				attachTo = mainPart,
				offset = CFrame.new(0, 0, 0),
				size = Vector3.new(40, 30, 40), -- Big hitbox
				damage = 7,
				damageTickTime = 0.3,
				character = character,
				name = "CycloneSlashBig",
				showVisual = true,
				visualColor = Color3.new(0.8, 0, 1), -- Brighter purple
				delay = 0
			})
		end)

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 3.5)

	end)



end)
