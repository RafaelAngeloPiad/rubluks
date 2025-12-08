-- ========================================
-- SERVER CONFIGURATION MODULE
-- Centralized configuration for all server-side settings
-- ========================================

local ServerConfigs = {}

-- ========================================
-- GLOBAL HITBOX CONFIGURATION
-- ========================================

ServerConfigs.Hitbox = {
	transparency = 0.9, -- Global transparency for all hitbox visuals
	
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
			textSize = 28, -- Text size (reduced from 36 to prevent overlap)
			textColor = Color3.new(1, 0.8, 0), -- Orange/yellow color
			backgroundColor = Color3.new(0, 0, 0), -- Background color (unused when fully transparent)
			backgroundTransparency = 1, -- Fully transparent background
			strokeColor = Color3.new(0, 0, 0), -- Black stroke
			strokeTransparency = 0, -- Solid stroke
			duration = 0.8, -- How long the number stays visible (seconds) (reduced from 1.5 to prevent overlap)
			riseHeight = 3, -- How high the number rises (studs)
			riseSpeed = 4, -- Speed at which number rises (studs per second) (increased from 2 to fly faster)
			fadeStart = 0.3, -- When to start fading (after this many seconds) (reduced from 0.5 to fade earlier)
			offsetY = 2, -- Vertical offset from character head (studs)
			randomOffsetX = 1, -- Random horizontal offset range (studs)
			width = 180,
			height = 90,
			maxDistance = 110,
			scaleReferenceDistance = 28,
			minScale = 0.55,
			maxScale = 1.05,
			scaleFalloff = 1,
		},

		-- XP Gain Numbers Configuration (floating "+12 XP" popups for players)
		xpNumbers = {
			enabled = true, -- Enable/disable XP popups
			font = Enum.Font.GothamBold, -- Font style to match damage numbers
			textSize = 20, -- Smaller for less intrusive display
			textColor = Color3.fromRGB(120, 255, 120), -- Bright green
			offsetX = -2.5, -- Shift to the left side of the character
			offsetY = -2.5, -- Position near the feet instead of above the head
			backgroundTransparency = 1, -- Fully transparent background
			strokeColor = Color3.fromRGB(20, 120, 20), -- Dark green outline
			strokeTransparency = 0.1, -- Slightly transparent outline for softness
			duration = 2.0, -- How long the number stays visible (seconds)
			riseHeight = 1.2, -- How high the text rises (studs)
			fadeStart = 1.0, -- When to start fading (after this many seconds)
			randomOffsetX = 0.2, -- Subtle horizontal variation
			attachTo = "Root", -- Anchor to humanoid root for lower positioning
			prefix = "+", -- Text prefix before XP amount
			suffix = " XP", -- Text suffix after XP amount
			width = 160,
			height = 70,
			maxDistance = 85,
			scaleReferenceDistance = 25,
			minScale = 0.45,
			maxScale = 0.95,
			scaleFalloff = 1.1,
		},

		-- Slavkoin Gain Numbers Configuration (floating "+5 Slavkoins" popups for players)
		slavkoinNumbers = {
			enabled = true, -- Enable/disable Slavkoin popups
			font = Enum.Font.GothamBold, -- Font style to match XP numbers
			textSize = 20, -- Keep consistent sizing with XP numbers
			textColor = Color3.fromRGB(255, 223, 93), -- Gold color
			offsetX = 2.5, -- Shift to the right side of the character
			offsetY = -2.5, -- Position near the feet instead of above the head
			backgroundTransparency = 1, -- Fully transparent background
			strokeColor = Color3.fromRGB(140, 95, 20), -- Dark gold outline
			strokeTransparency = 0.1, -- Slightly transparent outline
			duration = 2.0, -- How long the number stays visible (seconds)
			riseHeight = 1.2, -- How high the text rises (studs)
			fadeStart = 1.0, -- When to start fading (after this many seconds)
			randomOffsetX = 0.2, -- Subtle horizontal variation
			attachTo = "Root", -- Anchor to humanoid root for lower positioning
			prefix = "+", -- Text prefix before Slavkoin amount
			suffix = " Slavkoins", -- Text suffix after Slavkoin amount
			width = 160,
			height = 70,
			maxDistance = 85,
			scaleReferenceDistance = 25,
			minScale = 0.45,
			maxScale = 0.95,
			scaleFalloff = 1.1,
		},
		
		-- Knockback Configuration
		knockback = {
			enabled = true, -- Enable/disable knockback
			force = 2 -- Knockback force (velocity applied to mob)
		},
		
		-- Mob Stats Display Configuration
		mobStatsDisplay = {
			enabled = true, -- Enable/disable floating mob stats GUI
			offsetY = 6, -- Vertical offset from character head (studs) - above damage numbers
			offsetYNoStat = 1.9, -- Vertical offset when stat details are hidden
			size = Vector2.new(170, 120), -- GUI size in pixels
			visibilityRadius = 80, -- Only show stats for mobs within this radius
			distanceScaling = true, -- Scale UI based on distance
			scaleReferenceDistance = 45, -- Distance at which scale is 1.0
			minScale = 0.6, -- Minimum scale factor
			maxScale = 1.1, -- Maximum scale factor
			scaleFalloff = 1.0, -- How aggressively scale changes with distance
			backgroundColor = Color3.new(0, 0, 0), -- Background color (unused when fully transparent)
			backgroundTransparency = 1, -- Background transparency (1 = invisible overlay)
			borderColor = Color3.new(0, 0, 0), -- Border color (unused when border size is 0)
			borderSizePixel = 0, -- Border thickness (0 = none)
			cornerRadius = 5, -- Corner roundness for optional background
			textColor = Color3.new(1, 1, 1), -- Default text color (white)
			textStrokeColor = Color3.new(0, 0, 0), -- Outline color (black)
			textStrokeTransparency = 0.2, -- Outline opacity (0 = solid, 1 = none)
			textStrokeThickness = 1, -- Outline thickness (thin black outline)
			textSize = 12, -- Font size
			font = Enum.Font.Gotham, -- Font style
			headerColor = Color3.new(1, 1, 1), -- Header text color (white)
			headerSize = 16, -- Header font size
			headerStrokeTransparency = 1, -- Outline around header text (0 = solid, 1 = none)
			showStatDetails = false, -- Toggle to show/hide extra stat rows beneath the name
			healthBarHeight = 10, -- Pixel height of health bar
			healthBarBackgroundColor = Color3.fromRGB(35, 35, 35), -- Color behind the health bar fill
			healthBarBorderColor = Color3.fromRGB(10, 10, 10), -- Health bar outline color
			healthBarCornerRadius = 4, -- Health bar roundness
			healthBarDefaultColor = Color3.fromRGB(120, 220, 120), -- Default health bar fill if mob doesn't specify one
			healthBarTextColor = Color3.fromRGB(0, 0, 0), -- Text color inside the health bar
			defenseBarHeight = 9, -- Pixel height of defense bar
			defenseBarBackgroundColor = Color3.fromRGB(40, 40, 40), -- Color behind the defense bar fill
			defenseBarBorderColor = Color3.fromRGB(15, 15, 15), -- Defense bar outline color
			defenseBarCornerRadius = 4, -- Defense bar roundness
			defenseBarDefaultColor = Color3.fromRGB(120, 170, 220), -- Default defense bar fill
			defenseBarTextColor = Color3.fromRGB(0, 0, 0), -- Text color inside the defense bar
			levelLabelColor = Color3.fromRGB(255, 255, 255), -- Level label text color
			updateRate = 0.1 -- Update frequency in seconds
		},
		
		-- Status Ailment Configuration
		statusAilments = {
			stun = {
				defaultDuration = 2.0, -- Default duration in seconds
				highlightColor = {
					fillColor = Color3.new(0.5, 0.5, 0.5), -- Grey
					fillTransparency = 0.7,
					outlineColor = Color3.new(0.5, 0.5, 0.5), -- Grey
					outlineTransparency = 0
				}
			},
			poison = {
				defaultDuration = 5.0, -- Default duration in seconds
				defaultDPS = 5, -- Default damage per second
				defaultTickInterval = 1.0, -- Default tick interval in seconds
				highlightColor = {
					fillColor = Color3.new(0.5, 0, 0.5), -- Purple
					fillTransparency = 0.7,
					outlineColor = Color3.new(0.5, 0, 0.5), -- Purple
					outlineTransparency = 0
				}
			},
			burn = {
				defaultDuration = 5.0, -- Default duration in seconds
				defaultDPS = 5, -- Default damage per second
				defaultTickInterval = 1.0, -- Default tick interval in seconds
				highlightColor = {
					fillColor = Color3.new(1, 0.5, 0), -- Orange
					fillTransparency = 0.7,
					outlineColor = Color3.new(1, 0.5, 0), -- Orange
					outlineTransparency = 0
				}
			},
			ice = {
				defaultDuration = 3.0, -- Default duration in seconds
				defaultDPS = 3, -- Default damage per second
				defaultTickInterval = 1.0, -- Default tick interval in seconds
				slowMultiplier = 0.3, -- 30% movement speed
				highlightColor = {
					fillColor = Color3.new(0, 0.5, 1), -- Blue
					fillTransparency = 0.7,
					outlineColor = Color3.new(0, 0.5, 1), -- Blue
					outlineTransparency = 0
				}
			},
			slow = {
				defaultDuration = 3.0, -- Default duration in seconds
				slowMultiplier = 0.5, -- 50% movement speed
				highlightColor = {
					fillColor = Color3.new(0.5, 0.5, 0.5), -- Gray
					fillTransparency = 0.7,
					outlineColor = Color3.new(0.5, 0.5, 0.5), -- Gray
					outlineTransparency = 0
				}
			}
		}
}

-- ========================================
-- DEVELOPER TOOLING CONFIGURATION
-- ========================================

ServerConfigs.ControlUI = {
	displayStats = {
		enabled = true -- Toggle the developer stats overlay
	},
	masterControls = {
		enabled = true -- Toggle the developer master control panel (XP/class/friendly fire tools)
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
			damage = 1.0,                -- 100% of MaxAttack (base hit)
			skill1Damage = 1.5,          -- 150% of MaxAttack - PiercingShot
			skill2Damage = 2.0,          -- 200% of MaxAttack - PowerShot
			skill2TickTime = 1,        -- PowerShot DOT tick time
			ultDamage = 4.0,             -- 400% of MaxAttack - Starfall
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
			-- Unified animation speeds
			attackSpeed = 1.0,     -- Unified speed for all attack animations (normalAttack, jumpAttack, piercingShot, powerShot, hunterInstinct, hunterMark, starfall)
			skillAttackSpeedBaseline = 1.0, -- Baseline speed for skill/buff/ult animations (kept independent from normal attacks)
			movementSpeed = 1.0,   -- Unified speed for all movement animations (idle, run, jump)
			-- Note: block animations remain at 1.0 (not affected by these speeds)
			-- Walking speeds (fixed values, not affected by animation speed)
			walking = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking -- NO TOUCH
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills
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
			damage = 1.0,                -- 100% of MaxAttack
			skill1Damage = 1.5,           -- 150% of MaxAttack - Wakizashi
			skill2Damage = 2.0,           -- 200% of MaxAttack - Kozuki
			ultDamage = 4.0,              -- 400% of MaxAttack - Zantetsuken
			-- Unified animation speeds
			attackSpeed = 1.0,     -- Unified speed for all attack animations (combo1, combo2, combo3, moveAttack, jumpAttack, kozuki, wakizashi, banzai, bushido, zantetsuken)
			movementSpeed = 1.0,   -- Unified speed for all movement animations (idle, run, jump)
			-- Note: block animations remain at 1.0 (not affected by these speeds)
			-- Walking speeds (fixed values, not affected by animation speed)
			walking = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills (wakizashi/kozuki)
				blocking = 0    -- Fixed speed while blocking
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills (wakizashi/kozuki)
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
			combo3Cooldown = 60,     -- 60 second cooldown for 3rd attack
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
			damage = 1.0,              -- 100% of MaxAttack
			skill1Damage = 1.5,        -- 150% of MaxAttack - BrawlersRoar
			skill2Damage = 2.0,        -- 200% of MaxAttack - FeralLeap
			ultDamage = 4.0,           -- 400% of MaxAttack - MeteorDive
			ultTickTime = 0.5,           -- MeteorDive DOT tick time
			-- Unified animation speeds
			attackSpeed = 1.0,     -- Unified speed for all attack animations (combo1, combo2, moveAttack, jumpAttack, feralleap, brawlersroar, bloodthirst, lastchance, meteordive)
			movementSpeed = 1.0,   -- Unified speed for all movement animations (idle, run, jump)
			-- Note: block animations remain at 1.0 (not affected by these speeds)
			-- Walking speeds (fixed values, not affected by animation speed)
			walking = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking
			},
			-- Cooldowns
			cooldowns = {
				feralleap = 5,
				brawlersroar = 5,
				bloodthirst = 30,  -- 30 seconds cooldown
				lastchance = 30,   -- 30 seconds cooldown
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
			damage = 1.0,               -- 100% of MaxAttack
			skill1Damage = 1.5,        -- 150% of MaxAttack - SwordDance
			skill2Damage = 2.0,        -- 200% of MaxAttack - CycloneSlash
			skill2TickTime = 0.4,        -- CycloneSlash hitbox tick time
			ultDamage = 4.0,           -- 400% of MaxAttack - MightyBlade
			ultTickTime = 0.5,           -- MightyBlade DOT tick time
			-- Unified animation speeds
			attackSpeed = 1.0,     -- Unified speed for all attack animations (combo1, combo2, combo3, moveAttack, jumpAttack, sworddance, cyclone_slash, warcry, warriormight, mightyblade)
			movementSpeed = 1.0,   -- Unified speed for all movement animations (idle, run, jump)
			-- Note: block animations remain at 1.0 (not affected by these speeds)
			-- Walking speeds (fixed values, not affected by animation speed)
			walking = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills (sworddance/cyclone_slash)
				blocking = 0    -- Fixed speed while blocking
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills (sworddance/cyclone_slash)
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
			combo3Cooldown = 60,     -- 60 second cooldown for 3rd attack
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
			damage = 1.0,                -- 100% of MaxAttack
			skill1Damage = 1.5,        -- 150% of MaxAttack - ShieldBash
			skill2Damage = 2.0,          -- 200% of MaxAttack - DragoonJump
			ultDamage = 4.0,           -- 400% of MaxAttack - DemonicVorpalDance
			ultTickTime = 0.5,           -- DemonicVorpalDance DOT tick time
			-- Unified animation speeds
			attackSpeed = 1.0,     -- Unified speed for all attack animations (combo1, combo2, moveAttack, jumpAttack, shieldbash, dragoonjump, championsblood, championscheer, demonicvorpaldance)
			movementSpeed = 1.0,   -- Unified speed for all movement animations (idle, run, jump)
			-- Note: block animations remain at 1.0 (not affected by these speeds)
			-- Walking speeds (fixed values, not affected by animation speed)
			walking = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills
				blocking = 0    -- Fixed speed while blocking
			},
			-- Walking speeds (fixed values, not affected by animation speed)
			walkingSpeed = {
				normal = 18,    -- Fixed normal walking speed
				slow = 1,       -- Fixed speed during skills
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
	AttackSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.attackSpeed,
	SkillAttackSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.attackSpeed,
	SkillAttackSpeedRatio = 1.0,
	MovementSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.movementSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Archer.walkingSpeed,
	
	-- Block damage reduction (percentage of damage reduced when blocking)
	-- Example: 0.5 = 50% damage reduction (if enemy deals 100 damage, you take 50)
	blockDamageReduction = 0.5,
	
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
	AttackSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.attackSpeed,
	MovementSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.movementSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Samurai.walkingSpeed,
	
	-- Block damage reduction (percentage of damage reduced when blocking)
	-- Example: 0.5 = 50% damage reduction (if enemy deals 100 damage, you take 50)
	blockDamageReduction = 0.5,
	
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
	AttackSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.attackSpeed,
	MovementSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.movementSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Brawler.walkingSpeed,
	
	-- Block damage reduction (percentage of damage reduced when blocking)
	-- Example: 0.5 = 50% damage reduction (if enemy deals 100 damage, you take 50)
	blockDamageReduction = 0.5,
	
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
	AttackSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.attackSpeed,
	MovementSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.movementSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Knight.walkingSpeed,
	
	-- Block damage reduction (percentage of damage reduced when blocking)
	-- Example: 0.5 = 50% damage reduction (if enemy deals 100 damage, you take 50)
	blockDamageReduction = 0.5,
	
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
	AttackSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.attackSpeed,
	MovementSpeed = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.movementSpeed,
	Cooldowns = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.cooldowns,
	walking = ServerConfigs.Hitboxes.UnifiedAttacks.Gladiator.walkingSpeed,
	
	-- Block damage reduction (percentage of damage reduced when blocking)
	-- Example: 0.5 = 50% damage reduction (if enemy deals 100 damage, you take 50)
	blockDamageReduction = 0.5,
	
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
	
	-- Determine if this is an attack or movement action
	local isAttack = false
	local isMovement = false
	
	-- Attack actions (combo attacks, skills, etc.)
	if actionType == "normalAttack" or actionType == "jumpAttack" or
	   actionType == "combo1" or actionType == "combo2" or actionType == "combo3" or
	   actionType == "moveAttack" or
	   actionType == "piercingShot" or actionType == "powerShot" or actionType == "hunterInstinct" or actionType == "hunterMark" or actionType == "starfall" or
	   actionType == "kozuki" or actionType == "wakizashi" or actionType == "banzai" or actionType == "bushido" or actionType == "zantetsuken" or
	   actionType == "feralleap" or actionType == "brawlersroar" or actionType == "bloodthirst" or actionType == "lastchance" or actionType == "meteordive" or
	   actionType == "sworddance" or actionType == "cyclone_slash" or actionType == "warcry" or actionType == "warriormight" or actionType == "mightyblade" or
	   actionType == "shieldbash" or actionType == "dragoonjump" or actionType == "championsblood" or actionType == "championscheer" or actionType == "demonicvorpaldance" then
		isAttack = true
	-- Movement actions (run, jump) - NOTE: idle and block are NOT affected by movement speed (always 1.0)
	elseif actionType == "run" or actionType == "jump" then
		isMovement = true
	end
	
	-- Block and idle animations always use 1.0 (not affected by animation speeds)
	if actionType == "block" or actionType == "idle" then
		return baseDelay / 1.0 -- Always 1.0 speed
	end
	
	-- Get animation speed based on action type and class
	if classType and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and 
	   ServerConfigs.Hitboxes.UnifiedAttacks[classType] then
		local classConfig = ServerConfigs.Hitboxes.UnifiedAttacks[classType]
		if isAttack then
			animationSpeed = classConfig.attackSpeed or 1.0
		elseif isMovement then
			animationSpeed = classConfig.movementSpeed or 1.0
		end
	-- Fallback to reference lookup (for backward compatibility)
	elseif classType and ServerConfigs[classType] then
		if isAttack and ServerConfigs[classType].AttackSpeed then
			animationSpeed = ServerConfigs[classType].AttackSpeed
		elseif isMovement and ServerConfigs[classType].MovementSpeed then
			animationSpeed = ServerConfigs[classType].MovementSpeed
		end
	end
	
	-- Scale delay inversely with animation speed
	-- If animation is 2x faster, delays should be 0.5x (half the time) - hitbox appears EARLIER
	-- If animation is 0.5x slower, delays should be 2x (double the time) - hitbox appears LATER
	local scaledDelay = baseDelay / animationSpeed
	
	return scaledDelay
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
-- @param forceCrit: Optional boolean to force a critical hit (default: false)
-- @return: actualDamage, isCrit - the final damage value and whether it was a critical hit
function ServerConfigs.calculateDamageWithCrit(damageMultiplier, player, forceCrit)
	if not damageMultiplier or not player then
		return 0, false
	end
	
	forceCrit = forceCrit or false -- Default to false if not provided
	
	-- When forceCrit is true (e.g., combo3), bypass weapon penalty and always crit
	-- This allows special attacks to always do full crit damage regardless of weapon match
	local adjustedMultiplier
	if forceCrit then
		-- Skip weapon penalty for forced crits (combo3 should always do full damage)
		adjustedMultiplier = damageMultiplier
	else
		-- Apply mismatched weapon penalty before calculating damage
		adjustedMultiplier = ServerConfigs.applyMismatchedWeaponPenalty(player, damageMultiplier)
	end
	
	-- Calculate base damage
	local maxAttack = ServerConfigs.getPlayerMaxAttack(player)
	local baseDamage = ServerConfigs.calculateDamage(adjustedMultiplier, maxAttack)
	
	-- Check for crit (only if weapon matches class - no crits for mismatched weapons)
	-- EXCEPT when forceCrit is true, then always crit regardless of weapon match
	local isWeaponMatch = ServerConfigs.isWeaponClassMatch(player)
	local isCrit = false
	
	-- Force crit if requested (bypasses weapon match check for special attacks like combo3)
	if forceCrit then
		isCrit = true
	elseif isWeaponMatch then
		-- Normal crit roll
		local critRate = ServerConfigs.getPlayerCritRate(player)
		isCrit = ServerConfigs.rollCrit(critRate)
	end
	
	if isCrit then
		-- Apply crit multiplier
		local critMultiplier = ServerConfigs.getPlayerCritMultiplier(player)
		-- CritMultiplier is stored as percentage (150 = 1.5x), so divide by 100
		local finalDamage = math.floor(baseDamage * (critMultiplier / 100))
		return finalDamage, true
	end
	
	-- No crit or mismatched weapon
	return baseDamage, false
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

-- Function to get player's class from leaderstats
-- @param player: Player instance
-- @return: Class name (e.g., "Archer", "Samurai") or nil
function ServerConfigs.getPlayerClass(player)
	if not player then
		return nil
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	
	local class = leaderstats:FindFirstChild("Class")
	if not class then
		return nil
	end
	
	return class.Value or nil
end

-- Secret class helper: is SLAVKO
function ServerConfigs.isSlavkoClass(player)
	local className = ServerConfigs.getPlayerClass(player)
	if not className or className == "" then
		return false
	end
	local lower = string.lower(className)
	return lower == "slavko"
end

-- Acting class resolver: if SLAVKO, act as the equipped weapon's class; otherwise, the player's class
function ServerConfigs.getActingClass(player)
	if not player then
		return nil
	end
	local className = ServerConfigs.getPlayerClass(player)
	if className == "SLAVKO" then
		return ServerConfigs.getEquippedWeaponClass(player)
	end
	return className
end

-- Function to detect which weapon class is equipped by checking weapon tags
-- @param player: Player instance
-- @return: Weapon class name (e.g., "archer", "samurai") or nil if no weapon found
function ServerConfigs.getEquippedWeaponClass(player)
	if not player or not player.Character then
		return nil
	end
	
	local CollectionService = game:GetService("CollectionService")
	
	-- Check all tools in character
	for _, item in ipairs(player.Character:GetChildren()) do
		if item:IsA("Tool") then
			-- Check each weapon tag
			for className, weaponTag in pairs(ServerConfigs.Client.WeaponTags) do
				if CollectionService:HasTag(item, weaponTag) then
					-- Capitalize first letter to match class names (e.g., "archer" -> "Archer")
					return className:sub(1, 1):upper() .. className:sub(2)
				end
			end
		end
	end
	
	return nil
end

-- Function to check if equipped weapon matches player's class
-- @param player: Player instance
-- @return: true if weapon matches class, false otherwise
function ServerConfigs.isWeaponClassMatch(player)
	-- SLAVKO can use any weapon without penalty
	if ServerConfigs.isSlavkoClass(player) then
		return true
	end
	local playerClass = ServerConfigs.getPlayerClass(player)
	local weaponClass = ServerConfigs.getEquippedWeaponClass(player)
	
	-- If no class or no weapon, return false
	if not playerClass or not weaponClass then
		return false
	end
	
	-- Compare classes (case-insensitive)
	return playerClass:lower() == weaponClass:lower()
end

-- Function to apply mismatched weapon penalty to damage multiplier
-- @param player: Player instance
-- @param baseDamageMultiplier: Original damage multiplier
-- @return: Adjusted damage multiplier (penalty applied if weapon doesn't match)
function ServerConfigs.applyMismatchedWeaponPenalty(player, baseDamageMultiplier)
	if not player or not baseDamageMultiplier then
		return 0
	end
	
	-- SLAVKO: never penalize
	if ServerConfigs.isSlavkoClass(player) then
		return baseDamageMultiplier
	end
	
	-- Check if weapon matches class
	local isMatch = ServerConfigs.isWeaponClassMatch(player)
	
	if isMatch then
		-- Weapon matches class, use normal multiplier
		return baseDamageMultiplier
	else
		-- Weapon doesn't match, apply penalty
		local penaltyConfig = ServerConfigs.Client.MismatchedWeaponPenalty
		local penaltyMultiplier = penaltyConfig.damageMultiplier or 0.01
		
		-- Apply penalty (multiply by penalty multiplier)
		local penalizedMultiplier = baseDamageMultiplier * penaltyMultiplier
		
		-- Ensure minimum damage is applied
		local maxAttack = ServerConfigs.getPlayerMaxAttack(player)
		local minDamage = penaltyConfig.minDamage or 1
		local calculatedDamage = penalizedMultiplier * maxAttack
		
		-- If calculated damage would be less than minDamage, adjust multiplier
		if calculatedDamage < minDamage and maxAttack > 0 then
			penalizedMultiplier = minDamage / maxAttack
		end
		
		return penalizedMultiplier
	end
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
	},
	
	-- Mismatched weapon penalty configuration
	MismatchedWeaponPenalty = {
		damageMultiplier = 0.01,  -- 1% damage when using wrong class weapon (configurable)
		allowSkills = false,      -- Disable skills when weapon doesn't match class
		minDamage = 1             -- Minimum damage output (1 damage)
	}
}

-- ========================================
-- STAT CAPS
-- ========================================

ServerConfigs.StatCaps = {
	Default = {
		MaxAttack = { max = 1000000 },
		MaxDefense = { max = 1000000 },
		CurrentDefense = { max = 1000000 },
		MaxHealth = { max = 10000000 },
		DefensePenetration = { max = 100000 },
		CritRate = { max = 100 },
		CritMultiplier = { max = 500 },
		HealthRegen = { max = 10000 },
		MovementSpeed = { max = 5 },
		AttackSpeed = { max = 5 },
	},
	Slavkorian = {
		AttackSpeed = { max = 5 },
		MovementSpeed = { max = 3 },
	},
	Archer = {
		AttackSpeed = { max = 5 },
		MovementSpeed = { max = 3 },
	},
	Samurai = {
		AttackSpeed = { max = 5 },
		MovementSpeed = { max = 3 },
	},
	Brawler = {
		AttackSpeed = { max = 5 },
		MovementSpeed = { max = 3 },
	},
	Knight = {
		AttackSpeed = { max = 5 },
		MovementSpeed = { max = 3 },
	},
	Gladiator = {
		AttackSpeed = { max = 5 },
		MovementSpeed = { max = 3 },
	},
}

-- ========================================
-- BUFF CONFIGURATIONS
-- ========================================

-- Knight Buffs
ServerConfigs.KnightBuffs = {
	Warcry = {
		-- Buff: Increases Attack and Defense by multipliers
		levels = {
			[5] = {
				attackMultiplier = 1.1,   -- 10% increase
				defenseMultiplier = 1.1,  -- 10% increase
				duration = 30             -- 30 seconds
			},
			[15] = {
				attackMultiplier = 1.15,  -- 15% increase
				defenseMultiplier = 1.15, -- 15% increase
				duration = 35             -- 35 seconds
			},
			[25] = {
				attackMultiplier = 1.2,   -- 20% increase
				defenseMultiplier = 1.2,  -- 20% increase
				duration = 40             -- 40 seconds
			},
			[35] = {
				attackMultiplier = 1.25,  -- 25% increase
				defenseMultiplier = 1.25, -- 25% increase
				duration = 45             -- 45 seconds
			},
			[45] = {
				attackMultiplier = 1.3,   -- 30% increase
				defenseMultiplier = 1.3,  -- 30% increase
				duration = 50             -- 50 seconds
			}
		}
	},
	WarriorMight = {
		-- Buff: Increases HP by flat amount
		levels = {
			[1] = {
				hpIncrease = 100,        -- +100 HP
				duration = 30             -- 30 seconds
			},
			[11] = {
				hpIncrease = 200,        -- +200 HP
				duration = 35             -- 35 seconds
			},
			[21] = {
				hpIncrease = 400,        -- +400 HP
				duration = 40             -- 40 seconds
			},
			[31] = {
				hpIncrease = 800,        -- +800 HP
				duration = 45             -- 45 seconds
			},
			[41] = {
				hpIncrease = 1600,       -- +1600 HP
				duration = 50             -- 50 seconds
			}
		}
	}
}

-- Brawler Buffs
ServerConfigs.BrawlerBuffs = {
	BloodThirst = {
		-- Buff: Provides lifesteal based on Attack percentage
		levels = {
			[5] = {
				lifestealPercentage = 0.03,  -- 3% of Attack as lifesteal (ATK*0.03)
				duration = 60                 -- 60 seconds
			},
			[15] = {
				lifestealPercentage = 0.05,  -- 5% of Attack as lifesteal (ATK*0.05)
				duration = 80                 -- 80 seconds
			},
			[25] = {
				lifestealPercentage = 0.08,  -- 8% of Attack as lifesteal (ATK*0.08)
				duration = 100                -- 100 seconds
			},
			[35] = {
				lifestealPercentage = 0.1,   -- 10% of Attack as lifesteal (ATK*0.1)
				duration = 120                -- 120 seconds
			},
			[45] = {
				lifestealPercentage = 0.12,  -- 12% of Attack as lifesteal (ATK*0.12)
				duration = 180                -- 180 seconds
			}
		}
	},
	LastChance = {
		-- Buff: Provides status immunity and HP regeneration
		levels = {
			[1] = {
				hpRegenPercentage = 0.01,  -- 1% of Max HP healed per second
				immunityDuration = 11,      -- 11 seconds of status immunity
				duration = 11                -- 11 seconds total
			},
			[11] = {
				hpRegenPercentage = 0.02,  -- 2% of Max HP healed per second
				immunityDuration = 12,      -- 12 seconds of status immunity
				duration = 12                -- 12 seconds total
			},
			[21] = {
				hpRegenPercentage = 0.03,  -- 3% of Max HP healed per second
				immunityDuration = 13,      -- 13 seconds of status immunity
				duration = 13                -- 13 seconds total
			},
			[31] = {
				hpRegenPercentage = 0.04,  -- 4% of Max HP healed per second
				immunityDuration = 14,      -- 14 seconds of status immunity
				duration = 14                -- 14 seconds total
			},
			[41] = {
				hpRegenPercentage = 0.05,  -- 5% of Max HP healed per second
				immunityDuration = 15,      -- 15 seconds of status immunity
				duration = 15                -- 15 seconds total
			}
		}
	}
}

-- Gladiator Buffs
ServerConfigs.GladiatorBuffs = {
	ChampionsCheer = {
		-- Buff: Increases HP, Defense, and Health Regeneration by multipliers
		levels = {
			[5] = {
				hpMultiplier = 0.1,        -- 10% of Max HP
				defenseMultiplier = 0.1,    -- 10% of base Defense
				hpRegenPercentage = 0.01,  -- 1% of Max HP per second
				duration = 60               -- 60 seconds
			},
			[15] = {
				hpMultiplier = 0.15,       -- 15% of Max HP
				defenseMultiplier = 0.15,   -- 15% of base Defense
				hpRegenPercentage = 0.015, -- 1.5% of Max HP per second
				duration = 80               -- 80 seconds
			},
			[25] = {
				hpMultiplier = 0.2,        -- 20% of Max HP
				defenseMultiplier = 0.2,    -- 20% of base Defense
				hpRegenPercentage = 0.02,  -- 2% of Max HP per second
				duration = 100              -- 100 seconds
			},
			[35] = {
				hpMultiplier = 0.25,       -- 25% of Max HP
				defenseMultiplier = 0.25,   -- 25% of base Defense
				hpRegenPercentage = 0.025, -- 2.5% of Max HP per second
				duration = 120              -- 120 seconds
			},
			[45] = {
				hpMultiplier = 0.3,        -- 30% of Max HP
				defenseMultiplier = 0.3,    -- 30% of base Defense
				hpRegenPercentage = 0.03,  -- 3% of Max HP per second
				duration = 180              -- 180 seconds
			}
		}
	},
	ChampionsBlood = {
		-- Buff: Increases Defense by flat amount and provides status immunity
		levels = {
			[1] = {
				defenseIncrease = 100,     -- +100 Defense
				immunityDuration = 10,      -- 10 seconds of status immunity
				duration = 30               -- 30 seconds
			},
			[11] = {
				defenseIncrease = 200,     -- +200 Defense
				immunityDuration = 12,      -- 12 seconds of status immunity
				duration = 40               -- 40 seconds
			},
			[21] = {
				defenseIncrease = 400,     -- +400 Defense
				immunityDuration = 15,      -- 15 seconds of status immunity
				duration = 50               -- 50 seconds
			},
			[31] = {
				defenseIncrease = 800,     -- +800 Defense
				immunityDuration = 18,      -- 18 seconds of status immunity
				duration = 60               -- 60 seconds
			},
			[41] = {
				defenseIncrease = 1600,    -- +1600 Defense
				immunityDuration = 20,      -- 20 seconds of status immunity
				duration = 80               -- 80 seconds
			}
		}
	}
}

-- Archer Buffs
ServerConfigs.ArcherBuffs = {
	HuntersInstinct = {
		-- Buff: Increases Movement Speed and provides Status Immunity
		levels = {
			[5] = {
				mspdMultiplier = 0.06,    -- 6% movement speed increase
				immunityDuration = 10,     -- 10 seconds of status immunity
				duration = 30              -- 30 seconds
			},
			[15] = {
				mspdMultiplier = 0.07,     -- 7% movement speed increase
				immunityDuration = 12,     -- 12 seconds of status immunity
				duration = 35              -- 35 seconds
			},
			[25] = {
				mspdMultiplier = 0.08,     -- 8% movement speed increase
				immunityDuration = 15,     -- 15 seconds of status immunity
				duration = 40              -- 40 seconds
			},
			[35] = {
				mspdMultiplier = 0.09,     -- 9% movement speed increase
				immunityDuration = 18,     -- 18 seconds of status immunity
				duration = 45              -- 45 seconds
			},
			[45] = {
				mspdMultiplier = 0.1,      -- 10% movement speed increase
				immunityDuration = 20,     -- 20 seconds of status immunity
				duration = 50              -- 50 seconds
			}
		}
	},
	HuntersMark = {
		-- Buff: Increases Attack and Attack Speed
		levels = {
			[1] = {
				attackIncrease = 50,      -- +50 Attack
				attackSpeedIncrease = 0.5, -- +0.5 hit/s
				duration = 30              -- 30 seconds
			},
			[11] = {
				attackIncrease = 130,     -- +130 Attack
				attackSpeedIncrease = 0.5, -- +0.5 hit/s
				duration = 40              -- 40 seconds
			},
			[21] = {
				attackIncrease = 350,     -- +350 Attack
				attackSpeedIncrease = 0.5, -- +0.5 hit/s
				duration = 50              -- 50 seconds
			},
			[31] = {
				attackIncrease = 850,     -- +850 Attack
				attackSpeedIncrease = 1.0, -- +1 hit/s
				duration = 60              -- 60 seconds
			},
			[41] = {
				attackIncrease = 2300,    -- +2300 Attack
				attackSpeedIncrease = 1.0, -- +1 hit/s
				duration = 80              -- 80 seconds
			}
		}
	}
}

-- Samurai Buffs
ServerConfigs.SamuraiBuffs = {
	Banzai = {
		-- Buff: Creates static hitbox with small damage on use, provides immunity to damage
		levels = {
			[5] = {
				damageMultiplier = 0.1,  -- 10% of MaxAttack for small damage
				duration = 10              -- 10 seconds
			},
			[15] = {
				damageMultiplier = 0.1,  -- 10% of MaxAttack for small damage
				duration = 12              -- 12 seconds
			},
			[25] = {
				damageMultiplier = 0.1,  -- 10% of MaxAttack for small damage
				duration = 15              -- 15 seconds
			},
			[35] = {
				damageMultiplier = 0.1,  -- 10% of MaxAttack for small damage
				duration = 18              -- 18 seconds
			},
			[45] = {
				damageMultiplier = 0.1,  -- 10% of MaxAttack for small damage
				duration = 20              -- 20 seconds
			}
		}
	},
	Bushido = {
		-- Buff: Prevents HP from hitting 0 (death prevention)
		levels = {
			[1] = {
				duration = 10              -- 10 seconds
			},
			[11] = {
				duration = 12              -- 12 seconds
			},
			[21] = {
				duration = 15              -- 15 seconds
			},
			[31] = {
				duration = 18              -- 18 seconds
			},
			[41] = {
				duration = 20              -- 20 seconds
			}
		}
	}
}

-- Function to get buff config for a level
-- @param buffName: "Warcry", "WarriorMight", "BloodThirst", "LastChance", "ChampionsCheer", "ChampionsBlood", "HuntersInstinct", "HuntersMark", "Banzai", or "Bushido"
-- @param playerLevel: Player's current level
-- @return: Buff config for that level or nil if not unlocked
function ServerConfigs.getBuffConfig(buffName, playerLevel)
	-- Check Knight buffs first
	local classBuffs = ServerConfigs.KnightBuffs
	if classBuffs and classBuffs[buffName] then
		local buffLevels = classBuffs[buffName].levels
		if buffLevels then
			-- Find the highest unlocked level for this buff
			local highestUnlocked = nil
			for level, config in pairs(buffLevels) do
				if playerLevel >= level then
					if not highestUnlocked or level > highestUnlocked then
						highestUnlocked = level
					end
				end
			end
			
			if highestUnlocked then
				return buffLevels[highestUnlocked]
			end
		end
	end
	
	-- Check Brawler buffs
	local brawlerBuffs = ServerConfigs.BrawlerBuffs
	if brawlerBuffs and brawlerBuffs[buffName] then
		local buffLevels = brawlerBuffs[buffName].levels
		if buffLevels then
			-- Find the highest unlocked level for this buff
			local highestUnlocked = nil
			for level, config in pairs(buffLevels) do
				if playerLevel >= level then
					if not highestUnlocked or level > highestUnlocked then
						highestUnlocked = level
					end
				end
			end
			
			if highestUnlocked then
				return buffLevels[highestUnlocked]
			end
		end
	end
	
	-- Check Gladiator buffs
	local gladiatorBuffs = ServerConfigs.GladiatorBuffs
	if gladiatorBuffs and gladiatorBuffs[buffName] then
		local buffLevels = gladiatorBuffs[buffName].levels
		if buffLevels then
			-- Find the highest unlocked level for this buff
			local highestUnlocked = nil
			for level, config in pairs(buffLevels) do
				if playerLevel >= level then
					if not highestUnlocked or level > highestUnlocked then
						highestUnlocked = level
					end
				end
			end
			
			if highestUnlocked then
				return buffLevels[highestUnlocked]
			end
		end
	end
	
	-- Check Archer buffs
	local archerBuffs = ServerConfigs.ArcherBuffs
	if archerBuffs and archerBuffs[buffName] then
		local buffLevels = archerBuffs[buffName].levels
		if buffLevels then
			-- Find the highest unlocked level for this buff
			local highestUnlocked = nil
			for level, config in pairs(buffLevels) do
				if playerLevel >= level then
					if not highestUnlocked or level > highestUnlocked then
						highestUnlocked = level
					end
				end
			end
			
			if highestUnlocked then
				return buffLevels[highestUnlocked]
			end
		end
	end
	
	-- Check Samurai buffs
	local samuraiBuffs = ServerConfigs.SamuraiBuffs
	if samuraiBuffs and samuraiBuffs[buffName] then
		local buffLevels = samuraiBuffs[buffName].levels
		if buffLevels then
			-- Find the highest unlocked level for this buff
			local highestUnlocked = nil
			for level, config in pairs(buffLevels) do
				if playerLevel >= level then
					if not highestUnlocked or level > highestUnlocked then
						highestUnlocked = level
					end
				end
			end
			
			if highestUnlocked then
				return buffLevels[highestUnlocked]
			end
		end
	end
	
	return nil
end

-- Function to get minimum required level for a buff
-- @param buffName: "Warcry", "WarriorMight", "BloodThirst", "LastChance", "ChampionsCheer", "ChampionsBlood", "HuntersInstinct", or "HuntersMark"
-- @return: Minimum level required or nil if buff doesn't exist
function ServerConfigs.getBuffMinLevel(buffName)
	-- Check Knight buffs first
	local classBuffs = ServerConfigs.KnightBuffs
	if classBuffs and classBuffs[buffName] then
		local buffLevels = classBuffs[buffName].levels
		if buffLevels then
			-- Find the lowest level requirement
			local minLevel = nil
			for level, _ in pairs(buffLevels) do
				if not minLevel or level < minLevel then
					minLevel = level
				end
			end
			return minLevel
		end
	end
	
	-- Check Brawler buffs
	local brawlerBuffs = ServerConfigs.BrawlerBuffs
	if brawlerBuffs and brawlerBuffs[buffName] then
		local buffLevels = brawlerBuffs[buffName].levels
		if buffLevels then
			-- Find the lowest level requirement
			local minLevel = nil
			for level, _ in pairs(buffLevels) do
				if not minLevel or level < minLevel then
					minLevel = level
				end
			end
			return minLevel
		end
	end
	
	-- Check Gladiator buffs
	local gladiatorBuffs = ServerConfigs.GladiatorBuffs
	if gladiatorBuffs and gladiatorBuffs[buffName] then
		local buffLevels = gladiatorBuffs[buffName].levels
		if buffLevels then
			-- Find the lowest level requirement
			local minLevel = nil
			for level, _ in pairs(buffLevels) do
				if not minLevel or level < minLevel then
					minLevel = level
				end
			end
			return minLevel
		end
	end
	
	-- Check Archer buffs
	local archerBuffs = ServerConfigs.ArcherBuffs
	if archerBuffs and archerBuffs[buffName] then
		local buffLevels = archerBuffs[buffName].levels
		if buffLevels then
			-- Find the lowest level requirement
			local minLevel = nil
			for level, _ in pairs(buffLevels) do
				if not minLevel or level < minLevel then
					minLevel = level
				end
			end
			return minLevel
		end
	end
	
	-- Check Samurai buffs
	local samuraiBuffs = ServerConfigs.SamuraiBuffs
	if samuraiBuffs and samuraiBuffs[buffName] then
		local buffLevels = samuraiBuffs[buffName].levels
		if buffLevels then
			-- Find the lowest level requirement
			local minLevel = nil
			for level, _ in pairs(buffLevels) do
				if not minLevel or level < minLevel then
					minLevel = level
				end
			end
			return minLevel
		end
	end
	
	return nil
end

-- ========================================
-- KNIGHT PASSIVE CONFIGURATIONS
-- ========================================

ServerConfigs.KnightPassives = {
	Tenacity = {
		-- Passive: Increases Defense when HP < 30%
		levels = {
			[1] = {
				defenseIncrease = 100,  -- +100 Defense
			},
			[11] = {
				defenseIncrease = 200,  -- +200 Defense
			},
			[21] = {
				defenseIncrease = 400,  -- +400 Defense
			},
			[31] = {
				defenseIncrease = 800,  -- +800 Defense
			},
			[41] = {
				defenseIncrease = 1600, -- +1600 Defense
			}
		},
		hpThreshold = 0.3  -- 30% HP threshold
	},
	KnightsBlade = {
		-- Passive: 2nd combo attack has chance to hit twice (double damage)
		levels = {
			[5] = {
				chance = 10,  -- 10% chance
			},
			[15] = {
				chance = 15,  -- 15% chance
			},
			[25] = {
				chance = 20,  -- 20% chance
			},
			[35] = {
				chance = 25,  -- 25% chance
			},
			[45] = {
				chance = 30,  -- 30% chance
			}
		}
	}
}

-- Function to get passive config for a level
-- @param passiveName: "Tenacity" or "KnightsBlade"
-- @param playerLevel: Player's current level
-- @return: Passive config for that level or nil if not unlocked
function ServerConfigs.getPassiveConfig(passiveName, playerLevel)
	local classPassives = ServerConfigs.KnightPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the highest unlocked level for this passive
	local highestUnlocked = nil
	for level, config in pairs(passiveLevels) do
		if playerLevel >= level then
			if not highestUnlocked or level > highestUnlocked then
				highestUnlocked = level
			end
		end
	end
	
	if highestUnlocked then
		return passiveLevels[highestUnlocked]
	end
	
	return nil
end

-- Function to get minimum required level for a passive
-- @param passiveName: "Tenacity" or "KnightsBlade"
-- @return: Minimum level required or nil if passive doesn't exist
function ServerConfigs.getPassiveMinLevel(passiveName)
	local classPassives = ServerConfigs.KnightPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the lowest level requirement
	local minLevel = nil
	for level, _ in pairs(passiveLevels) do
		if not minLevel or level < minLevel then
			minLevel = level
		end
	end
	
	return minLevel
end

-- ========================================
-- BRAWLER PASSIVE CONFIGURATIONS
-- ========================================

ServerConfigs.BrawlerPassives = {
	Rage = {
		-- Passive: Increases Attack and Attack Speed when HP < 30%
		levels = {
			[1] = {
				attackIncrease = 45,      -- +45 Attack
				attackSpeedIncrease = 0.5 -- +0.5 hit/s
			},
			[11] = {
				attackIncrease = 100,     -- +100 Attack
				attackSpeedIncrease = 0.5  -- +0.5 hit/s
			},
			[21] = {
				attackIncrease = 250,      -- +250 Attack
				attackSpeedIncrease = 0.5  -- +0.5 hit/s
			},
			[31] = {
				attackIncrease = 600,      -- +600 Attack
				attackSpeedIncrease = 1.0  -- +1 hit/s
			},
			[41] = {
				attackIncrease = 1200,     -- +1200 Attack
				attackSpeedIncrease = 1.0  -- +1 hit/s
			}
		},
		hpThreshold = 0.3  -- 30% HP threshold
	},
	Madness = {
		-- Passive: Provides chance to stun on attacks when HP < 30%
		levels = {
			[5] = {
				stunChance = 3,  -- 3% chance to stun
			},
			[15] = {
				stunChance = 5,  -- 5% chance to stun
			},
			[25] = {
				stunChance = 10, -- 10% chance to stun
			},
			[35] = {
				stunChance = 13, -- 13% chance to stun
			},
			[45] = {
				stunChance = 15, -- 15% chance to stun
			}
		},
		hpThreshold = 0.3,  -- 30% HP threshold
		stunDuration = 2.0  -- 2 seconds stun duration
	}
}

-- Function to get brawler passive config for a level
-- @param passiveName: "Rage" or "Madness"
-- @param playerLevel: Player's current level
-- @return: Passive config for that level or nil if not unlocked
function ServerConfigs.getBrawlerPassiveConfig(passiveName, playerLevel)
	local classPassives = ServerConfigs.BrawlerPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the highest unlocked level for this passive
	local highestUnlocked = nil
	for level, config in pairs(passiveLevels) do
		if playerLevel >= level then
			if not highestUnlocked or level > highestUnlocked then
				highestUnlocked = level
			end
		end
	end
	
	if highestUnlocked then
		return passiveLevels[highestUnlocked]
	end
	
	return nil
end

-- Function to get minimum required level for a brawler passive
-- @param passiveName: "Rage" or "Madness"
-- @return: Minimum level required or nil if passive doesn't exist
function ServerConfigs.getBrawlerPassiveMinLevel(passiveName)
	local classPassives = ServerConfigs.BrawlerPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the lowest level requirement
	local minLevel = nil
	for level, _ in pairs(passiveLevels) do
		if not minLevel or level < minLevel then
			minLevel = level
		end
	end
	
	return minLevel
end

-- ========================================
-- GLADIATOR PASSIVE CONFIGURATIONS
-- ========================================

ServerConfigs.GladiatorPassives = {
	ChampionsRebuke = {
		-- Passive: 2nd combo attack has chance to hit twice (double damage)
		levels = {
			[5] = {
				chance = 10,  -- 10% chance
			},
			[15] = {
				chance = 15,  -- 15% chance
			},
			[25] = {
				chance = 20,  -- 20% chance
			},
			[35] = {
				chance = 25,  -- 25% chance
			},
			[45] = {
				chance = 30,  -- 30% chance
			}
		}
	},
	OneLastChance = {
		-- Passive: Resurrects player when HP reaches 0
		levels = {
			[1] = {
				resurrectHPPercentage = 0.1,  -- 10% of Max HP
			},
			[11] = {
				resurrectHPPercentage = 0.15, -- 15% of Max HP
			},
			[21] = {
				resurrectHPPercentage = 0.2,  -- 20% of Max HP
			},
			[31] = {
				resurrectHPPercentage = 0.25,  -- 25% of Max HP
			},
			[41] = {
				resurrectHPPercentage = 0.3,   -- 30% of Max HP
			}
		}
	}
}

-- Function to get gladiator passive config for a level
-- @param passiveName: "ChampionsRebuke" or "OneLastChance"
-- @param playerLevel: Player's current level
-- @return: Passive config for that level or nil if not unlocked
function ServerConfigs.getGladiatorPassiveConfig(passiveName, playerLevel)
	local classPassives = ServerConfigs.GladiatorPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the highest unlocked level for this passive
	local highestUnlocked = nil
	for level, config in pairs(passiveLevels) do
		if playerLevel >= level then
			if not highestUnlocked or level > highestUnlocked then
				highestUnlocked = level
			end
		end
	end
	
	if highestUnlocked then
		return passiveLevels[highestUnlocked]
	end
	
	return nil
end

-- Function to get minimum required level for a gladiator passive
-- @param passiveName: "ChampionsRebuke" or "OneLastChance"
-- @return: Minimum level required or nil if passive doesn't exist
function ServerConfigs.getGladiatorPassiveMinLevel(passiveName)
	local classPassives = ServerConfigs.GladiatorPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the lowest level requirement
	local minLevel = nil
	for level, _ in pairs(passiveLevels) do
		if not minLevel or level < minLevel then
			minLevel = level
		end
	end
	
	return minLevel
end

-- ========================================
-- ARCHER PASSIVE CONFIGURATIONS
-- ========================================

ServerConfigs.ArcherPassives = {
	Headshot = {
		-- Passive: Attacks have chance to deal double damage (x2)
		levels = {
			[1] = {
				chance = 10,  -- 10% chance
			},
			[11] = {
				chance = 12,  -- 12% chance
			},
			[21] = {
				chance = 15,  -- 15% chance
			},
			[31] = {
				chance = 18,  -- 18% chance
			},
			[41] = {
				chance = 20,  -- 20% chance
			}
		}
	},
	Immobilize = {
		-- Passive: Attacks have chance to stun targets
		levels = {
			[5] = {
				stunChance = 5,  -- 5% chance to stun
			},
			[15] = {
				stunChance = 8,  -- 8% chance to stun
			},
			[25] = {
				stunChance = 10, -- 10% chance to stun
			},
			[35] = {
				stunChance = 13, -- 13% chance to stun
			},
			[45] = {
				stunChance = 15, -- 15% chance to stun
			}
		},
		stunDuration = 2.0  -- 2 seconds stun duration
	}
}

-- Function to get archer passive config for a level
-- @param passiveName: "Headshot" or "Immobilize"
-- @param playerLevel: Player's current level
-- @return: Passive config for that level or nil if not unlocked
function ServerConfigs.getArcherPassiveConfig(passiveName, playerLevel)
	local classPassives = ServerConfigs.ArcherPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the highest unlocked level for this passive
	local highestUnlocked = nil
	for level, config in pairs(passiveLevels) do
		if playerLevel >= level then
			if not highestUnlocked or level > highestUnlocked then
				highestUnlocked = level
			end
		end
	end
	
	if highestUnlocked then
		return passiveLevels[highestUnlocked]
	end
	
	return nil
end

-- Function to get minimum required level for an archer passive
-- @param passiveName: "Headshot" or "Immobilize"
-- @return: Minimum level required or nil if passive doesn't exist
function ServerConfigs.getArcherPassiveMinLevel(passiveName)
	local classPassives = ServerConfigs.ArcherPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the lowest level requirement
	local minLevel = nil
	for level, _ in pairs(passiveLevels) do
		if not minLevel or level < minLevel then
			minLevel = level
		end
	end
	
	return minLevel
end

-- ========================================
-- SAMURAI PASSIVE CONFIGURATIONS
-- ========================================

ServerConfigs.SamuraiPassives = {
	BladeDance = {
		-- Passive: Adds Attack stat on attacks (HP-based with different chances, same multiplier)
		levels = {
			[1] = {
				attackIncrease = 100,  -- +100 Attack (same for both HP conditions)
				chance = 5,            -- 5% chance when HP>30%
			},
			[11] = {
				attackIncrease = 200,  -- +200 Attack (same for both HP conditions)
				chance = 6,            -- 6% chance when HP>30%
			},
			[21] = {
				attackIncrease = 400,  -- +400 Attack (same for both HP conditions)
				chance = 7,            -- 7% chance when HP>30%
			},
			[31] = {
				attackIncrease = 800,  -- +800 Attack (same for both HP conditions)
				chance = 8,            -- 8% chance when HP>30%
			},
			[41] = {
				attackIncrease = 1600, -- +1600 Attack (same for both HP conditions)
				chance = 10,           -- 10% chance when HP>30%
			}
		},
		hpThreshold = 0.3,  -- 30% HP threshold
		lowHPChanceMultiplier = 2.0  -- HP<30% gets 2x the base chance (much larger chance)
	},
	Burst = {
		-- Passive: Combo2 attack has chance to deal double damage (x2)
		levels = {
			[5] = {
				chanceHighHP = 5,   -- 5% chance when HP>30%
				chanceLowHP = 10,   -- 10% chance when HP<30% (much larger chance)
			},
			[15] = {
				chanceHighHP = 6,   -- 6% chance when HP>30%
				chanceLowHP = 12,   -- 12% chance when HP<30% (much larger chance)
			},
			[25] = {
				chanceHighHP = 7,   -- 7% chance when HP>30%
				chanceLowHP = 14,   -- 14% chance when HP<30% (much larger chance)
			},
			[35] = {
				chanceHighHP = 8,   -- 8% chance when HP>30%
				chanceLowHP = 16,   -- 16% chance when HP<30% (much larger chance)
			},
			[45] = {
				chanceHighHP = 10,  -- 10% chance when HP>30%
				chanceLowHP = 20,   -- 20% chance when HP<30% (much larger chance)
			}
		},
		hpThreshold = 0.3  -- 30% HP threshold
	}
}

-- Function to get samurai passive config for a level
-- @param passiveName: "BladeDance" or "Burst"
-- @param playerLevel: Player's current level
-- @return: Passive config for that level or nil if not unlocked
function ServerConfigs.getSamuraiPassiveConfig(passiveName, playerLevel)
	local classPassives = ServerConfigs.SamuraiPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the highest unlocked level for this passive
	local highestUnlocked = nil
	for level, config in pairs(passiveLevels) do
		if playerLevel >= level then
			if not highestUnlocked or level > highestUnlocked then
				highestUnlocked = level
			end
		end
	end
	
	if highestUnlocked then
		return passiveLevels[highestUnlocked]
	end
	
	return nil
end

-- Function to get minimum required level for a samurai passive
-- @param passiveName: "BladeDance" or "Burst"
-- @return: Minimum level required or nil if passive doesn't exist
function ServerConfigs.getSamuraiPassiveMinLevel(passiveName)
	local classPassives = ServerConfigs.SamuraiPassives
	if not classPassives or not classPassives[passiveName] then
		return nil
	end
	
	local passiveLevels = classPassives[passiveName].levels
	if not passiveLevels then
		return nil
	end
	
	-- Find the lowest level requirement
	local minLevel = nil
	for level, _ in pairs(passiveLevels) do
		if not minLevel or level < minLevel then
			minLevel = level
		end
	end
	
	return minLevel
end

-- ========================================
-- DEFENSE REGENERATION CONFIGURATION
-- ========================================

ServerConfigs.DefenseRegen = {
	enabled = true,
	regenRate = 1,          -- Defense points per second
	tickInterval = 1        -- Update every second
}

return ServerConfigs
