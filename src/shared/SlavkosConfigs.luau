-- ========================================
-- SERVER CONFIGURATION MODULE
-- Centralized configuration for all server-side settings
-- ========================================

local ServerConfigs = {}

-- ========================================
-- BASE PLAYER STATS (Classes)
-- ========================================

ServerConfigs.BaseStats = {
	-- XP/Level Configuration (shared across all classes)
	XP = {
		startLevel = 1,
		startXP = 0,
		startMaxXP = 5,
		maxLevel = 50
	},
	
	-- Level-up multipliers per class (base values from spreadsheet)
	LevelUpMultipliers = {
		Samurai = {
			HP = 1.08,     -- 8% growth
			ATK = 1.05,    -- 5% growth
			D = 1.08,      -- 8% growth
			MD = 1.08      -- 8% growth (Magic Defense)
		},
		Archer = {
			HP = 1.06,     -- 6% growth
			ATK = 1.10,    -- 10% growth
			D = 1.05,      -- 5% growth
			MD = 1.05      -- 5% growth
		},
		Gladiator = {
			HP = 1.10,     -- 10% growth
			ATK = 1.03,    -- 3% growth
			D = 1.08,      -- 8% growth
			MD = 1.08      -- 8% growth
		},
		Brawler = {
			HP = 1.07,     -- 7% growth
			ATK = 1.09,    -- 9% growth
			D = 1.05,      -- 5% growth
			MD = 1.05      -- 5% growth
		},
		Knight = {
			HP = 1.07,     -- 7% growth
			ATK = 1.07,    -- 7% growth
			D = 1.07,      -- 7% growth
			MD = 1.07      -- 7% growth
		}
	},
	
	Archer = {
		-- Offense Stats
		ATK = 100,        -- Attack: Directly affects Health points
		DP = 0,           -- Defense Penetration: Directly affects Defense
		CR = 5,           -- Crit Rate: Rate of Critical Chance up to 100%
		CM = 150,         -- Crit Multiplier: Attack Multiplier (percentage)
		SD = 0,           -- Skill Damage: Damage from Skill Based Attack
		
		-- Defense Stats
		HP = 1200,        -- Health Points: Life pool (dies if ≤ 0)
		D = 50,           -- Defense: Reduces Penetration
		MD = 50,          -- Magic Defense: Reduces magical damage
		HR = 0,           -- Health Regeneration: Health Points gained per second
		Mspd = 18,        -- Movement Speed: Displacement per second
		Aspd = 1,         -- Attack Speed: Amount of hits per second
	},
	
	Samurai = {
		-- Offense Stats
		ATK = 50,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 1600,
		D = 80,
		MD = 80,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Brawler = {
		-- Offense Stats
		ATK = 90,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 1400,
		D = 50,
		MD = 50,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Knight = {
		-- Offense Stats
		ATK = 70,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 1400,
		D = 70,
		MD = 70,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Gladiator = {
		-- Offense Stats
		ATK = 30,
		DP = 0,
		CR = 5,
		CM = 150,
		SD = 0,
		
		-- Defense Stats
		HP = 2000,
		D = 80,
		MD = 80,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	}
}

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
			damage = 20,
			skill1Damage = 35,           -- PiercingShot
			skill2Damage = 40,           -- PowerShot
			skill2TickTime = 0.3,        -- PowerShot DOT tick time
			ultDamage = 10,              -- Starfall
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
					hitboxSize = Vector3.new(6, 6, 6),
					hitboxDelay = 0.1
				},
				powerShot = {
					hitboxSize = Vector3.new(8, 8, 8),
					hitboxDelay = 0.1
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
			damage = 12,
			skill1Damage = 25,           -- Wakizashi
			skill2Damage = 30,           -- Kozuki
			ultDamage = 50,              -- Zantetsuken
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
			damage = 12,
			skill1Damage = 20,           -- BrawlersRoar
			skill2Damage = 35,           -- FeralLeap
			ultDamage = 8,               -- MeteorDive
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
			damage = 12,
			skill1Damage = 30,           -- SwordDance
			skill2Damage = 25,           -- CycloneSlash
			skill2TickTime = 0.4,        -- CycloneSlash hitbox tick time
			ultDamage = 10,              -- MightyBlade
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
			damage = 12,
			skill1Damage = 25,           -- ShieldBash
			skill2Damage = 15,           -- DragoonJump
			ultDamage = 5,               -- DemonicVorpalDance
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
	ArrowHitbox = {
		delay = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.arrowDelay,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.damage,
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
ServerConfigs.SamuraiSkills = {
	Kozuki = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.kozuki.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skill2Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.kozuki.hitboxDelay
	},
	Wakizashi = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.wakizashi.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skill1Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.wakizashi.hitboxDelay
	},
	Zantetsuken = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.zantetsuken.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.ultDamage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.skills.zantetsuken.hitboxDelay
	}
}

-- Brawler Skills (references UnifiedAttacks.Brawler)
ServerConfigs.BrawlerSkills = {
	FeralLeap = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.feralleap.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill2Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.feralleap.hitboxDelay
	},
	BrawlersRoar = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.brawlersroar.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skill1Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.brawlersroar.hitboxDelay
	},
	MeteorDive = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.meteordive.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.ultDamage,
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.ultTickTime,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.skills.meteordive.hitboxDelay
	}
}

-- Knight Skills (references UnifiedAttacks.Knight)
ServerConfigs.KnightSkills = {
	SwordDance = {
		swordHitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.sworddance.swordHitboxSize,
		swordHitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill1Damage,
		swordHitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.sworddance.swordHitboxDelay
	},
	CycloneSlash = {
		smallHitboxDuration = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.smallHitboxDuration,
		smallHitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.smallHitboxSize,
		smallHitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2Damage,
		smallHitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.smallHitboxDelay,
		bigHitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.bigHitboxSize,
		bigHitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2Damage,
		bigHitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.cycloneslash.bigHitboxDelay,
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2TickTime,
		bigDamageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skill2TickTime
	},
	MightyBlade = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.mightyblade.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.ultDamage,
		damageTickTime = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.ultTickTime,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.skills.mightyblade.hitboxDelay
	}
}

-- Gladiator Skills (references UnifiedAttacks.Gladiator)
ServerConfigs.GladiatorSkills = {
	ShieldBash = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.shieldbash.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skill1Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.shieldbash.hitboxDelay
	},
	DragoonJump = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.dragoonjump.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skill2Damage,
		hitboxDelay = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.dragoonjump.hitboxDelay
	},
	DemonicVorpalDance = {
		hitboxSize = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.skills.demonicvorpaldance.hitboxSize,
		hitboxDamage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.ultDamage,
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
ServerConfigs.SamuraiHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage,
		delay = 0,
		visualColor = Color3.new(1, 0.8, 0) -- Orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage,
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	combo3 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage,
		delay = 2, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(1, 0, 0) -- Red
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage,
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.damage,
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
	}
}

-- Brawler Hitboxes (Heavy, close-range attacks)
ServerConfigs.BrawlerHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage,
		delay = 0,
		visualColor = Color3.new(1, 0.5, 0) -- Dark orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage,
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage,
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.damage,
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
	}
}

-- Knight Hitboxes (Balanced, defensive attacks)
ServerConfigs.KnightHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage,
		delay = 0,
		visualColor = Color3.new(1, 0.8, 0) -- Orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage,
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	combo3 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage,
		delay = 1, -- Shorter delay than samurai
		visualColor = Color3.new(1, 0, 0) -- Red
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage,
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.damage,
		delay = 0,
		visualColor = Color3.new(0, 1, 0) -- Green
	}
}

-- Gladiator Hitboxes (Aggressive, wide attacks)
ServerConfigs.GladiatorHitboxes = {
	combo1 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage,
		delay = 0,
		visualColor = Color3.new(1, 0.8, 0) -- Orange
	},
	combo2 = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage,
		delay = 0,
		visualColor = Color3.new(0.8, 0.2, 1) -- Purple
	},
	moveAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage,
		delay = 0.4, -- Base delay (auto-scales with animation speed)
		visualColor = Color3.new(0, 0.8, 1) -- Light blue
	},
	jumpAttack = {
		offset = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.offset,
		size = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.size,
		damage = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.damage,
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
