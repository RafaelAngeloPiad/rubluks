-- ========================================
-- EXAMPLE: PART CONTACT DAMAGE USAGE
-- This is an example of how to use PartContactDamage module
-- ========================================

--[[
	USAGE INSTRUCTIONS:
	
	1. Place PartContactDamage.luau in ReplicatedStorage or ServerScriptService
	2. Create a Part in your workspace
	3. Add a ModuleScript to the Part with this code (or copy the PartContactDamage code directly)
	4. Customize the CONFIG table at the top of PartContactDamage.luau
	
	EXAMPLE CONFIGURATIONS:
	
	-- Basic damage only (red flash)
	damage = 50,
	statusAilmentType = nil,
	showDamageNumbers = true,
	showDamageFlash = true,
	damageFlashColor = Color3.new(1, 0, 0), -- Red
	
	-- Fire trap (burn damage)
	damage = 25,
	statusAilmentType = "burn",
	statusAilmentChance = 100,
	statusAilmentDuration = 5.0,
	statusAilmentDPS = 10,
	statusAilmentTickInterval = 1.0,
	damageFlashColor = Color3.new(1, 0.5, 0), -- Orange
	
	-- Poison trap (poison damage)
	damage = 20,
	statusAilmentType = "poison",
	statusAilmentChance = 100,
	statusAilmentDuration = 5.0,
	statusAilmentDPS = 5,
	statusAilmentTickInterval = 1.0,
	damageFlashColor = Color3.new(0.5, 0, 0.5), -- Purple
	
	-- Ice trap (slow + damage)
	damage = 15,
	statusAilmentType = "ice",
	statusAilmentChance = 100,
	statusAilmentDuration = 3.0,
	statusAilmentDPS = 3,
	statusAilmentTickInterval = 1.0,
	statusAilmentSlowMultiplier = 0.3, -- 30% speed
	damageFlashColor = Color3.new(0, 0.5, 1), -- Blue
	
	-- Slow trap (slow only, no damage)
	damage = 0,
	statusAilmentType = "slow",
	statusAilmentChance = 100,
	statusAilmentDuration = 3.0,
	statusAilmentSlowMultiplier = 0.5, -- 50% speed
	showDamageNumbers = false,
	showDamageFlash = false,
	
	-- Stun trap (stun only, no damage)
	damage = 0,
	statusAilmentType = "stun",
	statusAilmentChance = 50, -- 50% chance to stun
	statusAilmentDuration = 2.0,
	showDamageNumbers = false,
	damageFlashColor = Color3.new(0.5, 0.5, 0.5), -- Gray
]]

-- ========================================
-- ALTERNATIVE: DIRECT CONFIG IN SCRIPT
-- ========================================

-- If you want to configure it directly in the PartContactDamage script,
-- you can modify the CONFIG table at the top of the file.
-- Or, you can require the module and set config programmatically:

--[[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PartContactDamage = require(ReplicatedStorage:WaitForChild("PartContactDamage"))

-- Set custom configuration
PartContactDamage.setConfig({
	damage = 100,
	statusAilmentType = "burn",
	statusAilmentChance = 75,
	statusAilmentDuration = 5.0,
	statusAilmentDPS = 10,
	damageFlashColor = Color3.new(1, 0.5, 0), -- Orange
	damageCooldown = 0.5, -- Faster damage ticks
})
]]

