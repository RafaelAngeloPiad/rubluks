-- HitboxConfig: Configuration for weapon and skill hitbox sizes, offsets, and damage
-- This module manages hitbox properties for different weapon types and skills

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

local HitboxConfig = {}

-- Default hitbox configuration (fallback)
local DEFAULT_CONFIG = {
    size = Vector3.new(6, 6, 6), -- 6 wide, 6 tall, 6 deep
    offset = Vector3.new(0, 0, 4), -- centered, 4 studs forward
    baseDamage = 2, -- default damage
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
        baseDamage = 12, -- High damage for high-risk close combat
    },
    
    -- Archer: Short reach - backup melee weapon
    -- Low damage as it's secondary to ranged attacks
    ["archer_weapon"] = {
        size = Vector3.new(5, 5, 6), -- 5 wide, 5 tall, 6 deep (precise hitbox)
        offset = Vector3.new(0, 0, 3), -- centered, 3 studs forward (short reach)
        baseDamage = 5, -- Low damage, backup weapon
    },
    
    -- Knight: Mid reach - sword and shield, balanced combat
    -- Balanced damage for versatile fighter
    ["knight_weapon"] = {
        size = Vector3.new(6, 6, 7), -- 6 wide, 6 tall, 7 deep (balanced)
        offset = Vector3.new(0, 0, 4), -- centered, 4 studs forward (medium reach)
        baseDamage = 7, -- Balanced damage
    },
    
    -- Samurai: Long reach - katana with extended blade
    -- Good damage with precision strikes
    ["samurai_weapon"] = {
        size = Vector3.new(6, 6, 9), -- 6 wide, 6 tall, 9 deep (long katana)
        offset = Vector3.new(0, 0, 5.5), -- centered, 5.5 studs forward (long reach)
        baseDamage = 9, -- High damage, skilled warrior
    },
    
    -- Gladiator: Longest reach - spears, tridents, long weapons
    -- Moderate damage balanced by superior reach
    ["gladiator_weapon"] = {
        size = Vector3.new(7, 6, 11), -- 7 wide, 6 tall, 11 deep (maximum reach)
        offset = Vector3.new(0, 0, 6.5), -- centered, 6.5 studs forward (longest reach)
        baseDamage = 10, -- Moderate damage, reach advantage
    },
}

-- Skills can have their own configurations for each weapon type
local SKILL_CONFIGS = {

    -- Samurai-specific skills
    ["samurai_skill_1"] = {
        -- Forward dash slash: long reach, medium width
        size = Vector3.new(6, 6, 12), -- 6 wide, 6 tall, 12 deep (long dash)
        offset = Vector3.new(0, 0, 6), -- centered, 6 studs forward (extended reach)
        baseDamage = 10, -- High skill damage
        animationId = "rbxassetid://116519685012277", -- Dash Slash animation
        name = "Dash Slash",
        keyCode = Enum.KeyCode.K,
    },
    ["samurai_skill_2"] = {
        -- Wide sweeping arc: shorter reach, wider area
        size = Vector3.new(10, 6, 8), -- 10 wide, 6 tall, 8 deep (wide sweep)
        offset = Vector3.new(0, 0, 4.5), -- centered, 4.5 studs forward (medium reach)
        baseDamage = 10, -- Higher skill damage
        animationId = "rbxassetid://116519685012277", -- Wide Arc animation
        name = "Wide Arc",
        keyCode = Enum.KeyCode.L,
    },

    -- Berserker-specific skills
    ["berserker_skill_1"] = {
        -- Berserker rage: short range but high damage burst
        size = Vector3.new(6, 6, 5), -- 6 wide, 6 tall, 5 deep (close combat)
        offset = Vector3.new(0, 0, 2.5), -- centered, 2.5 studs forward (close range)
        baseDamage = 15, -- Very high damage for berserker rage
        animationId = "rbxassetid://116519685012277", -- Berserker Rage animation
        name = "Berserker Rage",
        keyCode = Enum.KeyCode.K,
    },
    ["berserker_skill_2"] = {
        -- Whirlwind attack: wide area, short reach
        size = Vector3.new(8, 6, 6), -- 8 wide, 6 tall, 6 deep (wide area)
        offset = Vector3.new(0, 0, 3), -- centered, 3 studs forward (medium reach)
        baseDamage = 12, -- High damage whirlwind
        animationId = "rbxassetid://116519685012277", -- Whirlwind animation
        name = "Whirlwind",
        keyCode = Enum.KeyCode.L,
    },

    -- Gladiator-specific skills
    ["gladiator_skill_1"] = {
        -- Spear thrust: maximum reach attack
        size = Vector3.new(4, 6, 15), -- 4 wide, 6 tall, 15 deep (precise long thrust)
        offset = Vector3.new(0, 0, 8), -- centered, 8 studs forward (maximum reach)
        baseDamage = 12, -- High damage precise thrust
        animationId = "rbxassetid://116519685012277", -- Spear Thrust animation
        name = "Spear Thrust",
        keyCode = Enum.KeyCode.K,
    },
    ["gladiator_skill_2"] = {
        -- Arena sweep: wide but shorter reach
        size = Vector3.new(12, 6, 8), -- 12 wide, 6 tall, 8 deep (wide arena sweep)
        offset = Vector3.new(0, 0, 5), -- centered, 5 studs forward (medium reach)
        baseDamage = 10, -- Moderate damage sweep
        animationId = "rbxassetid://116519685012277", -- Arena Sweep animation
        name = "Arena Sweep",
        keyCode = Enum.KeyCode.L,
    },

    -- Knight-specific skills
    ["knight_skill_1"] = {
        -- Shield bash: forward shield attack
        size = Vector3.new(6, 6, 8), -- 6 wide, 6 tall, 8 deep (shield bash)
        offset = Vector3.new(0, 0, 4.5), -- centered, 4.5 studs forward (medium reach)
        baseDamage = 8, -- Moderate damage shield bash
        animationId = "rbxassetid://116519685012277", -- Shield Bash animation
        name = "Shield Bash",
        keyCode = Enum.KeyCode.K,
    },
    ["knight_skill_2"] = {
        -- Defensive stance: protective area around knight
        size = Vector3.new(8, 6, 6), -- 8 wide, 6 tall, 6 deep (defensive area)
        offset = Vector3.new(0, 0, 3), -- centered, 3 studs forward (close protection)
        baseDamage = 6, -- Lower damage, defensive skill
        animationId = "rbxassetid://116519685012277", -- Defensive Stance animation
        name = "Defensive Stance",
        keyCode = Enum.KeyCode.L,
    },

    -- Archer-specific skills
    ["archer_skill_1"] = {
        -- Quick shot: precise ranged attack (using melee hitbox for now)
        size = Vector3.new(4, 6, 8), -- 4 wide, 6 tall, 8 deep (precise shot)
        offset = Vector3.new(0, 0, 5), -- centered, 5 studs forward (ranged)
        baseDamage = 8, -- Moderate damage precise shot
        animationId = "rbxassetid://116519685012277", -- Quick Shot animation
        name = "Quick Shot",
        keyCode = Enum.KeyCode.K,
    },
    ["archer_skill_2"] = {
        -- Volley: wide area shot
        size = Vector3.new(10, 6, 10), -- 10 wide, 6 tall, 10 deep (wide volley)
        offset = Vector3.new(0, 0, 6), -- centered, 6 studs forward (medium range)
        baseDamage = 6, -- Lower damage per shot, area effect
        animationId = "rbxassetid://116519685012277", -- Volley animation
        name = "Volley",
        keyCode = Enum.KeyCode.L,
    },
}

-- Get hitbox configuration for a specific weapon tag
function HitboxConfig.getWeaponConfig(weaponTag)
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

-- Get hitbox configuration for a specific skill tag
function HitboxConfig.getSkillConfig(skillTag)
    local config = SKILL_CONFIGS[skillTag]
    if config then
        return {
            size = config.size,
            offset = config.offset,
            baseDamage = config.baseDamage,
            animationId = config.animationId,
            name = config.name,
            keyCode = config.keyCode,
        }
    end
    
    -- Return default if skill tag not found
    return {
        size = DEFAULT_CONFIG.size,
        offset = DEFAULT_CONFIG.offset,
        baseDamage = DEFAULT_CONFIG.baseDamage,
        animationId = "rbxassetid://116519685012277",
        name = "Unknown Skill",
        keyCode = Enum.KeyCode.Unknown,
    }
end

-- Get all available weapon tags
function HitboxConfig.getAllWeaponTags()
    local tags = {}
    for tag, _ in pairs(WEAPON_CONFIGS) do
        table.insert(tags, tag)
    end
    return tags
end

-- Get all available skill tags
function HitboxConfig.getAllSkillTags()
    local tags = {}
    for tag, _ in pairs(SKILL_CONFIGS) do
        table.insert(tags, tag)
    end
    return tags
end

-- Check if a weapon tag has a custom configuration
function HitboxConfig.hasWeaponConfig(weaponTag)
    return WEAPON_CONFIGS[weaponTag] ~= nil
end

-- Check if a skill tag has a custom configuration
function HitboxConfig.hasSkillConfig(skillTag)
    return SKILL_CONFIGS[skillTag] ~= nil
end

-- Get default configuration
function HitboxConfig.getDefaultConfig()
    return {
        size = DEFAULT_CONFIG.size,
        offset = DEFAULT_CONFIG.offset,
        baseDamage = DEFAULT_CONFIG.baseDamage,
    }
end

-- Debug function to print all configurations (for development use)
function HitboxConfig.printAllConfigs()
    print("=== HITBOX CONFIGURATIONS ===")
    print("Default Config:", DEFAULT_CONFIG.size, DEFAULT_CONFIG.offset, DEFAULT_CONFIG.baseDamage)
    
    print("\nWeapon Configs:")
    for tag, config in pairs(WEAPON_CONFIGS) do
        print(string.format("  %s: Size=%s, Offset=%s, Damage=%d", tag, tostring(config.size), tostring(config.offset), config.baseDamage))
    end
    
    print("\nSkill Configs:")
    for tag, config in pairs(SKILL_CONFIGS) do
        print(string.format("  %s: Size=%s, Offset=%s, Damage=%d", tag, tostring(config.size), tostring(config.offset), config.baseDamage))
    end
end

return HitboxConfig
