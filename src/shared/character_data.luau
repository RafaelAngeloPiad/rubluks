-- -- Character data structure and class definitions
-- -- This module defines the character stats and class presets

-- local CharacterData = {}

-- -- Character stats structure
-- export type CharacterStats = {
-- 	hp: number,
-- 	mana: number,
-- 	attack: number,
-- 	defense: number,
-- 	magicResist: number,
-- 	statusAilments: {[string]: boolean},
-- 	speed: number
-- }

-- -- Character class definitions (single config per class)
-- local CLASS_CONFIGS = {
-- 	Berserker = {
-- 		hp = 120,
-- 		mana = 50,
-- 		attack = 25,
-- 		defense = 8,
-- 		magicResist = 3,
-- 		statusAilments = {
-- 			["Berserker Rage"] = true,
-- 			["Bloodlust"] = false
-- 		},
-- 		speed = 12
-- 	},
	
-- 	Knight = {
-- 		hp = 150,
-- 		mana = 80,
-- 		attack = 18,
-- 		defense = 20,
-- 		magicResist = 15,
-- 		statusAilments = {
-- 			["Divine Protection"] = true,
-- 			["Blessed"] = false
-- 		},
-- 		speed = 8
-- 	},
	
-- 	Gladiator = {
-- 		hp = 130,
-- 		mana = 70,
-- 		attack = 22,
-- 		defense = 15,
-- 		magicResist = 8,
-- 		statusAilments = {
-- 			["Showmanship"] = true,
-- 			["Crowd Favorite"] = false
-- 		},
-- 		speed = 11
-- 	},
	
-- 	Samurai = {
-- 		hp = 110,
-- 		mana = 85,
-- 		attack = 24,
-- 		defense = 12,
-- 		magicResist = 12,
-- 		statusAilments = {
-- 			["Bushido"] = true,
-- 			["Focus"] = false
-- 		},
-- 		speed = 16
-- 	}
-- }

-- -- Get all available classes
-- function CharacterData.getClasses()
-- 	local classes = {}
-- 	for className, _ in pairs(CLASS_CONFIGS) do
-- 		table.insert(classes, className)
-- 	end
-- 	return classes
-- end

-- -- Get config for a specific class
-- function CharacterData.getClassConfig(className)
-- 	return CLASS_CONFIGS[className]
-- end

-- -- Validate character stats
-- function CharacterData.validateStats(stats: CharacterStats): boolean
-- 	return stats.hp > 0 and stats.mana >= 0 and stats.attack > 0 and 
-- 		   stats.defense >= 0 and stats.magicResist >= 0 and stats.speed > 0
-- end

-- -- Create a character for a specific slot
-- function CharacterData.createCharacter(slotIndex: number, className: string)
-- 	local config = CharacterData.getClassConfig(className)
-- 	if not config then
-- 		error("Invalid class: " .. tostring(className))
-- 	end
	
-- 	return {
-- 		slotIndex = slotIndex,
-- 		className = className,
-- 		stats = table.clone(config),
-- 		level = 1,
-- 		experience = 0,
-- 		createdAt = os.time()
-- 	}
-- end

-- -- Create empty character slot
-- function CharacterData.createEmptySlot(slotIndex: number)
-- 	return {
-- 		slotIndex = slotIndex,
-- 		className = nil,
-- 		stats = nil,
-- 		level = 1,
-- 		experience = 0,
-- 		createdAt = nil
-- 	}
-- end

-- -- Check if character slot is empty
-- function CharacterData.isSlotEmpty(character)
-- 	return character == nil or character.className == nil
-- end

-- return CharacterData
