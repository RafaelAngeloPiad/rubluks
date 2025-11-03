-- ========================================
-- SIMPLE TRAVELING MOB
-- Very simple mob: shoots straight projectiles with traveling hitbox
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local MOB_STATS = {
	HP = 500,
	Defense = 20,
	Damage = 25,
	AttackCooldown = 2,      -- Seconds between shots
	AttackRange = 50,        -- Distance to start shooting
	WalkSpeed = 14,
	MissileSpeed = 30,       -- Speed of the missile part
	MissileLifetime = 5      -- Seconds before missile despawns
}

local MOB_VARIANT_NAME = "SimpleTravelingMob"

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
while not _G.createTravelingHitbox do
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
		local nearestDist = 100
		
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
				-- Shoot straight projectile
				lastAttack = tick()
				
				-- Calculate direction to target
				local direction = (nearest.Position - root.Position).Unit
				
				-- Create projectile part
				local projectile = Instance.new("Part")
				projectile.Name = "StraightProjectile"
				projectile.Size = Vector3.new(1, 1, 1)
				projectile.CFrame = root.CFrame * CFrame.new(0, 1, -2)
				projectile.Anchored = false
				projectile.CanCollide = false
				projectile.Material = Enum.Material.Neon
				projectile.Color = Color3.new(0, 1, 1) -- Cyan color
				projectile.Transparency = 0.3
				projectile.Parent = workspace
				
				-- Add body velocity to projectile (straight fire!)
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
				bodyVelocity.Velocity = direction * MOB_STATS.MissileSpeed
				bodyVelocity.Parent = projectile
				
				-- Create traveling hitbox attached to projectile
				_G.createTravelingHitbox({
					attachTo = projectile,
					offset = CFrame.new(0, 0, 0),
					size = Vector3.new(6, 6, 6),
					damage = MOB_STATS.Damage,
					character = model,
					name = "StraightProjectile",
					showVisual = true,
					visualColor = Color3.new(0, 1, 1), -- Cyan color
					delay = 0
				})
				
				-- Auto-cleanup projectile after lifetime
				task.delay(MOB_STATS.MissileLifetime, function()
					if projectile and projectile.Parent then
						projectile:Destroy()
					end
				end)
			else
				-- Follow
				humanoid:MoveTo(nearest.Position)
			end
		end
	end
end)
