-- ========================================
-- SIMPLE DOT MOB
-- Very simple mob: follows player, creates DOT field
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local MOB_STATS = {
	HP = 500,
	Defense = 20,
	Damage = 10,        -- Damage per tick
	AttackCooldown = 3,
	AttackRange = 12,
	WalkSpeed = 14,
	DOTTickTime = 0.5   -- Time between ticks
}

local MOB_VARIANT_NAME = "SimpleDOTMob"

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
while not _G.createStaticDOTHitbox do
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
				-- Create DOT field at target position
				lastAttack = tick()
				
				local dotPart = Instance.new("Part")
				dotPart.Name = "DOTField"
				dotPart.Size = Vector3.new(15, 15, 15)
				dotPart.CFrame = CFrame.new(nearest.Position.X, nearest.Position.Y - 2, nearest.Position.Z)
				dotPart.Anchored = true
				dotPart.CanCollide = false
				dotPart.Parent = workspace
                dotPart.Transparency = 0.5
				
				-- Create DOT hitbox
				_G.createStaticDOTHitbox({
					attachTo = dotPart,
					offset = CFrame.new(0, 0, 0),
					size = Vector3.new(15, 15, 15),
					damage = MOB_STATS.Damage,
					damageTickTime = MOB_STATS.DOTTickTime,
					character = model,
					name = "DOTField",
					showVisual = true,
					visualColor = Color3.new(1, 0.5, 0),
					delay = 0
				})
				
				-- Destroy DOT field after 5 seconds
				task.delay(5, function()
					if dotPart then
						dotPart:Destroy()
					end
				end)
			else
				-- Follow
				humanoid:MoveTo(nearest.Position)
			end
		end
	end
end)

