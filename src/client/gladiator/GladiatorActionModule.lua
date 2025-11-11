-- ========================================
-- GLADIATOR ACTION MODULE
-- Provides public API for triggering gladiator actions
-- Can be called from GUI buttons or keyboard inputs
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Module exports
local GladiatorActions = {}

-- ========================================
-- SKILL ENABLE/DISABLE CONFIG
-- Set to false to completely disable a skill (won't fire to server even if spammed)
-- ========================================
local SKILLS_ENABLED = {
	shieldbash = true,
	dragoonjump = true,
	championsblood = true,
	championscheer = true,
	demonicvorpaldance = false,
}

-- Internal state
local tool = nil
local inputLocked = false
local movementLocked = false
local onCooldown = {} -- Track which skills are on cooldown
local cooldownTimers = {} -- Track when each cooldown ends (os.clock timestamp)

-- ========================================
-- STATE MANAGEMENT (Internal)
-- ========================================

function GladiatorActions._setTool(newTool)
	tool = newTool
end

function GladiatorActions._setInputLocked(locked)
	inputLocked = locked
end

function GladiatorActions._setMovementLocked(locked)
	movementLocked = locked
end

function GladiatorActions._setCooldown(skillName, isOnCooldown, remainingTime)
	onCooldown[skillName] = isOnCooldown

	if isOnCooldown then
		if remainingTime and remainingTime > 0 then
			cooldownTimers[skillName] = os.clock() + remainingTime
		elseif not cooldownTimers[skillName] then
			cooldownTimers[skillName] = os.clock()
		end
	else
		cooldownTimers[skillName] = nil
	end
end

function GladiatorActions._getTool()
	return tool
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

function GladiatorActions.basicAttack()
	local success, reason = canPerformAction("attack")
	if not success then
		return false, reason
	end
	
	remote:FireServer("gladiator_left_click_attack")
	return true
end

function GladiatorActions.jumpAttack()
	local success, reason = canPerformAction("jump")
	if not success then
		return false, reason
	end
	
	remote:FireServer("gladiator_jump_attack")
	return true
end

function GladiatorActions.wave()
	local success, reason = canPerformAction("wave")
	if not success then
		return false, reason
	end
	
	remote:FireServer("gladiator_wave")
	return true
end

function GladiatorActions.blockStart()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("gladiator_block_start")
	return true
end

function GladiatorActions.blockEnd()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("gladiator_block_end")
	return true
end

-- ========================================
-- PUBLIC API - Skills
-- ========================================

function GladiatorActions.useSkill(skillName)
	local success, reason = canPerformAction("skill")
	if not success then
		return false, reason
	end
	
	-- Check if skill is disabled in config
	if SKILLS_ENABLED[skillName] == false then
		return false, "Skill is disabled"
	end
	
	-- Note: We don't block based on cooldown here - let the SERVER decide
	-- The client-side cooldown tracking is only for UI feedback (showing "CD" text)
	-- The server will handle actual cooldown validation and send status updates back
	
	remote:FireServer(skillName)
	return true
end

-- Convenience functions for each skill (placeholder for future)
function GladiatorActions.shieldbash()
	return GladiatorActions.useSkill("shieldbash")
end

function GladiatorActions.dragoonjump()
	return GladiatorActions.useSkill("dragoonjump")
end

-- ========================================
-- PUBLIC API - Buffs
-- ========================================

function GladiatorActions.championsblood()
	return GladiatorActions.useSkill("championsblood")
end

function GladiatorActions.championscheer()
	return GladiatorActions.useSkill("championscheer")
end

-- ========================================
-- PUBLIC API - Ultimate
-- ========================================

function GladiatorActions.demonicvorpaldance()
	return GladiatorActions.useSkill("demonicvorpaldance")
end

-- ========================================
-- PUBLIC API - Utility
-- ========================================

function GladiatorActions.isInputLocked()
	return inputLocked
end

function GladiatorActions.isMovementLocked()
	return movementLocked
end

function GladiatorActions.isSkillOnCooldown(skillName)
	if not onCooldown[skillName] then
		return false
	end

	local remaining = GladiatorActions.getCooldownRemaining(skillName)
	return remaining > 0
end

function GladiatorActions.isWeaponEquipped()
	return tool ~= nil and tool.Parent == player.Character
end

-- ========================================
-- PUBLIC API - Cooldown Helpers
-- ========================================

function GladiatorActions.getCooldownRemaining(skillName)
	local endsAt = cooldownTimers[skillName]
	if not endsAt then
		return 0
	end

	local remaining = endsAt - os.clock()
	if remaining <= 0 then
		cooldownTimers[skillName] = nil
		onCooldown[skillName] = false
		return 0
	end

	return remaining
end

return GladiatorActions

