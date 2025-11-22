-- ========================================
-- SIMPLE TRAVELING MOB WITH POISON
-- Shoots projectiles with traveling hitbox that can poison
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- Configuration
local MOB_STATS = {
	HP = 500,
	Defense = 20,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	AttackCooldown = 2,      -- Seconds between shots
	AttackRange = 50,        -- Distance to start shooting
	WalkSpeed = 14,
	MissileSpeed = 30,       -- Speed of the missile part
	MissileLifetime = 5      -- Seconds before missile despawns
}

-- Poison configuration
local POISON_CONFIG = {
	type = "poison",         -- Status ailment type
	chance = 50,             -- 50% chance to poison on hit
	duration = 5.0,          -- Poison duration in seconds
	dps = 5,                 -- Damage per second
	tickInterval = 1.0       -- Seconds between damage ticks
}

-- Radius and return configuration (same as GolemSolo)
local FOLLOW_RANGE = 100
local MAX_RADIUS = 40
local RETURN_RADIUS = 60
local RETURN_WAIT = 2
local UPDATE_RATE = 0.5

local MOB_VARIANT_NAME = "TravelingWithPoison"

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
model:SetAttribute("DefensePenetration", MOB_STATS.DefensePenetration)
model:SetAttribute("CritRate", MOB_STATS.CritRate)
model:SetAttribute("CritMultiplier", MOB_STATS.CritMultiplier)
model:SetAttribute("Damage", MOB_STATS.Damage)
model:SetAttribute("MobVariant", MOB_VARIANT_NAME)

-- Add exclusion tag so mobs don't damage each other
CollectionService:AddTag(model, "simple_entity")

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
	local spawnPosition = model:GetPivot().Position
	local timeSinceTarget = 0
	local returningHome = false
	
	while task.wait(UPDATE_RATE) do
		-- Safety check: ensure model, humanoid, and root still exist
		if not model or not model.Parent or not humanoid or not humanoid.Parent or not root or not root.Parent then
			break -- Exit loop if model was destroyed
		end
		
		if humanoid.Health <= 0 then break end
		
		local position = root.Position
		local distFromSpawn = (position - spawnPosition).Magnitude
		
		-- Return logic
		if returningHome then
			if distFromSpawn <= MAX_RADIUS * 0.8 then
				returningHome = false
			else
				humanoid:MoveTo(spawnPosition)
			end
		else
			-- Find nearest player within FOLLOW_RANGE
			local nearest = nil
			local nearestDist = FOLLOW_RANGE
			
			for _, player in pairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = player.Character.HumanoidRootPart
					end
				end
			end
			
			-- Attack or follow
			if nearest then
				local dist = (nearest.Position - position).Magnitude
				local targetDistFromSpawn = (nearest.Position - spawnPosition).Magnitude
				
				if targetDistFromSpawn <= RETURN_RADIUS then
					-- Target is within return radius, attack or follow
					if dist <= MOB_STATS.AttackRange and tick() - lastAttack >= MOB_STATS.AttackCooldown then
						-- Shoot straight projectile
						lastAttack = tick()
						
						-- Calculate direction to target
						local direction = (nearest.Position - root.Position).Unit
						
						-- Create projectile part
						local projectile = Instance.new("Part")
						projectile.Name = "PoisonProjectile"
						projectile.Size = Vector3.new(1, 1, 1)
						projectile.CFrame = root.CFrame * CFrame.new(0, 1, -2)
						projectile.Anchored = false
						projectile.CanCollide = false
						projectile.Material = Enum.Material.Neon
						projectile.Color = Color3.new(0.5, 0, 0.5) -- Purple color for poison
						projectile.Transparency = 0.3
						projectile.Parent = workspace
						
						-- Add body velocity to projectile
						local bodyVelocity = Instance.new("BodyVelocity")
						bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
						bodyVelocity.Velocity = direction * MOB_STATS.MissileSpeed
						bodyVelocity.Parent = projectile
						
						-- Create traveling hitbox attached to projectile with poison
						_G.createTravelingHitbox({
							attachTo = projectile,
							offset = CFrame.new(0, 0, 0),
							size = Vector3.new(6, 6, 6),
							damage = MOB_STATS.Damage,
							character = model,
							name = "PoisonProjectile",
							showVisual = true,
							visualColor = Color3.new(0.5, 0, 0.5), -- Purple color
							delay = 0,
							actionType = nil, -- Mobs don't have animation speeds
							classType = nil, -- Mobs don't have classes
							statusAilment = POISON_CONFIG -- Add poison status ailment
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
					timeSinceTarget = 0
				else
					-- Target too far from spawn, return home
					returningHome = true
					humanoid:MoveTo(spawnPosition)
				end
			else
				-- No target found
				timeSinceTarget += UPDATE_RATE
				if timeSinceTarget >= RETURN_WAIT then
					returningHome = true
					humanoid:MoveTo(spawnPosition)
					timeSinceTarget = 0
				end
			end
		end
	end
end)

