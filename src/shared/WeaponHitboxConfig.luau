-- WeaponHitboxConfig: Configuration for weapon-specific hitbox sizes and offsets
-- This module manages hitbox properties for different weapon types

--[[
HITBOX COORDINATE SYSTEM GUIDE:
===============================

SIZE Vector3(X, Y, Z):
- X = WIDTH (left/right) - How wide the hitbox extends sideways
- Y = HEIGHT (up/down) - How tall the hitbox extends vertically  
- Z = DEPTH/REACH (forward/back) - How far the hitbox extends forward from player

OFFSET Vector3(X, Y, Z):
- X = SIDEWAYS OFFSET (+ = right, - = left) - Usually 0 for centered attacks
- Y = VERTICAL OFFSET (+ = up, - = down) - Usually 0 for player height attacks
- Z = FORWARD DISTANCE (+ = forward) - How far in front of player the hitbox appears

EXAMPLES:
- Vector3.new(8, 6, 10) = 8 studs wide, 6 studs tall, 10 studs deep
- offset Vector3.new(0, 0, 5) = 5 studs in front of player, centered
- offset Vector3.new(2, 1, 3) = 2 studs right, 1 stud up, 3 studs forward
]]

local WeaponHitboxConfig = {}

-- Default hitbox configuration (fallback)
local DEFAULT_CONFIG = {
    size = Vector3.new(6, 6, 6), -- 6 wide, 6 tall, 6 deep
    offset = Vector3.new(0, 0, 4), -- centered, 4 studs forward
    baseDamage = 25, -- default damage
}

-- Weapon-specific hitbox configurations
-- Each weapon tag gets its own hitbox size and offset
-- Reach order: Gladiator (longest) > Samurai (long) > Knight (mid) > Archer (short) > Berserker (shortest)
local WEAPON_CONFIGS = {
    -- Berserker: Significantly shortest reach - claw weapons, ultra close combat
    -- High damage to compensate for ultra short range
    ["berserker_weapon"] = {
        size = Vector3.new(5, 5, 3), -- 5 wide, 5 tall, 3 deep (very short reach)
        offset = Vector3.new(0, 0, 1.5), -- centered, 1.5 studs forward (ultra close)
        baseDamage = 40, -- High damage for high-risk close combat
    },
    
    -- Archer: Short reach - backup melee weapon
    -- Low damage as it's secondary to ranged attacks
    ["archer_weapon"] = {
        size = Vector3.new(5, 5, 6), -- 5 wide, 5 tall, 6 deep (precise hitbox)
        offset = Vector3.new(0, 0, 3), -- centered, 3 studs forward (short reach)
        baseDamage = 20, -- Low damage, backup weapon
    },
    
    -- Knight: Mid reach - sword and shield, balanced combat
    -- Balanced damage for versatile fighter
    ["knight_weapon"] = {
        size = Vector3.new(6, 6, 7), -- 6 wide, 6 tall, 7 deep (balanced)
        offset = Vector3.new(0, 0, 4), -- centered, 4 studs forward (medium reach)
        baseDamage = 30, -- Balanced damage
    },
    
    -- Samurai: Long reach - katana with extended blade
    -- Good damage with precision strikes
    ["samurai_weapon"] = {
        size = Vector3.new(6, 6, 9), -- 6 wide, 6 tall, 9 deep (long katana)
        offset = Vector3.new(0, 0, 5.5), -- centered, 5.5 studs forward (long reach)
        baseDamage = 35, -- High damage, skilled warrior
    },
    
    -- Gladiator: Longest reach - spears, tridents, long weapons
    -- Moderate damage balanced by superior reach
    ["gladiator_weapon"] = {
        size = Vector3.new(7, 6, 11), -- 7 wide, 6 tall, 11 deep (maximum reach)
        offset = Vector3.new(0, 0, 6.5), -- centered, 6.5 studs forward (longest reach)
        baseDamage = 25, -- Moderate damage, reach advantage
    },
}

-- Future: Skills can have their own configurations too
local SKILL_CONFIGS = {

    -- Samurai-specific skills
    ["samurai_skill_1"] = {
        -- Forward dash slash: long reach, medium width
        size = Vector3.new(6, 6, 12),
        offset = Vector3.new(0, 0, 6),
        baseDamage = 45,
    },
    ["samurai_skill_2"] = {
        -- Wide sweeping arc: shorter reach, wider area
        size = Vector3.new(10, 6, 8),
        offset = Vector3.new(0, 0, 4.5),
        baseDamage = 55,
    },
}

-- Get hitbox configuration for a specific weapon tag
function WeaponHitboxConfig.getWeaponConfig(weaponTag)
    local config = WEAPON_CONFIGS[weaponTag]
    if config then
        return {
            size = config.size,
            offset = config.offset,
            baseDamage = config.baseDamage,
        }
    end
    
    -- Return default if weapon tag not found
    return {
        size = DEFAULT_CONFIG.size,
        offset = DEFAULT_CONFIG.offset,
        baseDamage = DEFAULT_CONFIG.baseDamage,
    }
end

-- Get hitbox configuration for a specific skill tag (for future use)
function WeaponHitboxConfig.getSkillConfig(skillTag)
    local config = SKILL_CONFIGS[skillTag]
    if config then
        return {
            size = config.size,
            offset = config.offset,
        }
    end
    
    -- Return default if skill tag not found
    return {
        size = DEFAULT_CONFIG.size,
        offset = DEFAULT_CONFIG.offset,
    }
end

-- Get all available weapon tags
function WeaponHitboxConfig.getAllWeaponTags()
    local tags = {}
    for tag, _ in pairs(WEAPON_CONFIGS) do
        table.insert(tags, tag)
    end
    return tags
end

-- Get all available skill tags
function WeaponHitboxConfig.getAllSkillTags()
    local tags = {}
    for tag, _ in pairs(SKILL_CONFIGS) do
        table.insert(tags, tag)
    end
    return tags
end

-- Check if a weapon tag has a custom configuration
function WeaponHitboxConfig.hasWeaponConfig(weaponTag)
    return WEAPON_CONFIGS[weaponTag] ~= nil
end

-- Check if a skill tag has a custom configuration
function WeaponHitboxConfig.hasSkillConfig(skillTag)
    return SKILL_CONFIGS[skillTag] ~= nil
end

-- Get default configuration
function WeaponHitboxConfig.getDefaultConfig()
    return {
        size = DEFAULT_CONFIG.size,
        offset = DEFAULT_CONFIG.offset,
        baseDamage = DEFAULT_CONFIG.baseDamage,
    }
end

-- Debug function to print all configurations
function WeaponHitboxConfig.printAllConfigs()
    print("=== WEAPON HITBOX CONFIGURATIONS ===")
    print("Default Config:", DEFAULT_CONFIG.size, DEFAULT_CONFIG.offset)
    
    print("\nWeapon Configs:")
    for tag, config in pairs(WEAPON_CONFIGS) do
        print(string.format("  %s: Size=%s, Offset=%s", tag, tostring(config.size), tostring(config.offset)))
    end
    
    print("\nSkill Configs:")
    for tag, config in pairs(SKILL_CONFIGS) do
        print(string.format("  %s: Size=%s, Offset=%s", tag, tostring(config.size), tostring(config.offset)))
    end
end

return WeaponHitboxConfig
