-- ========================================
-- SIMPLE MELEE MOB
-- Very simple mob: follows player, attacks with hitbox
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

-- Radius and return configuration (same as GolemSolo)
local FOLLOW_RANGE = 100
local MAX_RADIUS = 40
local RETURN_RADIUS = 60
local RETURN_WAIT = 2
local UPDATE_RATE = 0.5

local MOB_VARIANT_NAME = "SimpleMeleeMob"

-- Get model and parts
local model = script.Parent
if not model or not model.Parent then return end -- Safety check: model must exist

local humanoid = model:WaitForChild("Humanoid")
local root = model:WaitForChild("HumanoidRootPart")

-- ========================================
-- STATS ASSIGNMENT GUIDE
-- ========================================
-- 
-- STATS THAT GO TO HUMANOID (Roblox Humanoid properties):
-- - HP → humanoid.MaxHealth and humanoid.Health (used by Roblox's health system)
-- - WalkSpeed → humanoid.WalkSpeed (controls movement speed)
--
-- STATS THAT GO TO MODEL ATTRIBUTES (read by DynamicHitboxV3):
-- - Defense → MaxDefense and CurrentDefense attributes (used by defense system)
-- - DefensePenetration → attribute (reduces target's defense when attacking)
-- - CritRate → attribute (mob crit chance, used when mob attacks)
-- - CritMultiplier → attribute (mob crit damage multiplier)
-- - Damage → attribute (base damage dealt, used by hitbox creation)
-- - MobVariant → attribute (for display/identification)
--
-- STATS THAT ARE LOCAL CONFIG ONLY (not stored anywhere):
-- - AttackCooldown → used locally in attack logic
-- - AttackRange → used locally in attack logic
-- ========================================

-- Apply stats to HUMANOID (Roblox health/movement system)
humanoid.MaxHealth = MOB_STATS.HP
humanoid.Health = MOB_STATS.HP
humanoid.WalkSpeed = MOB_STATS.WalkSpeed

-- Apply stats to MODEL ATTRIBUTES (read by DynamicHitboxV3 damage system)
-- Defense stats (used when mob takes damage)
model:SetAttribute("MaxDefense", MOB_STATS.Defense)
model:SetAttribute("CurrentDefense", MOB_STATS.Defense)  -- Starts at MaxDefense, decreases when taking damage

-- Offensive stats (used when mob attacks)
model:SetAttribute("DefensePenetration", MOB_STATS.DefensePenetration)  -- Reduces target's defense
model:SetAttribute("CritRate", MOB_STATS.CritRate)  -- Crit chance (0-100)
model:SetAttribute("CritMultiplier", MOB_STATS.CritMultiplier)  -- Crit damage multiplier (150 = 1.5x)
model:SetAttribute("Damage", MOB_STATS.Damage)  -- Base damage dealt

-- Identification (for display/UI)
model:SetAttribute("MobVariant", MOB_VARIANT_NAME)

-- Note: AttackCooldown and AttackRange are used locally in the attack logic below,
-- they don't need to be stored as attributes or humanoid properties.

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
						-- Note: actionType and classType are nil for mobs (no animation speed scaling)
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
							classType = nil   -- Mobs don't have classes
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

