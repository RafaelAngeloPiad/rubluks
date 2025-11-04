-- ========================================
-- PART CONTACT DAMAGE - FIRE TRAP EXAMPLE
-- Example configuration for a fire trap that deals burn damage
-- ========================================

-- Copy the PartContactDamage.luau script and modify the CONFIG table:

local CONFIG = {
	-- Damage Settings
	damage = 25,                    -- Initial damage on contact
	damageCooldown = 1.0,           -- Seconds between damage ticks
	
	-- Status Ailment Settings (BURN)
	statusAilmentType = "burn",     -- Apply burn status
	statusAilmentChance = 100,      -- 100% chance to burn
	statusAilmentDuration = 5.0,   -- Burn lasts 5 seconds
	statusAilmentDPS = 10,          -- 10 damage per second while burning
	statusAilmentTickInterval = 1.0, -- 1 second between burn ticks
	
	-- Visual Settings
	showDamageNumbers = true,       -- Show damage numbers
	showDamageFlash = true,         -- Show damage flash
	damageFlashColor = Color3.new(1, 0.5, 0), -- Orange flame color
	damageFlashDuration = 0.1,      -- Flash duration
	
	-- Targeting Settings
	damagePlayers = true,          -- Damage players
	damageMobs = false,            -- Don't damage mobs
	damageSelf = false,            -- Don't damage self
}

