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

-- Sound Timing Configuration
-- PlayDelay: Wait X seconds before playing (server-side delay)
-- TimePosition: Start playing X seconds into the audio (skip intro)
ArcherSoundConfig.SoundTiming = {
	combo1 = { PlayDelay = 0, TimePosition = 0 },
	combo2 = { PlayDelay = 0, TimePosition = 0 },
	moveAttack = { PlayDelay = 0, TimePosition = 0 },
	jumpAttack = { PlayDelay = 0, TimePosition = 0 },
	piercingshot = { PlayDelay = 0, TimePosition = 0 },
	powershot = { PlayDelay = 0, TimePosition = 0 },
	starfall = { PlayDelay = 0, TimePosition = 0 },
	hunterinstinct = { PlayDelay = 0, TimePosition = 0 },
	huntermark = { PlayDelay = 0, TimePosition = 0 },
	unsheathe = { PlayDelay = 0, TimePosition = 0 },
}

-- Helper function to get sound ID for an attack type
function ArcherSoundConfig.getSound(attackType)
	return ArcherSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

-- Helper function to get sound timing for an attack type
function ArcherSoundConfig.getTiming(attackType)
	return ArcherSoundConfig.SoundTiming[attackType] or { PlayDelay = 0, TimePosition = 0 }
end

return ArcherSoundConfig

