--[[
	EquipmentBonusConfig
	--------------------
	Maps weapon / accessory names (as stored in InventoryStore and tool instances) to stat bonuses.
	Each entry can optionally provide an `assetName` field if the actual Tool instance name differs
	from the canonical inventory name stored in the DataStore. All other keys should match the
	stat modifiers recognised by PlayerManager (HPPlus, AttackPlus, DefensePlus, DefensePenPlus,
	CritRatePlus, CritMultiplierPlus).

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
	["Samurai Weapon Trailed"] = {
		AttackPlus = 500000000,
	},
	["Archer Weapon"] = {
		assetName = "Archer Weapon Bonus",
		AttackPlus = 40,
		CritRatePlus = 5,
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

