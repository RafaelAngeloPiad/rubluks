-- ========================================
-- KNIGHT ACTION MODULE
-- Provides public API for triggering knight actions
-- Can be called from GUI buttons or keyboard inputs
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Module exports
local KnightActions = {}

-- ========================================
-- SKILL ENABLE/DISABLE CONFIG
-- Set to false to completely disable a skill (won't fire to server even if spammed)
-- ========================================
local SKILLS_ENABLED = {
	sworddance = true,
	cyclone_slash = false,
	warcry = false,
	warriormight = true,
	mightyblade = false,
}

-- Internal state
local tool = nil
local inputLocked = false
local movementLocked = false
local onCooldown = {} -- Track which skills are on cooldown

-- ========================================
-- STATE MANAGEMENT (Internal)
-- ========================================

function KnightActions._setTool(newTool)
	tool = newTool
end

function KnightActions._setInputLocked(locked)
	inputLocked = locked
end

function KnightActions._setMovementLocked(locked)
	movementLocked = locked
end

function KnightActions._setCooldown(skillName, isOnCooldown)
	onCooldown[skillName] = isOnCooldown
end

function KnightActions._getTool()
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

function KnightActions.basicAttack()
	local success, reason = canPerformAction("attack")
	if not success then
		return false, reason
	end
	
	remote:FireServer("knight_left_click_attack")
	return true
end

function KnightActions.jumpAttack()
	local success, reason = canPerformAction("jump")
	if not success then
		return false, reason
	end
	
	remote:FireServer("knight_jump_attack")
	return true
end

function KnightActions.wave()
	local success, reason = canPerformAction("wave")
	if not success then
		return false, reason
	end
	
	remote:FireServer("knight_wave")
	return true
end

function KnightActions.blockStart()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("knight_block_start")
	return true
end

function KnightActions.blockEnd()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("knight_block_end")
	return true
end

-- ========================================
-- PUBLIC API - Skills
-- ========================================

function KnightActions.useSkill(skillName)
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

-- Convenience functions for each skill
function KnightActions.sworddance()
	return KnightActions.useSkill("sworddance")
end

function KnightActions.cyclone_slash()
	return KnightActions.useSkill("cyclone_slash")
end

-- ========================================
-- PUBLIC API - Buffs
-- ========================================

function KnightActions.warcry()
	return KnightActions.useSkill("warcry")
end

function KnightActions.warriormight()
	return KnightActions.useSkill("warriormight")
end

-- ========================================
-- PUBLIC API - Ultimate
-- ========================================

function KnightActions.mightyblade()
	return KnightActions.useSkill("mightyblade")
end

-- ========================================
-- PUBLIC API - Utility
-- ========================================

function KnightActions.isInputLocked()
	return inputLocked
end

function KnightActions.isMovementLocked()
	return movementLocked
end

function KnightActions.isSkillOnCooldown(skillName)
	return onCooldown[skillName] or false
end

function KnightActions.isWeaponEquipped()
	return tool ~= nil and tool.Parent == player.Character
end

return KnightActions

