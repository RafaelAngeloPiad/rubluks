-- ========================================
-- MOB STATS CONFIGURATION
-- Centralized stats for all mob variants
-- ========================================

local MobStatsConfig = {}

local DEFAULT_HEALTH_COLOR = Color3.fromRGB(120, 220, 120)

local COLOR_THEMES = {
	Sand = {
		name = Color3.fromRGB(210, 180, 140),
		health = Color3.fromRGB(240, 210, 160)
	},
	Ice = {
		name = Color3.fromRGB(110, 195, 255),
		health = Color3.fromRGB(150, 230, 255)
	},
	Lava = {
		name = Color3.fromRGB(255, 110, 60),
		health = Color3.fromRGB(255, 150, 100)
	},
	Fire = {
		name = Color3.fromRGB(255, 90, 60),
		health = Color3.fromRGB(255, 140, 100)
	},
	Woodland = {
		name = Color3.fromRGB(110, 200, 120),
		health = Color3.fromRGB(150, 230, 150)
	},
	Lightning = {
		name = Color3.fromRGB(255, 230, 90),
		health = Color3.fromRGB(255, 240, 150)
	},
	Crystal = {
		name = Color3.fromRGB(150, 120, 255),
		health = Color3.fromRGB(190, 170, 255)
	},
	Poison = {
		name = Color3.fromRGB(120, 255, 180),
		health = Color3.fromRGB(150, 255, 210)
	},
	Toxic = {
		name = Color3.fromRGB(90, 230, 90),
		health = Color3.fromRGB(130, 255, 140)
	},
	Light = {
		name = Color3.fromRGB(255, 250, 200),
		health = Color3.fromRGB(255, 255, 220)
	},
	Dark = {
		name = Color3.fromRGB(170, 80, 255),
		health = Color3.fromRGB(210, 140, 255)
	},
	Tornado = {
		name = Color3.fromRGB(160, 230, 255),
		health = Color3.fromRGB(200, 245, 255)
	},
Default = {
	name = Color3.fromRGB(255, 255, 255),
	health = DEFAULT_HEALTH_COLOR
}
}

local function applyTheme(stats, themeKey)
	local theme = COLOR_THEMES[themeKey] or COLOR_THEMES.Default
	stats.HealthBarColor = stats.HealthBarColor or theme.health
	return stats
end

-- ========================================
-- Spider Stats (fixed values)
-- ========================================

MobStatsConfig.Spider_Sand = applyTheme({
	Family = "Spider",
	Level = 2,
	DisplayName = "Sand Spider 2",
	HP = 260,
	Defense = 2,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 30,
	WalkSpeed = 18,
	XPGain = 8,
	StatusAilment = {
		type = "poison",
		chance = 30,
		duration = 3.6,
		dps = 3,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Sand")

MobStatsConfig.Spider_Ice = applyTheme({
	Family = "Spider",
	Level = 8,
	DisplayName = "Ice Spider 8",
	HP = 380,
	Defense = 4,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 39,
	WalkSpeed = 18,
	XPGain = 11,
	StatusAilment = {
		type = "poison",
		chance = 34,
		duration = 3.9,
		dps = 4,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Ice")

MobStatsConfig.Spider_Fire = applyTheme({
	Family = "Spider",
	Level = 14,
	DisplayName = "Fire Spider 14",
	HP = 500,
	Defense = 6,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 48,
	WalkSpeed = 19,
	XPGain = 14,
	StatusAilment = {
		type = "poison",
		chance = 39,
		duration = 4.1,
		dps = 6,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Fire")

MobStatsConfig.Spider_Woodland = applyTheme({
	Family = "Spider",
	Level = 20,
	DisplayName = "Woodland Spider 20",
	HP = 620,
	Defense = 8,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 57,
	WalkSpeed = 19,
	XPGain = 17,
	StatusAilment = {
		type = "poison",
		chance = 44,
		duration = 4.4,
		dps = 7,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Woodland")

MobStatsConfig.Spider_Lightning = applyTheme({
	Family = "Spider",
	Level = 26,
	DisplayName = "Lightning Spider 26",
	HP = 740,
	Defense = 10,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 65,
	WalkSpeed = 20,
	XPGain = 19,
	StatusAilment = {
		type = "poison",
		chance = 49,
		duration = 4.7,
		dps = 8,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Lightning")

MobStatsConfig.Spider_Crystal = applyTheme({
	Family = "Spider",
	Level = 32,
	DisplayName = "Crystal Spider 32",
	HP = 860,
	Defense = 12,
	DefensePenetration = 5,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 74,
	WalkSpeed = 20,
	XPGain = 22,
	StatusAilment = {
		type = "poison",
		chance = 54,
		duration = 4.9,
		dps = 10,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Crystal")

MobStatsConfig.Spider_Poison = applyTheme({
	Family = "Spider",
	Level = 38,
	DisplayName = "Poison Spider 38",
	HP = 980,
	Defense = 14,
	DefensePenetration = 15,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 83,
	WalkSpeed = 21,
	XPGain = 25,
	StatusAilment = {
		type = "poison",
		chance = 58,
		duration = 5.2,
		dps = 11,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Poison")

MobStatsConfig.Spider_Dark = applyTheme({
	Family = "Spider",
	Level = 44,
	DisplayName = "Dark Spider 44",
	HP = 1100,
	Defense = 16,
	DefensePenetration = 25,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 91,
	WalkSpeed = 21,
	XPGain = 27,
	StatusAilment = {
		type = "poison",
		chance = 63,
		duration = 5.5,
		dps = 12,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Dark")

-- ========================================
-- Golem Stats (fixed values)
-- ========================================

MobStatsConfig.Golem_Sand = applyTheme({
	Family = "Golem",
	Level = 3,
	DisplayName = "Sand Golem 3",
	HP = 492,
	Defense = 6,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 28,
	WalkSpeed = 10,
	XPGain = 22,
	StatusAilment = {
		type = "stun",
		chance = 35,
		duration = 1.5
	}
}, "Sand")

MobStatsConfig.Golem_Ice = applyTheme({
	Family = "Golem",
	Level = 9,
	DisplayName = "Ice Golem 9",
	HP = 636,
	Defense = 12,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 36,
	WalkSpeed = 10,
	XPGain = 28,
	StatusAilment = {
		type = "stun",
		chance = 38,
		duration = 1.7
	}
}, "Ice")

MobStatsConfig.Golem_Lava = applyTheme({
	Family = "Golem",
	Level = 15,
	DisplayName = "Lava Golem 15",
	HP = 780,
	Defense = 18,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 44,
	WalkSpeed = 10,
	XPGain = 33,
	StatusAilment = {
		type = "stun",
		chance = 42,
		duration = 1.9
	}
}, "Lava")

MobStatsConfig.Golem_Woodland = applyTheme({
	Family = "Golem",
	Level = 21,
	DisplayName = "Woodland Golem 21",
	HP = 924,
	Defense = 25,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 52,
	WalkSpeed = 11,
	XPGain = 38,
	StatusAilment = {
		type = "stun",
		chance = 46,
		duration = 2.0
	}
}, "Woodland")

MobStatsConfig.Golem_Lightning = applyTheme({
	Family = "Golem",
	Level = 27,
	DisplayName = "Lightning Golem 27",
	HP = 1068,
	Defense = 31,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 60,
	WalkSpeed = 11,
	XPGain = 44,
	StatusAilment = {
		type = "stun",
		chance = 50,
		duration = 2.2
	}
}, "Lightning")

MobStatsConfig.Golem_Crystal = applyTheme({
	Family = "Golem",
	Level = 33,
	DisplayName = "Crystal Golem 33",
	HP = 1212,
	Defense = 37,
	DefensePenetration = 10,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 68,
	WalkSpeed = 11,
	XPGain = 49,
	StatusAilment = {
		type = "stun",
		chance = 53,
		duration = 2.4
	}
}, "Crystal")

MobStatsConfig.Golem_Poison = applyTheme({
	Family = "Golem",
	Level = 39,
	DisplayName = "Poison Golem 39",
	HP = 1356,
	Defense = 43,
	DefensePenetration = 20,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 76,
	WalkSpeed = 12,
	XPGain = 55,
	StatusAilment = {
		type = "stun",
		chance = 57,
		duration = 2.6
	}
}, "Poison")

MobStatsConfig.Golem_Dark = applyTheme({
	Family = "Golem",
	Level = 45,
	DisplayName = "Dark Knight 45",
	HP = 1500,
	Defense = 50,
	DefensePenetration = 30,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 84,
	WalkSpeed = 12,
	XPGain = 60,
	StatusAilment = {
		type = "stun",
		chance = 61,
		duration = 2.8
	}
}, "Dark")

-- ========================================
-- Zombie Stats (fixed values)
-- ========================================

MobStatsConfig.Zombie_Sand = applyTheme({
	Family = "Zombie",
	Level = 7,
	DisplayName = "Sand Zombie 7",
	HP = 390,
	Defense = 8,
	DefensePenetration = 0,
	CritRate = 6,
	CritMultiplier = 155,
	Damage = 27,
	WalkSpeed = 11,
	XPGain = 16
}, "Sand")

MobStatsConfig.Zombie_Ice = applyTheme({
	Family = "Zombie",
	Level = 13,
	DisplayName = "Ice Zombie 13",
	HP = 470,
	Defense = 12,
	DefensePenetration = 0,
	CritRate = 7,
	CritMultiplier = 159,
	Damage = 34,
	WalkSpeed = 12,
	XPGain = 21
}, "Ice")

MobStatsConfig.Zombie_Lava = applyTheme({
	Family = "Zombie",
	Level = 19,
	DisplayName = "Fire Zombie 19",
	HP = 550,
	Defense = 16,
	DefensePenetration = 5,
	CritRate = 9,
	CritMultiplier = 164,
	Damage = 42,
	WalkSpeed = 12,
	XPGain = 27
}, "Lava")

MobStatsConfig.Zombie_Woodland = applyTheme({
	Family = "Zombie",
	Level = 25,
	DisplayName = "Woodland Zombie 25",
	HP = 625,
	Defense = 20,
	DefensePenetration = 10,
	CritRate = 10,
	CritMultiplier = 168,
	Damage = 50,
	WalkSpeed = 13,
	XPGain = 32
}, "Woodland")

MobStatsConfig.Zombie_Lightning = applyTheme({
	Family = "Zombie",
	Level = 31,
	DisplayName = "Lightning Zombie 31",
	HP = 700,
	Defense = 24,
	DefensePenetration = 15,
	CritRate = 11,
	CritMultiplier = 173,
	Damage = 58,
	WalkSpeed = 13,
	XPGain = 38
}, "Lightning")

MobStatsConfig.Zombie_Crystal = applyTheme({
	Family = "Zombie",
	Level = 37,
	DisplayName = "Crystal Zombie 37",
	HP = 780,
	Defense = 28,
	DefensePenetration = 20,
	CritRate = 12,
	CritMultiplier = 177,
	Damage = 66,
	WalkSpeed = 14,
	XPGain = 43
}, "Crystal")

MobStatsConfig.Zombie_Poison = applyTheme({
	Family = "Zombie",
	Level = 43,
	DisplayName = "Toxic Zombie 43",
	HP = 860,
	Defense = 32,
	DefensePenetration = 30,
	CritRate = 14,
	CritMultiplier = 182,
	Damage = 74,
	WalkSpeed = 14,
	XPGain = 48
}, "Toxic")

MobStatsConfig.Zombie_Dark = applyTheme({
	Family = "Zombie",
	Level = 49,
	DisplayName = "Zomben 49",
	HP = 940,
	Defense = 36,
	DefensePenetration = 40,
	CritRate = 15,
	CritMultiplier = 186,
	Damage = 82,
	WalkSpeed = 15,
	XPGain = 54
}, "Dark")

-- ========================================
-- Wraith Stats (fixed values)
-- ========================================

MobStatsConfig.Wraith_Sand = applyTheme({
	Family = "Wraith",
	Level = 44,
	DisplayName = "Sand Wraith 44",
	HP = 1130,
	Defense = 40,
	DefensePenetration = 0,
	CritRate = 14,
	CritMultiplier = 186,
	Damage = 86,
	WalkSpeed = 15,
	XPGain = 82,
	StatusAilment = {
		type = "burn",
		chance = 58,
		duration = 5.3,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Sand")

MobStatsConfig.Wraith_Ice = applyTheme({
	Family = "Wraith",
	Level = 45,
	DisplayName = "Poison Wraith 45",
	HP = 1150,
	Defense = 41,
	DefensePenetration = 5,
	CritRate = 14,
	CritMultiplier = 187,
	Damage = 87,
	WalkSpeed = 15,
	XPGain = 84,
	StatusAilment = {
		type = "burn",
		chance = 59,
		duration = 5.4,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Poison")

MobStatsConfig.Wraith_Lava = applyTheme({
	Family = "Wraith",
	Level = 46,
	DisplayName = "Fire Wraith 46",
	HP = 1170,
	Defense = 42,
	DefensePenetration = 7,
	CritRate = 14,
	CritMultiplier = 188,
	Damage = 88,
	WalkSpeed = 15,
	XPGain = 85,
	StatusAilment = {
		type = "burn",
		chance = 60,
		duration = 5.4,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Fire")

MobStatsConfig.Wraith_Woodland = applyTheme({
	Family = "Wraith",
	Level = 47,
	DisplayName = "Crystal Wraith 47",
	HP = 1185,
	Defense = 43,
	DefensePenetration = 10,
	CritRate = 14,
	CritMultiplier = 188,
	Damage = 90,
	WalkSpeed = 15,
	XPGain = 86,
	StatusAilment = {
		type = "burn",
		chance = 60,
		duration = 5.4,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Crystal")

MobStatsConfig.Wraith_Lightning = applyTheme({
	Family = "Wraith",
	Level = 48,
	DisplayName = "Light Wraith 48",
	HP = 1205,
	Defense = 44,
	DefensePenetration = 12,
	CritRate = 15,
	CritMultiplier = 189,
	Damage = 91,
	WalkSpeed = 15,
	XPGain = 88,
	StatusAilment = {
		type = "burn",
		chance = 61,
		duration = 5.4,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Light")

MobStatsConfig.Wraith_Crystal = applyTheme({
	Family = "Wraith",
	Level = 49,
	DisplayName = "Ice Wraith 49",
	HP = 1220,
	Defense = 45,
	DefensePenetration = 15,
	CritRate = 15,
	CritMultiplier = 190,
	Damage = 93,
	WalkSpeed = 15,
	XPGain = 89,
	StatusAilment = {
		type = "burn",
		chance = 62,
		duration = 5.5,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Ice")

MobStatsConfig.Wraith_Poison = applyTheme({
	Family = "Wraith",
	Level = 50,
	DisplayName = "Tornado Wraith 50",
	HP = 1240,
	Defense = 46,
	DefensePenetration = 18,
	CritRate = 15,
	CritMultiplier = 190,
	Damage = 94,
	WalkSpeed = 16,
	XPGain = 90,
	StatusAilment = {
		type = "burn",
		chance = 62,
		duration = 5.5,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Tornado")

MobStatsConfig.Wraith_Dark = applyTheme({
	Family = "Wraith",
	Level = 51,
	DisplayName = "Dark Wraith 51",
	HP = 1260,
	Defense = 47,
	DefensePenetration = 20,
	CritRate = 15,
	CritMultiplier = 191,
	Damage = 95,
	WalkSpeed = 16,
	XPGain = 91,
	StatusAilment = {
		type = "burn",
		chance = 63,
		duration = 5.5,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Dark")

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to apply stats to a mob model
-- @param model: The mob model
-- @param variantName: The variant name (e.g., "Golem_Sand", "Spider_Ice")
-- 
-- STATS FLOW:
-- 1. Stats applied to model attributes (MaxDefense, CurrentDefense, Damage, etc.)
-- 2. DynamicHitboxV3 reads these attributes when damage is calculated
-- 3. Defense system automatically uses CurrentDefense/MaxDefense from attributes
-- 4. All hitbox types (Static, DOT, Traveling, Projectile) work with this system
function MobStatsConfig.applyStats(model, variantName)
	if not model or not model.Parent then
		return false
	end
	
	local stats = MobStatsConfig[variantName]
	if not stats then
		warn("MobStatsConfig: Invalid variant name:", variantName)
		return false
	end
	
	-- Get humanoid to set health
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = stats.HP
		humanoid.Health = stats.HP
		if stats.WalkSpeed then
			humanoid.WalkSpeed = stats.WalkSpeed
		end
		humanoid.DisplayName = stats.DisplayName or variantName
		humanoid.NameDisplayDistance = stats.NameDisplayDistance or 100
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	end
	
	-- Set attributes for all stats (used by damage system)
	-- NOTE: These attributes are read by DynamicHitboxV3.getDefenseStats() 
	-- when calculating damage in calculateDamageWithDefense()
	model:SetAttribute("MaxDefense", stats.Defense)
	model:SetAttribute("CurrentDefense", stats.Defense)
	model:SetAttribute("DefensePenetration", stats.DefensePenetration or 0)
	model:SetAttribute("CritRate", stats.CritRate or 0)
	model:SetAttribute("CritMultiplier", stats.CritMultiplier or 150)
	model:SetAttribute("Damage", stats.Damage or 0)
	model:SetAttribute("WalkSpeed", stats.WalkSpeed or humanoid and humanoid.WalkSpeed or 0)
	model:SetAttribute("XPGain", stats.XPGain or 0)
	model:SetAttribute("MobDisplayName", stats.DisplayName or variantName)
	model:SetAttribute("MobLevel", stats.Level or 0)
	model:SetAttribute("MobHealthBarColor", stats.HealthBarColor or DEFAULT_HEALTH_COLOR)
	
	-- Store variant name for easy access
	model:SetAttribute("MobVariant", variantName)
	
	return true
end

-- Function to get stats for a variant name
function MobStatsConfig.getStats(variantName)
	return MobStatsConfig[variantName]
end

-- Function to update a mob's damage value (useful for temporary buffs/debuffs)
function MobStatsConfig.updateDamage(model, newDamage)
	if not model or not model.Parent then
		return false
	end
	
	model:SetAttribute("Damage", newDamage)
	return true
end

return MobStatsConfig

