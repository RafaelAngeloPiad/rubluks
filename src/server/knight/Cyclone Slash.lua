local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local player = Players.LocalPlayer

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- preload animation
local auraAnim = Instance.new("Animation")
auraAnim.AnimationId = "rbxassetid://129607332522508"


tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")

	local animTrack = animator:LoadAnimation(auraAnim)

	-- ? AURA marker (one-time connection lang)
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

		-- Auto cleanup
		game:GetService("Debris"):AddItem(vfx, 3.5)



	end)

	-- ?? Left click handler (ito lang uulit-ulit)
	tool.Activated:Connect(function()
		animTrack:Play()
	end)
end)
