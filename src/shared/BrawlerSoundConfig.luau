-- ========================================
-- BRAWLER SOUND CONFIGURATION
-- Centralized configuration for all brawler attack sounds
-- Adjust sound IDs here for all brawler attacks
-- ========================================

local BrawlerSoundConfig = {}

-- Sound ID for all brawler attacks (placeholder)
-- Change these to customize individual attack sounds
BrawlerSoundConfig.Sounds = {
	-- Basic Attacks
	combo1 = "rbxasset://sounds//swordslash.wav",
	combo2 = "rbxasset://sounds//swordslash.wav",
	moveAttack = "rbxasset://sounds//swordslash.wav",
	jumpAttack = "rbxasset://sounds//swordslash.wav",
	
	-- Skills
	feralleap = "rbxasset://sounds//swordslash.wav",
	brawlersroar = "rbxasset://sounds//swordslash.wav",
	
	-- Ultimate
	meteordive = "rbxasset://sounds//swordslash.wav",
	
	-- Buffs (with attacks)
	bloodthirst = "rbxasset://sounds//swordslash.wav",
	lastchance = "rbxasset://sounds//swordslash.wav",
	
	-- Weapon Equip
	unsheathe = "rbxasset://sounds//unsheath.wav",
}

-- Helper function to get sound ID for an attack type
function BrawlerSoundConfig.getSound(attackType)
	return BrawlerSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

return BrawlerSoundConfig

