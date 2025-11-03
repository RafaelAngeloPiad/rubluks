-- ========================================
-- SIMPLE PROJECTILE MOB
-- Very simple mob: shoots projectiles using projectile hitbox system (like archer)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local MOB_STATS = {
	HP = 500,
	Defense = 20,
	Damage = 25,
	AttackCooldown = 2,      -- Seconds between shots
	AttackRange = 50,        -- Distance to start shooting
	WalkSpeed = 14,
	ProjectileSpeed = 80,    -- Speed of the hitbox
	ProjectileVisualSpeed = 100 -- Speed of the visual (can be different for effect)
}

local MOB_VARIANT_NAME = "SimpleProjectileMob"

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
while not _G.createProjectileHitbox do
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
				-- Shoot projectile
				lastAttack = tick()
				
				-- Calculate direction to target
				local direction = (nearest.Position - root.Position).Unit
				
				-- Create projectile visual (simple model)
				local projectileModel = Instance.new("Model")
				projectileModel.Name = "MobProjectile"
				
				local projectile = Instance.new("Part")
				projectile.Name = "Projectile"
				projectile.Size = Vector3.new(1, 1, 1)
				projectile.CFrame = root.CFrame * CFrame.new(0, 1, -2)
				projectile.Anchored = false
				projectile.CanCollide = false
				projectile.Material = Enum.Material.Neon
				projectile.Color = Color3.new(1, 0, 1) -- Magenta color
				projectile.Transparency = 0.3
				projectile.Parent = projectileModel
				
				projectileModel.Parent = workspace
				
				-- Make all parts non-physical (preventPhysicsPush = true)
				for _, part in ipairs(projectileModel:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.CanQuery = false
						part.CanTouch = false
					end
				end
				
				-- Use projectile hitbox system (like archer arrows)
				_G.createProjectileHitbox({
					visualPart = projectile,
					direction = direction,
					size = Vector3.new(6, 6, 6), -- Hitbox size
					damage = MOB_STATS.Damage,
					character = model,
					name = "MobProjectile",
					visualSpeed = MOB_STATS.ProjectileVisualSpeed, -- Visual speed
					hitboxSpeed = MOB_STATS.ProjectileSpeed, -- Hitbox speed
					delay = 0,
					anchorDelay = 0.03, -- Anchor delay after hit
					showVisual = true,
					visualColor = Color3.new(1, 0, 1), -- Magenta color
					preventPhysicsPush = true -- Prevent physics interactions
				})
				
				-- Auto cleanup
				game:GetService("Debris"):AddItem(projectileModel, 3)
			else
				-- Follow
				humanoid:MoveTo(nearest.Position)
			end
		end
	end
end)
