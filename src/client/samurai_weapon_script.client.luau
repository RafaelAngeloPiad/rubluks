local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Replace these asset IDs with your actual animation asset IDs
local idleAnimId = "rbxassetid://132322083369838"
local runAnimId = "rbxassetid://80487023516839"
local jumpAnimId = "rbxassetid://121459102540074"
local fallAnimId = jumpAnimId
local climbAnimId = "rbxassetid://91967450916175"

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

local function onCharacterAdded(state, char)
	state.character = char
	state.humanoid = char:FindFirstChildOfClass("Humanoid")
	if not state.humanoid then return end
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
		end)
		state.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			onInputBegan(state, input, gameProcessed)
		end)
		state.inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			onInputEnded(state, input, gameProcessed)
		end)
		playInstantAnimation(state)
	end
end

local function onEquipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = true
	if player.Character then
		onCharacterAdded(state, player.Character)
	end
end

local function onUnequipped(tool)
	local state = weaponScanner:getWeaponState(tool)
	if not state then return end
	state.toolEquipped = false
	disconnectAll(state)
end

local function setupTool(tool, state)
	print("[SAMURAI WEAPON] Setting up tool: " .. tool.Name)
	
	-- Listen for equipped/unequipped
	state.equippedConn = tool.Equipped:Connect(function()
		print("[SAMURAI WEAPON] Tool equipped: " .. tool.Name)
		onEquipped(tool)
	end)
	state.unequippedConn = tool.Unequipped:Connect(function()
		print("[SAMURAI WEAPON] Tool unequipped: " .. tool.Name)
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
	if state.equippedConn then state.equippedConn:Disconnect() end
	if state.unequippedConn then state.unequippedConn:Disconnect() end
	if state.charConn then state.charConn:Disconnect() end
	disconnectAll(state)
end

-- Initialize weapon scanner
print("[SAMURAI WEAPON] Initializing weapon scanner...")
weaponScanner = WeaponScanner.new("samurai_weapon", setupTool, cleanupTool)
print("[SAMURAI WEAPON] Weapon scanner initialized!")

