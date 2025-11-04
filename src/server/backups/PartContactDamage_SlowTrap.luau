-- ========================================
-- PART CONTACT DAMAGE - SLOW TRAP EXAMPLE
-- Example configuration for a slow trap (no damage, just slows)
-- ========================================

-- Copy the PartContactDamage.luau script and modify the CONFIG table:

local CONFIG = {
	-- Damage Settings
	damage = 0,                     -- No direct damage
	damageCooldown = 1.0,           -- Seconds between ticks
	
	-- Status Ailment Settings (SLOW)
	statusAilmentType = "slow",    -- Apply slow status
	statusAilmentChance = 100,     -- 100% chance to slow
	statusAilmentDuration = 3.0,   -- Slow lasts 3 seconds
	statusAilmentSlowMultiplier = 0.5, -- 50% movement speed (half speed)
	
	-- Visual Settings
	showDamageNumbers = false,     -- No damage numbers (no damage)
	showDamageFlash = false,       -- No damage flash (no damage)
	damageFlashColor = Color3.new(0.5, 0.5, 0.5), -- Gray (unused)
	damageFlashDuration = 0.1,      -- Flash duration (unused)
	
	-- Targeting Settings
	damagePlayers = true,          -- Affect players
	damageMobs = false,            -- Don't affect mobs
	damageSelf = false,            -- Don't affect self
}

