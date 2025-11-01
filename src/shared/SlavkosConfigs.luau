-- ========================================
-- SERVER CONFIGURATION MODULE
-- Centralized configuration for all server-side settings
-- ========================================

local ServerConfigs = {}

-- ========================================
-- GLOBAL HITBOX CONFIGURATION
-- ========================================

ServerConfigs.Hitbox = {
	transparency = 1, -- Global transparency for all hitbox visuals
	
		-- Highlighting Configuration
		highlighting = {
			-- Damage flash effect settings (same for all hitbox types)
			damageFlash = {
				fillColor = Color3.new(1, 0, 0), -- Bright red
				fillTransparency = 0.95, -- Slightly transparent
				outlineColor = Color3.new(1, 0, 0), -- Red outline
				outlineTransparency = 0, -- Solid outline
				duration = 0.1 -- Flash duration in seconds
			}
		},
		
		-- Damage Numbers Configuration
		damageNumbers = {
			enabled = true, -- Enable/disable damage numbers
			font = Enum.Font.GothamBold, -- Font style
			textSize = 36, -- Text size
			textColor = Color3.new(1, 0.8, 0), -- Orange/yellow color
			backgroundColor = Color3.new(0, 0, 0), -- Black background
			backgroundTransparency = 0.5, -- Background transparency
			strokeColor = Color3.new(0, 0, 0), -- Black stroke
			strokeTransparency = 0, -- Solid stroke
			duration = 1.5, -- How long the number stays visible (seconds)
			riseHeight = 3, -- How high the number rises (studs)
			riseSpeed = 2, -- Speed at which number rises (studs per second)
			fadeStart = 0.5, -- When to start fading (after this many seconds)
			offsetY = 2, -- Vertical offset from character head (studs)
			randomOffsetX = 1, -- Random horizontal offset range (studs)
		},
		
		-- Knockback Configuration
		knockback = {
			enabled = false, -- Enable/disable knockback
			force = 20 -- Knockback force (velocity applied to mob)
		}
}

-- ========================================
-- GLOBAL HITBOX CONFIGURATIONS
-- ========================================

ServerConfigs.Hitboxes = {
	-- DOT (Damage Over Time) Configuration
	DOT = {
		defaultTickTime = 0.5, -- Default damage tick time in seconds
	},
	
	-- Unified Non-Skill Attack Configurations (separate per class)
	UnifiedAttacks = {
		Archer = {
			offset = CFrame.new(0, 0, -2),
			size = Vector3.new(6, 6, 6),
			damage = 0.2,                -- 20% of MaxAttack (base: 100 ATK = 20 damage)
			skill1Damage = 0.35,         -- 35% of MaxAttack (base: 100 ATK = 35 damage) - PiercingShot
			skill2Damage = 0.4,          -- 40% of MaxAttack (base: 100 ATK = 40 damage) - PowerShot
			skill2TickTime = 1,        -- PowerShot DOT tick time
			ultDamage = 0.1,             -- 10% of MaxAttack (base: 100 ATK = 10 damage) - Starfall
			ultTickTime = 0.5,           -- Starfall DOT tick time
			-- Arrow projectile configuration
			arrowDelay = 0,              -- Delay before arrow hitbox becomes active (seconds)
			arrowVisualSpeed = 100,      -- Visual arrow asset speed
			arrowHitboxSpeed = 80,       -- Arrow hitbox detection speed (visualSpeed - 20)
			arrowAnchorDelay = 0.03,     -- Delay before arrow gets anchored/sticks after hit detection
			arrowPreventPhysicsPush = true,  -- Prevent arrows from pushing objects around
			-- Arrow spawn offsets
			arrowSpawnOffsets = {
				firstPerson = Vector3.new(0, 0, 2),    -- Forward offset from camera center
				thirdPerson = Vector3.new(1, 0, 1),    -- Offset from player body
			},
			-- Arrow trail color (RGB 0-255)
			arrowTrailColor = {255, 255, 255},  -- White
			-- Animation speeds
			animSpeed = {
				idle = 1.0,
				run = 1.0,
				jump = 1.0,
				normalAttack = 1.0,
				jumpAttack = 1.0,
				block = 1.0,
				piercingShot = 1.0,
				powerShot = 1.0,
				hunterInstinct = 1.0,
				hunterMark = 1.0,
				starfall = 1.0,
				-- Walking speeds (fixed values, not affected by animation speed)
				walking = {
					normal = 18,    -- Fixed normal walking speed
					slow = 3,       -- Fixed speed during skills
					blocking = 0    -- Fixed speed while blocking
				}
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 3,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking
			},
			-- Cooldowns
			cooldowns = {
				piercingShot = 5,
				powerShot = 5,
				hunterInstinct = 5,
				hunterMark = 5,
				starfall = 5
			},
			-- Skill-specific hitbox configurations
			skills = {
				piercingShot = {
					hitboxSize = Vector3.new(10, 10, 10),
					hitboxDelay = 0
				},
				powerShot = {
					hitboxSize = Vector3.new(10, 10, 10),
					hitboxDelay = 0
				},
				starfall = {
					hitboxSize = Vector3.new(250, 60, 250),
					hitboxDelay = 0.2
				}
			}
		},
		Samurai = {
			offset = CFrame.new(0, 0, -5),
			size = Vector3.new(15, 15, 12),
			damage = 0.24,                -- 24% of MaxAttack (base: 50 ATK = 12 damage)
			skill1Damage = 0.5,           -- 50% of MaxAttack (base: 50 ATK = 25 damage) - Wakizashi
			skill2Damage = 0.6,           -- 60% of MaxAttack (base: 50 ATK = 30 damage) - Kozuki
			ultDamage = 1.0,              -- 100% of MaxAttack (base: 50 ATK = 50 damage) - Zantetsuken
			-- Animation speeds
			animSpeed = {
				idle = 1.0,
				run = 1.0,
				jump = 1.0,
				combo1 = 1.0,
				combo2 = 1.0,
				combo3 = 1.0,
				moveAttack = 1.0,
				jumpAttack = 1.0,
				block = 1.0,
				kozuki = 1.0,
				wakizashi = 1.0,
				banzai = 1.0,
				bushido = 1.0,
				zantetsuken = 1.0,
				-- Walking speeds (fixed values, not affected by animation speed)
				walking = {
					normal = 18,    -- Fixed normal walking speed
					slow = 3,       -- Fixed speed during skills (wakizashi/kozuki)
					blocking = 0    -- Fixed speed while blocking
				}
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 3,       -- Fixed speed during skills (wakizashi/kozuki)
				blocking = 0    -- Fixed speed while blocking
			},
			-- Cooldowns
			cooldowns = {
				kozuki = 5,
				wakizashi = 5,
				banzai = 5,
				bushido = 5,
				zantetsuken = 5
			},
			-- Combo configuration
			comboTimeout = 1,        -- 1 second timeout for combo reset
			combo3Cooldown = 20,     -- 3 second cooldown for 3rd attack
			-- Trail configuration
			trailLifetime = {
				trail1 = 0.13,
				trail2 = 0.1,
				trail3 = 0.08
			},
			trailColor = {
				trail1 = {255, 255, 255},  -- White
				trail2 = {255, 255, 255},  -- White
				trail3 = {255, 255, 255}   -- White
			},
			trailFaceCamera = {
				trail1 = true,
				trail2 = true,
				trail3 = true
			},
			-- Skill-specific hitbox configurations
			skills = {
				kozuki = {
					hitboxSize = Vector3.new(10, 10, 10),
					hitboxDelay = 0.1
				},
				wakizashi = {
					hitboxSize = Vector3.new(8, 8, 8),
					hitboxDelay = 0.1
				},
				zantetsuken = {
					hitboxSize = Vector3.new(20, 20, 20),
					hitboxDelay = 0.2
				}
			}
		},
		Brawler = {
			offset = CFrame.new(0, 0, -5),
			size = Vector3.new(15, 15, 12),
			damage = 0.133,              -- 13.3% of MaxAttack (base: 90 ATK = 12 damage)
			skill1Damage = 0.222,        -- 22.2% of MaxAttack (base: 90 ATK = 20 damage) - BrawlersRoar
			skill2Damage = 0.389,        -- 38.9% of MaxAttack (base: 90 ATK = 35 damage) - FeralLeap
			ultDamage = 0.089,           -- 8.9% of MaxAttack (base: 90 ATK = 8 damage) - MeteorDive
			ultTickTime = 0.5,           -- MeteorDive DOT tick time
			-- Animation speeds
			animSpeed = {
				idle = 1.0,
				run = 1.0,
				jump = 1.0,
				combo1 = 1.0,
				combo2 = 1.0,
				moveAttack = 1.0,
				jumpAttack = 1.0,
				block = 1.0,
				feralleap = 1.0,
				brawlersroar = 1.0,
				bloodthirst = 1.0,
				lastchance = 1.0,
				meteordive = 1.0,
				-- Walking speeds (fixed values, not affected by animation speed)
				walking = {
					normal = 18,    -- Fixed normal walking speed
					slow = 3,       -- Fixed speed during skills
					blocking = 0    -- Fixed speed while blocking
				}
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 3,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking
			},
			-- Cooldowns
			cooldowns = {
				feralleap = 5,
				brawlersroar = 5,
				bloodthirst = 5,
				lastchance = 5,
				meteordive = 5
			},
			-- Combo configuration
			comboTimeout = 1,        -- 1 second timeout for combo reset (Brawler has only 2-hit combo)
			-- Trail configuration
			trailLifetime = {
				trail1 = 0.2,      -- Handle
				trail2 = 0.2,      -- Handle
				trail3 = 0.2,      -- Handle
				trail4 = 0.2,      -- Shield
				trail5 = 0.2,      -- Shield
				trail6 = 0.2       -- Shield
			},
			trailColor = {
				trail1 = {255, 255, 255},  -- Handle - White
				trail2 = {255, 255, 255},  -- Handle - White
				trail3 = {255, 255, 255},  -- Handle - White
				trail4 = {255, 255, 255},  -- Shield - White
				trail5 = {255, 255, 255},  -- Shield - White
				trail6 = {255, 255, 255}   -- Shield - White
			},
			trailFaceCamera = {
				trail1 = true,      -- Handle
				trail2 = true,      -- Handle
				trail3 = true,      -- Handle
				trail4 = true,      -- Shield
				trail5 = true,      -- Shield
				trail6 = true       -- Shield
			},
			-- Skill-specific hitbox configurations
			skills = {
				feralleap = {
					hitboxSize = Vector3.new(70, 70, 70),
					hitboxDelay = 0.1
				},
				brawlersroar = {
					hitboxSize = Vector3.new(25, 25, 25),
					hitboxDelay = 0.1
				},
				meteordive = {
					hitboxSize = Vector3.new(250, 60, 250),
					hitboxDelay = 0.2
				}
			}
		},
		Knight = {
			offset = CFrame.new(0, 0, -5),
			size = Vector3.new(15, 15, 12),
			damage = 0.171,               -- 17.1% of MaxAttack (base: 70 ATK = 12 damage)
			skill1Damage = 0.429,        -- 42.9% of MaxAttack (base: 70 ATK = 30 damage) - SwordDance
			skill2Damage = 0.357,        -- 35.7% of MaxAttack (base: 70 ATK = 25 damage) - CycloneSlash
			skill2TickTime = 0.4,        -- CycloneSlash hitbox tick time
			ultDamage = 0.143,           -- 14.3% of MaxAttack (base: 70 ATK = 10 damage) - MightyBlade
			ultTickTime = 0.5,           -- MightyBlade DOT tick time
			-- Animation speeds
			animSpeed = {
				idle = 1.0,
				run = 1.0,
				jump = 1.0,
				combo1 = 1.0,
				combo2 = 1.0,
				combo3 = 1.0,
				moveAttack = 1.0,
				jumpAttack = 1.0,
				block = 1.0,
				sworddance = 1.0,
				cyclone_slash = 1.0,
				warcry = 1.0,
				warriormight = 1.0,
				mightyblade = 1.0,
				-- Walking speeds (fixed values, not affected by animation speed)
				walking = {
					normal = 18,    -- Fixed normal walking speed
					slow = 3,       -- Fixed speed during skills (sworddance/cyclone_slash)
					blocking = 0    -- Fixed speed while blocking
				}
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 3,       -- Fixed speed during skills (sworddance/cyclone_slash)
				blocking = 0    -- Fixed speed while blocking
			},
			-- Cooldowns
			cooldowns = {
				sworddance = 5,
				cyclone_slash = 5,
				warcry = 5,
				warriormight = 5,
				mightyblade = 5
			},
			-- Combo configuration
			comboTimeout = 1,        -- 1 second timeout for combo reset
			combo3Cooldown = 20,     -- 3 second cooldown for 3rd attack
			-- Trail configuration
			trailLifetime = {
				trail1 = 0.5,
				trail2 = 0.5,
				trail3 = 0.5
			},
			trailColor = {
				trail1 = {255, 255, 255},  -- White
				trail2 = {255, 255, 255},  -- White
				trail3 = {255, 255, 255}   -- White
			},
			trailFaceCamera = {
				trail1 = true,
				trail2 = true,
				trail3 = true
			},
			-- Skill-specific hitbox configurations
			skills = {
				sworddance = {
					swordHitboxSize = Vector3.new(12, 50, 12),
					swordHitboxDelay = 0.1
				},
				cycloneslash = {
					smallHitboxDuration = 1.0,
					smallHitboxSize = Vector3.new(8, 8, 8),
					smallHitboxDelay = 0.1,
					bigHitboxSize = Vector3.new(20, 20, 20),
					bigHitboxDelay = 0.1
				},
				mightyblade = {
					hitboxSize = Vector3.new(250, 60, 250),
					hitboxDelay = 0.2
				}
			}
		},
		Gladiator = {
			offset = CFrame.new(0, 0, -5),
			size = Vector3.new(15, 15, 12),
			damage = 0.4,                -- 40% of MaxAttack (base: 30 ATK = 12 damage)
			skill1Damage = 0.833,        -- 83.3% of MaxAttack (base: 30 ATK = 25 damage) - ShieldBash
			skill2Damage = 0.5,          -- 50% of MaxAttack (base: 30 ATK = 15 damage) - DragoonJump
			ultDamage = 0.167,           -- 16.7% of MaxAttack (base: 30 ATK = 5 damage) - DemonicVorpalDance
			ultTickTime = 0.5,           -- DemonicVorpalDance DOT tick time
			-- Animation speeds
			animSpeed = {
				idle = 1.0,
				run = 1.0,
				jump = 1.0,
				combo1 = 1.0,
				combo2 = 1.0,
				moveAttack = 1.0,
				jumpAttack = 1.0,
				block = 1.0,
				shieldbash = 1.0,
				dragoonjump = 1.0,
				championsblood = 1.0,
				championscheer = 1.0,
				demonicvorpaldance = 1.0,
				-- Walking speeds (fixed values, not affected by animation speed)
				walking = {
					normal = 18,    -- Fixed normal walking speed
					slow = 3,       -- Fixed speed during skills
					blocking = 0    -- Fixed speed while blocking
				}
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 3,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking
			},
			-- Cooldowns
			cooldowns = {
				shieldbash = 5,
				dragoonjump = 5,
				championsblood = 5,
				championscheer = 5,
				demonicvorpaldance = 5
			},
			-- Combo configuration
			comboTimeout = 1,        -- 1 second timeout for combo reset (Gladiator has only 2-hit combo)
			-- Trail configuration
			trailLifetime = {
				trail1 = 0.5,
				trail2 = 0.5,
				trail3 = 0.5
			},
			trailColor = {
				trail1 = {255, 255, 255},  -- White
				trail2 = {255, 255, 255},  -- White
				trail3 = {255, 255, 255}   -- White
			},
			trailFaceCamera = {
				trail1 = true,
				trail2 = true,
				trail3 = true
			},
			-- Skill-specific hitbox configurations
			skills = {
				shieldbash = {
					hitboxSize = Vector3.new(15, 15, 15),
					hitboxDelay = 0.1
				},
				dragoonjump = {
					hitboxSize = Vector3.new(20, 20, 20),
					hitboxDelay = 1
				},
				demonicvorpaldance = {
					hitboxSize = Vector3.new(250, 60, 250),
					hitboxDelay = 0.2
				}
			}
		}
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
-- ANIMATION SPEED CONFIGURATIONS
-- ========================================

-- Archer Configuration (references UnifiedAttacks.Archer)
ServerConfigs.Archer = {
	AnimationSpeeds = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.animSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.walkingSpeed,
	
	-- Archer Arrow Configuration (references UnifiedAttacks.Archer)
	-- Note: damage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
	ArrowHitbox = {
		delay = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowDelay,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.size,
		damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.damage, -- Multiplier: 0.2
		visualSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowVisualSpeed,
		hitboxSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowHitboxSpeed,
		anchorDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowAnchorDelay,
		preventPhysicsPush = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowPreventPhysicsPush
	},
	
	-- Archer Arrow Spawn Offsets (references UnifiedAttacks.Archer)
	ArrowSpawnOffsets = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowSpawnOffsets,
	
	-- Archer Trail Color Configuration (references UnifiedAttacks.Archer)
	ArrowTrailColor = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowTrailColor
}

-- Samurai Configuration (references UnifiedAttacks.Samurai)
ServerConfigs.Samurai = {
	AnimationSpeeds = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.animSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.walkingSpeed,
	ComboConfig = {
		comboTimeout = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.comboTimeout,
		combo3Cooldown = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.combo3Cooldown
	},
	TrailConfig = {
		Lifetime = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.trailLifetime,
		Color = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.trailColor,
		FaceCamera = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.trailFaceCamera
	}
}

-- Brawler Configuration (references UnifiedAttacks.Brawler)
ServerConfigs.Brawler = {
	AnimationSpeeds = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.animSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.walkingSpeed,
	ComboConfig = {
		comboTimeout = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.comboTimeout
	},
	TrailConfig = {
		Lifetime = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.trailLifetime,
		Color = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.trailColor,
		FaceCamera = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.trailFaceCamera
	}
}

-- Knight Configuration (references UnifiedAttacks.Knight)
ServerConfigs.Knight = {
	AnimationSpeeds = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.animSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.walkingSpeed,
	ComboConfig = {
		comboTimeout = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.comboTimeout,
		combo3Cooldown = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.combo3Cooldown
	},
	TrailConfig = {
		Lifetime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.trailLifetime,
		Color = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.trailColor,
		FaceCamera = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.trailFaceCamera
	}
}

-- Gladiator Configuration (references UnifiedAttacks.Gladiator)
ServerConfigs.Gladiator = {
	AnimationSpeeds = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.animSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.walkingSpeed,
	ComboConfig = {
		comboTimeout = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.comboTimeout
	},
	TrailConfig = {
		Lifetime = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.trailLifetime,
		Color = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.trailColor,
		FaceCamera = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.trailFaceCamera
	}
}

-- ========================================
-- SKILL-SPECIFIC CONFIGURATIONS
-- ========================================

-- Archer Skills (references UnifiedAttacks.Archer)
ServerConfigs.ArcherSkills = {
	PowerShot = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skills.powerShot.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skill2Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skills.powerShot.hitboxDelay,
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skill2TickTime
	},
	PiercingShot = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skills.piercingShot.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skill1Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skills.piercingShot.hitboxDelay
	},
	Starfall = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skills.starfall.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.ultDamage,
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.ultTickTime,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.skills.starfall.hitboxDelay
	}
}

-- Samurai Skills (references UnifiedAttacks.Samurai)
-- Note: hitboxDamage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.SamuraiSkills = {
	Kozuki = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.kozuki.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skill2Damage, -- Multiplier: 0.6
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.kozuki.hitboxDelay
	},
	Wakizashi = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.wakizashi.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skill1Damage, -- Multiplier: 0.5
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.wakizashi.hitboxDelay
	},
	Zantetsuken = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.zantetsuken.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.ultDamage, -- Multiplier: 1.0
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.zantetsuken.hitboxDelay
	}
}

-- Brawler Skills (references UnifiedAttacks.Brawler)
-- Note: hitboxDamage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.BrawlerSkills = {
	FeralLeap = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.feralleap.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill2Damage, -- Multiplier: 0.389
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.feralleap.hitboxDelay
	},
	BrawlersRoar = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.brawlersroar.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill1Damage, -- Multiplier: 0.222
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.brawlersroar.hitboxDelay
	},
	MeteorDive = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.meteordive.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.ultDamage, -- Multiplier: 0.089
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.ultTickTime,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.meteordive.hitboxDelay
	}
}

-- Knight Skills (references UnifiedAttacks.Knight)
-- Note: hitboxDamage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.KnightSkills = {
	SwordDance = {
		swordHitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.sworddance.swordHitboxSize,
		swordHitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill1Damage, -- Multiplier: 0.429
		swordHitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.sworddance.swordHitboxDelay
	},
	CycloneSlash = {
		smallHitboxDuration = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.smallHitboxDuration,
		smallHitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.smallHitboxSize,
		smallHitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2Damage, -- Multiplier: 0.357
		smallHitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.smallHitboxDelay,
		bigHitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.bigHitboxSize,
		bigHitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2Damage, -- Multiplier: 0.357
		bigHitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.bigHitboxDelay,
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2TickTime,
		bigDamageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2TickTime
	},
	MightyBlade = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.mightyblade.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.ultDamage, -- Multiplier: 0.143
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.ultTickTime,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.mightyblade.hitboxDelay
	}
}

-- Gladiator Skills (references UnifiedAttacks.Gladiator)
-- Note: hitboxDamage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.GladiatorSkills = {
	ShieldBash = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.shieldbash.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skill1Damage, -- Multiplier: 0.833
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.shieldbash.hitboxDelay
	},
	DragoonJump = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.dragoonjump.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skill2Damage, -- Multiplier: 0.5
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.dragoonjump.hitboxDelay
	},
	DemonicVorpalDance = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.demonicvorpaldance.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.ultDamage, -- Multiplier: 0.167
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.ultTickTime,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.demonicvorpaldance.hitboxDelay
	}
}

-- ========================================
-- CLASS-SPECIFIC HITBOX CONFIGURATIONS
-- ========================================

-- Archer Hitboxes (Ranged attacks)
ServerConfigs.ArcherHitboxes = {
	normalAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.damage,
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green for arrows
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.damage,
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green for arrows
	}
}

-- Samurai Hitboxes (Fast, precise attacks)
-- Note: damage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.SamuraiHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage, -- Multiplier: 0.24
		delay = 0,
		visualColor = Color3.new(1, 0.8, 0) -- Orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage, -- Multiplier: 0.24
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	combo3 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage, -- Multiplier: 0.24
		delay = 2, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(1, 0, 0) -- Red
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage, -- Multiplier: 0.24
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage, -- Multiplier: 0.24
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
	}
}

-- Brawler Hitboxes (Heavy, close-range attacks)
-- Note: damage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.BrawlerHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage, -- Multiplier: 0.133
		delay = 0,
		visualColor = Color3.new(1, 0.5, 0) -- Dark orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage, -- Multiplier: 0.133
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage, -- Multiplier: 0.133
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage, -- Multiplier: 0.133
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
	}
}

-- Knight Hitboxes (Balanced, defensive attacks)
-- Note: damage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.KnightHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage, -- Multiplier: 0.171
		delay = 0,
		visualColor = Color3.new(1, 0.8, 0) -- Orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage, -- Multiplier: 0.171
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	combo3 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage, -- Multiplier: 0.171
		delay = 1, -- Shorter delay than samurai
		visualColor = Color3.new(1, 0, 0) -- Red
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage, -- Multiplier: 0.171
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage, -- Multiplier: 0.171
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
	}
}

-- Gladiator Hitboxes (Aggressive, wide attacks)
-- Note: damage is now a multiplier - use getBaseDamage() or calculateDamage() to get actual damage
ServerConfigs.GladiatorHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage, -- Multiplier: 0.4
		delay = 0,
		visualColor = Color3.new(1, 0.8, 0) -- Orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage, -- Multiplier: 0.4
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage, -- Multiplier: 0.4
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage, -- Multiplier: 0.4
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
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

-- ========================================
-- DAMAGE CALCULATION FUNCTIONS
-- ========================================

-- Function to get player's CritRate stat
-- @param player: Player instance
-- @return: CritRate value (0-100) or 0
function ServerConfigs.getPlayerCritRate(player)
	if not player then
		return 0
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end
	
	local critRate = leaderstats:FindFirstChild("CritRate")
	if not critRate then
		return 0
	end
	
	return critRate.Value or 0
end

-- Function to get player's CritMultiplier stat
-- @param player: Player instance
-- @return: CritMultiplier value (e.g., 150 = 1.5x damage) or 150 (default)
function ServerConfigs.getPlayerCritMultiplier(player)
	if not player then
		return 150
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return 150
	end
	
	local critMultiplier = leaderstats:FindFirstChild("CritMultiplier")
	if not critMultiplier then
		return 150
	end
	
	return critMultiplier.Value or 150
end

-- Function to check if an attack crits based on CritRate
-- @param critRate: CritRate value (0-100)
-- @return: Boolean indicating if the attack crits
function ServerConfigs.rollCrit(critRate)
	if not critRate or critRate <= 0 then
		return false
	end
	
	-- Clamp crit rate to 0-100
	critRate = math.max(0, math.min(100, critRate))
	
	-- Roll random number between 0-100
	local roll = math.random() * 100
	
	-- Crit if roll is less than critRate
	return roll < critRate
end

-- Function to calculate actual damage from damage multiplier and player's MaxAttack stat
-- @param damageMultiplier: The multiplier from UnifiedAttacks (e.g., 0.2 = 20% of MaxAttack)
-- @param playerMaxAttack: The player's MaxAttack stat value
-- @return: Actual damage value (damageMultiplier * playerMaxAttack)
function ServerConfigs.calculateDamage(damageMultiplier, playerMaxAttack)
	if not damageMultiplier or not playerMaxAttack then
		return 0
	end
	return math.floor(damageMultiplier * playerMaxAttack)
end

-- Function to calculate damage with crit chance (returns damage and isCrit flag)
-- @param damageMultiplier: The multiplier from UnifiedAttacks (e.g., 0.2 = 20% of MaxAttack)
-- @param player: Player instance (for getting stats)
-- @return: actualDamage, isCrit - the final damage value and whether it was a critical hit
function ServerConfigs.calculateDamageWithCrit(damageMultiplier, player)
	if not damageMultiplier or not player then
		return 0, false
	end
	
	-- Calculate base damage
	local maxAttack = ServerConfigs.getPlayerMaxAttack(player)
	local baseDamage = ServerConfigs.calculateDamage(damageMultiplier, maxAttack)
	
	-- Check for crit
	local critRate = ServerConfigs.getPlayerCritRate(player)
	local isCrit = ServerConfigs.rollCrit(critRate)
	
	if isCrit then
		-- Apply crit multiplier
		local critMultiplier = ServerConfigs.getPlayerCritMultiplier(player)
		-- CritMultiplier is stored as percentage (150 = 1.5x), so divide by 100
		local finalDamage = math.floor(baseDamage * (critMultiplier / 100))
		return finalDamage, true
	else
		return baseDamage, false
	end
end

-- Function to get base damage for a class's normal attack
-- @param classType: Class name (e.g., "Archer", "Samurai")
-- @param playerMaxAttack: The player's MaxAttack stat value
-- @return: Actual damage value
function ServerConfigs.getBaseDamage(classType, playerMaxAttack)
	if not classType or not ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
		return 0
	end
	
	local damageMultiplier = ServerConfigs.Hitboxes.UnifiedAttacks[classType].damage or 0
	return ServerConfigs.calculateDamage(damageMultiplier, playerMaxAttack)
end

-- Function to get skill damage (skill1, skill2, or ult)
-- @param classType: Class name (e.g., "Archer", "Samurai")
-- @param skillType: "skill1", "skill2", or "ult"
-- @param playerMaxAttack: The player's MaxAttack stat value
-- @return: Actual damage value
function ServerConfigs.getSkillDamage(classType, skillType, playerMaxAttack)
	if not classType or not ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
		return 0
	end
	
	local classConfig = ServerConfigs.Hitboxes.UnifiedAttacks[classType]
	local damageMultiplier = 0
	
	if skillType == "skill1" then
		damageMultiplier = classConfig.skill1Damage or 0
	elseif skillType == "skill2" then
		damageMultiplier = classConfig.skill2Damage or 0
	elseif skillType == "ult" then
		damageMultiplier = classConfig.ultDamage or 0
	end
	
	return ServerConfigs.calculateDamage(damageMultiplier, playerMaxAttack)
end

-- Function to get player stats from leaderstats
-- Helper function to get player's MaxAttack stat
-- @param player: Player instance
-- @return: MaxAttack value or 0
function ServerConfigs.getPlayerMaxAttack(player)
	if not player then
		return 0
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end
	
	local maxAttack = leaderstats:FindFirstChild("MaxAttack")
	if not maxAttack then
		return 0
	end
	
	return maxAttack.Value or 0
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

-- Function to get class-specific hitbox configuration
function ServerConfigs.getHitboxConfig(attackType, classType)
	local classHitboxes = ServerConfigs[classType .. "Hitboxes"]
	if classHitboxes and classHitboxes[attackType] then
		return classHitboxes[attackType]
	end
	
	-- Fallback to defaults if class-specific config not found
	return ServerConfigs.Hitboxes.Defaults
end

-- Function to get hitbox configuration with defaults
function ServerConfigs.getHitboxConfigWithDefaults(attackType, classType, customConfig)
	local baseConfig = ServerConfigs.getHitboxConfig(attackType, classType)
	local defaults = ServerConfigs.Hitboxes.Defaults
	
	return {
		offset = customConfig and customConfig.offset or baseConfig.offset or defaults.defaultOffset,
		size = customConfig and customConfig.size or baseConfig.size or defaults.defaultSize,
		damage = customConfig and customConfig.damage or baseConfig.damage or defaults.defaultDamage,
		delay = customConfig and customConfig.delay or baseConfig.delay or defaults.defaultDelay,
		visualColor = customConfig and customConfig.visualColor or baseConfig.visualColor or defaults.defaultVisualColor
	}
end

-- Legacy function for backward compatibility
function ServerConfigs.getLegacyHitboxConfig(attackType)
	return ServerConfigs.getHitboxConfig(attackType, "Samurai") -- Default to Samurai for legacy calls
end

-- ========================================
-- CLIENT CONFIGURATIONS
-- ========================================

-- Client-side configuration for all classes
ServerConfigs.Client = {
	-- Highlight cleanup configuration
	HighlightCleanup = {
		cleanupInterval = 60 -- Clean up highlights every 60 seconds
	},
	
	-- Camera speed multipliers for all classes
	CameraSpeedMultipliers = {
		-- Basic movements (shared across all classes)
		idle = 1.0,
		run = 1.0,
		jump = 1.0,
		block = 1.0,
		wave = 1.0,
		
		-- Archer specific
		archer = {
			normalAttack = 1.0,
			jumpAttack = 1.0,
			piercingShot = 1.0,
			powerShot = 1.0,
			hunterInstinct = 1.0,
			hunterMark = 1.0,
			starfall = 1.0
		},
		
		-- Samurai specific
		samurai = {
			combo1 = 1.0,
			combo2 = 1.0,
			combo3 = 1.0,
			moveAttack = 1.0,
			jumpAttack = 1.0,
			kozuki = 1.0,
			wakizashi = 1.0,
			banzai = 1.0,
			bushido = 1.0,
			zantetsuken = 1.0
		},
		
		-- Brawler specific
		brawler = {
			combo1 = 1.0,
			combo2 = 1.0,
			moveAttack = 1.0,
			jumpAttack = 1.0,
			feralleap = 1.0,
			brawlersroar = 1.0,
			bloodthirst = 1.0,
			lastchance = 1.0,
			meteordive = 1.0
		},
		
		-- Knight specific
		knight = {
			combo1 = 1.0,
			combo2 = 1.0,
			combo3 = 1.0,
			moveAttack = 1.0,
			jumpAttack = 1.0,
			sworddance = 1.0,
			cyclone_slash = 1.0,
			warcry = 1.0,
			warriormight = 1.0,
			mightyblade = 1.0
		},
		
		-- Gladiator specific
		gladiator = {
			combo1 = 1.0,
			combo2 = 1.0,
			moveAttack = 1.0,
			jumpAttack = 1.0,
			shieldbash = 1.0,
			dragoonjump = 1.0,
			championsblood = 1.0,
			championscheer = 1.0,
			demonicvorpaldance = 1.0
		}
	},
	
	-- Archer specific client configurations
	Archer = {
		-- Aim lock configuration
		aimLock = {
			mode = "dynamic", -- Options: true (always), false (never), "dynamic" (toggle with F)
			modes = {true, false, "dynamic"},
			currentModeIndex = 3 -- Start with dynamic mode
		},
		
		-- Arrow trail color (references UnifiedAttacks.Archer)
		arrowTrailColor = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowTrailColor
	},
	
	-- Brawler specific client configurations
	Brawler = {
		-- Feral leap initialization delay
		feralLeap = {
			initializationDelay = 0.5 -- Delay after weapon equip before system is ready
		}
	},
	
	-- Keybind configurations for all classes
	Keybinds = {
		-- Global keybinds (shared across all classes)
		global = {
			attack = Enum.UserInputType.MouseButton1, -- Left click
			block = Enum.KeyCode.V,
			jump = Enum.KeyCode.Space,
			wave = Enum.KeyCode.T -- Global wave keybind
		},
		
		-- Archer specific keybinds
		archer = {
			piercingShot = Enum.KeyCode.Q,
			powerShot = Enum.KeyCode.E,
			hunterInstinct = Enum.KeyCode.X,
			hunterMark = Enum.KeyCode.C,
			starfall = Enum.KeyCode.Z,
			dynamicAim = Enum.KeyCode.F -- F key for aim lock toggle
		},
		
		-- Samurai specific keybinds
		samurai = {
			wakizashi = Enum.KeyCode.Q,
			kozuki = Enum.KeyCode.E,
			banzai = Enum.KeyCode.X,
			bushido = Enum.KeyCode.C,
			zantetsuken = Enum.KeyCode.Z
		},
		
		-- Brawler specific keybinds
		brawler = {
			feralleap = Enum.KeyCode.E,
			brawlersroar = Enum.KeyCode.Q,
			bloodthirst = Enum.KeyCode.X,
			lastchance = Enum.KeyCode.C,
			meteordive = Enum.KeyCode.Z,
			feralleapStop = Enum.KeyCode.E -- E key to stop feral leap early
		},
		
		-- Knight specific keybinds
		knight = {
			sworddance = Enum.KeyCode.Q,
			cyclone_slash = Enum.KeyCode.E,
			warcry = Enum.KeyCode.X,
			warriormight = Enum.KeyCode.C,
			mightyblade = Enum.KeyCode.Z
		},
		
		-- Gladiator specific keybinds
		gladiator = {
			shieldbash = Enum.KeyCode.Q,
			dragoonjump = Enum.KeyCode.E,
			championsblood = Enum.KeyCode.X,
			championscheer = Enum.KeyCode.C,
			demonicvorpaldance = Enum.KeyCode.Z
		}
	},
	
	-- Weapon tag configurations
	WeaponTags = {
		archer = "archer_wpn",
		samurai = "samurai_wpn",
		brawler = "brawler_wpn",
		knight = "knight_wpn",
		gladiator = "gladiator_wpn"
	}
}

return ServerConfigs
