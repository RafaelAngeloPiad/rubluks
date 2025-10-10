-- ========================================
-- UNIFIED BUTTON MANAGER
-- Single button system that works for ALL classes
-- Buttons automatically switch based on equipped weapon
-- Place this in StarterGui > ActionsGUI
-- ========================================

-- Tag	Purpose	Samurai	Archer
-- attack_trigger	Basic attack	Attack	Attack
-- skill1_trigger	First skill	Wakizashi	Piercing Shot
-- skill2_trigger	Second skill	Kozuki	Power Shot
-- buff1_trigger	First buff	Banzai	Hunter Instinct
-- buff2_trigger	Second buff	Bushido	Hunter Mark
-- ultimate_trigger	Ultimate	Zantetsuken	Starfall
-- block_trigger	Block	Block	Block
-- wave_trigger	Wave	Wave	Wave
-- aim_mode_toggle	Aim mode toggle	(none)	Toggle Aim Mode
-- dynamic_aim_trigger	Dynamic aim (hold)	(none)	Hold to Aim

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

-- Require both action modules
local SamuraiActions = require(player.PlayerScripts.samurai.SamuraiActionModule)
local ArcherActions = require(player.PlayerScripts.archer.ArcherActionModule)

-- Track current class
local currentClass = nil -- "samurai" or "archer"
local classCheckConnection = nil

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
			name = "Attack",
			description = "Basic attack (auto-detects: normal, move, or jump attack)"
		},
		archer = {
			action = function() return ArcherActions.basicAttack() end,
			name = "Attack",
			description = "Basic attack with aim"
		}
	},
	
	block_trigger = {
		samurai = {
			start = function() return SamuraiActions.blockStart() end,
			stop = function() return SamuraiActions.blockEnd() end,
			isHoldButton = true,
			name = "Block",
			description = "Hold to block"
		},
		archer = {
			start = function() return ArcherActions.blockStart() end,
			stop = function() return ArcherActions.blockEnd() end,
			isHoldButton = true,
			name = "Block",
			description = "Hold to block"
		}
	},
	
	wave_trigger = {
		samurai = {
			action = function() return SamuraiActions.wave() end,
			name = "Wave",
			description = "Wave emote"
		},
		archer = {
			action = function() return ArcherActions.wave() end,
			name = "Wave",
			description = "Wave emote"
		}
	},
	
	-- Skill 1 (varies by class)
	skill1_trigger = {
		samurai = {
			action = function() return SamuraiActions.wakizashi() end,
			name = "Wakizashi",
			description = "Wakizashi skill"
		},
		archer = {
			action = function() return ArcherActions.piercingShot() end,
			name = "Piercing Shot",
			description = "Piercing Shot skill"
		}
	},
	
	-- Skill 2 (varies by class)
	skill2_trigger = {
		samurai = {
			action = function() return SamuraiActions.kozuki() end,
			name = "Kozuki",
			description = "Kozuki skill"
		},
		archer = {
			action = function() return ArcherActions.powerShot() end,
			name = "Power Shot",
			description = "Power Shot skill"
		}
	},
	
	-- Buff 1 (varies by class)
	buff1_trigger = {
		samurai = {
			action = function() return SamuraiActions.banzai() end,
			name = "Banzai",
			description = "Banzai buff"
		},
		archer = {
			action = function() return ArcherActions.hunterInstinct() end,
			name = "Hunter Instinct",
			description = "Hunter Instinct buff"
		}
	},
	
	-- Buff 2 (varies by class)
	buff2_trigger = {
		samurai = {
			action = function() return SamuraiActions.bushido() end,
			name = "Bushido",
			description = "Bushido buff"
		},
		archer = {
			action = function() return ArcherActions.hunterMark() end,
			name = "Hunter Mark",
			description = "Hunter Mark buff"
		}
	},
	
	-- Ultimate (varies by class)
	ultimate_trigger = {
		samurai = {
			action = function() return SamuraiActions.zantetsuken() end,
			name = "Zantetsuken",
			description = "Zantetsuken ultimate"
		},
		archer = {
			action = function() return ArcherActions.starfall() end,
			name = "Starfall",
			description = "Starfall ultimate"
		}
	},
	
	-- Aim Controls (Archer only)
	aim_mode_toggle = {
		archer = {
			action = function() return ArcherActions.cycleAimMode() end,
			name = "Aim Mode",
			description = "Toggle aim mode (Always/Never/Dynamic)"
		}
	},
	
	dynamic_aim_trigger = {
		archer = {
			start = function() return ArcherActions.dynamicAimStart() end,
			stop = function() return ArcherActions.dynamicAimEnd() end,
			isHoldButton = true,
			name = "Aim",
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
	
	return nil
end

local function isWeaponEquipped()
	return SamuraiActions.isWeaponEquipped() or ArcherActions.isWeaponEquipped()
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
		if not class then return end
		
		local classConfig = tagConfig[class]
		if not classConfig or not classConfig.action then return end
		
		classConfig.action()
	end)
	
	-- Transparency updater
	task.spawn(function()
		while button and button.Parent do
			local class = detectCurrentClass()
			local classConfig = tagConfig[class]
			
			-- Only show button if weapon is equipped AND class has config for this button
			if isWeaponEquipped() and classConfig then
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
					-- Update button text to show current class's skill name
					button.Text = classConfig.name or "???"
				end
			else
				-- No weapon equipped - show generic name
				button.Text = "---"
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
					button.Text = classConfig.name or "???"
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

