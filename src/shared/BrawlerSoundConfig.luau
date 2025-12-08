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

-- Sound Timing Configuration
-- PlayDelay: Wait X seconds before playing (server-side delay)
-- TimePosition: Start playing X seconds into the audio (skip intro)
BrawlerSoundConfig.SoundTiming = {
	combo1 = { PlayDelay = 0, TimePosition = 0 },
	combo2 = { PlayDelay = 0, TimePosition = 0 },
	moveAttack = { PlayDelay = 0, TimePosition = 0 },
	jumpAttack = { PlayDelay = 0, TimePosition = 0 },
	feralleap = { PlayDelay = 0, TimePosition = 0 },
	brawlersroar = { PlayDelay = 0, TimePosition = 0 },
	meteordive = { PlayDelay = 0, TimePosition = 0 },
	bloodthirst = { PlayDelay = 0, TimePosition = 0 },
	lastchance = { PlayDelay = 0, TimePosition = 0 },
	unsheathe = { PlayDelay = 0, TimePosition = 0 },
}

-- Helper function to get sound ID for an attack type
function BrawlerSoundConfig.getSound(attackType)
	return BrawlerSoundConfig.Sounds[attackType] or "rbxasset://sounds//swordslash.wav"
end

-- Helper function to get sound timing for an attack type
function BrawlerSoundConfig.getTiming(attackType)
	return BrawlerSoundConfig.SoundTiming[attackType] or { PlayDelay = 0, TimePosition = 0 }
end

return BrawlerSoundConfig

