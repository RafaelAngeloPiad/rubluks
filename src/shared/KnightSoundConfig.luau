-- ========================================
-- KNIGHT SOUND CONFIGURATION
-- Centralized configuration for all knight attack sounds
-- Adjust sound IDs here for all knight attacks
-- ========================================

local KnightSoundConfig = {}

-- Sound ID for all knight attacks (placeholder)
-- Change these to customize individual attack sounds
KnightSoundConfig.Sounds = {
	-- Basic Attacks
	combo1 = "rbxasset://sounds//swordslash.wav",
	combo2 = "rbxasset://sounds//swordslash.wav",
	moveAttack = "rbxasset://sounds//swordslash.wav",
	jumpAttack = "rbxasset://sounds//swordslash.wav",
	
	-- Skills
	cycloneslash = "rbxasset://sounds//swordslash.wav",
	sworddance = "rbxasset://sounds//swordslash.wav",
	
	-- Ultimate
	mightyblade = "rbxasset://sounds//swordslash.wav",
	
	-- Buffs (with attacks)
	warriormight = "rbxasset://sounds//swordslash.wav",
	warcry = "rbxasset://sounds//swordslash.wav",
	
	-- Weapon Equip
	unsheathe = "rbxasset://sounds//unsheath.wav",
}

-- Helper function to get sound ID for an attack type
function KnightSoundConfig.getSound(attackType)
	return KnightSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

return KnightSoundConfig

