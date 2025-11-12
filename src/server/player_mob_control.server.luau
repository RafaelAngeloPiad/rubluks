local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local PLAYER_TAG = "player_transformed"
local ATTACK_ATTRIBUTE = "PlayerAttackRequest"

local actionEvent = ReplicatedStorage:FindFirstChild("ActionEvent")

if not actionEvent or not actionEvent:IsA("RemoteEvent") then
	warn("[PlayerMobControl] ActionEvent RemoteEvent not found. Manual mob control disabled.")
	return
end

local function isPlayerControllingMob(player: Player): (Model?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end

	if not CollectionService:HasTag(character, PLAYER_TAG) then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end

	return character, humanoid
end

local function requestAttack(player: Player)
	local _, humanoid = isPlayerControllingMob(player)
	if not humanoid then
		return
	end

	-- Toggle attribute so AI modules can react to edge
	humanoid:SetAttribute(ATTACK_ATTRIBUTE, true)
	task.delay(0.5, function()
		if humanoid and humanoid.Parent and humanoid:GetAttribute(ATTACK_ATTRIBUTE) then
			humanoid:SetAttribute(ATTACK_ATTRIBUTE, false)
		end
	end)
end

actionEvent.OnServerEvent:Connect(function(player: Player, actionName, ...)
	if typeof(actionName) ~= "string" then
		return
	end

	local lowered = string.lower(actionName)
	if lowered == "mob_manual_attack" then
		requestAttack(player)
	end
end)


