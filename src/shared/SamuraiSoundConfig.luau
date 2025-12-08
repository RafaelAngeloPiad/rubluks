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

-- Sound Timing Configuration
-- PlayDelay: Wait X seconds before playing (server-side delay)
-- TimePosition: Start playing X seconds into the audio (skip intro)
SamuraiSoundConfig.SoundTiming = {
	combo1 = { PlayDelay = 0, TimePosition = 0 },
	combo2 = { PlayDelay = 0, TimePosition = 0 },
	combo3 = { PlayDelay = 0, TimePosition = 0 },
	moveAttack = { PlayDelay = 0, TimePosition = 0 },
	jumpAttack = { PlayDelay = 0, TimePosition = 0 },
	kozuki = { PlayDelay = 0, TimePosition = 0 },
	wakizashi = { PlayDelay = 0, TimePosition = 0 },
	zantetsuken = { PlayDelay = 0, TimePosition = 0 },
	banzai = { PlayDelay = 0, TimePosition = 0 },
	unsheathe = { PlayDelay = 0, TimePosition = 0 },
}

-- Helper function to get sound ID for an attack type
function SamuraiSoundConfig.getSound(attackType)
	return SamuraiSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

-- Helper function to get sound timing for an attack type
function SamuraiSoundConfig.getTiming(attackType)
	return SamuraiSoundConfig.SoundTiming[attackType] or { PlayDelay = 0, TimePosition = 0 }
end

return SamuraiSoundConfig

