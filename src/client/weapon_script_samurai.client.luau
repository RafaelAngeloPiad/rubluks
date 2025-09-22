local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.weapon_scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Try to load combo module with error handling
local SamuraiCombo = nil
local comboLoadSuccess, comboError = pcall(function()
    -- Check if combo module exists first
    print("[SAMURAI WEAPON] Checking for combo module...")
    local comboModule = script.Parent:FindFirstChild("weapon_script_samurai_combo")
    
    if comboModule then
        print("[SAMURAI WEAPON] Found combo module:", comboModule.Name, "Type:", comboModule.ClassName)
        SamuraiCombo = require(comboModule)
        print("[SAMURAI WEAPON] ✅ Successfully loaded combo module!")
    else
        print("[SAMURAI WEAPON] Combo module not found, listing all children:")
        for _, child in pairs(script.Parent:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
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
	print("[SAMURAI WEAPON] playAttack called")
	print("[SAMURAI WEAPON] State info - Character:", state.character, "Humanoid:", state.humanoid, "Animator:", state.animator)
	
	-- Use combo system if available, otherwise fall back to standard attack
	if SamuraiCombo then
		print("[SAMURAI WEAPON] Using combo system for attack")
		SamuraiCombo.executeComboAttack(state)
	else
		print("[SAMURAI WEAPON] Using standard attack system")
		print("[SAMURAI WEAPON] Calling WeaponUtils.playAttackAnimation")
		WeaponUtils.playAttackAnimation(state)
		print("[SAMURAI WEAPON] WeaponUtils.playAttackAnimation completed")
	end
end

local function onCharacterAdded(state, char)
	print("[SAMURAI WEAPON] Character added, setting up animations")
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then 
		warn("[SAMURAI WEAPON] No humanoid found in character")
		return 
	end
	state.animator = state.humanoid:FindFirstChildOfClass("Animator")
	if not state.animator then
		print("[SAMURAI WEAPON] Creating new animator")
		state.animator = Instance.new("Animator")
		state.animator.Parent = state.humanoid
	end

	print("[SAMURAI WEAPON] Setting up animation tracks")
	WeaponUtils.setupTracks(state, animations)
	disconnectAll(state)

	if state.toolEquipped then
		print("[SAMURAI WEAPON] Tool is equipped, connecting events")
		
		state.stateConn = state.humanoid.StateChanged:Connect(function(old, new)
			print("[SAMURAI WEAPON] State changed:", old, "->", new)
			onStateChanged(state, old, new)
			
			-- Test if movement animations are working
			if new == Enum.HumanoidStateType.Running then
				print("[SAMURAI WEAPON] ✅ Running animation should be playing")
			elseif new == Enum.HumanoidStateType.RunningNoPhysics then
				print("[SAMURAI WEAPON] ✅ Idle animation should be playing")
			elseif new == Enum.HumanoidStateType.Jumping then
				print("[SAMURAI WEAPON] ✅ Jump animation should be playing")
			end
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
			-- Only trigger attack animation on left mouse click
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
				print("[SAMURAI WEAPON] Attack input detected")
				playAttack(state)
			end
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		print("[SAMURAI WEAPON] Playing instant animation")
		playInstantAnimation(state)
	else
		print("[SAMURAI WEAPON] Tool not equipped, skipping event connections")
	end
end

local function onEquipped(tool)
	print("[SAMURAI WEAPON] Tool equipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then 
		warn("[SAMURAI WEAPON] No weapon state found for tool:", tool.Name)
		return 
	end
	state.toolEquipped = true
	state.tool = tool
	
	if player.Character then
		print("[SAMURAI WEAPON] Character exists, setting up animations")
		onCharacterAdded(state, player.Character)
	else
		warn("[SAMURAI WEAPON] No character found when equipping tool")
	end
end

local function onUnequipped(tool)
	print("[SAMURAI WEAPON] Tool unequipped:", tool.Name)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	
	-- Reset combo if available
	if SamuraiCombo then
		print("[SAMURAI WEAPON] Resetting combo system")
		SamuraiCombo.resetCombo()
	end
	
	print("[SAMURAI WEAPON] Disconnecting all events")
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
	print("[SAMURAI WEAPON] Cleaning up tool:", tool.Name)
	
	-- Reset combo when cleaning up
	if SamuraiCombo then
		print("[SAMURAI WEAPON] Resetting combo system during cleanup")
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
            print("[SAMURAI DEBUG] Character found, humanoid state:", humanoid:GetState())
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                print("[SAMURAI DEBUG] Animator found")
                local playingTracks = animator:GetPlayingAnimationTracks()
                print("[SAMURAI DEBUG] Playing tracks:", #playingTracks)
                for i, track in ipairs(playingTracks) do
                    print("[SAMURAI DEBUG] Track", i, ":", track.Animation.AnimationId)
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
    
    print("[SAMURAI WEAPON] Global combo debug functions available:")
    print("  _G.debugSamuraiCombo() - Show current combo state")
    print("  _G.setSamuraiComboTimeout(seconds) - Change combo timeout")
    print("  _G.getSamuraiComboTimeout() - Get current timeout")
    print("  _G.setSamuraiAttackDuration(1/2/3, seconds) - Change attack duration")
    print("  _G.getSamuraiAttackDurations() - Get current durations")
    print("  _G.checkSamuraiHitboxSystem() - Check hitbox system availability")
    print("  _G.resetSamuraiCombo() - Manually reset combo")
end

-- Initialize weapon scanner
print("[SAMURAI WEAPON] Initializing weapon scanner")
weaponScanner = WeaponScanner.new("samurai_weapon", setupTool, cleanupTool)
print("[SAMURAI WEAPON] Weapon scanner initialized successfully")

