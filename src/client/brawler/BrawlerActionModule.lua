-- ========================================
-- BRAWLER ACTION MODULE
-- Provides public API for triggering brawler actions
-- Can be called from GUI buttons or keyboard inputs
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Module exports
local BrawlerActions = {}

-- ========================================
-- SKILL ENABLE/DISABLE CONFIG
-- Set to false to completely disable a skill (won't fire to server even if spammed)
-- ========================================
local SKILLS_ENABLED = {
	feralleap = true,
	brawlersroar = true,
	bloodthirst = true,
	lastchance = true,
	meteordive = true,
}

-- Internal state
local tool = nil
local inputLocked = false
local movementLocked = false
local onCooldown = {} -- Track which skills are on cooldown

-- ========================================
-- STATE MANAGEMENT (Internal)
-- ========================================

function BrawlerActions._setTool(newTool)
	tool = newTool
end

function BrawlerActions._setInputLocked(locked)
	inputLocked = locked
end

function BrawlerActions._setMovementLocked(locked)
	movementLocked = locked
end

function BrawlerActions._setCooldown(skillName, isOnCooldown)
	onCooldown[skillName] = isOnCooldown
end

function BrawlerActions._getTool()
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

function BrawlerActions.basicAttack()
	local success, reason = canPerformAction("attack")
	if not success then
		return false, reason
	end

	remote:FireServer("brawler_left_click_attack")
	return true
end

function BrawlerActions.jumpAttack()
	local success, reason = canPerformAction("jump")
	if not success then
		return false, reason
	end

	remote:FireServer("brawler_jump_attack")
	return true
end

function BrawlerActions.wave()
	local success, reason = canPerformAction("wave")
	if not success then
		return false, reason
	end

	remote:FireServer("brawler_wave")
	return true
end

function BrawlerActions.blockStart()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end

	remote:FireServer("brawler_block_start")
	return true
end

function BrawlerActions.blockEnd()
	local success, reason = canPerformAction("block")
	if not success then
		return false, reason
	end

	remote:FireServer("brawler_block_end")
	return true
end

-- ========================================
-- PUBLIC API - Skills
-- ========================================

function BrawlerActions.useSkill(skillName)
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
function BrawlerActions.brawlersroar()
	return BrawlerActions.useSkill("brawlersroar")
end

function BrawlerActions.feralleap()
	return BrawlerActions.useSkill("feralleap")
end

-- ========================================
-- PUBLIC API - Buffs
-- ========================================

function BrawlerActions.bloodthirst()
	return BrawlerActions.useSkill("bloodthirst")
end

function BrawlerActions.lastchance()
	return BrawlerActions.useSkill("lastchance")
end

-- ========================================
-- PUBLIC API - Ultimate
-- ========================================

function BrawlerActions.meteordive()
	return BrawlerActions.useSkill("meteordive")
end

-- ========================================
-- PUBLIC API - Utility
-- ========================================

function BrawlerActions.isInputLocked()
	return inputLocked
end

function BrawlerActions.isMovementLocked()
	return movementLocked
end

function BrawlerActions.isSkillOnCooldown(skillName)
	return onCooldown[skillName] or false
end

function BrawlerActions.isWeaponEquipped()
	return tool ~= nil and tool.Parent == player.Character
end

return BrawlerActions

