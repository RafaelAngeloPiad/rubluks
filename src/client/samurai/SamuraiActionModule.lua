-- ========================================
-- SAMURAI ACTION MODULE
-- Provides public API for triggering samurai actions
-- Can be called from GUI buttons or keyboard inputs
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Module exports
local SamuraiActions = {}

-- ========================================
-- SKILL ENABLE/DISABLE CONFIG
-- Set to false to completely disable a skill (won't fire to server even if spammed)
-- ========================================
local SKILLS_ENABLED = {
	kozuki = true,
	wakizashi = true,
	banzai = true,
	bushido = true,
	zantetsuken = true,
}

-- Internal state
local tool = nil
local inputLocked = false
local movementLocked = false
local onCooldown = {} -- Track which skills are on cooldown

-- ========================================
-- STATE MANAGEMENT (Internal)
-- ========================================

function SamuraiActions._setTool(newTool)
	tool = newTool
end

function SamuraiActions._setInputLocked(locked)
	inputLocked = locked
end

function SamuraiActions._setMovementLocked(locked)
	movementLocked = locked
end

function SamuraiActions._setCooldown(skillName, isOnCooldown)
	onCooldown[skillName] = isOnCooldown
end

function SamuraiActions._getTool()
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

function SamuraiActions.basicAttack()
	local success, reason = canPerformAction("attack")
	if not success then
		return false, reason
	end
	
	remote:FireServer("samurai_left_click_attack")
	return true
end

function SamuraiActions.jumpAttack()
	local success, reason = canPerformAction("jump")
	if not success then
		return false, reason
	end
	
	remote:FireServer("samurai_jump_attack")
	return true
end

function SamuraiActions.wave()
	local success, reason = canPerformAction("wave")
	if not success then
		return false, reason
	end
	
	remote:FireServer("samurai_wave")
	return true
end

function SamuraiActions.blockStart()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("samurai_block_start")
	return true
end

function SamuraiActions.blockEnd()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end
	
	remote:FireServer("samurai_block_end")
	return true
end

-- ========================================
-- PUBLIC API - Skills
-- ========================================

function SamuraiActions.useSkill(skillName)
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
function SamuraiActions.kozuki()
	return SamuraiActions.useSkill("kozuki")
end

function SamuraiActions.wakizashi()
	return SamuraiActions.useSkill("wakizashi")
end

-- ========================================
-- PUBLIC API - Buffs
-- ========================================

function SamuraiActions.banzai()
	return SamuraiActions.useSkill("banzai")
end

function SamuraiActions.bushido()
	return SamuraiActions.useSkill("bushido")
end

-- ========================================
-- PUBLIC API - Ultimate
-- ========================================

function SamuraiActions.zantetsuken()
	return SamuraiActions.useSkill("zantetsuken")
end

-- ========================================
-- PUBLIC API - Utility
-- ========================================

function SamuraiActions.isInputLocked()
	return inputLocked
end

function SamuraiActions.isMovementLocked()
	return movementLocked
end

function SamuraiActions.isSkillOnCooldown(skillName)
	return onCooldown[skillName] or false
end

function SamuraiActions.isWeaponEquipped()
	return tool ~= nil and tool.Parent == player.Character
end

return SamuraiActions

