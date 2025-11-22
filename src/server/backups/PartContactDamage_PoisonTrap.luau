-- ========================================
-- PART CONTACT DAMAGE - POISON TRAP EXAMPLE
-- Example configuration for a poison trap that deals poison damage
-- ========================================

-- Copy the PartContactDamage.luau script and modify the CONFIG table:

local CONFIG = {
	-- Damage Settings
	damage = 20,                    -- Initial damage on contact
	damageCooldown = 1.0,           -- Seconds between damage ticks
	
	-- Status Ailment Settings (POISON)
	statusAilmentType = "poison",   -- Apply poison status
	statusAilmentChance = 100,      -- 100% chance to poison
	statusAilmentDuration = 5.0,   -- Poison lasts 5 seconds
	statusAilmentDPS = 5,           -- 5 damage per second while poisoned
	statusAilmentTickInterval = 1.0, -- 1 second between poison ticks
	
	-- Visual Settings
	showDamageNumbers = true,       -- Show damage numbers
	showDamageFlash = true,         -- Show damage flash
	damageFlashColor = Color3.new(0.5, 0, 0.5), -- Purple poison color
	damageFlashDuration = 0.1,      -- Flash duration
	
	-- Targeting Settings
	damagePlayers = true,          -- Damage players
	damageMobs = false,            -- Don't damage mobs
	damageSelf = false,            -- Don't damage self
}

