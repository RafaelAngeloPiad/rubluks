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

-- Global hitbox damage interval configuration
local DAMAGE_INTERVAL_CONFIG = {
    hitboxDamageInterval = 0.5, -- Damage is applied every 0.5 seconds for sustained hitboxes
    immunityBuffer = 0.1, -- Small buffer to prevent double-hits due to timing
}

-- Projectile configuration for different weapon types
local PROJECTILE_CONFIGS = {
    -- Archer projectiles: Fast, precise arrows
    ["archer_weapon"] = {
        projectileType = "arrow",
        speed = 200, -- studs per second
        range = 800, -- maximum range in studs
        size = Vector3.new(0.5, 0.5, 3), -- thin, long arrow shape
        color = Color3.new(1, 1, 0), -- yellow arrow
        transparency = 0.3,
        material = Enum.Material.Neon,
        hitboxSize = Vector3.new(2, 2, 2), -- small hitbox at impact
        hitboxDuration = 0.2, -- how long impact hitbox lasts
        trailEffect = true, -- whether to show trail effect
        trailLength = 5, -- trail length in studs
        trailTransparency = 0.7, -- trail transparency
    }
}

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
        -- Timing configuration
        cooldownTime = 2.5, -- 2.5 second cooldown between uses
        castTime = 0.7, -- 0.7 second cast/animation duration
        hitboxDelay = 0.2, -- Hitbox appears 0.2s into animation (fast dash)
        hitboxDuration = 0.4, -- Hitbox lasts 0.4s (quick dash strike)
    },
    ["samurai_skill_2"] = {
        -- Wide sweeping arc: shorter reach, wider area
        size = Vector3.new(10, 6, 8), -- 10 wide, 6 tall, 8 deep (wide sweep)
        offset = Vector3.new(0, 0, 4.5), -- centered, 4.5 studs forward (medium reach)
        baseDamage = 10, -- Higher skill damage
        animationId = "rbxassetid://116519685012277", -- Wide Arc animation
        name = "Wide Arc",
        keyCode = Enum.KeyCode.L,
        -- Timing configuration
        cooldownTime = 3.5, -- 3.5 second cooldown between uses
        castTime = 0.9, -- 0.9 second cast/animation duration
        hitboxDelay = 0.3, -- Hitbox appears 0.3s into animation (wide sweep)
        hitboxDuration = 0.6, -- Hitbox lasts 0.6s (extended sweep)
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
        -- Timing configuration
        cooldownTime = 3.0, -- 3 second cooldown between uses
        castTime = 0.8, -- 0.8 second cast/animation duration
        hitboxDelay = 0.3, -- Hitbox appears 0.3s into animation
        hitboxDuration = 0.5, -- Hitbox lasts 0.5s (berserker rage burst)
    },
    ["berserker_skill_2"] = {
        -- Whirlwind attack: wide area, short reach
        size = Vector3.new(8, 6, 6), -- 8 wide, 6 tall, 6 deep (wide area)
        offset = Vector3.new(0, 0, 3), -- centered, 3 studs forward (medium reach)
        baseDamage = 12, -- High damage whirlwind
        animationId = "rbxassetid://116519685012277", -- Whirlwind animation
        name = "Whirlwind",
        keyCode = Enum.KeyCode.L,
        -- Timing configuration
        cooldownTime = 4.0, -- 4 second cooldown between uses
        castTime = 1.0, -- 1.0 second cast/animation duration
        hitboxDelay = 0.4, -- Hitbox appears 0.4s into animation
        hitboxDuration = 0.8, -- Hitbox lasts 0.8s (extended whirlwind)
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
        -- Timing configuration
        cooldownTime = 3.0, -- 3.0 second cooldown between uses
        castTime = 0.8, -- 0.8 second cast/animation duration
        hitboxDelay = 0.4, -- Hitbox appears 0.4s into animation (precise thrust timing)
        hitboxDuration = 0.3, -- Hitbox lasts 0.3s (quick precise thrust)
    },
    ["gladiator_skill_2"] = {
        -- Arena sweep: wide but shorter reach
        size = Vector3.new(12, 6, 8), -- 12 wide, 6 tall, 8 deep (wide arena sweep)
        offset = Vector3.new(0, 0, 5), -- centered, 5 studs forward (medium reach)
        baseDamage = 10, -- Moderate damage sweep
        animationId = "rbxassetid://116519685012277", -- Arena Sweep animation
        name = "Arena Sweep",
        keyCode = Enum.KeyCode.L,
        -- Timing configuration
        cooldownTime = 4.5, -- 4.5 second cooldown between uses
        castTime = 1.1, -- 1.1 second cast/animation duration
        hitboxDelay = 0.5, -- Hitbox appears 0.5s into animation (wide sweep buildup)
        hitboxDuration = 0.7, -- Hitbox lasts 0.7s (long arena sweep)
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
        -- Timing configuration
        cooldownTime = 2.0, -- 2.0 second cooldown between uses
        castTime = 0.6, -- 0.6 second cast/animation duration
        hitboxDelay = 0.2, -- Hitbox appears 0.2s into animation (quick bash)
        hitboxDuration = 0.3, -- Hitbox lasts 0.3s (quick shield bash)
    },
    ["knight_skill_2"] = {
        -- Defensive stance: protective area around knight
        size = Vector3.new(8, 6, 6), -- 8 wide, 6 tall, 6 deep (defensive area)
        offset = Vector3.new(0, 0, 3), -- centered, 3 studs forward (close protection)
        baseDamage = 6, -- Lower damage, defensive skill
        animationId = "rbxassetid://116519685012277", -- Defensive Stance animation
        name = "Defensive Stance",
        keyCode = Enum.KeyCode.L,
        -- Timing configuration
        cooldownTime = 5.0, -- 5.0 second cooldown between uses (defensive skill)
        castTime = 0.8, -- 0.8 second cast/animation duration
        hitboxDelay = 0.3, -- Hitbox appears 0.3s into animation (defensive setup)
        hitboxDuration = 1.0, -- Hitbox lasts 1.0s (extended defensive area)
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
        -- Timing configuration
        cooldownTime = 1.5, -- 1.5 second cooldown between uses (quick shots)
        castTime = 0.5, -- 0.5 second cast/animation duration
        hitboxDelay = 0.1, -- Hitbox appears 0.1s into animation (very quick shot)
        hitboxDuration = 0.2, -- Hitbox lasts 0.2s (very quick shot)
    },
    ["archer_skill_2"] = {
        -- Volley: wide area shot
        size = Vector3.new(10, 6, 10), -- 10 wide, 6 tall, 10 deep (wide volley)
        offset = Vector3.new(0, 0, 6), -- centered, 6 studs forward (medium range)
        baseDamage = 6, -- Lower damage per shot, area effect
        animationId = "rbxassetid://116519685012277", -- Volley animation
        name = "Volley",
        keyCode = Enum.KeyCode.L,
        -- Timing configuration
        cooldownTime = 3.0, -- 3.0 second cooldown between uses
        castTime = 1.0, -- 1.0 second cast/animation duration
        hitboxDelay = 0.6, -- Hitbox appears 0.6s into animation (volley buildup)
        hitboxDuration = 0.6, -- Hitbox lasts 0.6s (sustained volley)
    },
}

-- Combo attack configurations for each weapon type
-- Each combo has 3 attacks with individual timing, damage, and hitbox settings
local COMBO_CONFIGS = {
    -- Berserker combo: Fast, aggressive 3-hit combo with shortest reach
    ["berserker_weapon_combo"] = {
        comboWindow = 2.0, -- Time window to continue combo (seconds)
        resetTime = 3.0, -- Time before combo resets if no input (seconds)
        
        -- Attack 1: Quick opener
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.8, -- Animation duration
            hitboxDelay = 0.3, -- When hitbox appears in animation
            hitboxDuration = 0.4, -- How long hitbox stays active
            size = Vector3.new(5, 5, 3), -- Hitbox size
            offset = Vector3.new(0, 0, 1.5), -- Hitbox offset
            baseDamage = 8, -- Damage for this attack
            name = "Berserker Strike 1",
        },
        
        -- Attack 2: Medium follow-up
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.0,
            hitboxDelay = 0.2,
            hitboxDuration = 0.5,
            size = Vector3.new(6, 5, 4),
            offset = Vector3.new(0, 0, 2),
            baseDamage = 10,
            name = "Berserker Strike 2",
        },
        
        -- Attack 3: Powerful finisher
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.2,
            hitboxDelay = 0.4,
            hitboxDuration = 0.6,
            size = Vector3.new(7, 6, 5),
            offset = Vector3.new(0, 0, 2.5),
            baseDamage = 15,
            name = "Berserker Finisher",
        },
    },

    -- Archer combo: Precise, quick 3-hit combo with short reach
    ["archer_weapon_combo"] = {
        comboWindow = 2.0,
        resetTime = 3.0,
        
        -- Attack 1: Quick precise strike
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.7, -- Faster than berserker
            hitboxDelay = 0.2,
            hitboxDuration = 0.3,
            size = Vector3.new(4, 5, 5), -- Narrower, more precise
            offset = Vector3.new(0, 0, 2.5), -- Slightly longer than berserker
            baseDamage = 6,
            name = "Quick Strike 1",
        },
        
        -- Attack 2: Follow-up strike
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.8,
            hitboxDelay = 0.15,
            hitboxDuration = 0.4,
            size = Vector3.new(5, 5, 6), -- Same as weapon config
            offset = Vector3.new(0, 0, 3),
            baseDamage = 7,
            name = "Quick Strike 2",
        },
        
        -- Attack 3: Precision finisher
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.0,
            hitboxDelay = 0.3,
            hitboxDuration = 0.5,
            size = Vector3.new(6, 6, 7), -- Wider final strike
            offset = Vector3.new(0, 0, 3.5),
            baseDamage = 12,
            name = "Precision Shot",
        },
    },

    -- Knight combo: Balanced, defensive 3-hit combo with medium reach
    ["knight_weapon_combo"] = {
        comboWindow = 2.0,
        resetTime = 3.0,
        
        -- Attack 1: Defensive opener
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.9,
            hitboxDelay = 0.3,
            hitboxDuration = 0.4,
            size = Vector3.new(6, 6, 6), -- Balanced size
            offset = Vector3.new(0, 0, 3.5),
            baseDamage = 7,
            name = "Shield Strike 1",
        },
        
        -- Attack 2: Balanced follow-up
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.0,
            hitboxDelay = 0.25,
            hitboxDuration = 0.5,
            size = Vector3.new(6, 6, 7), -- Same as weapon config
            offset = Vector3.new(0, 0, 4),
            baseDamage = 8,
            name = "Shield Strike 2",
        },
        
        -- Attack 3: Noble finisher
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.1,
            hitboxDelay = 0.4,
            hitboxDuration = 0.6,
            size = Vector3.new(7, 6, 8), -- Slightly larger final strike
            offset = Vector3.new(0, 0, 4.5),
            baseDamage = 14,
            name = "Noble Strike",
        },
    },

    -- Samurai combo: Precise, elegant 3-hit combo with long reach
    ["samurai_weapon_combo"] = {
        comboWindow = 2.0,
        resetTime = 3.0,
        
        -- Attack 1: Elegant opener
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.8,
            hitboxDelay = 0.2,
            hitboxDuration = 0.3,
            size = Vector3.new(5, 6, 8), -- Narrow, precise
            offset = Vector3.new(0, 0, 4.5),
            baseDamage = 8,
            name = "Katana Slash 1",
        },
        
        -- Attack 2: Flowing follow-up
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.9,
            hitboxDelay = 0.15,
            hitboxDuration = 0.4,
            size = Vector3.new(6, 6, 9), -- Same as weapon config
            offset = Vector3.new(0, 0, 5.5),
            baseDamage = 9,
            name = "Katana Slash 2",
        },
        
        -- Attack 3: Iaijutsu finisher
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.2,
            hitboxDelay = 0.5,
            hitboxDuration = 0.4,
            size = Vector3.new(7, 6, 10), -- Longest reach finisher
            offset = Vector3.new(0, 0, 6),
            baseDamage = 16,
            name = "Iaijutsu Strike",
        },
    },

    -- Gladiator combo: Powerful, arena-style 3-hit combo with longest reach
    ["gladiator_weapon_combo"] = {
        comboWindow = 2.0,
        resetTime = 3.0,
        
        -- Attack 1: Arena opener
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.9,
            hitboxDelay = 0.3,
            hitboxDuration = 0.4,
            size = Vector3.new(6, 6, 10), -- Long reach
            offset = Vector3.new(0, 0, 5.5),
            baseDamage = 9,
            name = "Spear Thrust 1",
        },
        
        -- Attack 2: Arena follow-up
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.0,
            hitboxDelay = 0.25,
            hitboxDuration = 0.5,
            size = Vector3.new(7, 6, 11), -- Same as weapon config
            offset = Vector3.new(0, 0, 6.5),
            baseDamage = 10,
            name = "Spear Thrust 2",
        },
        
        -- Attack 3: Arena champion finisher
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.3,
            hitboxDelay = 0.5,
            hitboxDuration = 0.6,
            size = Vector3.new(8, 6, 12), -- Widest and longest finisher
            offset = Vector3.new(0, 0, 7),
            baseDamage = 18,
            name = "Arena Strike",
        },
    },
}

-- Get combo configuration for a specific weapon tag
function HitboxConfig.getComboConfig(weaponTag)
    local comboKey = weaponTag .. "_combo"
    local config = COMBO_CONFIGS[comboKey]
    if config then
        return {
            comboWindow = config.comboWindow,
            resetTime = config.resetTime,
            attack1 = {
                animationId = config.attack1.animationId,
                duration = config.attack1.duration,
                hitboxDelay = config.attack1.hitboxDelay,
                hitboxDuration = config.attack1.hitboxDuration,
                size = config.attack1.size,
                offset = config.attack1.offset,
                baseDamage = config.attack1.baseDamage,
                name = config.attack1.name,
            },
            attack2 = {
                animationId = config.attack2.animationId,
                duration = config.attack2.duration,
                hitboxDelay = config.attack2.hitboxDelay,
                hitboxDuration = config.attack2.hitboxDuration,
                size = config.attack2.size,
                offset = config.attack2.offset,
                baseDamage = config.attack2.baseDamage,
                name = config.attack2.name,
            },
            attack3 = {
                animationId = config.attack3.animationId,
                duration = config.attack3.duration,
                hitboxDelay = config.attack3.hitboxDelay,
                hitboxDuration = config.attack3.hitboxDuration,
                size = config.attack3.size,
                offset = config.attack3.offset,
                baseDamage = config.attack3.baseDamage,
                name = config.attack3.name,
            },
        }
    end
    
    -- Return default combo if weapon tag not found
    return {
        comboWindow = 2.0,
        resetTime = 3.0,
        attack1 = {
            animationId = "rbxassetid://116519685012277",
            duration = 0.8,
            hitboxDelay = 0.3,
            hitboxDuration = 0.4,
            size = Vector3.new(5, 5, 3),
            offset = Vector3.new(0, 0, 1.5),
            baseDamage = 8,
            name = "Default Strike 1",
        },
        attack2 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.0,
            hitboxDelay = 0.2,
            hitboxDuration = 0.5,
            size = Vector3.new(6, 5, 4),
            offset = Vector3.new(0, 0, 2),
            baseDamage = 10,
            name = "Default Strike 2",
        },
        attack3 = {
            animationId = "rbxassetid://116519685012277",
            duration = 1.2,
            hitboxDelay = 0.4,
            hitboxDuration = 0.6,
            size = Vector3.new(7, 6, 5),
            offset = Vector3.new(0, 0, 2.5),
            baseDamage = 15,
            name = "Default Finisher",
        },
    }
end

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
            -- Timing configuration
            cooldownTime = config.cooldownTime or 2.0, -- Default 2s cooldown
            castTime = config.castTime or 0.8, -- Default 0.8s cast time
            hitboxDelay = config.hitboxDelay or 0.3, -- Default 0.3s hitbox delay
            hitboxDuration = config.hitboxDuration or 0.5, -- Default 0.5s hitbox duration
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
        -- Default timing configuration
        cooldownTime = 2.0,
        castTime = 0.8,
        hitboxDelay = 0.3,
        hitboxDuration = 0.5,
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

-- Get damage interval configuration
function HitboxConfig.getDamageIntervalConfig()
    return {
        hitboxDamageInterval = DAMAGE_INTERVAL_CONFIG.hitboxDamageInterval,
        immunityBuffer = DAMAGE_INTERVAL_CONFIG.immunityBuffer,
    }
end

-- Get damage interval value (convenience function)
function HitboxConfig.getDamageInterval()
    return DAMAGE_INTERVAL_CONFIG.hitboxDamageInterval
end

-- Get projectile configuration for a specific weapon tag
function HitboxConfig.getProjectileConfig(weaponTag)
    local config = PROJECTILE_CONFIGS[weaponTag]
    if config then
        return {
            projectileType = config.projectileType,
            speed = config.speed,
            range = config.range,
            size = config.size,
            color = config.color,
            transparency = config.transparency,
            material = config.material,
            hitboxSize = config.hitboxSize,
            hitboxDuration = config.hitboxDuration,
            trailEffect = config.trailEffect,
            trailLength = config.trailLength,
            trailTransparency = config.trailTransparency,
        }
    end
    
    -- Return default projectile config if weapon tag not found
    return {
        projectileType = "arrow",
        speed = 200,
        range = 100,
        size = Vector3.new(0.5, 0.5, 3),
        color = Color3.new(1, 1, 1),
        transparency = 0.5,
        material = Enum.Material.Neon,
        hitboxSize = Vector3.new(2, 2, 2),
        hitboxDuration = 0.2,
        trailEffect = false,
        trailLength = 3,
        trailTransparency = 0.8,
    }
end

-- Get all available projectile weapon tags
function HitboxConfig.getAllProjectileWeaponTags()
    local tags = {}
    for tag, _ in pairs(PROJECTILE_CONFIGS) do
        table.insert(tags, tag)
    end
    return tags
end

-- Check if a weapon tag has projectile configuration
function HitboxConfig.hasProjectileConfig(weaponTag)
    return PROJECTILE_CONFIGS[weaponTag] ~= nil
end

-- Get default projectile configuration
function HitboxConfig.getDefaultProjectileConfig()
    return {
        projectileType = "arrow",
        speed = 200,
        range = 100,
        size = Vector3.new(0.5, 0.5, 3),
        color = Color3.new(1, 1, 1),
        transparency = 0.5,
        material = Enum.Material.Neon,
        hitboxSize = Vector3.new(2, 2, 2),
        hitboxDuration = 0.2,
        trailEffect = false,
        trailLength = 3,
        trailTransparency = 0.8,
    }
end

-- Calculate DOT info for sustained hitboxes (simple: full damage every interval)
function HitboxConfig.calculateDamagePerTick(baseDamage, hitboxDuration)
    local interval = DAMAGE_INTERVAL_CONFIG.hitboxDamageInterval
    local maxTicks = math.floor(hitboxDuration / interval) + 1 -- +1 for immediate first tick
    
    
    return {
        damagePerTick = baseDamage, -- Full base damage every tick
        maxTicks = maxTicks,
        interval = interval,
        duration = hitboxDuration
    }
end

-- Test function to verify DOT calculations
function HitboxConfig.testDOTCalculations()
    
    -- Test berserker combo attacks
    local combo = HitboxConfig.getComboConfig("berserker_weapon")
    if combo then
        
        local result1 = HitboxConfig.calculateDamagePerTick(combo.attack1.baseDamage, combo.attack1.hitboxDuration)
        
        local result2 = HitboxConfig.calculateDamagePerTick(combo.attack2.baseDamage, combo.attack2.hitboxDuration)
        
        local result3 = HitboxConfig.calculateDamagePerTick(combo.attack3.baseDamage, combo.attack3.hitboxDuration)
    end
    
    -- Test berserker skills
    local skill1 = HitboxConfig.getSkillConfig("berserker_skill_1")
    if skill1 then
        HitboxConfig.calculateDamagePerTick(skill1.baseDamage, skill1.hitboxDuration)
    end
    
    local skill2 = HitboxConfig.getSkillConfig("berserker_skill_2")
    if skill2 then
        HitboxConfig.calculateDamagePerTick(skill2.baseDamage, skill2.hitboxDuration)
    end
end

-- Debug function to print all configurations (for development use)
function HitboxConfig.printAllConfigs()
    
    for tag, config in pairs(WEAPON_CONFIGS) do
    end
    
    for tag, config in pairs(SKILL_CONFIGS) do
    end
end

return HitboxConfig
