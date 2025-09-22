local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.weapon_scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Try to load combo module with error handling
local SamuraiCombo = nil
local comboLoadSuccess, comboError = pcall(function()
    -- Check if combo module exists first
    local comboModule = script.Parent:FindFirstChild("weapon_script_samurai_combo")
    
    if comboModule then
        SamuraiCombo = require(comboModule)
    else
        for _, child in pairs(script.Parent:GetChildren()) do
        end
        error("Combo module not found in script.Parent")
    end
end)
if not comboLoadSuccess then
    warn("[SAMURAI WEAPON] Failed to load combo module:", comboError)
    warn("[SAMURAI WEAPON] Falling back to standard attack system")
end

-- Replace these asset IDs with your actual animation asset IDs
local idleAnimId = "rbxassetid://132322083369838"
local runAnimId = "rbxassetid://80487023516839"
local jumpAnimId = "rbxassetid://121459102540074"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://91967450916175"
local attackAnimId = "rbxassetid://116519685012277" -- Samurai attack animation

-- Track WASD key states
local movementKeys = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.D] = false,
}

-- Store per-tool connections and animation state
local toolStates = {}
local weaponScanner = nil

-- Animation configuration
local animations = {
	idle = idleAnimId,
	run = runAnimId,
	jump = jumpAnimId,
	climb = climbAnimId,
	attack = attackAnimId,
}

-- Use utility functions for common animation logic
local function onStateChanged(state, old, new)
	WeaponUtils.onStateChanged(state, old, new, movementKeys)
end

local function onMove(state)
	WeaponUtils.onMove(state, movementKeys)
end

local function onInputBegan(state, input, gameProcessed)
	WeaponUtils.onInputBegan(state, input, gameProcessed, movementKeys)
end

local function onInputEnded(state, input, gameProcessed)
	WeaponUtils.onInputEnded(state, input, gameProcessed, movementKeys)
end

local function disconnectAll(state)
	WeaponUtils.disconnectAll(state)
end

local function playInstantAnimation(state)
	WeaponUtils.playInstantAnimation(state, movementKeys)
end

local function playAttack(state)
	
	-- Use combo system if available, otherwise fall back to standard attack
	if SamuraiCombo then
		SamuraiCombo.executeComboAttack(state)
	else
		WeaponUtils.playAttackAnimation(state)
	end
end

local function onCharacterAdded(state, char)
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then 
		warn("[SAMURAI WEAPON] No humanoid found in character")
		return 
	end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	WeaponUtils.setupTracks(state, animations)
	disconnectAll(state)

	if state.toolEquipped then
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			onStateChanged(state, old, new)
			
			-- Test if movement animations are working
			if new == Enum.HumanoidStateType.Running then
			elseif new == Enum.HumanoidStateType.RunningNoPhysics then
			elseif new == Enum.HumanoidStateType.Jumping then
			end
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
			-- Only trigger attack animation on left mouse click
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
				playAttack(state)
			end
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		playInstantAnimation(state)
	else
	end
end

local function onEquipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then 
		warn("[SAMURAI WEAPON] No weapon state found for tool:", tool.Name)
		return 
	end
	state.toolEquipped = true
	state.tool = tool
	
	if player.Character then
		onCharacterAdded(state, player.Character)
	else
		warn("[SAMURAI WEAPON] No character found when equipping tool")
	end
end

local function onUnequipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Reset combo if available
	if SamuraiCombo then
		SamuraiCombo.resetCombo()
	end
	
	disconnectAll(state)
	state.tool = nil
end

local function setupTool(tool, state)
	-- Listen for equipped/unequipped
	state.equippedConn = tool.Equipped:Connect(function()
		onEquipped(tool)
	end)
	state.unequippedConn = tool.Unequipped:Connect(function()
		onUnequipped(tool)
	end)

	-- Listen for character added
	state.charConn = player.CharacterAdded:Connect(function(char)
		onCharacterAdded(state, char)
	end)
	if player.Character then
		onCharacterAdded(state, player.Character)
	end
end

local function cleanupTool(tool, state)
	
	-- Reset combo when cleaning up
	if SamuraiCombo then
		SamuraiCombo.resetCombo()
	end
	
	if state.equippedConn then state.equippedConn:Disconnect() end
	if state.unequippedConn then state.unequippedConn:Disconnect() end
	if state.charConn then state.charConn:Disconnect() end
	disconnectAll(state)
end

-- Debug function to test animation system
local function debugAnimationSystem()
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local playingTracks = animator:GetPlayingAnimationTracks()
                for i, track in ipairs(playingTracks) do
                end
            else
                warn("[SAMURAI DEBUG] No animator found")
            end
        else
            warn("[SAMURAI DEBUG] No humanoid found")
        end
    else
        warn("[SAMURAI DEBUG] No character found")
    end
end

-- Make debug function globally accessible
_G.debugSamuraiAnimations = debugAnimationSystem

-- Global debug functions for combo system
if SamuraiCombo then
    _G.debugSamuraiCombo = function()
        return SamuraiCombo.debugComboState()
    end
    
    _G.setSamuraiComboTimeout = function(seconds)
        return SamuraiCombo.setComboTimeout(seconds)
    end
    
    _G.getSamuraiComboTimeout = function()
        return SamuraiCombo.getComboTimeout()
    end
    
    _G.resetSamuraiCombo = function()
        return SamuraiCombo.resetCombo()
    end
    
    _G.setSamuraiAttackDuration = function(attackNumber, seconds)
        return SamuraiCombo.setAttackDuration(attackNumber, seconds)
    end
    
    _G.getSamuraiAttackDurations = function()
        return SamuraiCombo.getAttackDurations()
    end
    
    _G.checkSamuraiHitboxSystem = function()
        return SamuraiCombo.checkHitboxSystem()
    end
    
end

-- Initialize weapon scanner
weaponScanner = WeaponScanner.new("samurai_weapon", setupTool, cleanupTool)

