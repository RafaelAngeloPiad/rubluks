--[[
	HelmetConfig
	------------
	Defines helmet items that occupy a single helmet slot per player.
	Helmets behave like permanent equipment: they grant stat bonuses such as
	AttackPlus, DefensePlus, HPPlus, etc. while equipped.

	Each entry supports:
	- assetName      : Optional. Name of the Tool instance in the world.
	                   Defaults to the canonical entry name.
	- displayName    : Optional. Friendly name to show in UI.
	- description    : Optional. Helpful text for future UI/tooltips.
	- HPPlus         : Optional number. Flat MaxHealth bonus.
	- AttackPlus     : Optional number. Flat MaxAttack bonus.
	- DefensePlus    : Optional number. Flat MaxDefense bonus.
	- DefensePenPlus : Optional number. Flat DefensePenetration bonus.
	- CritRatePlus   : Optional number. Flat CritRate bonus.
	- CritMultiplierPlus : Optional number. Flat CritMultiplier bonus.

	Example:
	["Bronze Helmet"] = {
		assetName = "BronzeHelmet",
		displayName = "Bronze Helmet",
		DefensePlus = 25,
	}
--]]

local Entries = {
	-- You can delete these examples and add your own helmets.

	["Silver Dragon Helmet"] = {
		assetName = "Silver Dragon Helmet",
		displayName = "Silver Dragon Helmet",
		description = "A mythical crown that empowers its wearer.",
		AttackPlus = 40,
		DefensePlus = 40,
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


