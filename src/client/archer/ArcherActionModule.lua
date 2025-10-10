-- ========================================
-- ARCHER ACTION MODULE
-- Provides public API for triggering archer actions
-- Can be called from GUI buttons or keyboard inputs
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ActionEvent")
local camera = workspace.CurrentCamera

-- Module exports
local ArcherActions = {}

-- ========================================
-- SKILL ENABLE/DISABLE CONFIG
-- Set to false to completely disable a skill (won't fire to server even if spammed)
-- ========================================
local SKILLS_ENABLED = {
	piercingShot = true,
	powerShot = true,
	hunterInstinct = true,
	hunterMark = true,
	starfall = true,
}

-- Internal state
local tool = nil
local inputLocked = false
local movementLocked = false
local onCooldown = {} -- Track which skills are on cooldown
local aimLockEnabled = false
local isFirstPerson = false

-- Aim control callbacks (set by main client script)
local cycleAimModeCallback = nil
local dynamicAimStartCallback = nil
local dynamicAimEndCallback = nil
local getCurrentAimModeCallback = nil

-- ========================================
-- STATE MANAGEMENT (Internal)
-- ========================================

function ArcherActions._setTool(newTool)
	tool = newTool
end

function ArcherActions._setInputLocked(locked)
	inputLocked = locked
end

function ArcherActions._setMovementLocked(locked)
	movementLocked = locked
end

function ArcherActions._setCooldown(skillName, isOnCooldown)
	onCooldown[skillName] = isOnCooldown
end

function ArcherActions._setAimLockEnabled(enabled)
	aimLockEnabled = enabled
end

function ArcherActions._setFirstPerson(firstPerson)
	isFirstPerson = firstPerson
end

function ArcherActions._getTool()
	return tool
end

function ArcherActions._registerAimCallbacks(cycleMode, dynamicStart, dynamicEnd, getCurrentMode)
	cycleAimModeCallback = cycleMode
	dynamicAimStartCallback = dynamicStart
	dynamicAimEndCallback = dynamicEnd
	getCurrentAimModeCallback = getCurrentMode
end

-- ========================================
-- VALIDATION (Internal)
-- ========================================

local function canPerformAction(actionType)
	-- Check if input is locked
	if inputLocked then
		return false, "Input is locked"
	end
	
	-- Check if tool is equipped
	if not tool or tool.Parent ~= player.Character then
		return false, "Weapon not equipped"
	end
	
	-- For movement-dependent actions (attacks, block, jump, wave), check if movement is locked
	if movementLocked and actionType ~= "skill" then
		return false, "Movement is locked"
	end
	
	return true
end

-- ========================================
-- PUBLIC API - Basic Actions
-- ========================================

function ArcherActions.basicAttack()
	local success, reason = canPerformAction("attack")
	if not success then
		return false, reason
	end
	
	-- Send camera direction, aim lock state, and first-person state for aiming
	local cameraDirection = camera.CFrame.LookVector
	remote:FireServer("archer_left_click_attack", cameraDirection, aimLockEnabled, isFirstPerson)
	return true
end

function ArcherActions.jumpAttack()
	local success, reason = canPerformAction("jump")
	if not success then
		return false, reason
	end
	
	remote:FireServer("archer_jump_attack")
	return true
end

function ArcherActions.wave()
	local success, reason = canPerformAction("wave")
	if not success then
		return false, reason
	end
	
	remote:FireServer("archer_wave")
	return true
end

function ArcherActions.blockStart()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("archer_block_start")
	return true
end

function ArcherActions.blockEnd()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("archer_block_end")
	return true
end

-- ========================================
-- PUBLIC API - Skills (with camera direction)
-- ========================================

function ArcherActions.useSkill(skillName)
	local success, reason = canPerformAction("skill")
	if not success then
		return false, reason
	end
	
	-- Check if skill is disabled in config
	if SKILLS_ENABLED[skillName] == false then
		return false, "Skill is disabled"
	end
	
	-- Note: We don't block based on cooldown here - let the SERVER decide
	-- The client-side cooldown tracking is only for UI feedback
	-- The server will handle actual cooldown validation and send status updates back
	
	-- Skills that need camera direction (piercing shot and power shot)
	if skillName == "piercingShot" or skillName == "powerShot" then
		local cameraDirection = camera.CFrame.LookVector
		remote:FireServer(skillName, cameraDirection, aimLockEnabled, isFirstPerson)
	else
		remote:FireServer(skillName)
	end
	
	return true
end

-- Convenience functions for each skill
function ArcherActions.piercingShot()
	return ArcherActions.useSkill("piercingShot")
end

function ArcherActions.powerShot()
	return ArcherActions.useSkill("powerShot")
end

-- ========================================
-- PUBLIC API - Buffs
-- ========================================

function ArcherActions.hunterInstinct()
	return ArcherActions.useSkill("hunterInstinct")
end

function ArcherActions.hunterMark()
	return ArcherActions.useSkill("hunterMark")
end

-- ========================================
-- PUBLIC API - Ultimate
-- ========================================

function ArcherActions.starfall()
	return ArcherActions.useSkill("starfall")
end

-- ========================================
-- PUBLIC API - Utility
-- ========================================

function ArcherActions.isInputLocked()
	return inputLocked
end

function ArcherActions.isMovementLocked()
	return movementLocked
end

function ArcherActions.isSkillOnCooldown(skillName)
	return onCooldown[skillName] or false
end

function ArcherActions.isWeaponEquipped()
	return tool ~= nil and tool.Parent == player.Character
end

function ArcherActions.getAimLockEnabled()
	return aimLockEnabled
end

function ArcherActions.getFirstPerson()
	return isFirstPerson
end

-- ========================================
-- PUBLIC API - Aim Controls (Archer Only)
-- ========================================

function ArcherActions.cycleAimMode()
	if not tool or tool.Parent ~= player.Character then
		return false, "Weapon not equipped"
	end
	
	if cycleAimModeCallback then
		cycleAimModeCallback()
		return true
	end
	return false, "Aim mode callback not registered"
end

function ArcherActions.dynamicAimStart()
	if not tool or tool.Parent ~= player.Character then
		return false, "Weapon not equipped"
	end
	
	if dynamicAimStartCallback then
		dynamicAimStartCallback()
		return true
	end
	return false, "Dynamic aim callback not registered"
end

function ArcherActions.dynamicAimEnd()
	if not tool or tool.Parent ~= player.Character then
		return false, "Weapon not equipped"
	end
	
	if dynamicAimEndCallback then
		dynamicAimEndCallback()
		return true
	end
	return false, "Dynamic aim callback not registered"
end

function ArcherActions.getCurrentAimMode()
	if getCurrentAimModeCallback then
		return getCurrentAimModeCallback()
	end
	return "dynamic" -- Default to dynamic if callback not registered
end

return ArcherActions

