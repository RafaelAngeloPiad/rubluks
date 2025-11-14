-- ========================================
-- SAMURAI SOUND CONFIGURATION
-- Centralized configuration for all samurai attack sounds
-- Adjust sound IDs here for all samurai attacks
-- ========================================

local SamuraiSoundConfig = {}

-- Sound ID for all samurai attacks (placeholder)
-- Change these to customize individual attack sounds
SamuraiSoundConfig.Sounds = {
	-- Basic Attacks
	combo1 = "rbxasset://sounds//swordslash.wav",
	combo2 = "rbxasset://sounds//swordslash.wav",
	combo3 = "rbxasset://sounds//swordslash.wav",
	moveAttack = "rbxasset://sounds//swordslash.wav",
	jumpAttack = "rbxasset://sounds//swordslash.wav",
	
	-- Skills
	kozuki = "rbxasset://sounds//swordslash.wav",
	wakizashi = "rbxasset://sounds//swordslash.wav",
	
	-- Ultimate
	zantetsuken = "rbxasset://sounds//swordslash.wav",
	
	-- Buffs (with attacks)
	banzai = "rbxasset://sounds//swordslash.wav",
	
	-- Weapon Equip
	unsheathe = "rbxasset://sounds//unsheath.wav",
}

-- Helper function to get sound ID for an attack type
function SamuraiSoundConfig.getSound(attackType)
	return SamuraiSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

return SamuraiSoundConfig

