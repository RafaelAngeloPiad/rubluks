-- ========================================
-- PART CONTACT DAMAGE - ICE TRAP EXAMPLE
-- Example configuration for an ice trap that deals ice damage (slow + DPS)
-- ========================================

-- Copy the PartContactDamage.luau script and modify the CONFIG table:

local CONFIG = {
	-- Damage Settings
	damage = 15,                    -- Initial damage on contact
	damageCooldown = 1.0,           -- Seconds between damage ticks
	
	-- Status Ailment Settings (ICE)
	statusAilmentType = "ice",     -- Apply ice status (slow + damage)
	statusAilmentChance = 100,     -- 100% chance to freeze
	statusAilmentDuration = 3.0,   -- Ice effect lasts 3 seconds
	statusAilmentDPS = 3,          -- 3 damage per second while frozen
	statusAilmentTickInterval = 1.0, -- 1 second between ice damage ticks
	statusAilmentSlowMultiplier = 0.3, -- 30% movement speed (70% slow)
	
	-- Visual Settings
	showDamageNumbers = true,       -- Show damage numbers
	showDamageFlash = true,         -- Show damage flash
	damageFlashColor = Color3.new(0, 0.5, 1), -- Blue ice color
	damageFlashDuration = 0.1,      -- Flash duration
	
	-- Targeting Settings
	damagePlayers = true,          -- Damage players
	damageMobs = false,            -- Don't damage mobs
	damageSelf = false,            -- Don't damage self
}

