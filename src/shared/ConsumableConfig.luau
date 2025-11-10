--[[
	ConsumableConfig
	----------------
	Defines all consumable items that can be collected and stored in a player's
	consumable inventory slots. Each entry supports the following fields:

	- assetName      : Optional. Name of the Tool instance in the world. Defaults
	                   to the canonical entry name.
	- displayName    : Optional. Friendly name to show in UI. Defaults to the
	                   canonical entry name.
	- description    : Optional. Helpful text for future UI/tooltips.
	- duration       : Optional number (seconds). When greater than 0 the
	                   consumable grants temporary bonuses that expire after the
	                   given duration. When nil or <= 0 the bonuses are applied
	                   permanently.
	- permanent      : Optional boolean shortcut. When true, bonuses are treated
	                   as permanent regardless of duration.
	- effects        : Table whose keys line up with the stat bonus keys used by
	                   PlayerManager (HPPlus, AttackPlus, DefensePlus,
	                   DefensePenPlus, CritRatePlus, CritMultiplierPlus).

	Example:
	["Health Potion"] = {
		assetName = "HealthPotionTool",
		displayName = "Health Potion",
		duration = 15,
		effects = {
			HPPlus = 250,
		},
	}
--]]

local Entries = {
	["Health Potion"] = {
		assetName = "HealthPotion",
		displayName = "Health Potion",
		duration = 20,
		effects = {
			HPPlus = 250,
		},
	},

	["Iron Skin Elixir"] = {
		assetName = "IronSkinElixir",
		displayName = "Iron Skin Elixir",
		duration = 30,
		effects = {
			DefensePlus = 40,
		},
	},

	["Dragon Fruit"] = {
		assetName = "DragonFruit",
		displayName = "Dragon Fruit",
        description = "A fruit that grants you a temporary boost to your health and attack.",
		permanent = false,
        duration = 10,
		effects = {
			HPPlus = 150,
			AttackPlus = 15,
		},
	},

	["Extra Joss"] = {
		assetName = "Extra Joss",
		displayName = "Extra Joss",
		description = "Refills your Water Level with 150 Points.",
		specialEffects = {
			{
				type = "SunfireWaterRestore",
				amount = 150,
				mode = "add",
				clampToMax = true,
			},
		},
	},

	["Large Extra Joss"] = {
		assetName = "LargeExtraJoss",
		displayName = "Large Extra Joss",
		description = "A premium recharge that tops up your water supply and bolsters your vitality.",
		permanent = false,
		duration = 30,
		specialEffects = {
			{
				type = "SunfireWaterRestore",
				amount = 250,
				mode = "add",
				clampToMax = true,
			},
		},
		effects = {
			HPPlus = 350,
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