-- ========================================
-- SAMURAI ACTIONS CLIENT (UNIFIED)
-- Handles skills, buffs, and ultimate for Samurai class
-- Skills: Kozuki (E), Wakizashi (Q)
-- Buffs: Banzai (R), Bushido (F)
-- Ultimate: Zantetsuken (Z)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local tool = nil
local inputConnection = nil

-- Configuration
local CONFIG = {
	weaponTag = "samurai_wpn",
	skills = {
		[Enum.KeyCode.E] = "kozuki",
		[Enum.KeyCode.Q] = "wakizashi",
		[Enum.KeyCode.R] = "banzai",
		[Enum.KeyCode.F] = "bushido",
		[Enum.KeyCode.Z] = "zantetsuken",
	}
}

-- Functions
local function useAction(actionName)
	print("[Actions] Attempting to use action:", actionName)
	
	if not tool or tool.Parent ~= player.Character then
		print("[Actions] Failed - tool not equipped. Tool:", tool, "Parent:", tool and tool.Parent)
		return
	end
	
	print("[Actions] Firing server with action:", actionName)
	-- Fire server - server handles EVERYTHING (VFX + Hitbox for skills, VFX only for buffs)
	local remote = ReplicatedStorage:WaitForChild("ActionEvent")
	remote:FireServer(actionName)
end

local function onWeaponFound(weaponTool)
	tool = weaponTool
	print("[Actions] Weapon found and equipped:", weaponTool.Name)
	
	-- Disconnect existing connection if any
	if inputConnection then
		inputConnection:Disconnect()
	end
	
	inputConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
		if not isProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
			local actionName = CONFIG.skills[input.KeyCode]
			if actionName then
				print("[Actions] Key pressed, mapped to:", actionName)
				useAction(actionName)
			end
		end
	end)
end

local function onCharacterAdded(character)
	for _, weaponTool in character:GetChildren() do
		if weaponTool:IsA("Tool") and CollectionService:HasTag(weaponTool, CONFIG.weaponTag) then
			onWeaponFound(weaponTool)
		end
	end
	
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("Tool") and CollectionService:HasTag(desc, CONFIG.weaponTag) then
			onWeaponFound(desc)
		end
	end)
end

-- Initialize
if player.Character then
	onCharacterAdded(player.Character)
else
	player.CharacterAdded:Connect(onCharacterAdded)
end

