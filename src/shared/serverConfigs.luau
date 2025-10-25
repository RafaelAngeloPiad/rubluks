-- ========================================
-- SERVER CONFIGURATION MODULE
-- Centralized configuration for all server-side settings
-- ========================================

local ServerConfigs = {}

-- ========================================
-- GLOBAL HITBOX CONFIGURATION
-- ========================================

ServerConfigs.Hitbox = {
	transparency = 0.8, -- Global transparency for all hitbox visuals
}

-- ========================================
-- ANIMATION SPEED CONFIGURATIONS
-- ========================================

-- Archer Animation Speeds
ServerConfigs.Archer = {
	AnimationSpeeds = {
		-- Basic movements
		idle = 1.0,
		run = 1.0,
		jump = 1.0,
		
		-- Walking speeds (fixed values, not affected by animation speed)
		walking = {
			normal = 18,    -- Fixed normal walking speed
			slow = 3,       -- Fixed speed during skills
			blocking = 0    -- Fixed speed while blocking
		},
		
		-- Attack animations (archer uses single attack system)
		normalAttack = 1.0,    -- Single normal attack (replaces combo1)
		jumpAttack = 1.0,
		block = 1.0,
		
		-- Skills
		piercingShot = 1.0,
		powerShot = 1.0,
		
		-- Buffs
		hunterInstinct = 1.0,
		hunterMark = 1.0,
		
		-- Ultimate
		starfall = 1.0
	},
	
	-- Archer Cooldowns
	Cooldowns = {
		-- Skills
		piercingShot = 5, -- 10 seconds cooldown
		powerShot = 5,     -- 8 seconds cooldown

		-- Buffs
		hunterInstinct = 5, -- 15 seconds cooldown
		hunterMark = 5,     -- 12 seconds cooldown

		-- Ultimate
		starfall = 5       -- 30 seconds cooldown (ultimate)
	},
	
	-- Archer Arrow Configuration
	ArrowVisualSpeed = 100,
	ArrowHitboxSpeed = 80, -- archerArrowVisualSpeed - 20
	
	ArrowHitbox = {
		delay = 0,           -- Delay before hitbox becomes active (seconds)
		size = Vector3.new(6, 6, 6),  -- Hitbox size for all arrows
		damage = 20,         -- Damage for all normal arrows
		visualSpeed = 100,   -- Visual arrow asset speed
		hitboxSpeed = 80,    -- Hitbox detection speed
		anchorDelay = 0.03,  -- Delay before arrow gets anchored/sticks after hit detection
		preventPhysicsPush = true  -- Prevent arrows from pushing objects around
	},
	
	-- Archer Arrow Spawn Offsets
	ArrowSpawnOffsets = {
		-- First-person mode: offset from camera center
		firstPerson = Vector3.new(0, 0, 2),    -- Forward offset from camera center
		-- Third-person mode: offset from player body
		thirdPerson = Vector3.new(1, 0, 1),    -- Offset from player body
	},
	
	-- Archer Trail Color Configuration (RGB values 0-255)
	ArrowTrailColor = {255, 255, 255} -- White by default
}

-- Samurai Animation Speeds
ServerConfigs.Samurai = {
	AnimationSpeeds = {
		-- Basic movements
		idle = 1.0,
		run = 1.0,
		jump = 1.0,
		
		-- Walking speeds (fixed values, not affected by animation speed)
		walking = {
			normal = 18,    -- Fixed normal walking speed
			slow = 3,       -- Fixed speed during skills (wakizashi/kozuki)
			blocking = 0    -- Fixed speed while blocking
		},
		
		-- Attack combos
		combo1 = 1.0,
		combo2 = 1.0,
		combo3 = 1.0,
		moveAttack = 1.0,
		jumpAttack = 1.0,
		block = 1.0,
		
		-- Skills
		kozuki = 1.0,
		wakizashi = 1.0,
		
		-- Buffs
		banzai = 1.0,
		bushido = 1.0,
		
		-- Ultimate
		zantetsuken = 1.0
	},
	
	-- Samurai Cooldowns
	Cooldowns = {
		-- Skills
		kozuki = 5,        -- 10 seconds cooldown
		wakizashi = 5,      -- 8 seconds cooldown
		
		-- Buffs
		banzai = 5,        -- 15 seconds cooldown
		bushido = 5,       -- 12 seconds cooldown
		
		-- Ultimate
		zantetsuken = 5    -- 30 seconds cooldown (ultimate)
	},
	
	-- Samurai Combo Configuration
	ComboConfig = {
		comboTimeout = 1, -- 1 second timeout for combo reset
		combo3Cooldown = 20, -- 3 second cooldown for 3rd attack
	},
	
	-- Samurai Trail Configuration
	TrailConfig = {
		-- Individual Trail Lifetime settings (in seconds)
		Lifetime = {
			trail1 = 0.13,      -- Trail1.Lifetime for all attacks
			trail2 = 0.1,      -- Trail2.Lifetime for all attacks
			trail3 = 0.08       -- Trail3.Lifetime for all attacks
		},
		-- Individual Trail Color settings (RGB values 0-255)
		Color = {
			trail1 = {255, 255, 255},  -- Trail1.Color (white)
			trail2 = {255, 255, 255},  -- Trail2.Color (white)
			trail3 = {255, 255, 255}   -- Trail3.Color (white)
		},
		-- Individual Trail FaceCamera settings (boolean)
		FaceCamera = {
			trail1 = true,      -- Trail1.FaceCamera
			trail2 = true,      -- Trail2.FaceCamera
			trail3 = true       -- Trail3.FaceCamera
		}
	}
}

-- Brawler Animation Speeds
ServerConfigs.Brawler = {
	AnimationSpeeds = {
		-- Basic movements
		idle = 1.0,
		run = 1.0,
		jump = 1.0,
		
		-- Walking speeds (fixed values, not affected by animation speed)
		walking = {
			normal = 18,    -- Fixed normal walking speed
			slow = 3,       -- Fixed speed during skills
			blocking = 0    -- Fixed speed while blocking
		},
		
		-- Attack combos (Brawler only has 2-hit combo)
		combo1 = 1.0,
		combo2 = 1.0,
		moveAttack = 1.0,
		jumpAttack = 1.0,
		block = 1.0,
		
		-- Skills
		feralleap = 1.0,
		brawlersroar = 1.0,
		
		-- Buffs
		bloodthirst = 1.0,
		lastchance = 1.0,
		
		-- Ultimate
		meteordive = 1.0
	},
	
	-- Brawler Cooldowns
	Cooldowns = {
		-- Skills
		feralleap = 5,
		brawlersroar = 5,
		
		-- Buffs
		bloodthirst = 5,
		lastchance = 5,
		
		-- Ultimate
		meteordive = 5
	},
	
	-- Brawler Combo Configuration
	ComboConfig = {
		comboTimeout = 1, -- 1 second timeout for combo reset (Brawler has only 2-hit combo)
	},
	
	-- Brawler Trail Configuration
	TrailConfig = {
		-- Individual Trail Lifetime settings (in seconds)
		Lifetime = {
			trail1 = 0.2,      -- Trail1.Lifetime for all attacks (Handle)
			trail2 = 0.2,       -- Trail2.Lifetime for all attacks (Handle)
			trail3 = 0.2,     -- Trail3.Lifetime for all attacks (Handle)
			trail4 = 0.2,      -- Trail1.Lifetime for all attacks (Shield)
			trail5 = 0.2,       -- Trail2.Lifetime for all attacks (Shield)
			trail6 = 0.2       -- Trail3.Lifetime for all attacks (Shield)
		},
		-- Individual Trail Color settings (RGB values 0-255)
		Color = {
			trail1 = {255, 255, 255},  -- Trail1.Color (white) - Handle
			trail2 = {255, 255, 255},  -- Trail2.Color (white) - Handle
			trail3 = {255, 255, 255},  -- Trail3.Color (white) - Handle
			trail4 = {255, 255, 255},  -- Trail1.Color (white) - Shield
			trail5 = {255, 255, 255},  -- Trail2.Color (white) - Shield
			trail6 = {255, 255, 255}   -- Trail3.Color (white) - Shield
		},
		-- Individual Trail FaceCamera settings (boolean)
		FaceCamera = {
			trail1 = true,      -- Trail1.FaceCamera - Handle
			trail2 = true,      -- Trail2.FaceCamera - Handle
			trail3 = true,      -- Trail3.FaceCamera - Handle
			trail4 = true,      -- Trail1.FaceCamera - Shield
			trail5 = true,      -- Trail2.FaceCamera - Shield
			trail6 = true       -- Trail3.FaceCamera - Shield
		}
	}
}

-- Knight Animation Speeds
ServerConfigs.Knight = {
	AnimationSpeeds = {
		-- Basic movements
		idle = 1.0,
		run = 1.0,
		jump = 1.0,
		
		-- Walking speeds (fixed values, not affected by animation speed)
		walking = {
			normal = 18,    -- Fixed normal walking speed
			slow = 3,       -- Fixed speed during skills (sworddance/cyclone_slash)
			blocking = 0    -- Fixed speed while blocking
		},
		
		-- Attack combos
		combo1 = 1.0,
		combo2 = 1.0,
		combo3 = 1.0,
		moveAttack = 1.0,
		jumpAttack = 1.0,
		block = 1.0,
		
		-- Skills
		sworddance = 1.0,
		cyclone_slash = 1.0,
		
		-- Buffs
		warcry = 1.0,
		warriormight = 1.0,
		
		-- Ultimate
		mightyblade = 1.0
	},
	
	-- Knight Cooldowns
	Cooldowns = {
		-- Skills
		sworddance = 5,        -- 10 seconds cooldown
		cyclone_slash = 5,     -- 8 seconds cooldown
		
		-- Buffs
		warcry = 5,            -- 15 seconds cooldown
		warriormight = 5,      -- 12 seconds cooldown
		
		-- Ultimate
		mightyblade = 5        -- 30 seconds cooldown (ultimate)
	},
	
	-- Knight Combo Configuration
	ComboConfig = {
		comboTimeout = 1, -- 1 second timeout for combo reset
		combo3Cooldown = 20, -- 3 second cooldown for 3rd attack
	},
	
	-- Knight Trail Configuration
	TrailConfig = {
		-- Individual Trail Lifetime settings (in seconds)
		Lifetime = {
			trail1 = 0.5,  -- First attack trail lifetime
			trail2 = 0.5,  -- Second attack trail lifetime
			trail3 = 0.5,  -- Third attack trail lifetime
		},
		Color = ColorSequence.new(Color3.new(0, 0, 1)), -- Blue trail color
		FaceCamera = true
	}
}

-- Gladiator Animation Speeds
ServerConfigs.Gladiator = {
	AnimationSpeeds = {
		-- Basic movements
		idle = 1.0,
		run = 1.0,
		jump = 1.0,
		
		-- Walking speeds (fixed values, not affected by animation speed)
		walking = {
			normal = 18,    -- Fixed normal walking speed
			slow = 3,       -- Fixed speed during skills
			blocking = 0    -- Fixed speed while blocking
		},
		
		-- Attack combos (Gladiator only has 2-hit combo)
		combo1 = 1.0,
		combo2 = 1.0,
		moveAttack = 1.0,
		jumpAttack = 1.0,
		block = 1.0,
		
		-- Skills
		shieldbash = 1.0,
		dragoonjump = 1.0,
		
		-- Buffs
		championsblood = 1.0,
		championscheer = 1.0,
		
		-- Ultimate
		demonicvorpaldance = 1.0
	},
	
	-- Gladiator Cooldowns
	Cooldowns = {
		-- Skills
		shieldbash = 5,
		dragoonjump = 5,
		
		-- Buffs
		championsblood = 5,
		championscheer = 5,
		
		-- Ultimate
		demonicvorpaldance = 5
	},
	
	-- Gladiator Combo Configuration
	ComboConfig = {
		comboTimeout = 1, -- 1 second timeout for combo reset (Gladiator has only 2-hit combo)
	},
	
	-- Gladiator Trail Configuration
	TrailConfig = {
		-- Individual Trail Lifetime settings (in seconds)
		Lifetime = {
			trail1 = 0.5,  -- First attack trail lifetime
			trail2 = 0.5,  -- Second attack trail lifetime
			trail3 = 0.5,  -- Third attack trail lifetime
		},
		Color = ColorSequence.new(Color3.new(1, 1, 0)), -- Yellow trail color
		FaceCamera = true
	}
}

-- ========================================
-- SKILL-SPECIFIC CONFIGURATIONS
-- ========================================

-- Archer Skills
ServerConfigs.ArcherSkills = {
	-- PowerShot Configuration
	PowerShot = {
		hitboxSize = Vector3.new(8, 8, 8),
		hitboxDamage = 40,
		hitboxDelay = 0.1,
		damageTickTime = 0.3, -- Damage every 0.3 seconds
	},
	
	-- PiercingShot Configuration
	PiercingShot = {
		hitboxSize = Vector3.new(6, 6, 6),
		hitboxDamage = 35,
		hitboxDelay = 0.1,
	},
	
	-- Starfall Ultimate Configuration
	Starfall = {
		hitboxSize = Vector3.new(15, 15, 15),
		hitboxDamage = 40,
		hitboxDelay = 0.2,
	}
}

-- Samurai Skills
ServerConfigs.SamuraiSkills = {
	-- Kozuki Configuration
	Kozuki = {
		hitboxSize = Vector3.new(10, 10, 10),
		hitboxDamage = 30,
		hitboxDelay = 0.1,
	},
	
	-- Wakizashi Configuration
	Wakizashi = {
		hitboxSize = Vector3.new(8, 8, 8),
		hitboxDamage = 25,
		hitboxDelay = 0.1,
	},
	
	-- Zantetsuken Ultimate Configuration
	Zantetsuken = {
		hitboxSize = Vector3.new(20, 20, 20),
		hitboxDamage = 50,
		hitboxDelay = 0.2,
	}
}

-- Brawler Skills
ServerConfigs.BrawlerSkills = {
	-- FeralLeap Configuration
	FeralLeap = {
		hitboxSize = Vector3.new(70, 70, 70), -- Hitbox size for claw mark
		hitboxDamage = 35, -- Damage on landing
		hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
	},
	
	-- BrawlersRoar Configuration
	BrawlersRoar = {
		hitboxSize = Vector3.new(25, 25, 25), -- Hitbox size for roar
		hitboxDamage = 20, -- Damage per hit
		hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
	},
	
	-- MeteorDive Ultimate Configuration
	MeteorDive = {
		explosionHitboxSize = Vector3.new(40, 40, 40), -- Hitbox size for meteor explosion
		explosionHitboxDamage = 50, -- Damage on meteor impact
		hitboxDelay = 0.2, -- Delay before hitbox activates (in seconds)
		damageTickTime = 0.5, -- Damage every 0.5 seconds
	}
}

-- Knight Skills
ServerConfigs.KnightSkills = {
	-- SwordDance Configuration
	SwordDance = {
		swordHitboxSize = Vector3.new(12, 50, 12), -- Hitbox size (wider horizontally: width, HEIGHT, depth)
		swordHitboxDamage = 30, -- Damage per sword hit
		swordHitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
	},
	
	-- CycloneSlash Configuration
	CycloneSlash = {
		smallHitboxDuration = 1.0, -- How long to use small hitbox before switching to big (in seconds)
		smallHitboxSize = Vector3.new(8, 8, 8),
		smallHitboxDamage = 15,
		smallHitboxDelay = 0.1,
		bigHitboxSize = Vector3.new(20, 20, 20),
		bigHitboxDamage = 25,
		bigHitboxDelay = 0.1,
		damageTickTime = 0.4, -- For small hitbox
		bigDamageTickTime = 0.3, -- For big hitbox
	},
	
	-- MightyBlade Ultimate Configuration
	MightyBlade = {
		hitboxSize = Vector3.new(15, 15, 15),
		hitboxDamage = 40,
		hitboxDelay = 0.2,
	}
}

-- Gladiator Skills
ServerConfigs.GladiatorSkills = {
	-- ShieldBash Configuration
	ShieldBash = {
		hitboxSize = Vector3.new(15, 15, 15), -- Hitbox size
		hitboxDamage = 25, -- Damage per hit
		hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
	},
	
	-- DragoonJump Configuration
	DragoonJump = {
		hitboxSize = Vector3.new(20, 20, 20), -- Hitbox size for each explosion
		hitboxDamage = 15, -- Damage per explosion hit
		hitboxDelay = 1, -- Delay before hitbox activates (in seconds) - synced with explosion VFX
	},
	
	-- DemonicVorpalDance Ultimate Configuration
	DemonicVorpalDance = {
		nearHitboxSize = Vector3.new(35, 35, 35), -- Hitbox size for near explosions (wider to cover center)
		farHitboxSize = Vector3.new(40, 40, 40), -- Hitbox size for far explosions (wider to cover center)
		nearHitboxDamage = 20, -- Damage per near explosion
		farHitboxDamage = 25, -- Damage per far explosion
		hitboxDelay = 0.1, -- Delay before hitbox activates (in seconds)
		damageTickTime = 0.5, -- Damage every 0.5 seconds
	}
}

-- ========================================
-- GLOBAL HITBOX CONFIGURATIONS
-- ========================================

ServerConfigs.Hitboxes = {
	-- Normal Attack Hitboxes
	NormalAttacks = {
		combo1 = {
			offset = CFrame.new(0, 0, -3),
			size = Vector3.new(12, 12, 9),
			damage = 8,
			delay = 0,
			visualColor = Color3.new(1, 0.8, 0)
		},
		combo2 = {
			offset = CFrame.new(0, 0, -4),
			size = Vector3.new(15, 15, 12),
			damage = 12,
			delay = 0,
			visualColor = Color3.new(0.8, 0.2, 1)
		},
		combo3 = {
			offset = CFrame.new(0, 0, -5),
			size = Vector3.new(25, 25, 25),
			damage = 20,
			delay = 2, -- Base delay (auto-scales with animation speed)
			visualColor = Color3.new(1, 0, 0)
		},
		moveAttack = {
			offset = CFrame.new(0, 0, -10),
			size = Vector3.new(18, 18, 18),
			damage = 15,
			delay = 0.4, -- Base delay (auto-scales with animation speed)
			visualColor = Color3.new(0, 0.8, 1)
		},
		jumpAttack = {
			offset = CFrame.new(0, -5, -10),
			size = Vector3.new(8, 20, 15),
			damage = 12,
			delay = 0,
			visualColor = Color3.new(0, 1, 0)
		},
		block = {
			offset = CFrame.new(0, 0, -2),
			size = Vector3.new(6, 6, 4),
			damage = 8,
			delay = 0,
			visualColor = Color3.new(0.5, 0.5, 0.5)
		}
	},
	
	-- DOT (Damage Over Time) Configuration
	DOT = {
		defaultTickTime = 0.5, -- Default damage tick time in seconds
	},
	
	-- Hitbox Defaults
	Defaults = {
		defaultSize = Vector3.new(8, 8, 8),
		defaultDelay = 0.1,
		defaultDamage = 20,
		defaultOffset = CFrame.new(0, 0, -5),
		defaultVisualColor = Color3.new(1, 0, 0)
	}
}

-- ========================================
-- GLOBAL DAMAGE CONFIGURATIONS
-- ========================================

ServerConfigs.Damage = {
	-- Normal Attack Damages (legacy - use Hitboxes.NormalAttacks instead)
	NormalAttacks = {
		combo1 = 12,
		combo2 = 15,
		combo3 = 20,
		moveAttack = 12,
		jumpAttack = 15,
		block = 8,
	},
	
	-- DOT (Damage Over Time) Configuration
	DOT = {
		defaultTickTime = 0.5, -- Default damage tick time in seconds
	}
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function to get scaled delay based on animation speed
function ServerConfigs.getScaledDelay(baseDelay, actionType, classType)
	if not baseDelay or baseDelay == 0 then
		return 0
	end
	
	local animationSpeed = 1.0 -- Default speed
	
	-- Get specific animation speed for the action type and class
	if classType and ServerConfigs[classType] and ServerConfigs[classType].AnimationSpeeds then
		animationSpeed = ServerConfigs[classType].AnimationSpeeds[actionType] or 1.0
	end
	
	-- Scale delay inversely with animation speed
	-- If animation is 2x faster, delays should be 0.5x (half the time)
	-- If animation is 0.5x slower, delays should be 2x (double the time)
	return baseDelay / animationSpeed
end

-- Function to get class-specific configuration
function ServerConfigs.getClassConfig(classType)
	return ServerConfigs[classType] or {}
end

-- Function to get skill-specific configuration
function ServerConfigs.getSkillConfig(classType, skillName)
	local classSkills = ServerConfigs[classType .. "Skills"]
	if classSkills then
		return classSkills[skillName] or {}
	end
	return {}
end

-- Function to get hitbox configuration for normal attacks
function ServerConfigs.getHitboxConfig(attackType)
	return ServerConfigs.Hitboxes.NormalAttacks[attackType] or ServerConfigs.Hitboxes.Defaults
end

-- Function to get hitbox configuration with defaults
function ServerConfigs.getHitboxConfigWithDefaults(attackType, customConfig)
	local baseConfig = ServerConfigs.getHitboxConfig(attackType)
	local defaults = ServerConfigs.Hitboxes.Defaults
	
	return {
		offset = customConfig and customConfig.offset or baseConfig.offset or defaults.defaultOffset,
		size = customConfig and customConfig.size or baseConfig.size or defaults.defaultSize,
		damage = customConfig and customConfig.damage or baseConfig.damage or defaults.defaultDamage,
		delay = customConfig and customConfig.delay or baseConfig.delay or defaults.defaultDelay,
		visualColor = customConfig and customConfig.visualColor or baseConfig.visualColor or defaults.defaultVisualColor
	}
end

return ServerConfigs
