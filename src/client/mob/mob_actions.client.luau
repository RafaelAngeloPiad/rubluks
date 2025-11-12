local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerConfigs = require(ReplicatedStorage:WaitForChild("SlavkosConfigs"))

local player = Players.LocalPlayer
local actionEvent = ReplicatedStorage:WaitForChild("ActionEvent")

local PLAYER_TAG = "player_transformed"

local function isPlayerTransformed()
	local character = player.Character
	return character and CollectionService:HasTag(character, PLAYER_TAG) or false
end

local function sendAttackRequest()
	actionEvent:FireServer("mob_manual_attack")
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if not isPlayerTransformed() then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sendAttackRequest()
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local attackKey = ServerConfigs.Client and ServerConfigs.Client.Keybinds and ServerConfigs.Client.Keybinds.global and ServerConfigs.Client.Keybinds.global.attack
		if attackKey and input.KeyCode == attackKey then
			sendAttackRequest()
		end
	end
end)


