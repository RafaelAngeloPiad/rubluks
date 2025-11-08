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

local Entries = {
	-- Example configuration entries (replace with your own values)
	["Samurai Weapon Trailed"] = {
		HPPlus = 500000000,
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

