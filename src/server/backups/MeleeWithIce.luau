-- ========================================
-- SIMPLE MELEE MOB WITH ICE
-- Same as SimpleMeleeMob but with ice status ailment (slow + damage)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Configuration
local MOB_STATS = {
	HP = 500,
	Defense = 20,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 30,
	AttackCooldown = 1.5,
	AttackRange = 8,
	WalkSpeed = 16
}

-- Ice configuration
local ICE_CONFIG = {
	type = "ice",            -- Status ailment type
	chance = 50,             -- 50% chance to freeze on hit
	duration = 3.0,          -- Ice duration in seconds
	dps = 3,                 -- Damage per second
	tickInterval = 1.0,      -- Seconds between damage ticks
	slowMultiplier = 0.3     -- 30% movement speed
}

-- Radius and return configuration (same as GolemSolo)
local FOLLOW_RANGE = 100
local MAX_RADIUS = 40
local RETURN_RADIUS = 60
local RETURN_WAIT = 2
local UPDATE_RATE = 0.5

local MOB_VARIANT_NAME = "MeleeWithIce"

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
while not _G.createStaticHitbox do
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
						-- Attack
						lastAttack = tick()
						-- Include statusAilment in hitbox config for ice chance
						_G.createStaticHitbox({
							attachTo = root,
							offset = CFrame.new(0, 0, -4),
							size = Vector3.new(8, 8, 8),
							damage = MOB_STATS.Damage,
							character = model,
							name = "MeleeAttack",
							showVisual = true,
							visualColor = Color3.new(1, 0, 0),
							delay = 0,
							actionType = nil, -- Mobs don't have animation speeds
							classType = nil, -- Mobs don't have classes
							statusAilment = ICE_CONFIG -- Add ice status ailment
						})
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

