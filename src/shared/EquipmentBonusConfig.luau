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
	-- Example configuration entries (replace with your own values)
	["Flame Sword"] = {
		AttackPlus = 5,
		statusAilment = {
			type = "burn",
			chance = 100,
			duration = 5.0,
			dps = 5,
			tickInterval = 1.0,
		},
	},
	["Prominent Bow"] = {
		AttackPlus = 40,
		CritRatePlus = 5,
	},
	["Giant Dragon Gauntlet"] = {
		AttackPlus = 100,
		DefensePlus = 100,
		statusAilment = {
			type = "stun",
			chance = 30,
			duration = 1.0
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

