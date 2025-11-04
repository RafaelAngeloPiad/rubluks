-- ========================================
-- GLADIATOR PASSIVES SERVER
-- Passive: Champion's Rebuke - 2nd combo attack has chance to hit twice (double damage)
-- Passive: One Last Chance - Resurrects player when HP reaches 0
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import centralized configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Function to check if Champion's Rebuke passive should trigger
-- @param player: Player instance
-- @return: boolean indicating if passive should trigger
function _G.checkChampionsRebukePassive(player)
	if not player then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Check if player is Gladiator class
	local class = leaderstats:FindFirstChild("Class")
	if not class or class.Value ~= "Gladiator" then
		return false
	end
	
	-- Get player level
	local level = leaderstats:FindFirstChild("Level")
	if not level then
		return false
	end
	
	-- Get passive config (this checks for highest unlocked level)
	local passiveConfig = ServerConfigs.getGladiatorPassiveConfig("ChampionsRebuke", level.Value)
	if not passiveConfig or not passiveConfig.chance then
		-- Passive not unlocked or config invalid
		return false
	end
	
	-- Roll for chance to trigger passive (0-100)
	-- If chance is 100, always trigger; otherwise roll
	if passiveConfig.chance >= 100 then
		return true
	end
	
	local roll = math.random() * 100
	local shouldTrigger = roll < passiveConfig.chance
	
	return shouldTrigger
end

-- Store player state for One Last Chance passive
local playerOneLastChanceStates = {}

-- Function to show "RESURRECTED" text above character head
local function showResurrectedText(character)
	if not character or not character.Parent then return end
	
	local head = character:FindFirstChild("Head")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local attachPart = head or humanoidRootPart
	
	if not attachPart then return end
	
	-- Create "RESURRECTED" text
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ResurrectedText_" .. tostring(tick() * 1000)
	billboardGui.Size = UDim2.new(0, 250, 0, 60)
	billboardGui.StudsOffset = Vector3.new(0, 3.5, 0) -- Above head, higher than ailment text
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboardGui.Parent = attachPart
	
	-- Create TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "RESURRECTED"
	textLabel.TextColor3 = Color3.new(1, 0.8, 0) -- Gold/Orange
	textLabel.TextSize = 32
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = billboardGui
	
	-- Remove text after 3 seconds
	task.delay(3, function()
		if billboardGui and billboardGui.Parent then
			billboardGui:Destroy()
		end
	end)
end

-- Function to handle One Last Chance resurrection
local function handleOneLastChanceResurrection(player, character, humanoid, passiveConfig)
	if not player or not character or not humanoid or not passiveConfig then
		return false
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end
	
	-- Check if One Last Chance has already been used (once per life)
	local state = playerOneLastChanceStates[player]
	if state and state.resurrected then
		-- Already used this life, don't resurrect again
		return false
	end
	
	-- Get resurrect HP percentage
	local resurrectHPPercentage = passiveConfig.resurrectHPPercentage or 0.1
	
	-- Calculate resurrected HP (percentage of Max HP)
	local maxHealth = humanoid.MaxHealth
	local resurrectedHealth = math.floor(maxHealth * resurrectHPPercentage)
	
	-- Prevent death by immediately setting health
	-- This must happen as fast as possible to prevent death
	-- Set it synchronously first (immediate response)
	if humanoid.Health <= 0 then
		humanoid.Health = math.max(1, resurrectedHealth)
	end
	
	-- Also use task.spawn as a backup to ensure it happens even if something else tries to set health to 0
	task.spawn(function()
		-- Wait a tiny bit to ensure we catch it after any other death processing
		task.wait(0)
		if humanoid and humanoid.Parent and humanoid.Health <= 0 then
			-- Set health to resurrected amount (this prevents death)
			humanoid.Health = math.max(1, resurrectedHealth) -- Ensure at least 1 HP
		end
	end)
	
	-- Restore Defense to full
	local maxDefense = leaderstats:FindFirstChild("MaxDefense")
	local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
	if maxDefense and currentDefense then
		currentDefense.Value = maxDefense.Value
	end
	
	-- Mark as resurrected (once per life)
	if not state then
		playerOneLastChanceStates[player] = {
			resurrected = false
		}
	end
	playerOneLastChanceStates[player].resurrected = true
	
	-- Show "RESURRECTED" text
	showResurrectedText(character)
	
	-- Enable invincibility for 3 seconds after resurrection (god mode to escape)
	if _G.enablePlayerInvincibility then
		_G.enablePlayerInvincibility(player)
		
		-- Disable invincibility after 3 seconds
		task.spawn(function()
			task.wait(3)
			
			-- Check if character still exists before disabling invincibility
			if character and character.Parent and humanoid and humanoid.Parent then
				if _G.disablePlayerInvincibility then
					_G.disablePlayerInvincibility(player)
				end
			else
				-- Character was removed, disable invincibility anyway (safety cleanup)
				if _G.disablePlayerInvincibility then
					_G.disablePlayerInvincibility(player)
				end
			end
		end)
	end
	
	-- Update ActivePassives tracking
	local activePassives = leaderstats:FindFirstChild("ActivePassives")
	if activePassives then
		local currentPassives = activePassives.Value
		-- Check if OneLastChance is already in the list
		if not string.find(currentPassives, "OneLastChance") then
			if currentPassives == "" then
				activePassives.Value = "OneLastChance"
			else
				activePassives.Value = currentPassives .. ",OneLastChance"
			end
		end
	end
	
	return true
end

-- Monitor all players for One Last Chance passive
local function setupPlayerOneLastChance(player)
	-- Wait for character to spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Reset resurrected state on respawn (new life)
		if playerOneLastChanceStates[player] then
			playerOneLastChanceStates[player].resurrected = false
		else
			playerOneLastChanceStates[player] = {
				resurrected = false
			}
		end
		
		-- Monitor health for One Last Chance using HealthChanged (immediate response)
		-- This catches health changes as soon as they happen, before death triggers
		local healthChangedConnection
		healthChangedConnection = humanoid.HealthChanged:Connect(function(newHealth)
			-- Check if health reached 0 or below (character is still alive at this point)
			if newHealth <= 0 and humanoid.Parent and humanoid.Health <= 0 then
				local leaderstats = player:FindFirstChild("leaderstats")
				if not leaderstats then return end
				
				local class = leaderstats:FindFirstChild("Class")
				local level = leaderstats:FindFirstChild("Level")
				
				-- Only check if player is Gladiator class
				if class and class.Value == "Gladiator" and level then
					-- Get passive config
					local passiveConfig = ServerConfigs.getGladiatorPassiveConfig("OneLastChance", level.Value)
					if passiveConfig then
						-- Try to resurrect (will fail if already used this life)
						local resurrected = handleOneLastChanceResurrection(player, character, humanoid, passiveConfig)
						if resurrected then
							-- Successfully resurrected, health should now be > 0
							-- The function already set the health, so we're good
						end
					end
				end
			end
		end)
		
		-- Also use Heartbeat as a backup safety net (in case HealthChanged doesn't catch it)
		local heartbeatConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			-- Check if character and humanoid still exist
			if not character or not character.Parent or not humanoid or not humanoid.Parent then
				if heartbeatConnection then
					heartbeatConnection:Disconnect()
				end
				return
			end
			
			-- Check if health reached 0 or below (but character is still alive)
			if humanoid.Health <= 0 and humanoid.Parent then
				local leaderstats = player:FindFirstChild("leaderstats")
				if not leaderstats then return end
				
				local class = leaderstats:FindFirstChild("Class")
				local level = leaderstats:FindFirstChild("Level")
				
				-- Only check if player is Gladiator class
				if class and class.Value == "Gladiator" and level then
					-- Get passive config
					local passiveConfig = ServerConfigs.getGladiatorPassiveConfig("OneLastChance", level.Value)
					if passiveConfig then
						-- Try to resurrect (will fail if already used this life)
						local resurrected = handleOneLastChanceResurrection(player, character, humanoid, passiveConfig)
						if resurrected then
							-- Successfully resurrected, health should now be > 0
							-- The function already set the health, so we're good
						end
					end
				end
			end
		end)
		
		-- Clean up when character is removed
		character:WaitForChild("HumanoidRootPart").AncestryChanged:Connect(function()
			if not character.Parent then
				if healthChangedConnection then
					healthChangedConnection:Disconnect()
				end
				if heartbeatConnection then
					heartbeatConnection:Disconnect()
				end
			end
		end)
	end)
	
	-- Also monitor level changes (for passive unlocking)
	player:WaitForChild("leaderstats", 10)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level")
		if level then
			level.Changed:Connect(function()
				-- Level changed, but no need to do anything special here
				-- The passive will be checked when HP reaches 0
			end)
		end
		
		-- Monitor class changes
		local class = leaderstats:FindFirstChild("Class")
		if class then
			class.Changed:Connect(function()
				-- Class changed, reset resurrected state
				if playerOneLastChanceStates[player] then
					playerOneLastChanceStates[player].resurrected = false
				end
			end)
		end
	end
end

-- Setup for all players
Players.PlayerAdded:Connect(function(player)
	setupPlayerOneLastChance(player)
end)

-- Setup for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerOneLastChance(player)
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerOneLastChanceStates[player] then
		playerOneLastChanceStates[player] = nil
	end
end)

