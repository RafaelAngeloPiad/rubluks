local RunService = game:GetService("RunService")

local MainDataStore

local success, err = pcall(function()
	MainDataStore = require(game.ReplicatedStorage:WaitForChild("MainDataStore"))
end)

if not success or not MainDataStore then
	--warn("MainDataStore module not found or failed to load: " .. tostring(err))
end

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Create RemoteEvent for dev stat changes (client->server communication)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevStatEvent = Instance.new("RemoteEvent")
DevStatEvent.Name = "DevStatEvent"
DevStatEvent.Parent = ReplicatedStorage

-- ========================================
-- BASE PLAYER STATS (Classes)
-- Moved from SlavkosConfigs to be managed here
-- ========================================

local BaseStats = {
	-- XP/Level Configuration (shared across all classes)
	XP = {
		startLevel = 1,
		startXP = 0,
		startMaxXP = 5,
		maxLevel = 50,
		xpMultiplier = 1.2  -- Each level requires 20% more XP than the previous
	},
	
	-- Level-up multipliers per class (from spreadsheet)
	LevelUpMultipliers = {
		Samurai = {
			HP = 1.08,     -- 8% growth
			ATK = 1.05,    -- 5% growth
			D = 1.08,      -- 8% growth
			DP = 1.05,     -- 5% growth - Defense Penetration
			CR = 1.02,     -- 2% growth - Crit Rate (percentage stat)
			CM = 1.01,     -- 1% growth - Crit Multiplier (percentage stat)
			HR = 1.05,     -- 5% growth - Health Regeneration
			Mspd = 1.03,   -- 1% growth - Movement Speed
			Aspd = 1.03,   -- 1% growth - Attack Speed
		},
		Archer = {
			HP = 1.06,     -- 6% growth
			ATK = 1.10,    -- 10% growth
			D = 1.05,      -- 5% growth
			DP = 1.05,     -- 5% growth - Defense Penetration
			CR = 1.03,     -- 3% growth - Crit Rate (percentage stat)
			CM = 1.01,     -- 1% growth - Crit Multiplier (percentage stat)
			HR = 1.05,     -- 5% growth - Health Regeneration
			Mspd = 1.03,   -- 1% growth - Movement Speed
			Aspd = 1.03    -- 1% growth - Attack Speed
		},
		Gladiator = {
			HP = 1.10,     -- 10% growth
			ATK = 1.03,    -- 3% growth
			D = 1.08,      -- 8% growth
			DP = 1.05,     -- 5% growth - Defense Penetration
			CR = 1.02,     -- 2% growth - Crit Rate (percentage stat)
			CM = 1.01,     -- 1% growth - Crit Multiplier (percentage stat)
			HR = 1.05,     -- 5% growth - Health Regeneration
			Mspd = 1.03,   -- 1% growth - Movement Speed
			Aspd = 1.03,   -- 1% growth - Attack Speed
		},
		Brawler = {  -- Berserker in spreadsheet
			HP = 1.07,     -- 7% growth
			ATK = 1.09,    -- 9% growth
			D = 1.05,      -- 5% growth
			DP = 1.05,     -- 5% growth - Defense Penetration
			CR = 1.03,     -- 3% growth - Crit Rate (percentage stat)
			CM = 1.01,     -- 1% growth - Crit Multiplier (percentage stat)
			HR = 1.05,     -- 5% growth - Health Regeneration
			Mspd = 1.03,   -- 1% growth - Movement Speed
			Aspd = 1.03,   -- 1% growth - Attack Speed
		},
		Knight = {
			HP = 1.07,     -- 7% growth
			ATK = 1.07,    -- 7% growth
			D = 1.07,      -- 7% growth
			DP = 1.05,     -- 5% growth - Defense Penetration
			CR = 1.02,     -- 2% growth - Crit Rate (percentage stat)
			CM = 1.01,     -- 1% growth - Crit Multiplier (percentage stat)
			HR = 1.05,     -- 5% growth - Health Regeneration
			Mspd = 1.03,   -- 1% growth - Movement Speed
			Aspd = 1.03,   -- 1% growth - Attack Speed
		}
	},
	
	Archer = {
		-- Offense Stats
		ATK = 100,        -- Attack: Directly affects Health points
		DP = 0,           -- Defense Penetration: Directly affects Defense
		CR = 5,           -- Crit Rate: Rate of Critical Chance up to 100%
		CM = 150,         -- Crit Multiplier: Attack Multiplier (percentage)
		
		-- Defense Stats
		HP = 1200,        -- Health Points: Life pool (dies if ≤ 0)
		D = 50,           -- Defense: Reduces Penetration
		HR = 0,           -- Health Regeneration: Health Points gained per second
		Mspd = 18,        -- Movement Speed: Displacement per second (also used for movement animation speed multiplier: Mspd/18)
		Aspd = 1,         -- Attack Speed: Amount of hits per second (also used for attack animation speed multiplier)
	},
	
	Samurai = {
		-- Offense Stats
		ATK = 50,
		DP = 0,
		CR = 5,
		CM = 150,
		
		-- Defense Stats
		HP = 1600,
		D = 80,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Brawler = {
		-- Offense Stats
		ATK = 90,
		DP = 0,
		CR = 5,
		CM = 150,
		
		-- Defense Stats
		HP = 1400,
		D = 50,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Knight = {
		-- Offense Stats
		ATK = 70,
		DP = 0,
		CR = 5,
		CM = 150,
		
		-- Defense Stats
		HP = 1400,
		D = 70,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	},
	
	Gladiator = {
		-- Offense Stats
		ATK = 30,
		DP = 0,
		CR = 5,
		CM = 150,
		
		-- Defense Stats
		HP = 2000,
		D = 80,
		HR = 0,
		Mspd = 18,
		Aspd = 1,
	}
}

-- Export BaseStats to ServerConfigs so other modules can access it
ServerConfigs.BaseStats = BaseStats

-- ========================================
-- BUFF MANAGEMENT SYSTEM
-- ========================================

-- Store active buffs for each player
local playerBuffs = {} -- player -> { buffName -> { config, startTime, endTime, baseStats } }

-- Function to get base stats before buffs (stored temporarily during buff)
local function getBaseStatsBeforeBuff(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	
	return {
		MaxAttack = leaderstats:FindFirstChild("MaxAttack") and leaderstats.MaxAttack.Value or 0,
		MaxDefense = leaderstats:FindFirstChild("MaxDefense") and leaderstats.MaxDefense.Value or 0,
		MaxHealth = leaderstats:FindFirstChild("MaxHealth") and leaderstats.MaxHealth.Value or 0,
		CurrentHealth = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health or 0
	}
end

-- Function to apply a buff to a player
-- @param player: Player instance
-- @param buffName: "Warcry" or "WarriorMight"
-- @param buffConfig: Buff configuration from ServerConfigs.getBuffConfig()
-- @return: true if buff was applied, false otherwise
function _G.applyBuff(player, buffName, buffConfig)
	if not player or not buffName or not buffConfig then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Get player's level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return false
	end
	
	-- Check if buff config is valid for player's level
	local config = ServerConfigs.getBuffConfig(buffName, level.Value)
	if not config then
		-- Buff not unlocked yet
		return false
	end
	
	-- Initialize player buffs tracking
	if not playerBuffs[player] then
		playerBuffs[player] = {}
	end
	
	-- Remove existing buff if active (stacking prevention)
	if playerBuffs[player][buffName] then
		_G.removeBuff(player, buffName)
	end
	
	-- Store base stats before applying buff
	local baseStats = getBaseStatsBeforeBuff(player)
	
	-- Calculate new stats with buff
	if buffName == "Warcry" then
		-- Warcry: Multiplies Attack and Defense
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxAttack and baseStats then
			-- Calculate buffed attack (multiply base by multiplier)
			local buffedAttack = math.floor(baseStats.MaxAttack * config.attackMultiplier)
			maxAttack.Value = buffedAttack
		end
		
		if maxDefense and baseStats then
			-- Calculate buffed defense (multiply base by multiplier)
			local buffedDefense = math.floor(baseStats.MaxDefense * config.defenseMultiplier)
			maxDefense.Value = buffedDefense
			
			-- Also update CurrentDefense to match MaxDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = buffedDefense
			end
		end
		
	elseif buffName == "WarriorMight" then
		-- WarriorMight: Adds flat HP
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Calculate buffed health (base + flat increase)
			local buffedHealth = baseStats.MaxHealth + config.hpIncrease
			maxHealth.Value = buffedHealth
			
			-- Update humanoid MaxHealth
			humanoid.MaxHealth = buffedHealth
			
			-- Increase current health proportionally or add flat amount (preserve health percentage)
			local healthPercentage = baseStats.MaxHealth > 0 and (baseStats.CurrentHealth / baseStats.MaxHealth) or 1
			local newHealth = math.min(buffedHealth * healthPercentage, buffedHealth)
			humanoid.Health = newHealth
		end
		
	elseif buffName == "BloodThirst" then
		-- BloodThirst: Provides lifesteal (no stat modifications, just tracking)
		-- Lifesteal is applied automatically in hitbox creation
		
	elseif buffName == "LastChance" then
		-- LastChance: Provides status immunity and HP regeneration
		-- Status immunity is checked in StatusAilmentHandler
		-- HP regeneration is handled in update loop
		
	elseif buffName == "ChampionsCheer" then
		-- ChampionsCheer: Multiplies HP and Defense, adds HP regeneration
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Calculate buffed health (base * (1 + multiplier))
			local buffedHealth = math.floor(baseStats.MaxHealth * (1 + config.hpMultiplier))
			maxHealth.Value = buffedHealth
			
			-- Update humanoid MaxHealth
			humanoid.MaxHealth = buffedHealth
			
			-- Increase current health proportionally (preserve health percentage)
			local healthPercentage = baseStats.MaxHealth > 0 and (baseStats.CurrentHealth / baseStats.MaxHealth) or 1
			local newHealth = math.min(buffedHealth * healthPercentage, buffedHealth)
			humanoid.Health = newHealth
		end
		
		if maxDefense and baseStats then
			-- Calculate buffed defense (base * (1 + multiplier))
			local buffedDefense = math.floor(baseStats.MaxDefense * (1 + config.defenseMultiplier))
			maxDefense.Value = buffedDefense
			
			-- Also update CurrentDefense to match MaxDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = buffedDefense
			end
		end
		
		-- HP regeneration is handled in update loop (similar to LastChance)
		
	elseif buffName == "ChampionsBlood" then
		-- ChampionsBlood: Adds flat Defense and provides status immunity
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxDefense and baseStats then
			-- Calculate buffed defense (base + flat increase)
			local buffedDefense = baseStats.MaxDefense + config.defenseIncrease
			maxDefense.Value = buffedDefense
			
			-- Also update CurrentDefense to match MaxDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = buffedDefense
			end
		end
		
		-- Status immunity is checked in StatusAilmentHandler (similar to LastChance)
	end
	
	-- Track buff
	local startTime = tick()
	local endTime = startTime + config.duration
	playerBuffs[player][buffName] = {
		config = config,
		startTime = startTime,
		endTime = endTime,
		baseStats = baseStats
	}
	
	-- Store base stats in leaderstats for UI display (only for UI, not used in calculations)
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	if not baseStatsFolder then
		baseStatsFolder = Instance.new("Folder", leaderstats)
		baseStatsFolder.Name = "BaseStats"
	end
	
	if buffName == "Warcry" then
		-- Store base Attack and Defense for UI
		if baseStats then
			local baseAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
			if not baseAttack then
				baseAttack = Instance.new("NumberValue", baseStatsFolder)
				baseAttack.Name = "BaseMaxAttack"
			end
			baseAttack.Value = baseStats.MaxAttack
			
			local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
			if not baseDefense then
				baseDefense = Instance.new("NumberValue", baseStatsFolder)
				baseDefense.Name = "BaseMaxDefense"
			end
			baseDefense.Value = baseStats.MaxDefense
		end
	elseif buffName == "WarriorMight" then
		-- Store base Health for UI
		if baseStats then
			local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
			if not baseHealth then
				baseHealth = Instance.new("NumberValue", baseStatsFolder)
				baseHealth.Name = "BaseMaxHealth"
			end
			baseHealth.Value = baseStats.MaxHealth
		end
	elseif buffName == "ChampionsCheer" then
		-- Store base Health and Defense for UI
		if baseStats then
			local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
			if not baseHealth then
				baseHealth = Instance.new("NumberValue", baseStatsFolder)
				baseHealth.Name = "BaseMaxHealth"
			end
			baseHealth.Value = baseStats.MaxHealth
			
			local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
			if not baseDefense then
				baseDefense = Instance.new("NumberValue", baseStatsFolder)
				baseDefense.Name = "BaseMaxDefense"
			end
			baseDefense.Value = baseStats.MaxDefense
		end
	elseif buffName == "ChampionsBlood" then
		-- Store base Defense for UI
		if baseStats then
			local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
			if not baseDefense then
				baseDefense = Instance.new("NumberValue", baseStatsFolder)
				baseDefense.Name = "BaseMaxDefense"
			end
			baseDefense.Value = baseStats.MaxDefense
		end
	end
	
	-- Update ActiveBuffs string value
	local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
	if activeBuffs then
		local currentBuffs = activeBuffs.Value
		if currentBuffs == "" then
			activeBuffs.Value = buffName
		else
			activeBuffs.Value = currentBuffs .. "," .. buffName
		end
	end
	
	-- Create buff duration tracking value
	local buffDurations = leaderstats:FindFirstChild("BuffDurations")
	if buffDurations then
		local buffDuration = Instance.new("NumberValue", buffDurations)
		buffDuration.Name = buffName
		buffDuration.Value = math.ceil(config.duration)
		
		-- Update duration countdown
		local buffStartTime = tick()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if not buffDuration or not buffDuration.Parent then
				connection:Disconnect()
				return
			end
			local elapsed = tick() - buffStartTime
			local remaining = math.max(0, math.ceil(config.duration - elapsed))
			buffDuration.Value = remaining
			if remaining <= 0 then
				connection:Disconnect()
			end
		end)
	end
	
	-- Start HP regeneration for ChampionsCheer buff
	if buffName == "ChampionsCheer" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Start HP regeneration loop
				local regenThread = task.spawn(function()
					while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
						-- Check if buff is still active
						if not playerBuffs[player] or not playerBuffs[player]["ChampionsCheer"] then
							break
						end
						
						local buffData = playerBuffs[player]["ChampionsCheer"]
						if not buffData or not buffData.config then
							break
						end
						
						-- Check if buff expired
						local currentTime = tick()
						if currentTime >= buffData.endTime then
							break
						end
						
						-- Wait 1 second before next regeneration
						task.wait(1)
						
						-- Check again after wait (character might have been removed or buff expired)
						if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
							break
						end
						
						if not playerBuffs[player] or not playerBuffs[player]["ChampionsCheer"] then
							break
						end
						
						-- Get HP regen percentage from buff config
						local hpRegenPercentage = buffData.config.hpRegenPercentage or 0
						if hpRegenPercentage > 0 then
							-- Calculate healing amount (percentage of Max HP)
							local maxHealth = humanoid.MaxHealth
							local healingAmount = maxHealth * hpRegenPercentage
							
							-- Regenerate health (cap at MaxHealth)
							local newHealth = math.min(humanoid.Health + healingAmount, maxHealth)
							humanoid.Health = newHealth
						end
					end
				end)
			end
		end
	end
	
	-- Start HP regeneration and status immunity display for LastChance buff
	if buffName == "LastChance" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Start HP regeneration loop
				local regenThread = task.spawn(function()
					while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
						-- Check if buff is still active
						if not playerBuffs[player] or not playerBuffs[player]["LastChance"] then
							break
						end
						
						local buffData = playerBuffs[player]["LastChance"]
						if not buffData or not buffData.config then
							break
						end
						
						-- Check if buff expired
						local currentTime = tick()
						if currentTime >= buffData.endTime then
							break
						end
						
						-- Wait 1 second before next regeneration
						task.wait(1)
						
						-- Check again after wait (character might have been removed or buff expired)
						if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
							break
						end
						
						if not playerBuffs[player] or not playerBuffs[player]["LastChance"] then
							break
						end
						
						-- Get HP regen percentage from buff config
						local hpRegenPercentage = buffData.config.hpRegenPercentage or 0
						if hpRegenPercentage > 0 then
							-- Calculate healing amount (percentage of Max HP)
							local maxHealth = humanoid.MaxHealth
							local healingAmount = maxHealth * hpRegenPercentage
							
							-- Regenerate health (cap at MaxHealth)
							local newHealth = math.min(humanoid.Health + healingAmount, maxHealth)
							humanoid.Health = newHealth
						end
					end
				end)
				
				-- Show "Immune" text above head during immunity duration
				local RunService = game:GetService("RunService")
				local head = character:FindFirstChild("Head")
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				local attachPart = head or humanoidRootPart
				
				if attachPart then
					-- Create "Immune" text
					local billboardGui = Instance.new("BillboardGui")
					billboardGui.Name = "ImmuneText_" .. tostring(tick() * 1000)
					billboardGui.Size = UDim2.new(0, 200, 0, 50)
					billboardGui.StudsOffset = Vector3.new(0, 3.5, 0) -- Above head, higher than ailment text
					billboardGui.AlwaysOnTop = true
					billboardGui.LightInfluence = 0
					billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
					billboardGui.Parent = attachPart
					
					-- Create TextLabel
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.Text = "IMMUNE"
					textLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
					textLabel.TextSize = 24
					textLabel.Font = Enum.Font.GothamBold
					textLabel.TextStrokeTransparency = 0
					textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
					textLabel.TextXAlignment = Enum.TextXAlignment.Center
					textLabel.TextYAlignment = Enum.TextYAlignment.Center
					textLabel.Parent = billboardGui
					
					-- Monitor immunity status and remove text when immunity expires
					local connection
					connection = RunService.Heartbeat:Connect(function()
						if not character or not character.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
						
						if not playerBuffs[player] or not playerBuffs[player]["LastChance"] then
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
						
						local buffData = playerBuffs[player]["LastChance"]
						if not buffData or not buffData.config then
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
						
						local currentTime = tick()
						local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
						
						if currentTime >= immunityEndTime then
							-- Immunity expired, remove text
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
							return
						end
					end)
					
					-- Clean up when done (safety cleanup)
					local buffData = playerBuffs[player]["LastChance"]
					if buffData and buffData.config then
						task.delay(buffData.config.immunityDuration + 0.1, function()
							if connection then connection:Disconnect() end
							if billboardGui and billboardGui.Parent then
								billboardGui:Destroy()
							end
						end)
					end
				end
			end
		end
	end
	
	-- Start status immunity display for ChampionsBlood buff
	if buffName == "ChampionsBlood" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local head = character:FindFirstChild("Head")
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local attachPart = head or humanoidRootPart
			
			if attachPart then
				-- Create "Immune" text above head during immunity duration
				local RunService = game:GetService("RunService")
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Name = "ImmuneText_" .. tostring(tick() * 1000)
				billboardGui.Size = UDim2.new(0, 200, 0, 50)
				billboardGui.StudsOffset = Vector3.new(0, 3.5, 0) -- Above head, higher than ailment text
				billboardGui.AlwaysOnTop = true
				billboardGui.LightInfluence = 0
				billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
				billboardGui.Parent = attachPart
				
				-- Create TextLabel
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = "IMMUNE"
				textLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
				textLabel.TextSize = 24
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextStrokeTransparency = 0
				textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
				textLabel.TextXAlignment = Enum.TextXAlignment.Center
				textLabel.TextYAlignment = Enum.TextYAlignment.Center
				textLabel.Parent = billboardGui
				
				-- Monitor immunity status and remove text when immunity expires
				local connection
				connection = RunService.Heartbeat:Connect(function()
					if not character or not character.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					if not playerBuffs[player] or not playerBuffs[player]["ChampionsBlood"] then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					local buffData = playerBuffs[player]["ChampionsBlood"]
					if not buffData or not buffData.config then
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
					
					local currentTime = tick()
					local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
					
					if currentTime >= immunityEndTime then
						-- Immunity expired, remove text
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
						return
					end
				end)
				
				-- Clean up when done (safety cleanup)
				local buffData = playerBuffs[player]["ChampionsBlood"]
				if buffData and buffData.config then
					task.delay(buffData.config.immunityDuration + 0.1, function()
						if connection then connection:Disconnect() end
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
					end)
				end
			end
		end
	end
	
	-- Auto-remove buff after duration
	task.delay(config.duration, function()
		if playerBuffs[player] and playerBuffs[player][buffName] then
			_G.removeBuff(player, buffName)
		end
	end)
	
	return true
end

-- Function to remove a buff from a player
-- @param player: Player instance
-- @param buffName: "Warcry" or "WarriorMight"
-- @return: true if buff was removed, false otherwise
function _G.removeBuff(player, buffName)
	if not player or not buffName then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	if not playerBuffs[player] or not playerBuffs[player][buffName] then
		return false
	end
	
	local buffData = playerBuffs[player][buffName]
	local baseStats = buffData.baseStats
	
	-- Restore base stats
	if buffName == "Warcry" then
		-- Warcry: Restore Attack and Defense to base values
		local maxAttack = leaderstats:FindFirstChild("MaxAttack")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxAttack and baseStats then
			maxAttack.Value = baseStats.MaxAttack
		end
		
		if maxDefense and baseStats then
			maxDefense.Value = baseStats.MaxDefense
			
			-- Also restore CurrentDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = baseStats.MaxDefense
			end
		end
		
	elseif buffName == "WarriorMight" then
		-- WarriorMight: Restore HP to base value
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Restore base health
			maxHealth.Value = baseStats.MaxHealth
			humanoid.MaxHealth = baseStats.MaxHealth
			
			-- Restore health percentage (cap at max health)
			local healthPercentage = baseStats.MaxHealth > 0 and (humanoid.Health / (baseStats.MaxHealth + buffData.config.hpIncrease)) or 1
			local newHealth = math.min(baseStats.MaxHealth * healthPercentage, baseStats.MaxHealth)
			humanoid.Health = newHealth
		end
		
	elseif buffName == "BloodThirst" then
		-- BloodThirst: No stat restoration needed (no stat modifications)
		
	elseif buffName == "LastChance" then
		-- LastChance: No stat restoration needed (no stat modifications)
		-- Status immunity and HP regen are handled automatically
		
	elseif buffName == "ChampionsCheer" then
		-- ChampionsCheer: Restore HP and Defense to base values
		local maxHealth = leaderstats:FindFirstChild("MaxHealth")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		
		if maxHealth and baseStats and humanoid then
			-- Restore base health
			maxHealth.Value = baseStats.MaxHealth
			humanoid.MaxHealth = baseStats.MaxHealth
			
			-- Restore health percentage (cap at max health)
			local buffedMaxHealth = baseStats.MaxHealth * (1 + buffData.config.hpMultiplier)
			local healthPercentage = buffedMaxHealth > 0 and (humanoid.Health / buffedMaxHealth) or 1
			local newHealth = math.min(baseStats.MaxHealth * healthPercentage, baseStats.MaxHealth)
			humanoid.Health = newHealth
		end
		
		if maxDefense and baseStats then
			-- Restore base defense
			maxDefense.Value = baseStats.MaxDefense
			
			-- Also restore CurrentDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = baseStats.MaxDefense
			end
		end
		
	elseif buffName == "ChampionsBlood" then
		-- ChampionsBlood: Restore Defense to base value
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		
		if maxDefense and baseStats then
			-- Restore base defense
			maxDefense.Value = baseStats.MaxDefense
			
			-- Also restore CurrentDefense
			local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefense then
				currentDefense.Value = baseStats.MaxDefense
			end
		end
		
		-- Status immunity is handled automatically
	end
	
	-- Remove buff tracking
	playerBuffs[player][buffName] = nil
	
	-- Update ActiveBuffs string value
	local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
	if activeBuffs then
		local currentBuffs = activeBuffs.Value
		local buffList = {}
		for buff in string.gmatch(currentBuffs, "([^,]+)") do
			if buff ~= buffName then
				table.insert(buffList, buff)
			end
		end
		activeBuffs.Value = table.concat(buffList, ",")
	end
	
	-- Remove buff duration tracking
	local buffDurations = leaderstats:FindFirstChild("BuffDurations")
	if buffDurations then
		local buffDuration = buffDurations:FindFirstChild(buffName)
		if buffDuration then
			buffDuration:Destroy()
		end
	end
	
	-- Remove base stats tracking when buff expires (clean up BaseStats folder)
	-- BUT: Only remove if no other buffs/passives are using it
	local baseStatsFolder = leaderstats:FindFirstChild("BaseStats")
	if baseStatsFolder then
		-- Check if other buffs are active that might need these base stats
		local activeBuffs = leaderstats:FindFirstChild("ActiveBuffs")
		local activePassives = leaderstats:FindFirstChild("ActivePassives")
		local hasOtherBuffs = false
		local hasPassives = false
		
		-- Check for other active buffs
		if activeBuffs and activeBuffs.Value ~= "" then
			for buff in string.gmatch(activeBuffs.Value, "([^,]+)") do
				if buff ~= buffName then
					hasOtherBuffs = true
					break
				end
			end
		end
		
		-- Check for active passives
		if activePassives and activePassives.Value ~= "" then
			hasPassives = true
		end
		
		-- Only remove BaseStats if no other buffs/passives are active
		if not hasOtherBuffs and not hasPassives then
			if buffName == "Warcry" then
				local baseAttack = baseStatsFolder:FindFirstChild("BaseMaxAttack")
				if baseAttack then
					baseAttack:Destroy()
				end
				local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
				if baseDefense then
					baseDefense:Destroy()
				end
			elseif buffName == "WarriorMight" then
				local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
				if baseHealth then
					baseHealth:Destroy()
				end
			elseif buffName == "ChampionsCheer" then
				local baseHealth = baseStatsFolder:FindFirstChild("BaseMaxHealth")
				if baseHealth then
					baseHealth:Destroy()
				end
				local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
				if baseDefense then
					baseDefense:Destroy()
				end
			elseif buffName == "ChampionsBlood" then
				local baseDefense = baseStatsFolder:FindFirstChild("BaseMaxDefense")
				if baseDefense then
					baseDefense:Destroy()
				end
			end
			
			-- Clean up BaseStats folder if it's empty
			if #baseStatsFolder:GetChildren() == 0 then
				baseStatsFolder:Destroy()
			end
		end
	end
	
	return true
end

-- Function to get active buffs for a player
-- @param player: Player instance
-- @return: Table of active buff names
function _G.getActiveBuffs(player)
	if not playerBuffs[player] then
		return {}
	end
	
	local active = {}
	for buffName, _ in pairs(playerBuffs[player]) do
		table.insert(active, buffName)
	end
	
	return active
end

-- Function to get player's active lifesteal percentage from buffs
-- @param player: Player instance
-- @return: Lifesteal percentage (0.03 = 3%) or nil if no lifesteal buff active
function _G.getPlayerLifestealPercentage(player)
	if not player or not playerBuffs[player] then
		return nil
	end
	
	-- Check for BloodThirst buff
	if playerBuffs[player]["BloodThirst"] then
		local buffData = playerBuffs[player]["BloodThirst"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Buff is still active
				return buffData.config.lifestealPercentage
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["BloodThirst"] = nil
			end
		end
	end
	
	return nil
end

-- Function to check if player has status immunity (from LastChance or ChampionsBlood buff)
-- @param player: Player instance
-- @return: true if player has status immunity, false otherwise
function _G.hasStatusImmunity(player)
	if not player or not playerBuffs[player] then
		return false
	end
	
	-- Check for LastChance buff
	if playerBuffs[player]["LastChance"] then
		local buffData = playerBuffs[player]["LastChance"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Check if immunity duration is still active
				local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
				if currentTime < immunityEndTime then
					-- Player has status immunity
					return true
				end
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["LastChance"] = nil
			end
		end
	end
	
	-- Check for ChampionsBlood buff
	if playerBuffs[player]["ChampionsBlood"] then
		local buffData = playerBuffs[player]["ChampionsBlood"]
		-- Check if buff is still active (not expired)
		if buffData and buffData.config and buffData.endTime then
			local currentTime = tick()
			if currentTime < buffData.endTime then
				-- Check if immunity duration is still active
				local immunityEndTime = buffData.startTime + buffData.config.immunityDuration
				if currentTime < immunityEndTime then
					-- Player has status immunity
					return true
				end
			else
				-- Buff expired, remove it (safety cleanup)
				playerBuffs[player]["ChampionsBlood"] = nil
			end
		end
	end
	
	return false
end

-- Clean up buffs when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	if playerBuffs[player] then
		playerBuffs[player] = nil
	end
end)

-- ========================================
-- INVINCIBILITY / GOD MODE SYSTEM
-- ========================================

-- Track which players are currently invincible (during skill/ult execution)
-- Key: player, Value: boolean (true = invincible, false/nil = not invincible)
-- This freezes health - no damage is applied while invincible (health stays the same)
local playerInvincibility = {}

-- Function to enable invincibility for a player (freezes health, prevents damage)
-- @param player: Player instance
function _G.enablePlayerInvincibility(player)
	if not player then return end
	playerInvincibility[player] = true
end

-- Function to disable invincibility for a player (allows damage again)
-- @param player: Player instance
function _G.disablePlayerInvincibility(player)
	if not player then return end
	playerInvincibility[player] = nil
end

-- Function to check if player is invincible
-- @param player: Player instance
-- @return: true if player is invincible, false otherwise
function _G.isPlayerInvincible(player)
	if not player then return false end
	return playerInvincibility[player] == true
end

-- Clean up invincibility when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	if playerInvincibility[player] then
		playerInvincibility[player] = nil
	end
end)

-- Helper function to calculate MaximumXP based on level
local function calculateMaximumXP(level)
	local startMaxXP = BaseStats.XP.startMaxXP
	local xpMultiplier = BaseStats.XP.xpMultiplier
	-- Formula: startMaxXP * (xpMultiplier ^ (level - 1))
	-- For level 1: startMaxXP * (xpMultiplier ^ 0) = startMaxXP * 1 = startMaxXP
	-- For level 2: startMaxXP * (xpMultiplier ^ 1) = startMaxXP * xpMultiplier
	-- For level 22: startMaxXP * (xpMultiplier ^ 21)
	local calculatedMaxXP = startMaxXP * (xpMultiplier ^ (level - 1))
	return math.floor(calculatedMaxXP)
end

-- Helper function to convert data values to proper types
local function convertDataType(value, defaultValue)
	if value == nil then
		return defaultValue
	end
	-- If it's a string, try to convert to number
	if typeof(value) == "string" then
		local numValue = tonumber(value)
		return numValue ~= nil and numValue or defaultValue
	end
	-- If it's already a number, return it
	if typeof(value) == "number" then
		return value
	end
	return defaultValue
end


game.Players.PlayerAdded:Connect(function(plr)
	
	local teleportData = plr:GetJoinData().TeleportData
	--print("PlayerAdded: TeleportData =", teleportData)
	local data

	if teleportData then
		-- Use TeleportData if present
		data = teleportData
		--print("Loaded data from TeleportData:", data)
	else
		-- Otherwise, load from MainDataStore
		if MainDataStore then
			data = MainDataStore.LoadPlayerData(plr.UserId)
			--print("Loaded data from MainDataStore:", data)
		else
			--warn("MainDataStore not available, cannot load player data.")
		end
	end


	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plr

	local level = Instance.new("IntValue", leaderstats)
	level.Name = "Level"
	level.Value = BaseStats.XP.startLevel

	local currxp = Instance.new("NumberValue", leaderstats)
	currxp.Name = "CurrentXP"
	currxp.Value = BaseStats.XP.startXP

	local maxxp = Instance.new("NumberValue", leaderstats)
	maxxp.Name = "MaximumXP"
	maxxp.Value = BaseStats.XP.startMaxXP

	local class = Instance.new("StringValue", leaderstats)
	class.Name = "Class"
	class.Value = "Slavkorian"

	-- Offense Stats
	local maxAttack = Instance.new("NumberValue", leaderstats)
	maxAttack.Name = "MaxAttack"
	maxAttack.Value = 0 -- Will be set based on class
	
	local defensePenetration = Instance.new("NumberValue", leaderstats)
	defensePenetration.Name = "DefensePenetration"
	defensePenetration.Value = 0
	
	local critRate = Instance.new("NumberValue", leaderstats)
	critRate.Name = "CritRate"
	critRate.Value = 0
	
	local critMultiplier = Instance.new("NumberValue", leaderstats)
	critMultiplier.Name = "CritMultiplier"
	critMultiplier.Value = 0
	

	-- Defense Stats
	local maxDefense = Instance.new("NumberValue", leaderstats)
	maxDefense.Name = "MaxDefense"
	maxDefense.Value = 0 -- Will be set based on class
	
	local currentDefense = Instance.new("NumberValue", leaderstats)
	currentDefense.Name = "CurrentDefense"
	currentDefense.Value = 0 -- Will track current defense (damaged defense)

	local maxHealth = Instance.new("NumberValue", leaderstats)
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = 0 -- Will be set based on class
	
	local healthRegen = Instance.new("NumberValue", leaderstats)
	healthRegen.Name = "HealthRegen"
	healthRegen.Value = 0
	
	local movementSpeed = Instance.new("NumberValue", leaderstats)
	movementSpeed.Name = "MovementSpeed"
	movementSpeed.Value = 0
	
	local attackSpeed = Instance.new("NumberValue", leaderstats)
	attackSpeed.Name = "AttackSpeed"
	attackSpeed.Value = 0

	local slavkoins = Instance.new("NumberValue", leaderstats)
	slavkoins.Name = "Slavkoins"
	slavkoins.Value = 0
	
	-- Buff tracking (stores active buff information)
	local activeBuffs = Instance.new("StringValue", leaderstats)
	activeBuffs.Name = "ActiveBuffs"
	activeBuffs.Value = "" -- Comma-separated list of active buffs (e.g., "Warcry,WarriorMight")
	
	-- Buff duration tracking (stores when buffs expire)
	local buffDurations = Instance.new("Folder", leaderstats)
	buffDurations.Name = "BuffDurations"
	
	-- Passive tracking (stores active passive information)
	local activePassives = Instance.new("StringValue", leaderstats)
	activePassives.Name = "ActivePassives"
	activePassives.Value = "" -- Comma-separated list of active passives (e.g., "Tenacity")
	
	-- loads progress data
	if data then
		-- Convert and load level (ensure it's a number)
		local loadedLevel = convertDataType(data.Level, BaseStats.XP.startLevel)
		level.Value = math.min(math.max(loadedLevel, 1), BaseStats.XP.maxLevel)
		
		-- Load CurrentXP and ensure it's a number
		currxp.Value = convertDataType(data.CurrentXP, BaseStats.XP.startXP)
		
		-- Calculate MaximumXP based on level (don't trust saved MaximumXP as it might be outdated)
		maxxp.Value = calculateMaximumXP(level.Value)
		
		-- Load class
		class.Value = typeof(data.Class) == "string" and data.Class or "Slavkorian"
		
		-- Load all stats with proper type conversion
		maxAttack.Value = convertDataType(data.MaxAttack, 0)
		defensePenetration.Value = convertDataType(data.DefensePenetration, 0)
		critRate.Value = convertDataType(data.CritRate, 0)
		critMultiplier.Value = convertDataType(data.CritMultiplier, 0)
		maxDefense.Value = convertDataType(data.MaxDefense, 0)
		currentDefense.Value = convertDataType(data.CurrentDefense, data.MaxDefense or 0) -- Load CurrentDefense, default to MaxDefense if not saved
		maxHealth.Value = convertDataType(data.MaxHealth, 0)
		healthRegen.Value = convertDataType(data.HealthRegen, 0)
		
		-- Load MovementSpeed and AttackSpeed, but convert if they're old format (walk speed values > 1.5)
		-- MovementSpeed and AttackSpeed should be animation multipliers starting at 1.0
		local loadedMovementSpeed = convertDataType(data.MovementSpeed, 0)
		if loadedMovementSpeed > 1.5 then
			-- Old format: This is likely the walk speed (18), convert to animation multiplier
			-- Reverse-engineer: divide by base Mspd (18) to get the multiplier
			local baseMspd = 18 -- Base walk speed
			local calculatedMultiplier = loadedMovementSpeed / baseMspd
			-- Clamp to reasonable range (between 1.0 and 2.0 for safety)
			movementSpeed.Value = math.max(1.0, math.min(2.0, calculatedMultiplier))
		else
			movementSpeed.Value = loadedMovementSpeed == 0 and 0 or loadedMovementSpeed
		end
		
		local loadedAttackSpeed = convertDataType(data.AttackSpeed, 0)
		-- AttackSpeed should be animation multiplier (1.0)
		-- Old data might have it as 1 (which is correct) or > 1.5 (invalid)
		if loadedAttackSpeed > 1.5 then
			-- Invalid value, reset to 1.0
			attackSpeed.Value = 1.0
		elseif loadedAttackSpeed > 0 and loadedAttackSpeed < 0.5 then
			-- Invalid value, reset to 1.0
			attackSpeed.Value = 1.0
		else
			attackSpeed.Value = loadedAttackSpeed == 0 and 0 or loadedAttackSpeed
		end
		
		slavkoins.Value = convertDataType(data.Slavkoins, 0)
		
		-- Ensure CurrentXP doesn't exceed MaximumXP
		if currxp.Value > maxxp.Value then
			-- If CurrentXP exceeds MaximumXP, trigger level up logic
			while currxp.Value >= maxxp.Value and level.Value < BaseStats.XP.maxLevel do
				local overtop = currxp.Value - maxxp.Value
				currxp.Value = overtop
				maxxp.Value = calculateMaximumXP(level.Value + 1)
				level.Value = level.Value + 1
			end
		end
	end
	
	-- Flag to track if stats have been initialized (to prevent applying multipliers on load)
	local statsInitialized = false
	
	-- XP-based leveling: Level only increases when CurrentXP >= MaximumXP
	-- Connect this OUTSIDE CharacterAdded so it works even before character spawns
	-- Use a flag to prevent recursive triggers
	local isLevelingUp = false
	currxp.Changed:Connect(function(newv)
		-- Prevent recursive calls
		if isLevelingUp then
			return
		end
		
		-- DISABLE LEVELING WHEN CLASS IS SLAVKORIAN
		if class.Value == "Slavkorian" then
			return -- Don't allow leveling up when class is Slavkorian
		end
		
		-- Ensure MaximumXP is valid
		if not maxxp or not maxxp.Value then
			return
		end
		
		-- Check if we should level up (handle multiple level-ups in one go)
		-- Level increases ONLY when XP reaches MaximumXP threshold
		isLevelingUp = true
		while newv >= maxxp.Value and level.Value < BaseStats.XP.maxLevel do
			local overtop = newv - maxxp.Value
			local currentLevel = level.Value
			
			-- Increment level (this will trigger level.Changed which recalculates MaximumXP)
			level.Value = currentLevel + 1
			-- LEVEL CAP: Clamp level to max level from config
			level.Value = math.min(level.Value, BaseStats.XP.maxLevel)
			
			-- MaximumXP should be updated by level.Changed event, but let's ensure it's correct
			-- Get the new MaximumXP for the new level
			local newMaxXP = calculateMaximumXP(level.Value)
			maxxp.Value = newMaxXP
			
			-- Set remaining XP
			currxp.Value = overtop
			newv = overtop -- Update for while loop condition
		end
		isLevelingUp = false
		
		-- If at max level, cap current XP to MaximumXP
		if level.Value >= BaseStats.XP.maxLevel then
			currxp.Value = math.min(currxp.Value, maxxp.Value)
		end
	end)
	
	-- Track previous level to detect actual level ups (not initial load)
	local previousLevel = level.Value

	-- Update MaxHealth in real-time when it changes (works even before character spawns)
	-- This ensures resets and other changes update the humanoid immediately
	maxHealth.Changed:Connect(function(newMaxHealth)
		-- Update humanoid MaxHealth in real-time if character exists
		if plr.Character then
			local humanoid = plr.Character:FindFirstChild("Humanoid")
			if humanoid then
				-- Store old MaxHealth and old health before changing it
				local oldMaxHealth = humanoid.MaxHealth
				local oldHealth = humanoid.Health
				
				-- Update MaxHealth first
				humanoid.MaxHealth = newMaxHealth
				
				-- Set health based on new MaxHealth
				if newMaxHealth > 0 then
					-- If MaxHealth is increasing or resetting (old was 0 or new >= old), set to full health
					-- If MaxHealth is decreasing, preserve health percentage (but ensure minimum 50%)
					if newMaxHealth >= oldMaxHealth or oldMaxHealth == 0 then
						-- Set to full health when resetting or increasing MaxHealth
						humanoid.Health = newMaxHealth
					else
						-- Preserve health percentage when MaxHealth decreases (but ensure it's not too low)
						local healthPercentage = oldMaxHealth > 0 and (oldHealth / oldMaxHealth) or 1
						local newHealth = math.max(newMaxHealth * healthPercentage, newMaxHealth * 0.5)
						humanoid.Health = newHealth
					end
				else
					-- If MaxHealth is being set to 0 temporarily (during reset), don't change health
					-- Health will be set when MaxHealth is set to the final value
				end
			end
		end
	end)

	-- kapag level up, dagdagan at i-store
	-- Connect this OUTSIDE CharacterAdded so it works even before character spawns
	level.Changed:Connect(function()
		local newLevel = level.Value
		
		-- Recalculate MaximumXP when level changes (always, for resets too)
		local newMaxXP = calculateMaximumXP(newLevel)
		maxxp.Value = newMaxXP
		
		-- DISABLE LEVELING WHEN CLASS IS SLAVKORIAN
		if class.Value == "Slavkorian" then
			-- Don't apply multipliers when class is Slavkorian
			return
		end
		
		-- Only apply multipliers if stats are initialized AND level actually increased (not decreased/reset)
		-- This prevents applying multipliers during initial load or reset
		if not statsInitialized then
			-- Stats not initialized yet, skipping multiplier application
		elseif newLevel <= previousLevel then
			-- Level did not increase, skipping multipliers
		else
			local multipliers = BaseStats.LevelUpMultipliers[class.Value]
			
			if not multipliers then
				-- No multipliers found for class
			elseif newLevel > BaseStats.XP.maxLevel then
				-- Level exceeds max level, skipping multipliers
			else
				-- Apply level-up multipliers for all stats
				leaderstats.MaxHealth.Value = math.floor(leaderstats.MaxHealth.Value * multipliers.HP)
				
				-- For MaxAttack, use round to ensure it always increases (especially important for classes with small multipliers like Gladiator)
				-- Gladiator: 30 * 1.03 = 30.9, floor = 30 (no increase!), round = 31 (increases!)
				if leaderstats:FindFirstChild("MaxAttack") and multipliers.ATK then
					local oldATK = leaderstats.MaxAttack.Value
					local newATK = oldATK * multipliers.ATK
					-- Use round to ensure it always increases (math.floor(x + 0.5))
					local roundedATK = math.floor(newATK + 0.5)
					-- Ensure it increases by at least 1 (prevents stats from staying the same due to rounding)
					leaderstats.MaxAttack.Value = math.max(roundedATK, oldATK + 1)
				end
				
				if leaderstats:FindFirstChild("MaxDefense") and multipliers.D then
					leaderstats.MaxDefense.Value = math.floor(leaderstats.MaxDefense.Value * multipliers.D)
				end
				
				-- Apply offense stat multipliers
				-- Defense Penetration: Use round to ensure it increases (important when starting at 0)
				if leaderstats:FindFirstChild("DefensePenetration") and multipliers.DP then
					local oldDP = leaderstats.DefensePenetration.Value
					local newDP = oldDP * multipliers.DP
					-- Use round to ensure it increases (math.floor(x + 0.5))
					local roundedDP = math.floor(newDP + 0.5)
					-- Ensure it increases by at least 1 if it was 0 or very small (prevents staying at 0)
					if oldDP == 0 then
						-- If starting from 0, give at least 1 point on first level up
						leaderstats.DefensePenetration.Value = 1
					else
						-- Otherwise use rounded value, but ensure it increases
						leaderstats.DefensePenetration.Value = math.max(roundedDP, oldDP + 1)
					end
				end
				-- CritRate needs math.ceil because it's a small percentage stat (starts at 5)
				-- 5 * 1.03 = 5.15, floor(5.15) = 5 (stays same), ceil(5.15) = 6 (increases!)
				if leaderstats:FindFirstChild("CritRate") and multipliers.CR then
					local oldCR = leaderstats.CritRate.Value
					local newCritRate = oldCR * multipliers.CR
					-- Always use ceil to ensure progression (removes floating point comparison issues)
					leaderstats.CritRate.Value = math.ceil(newCritRate)
				end
				-- CritMultiplier works fine with floor since it starts at 150 (150 * 1.01 = 151.5, floor = 151 ✓)
				-- But we use round to ensure it always increases slightly
				if leaderstats:FindFirstChild("CritMultiplier") and multipliers.CM then
					local oldCM = leaderstats.CritMultiplier.Value
					local newCritMultiplier = oldCM * multipliers.CM
					-- Use round to ensure it increases (1.01 multiplier on 150 = 151.5, round = 152)
					-- math.round might not exist, so use: math.floor(x + 0.5)
					leaderstats.CritMultiplier.Value = math.floor(newCritMultiplier + 0.5)
				end
				
				-- Apply defense/utility stat multipliers
				-- Health Regeneration: Use round to ensure it increases (important when starting at 0)
				if leaderstats:FindFirstChild("HealthRegen") and multipliers.HR then
					local oldHR = leaderstats.HealthRegen.Value
					local newHR = oldHR * multipliers.HR
					-- Use round to ensure it increases (math.floor(x + 0.5))
					local roundedHR = math.floor(newHR + 0.5)
					-- Ensure it increases by at least 1 if it was 0 or very small (prevents staying at 0)
					if oldHR == 0 then
						-- If starting from 0, give at least 1 point on first level up
						leaderstats.HealthRegen.Value = 1
					else
						-- Otherwise use rounded value, but ensure it increases
						leaderstats.HealthRegen.Value = math.max(roundedHR, oldHR + 1)
					end
				end
				if leaderstats:FindFirstChild("MovementSpeed") and multipliers.Mspd then
					local oldMspd = leaderstats.MovementSpeed.Value
					-- MovementSpeed is the animation speed multiplier, scale it with Mspd multiplier
					leaderstats.MovementSpeed.Value = oldMspd * multipliers.Mspd
					
					-- Update unified movement animation speed in ServerConfigs (MovementSpeed is already the multiplier)
					local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
					end
					
					-- Sync animation speeds with action files for all players of this class
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("movement", movementAnimSpeedMultiplier)
					end
				end
				if leaderstats:FindFirstChild("AttackSpeed") and multipliers.Aspd then
					local oldAspd = leaderstats.AttackSpeed.Value
					-- AttackSpeed is the animation speed multiplier, scale it with Aspd multiplier
					leaderstats.AttackSpeed.Value = oldAspd * multipliers.Aspd
					
					-- Update unified attack animation speed in ServerConfigs (AttackSpeed is already the multiplier)
					local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
					end
					
					-- Sync animation speeds with action files for all players of this class
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("attack", attackAnimSpeedMultiplier)
					end
				end

				-- update humanoid din habang buhay pa siya (if character exists)
				if plr.Character then
					local humanoid = plr.Character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.MaxHealth = leaderstats.MaxHealth.Value
						humanoid.Health = humanoid.MaxHealth
						-- Update walk speed: base Mspd (18) * MovementSpeed animation multiplier
						if leaderstats:FindFirstChild("MovementSpeed") and multipliers.Mspd then
							local baseStats = BaseStats[class.Value]
							local baseMspd = baseStats and baseStats.Mspd or 18
							humanoid.WalkSpeed = baseMspd * leaderstats.MovementSpeed.Value
						end
					end
				end
			end
		end
		
		-- Update previous level (important for detecting resets)
		previousLevel = newLevel
	end)
	
	-- Function to apply base stats (works before character spawns)
	local function applyBaseStats()
		-- Get base stats from BaseStats based on class
		local baseStats = BaseStats[class.Value]
		
		-- If no base stats found for class, use Slavkorian defaults
		if not baseStats then
			baseStats = { HP = 1000, ATK = 100, D = 0, DP = 0, CR = 5, CM = 150, HR = 0, Mspd = 18, Aspd = 1 }
		end
		
		-- Set all base stats if not already set (Value == 0 means uninitialized)
		if leaderstats:FindFirstChild("MaxHealth").Value == 0 then
			leaderstats.MaxHealth.Value = baseStats.HP
		end
		
		if leaderstats:FindFirstChild("MaxAttack").Value == 0 then
			leaderstats.MaxAttack.Value = baseStats.ATK
		end
		
		if leaderstats:FindFirstChild("MaxDefense").Value == 0 then
			leaderstats.MaxDefense.Value = baseStats.D
		end
		
		-- Set CurrentDefense to MaxDefense if not set
		if leaderstats:FindFirstChild("CurrentDefense") and leaderstats.CurrentDefense.Value == 0 then
			leaderstats.CurrentDefense.Value = baseStats.D
		end
		
		if leaderstats:FindFirstChild("DefensePenetration").Value == 0 then
			leaderstats.DefensePenetration.Value = baseStats.DP or 0
		end
		
		if leaderstats:FindFirstChild("CritRate").Value == 0 then
			leaderstats.CritRate.Value = baseStats.CR or 5
		end
		
		if leaderstats:FindFirstChild("CritMultiplier").Value == 0 then
			leaderstats.CritMultiplier.Value = baseStats.CM or 150
		end
		
		if leaderstats:FindFirstChild("HealthRegen").Value == 0 then
			leaderstats.HealthRegen.Value = baseStats.HR or 0
		end
		
		if leaderstats:FindFirstChild("MovementSpeed").Value == 0 then
			-- MovementSpeed in leaderstats is the animation speed multiplier, should start at 1.0
			leaderstats.MovementSpeed.Value = 1.0
		end
		
		if leaderstats:FindFirstChild("AttackSpeed").Value == 0 then
			-- AttackSpeed in leaderstats is the animation speed multiplier, should start at 1.0
			leaderstats.AttackSpeed.Value = 1.0
		end
		
		-- Initialize animation speeds in ServerConfigs based on MovementSpeed and AttackSpeed (animation multipliers)
		if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
			local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
			local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
			ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
			ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
		end
		if ServerConfigs and ServerConfigs[class.Value] then
			local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
			local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
			ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
			ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
		end
	end
	
	-- Apply base stats when class changes (works immediately, even before character spawns)
	class.Changed:Connect(function()
		-- Reset all stats to 0 so base stats get applied
		leaderstats.MaxHealth.Value = 0
		leaderstats.MaxAttack.Value = 0
		leaderstats.MaxDefense.Value = 0
		leaderstats.CurrentDefense.Value = 0
		leaderstats.DefensePenetration.Value = 0
		leaderstats.CritRate.Value = 0
		leaderstats.CritMultiplier.Value = 0
		leaderstats.HealthRegen.Value = 0
		leaderstats.MovementSpeed.Value = 0
		leaderstats.AttackSpeed.Value = 0
		-- Apply base stats immediately
		applyBaseStats()
		-- Mark stats as initialized when class is set (allows leveling before character spawns)
		if class.Value and class.Value ~= "Slavkorian" then
			statsInitialized = true
		else
			statsInitialized = false
		end
	end)
	
	-- Apply base stats on initial load (if no saved data or if class was selected)
	if not data or (data and class.Value ~= "Slavkorian") then
		applyBaseStats()
		-- Mark stats as initialized if class is already set
		if class.Value and class.Value ~= "Slavkorian" then
			statsInitialized = true
		end
	end

	-- Health regeneration system
	local healthRegenConnections = {}
	
	-- Defense regeneration system
	local defenseRegenConnections = {}
	
	-- Function to start health regeneration for a character
	local function startHealthRegen(character, humanoid)
		-- Clean up any existing thread for this character
		if healthRegenConnections[character] then
			-- Cancel the existing thread
			task.cancel(healthRegenConnections[character])
			healthRegenConnections[character] = nil
		end
		
		-- Get HealthRegen stat
		local healthRegenStat = leaderstats:FindFirstChild("HealthRegen")
		if not healthRegenStat or healthRegenStat.Value <= 0 then
			return -- No health regen, don't start system
		end
		
		-- Run health regeneration every second
		local regenThread = task.spawn(function()
			while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
				-- Check if character and humanoid still exist before waiting
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				task.wait(1) -- Wait 1 second
				
				-- Check again after wait (character might have been removed)
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				-- Get current HealthRegen value
				local currentHealthRegen = healthRegenStat.Value
				if currentHealthRegen > 0 then
					-- Regenerate health (cap at MaxHealth)
					local newHealth = math.min(humanoid.Health + currentHealthRegen, humanoid.MaxHealth)
					humanoid.Health = newHealth
				else
					-- If HealthRegen becomes 0, stop regenerating
					break
				end
			end
			
			-- Clean up when done
			healthRegenConnections[character] = nil
		end)
		
		healthRegenConnections[character] = regenThread
	end
	
	-- Function to start defense regeneration for a character
	local function startDefenseRegen(character, humanoid)
		-- Clean up any existing thread for this character
		if defenseRegenConnections[character] then
			task.cancel(defenseRegenConnections[character])
			defenseRegenConnections[character] = nil
		end
		
		-- Get defense regen config
		local defenseRegenConfig = ServerConfigs.DefenseRegen
		if not defenseRegenConfig or not defenseRegenConfig.enabled then
			return
		end
		
		-- Run defense regeneration every tick interval
		local regenThread = task.spawn(function()
			while character and character.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
				-- Check if character and humanoid still exist before waiting
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				task.wait(defenseRegenConfig.tickInterval) -- Wait for tick interval
				
				-- Check again after wait
				if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end
				
				-- Defense only regenerates when health is full
				if humanoid.Health >= humanoid.MaxHealth then
					local currentDef = leaderstats.CurrentDefense.Value
					local maxDef = leaderstats.MaxDefense.Value
					
					-- Only regen if defense is not at max
					if currentDef < maxDef then
						local newDef = math.min(currentDef + defenseRegenConfig.regenRate, maxDef)
						leaderstats.CurrentDefense.Value = newDef
					end
				end
			end
			
			-- Clean up when done
			defenseRegenConnections[character] = nil
		end)
		
		defenseRegenConnections[character] = regenThread
	end
	
	-- Sa spawn
	plr.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")

		-- Apply base stats if not already set
		applyBaseStats()

		-- Apply stored MaxHealth to humanoid
		humanoid.MaxHealth = leaderstats.MaxHealth.Value
		humanoid.Health = humanoid.MaxHealth
		
		-- Reset CurrentDefense to MaxDefense on respawn
		local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
		local maxDefense = leaderstats:FindFirstChild("MaxDefense")
		if currentDefense and maxDefense then
			currentDefense.Value = maxDefense.Value
		elseif maxDefense then
			-- Create CurrentDefense if it doesn't exist
			local newCurrentDefense = Instance.new("NumberValue", leaderstats)
			newCurrentDefense.Name = "CurrentDefense"
			newCurrentDefense.Value = maxDefense.Value
		end
		
		-- Apply Movement Speed: base Mspd (18) * MovementSpeed animation multiplier
		if leaderstats:FindFirstChild("MovementSpeed") then
			local baseStats = BaseStats[class.Value]
			local baseMspd = baseStats and baseStats.Mspd or 18
			humanoid.WalkSpeed = baseMspd * leaderstats.MovementSpeed.Value
		end
		
		-- Start health regeneration system
		startHealthRegen(char, humanoid)
		
		-- Start defense regeneration system
		startDefenseRegen(char, humanoid)
		
		-- Initialize animation speeds based on MovementSpeed and AttackSpeed (animation multipliers)
		if class.Value and class.Value ~= "Slavkorian" then
			local movementAnimSpeedMultiplier = leaderstats.MovementSpeed.Value
			local attackAnimSpeedMultiplier = leaderstats.AttackSpeed.Value
			if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
				ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
				ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
			end
			if ServerConfigs and ServerConfigs[class.Value] then
				ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
				ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
			end
			
			-- Sync animation speeds with action files
			local classFuncs = {
				Archer = _G.updateArcherAnimationSpeed,
				Samurai = _G.updateSamuraiAnimationSpeed,
				Brawler = _G.updateBrawlerAnimationSpeed,
				Knight = _G.updateKnightAnimationSpeed,
				Gladiator = _G.updateGladiatorAnimationSpeed
			}
			local updateFunc = classFuncs[class.Value]
			if updateFunc then
				updateFunc("movement", movementAnimSpeedMultiplier)
				updateFunc("attack", attackAnimSpeedMultiplier)
			end
		end
		
		-- Update animation speeds when MovementSpeed or AttackSpeed change
		local movementSpeedStat = leaderstats:FindFirstChild("MovementSpeed")
		if movementSpeedStat then
			movementSpeedStat.Changed:Connect(function()
				if class.Value and class.Value ~= "Slavkorian" then
					local movementAnimSpeedMultiplier = movementSpeedStat.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].movementSpeed = movementAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].MovementSpeed = movementAnimSpeedMultiplier
					end
					-- Update humanoid walk speed when MovementSpeed changes
					if humanoid then
						local baseStats = BaseStats[class.Value]
						local baseMspd = baseStats and baseStats.Mspd or 18
						humanoid.WalkSpeed = baseMspd * movementAnimSpeedMultiplier
					end
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("movement", movementAnimSpeedMultiplier)
					end
				end
			end)
		end
		
		local attackSpeedStat = leaderstats:FindFirstChild("AttackSpeed")
		if attackSpeedStat then
			attackSpeedStat.Changed:Connect(function()
				if class.Value and class.Value ~= "Slavkorian" then
					local attackAnimSpeedMultiplier = attackSpeedStat.Value
					if ServerConfigs and ServerConfigs.Hitboxes and ServerConfigs.Hitboxes.UnifiedAttacks and ServerConfigs.Hitboxes.UnifiedAttacks[class.Value] then
						ServerConfigs.Hitboxes.UnifiedAttacks[class.Value].attackSpeed = attackAnimSpeedMultiplier
					end
					if ServerConfigs and ServerConfigs[class.Value] then
						ServerConfigs[class.Value].AttackSpeed = attackAnimSpeedMultiplier
					end
					local classFuncs = {
						Archer = _G.updateArcherAnimationSpeed,
						Samurai = _G.updateSamuraiAnimationSpeed,
						Brawler = _G.updateBrawlerAnimationSpeed,
						Knight = _G.updateKnightAnimationSpeed,
						Gladiator = _G.updateGladiatorAnimationSpeed
					}
					local updateFunc = classFuncs[class.Value]
					if updateFunc then
						updateFunc("attack", attackAnimSpeedMultiplier)
					end
				end
			end)
		end
		
		-- Update health regen when the stat changes
		local healthRegenStat = leaderstats:FindFirstChild("HealthRegen")
		if healthRegenStat then
			healthRegenStat.Changed:Connect(function()
				-- Restart health regen system with new value
				if char.Parent and humanoid.Parent then
					startHealthRegen(char, humanoid)
				end
			end)
		end
		
		-- Update MaxHealth in real-time when it changes (so resets work immediately)
		local maxHealthStat = leaderstats:FindFirstChild("MaxHealth")
		if maxHealthStat then
			maxHealthStat.Changed:Connect(function(newMaxHealth)
				-- Update humanoid MaxHealth in real-time
				if char.Parent and humanoid.Parent then
					-- Store old MaxHealth and old health before changing it
					local oldMaxHealth = humanoid.MaxHealth
					local oldHealth = humanoid.Health
					
					-- Update MaxHealth first
					humanoid.MaxHealth = newMaxHealth
					
					-- Set health based on new MaxHealth
					if newMaxHealth > 0 then
						-- If MaxHealth is increasing or resetting (old was 0 or new >= old), set to full health
						-- If MaxHealth is decreasing, preserve health percentage (but ensure minimum 50%)
						if newMaxHealth >= oldMaxHealth or oldMaxHealth == 0 then
							-- Set to full health when resetting or increasing MaxHealth
							humanoid.Health = newMaxHealth
						else
							-- Preserve health percentage when MaxHealth decreases (but ensure it's not too low)
							local healthPercentage = oldMaxHealth > 0 and (oldHealth / oldMaxHealth) or 1
							local newHealth = math.max(newMaxHealth * healthPercentage, newMaxHealth * 0.5)
							humanoid.Health = newHealth
						end
					else
						-- If MaxHealth is being set to 0 temporarily (during reset), don't change health
						-- Health will be set when MaxHealth is set to the final value
					end
				end
			end)
		end
		
		-- Mark stats as initialized after first spawn
		statsInitialized = true
		
		-- Also initialize stats immediately when class is set (before character spawns)
		-- This allows leveling up to work even before character spawns
		if class.Value and class.Value ~= "Slavkorian" then
			statsInitialized = true
		end
	end)
	
	-- Clean up health and defense regen when player leaves
	plr.CharacterRemoving:Connect(function(char)
		if healthRegenConnections[char] then
			healthRegenConnections[char] = nil
		end
		if defenseRegenConnections[char] then
			defenseRegenConnections[char] = nil
		end
	end)
	
end)

-- Function to save player data
local function savePlayerData(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats or not MainDataStore then
		return
	end
	
	-- Ensure MaximumXP is correct before saving
	local currentLevel = leaderstats.Level.Value
	leaderstats.MaximumXP.Value = calculateMaximumXP(currentLevel)
	
	-- LEVEL CAP: Clamp level before saving
	leaderstats.Level.Value = math.min(leaderstats.Level.Value, BaseStats.XP.maxLevel)

	-- Helper function to safely get a stat value
	local function getStatValue(statName, defaultValue)
		local stat = leaderstats:FindFirstChild(statName)
		if stat and stat:IsA("ValueBase") then
			return tonumber(stat.Value) or defaultValue
		end
		return defaultValue
	end
	
	local dataToSave = {
		Level = getStatValue("Level", 1),
		CurrentXP = getStatValue("CurrentXP", 0),
		MaximumXP = getStatValue("MaximumXP", BaseStats.XP.startMaxXP),
		Class = tostring(leaderstats.Class.Value) or "Slavkorian",
		MaxAttack = getStatValue("MaxAttack", 0),
		DefensePenetration = getStatValue("DefensePenetration", 0),
		CritRate = getStatValue("CritRate", 0),
		CritMultiplier = getStatValue("CritMultiplier", 0),
		MaxDefense = getStatValue("MaxDefense", 0),
		CurrentDefense = getStatValue("CurrentDefense", getStatValue("MaxDefense", 0)), -- Default to MaxDefense if CurrentDefense doesn't exist
		MaxHealth = getStatValue("MaxHealth", 0),
		HealthRegen = getStatValue("HealthRegen", 0),
		MovementSpeed = getStatValue("MovementSpeed", 0),
		AttackSpeed = getStatValue("AttackSpeed", 0),
		Slavkoins = getStatValue("Slavkoins", 0)
	}

	local success, err = MainDataStore.SavePlayerData(plr.UserId, dataToSave)
	if not success then
		-- Failed to save data
	end
end

-- Save data periodically (every 60 seconds) and on player removal
game.Players.PlayerRemoving:Connect(function(plr)
	savePlayerData(plr)
end)

-- Periodic save (every 60 seconds)
spawn(function()
	while true do
		wait(60)
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr:FindFirstChild("leaderstats") then
				savePlayerData(plr)
			end
		end
	end
end)

-- Handle dev stat changes from client
DevStatEvent.OnServerEvent:Connect(function(plr, action, value)
	-- Only allow dev stat changes from the client (security: could add admin check here)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	
	if action == "setCurrentXP" then
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = tonumber(value) or 0
		end
	elseif action == "addCurrentXP" then
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = leaderstats.CurrentXP.Value + (tonumber(value) or 0)
		end
	elseif action == "setLevel" then
		if leaderstats:FindFirstChild("Level") then
			local newLevel = tonumber(value) or 1
			-- LEVEL CAP: Clamp level to max level
			leaderstats.Level.Value = math.min(math.max(newLevel, 1), BaseStats.XP.maxLevel)
			-- Recalculate MaximumXP for the new level
			if leaderstats:FindFirstChild("MaximumXP") then
				leaderstats.MaximumXP.Value = calculateMaximumXP(leaderstats.Level.Value)
			end
		end
	elseif action == "setClass" then
		if leaderstats:FindFirstChild("Class") then
			local newClass = tostring(value) or "Slavkorian"
			
			-- Reset level to 1
			if leaderstats:FindFirstChild("Level") then
				leaderstats.Level.Value = 1
			end
			
			-- Reset XP to 0
			if leaderstats:FindFirstChild("CurrentXP") then
				leaderstats.CurrentXP.Value = 0
			end
			
			-- Recalculate MaximumXP for level 1
			if leaderstats:FindFirstChild("MaximumXP") then
				leaderstats.MaximumXP.Value = calculateMaximumXP(1)
			end
			
		-- Reset all stats to 0 first
		local statsToReset = {"MaxAttack", "MaxDefense", "CurrentDefense", "MaxHealth", "DefensePenetration", 
			"CritRate", "CritMultiplier", "HealthRegen", "MovementSpeed", "AttackSpeed"}
			
			for _, statName in ipairs(statsToReset) do
				if leaderstats:FindFirstChild(statName) then
					leaderstats[statName].Value = 0
				end
			end
			
			-- Set class (this will trigger class.Changed event which applies base stats)
			leaderstats.Class.Value = newClass
			
			-- Apply base stats immediately (don't wait for class.Changed event)
			local baseStats = BaseStats[newClass]
			if baseStats then
				leaderstats.MaxHealth.Value = baseStats.HP or 0
				leaderstats.MaxAttack.Value = baseStats.ATK or 0
				leaderstats.MaxDefense.Value = baseStats.D or 0
				leaderstats.CurrentDefense.Value = baseStats.D or 0
				leaderstats.DefensePenetration.Value = baseStats.DP or 0
				leaderstats.CritRate.Value = baseStats.CR or 5
				leaderstats.CritMultiplier.Value = baseStats.CM or 150
				leaderstats.HealthRegen.Value = baseStats.HR or 0
				-- MovementSpeed and AttackSpeed are animation speed multipliers, should start at 1.0
				leaderstats.MovementSpeed.Value = 1.0
				leaderstats.AttackSpeed.Value = 1.0
			else
				-- Default Slavkorian stats if class not found
				leaderstats.MaxHealth.Value = 1000
				leaderstats.MaxAttack.Value = 100
				leaderstats.MaxDefense.Value = 0
				leaderstats.CurrentDefense.Value = 0
				leaderstats.DefensePenetration.Value = 0
				leaderstats.CritRate.Value = 5
				leaderstats.CritMultiplier.Value = 150
				leaderstats.HealthRegen.Value = 0
				-- MovementSpeed and AttackSpeed are animation speed multipliers, should start at 1.0
				leaderstats.MovementSpeed.Value = 1.0
				leaderstats.AttackSpeed.Value = 1.0
			end
		end
	elseif action == "resetStat" then
		local statName = tostring(value)
		if leaderstats:FindFirstChild(statName) then
			leaderstats[statName].Value = 0
		end
	elseif action == "fullReset" then
		-- Full reset: Level 1, XP 0, MaximumXP recalculated, Class Slavkorian, all stats reset
		
		-- Reset level first (this will recalculate MaximumXP)
		if leaderstats:FindFirstChild("Level") then
			leaderstats.Level.Value = 1
		end
		
		-- Reset XP
		if leaderstats:FindFirstChild("CurrentXP") then
			leaderstats.CurrentXP.Value = 0
		end
		
		-- Recalculate MaximumXP for level 1
		if leaderstats:FindFirstChild("MaximumXP") then
			leaderstats.MaximumXP.Value = calculateMaximumXP(1)
		end
		
		-- Reset class (this will trigger base stats application)
		if leaderstats:FindFirstChild("Class") then
			leaderstats.Class.Value = "Slavkorian"
		end
		
		-- Reset all stats to 0 (base stats will be applied via class.Changed event)
		local statsToReset = {"MaxAttack", "MaxDefense", "CurrentDefense", "MaxHealth", "DefensePenetration", 
			"CritRate", "CritMultiplier", "HealthRegen", "MovementSpeed", "AttackSpeed"}
		
		for _, statName in ipairs(statsToReset) do
			if leaderstats:FindFirstChild(statName) then
				leaderstats[statName].Value = 0
			end
		end
	end
end)

