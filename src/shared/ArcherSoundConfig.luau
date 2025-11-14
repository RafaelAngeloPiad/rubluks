-- ========================================
-- ARCHER SOUND CONFIGURATION
-- Centralized configuration for all archer attack sounds
-- Adjust sound IDs here for all archer attacks
-- ========================================

local ArcherSoundConfig = {}

-- Sound ID for all archer attacks (placeholder)
-- Change these to customize individual attack sounds
ArcherSoundConfig.Sounds = {
	-- Basic Attacks
	combo1 = "rbxasset://sounds//swordslash.wav",
	combo2 = "rbxasset://sounds//swordslash.wav",
	moveAttack = "rbxasset://sounds//swordslash.wav",
	jumpAttack = "rbxasset://sounds//swordslash.wav",
	
	-- Skills
	piercingshot = "rbxasset://sounds//swordslash.wav",
	powershot = "rbxasset://sounds//swordslash.wav",
	
	-- Ultimate
	starfall = "rbxasset://sounds//swordslash.wav",
	
	-- Buffs (with attacks)
	hunterinstinct = "rbxasset://sounds//swordslash.wav",
	huntermark = "rbxasset://sounds//swordslash.wav",
	
	-- Weapon Equip
	unsheathe = "rbxasset://sounds//unsheath.wav",
}

-- Helper function to get sound ID for an attack type
function ArcherSoundConfig.getSound(attackType)
	return ArcherSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

return ArcherSoundConfig

