-- ========================================
-- UNIFIED BUTTON MANAGER
-- Single button system that works for ALL classes
-- Buttons automatically switch based on equipped weapon
-- Place this in StarterGui > ActionsGUI
-- ========================================
-- NOTE: Global keybinds (like Wave) work WITHOUT weapon equipped!
-- See GlobalKeybindManager.client.luau for global keybind handling
-- ========================================

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

-- Require all action modules
local SamuraiActions = require(player.PlayerScripts.samurai.SamuraiActionModule)
local ArcherActions = require(player.PlayerScripts.archer.ArcherActionModule)
local KnightActions = require(player.PlayerScripts.knight.KnightActionModule)
local GladiatorActions = require(player.PlayerScripts.gladiator.GladiatorActionModule)
local BrawlerActions = require(player.PlayerScripts.brawler.BrawlerActionModule)

-- ========================================
-- UNIFIED BUTTON TAG CONFIGURATION
-- One tag per action, works for ALL classes!
-- Generic names not tied to specific keybinds
-- ========================================

local UNIFIED_TAGS = {
	-- Basic actions (shared across all classes)
	attack_trigger = {
		samurai = {
			action = function() return SamuraiActions.basicAttack() end,
			name = "[LMB] Attack",
			description = "Basic attack (auto-detects: normal, move, or jump attack)"
		},
		archer = {
			action = function() return ArcherActions.basicAttack() end,
			name = "[LMB] Attack",
			description = "Basic attack with aim"
		},
		knight = {
			action = function() return KnightActions.basicAttack() end,
			name = "[LMB] Attack",
			description = "Basic attack (auto-detects: normal, move, or jump attack)"
		},
		gladiator = {
			action = function() return GladiatorActions.basicAttack() end,
			name = "[LMB] Attack",
			description = "Basic attack (2-hit combo, move, or jump attack)"
		},
		brawler = {
			action = function() return BrawlerActions.basicAttack() end,
			name = "[LMB] Attack",
			description = "Basic attack (2-hit combo, move, or jump attack)"
		}
	},
	
	block_trigger = {
		samurai = {
			start = function() return SamuraiActions.blockStart() end,
			stop = function() return SamuraiActions.blockEnd() end,
			isHoldButton = true,
			name = "[V] Block",
			description = "Hold to block"
		},
		archer = {
			start = function() return ArcherActions.blockStart() end,
			stop = function() return ArcherActions.blockEnd() end,
			isHoldButton = true,
			name = "[V] Block",
			description = "Hold to block"
		},
		knight = {
			start = function() return KnightActions.blockStart() end,
			stop = function() return KnightActions.blockEnd() end,
			isHoldButton = true,
			name = "[V] Block",
			description = "Hold to block with shield"
		},
		gladiator = {
			start = function() return GladiatorActions.blockStart() end,
			stop = function() return GladiatorActions.blockEnd() end,
			isHoldButton = true,
			name = "[V] Block",
			description = "Hold to block with shield"
		},
		brawler = {
			start = function() return BrawlerActions.blockStart() end,
			stop = function() return BrawlerActions.blockEnd() end,
			isHoldButton = true,
			name = "[V] Block",
			description = "Hold to block"
		}
	},
	
	wave_trigger = {
		samurai = {
			action = function()
				-- Global wave (works without weapon)
				local remote = game:GetService("ReplicatedStorage"):WaitForChild("ActionEvent")
				remote:FireServer("global_wave")
				return true
			end,
			name = "[L] Wave",
			description = "Wave emote",
			isGlobal = true -- Doesn't require weapon
		},
		archer = {
			action = function()
				-- Global wave (works without weapon)
				local remote = game:GetService("ReplicatedStorage"):WaitForChild("ActionEvent")
				remote:FireServer("global_wave")
				return true
			end,
			name = "[L] Wave",
			description = "Wave emote",
			isGlobal = true -- Doesn't require weapon
		},
		knight = {
			action = function()
				-- Global wave (works without weapon)
				local remote = game:GetService("ReplicatedStorage"):WaitForChild("ActionEvent")
				remote:FireServer("global_wave")
				return true
			end,
			name = "[L] Wave",
			description = "Wave emote",
			isGlobal = true -- Doesn't require weapon
		},
		gladiator = {
			action = function()
				-- Global wave (works without weapon)
				local remote = game:GetService("ReplicatedStorage"):WaitForChild("ActionEvent")
				remote:FireServer("global_wave")
				return true
			end,
			name = "[L] Wave",
			description = "Wave emote",
			isGlobal = true -- Doesn't require weapon
		},
		brawler = {
			action = function()
				-- Global wave (works without weapon)
				local remote = game:GetService("ReplicatedStorage"):WaitForChild("ActionEvent")
				remote:FireServer("global_wave")
				return true
			end,
			name = "[L] Wave",
			description = "Wave emote",
			isGlobal = true -- Doesn't require weapon
		}
	},
	
	-- Skill 1 (varies by class)
	skill1_trigger = {
		samurai = {
			action = function() return SamuraiActions.wakizashi() end,
			name = "[Q] Wakizashi",
			description = "Wakizashi skill"
		},
		archer = {
			action = function() return ArcherActions.piercingShot() end,
			name = "[Q] Piercing Shot",
			description = "Piercing Shot skill"
		},
		knight = {
			action = function() return KnightActions.sworddance() end,
			name = "[Q] Sword Dance",
			description = "Sword Dance skill"
		},
		gladiator = {
			action = function() return GladiatorActions.shieldbash() end,
			name = "[Q] Shield Bash",
			description = "Shield Bash skill"
		},
		brawler = {
			action = function() return BrawlerActions.feralleap() end,
			name = "[Q] Feral Leap",
			description = "Feral Leap skill"
		}
	},
	
	-- Skill 2 (varies by class)
	skill2_trigger = {
		samurai = {
			action = function() return SamuraiActions.kozuki() end,
			name = "[E] Kozuki",
			description = "Kozuki skill"
		},
		archer = {
			action = function() return ArcherActions.powerShot() end,
			name = "[E] Power Shot",
			description = "Power Shot skill"
		},
		knight = {
			action = function() return KnightActions.cyclone_slash() end,
			name = "[E] Cyclone Slash",
			description = "Cyclone Slash skill"
		},
		gladiator = {
			action = function() return GladiatorActions.dragoonjump() end,
			name = "[E] Dragoon Jump",
			description = "Dragoon Jump skill"
		},
		brawler = {
			action = function() return BrawlerActions.brawlersroar() end,
			name = "[E] Berserker's Roar",
			description = "Berserker's Roar skill"
		}
	},
	
	-- Buff 1 (varies by class)
	buff1_trigger = {
		samurai = {
			action = function() return SamuraiActions.banzai() end,
			name = "[X] Banzai",
			description = "Banzai buff"
		},
		archer = {
			action = function() return ArcherActions.hunterInstinct() end,
			name = "[X] Hunters Instinct",
			description = "Hunters Instinct buff"
		},
		knight = {
			action = function() return KnightActions.warcry() end,
			name = "[X] War Cry",
			description = "War Cry buff"
		},
		gladiator = {
			action = function() return GladiatorActions.championsblood() end,
			name = "[X] Champions Blood",
			description = "Champions Blood buff"
		},
		brawler = {
			action = function() return BrawlerActions.bloodthirst() end,
			name = "[X] Bloodthirst",
			description = "Bloodthirst buff"
		}
	},
	
	-- Buff 2 (varies by class)
	buff2_trigger = {
		samurai = {
			action = function() return SamuraiActions.bushido() end,
			name = "[C] Bushido",
			description = "Bushido buff"
		},
		archer = {
			action = function() return ArcherActions.hunterMark() end,
			name = "[C] Hunters Mark",
			description = "Hunters Mark buff"
		},
		knight = {
			action = function() return KnightActions.warriormight() end,
			name = "[C] Warrior Might",
			description = "Warrior Might buff"
		},
		gladiator = {
			action = function() return GladiatorActions.championscheer() end,
			name = "[C] Champions Cheer",
			description = "Champions Cheer buff"
		},
		brawler = {
			action = function() return BrawlerActions.lastchance() end,
			name = "[C] Last Chance",
			description = "Last Chance buff"
		}
	},
	
	-- Ultimate (varies by class)
	ultimate_trigger = {
		samurai = {
			action = function() return SamuraiActions.zantetsuken() end,
			name = "[Z] Zantetsuken",
			description = "Zantetsuken ultimate"
		},
		archer = {
			action = function() return ArcherActions.starfall() end,
			name = "[Z] Starfall",
			description = "Starfall ultimate"
		},
		knight = {
			action = function() return KnightActions.mightyblade() end,
			name = "[Z] Mighty Blade",
			description = "Mighty Blade ultimate"
		},
		gladiator = {
			action = function() return GladiatorActions.demonicvorpaldance() end,
			name = "[Z] Demonic Vorpal Dance",
			description = "Demonic Vorpal Dance ultimate"
		},
		brawler = {
			action = function() return BrawlerActions.meteordive() end,
			name = "[Z] Meteor Dive",
			description = "Meteor Dive ultimate"
		}
	},
	
	-- Aim Controls (Archer only)
	aim_mode_toggle = {
		archer = {
			action = function() return ArcherActions.cycleAimMode() end,
			name = "[T] Aim Mode",
			description = "Toggle aim mode (Always/Never/Dynamic)",
			isDynamic = true -- Flag to indicate this button needs dynamic text updates
		}
	},
	
	dynamic_aim_trigger = {
		archer = {
			start = function() return ArcherActions.dynamicAimStart() end,
			stop = function() return ArcherActions.dynamicAimEnd() end,
			isHoldButton = true,
			name = "[F] Aim",
			description = "Hold to aim (Dynamic mode only)"
		}
	}
}

-- ========================================
-- CLASS DETECTION
-- ========================================

local function detectCurrentClass()
	local character = player.Character
	if not character then return nil end
	
	-- Check for samurai weapon
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and CollectionService:HasTag(item, "samurai_wpn") then
			return "samurai"
		end
	end
	
	-- Check for archer weapon
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and CollectionService:HasTag(item, "archer_wpn") then
			return "archer"
		end
	end
	
	-- Check for knight weapon
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and CollectionService:HasTag(item, "knight_wpn") then
			return "knight"
		end
	end
	
	-- Check for gladiator weapon
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and CollectionService:HasTag(item, "gladiator_wpn") then
			return "gladiator"
		end
	end
	
	-- Check for brawler weapon
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and CollectionService:HasTag(item, "brawler_wpn") then
			return "brawler"
		end
	end
	
	return nil
end

local function isWeaponEquipped()
	return SamuraiActions.isWeaponEquipped() or ArcherActions.isWeaponEquipped() or KnightActions.isWeaponEquipped() or GladiatorActions.isWeaponEquipped() or BrawlerActions.isWeaponEquipped()
end

-- ========================================
-- BUTTON SETUP FUNCTIONS
-- ========================================

-- Setup a regular button that adapts to current class
local function setupUnifiedButton(button, tag)
	local tagConfig = UNIFIED_TAGS[tag]
	
	if not tagConfig then
		warn("Unknown unified tag:", tag)
		return
	end
	
	-- Click handler
	button.MouseButton1Click:Connect(function()
		local class = detectCurrentClass()
		
		-- For global actions, try both classes if no weapon equipped
		if not class then
			-- Try to find any class config that has this as a global action
			for className, classConfig in pairs(tagConfig) do
				if classConfig and classConfig.isGlobal and classConfig.action then
					classConfig.action()
					return
				end
			end
			return
		end
		
		local classConfig = tagConfig[class]
		if not classConfig or not classConfig.action then return end
		
		classConfig.action()
	end)
	
	-- Transparency updater
	task.spawn(function()
		while button and button.Parent do
			local class = detectCurrentClass()
			local classConfig = tagConfig[class]
			
			-- Check if this is a global action (works without weapon)
			local isGlobalAction = false
			for _, config in pairs(tagConfig) do
				if config and config.isGlobal then
					isGlobalAction = true
					break
				end
			end
			
			-- Show button if: (weapon equipped AND has class config) OR (is global action)
			if (isWeaponEquipped() and classConfig) or isGlobalAction then
				button.TextTransparency = 0
				button.BackgroundTransparency = 0
			else
				button.TextTransparency = 1
				button.BackgroundTransparency = 1
			end
			task.wait(0.5)
		end
	end)
	
	-- Text updater (updates based on equipped weapon)
	task.spawn(function()
		while button and button.Parent do
			local class = detectCurrentClass()
			if class then
				local classConfig = tagConfig[class]
				if classConfig then
					-- Special handling for dynamic aim mode toggle button
					if classConfig.isDynamic and class == "archer" then
						local currentMode = ArcherActions.getCurrentAimMode()
						local modeText = ""
						if currentMode == true then
							modeText = "Always On"
						elseif currentMode == false then
							modeText = "Always Off"
						elseif currentMode == "dynamic" then
							modeText = "Dynamic"
						end
						button.Text = "[T] " .. modeText
					else
						-- Update button text to show current class's skill name
						button.Text = classConfig.name or "???"
					end
				end
			else
				-- No weapon equipped - check if this is a global action
				local globalConfig = nil
				for _, config in pairs(tagConfig) do
					if config and config.isGlobal then
						globalConfig = config
						break
					end
				end
				
				if globalConfig then
					button.Text = globalConfig.name or "???"
				else
					button.Text = "---"
				end
			end
			task.wait(0.5)
		end
	end)
	
	print("✅ Setup unified button:", button.Name, "with tag:", tag)
end

-- Setup a hold button that adapts to current class
local function setupUnifiedHoldButton(button, tag)
	local tagConfig = UNIFIED_TAGS[tag]
	
	if not tagConfig then
		warn("Unknown unified tag:", tag)
		return
	end
	
	local isActive = false
	
	-- Press handler
	button.MouseButton1Down:Connect(function()
		if not isActive then
			local class = detectCurrentClass()
			if not class then return end
			
			local classConfig = tagConfig[class]
			if not classConfig or not classConfig.start then return end
			
			classConfig.start()
			isActive = true
			button.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		end
	end)
	
	-- Release handler
	button.MouseButton1Up:Connect(function()
		if isActive then
			local class = detectCurrentClass()
			if not class then return end
			
			local classConfig = tagConfig[class]
			if not classConfig or not classConfig.stop then return end
			
			classConfig.stop()
			isActive = false
			button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	-- Handle case where mouse leaves button while holding
	button.MouseLeave:Connect(function()
		if isActive then
			local class = detectCurrentClass()
			if class then
				local classConfig = tagConfig[class]
				if classConfig and classConfig.stop then
					classConfig.stop()
				end
			end
			isActive = false
			button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	-- Transparency updater
	task.spawn(function()
		while button and button.Parent do
			local class = detectCurrentClass()
			local classConfig = tagConfig[class]
			
			-- Only show button if weapon is equipped AND class has config for this button
			if isWeaponEquipped() and classConfig then
				button.TextTransparency = 0
				if not isActive then
					button.BackgroundTransparency = 0
				end
			else
				button.TextTransparency = 1
				button.BackgroundTransparency = 1
			end
			task.wait(0.5)
		end
	end)
	
	-- Text updater
	task.spawn(function()
		while button and button.Parent do
			local class = detectCurrentClass()
			if class then
				local classConfig = tagConfig[class]
				if classConfig then
					-- Special handling for dynamic aim mode toggle button
					if classConfig.isDynamic and class == "archer" then
						local currentMode = ArcherActions.getCurrentAimMode()
						local modeText = ""
						if currentMode == true then
							modeText = "Always On"
						elseif currentMode == false then
							modeText = "Always Off"
						elseif currentMode == "dynamic" then
							modeText = "Dynamic"
						end
						button.Text = "[T] " .. modeText
					else
						button.Text = classConfig.name or "???"
					end
				end
			else
				button.Text = "---"
			end
			task.wait(0.5)
		end
	end)
	
	print("✅ Setup unified hold button:", button.Name, "with tag:", tag)
end

-- Setup a button based on its tag
local function setupButton(button, tag)
	local tagConfig = UNIFIED_TAGS[tag]
	
	if not tagConfig then
		warn("Unknown button tag:", tag)
		return
	end
	
	-- Check if this is a hold button by checking if first class config has start/stop
	local firstClass = next(tagConfig)
	if firstClass and tagConfig[firstClass].isHoldButton then
		setupUnifiedHoldButton(button, tag)
	else
		setupUnifiedButton(button, tag)
	end
end

-- ========================================
-- INITIALIZE ALL BUTTONS
-- ========================================

local function initializeButtons()
	-- Find and setup all buttons with unified tags
	for tag, _ in pairs(UNIFIED_TAGS) do
		-- Get all instances with this tag
		local taggedButtons = CollectionService:GetTagged(tag)
		
		for _, button in ipairs(taggedButtons) do
			if button:IsA("GuiButton") then
				setupButton(button, tag)
			end
		end
		
		-- Listen for new buttons being added with this tag
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(button)
			if button:IsA("GuiButton") then
				setupButton(button, tag)
			end
		end)
	end
	
	print("🎮 Unified Button Manager initialized!")
	print("Buttons will automatically adapt based on equipped weapon")
end

-- ========================================
-- START
-- ========================================

-- Initialize when script runs
initializeButtons()

