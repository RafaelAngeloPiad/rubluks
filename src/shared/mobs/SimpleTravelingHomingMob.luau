-- ========================================
-- SIMPLE TRAVELING HOMING MOB
-- Very simple mob: shoots homing missiles with traveling hitbox
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

local MOB_VARIANT_NAME = "SimpleTravelingHomingMob"

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
				-- Shoot homing missile
				lastAttack = tick()
				
				-- Create missile part
				local missile = Instance.new("Part")
				missile.Name = "HomingMissile"
				missile.Size = Vector3.new(1, 1, 1)
				missile.CFrame = root.CFrame * CFrame.new(0, 1, -2)
				missile.Anchored = false
				missile.CanCollide = false
				missile.Material = Enum.Material.Neon
				missile.Color = Color3.new(1, 0.5, 0)
				missile.Transparency = 0.3
				missile.Parent = workspace
				
				-- Add body velocity to missile
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
				bodyVelocity.Velocity = root.CFrame.LookVector * MOB_STATS.MissileSpeed
				bodyVelocity.Parent = missile
				
				-- Create traveling hitbox attached to missile
				_G.createTravelingHitbox({
					attachTo = missile,
					offset = CFrame.new(0, 0, 0),
					size = Vector3.new(6, 6, 6),
					damage = MOB_STATS.Damage,
					character = model,
					name = "HomingMissile",
					showVisual = true,
					visualColor = Color3.new(1, 0.5, 0),
					delay = 0
				})
				
				-- Homing behavior - update direction towards target
				local homingConnection
				local startTime = tick()
				homingConnection = RunService.Heartbeat:Connect(function()
					if not missile or not missile.Parent then
						homingConnection:Disconnect()
						return
					end
					
					-- Check lifetime
					if tick() - startTime >= MOB_STATS.MissileLifetime then
						homingConnection:Disconnect()
						missile:Destroy()
						return
					end
					
					-- Find current target (may have moved)
					local currentTarget = nil
					local nearestDist = 100
					for _, player in pairs(game.Players:GetPlayers()) do
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local dist = (player.Character.HumanoidRootPart.Position - missile.Position).Magnitude
							if dist < nearestDist then
								nearestDist = dist
								currentTarget = player.Character.HumanoidRootPart
							end
						end
					end
					
					if currentTarget then
						-- Update direction towards target
						local direction = (currentTarget.Position - missile.Position).Unit
						bodyVelocity.Velocity = direction * MOB_STATS.MissileSpeed
					end
				end)
			else
				-- Follow
				humanoid:MoveTo(nearest.Position)
			end
		end
	end
end)

