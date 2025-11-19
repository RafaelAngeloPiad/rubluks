-- GET IMPORTANT SERVICES
local main = script.Parent -- model
local humanoid = main:WaitForChild("Humanoid")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossDefeatedEvent = ReplicatedStorage:WaitForChild("BossDefeatedEvent")
local Players = game:GetService("Players")

-- GET MODULE SCRIPTS
local modules = main:WaitForChild("Modules")
local MobStats = require(modules:WaitForChild("MobStatsModule"))
local MobAI = require(modules:WaitForChild("MobAI"))
local HomingAttack = require(modules:WaitForChild("HomingAttack"))
local EpicenterAttack = require(modules:WaitForChild("EpicenterAttack"))
local StunAttack = require(modules:WaitForChild("StunAttack"))
local MeleeAttack = require(modules:WaitForChild("MeleeAttack"))
local BossBar = require(modules:WaitForChild("BossBarModule"))

-- GET MUSIC AND SOUND EFFECTS
local musicBG = main.Musics.BossMusic
local victoryBG = main.Musics.VictoryFanfare
local sunfireMusic = game.SoundService:WaitForChild("BG Music")

-- FOR THE DAMAGE BELOW THE BOSS
local root = main.HumanoidRootPart
local rootDamage = 150
local rootDamageCD = 1 -- seconds between each damage tick
local lastHit = {} -- para i-track bawat humanoid

-- TRIGGERING BOSS FIGHT
local trigger = workspace["Solaryn (Boss)"]:WaitForChild("BossTrigger")
local activated = false

-- BOSS HP AND WALKSPEED STATS
local STATS = {
	maxHP = 2500,
	currentHP = 2500,
	WalkSpeed = 100
}

-- BOSS REWARD CONFIGURATION
local REWARD_CONFIG = {
	XPGain = 500, -- XP reward for defeating the boss
	SlavkoinGain = 400 -- Slavkoin reward for defeating the boss
}

-- DAMAGE BELOW THE BOSS
local connection

connection = root.Touched:Connect(function(hit)
	local char = hit.Parent
	local hum = char and char:FindFirstChild("Humanoid")

	if hum and hum ~= humanoid then
		local now = tick()
		local last = lastHit[hum] or 0

		if now - last >= rootDamageCD then
			hum:TakeDamage(rootDamage)
			lastHit[hum] = now
		end
	end
end)

-- FADE MUSIC WHEN BOSS DIED
function fadeMusic()
	local fadeTime = 3
	local tween = TweenService:Create(musicBG, TweenInfo.new(fadeTime), {Volume = 0})
	-- Start fading
	tween:Play()
	
	-- After fade completes, stop the music
	tween.Completed:Connect(function()
		musicBG:Stop()
	end)
end

-- CHANGE PHASE LOGIC
humanoid.HealthChanged:Connect(function(currentHealth)
	local healthPercent = currentHealth / humanoid.MaxHealth
	
	MobAI.currentPhase = 1

	if healthPercent <= 0.3 and MobAI.currentPhase < 3 then
		MobAI.currentPhase = 3
		--humanoid.Health = math.min(humanoid.Health + (humanoid.MaxHealth * 0.2), humanoid.MaxHealth)

	elseif healthPercent <= 0.7 and MobAI.currentPhase < 2 then
		MobAI.currentPhase = 2
		
	end
	
end)

humanoid.Died:Connect(function()
	if connection then
		connection:Disconnect()
		connection = nil
		
		-- Grant rewards to the player who dealt the last damage
		if not main:GetAttribute("RewardsGranted") then
			main:SetAttribute("RewardsGranted", true)
			
			local killerUserId = main:GetAttribute("LastDamagePlayerId")
			if killerUserId then
				local player = Players:GetPlayerByUserId(killerUserId)
				if player then
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats then
						-- Grant XP
						local xpGain = main:GetAttribute("XPGain")
						if xpGain and xpGain > 0 then
							local currentXP = leaderstats:FindFirstChild("CurrentXP")
							if currentXP then
								currentXP.Value = currentXP.Value + xpGain
								task.spawn(function()
									if _G.createXpGainNumber then
										_G.createXpGainNumber(player, xpGain)
									end
								end)
							end
						end
						
						-- Grant Slavkoins
						local coinGain = main:GetAttribute("SlavkoinGain")
						if coinGain and coinGain > 0 then
							local slavkoins = leaderstats:FindFirstChild("Slavkoins")
							if slavkoins then
								slavkoins.Value = slavkoins.Value + coinGain
								task.spawn(function()
									if _G.createSlavkoinGainNumber then
										_G.createSlavkoinGainNumber(player, coinGain)
									end
								end)
							end
						end
					end
				end
			end
		end
		
		fadeMusic()
		MobAI.stopSandstorm()
		task.wait(2)
		
		victoryBG:Play()
		for _, player in pairs(game.Players:GetPlayers()) do
			BossDefeatedEvent:FireClient(player)
		end
		
		task.wait(6)
		sunfireMusic:Play()
		main:Destroy()
	end
end)

-- Function to start boss
local function activateBoss(player)
	if activated then return end
	activated = true
	
	-- stop sunfire music
	sunfireMusic:Stop()

	-- play boss music
	musicBG:Play()

	-- Apply stats and attach health bar
	MobStats.ApplyStats(main, STATS)
	BossBar.AttachTo(main)
	
	-- Set reward attributes
	main:SetAttribute("XPGain", REWARD_CONFIG.XPGain)
	main:SetAttribute("SlavkoinGain", REWARD_CONFIG.SlavkoinGain)

	-- Start AI logic
	MobAI.Start(main, HomingAttack, EpicenterAttack, StunAttack, MeleeAttack)
end

-- Detect touch
trigger.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		activateBoss(player)
	end
end)