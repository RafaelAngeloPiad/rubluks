-- ========================================
-- PART CONTACT DAMAGE - STUN TRAP EXAMPLE
-- Example configuration for a stun trap (no damage, just stuns)
-- ========================================

-- Copy the PartContactDamage.luau script and modify the CONFIG table:

local CONFIG = {
	-- Damage Settings
	damage = 0,                     -- No direct damage
	damageCooldown = 1.0,           -- Seconds between ticks
	
	-- Status Ailment Settings (STUN)
	statusAilmentType = "stun",    -- Apply stun status
	statusAilmentChance = 50,      -- 50% chance to stun (50/50 chance)
	statusAilmentDuration = 2.0,   -- Stun lasts 2 seconds
	
	-- Visual Settings
	showDamageNumbers = false,     -- No damage numbers (no damage)
	showDamageFlash = true,        -- Show flash when stunned (even if no damage)
	damageFlashColor = Color3.new(0.5, 0.5, 0.5), -- Gray stun color
	damageFlashDuration = 0.1,      -- Flash duration
	
	-- Targeting Settings
	damagePlayers = true,          -- Affect players
	damageMobs = false,            -- Don't affect mobs
	damageSelf = false,            -- Don't affect self
}

