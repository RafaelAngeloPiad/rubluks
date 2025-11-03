-- ========================================
-- SIMPLE MELEE MOB
-- Very simple mob: follows player, attacks with hitbox
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local MOB_STATS = {
	HP = 500,
	Defense = 20,
	Damage = 30,
	AttackCooldown = 1.5,
	AttackRange = 8,
	WalkSpeed = 16
}

local MOB_VARIANT_NAME = "SimpleMeleeMob"

-- Get model and parts
local model = script.Parent
if not model or not model.Parent then return end -- Safety check: model must exist

local humanoid = model:WaitForChild("Humanoid")
local root = model:WaitForChild("HumanoidRootPart")

-- Apply stats
humanoid.MaxHealth = MOB_STATS.HP
humanoid.Health = MOB_STATS.HP
humanoid.WalkSpeed = MOB_STATS.WalkSpeed

model:SetAttribute("MaxDefense", MOB_STATS.Defense)
model:SetAttribute("CurrentDefense", MOB_STATS.Defense)
model:SetAttribute("Damage", MOB_STATS.Damage)
model:SetAttribute("MobVariant", MOB_VARIANT_NAME)

-- Create floating stats display
local MobStatsDisplay = require(ReplicatedStorage:WaitForChild("MobStatsDisplay"))
if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
	MobStatsDisplay.createMobStatsDisplay(model)
end

-- Wait for hitbox functions to be available
while not _G.createStaticHitbox do
	task.wait(0.1)
end

-- Main loop
task.spawn(function()
	local lastAttack = 0
	
	while task.wait(0.5) do
		-- Safety check: ensure model, humanoid, and root still exist
		if not model or not model.Parent or not humanoid or not humanoid.Parent or not root or not root.Parent then
			break -- Exit loop if model was destroyed
		end
		
		if humanoid.Health <= 0 then break end
		
		-- Find nearest player
		local nearest = nil
		local nearestDist = 20
		
		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearest = player.Character.HumanoidRootPart
				end
			end
		end
		
		-- Attack or follow
		if nearest then
			local dist = (nearest.Position - root.Position).Magnitude
			
			if dist <= MOB_STATS.AttackRange and tick() - lastAttack >= MOB_STATS.AttackCooldown then
				-- Attack
				lastAttack = tick()
				_G.createStaticHitbox({
					attachTo = root,
					offset = CFrame.new(0, 0, -4),
					size = Vector3.new(8, 8, 8),
					damage = MOB_STATS.Damage,
					character = model,
					name = "MeleeAttack",
					showVisual = true,
					visualColor = Color3.new(1, 0, 0),
					delay = 0
				})
			else
				-- Follow
				humanoid:MoveTo(nearest.Position)
			end
		end
	end
end)

