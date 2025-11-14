-- ========================================
-- MOB STATS CONFIGURATION
-- Centralized stats for all mob variants
-- ========================================

local MobStatsConfig = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DEFAULT_HEALTH_COLOR = Color3.fromRGB(120, 220, 120)

local COLOR_THEMES = {
	Sand = {
		name = Color3.fromRGB(210, 180, 140),
		health = Color3.fromRGB(240, 210, 160)
	},
	Ice = {
		name = Color3.fromRGB(110, 195, 255),
		health = Color3.fromRGB(150, 230, 255)
	},
	Lava = {
		name = Color3.fromRGB(255, 110, 60),
		health = Color3.fromRGB(255, 150, 100)
	},
	Fire = {
		name = Color3.fromRGB(255, 90, 60),
		health = Color3.fromRGB(255, 140, 100)
	},
	Woodland = {
		name = Color3.fromRGB(110, 200, 120),
		health = Color3.fromRGB(150, 230, 150)
	},
	Lightning = {
		name = Color3.fromRGB(255, 230, 90),
		health = Color3.fromRGB(255, 240, 150)
	},
	Crystal = {
		name = Color3.fromRGB(150, 120, 255),
		health = Color3.fromRGB(190, 170, 255)
	},
	Poison = {
		name = Color3.fromRGB(120, 255, 180),
		health = Color3.fromRGB(150, 255, 210)
	},
	Toxic = {
		name = Color3.fromRGB(90, 230, 90),
		health = Color3.fromRGB(130, 255, 140)
	},
	Light = {
		name = Color3.fromRGB(255, 250, 200),
		health = Color3.fromRGB(255, 255, 220)
	},
	Dark = {
		name = Color3.fromRGB(170, 80, 255),
		health = Color3.fromRGB(210, 140, 255)
	},
	Tornado = {
		name = Color3.fromRGB(160, 230, 255),
		health = Color3.fromRGB(200, 245, 255)
	},
Default = {
	name = Color3.fromRGB(255, 255, 255),
	health = DEFAULT_HEALTH_COLOR
}
}

local function applyTheme(stats, themeKey)
	local theme = COLOR_THEMES[themeKey] or COLOR_THEMES.Default
	stats.HealthBarColor = stats.HealthBarColor or theme.health
	stats.SlavkoinGain = stats.SlavkoinGain or stats.XPGain or 0
	return stats
end

local function bindRewardHandler(model)
	if not RunService:IsServer() then
		return
	end

	if not model or not model:IsA("Model") then
		return
	end

	if model:GetAttribute("RewardHandlerBound") then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	model:SetAttribute("RewardHandlerBound", true)

	humanoid.Died:Connect(function()
		if model:GetAttribute("RewardsGranted") then
			return
		end

		model:SetAttribute("RewardsGranted", true)

		local killerUserId = model:GetAttribute("LastDamagePlayerId")
		if not killerUserId then
			return
		end

		local player = Players:GetPlayerByUserId(killerUserId)
		if not player then
			return
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return
		end

		local xpGain = model:GetAttribute("XPGain")
		if xpGain and xpGain > 0 then
			local currentXP = leaderstats:FindFirstChild("CurrentXP")
			if currentXP then
				currentXP.Value = currentXP.Value + xpGain

				if _G.createXpGainNumber then
					_G.createXpGainNumber(player, xpGain)
				end
			end
		end

		local coinGain = model:GetAttribute("SlavkoinGain")
		if coinGain and coinGain > 0 then
			local slavkoins = leaderstats:FindFirstChild("Slavkoins")
			if slavkoins then
				slavkoins.Value = slavkoins.Value + coinGain

				if _G.createSlavkoinGainNumber then
					_G.createSlavkoinGainNumber(player, coinGain)
				end
			end
		end
	end)
end

-- ========================================
-- Spider Stats (fixed values)
-- ========================================

MobStatsConfig.Spider_Sand = applyTheme({
	Family = "Spider",
	Level = 2,
	DisplayName = "Sand Spider",
	HP = 260,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 30,
	WalkSpeed = 18,
	XPGain = 8,
	SlavkoinGain = 8,
	StatusAilment = {
		type = "poison",
		chance = 30,
		duration = 3.6,
		dps = 3,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Sand")

MobStatsConfig.Spider_Ice = applyTheme({
	Family = "Spider",
	Level = 8,
	DisplayName = "Ice Spider",
	HP = 380,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 39,
	WalkSpeed = 18,
	XPGain = 11,
	SlavkoinGain = 11,
	StatusAilment = {
		type = "poison",
		chance = 34,
		duration = 3.9,
		dps = 4,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Ice")

MobStatsConfig.Spider_Fire = applyTheme({
	Family = "Spider",
	Level = 14,
	DisplayName = "Fire Spider",
	HP = 500,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 48,
	WalkSpeed = 19,
	XPGain = 14,
	SlavkoinGain = 14,
	StatusAilment = {
		type = "poison",
		chance = 39,
		duration = 4.1,
		dps = 6,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Fire")

MobStatsConfig.Spider_Woodland = applyTheme({
	Family = "Spider",
	Level = 20,
	DisplayName = "Woodland Spider",
	HP = 620,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 57,
	WalkSpeed = 19,
	XPGain = 17,
	SlavkoinGain = 17,
	StatusAilment = {
		type = "poison",
		chance = 44,
		duration = 4.4,
		dps = 7,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Woodland")

MobStatsConfig.Spider_Lightning = applyTheme({
	Family = "Spider",
	Level = 26,
	DisplayName = "Lightning Spider",
	HP = 740,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 65,
	WalkSpeed = 20,
	XPGain = 19,
	SlavkoinGain = 19,
	StatusAilment = {
		type = "poison",
		chance = 49,
		duration = 4.7,
		dps = 8,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Lightning")

MobStatsConfig.Spider_Crystal = applyTheme({
	Family = "Spider",
	Level = 32,
	DisplayName = "Crystal Spider",
	HP = 860,
	Defense = 50,
	DefensePenetration = 5,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 74,
	WalkSpeed = 20,
	XPGain = 22,
	SlavkoinGain = 22,
	StatusAilment = {
		type = "poison",
		chance = 54,
		duration = 4.9,
		dps = 10,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Crystal")

MobStatsConfig.Spider_Poison = applyTheme({
	Family = "Spider",
	Level = 38,
	DisplayName = "Poison Spider",
	HP = 980,
	Defense = 50,
	DefensePenetration = 15,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 83,
	WalkSpeed = 21,
	XPGain = 25,
	SlavkoinGain = 25,
	StatusAilment = {
		type = "poison",
		chance = 58,
		duration = 5.2,
		dps = 11,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Poison")

MobStatsConfig.Spider_Dark = applyTheme({
	Family = "Spider",
	Level = 44,
	DisplayName = "Dark Spider",
	HP = 1100,
	Defense = 50,
	DefensePenetration = 25,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 91,
	WalkSpeed = 21,
	XPGain = 27,
	SlavkoinGain = 27,
	StatusAilment = {
		type = "poison",
		chance = 63,
		duration = 5.5,
		dps = 12,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Dark")

-- ========================================
-- Golem Stats (fixed values)
-- ========================================

MobStatsConfig.Golem_Sand = applyTheme({
	Family = "Golem",
	Level = 3,
	DisplayName = "Sand Golem",
	HP = 492,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 28,
	WalkSpeed = 10,
	XPGain = 22,
	SlavkoinGain = 22,
	StatusAilment = {
		type = "stun",
		chance = 35,
		duration = 1.5
	}
}, "Sand")

MobStatsConfig.Golem_Ice = applyTheme({
	Family = "Golem",
	Level = 9,
	DisplayName = "Ice Golem",
	HP = 636,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 36,
	WalkSpeed = 10,
	XPGain = 28,
	SlavkoinGain = 28,
	StatusAilment = {
		type = "stun",
		chance = 38,
		duration = 1.7
	}
}, "Ice")

MobStatsConfig.Golem_Lava = applyTheme({
	Family = "Golem",
	Level = 15,
	DisplayName = "Lava Golem",
	HP = 780,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 44,
	WalkSpeed = 10,
	XPGain = 33,
	SlavkoinGain = 33,
	StatusAilment = {
		type = "stun",
		chance = 42,
		duration = 1.9
	}
}, "Lava")

MobStatsConfig.Golem_Woodland = applyTheme({
	Family = "Golem",
	Level = 21,
	DisplayName = "Woodland Golem",
	HP = 924,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 52,
	WalkSpeed = 11,
	XPGain = 38,
	SlavkoinGain = 38,
	StatusAilment = {
		type = "stun",
		chance = 46,
		duration = 2.0
	}
}, "Woodland")

MobStatsConfig.Golem_Lightning = applyTheme({
	Family = "Golem",
	Level = 27,
	DisplayName = "Lightning Golem",
	HP = 1068,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 60,
	WalkSpeed = 11,
	XPGain = 44,
	SlavkoinGain = 44,
	StatusAilment = {
		type = "stun",
		chance = 50,
		duration = 2.2
	}
}, "Lightning")

MobStatsConfig.Golem_Crystal = applyTheme({
	Family = "Golem",
	Level = 33,
	DisplayName = "Crystal Golem",
	HP = 1212,
	Defense = 50,
	DefensePenetration = 10,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 68,
	WalkSpeed = 11,
	XPGain = 49,
	SlavkoinGain = 49,
	StatusAilment = {
		type = "stun",
		chance = 53,
		duration = 2.4
	}
}, "Crystal")

MobStatsConfig.Golem_Poison = applyTheme({
	Family = "Golem",
	Level = 39,
	DisplayName = "Poison Golem",
	HP = 1356,
	Defense = 50,
	DefensePenetration = 20,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 76,
	WalkSpeed = 12,
	XPGain = 55,
	SlavkoinGain = 55,
	StatusAilment = {
		type = "stun",
		chance = 57,
		duration = 2.6
	}
}, "Poison")

MobStatsConfig.Golem_Dark = applyTheme({
	Family = "Golem",
	Level = 45,
	DisplayName = "Dark Knight",
	HP = 1500,
	Defense = 50,
	DefensePenetration = 30,
	CritRate = 0,
	CritMultiplier = 150,
	Damage = 84,
	WalkSpeed = 12,
	XPGain = 60,
	SlavkoinGain = 60,
	StatusAilment = {
		type = "stun",
		chance = 61,
		duration = 2.8
	}
}, "Dark")

-- ========================================
-- Bandit Stats (placeholder values)
-- ========================================

MobStatsConfig.Arabandit_Sand = applyTheme({
	Family = "Bandit",
	Level = 4,
	DisplayName = "Arabandit",
	HP = 320,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 4,
	CritMultiplier = 155,
	Damage = 24,
	WalkSpeed = 17,
	XPGain = 12,
	SlavkoinGain = 12
}, "Sand")

MobStatsConfig.Arrabow_Sand = applyTheme({
	Family = "Bandit",
	Level = 5,
	DisplayName = "Arrabow",
	HP = 340,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 7,
	CritMultiplier = 160,
	Damage = 26,
	WalkSpeed = 18,
	XPGain = 13,
	SlavkoinGain = 13
}, "Sand")

MobStatsConfig.Arawizard_Sand = applyTheme({
	Family = "Bandit",
	Level = 6,
	DisplayName = "Arawizard",
	HP = 360,
	Defense = 50,
	DefensePenetration = 1,
	CritRate = 8,
	CritMultiplier = 165,
	Damage = 29,
	WalkSpeed = 17,
	XPGain = 14,
	SlavkoinGain = 14
}, "Sand")

-- ========================================
-- Pirate Stats (placeholder values)
-- ========================================

MobStatsConfig.Pirate_Ice = applyTheme({
	Family = "Pirate",
	Level = 10,
	DisplayName = "Pirate",
	HP = 460,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 5,
	CritMultiplier = 158,
	Damage = 36,
	WalkSpeed = 18,
	XPGain = 20,
	SlavkoinGain = 20
}, "Ice")

MobStatsConfig.GunPirate_Ice = applyTheme({
	Family = "Pirate",
	Level = 11,
	DisplayName = "Gun Pirate",
	HP = 480,
	Defense = 50,
	DefensePenetration = 2,
	CritRate = 8,
	CritMultiplier = 164,
	Damage = 39,
	WalkSpeed = 18,
	XPGain = 22,
	SlavkoinGain = 22
}, "Ice")

MobStatsConfig.Jakalapati_Ice = applyTheme({
	Family = "Pirate",
	Level = 12,
	DisplayName = "Jakalapati",
	HP = 500,
	Defense = 50,
	DefensePenetration = 4,
	CritRate = 9,
	CritMultiplier = 168,
	Damage = 42,
	WalkSpeed = 19,
	XPGain = 24,
	SlavkoinGain = 24
}, "Ice")

-- ========================================
-- Demon Stats (placeholder values)
-- ========================================

MobStatsConfig.BurningDemon_Lava = applyTheme({
	Family = "Demon",
	Level = 16,
	DisplayName = "Burning Demon",
	HP = 620,
	Defense = 50,
	DefensePenetration = 5,
	CritRate = 6,
	CritMultiplier = 170,
	Damage = 48,
	WalkSpeed = 19,
	XPGain = 30,
	SlavkoinGain = 30
}, "Lava")

MobStatsConfig.FlamingDemon_Lava = applyTheme({
	Family = "Demon",
	Level = 17,
	DisplayName = "Flaming Demon",
	HP = 650,
	Defense = 50,
	DefensePenetration = 6,
	CritRate = 7,
	CritMultiplier = 172,
	Damage = 50,
	WalkSpeed = 19,
	XPGain = 32,
	SlavkoinGain = 32
}, "Lava")

MobStatsConfig.HotDemon_Lava = applyTheme({
	Family = "Demon",
	Level = 18,
	DisplayName = "Hot Demon",
	HP = 680,
	Defense = 50,
	DefensePenetration = 7,
	CritRate = 8,
	CritMultiplier = 174,
	Damage = 52,
	WalkSpeed = 19,
	XPGain = 34,
	SlavkoinGain = 34
}, "Lava")

-- ========================================
-- Elf Stats (placeholder values)
-- ========================================

MobStatsConfig.EvilElf_Woodland = applyTheme({
	Family = "Elf",
	Level = 22,
	DisplayName = "Evil Elf",
	HP = 720,
	Defense = 50,
	DefensePenetration = 5,
	CritRate = 10,
	CritMultiplier = 176,
	Damage = 55,
	WalkSpeed = 19,
	XPGain = 36,
	SlavkoinGain = 36
}, "Woodland")

MobStatsConfig.EvilerElf_Woodland = applyTheme({
	Family = "Elf",
	Level = 23,
	DisplayName = "Eviler Elf",
	HP = 750,
	Defense = 50,
	DefensePenetration = 7,
	CritRate = 11,
	CritMultiplier = 178,
	Damage = 58,
	WalkSpeed = 19,
	XPGain = 38,
	SlavkoinGain = 38
}, "Woodland")

MobStatsConfig.EvilistElf_Woodland = applyTheme({
	Family = "Elf",
	Level = 24,
	DisplayName = "Evilist Elf",
	HP = 780,
	Defense = 50,
	DefensePenetration = 8,
	CritRate = 12,
	CritMultiplier = 180,
	Damage = 60,
	WalkSpeed = 20,
	XPGain = 40,
	SlavkoinGain = 40
}, "Woodland")

-- ========================================
-- Monk Stats (placeholder values)
-- ========================================

MobStatsConfig.LightningRaider_Lightning = applyTheme({
	Family = "Monk",
	Level = 27,
	DisplayName = "Lightning",
	HP = 820,
	Defense = 50,
	DefensePenetration = 8,
	CritRate = 10,
	CritMultiplier = 182,
	Damage = 62,
	WalkSpeed = 20,
	XPGain = 42,
	SlavkoinGain = 42
}, "Lightning")

MobStatsConfig.EvilMonk_Lightning = applyTheme({
	Family = "Monk",
	Level = 28,
	DisplayName = "Evil Monk",
	HP = 850,
	Defense = 50,
	DefensePenetration = 9,
	CritRate = 11,
	CritMultiplier = 184,
	Damage = 64,
	WalkSpeed = 20,
	XPGain = 44,
	SlavkoinGain = 44
}, "Lightning")

MobStatsConfig.EvilerMonk_Lightning = applyTheme({
	Family = "Monk",
	Level = 29,
	DisplayName = "Eviler Monk",
	HP = 880,
	Defense = 50,
	DefensePenetration = 10,
	CritRate = 12,
	CritMultiplier = 186,
	Damage = 66,
	WalkSpeed = 21,
	XPGain = 46,
	SlavkoinGain = 46
}, "Lightning")

MobStatsConfig.EvilistMonk_Lightning = applyTheme({
	Family = "Monk",
	Level = 30,
	DisplayName = "Evilist Monk",
	HP = 910,
	Defense = 50,
	DefensePenetration = 12,
	CritRate = 13,
	CritMultiplier = 188,
	Damage = 68,
	WalkSpeed = 21,
	XPGain = 48,
	SlavkoinGain = 48
}, "Lightning")

-- ========================================
-- Dwarven Stats (placeholder values)
-- ========================================

MobStatsConfig.DwarvenMiner_Crystal = applyTheme({
	Family = "Dwarf",
	Level = 34,
	DisplayName = "Dwarven Miner",
	HP = 960,
	Defense = 50,
	DefensePenetration = 10,
	CritRate = 9,
	CritMultiplier = 182,
	Damage = 72,
	WalkSpeed = 18,
	XPGain = 52,
	SlavkoinGain = 52
}, "Crystal")

MobStatsConfig.DwarvenSniper_Crystal = applyTheme({
	Family = "Dwarf",
	Level = 35,
	DisplayName = "Dwarven Sniper",
	HP = 980,
	Defense = 50,
	DefensePenetration = 12,
	CritRate = 14,
	CritMultiplier = 190,
	Damage = 75,
	WalkSpeed = 19,
	XPGain = 54,
	SlavkoinGain = 54
}, "Crystal")

MobStatsConfig.Cardelist_Crystal = applyTheme({
	Family = "Dwarf",
	Level = 36,
	DisplayName = "Cardelist",
	HP = 1000,
	Defense = 50,
	DefensePenetration = 14,
	CritRate = 12,
	CritMultiplier = 188,
	Damage = 78,
	WalkSpeed = 19,
	XPGain = 56,
	SlavkoinGain = 56
}, "Crystal")

-- ========================================
-- Boy Stats (placeholder values)
-- ========================================

MobStatsConfig.BoyLason_Poison = applyTheme({
	Family = "Boy",
	Level = 40,
	DisplayName = "Boy Lason",
	HP = 1080,
	Defense = 50,
	DefensePenetration = 12,
	CritRate = 10,
	CritMultiplier = 186,
	Damage = 82,
	WalkSpeed = 19,
	XPGain = 60,
	SlavkoinGain = 60
}, "Poison")

MobStatsConfig.BoyDura_Poison = applyTheme({
	Family = "Boy",
	Level = 41,
	DisplayName = "Boy Dura",
	HP = 1100,
	Defense = 50,
	DefensePenetration = 13,
	CritRate = 11,
	CritMultiplier = 188,
	Damage = 84,
	WalkSpeed = 19,
	XPGain = 62,
	SlavkoinGain = 62
}, "Poison")

MobStatsConfig.PlemaBoy_Poison = applyTheme({
	Family = "Boy",
	Level = 42,
	DisplayName = "Plema Boy",
	HP = 1120,
	Defense = 50,
	DefensePenetration = 14,
	CritRate = 12,
	CritMultiplier = 190,
	Damage = 86,
	WalkSpeed = 20,
	XPGain = 64,
	SlavkoinGain = 64
}, "Poison")

-- ========================================
-- Dark Faction Stats (placeholder values)
-- ========================================

MobStatsConfig.DarkBoi_Dark = applyTheme({
	Family = "Darkling",
	Level = 46,
	DisplayName = "Dark Boi",
	HP = 1200,
	Defense = 50,
	DefensePenetration = 18,
	CritRate = 14,
	CritMultiplier = 192,
	Damage = 92,
	WalkSpeed = 20,
	XPGain = 72,
	SlavkoinGain = 72
}, "Dark")

MobStatsConfig.DarkBai_Dark = applyTheme({
	Family = "Darkling",
	Level = 47,
	DisplayName = "Dark Bai",
	HP = 1230,
	Defense = 50,
	DefensePenetration = 20,
	CritRate = 15,
	CritMultiplier = 194,
	Damage = 95,
	WalkSpeed = 20,
	XPGain = 74,
	SlavkoinGain = 74
}, "Dark")

MobStatsConfig.Libagerist_Dark = applyTheme({
	Family = "Darkling",
	Level = 48,
	DisplayName = "Libagerist",
	HP = 1260,
	Defense = 50,
	DefensePenetration = 22,
	CritRate = 16,
	CritMultiplier = 196,
	Damage = 98,
	WalkSpeed = 20,
	XPGain = 76,
	SlavkoinGain = 76
}, "Dark")

-- ========================================
-- Zombie Stats (fixed values)
-- ========================================

MobStatsConfig.Zombie_Sand = applyTheme({
	Family = "Zombie",
	Level = 7,
	DisplayName = "Sand Zombie",
	HP = 390,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 6,
	CritMultiplier = 155,
	Damage = 27,
	WalkSpeed = 11,
	XPGain = 16,
	SlavkoinGain = 16,
	Lifesteal = {
		percentage = 1.0
	}
}, "Sand")

MobStatsConfig.Zombie_Ice = applyTheme({
	Family = "Zombie",
	Level = 13,
	DisplayName = "Ice Zombie",
	HP = 470,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 7,
	CritMultiplier = 159,
	Damage = 34,
	WalkSpeed = 12,
	XPGain = 21,
	SlavkoinGain = 21,
	Lifesteal = {
		percentage = 1.0
	}
}, "Ice")

MobStatsConfig.Zombie_Lava = applyTheme({
	Family = "Zombie",
	Level = 19,
	DisplayName = "Fire Zombie",
	HP = 550,
	Defense = 50,
	DefensePenetration = 5,
	CritRate = 9,
	CritMultiplier = 164,
	Damage = 42,
	WalkSpeed = 12,
	XPGain = 27,
	SlavkoinGain = 27,
	Lifesteal = {
		percentage = 1.0
	}
}, "Lava")

MobStatsConfig.Zombie_Woodland = applyTheme({
	Family = "Zombie",
	Level = 25,
	DisplayName = "Woodland Zombie",
	HP = 625,
	Defense = 50,
	DefensePenetration = 10,
	CritRate = 10,
	CritMultiplier = 168,
	Damage = 50,
	WalkSpeed = 13,
	XPGain = 32,
	SlavkoinGain = 32,
	Lifesteal = {
		percentage = 1.0
	}
}, "Woodland")

MobStatsConfig.Zombie_Lightning = applyTheme({
	Family = "Zombie",
	Level = 31,
	DisplayName = "Lightning Zombie",
	HP = 700,
	Defense = 50,
	DefensePenetration = 15,
	CritRate = 11,
	CritMultiplier = 173,
	Damage = 58,
	WalkSpeed = 13,
	XPGain = 38,
	SlavkoinGain = 38,
	Lifesteal = {
		percentage = 1.0
	}
}, "Lightning")

MobStatsConfig.Zombie_Crystal = applyTheme({
	Family = "Zombie",
	Level = 37,
	DisplayName = "Crystal Zombie",
	HP = 780,
	Defense = 50,
	DefensePenetration = 20,
	CritRate = 12,
	CritMultiplier = 177,
	Damage = 66,
	WalkSpeed = 14,
	XPGain = 43,
	SlavkoinGain = 43,
	Lifesteal = {
		percentage = 1.0
	}
}, "Crystal")

MobStatsConfig.Zombie_Poison = applyTheme({
	Family = "Zombie",
	Level = 43,
	DisplayName = "Toxic Zombie",
	HP = 860,
	Defense = 50,
	DefensePenetration = 30,
	CritRate = 14,
	CritMultiplier = 182,
	Damage = 74,
	WalkSpeed = 14,
	XPGain = 48,
	SlavkoinGain = 48,
	Lifesteal = {
		percentage = 1.0
	}
}, "Poison")

MobStatsConfig.Zombie_Dark = applyTheme({
	Family = "Zombie",
	Level = 49,
	DisplayName = "Zomben",
	HP = 940,
	Defense = 50,
	DefensePenetration = 40,
	CritRate = 15,
	CritMultiplier = 186,
	Damage = 82,
	WalkSpeed = 15,
	XPGain = 54,
	SlavkoinGain = 54,
	Lifesteal = {
		percentage = 1.0
	}
}, "Dark")

-- ========================================
-- Wraith Stats (fixed values)
-- ========================================

MobStatsConfig.Wraith_Sand = applyTheme({
	Family = "Wraith",
	Level = 44,
	DisplayName = "Sand Wraith",
	HP = 1130,
	Defense = 50,
	DefensePenetration = 0,
	CritRate = 14,
	CritMultiplier = 186,
	Damage = 86,
	WalkSpeed = 15,
	XPGain = 82,
	SlavkoinGain = 82,
	StatusAilment = {
		type = "burn",
		chance = 58,
		duration = 5.3,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Sand")

MobStatsConfig.Wraith_Ice = applyTheme({
	Family = "Wraith",
	Level = 45,
	DisplayName = "Ice Wraith",
	HP = 1150,
	Defense = 50,
	DefensePenetration = 5,
	CritRate = 14,
	CritMultiplier = 187,
	Damage = 87,
	WalkSpeed = 15,
	XPGain = 84,
	SlavkoinGain = 84,
	StatusAilment = {
		type = "burn",
		chance = 59,
		duration = 5.4,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Ice")

MobStatsConfig.Wraith_Lava = applyTheme({
	Family = "Wraith",
	Level = 46,
	DisplayName = "Fire Wraith",
	HP = 1170,
	Defense = 50,
	DefensePenetration = 7,
	CritRate = 14,
	CritMultiplier = 188,
	Damage = 88,
	WalkSpeed = 15,
	XPGain = 85,
	SlavkoinGain = 85,
	StatusAilment = {
		type = "burn",
		chance = 60,
		duration = 5.4,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Lava")

MobStatsConfig.Wraith_Woodland = applyTheme({
	Family = "Wraith",
	Level = 47,
	DisplayName = "Woodland Wraith",
	HP = 1185,
	Defense = 50,
	DefensePenetration = 10,
	CritRate = 14,
	CritMultiplier = 188,
	Damage = 90,
	WalkSpeed = 15,
	XPGain = 86,
	SlavkoinGain = 86,
	StatusAilment = {
		type = "burn",
		chance = 60,
		duration = 5.4,
		dps = 15,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Woodland")

MobStatsConfig.Wraith_Lightning = applyTheme({
	Family = "Wraith",
	Level = 48,
	DisplayName = "Light Wraith",
	HP = 1205,
	Defense = 50,
	DefensePenetration = 12,
	CritRate = 15,
	CritMultiplier = 189,
	Damage = 91,
	WalkSpeed = 15,
	XPGain = 88,
	SlavkoinGain = 88,
	StatusAilment = {
		type = "burn",
		chance = 61,
		duration = 5.4,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Lightning")

MobStatsConfig.Wraith_Crystal = applyTheme({
	Family = "Wraith",
	Level = 49,
	DisplayName = "Crystal Wraith",
	HP = 1220,
	Defense = 50,
	DefensePenetration = 15,
	CritRate = 15,
	CritMultiplier = 190,
	Damage = 93,
	WalkSpeed = 15,
	XPGain = 89,
	SlavkoinGain = 89,
	StatusAilment = {
		type = "burn",
		chance = 62,
		duration = 5.5,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Crystal")

MobStatsConfig.Wraith_Poison = applyTheme({
	Family = "Wraith",
	Level = 50,
	DisplayName = "Poison Wraith",
	HP = 1240,
	Defense = 50,
	DefensePenetration = 18,
	CritRate = 15,
	CritMultiplier = 190,
	Damage = 94,
	WalkSpeed = 16,
	XPGain = 90,
	SlavkoinGain = 90,
	StatusAilment = {
		type = "burn",
		chance = 62,
		duration = 5.5,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Poison")

MobStatsConfig.Wraith_Dark = applyTheme({
	Family = "Wraith",
	Level = 51,
	DisplayName = "Dark Wraith",
	HP = 1260,
	Defense = 50,
	DefensePenetration = 20,
	CritRate = 15,
	CritMultiplier = 191,
	Damage = 95,
	WalkSpeed = 16,
	XPGain = 91,
	SlavkoinGain = 91,
	StatusAilment = {
		type = "burn",
		chance = 63,
		duration = 5.5,
		dps = 16,
		tickInterval = 1.0,
		skipDefense = true
	}
}, "Dark")

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to apply stats to a mob model
-- @param model: The mob model
-- @param variantName: The variant name (e.g., "Golem_Sand", "Spider_Ice")
-- 
-- STATS FLOW:
-- 1. Stats applied to model attributes (MaxDefense, CurrentDefense, Damage, etc.)
-- 2. DynamicHitboxV3 reads these attributes when damage is calculated
-- 3. Defense system automatically uses CurrentDefense/MaxDefense from attributes
-- 4. All hitbox types (Static, DOT, Traveling, Projectile) work with this system
function MobStatsConfig.applyStats(model, variantName)
	if not model or not model.Parent then
		return false
	end
	
	local stats = MobStatsConfig[variantName]
	if not stats then
		warn("MobStatsConfig: Invalid variant name:", variantName)
		return false
	end
	
	-- Get humanoid to set health
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = stats.HP
		humanoid.Health = stats.HP
		if stats.WalkSpeed then
			humanoid.WalkSpeed = stats.WalkSpeed
		end
		-- Append level to display name
		local baseDisplayName = stats.DisplayName or variantName
		if stats.Level and stats.Level > 0 then
			humanoid.DisplayName = baseDisplayName .. " " .. stats.Level
		else
			humanoid.DisplayName = baseDisplayName
		end
		humanoid.NameDisplayDistance = stats.NameDisplayDistance or 100
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end
	
	-- Set attributes for all stats (used by damage system)
	-- NOTE: These attributes are read by DynamicHitboxV3.getDefenseStats() 
	-- when calculating damage in calculateDamageWithDefense()
	model:SetAttribute("MaxDefense", stats.Defense)
	model:SetAttribute("CurrentDefense", stats.Defense)
	model:SetAttribute("DefensePenetration", stats.DefensePenetration or 0)
	model:SetAttribute("CritRate", stats.CritRate or 0)
	model:SetAttribute("CritMultiplier", stats.CritMultiplier or 150)
	model:SetAttribute("Damage", stats.Damage or 0)
	model:SetAttribute("WalkSpeed", stats.WalkSpeed or humanoid and humanoid.WalkSpeed or 0)
	model:SetAttribute("XPGain", stats.XPGain or 0)
	model:SetAttribute("SlavkoinGain", stats.SlavkoinGain or stats.XPGain or 0)
	model:SetAttribute("MobDisplayName", stats.DisplayName or variantName)
	model:SetAttribute("MobLevel", stats.Level or 0)
	model:SetAttribute("MobHealthBarColor", stats.HealthBarColor or DEFAULT_HEALTH_COLOR)

	
	-- Store variant name for easy access
	model:SetAttribute("MobVariant", variantName)

	bindRewardHandler(model)
	
	return true
end

-- Function to get stats for a variant name
function MobStatsConfig.getStats(variantName)
	return MobStatsConfig[variantName]
end

-- Function to update a mob's damage value (useful for temporary buffs/debuffs)
function MobStatsConfig.updateDamage(model, newDamage)
	if not model or not model.Parent then
		return false
	end
	
	model:SetAttribute("Damage", newDamage)
	return true
end

return MobStatsConfig

