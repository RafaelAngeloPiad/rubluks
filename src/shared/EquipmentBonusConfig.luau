--[[
	EquipmentBonusConfig
	--------------------
	Maps weapon / accessory names (as stored in InventoryStore and tool instances) to stat bonuses.
	Each entry should contain any of the keys recognised by EquipmentStatMappings in PlayerManager:
		HPPlus, AttackPlus, DefensePlus, DefensePenPlus, CritRatePlus, CritMultiplierPlus

	Example:
	["Samurai Weapon Trailed"] = {
		HPPlus = 500,
		AttackPlus = 75,
	}

	You can remove the example entries below and configure your own.
--]]

local EquipmentBonusConfig = {
	-- Example configuration entries (replace with your own values)
	["Samurai Weapon Trailed"] = {
		HPPlus = 500000000,
	},
	["Archer Weapon Bonus"] = {
		AttackPlus = 40,
		CritRatePlus = 5,
	},
}

return EquipmentBonusConfig

