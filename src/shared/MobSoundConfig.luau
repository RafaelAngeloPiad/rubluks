-- Mob Sound Configuration
-- Centralized sound configuration for all mobs
-- Easy to adjust all mob sounds from one place
-- Each mob has 2 sounds: Move and Attack

local MobSoundConfig = {}

-- Sound configuration for all mobs (placeholder sounds)
MobSoundConfig.Sounds = {
	-- Golem
	golemMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual golem movement sound
	golemAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual golem attack sound
	golemDeath = "rbxassetid://6108540937", -- Death sound for golem
	
	-- Human Melee
	humanMeleeMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual human melee movement sound
	humanMeleeAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual human melee attack sound
	humanMeleeDeath = "rbxassetid://6108540937", -- Death sound for human melee
	
	-- Human Projectile
	humanProjectileMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual human projectile movement sound
	humanProjectileAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual human projectile attack sound
	humanProjectileDeath = "rbxassetid://6108540937", -- Death sound for human projectile
	
	-- Human Wizard
	humanWizardMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual human wizard movement sound
	humanWizardAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual human wizard attack sound
	humanWizardDeath = "rbxassetid://6108540937", -- Death sound for human wizard
	
	-- Spider
	spiderMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual spider movement sound
	spiderAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual spider attack sound
	spiderDeath = "rbxassetid://6108540937", -- Death sound for spider
	
	-- Wraith
	wraithMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual wraith movement sound
	wraithAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual wraith attack sound
	wraithDeath = "rbxassetid://6108540937", -- Death sound for wraith
	
	-- Zombie
	zombieMove = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual zombie movement sound
	zombieAttack = "rbxasset://sounds//swordslash.wav", -- Placeholder - replace with actual zombie attack sound
	zombieDeath = "rbxassetid://6108540937", -- Death sound for zombie
}

-- Helper function to get sound by type
function MobSoundConfig.getSound(soundType)
	return MobSoundConfig.Sounds[soundType] or "rbxasset://sounds//swordslash.wav"
end

return MobSoundConfig

