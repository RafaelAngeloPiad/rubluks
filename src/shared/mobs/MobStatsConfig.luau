-- ========================================
-- MOB STATS CONFIGURATION
-- Centralized stats for all mob variants
-- ========================================

local MobStatsConfig = {}

-- ========================================
-- Golem Stats
-- ========================================

-- IF you reach a certain level - all xpgains of the cap will only be small

MobStatsConfig.Golem_Sand = {
	HP = 500,
	Defense = 3,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	XPGain = 20,
	LvlCap = 7,
	CappedXPGain = 0.5,
	StatusAilment = {
		type = "stun",
		chance = 30,
		duration = 1.5
	}
}

MobStatsConfig.Golem_Ice = {
	HP = 500,
	Defense = 9,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "stun",
		chance = 35,
		duration = 1.8
	}
}

MobStatsConfig.Golem_Lava = {
	HP = 500,
	Defense = 15,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "stun",
		chance = 40,
		duration = 2.0
	}
}

MobStatsConfig.Golem_Woodland = {
	HP = 500,
	Defense = 20,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "stun",
		chance = 45,
		duration = 2.2
	}
}

MobStatsConfig.Golem_Lightning = {
	HP = 500,
	Defense = 21,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "stun",
		chance = 50,
		duration = 2.5
	}
}

MobStatsConfig.Golem_Crystal = {
	HP = 500,
	Defense = 33,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "stun",
		chance = 55,
		duration = 2.8
	}
}

MobStatsConfig.Golem_Poison = {
	HP = 500,
	Defense = 39,
	DefensePenetration = 50,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "stun",
		chance = 60,
		duration = 3.0
	}
}

-- ========================================
-- Spider Stats
-- ========================================

MobStatsConfig.Spider_Sand = {
	HP = 300,
	Defense = 2,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 30,
		duration = 4.0,
		dps = 3,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Ice = {
	HP = 300,
	Defense = 8,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 35,
		duration = 4.5,
		dps = 4,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Fire = {
	HP = 300,
	Defense = 14,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 40,
		duration = 5.0,
		dps = 5,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Woodland = {
	HP = 300,
	Defense = 20,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 45,
		duration = 5.5,
		dps = 6,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Lightning = {
	HP = 300,
	Defense = 26,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 50,
		duration = 6.0,
		dps = 7,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Crystal = {
	HP = 300,
	Defense = 32,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 55,
		duration = 6.5,
		dps = 8,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Poison = {
	HP = 300,
	Defense = 38,
	DefensePenetration = 20,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 60,
		duration = 7.0,
		dps = 10,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Spider_Dark = {
	HP = 300,
	Defense = 10,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 50,
	StatusAilment = {
		type = "poison",
		chance = 40,
		duration = 5.0,
		dps = 5,
		tickInterval = 1.0,
		skipDefense = true
	}
}

-- ========================================
-- Wraith Stats
-- ========================================

MobStatsConfig.Wraith_Sand = {
	HP = 400,
	Defense = 3,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 30,
		duration = 4.0,
		dps = 3,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Wraith_Ice = {
	HP = 400,
	Defense = 9,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 35,
		duration = 4.5,
		dps = 4,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Wraith_Lava = {
	HP = 400,
	Defense = 15,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 40,
		duration = 5.0,
		dps = 5,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Wraith_Woodland = {
	HP = 400,
	Defense = 20,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 45,
		duration = 5.5,
		dps = 6,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Wraith_Lightning = {
	HP = 400,
	Defense = 21,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 50,
		duration = 6.0,
		dps = 7,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Wraith_Crystal = {
	HP = 400,
	Defense = 33,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 55,
		duration = 6.5,
		dps = 8,
		tickInterval = 1.0,
		skipDefense = true
	}
}

MobStatsConfig.Wraith_Poison = {
	HP = 400,
	Defense = 39,
	DefensePenetration = 50,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 25,
	StatusAilment = {
		type = "burn",
		chance = 60,
		duration = 7.0,
		dps = 10,
		tickInterval = 1.0,
		skipDefense = true
	}
}

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

