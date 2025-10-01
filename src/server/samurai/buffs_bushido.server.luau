-- ========================================
-- BUSHIDO BUFF SERVER
-- Raw and procedural implementation
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://111377142829522"

remote.OnServerEvent:Connect(function(player, skillType)
	
	-- Only handle bushido buff requests
	if skillType ~= "bushido" then
		return
	end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)
	animTrack:Play()
	_G.applySamuraiAnimationSpeed(animTrack)
	
	-- Lock input when buff starts
	remote:FireClient(player, "lock_input")
	_G.setSamuraiWalkingSpeed(player, "blocking") -- Stop movement during buff
	
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
	end)

end)
