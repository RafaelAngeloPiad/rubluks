-- WeaponHitboxConfig: Configuration for weapon-specific hitbox sizes and offsets
-- This module manages hitbox properties for different weapon types

local WeaponHitboxConfig = {}

-- Default hitbox configuration (fallback)
local DEFAULT_CONFIG = {
    size = Vector3.new(6, 6, 6),
    offset = Vector3.new(0, 0, 4), -- (x, y, z) offset from HumanoidRootPart; z is forward
}

-- Weapon-specific hitbox configurations
-- Each weapon tag gets its own hitbox size and offset
local WEAPON_CONFIGS = {
    -- Melee weapons with different reach and coverage
    ["archer_weapon"] = {
        size = Vector3.new(5, 5, 5), -- Smaller, precise hitbox for archer melee
        offset = Vector3.new(0, 0, 3.5),
    },
    
    ["samurai_weapon"] = {
        size = Vector3.new(7, 6, 8), -- Long reach for katana
        offset = Vector3.new(0, 0, 5),
    },
    
    ["knight_weapon"] = {
        size = Vector3.new(6, 7, 6), -- Balanced sword and shield
        offset = Vector3.new(0, 0, 4),
    },
    
    ["gladiator_weapon"] = {
        size = Vector3.new(8, 6, 7), -- Wide sweeping attacks
        offset = Vector3.new(0, 0, 4.5),
    },
    
    ["berserker_weapon"] = {
        size = Vector3.new(9, 8, 7), -- Large, powerful swings
        offset = Vector3.new(0, 0, 5),
    },
}

-- Future: Skills can have their own configurations too
local SKILL_CONFIGS = {
    -- Example skill configurations (for future use)
    ["fire_slash"] = {
        size = Vector3.new(10, 8, 12),
        offset = Vector3.new(0, 0, 6),
    },
    
    ["ice_spear"] = {
        size = Vector3.new(4, 4, 15),
        offset = Vector3.new(0, 0, 8),
    },
    
    ["thunder_strike"] = {
        size = Vector3.new(12, 15, 8),
        offset = Vector3.new(0, 0, 4),
    },
}

-- Get hitbox configuration for a specific weapon tag
function WeaponHitboxConfig.getWeaponConfig(weaponTag)
    local config = WEAPON_CONFIGS[weaponTag]
    if config then
        return {
            size = config.size,
            offset = config.offset,
        }
    end
    
    -- Return default if weapon tag not found
    return {
        size = DEFAULT_CONFIG.size,
        offset = DEFAULT_CONFIG.offset,
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
