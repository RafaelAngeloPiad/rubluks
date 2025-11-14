-- ========================================
-- GLADIATOR SOUND CONFIGURATION
-- Centralized configuration for all gladiator attack sounds
-- Adjust sound IDs here for all gladiator attacks
-- ========================================

local GladiatorSoundConfig = {}

-- Sound ID for all gladiator attacks (placeholder)
-- Change these to customize individual attack sounds
GladiatorSoundConfig.Sounds = {
	-- Basic Attacks
	combo1 = "rbxasset://sounds//swordslash.wav",
	combo2 = "rbxasset://sounds//swordslash.wav",
	moveAttack = "rbxasset://sounds//swordslash.wav",
	jumpAttack = "rbxasset://sounds//swordslash.wav",
	
	-- Skills
	shieldbash = "rbxasset://sounds//swordslash.wav",
	dragoonjump = "rbxasset://sounds//swordslash.wav",
	
	-- Ultimate
	demonicvorpaldance = "rbxasset://sounds//swordslash.wav",
	
	-- Buffs (with attacks)
	championsblood = "rbxasset://sounds//swordslash.wav",
	championscheer = "rbxasset://sounds//swordslash.wav",
	
	-- Weapon Equip
	unsheathe = "rbxasset://sounds//unsheath.wav",
}

-- Helper function to get sound ID for an attack type
function GladiatorSoundConfig.getSound(attackType)
	return GladiatorSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

return GladiatorSoundConfig

