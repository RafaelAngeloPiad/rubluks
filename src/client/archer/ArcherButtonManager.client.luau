-- ========================================
-- ARCHER BUTTON MANAGER
-- Single script that manages all archer action buttons
-- Place this in StarterGui > ActionsGUI (or StarterPlayerScripts)
-- Tag your buttons with CollectionService tags to connect them
-- ========================================

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local ArcherActions = require(player.PlayerScripts.archer.ArcherActionModule)

-- ========================================
-- BUTTON TAG CONFIGURATION
-- Map CollectionService tags to their action functions
-- ========================================

local BUTTON_TAGS = {
	-- Combat actions
	archer_attack_trigger = function() return ArcherActions.basicAttack() end,
	archer_block_trigger = {
		start = function() return ArcherActions.blockStart() end,
		stop = function() return ArcherActions.blockEnd() end,
		isHoldButton = true -- Special handling for block (press/release)
	},
	archer_wave_trigger = function() return ArcherActions.wave() end,
	
	-- Skills (Q & E)
	archer_piercingshot_trigger = function() return ArcherActions.piercingShot() end,
	archer_powershot_trigger = function() return ArcherActions.powerShot() end,
	
	-- Buffs (X & C)
	archer_hunterinstinct_trigger = function() return ArcherActions.hunterInstinct() end,
	archer_huntermark_trigger = function() return ArcherActions.hunterMark() end,
	
	-- Ultimate (Z)
	archer_starfall_trigger = function() return ArcherActions.starfall() end,
}

-- ========================================
-- BUTTON SETUP FUNCTIONS
-- ========================================

-- Setup a regular button (click once to activate)
local function setupRegularButton(button, actionFunc)
	-- Click handler
	button.MouseButton1Click:Connect(function()
		actionFunc()
	end)
	
	-- Transparency updater
	task.spawn(function()
		while button and button.Parent do
			if ArcherActions.isWeaponEquipped() then
				button.TextTransparency = 0
				button.BackgroundTransparency = 0
			else
				button.TextTransparency = 1
				button.BackgroundTransparency = 1
			end
			task.wait(0.5)
		end
	end)
end

-- Setup a hold button (press and release, like block)
local function setupHoldButton(button, actionConfig)
	local isActive = false
	
	-- Press handler
	button.MouseButton1Down:Connect(function()
		if not isActive then
			actionConfig.start()
			isActive = true
			-- Visual feedback: change button color while active
			button.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		end
	end)
	
	-- Release handler
	button.MouseButton1Up:Connect(function()
		if isActive then
			actionConfig.stop()
			isActive = false
			-- Reset button color
			button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	-- Handle case where mouse leaves button while holding
	button.MouseLeave:Connect(function()
		if isActive then
			actionConfig.stop()
			isActive = false
			button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	-- Transparency updater
	task.spawn(function()
		while button and button.Parent do
			if ArcherActions.isWeaponEquipped() then
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
end

-- Setup a button based on its tag
local function setupButton(button, tag)
	local actionConfig = BUTTON_TAGS[tag]
	
	if not actionConfig then
		warn("Unknown button tag:", tag)
		return
	end
	
	-- Check if this is a hold button (like block)
	if type(actionConfig) == "table" and actionConfig.isHoldButton then
		setupHoldButton(button, actionConfig)
		print("✅ Setup hold button:", button.Name, "with tag:", tag)
	else
		-- Regular button
		setupRegularButton(button, actionConfig)
		print("✅ Setup button:", button.Name, "with tag:", tag)
	end
end

-- ========================================
-- INITIALIZE ALL BUTTONS
-- ========================================

local function initializeButtons()
	-- Find and setup all buttons with archer tags
	for tag, _ in pairs(BUTTON_TAGS) do
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
	
	print("🏹 Archer Button Manager initialized!")
end

-- ========================================
-- START
-- ========================================

-- Initialize when script runs
initializeButtons()

