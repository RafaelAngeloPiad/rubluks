--[[
	EquipmentBonusConfig
	--------------------
	Maps weapon / accessory names (as stored in InventoryStore and tool instances) to stat bonuses.
	Each entry can optionally provide:
		- `assetName` when the Tool instance name differs from the canonical inventory name.
		- Stat modifiers recognised by PlayerManager (HPPlus, AttackPlus, DefensePlus,
		  DefensePenPlus, CritRatePlus, CritMultiplierPlus).
		- `statusAilment` to automatically apply a status effect when the weapon hits an enemy.
		  Supported keys mirror hitbox configuration: `type`, `chance`, `duration`, `dps`,
		  `tickInterval`, `slowMultiplier`, `skipDefense`.

	Example:
	["Samurai Weapon Trailed"] = {
		assetName = "Samurai Weapon Trailed", -- Optional when identical
		HPPlus = 500,
		AttackPlus = 75,
	}

	You can remove the example entries below and configure your own.
--]]


-- local EquipmentStatMappings = {
-- 	HPPlus = {leaderstat = "MaxHealth", displayName = "HP"},
-- 	AttackPlus = {leaderstat = "MaxAttack", displayName = "Attack"},
-- 	DefensePlus = {leaderstat = "MaxDefense", displayName = "Defense"},
-- 	DefensePenPlus = {leaderstat = "DefensePenetration", displayName = "Defense Penetration"},
-- 	CritRatePlus = {leaderstat = "CritRate", displayName = "Crit Rate"},
-- 	CritMultiplierPlus = {leaderstat = "CritMultiplier", displayName = "Crit Multiplier"},
-- }

-- hindi literal na inventory - kunyari lang .. tapos tayo may mga boolean dito kung nakaequip ba , tapos 
-- dun irereference ng gui. based sa pangalan nung nakaequip
-- level requirement dapat and class 
-- pero pag accessory kahit kanino yun
-- tsaka armor kahit kanino

local Entries = {
	-- ========================================
	-- SWORD AND SHIELD WEAPONS
	-- ========================================
	
	["Slavkoria Sword"] = {
		AttackPlus = 12,
		DefensePlus = 12,
	},
	
	["Lohergin"] = {
		AttackPlus = 15,
		DefensePlus = 15,
	},
	
	["Claymore"] = {
		AttackPlus = 20,
		DefensePlus = 20,
	},
	
	["Hardege"] = {
		AttackPlus = 25,
		DefensePlus = 25,
	},
	
	["Durandal"] = {
		AttackPlus = 45,
		DefensePlus = 45,
		statusAilment = {
			type = "burn",
			chance = 15,
			duration = 3.0,
			dps = 5,
			tickInterval = 1.0,
		},
	},
	
	["Dragon Slayer"] = {
		AttackPlus = 75,
		DefensePlus = 75,
		statusAilment = {
			type = "burn",
			chance = 20,
			duration = 4.0,
			dps = 8,
			tickInterval = 1.0,
		},
	},
	
	["Joyeuse"] = {
		AttackPlus = 160,
		DefensePlus = 160,
	},
	
	["Excalibur"] = {
		AttackPlus = 300,
		DefensePlus = 300,
		statusAilment = {
			type = "stun",
			chance = 8,
			duration = 1.5,
		},
	},
	
	["Save the Queen"] = {
		AttackPlus = 750,
		DefensePlus = 750,
	},
	
	["End Bringer"] = {
		AttackPlus = 1800,
		DefensePlus = 1800,
		statusAilment = {
			type = "poison",
			chance = 25,
			duration = 5.0,
			dps = 50,
			tickInterval = 1.0,
		},
	},
	
	["Slav's Peacekeeper"] = {
		AttackPlus = 4500,
		DefensePlus = 4500,
		statusAilment = {
			type = "stun",
			chance = 12,
			duration = 2.0,
		},
	},
	
	-- ========================================
	-- CLAWS WEAPONS
	-- ========================================
	
	["Slavkorian Assassin's Claw"] = {
		AttackPlus = 20,
	},
	
	["Ice Golem's Claws"] = {
		AttackPlus = 26,
		statusAilment = {
			type = "ice",
			chance = 20,
			duration = 2.0,
			dps = 3,
			tickInterval = 1.0,
			slowMultiplier = 0.6,
		},
	},
	
	["King Crab Smashers"] = {
		AttackPlus = 30,
	},
	
	["Skeleton Gloves"] = {
		AttackPlus = 45,
	},
	
	["Steampunk Gloves"] = {
		AttackPlus = 70,
	},
	
	["Giant Golden Bull Gauntlet"] = {
		AttackPlus = 120,
		statusAilment = {
			type = "slow",
			chance = 25,
			duration = 3.0,
			slowMultiplier = 0.5,
		},
	},
	
	["Steampunk Claws"] = {
		AttackPlus = 250,
	},
	
	["Giant Demonic Dragon Gauntlet"] = {
		AttackPlus = 480,
		statusAilment = {
			type = "burn",
			chance = 30,
			duration = 4.0,
			dps = 15,
			tickInterval = 1.0,
		},
	},
	
	["Mantis Blades"] = {
		AttackPlus = 1200,
		statusAilment = {
			type = "poison",
			chance = 20,
			duration = 5.0,
			dps = 30,
			tickInterval = 1.0,
		},
	},
	
	["Nidavellir's Instruments"] = {
		AttackPlus = 2900,
	},
	
	["Blades of Chaos"] = {
		AttackPlus = 7200,
		statusAilment = {
			type = "burn",
			chance = 35,
			duration = 6.0,
			dps = 80,
			tickInterval = 1.0,
		},
	},
	
	-- ========================================
	-- KATANA WEAPONS
	-- ========================================
	
	["The Chosen One"] = {
		AttackPlus = 25,
	},
	
	["Boar Tusk Katana"] = {
		AttackPlus = 30,
	},
	
	["Wind Blade"] = {
		AttackPlus = 40,
	},
	
	["Lightning Nichirin"] = {
		AttackPlus = 50,
		statusAilment = {
			type = "stun",
			chance = 10,
			duration = 1.0,
		},
	},
	
	["Serpent's Venom"] = {
		AttackPlus = 90,
		statusAilment = {
			type = "poison",
			chance = 30,
			duration = 4.0,
			dps = 10,
			tickInterval = 1.0,
		},
	},
	
	["Tensa Zangetsu"] = {
		AttackPlus = 150,
	},
	
	["Flesh Nichirin"] = {
		AttackPlus = 320,
	},
	
	["Zabimaru"] = {
		AttackPlus = 600,
	},
	
	["Danto"] = {
		AttackPlus = 1500,
	},
	
	["Flashy Ninja's Slasher"] = {
		AttackPlus = 3600,
		statusAilment = {
			type = "slow",
			chance = 30,
			duration = 3.0,
			slowMultiplier = 0.4,
		},
	},
	
	["Yoru"] = {
		AttackPlus = 9000,
		statusAilment = {
			type = "stun",
			chance = 15,
			duration = 2.5,
		},
	},
	
	-- ========================================
	-- SPEAR AND SHIELD WEAPONS
	-- ========================================
	
	["Slavkorian Spear"] = {
		AttackPlus = 10,
		DefensePlus = 14,
	},
	
	["Ancestor's Spear"] = {
		AttackPlus = 13,
		DefensePlus = 17,
	},
	
	["Crood's Tooth"] = {
		AttackPlus = 15,
		DefensePlus = 25,
	},
	
	["Primal Spear"] = {
		AttackPlus = 20,
		DefensePlus = 30,
	},
	
	["Sun God's Impaler"] = {
		AttackPlus = 35,
		DefensePlus = 55,
		statusAilment = {
			type = "burn",
			chance = 18,
			duration = 3.0,
			dps = 6,
			tickInterval = 1.0,
		},
	},
	
	["Dragoon's Lance"] = {
		AttackPlus = 60,
		DefensePlus = 90,
	},
	
	["Champion's Spear"] = {
		AttackPlus = 120,
		DefensePlus = 200,
	},
	
	["Hell's Halberd"] = {
		AttackPlus = 250,
		DefensePlus = 350,
		statusAilment = {
			type = "burn",
			chance = 25,
			duration = 5.0,
			dps = 20,
			tickInterval = 1.0,
		},
	},
	
	["Partisan's Lance"] = {
		AttackPlus = 600,
		DefensePlus = 900,
	},
	
	["Bason's Oversoul"] = {
		AttackPlus = 1500,
		DefensePlus = 2100,
		statusAilment = {
			type = "ice",
			chance = 20,
			duration = 4.0,
			dps = 35,
			tickInterval = 1.0,
			slowMultiplier = 0.5,
		},
	},
	
	["Slav's Holy Lance"] = {
		AttackPlus = 3500,
		DefensePlus = 5500,
		statusAilment = {
			type = "stun",
			chance = 10,
			duration = 2.0,
		},
	},
	
	-- ========================================
	-- BOW WEAPONS
	-- ========================================
	
	["Woodland Assassin Bow"] = {
		AttackPlus = 20,
	},
	
	["Evil Elder Wood Bow"] = {
		AttackPlus = 26,
	},
	
	["Dragon Wing Bow"] = {
		AttackPlus = 30,
	},
	
	["Lapiz Lazuli's Bow"] = {
		AttackPlus = 45,
	},
	
	["Pharaoh's Ruby Bow"] = {
		AttackPlus = 70,
	},
	
	["Prehistoric Bow"] = {
		AttackPlus = 120,
	},
	
	["Icy Tundra Bow"] = {
		AttackPlus = 250,
		statusAilment = {
			type = "ice",
			chance = 25,
			duration = 3.0,
			dps = 12,
			tickInterval = 1.0,
			slowMultiplier = 0.6,
		},
	},
	
	["Crystalis Bow"] = {
		AttackPlus = 480,
	},
	
	["Dark Spider Bow"] = {
		AttackPlus = 1200,
		statusAilment = {
			type = "poison",
			chance = 28,
			duration = 5.0,
			dps = 25,
			tickInterval = 1.0,
		},
	},
	
	["Vampire Hunter's Crossbow"] = {
		AttackPlus = 2900,
	},
	
	["Slav's Golden Ornate Bow"] = {
		AttackPlus = 7200,
		statusAilment = {
			type = "stun",
			chance = 12,
			duration = 1.8,
		},
	},
}

local AssetLookup = {}
local CanonicalLookup = {}

for canonicalName, entry in pairs(Entries) do
	entry.assetName = entry.assetName or canonicalName
	entry.canonicalName = canonicalName

	AssetLookup[canonicalName] = entry
	AssetLookup[entry.assetName] = entry
	CanonicalLookup[canonicalName] = canonicalName
	CanonicalLookup[entry.assetName] = canonicalName
end

return {
	Entries = Entries,
	AssetLookup = AssetLookup,
	CanonicalLookup = CanonicalLookup,
}

