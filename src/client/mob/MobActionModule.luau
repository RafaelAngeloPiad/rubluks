local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local actionEvent = ReplicatedStorage:WaitForChild("ActionEvent")

local PLAYER_TAG = "player_transformed"

local MobActions = {}

local function isPlayerTransformed()
	local character = player.Character
	return character and CollectionService:HasTag(character, PLAYER_TAG) or false
end

function MobActions.basicAttack()
	if not isPlayerTransformed() then
		return false, "Not transformed"
	end

	actionEvent:FireServer("mob_manual_attack")
	return true
end

function MobActions.blockStart()
	return false
end

function MobActions.blockEnd()
	return false
end

function MobActions.isWeaponEquipped()
	return isPlayerTransformed()
end

function MobActions.isSkillOnCooldown()
	return false
end

function MobActions.getCooldownRemaining()
	return 0
end

return MobActions


