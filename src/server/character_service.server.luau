-- -- Character DataStore service
-- -- Handles saving and loading character data

-- local Players = game:GetService("Players")
-- local DataStoreService = game:GetService("DataStoreService")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local RunService = game:GetService("RunService")

-- local CharacterData = require(ReplicatedStorage.Shared.character_data)

-- -- Create DataStore
-- local characterStore = DataStoreService:GetDataStore("CharacterData")

-- -- Remote events
-- local remoteEvents = Instance.new("Folder")
-- remoteEvents.Name = "CharacterEvents"
-- remoteEvents.Parent = ReplicatedStorage

-- local loadCharacterEvent = Instance.new("RemoteEvent")
-- loadCharacterEvent.Name = "LoadCharacter"
-- loadCharacterEvent.Parent = remoteEvents

-- local saveCharacterEvent = Instance.new("RemoteEvent")
-- saveCharacterEvent.Name = "SaveCharacter"
-- saveCharacterEvent.Parent = remoteEvents

-- local getCharacterDataEvent = Instance.new("RemoteEvent")
-- getCharacterDataEvent.Name = "GetCharacterData"
-- getCharacterDataEvent.Parent = remoteEvents

-- -- Store character data in memory for quick access
-- local playerCharacters = {}

-- -- Character service
-- local CharacterService = {}

-- -- Load character slots for a player
-- function CharacterService.loadCharacterSlots(player)
-- 	local success, data = pcall(function()
-- 		return characterStore:GetAsync(player.UserId)
-- 	end)
	
-- 	if success and data then
-- 		playerCharacters[player.UserId] = data
-- 		print("Loaded character slots for", player.Name)
-- 		return data
-- 	else
-- 		-- Create empty character slots if none exist
-- 		local characterSlots = {
-- 			CharacterData.createEmptySlot(1),
-- 			CharacterData.createEmptySlot(2),
-- 			CharacterData.createEmptySlot(3)
-- 		}
-- 		playerCharacters[player.UserId] = characterSlots
		
-- 		CharacterService.saveCharacterSlots(player, characterSlots)
		
-- 		print("Created empty character slots for", player.Name)
-- 		return characterSlots
-- 	end
-- end

-- -- Save character slots for a player
-- function CharacterService.saveCharacterSlots(player, characterSlots)
-- 	playerCharacters[player.UserId] = characterSlots
	
-- 	local success, errorMessage = pcall(function()
-- 		characterStore:SetAsync(player.UserId, characterSlots)
-- 	end)
	
-- 	if success then
-- 		print("Saved character slots for", player.Name)
-- 		return true
-- 	else
-- 		warn("Failed to save character slots for", player.Name, ":", errorMessage)
-- 		return false
-- 	end
-- end

-- -- Get character slots for a player
-- function CharacterService.getCharacterSlots(player)
-- 	return playerCharacters[player.UserId]
-- end

-- -- Create character in specific slot
-- function CharacterService.createCharacterInSlot(player, slotIndex, className)
-- 	local characterSlots = playerCharacters[player.UserId]
-- 	if not characterSlots then
-- 		characterSlots = CharacterService.loadCharacterSlots(player)
-- 	end
	
-- 	-- Check if slot is valid
-- 	if slotIndex < 1 or slotIndex > 3 then
-- 		error("Invalid slot index: " .. tostring(slotIndex))
-- 	end
	
-- 	-- Create character in slot
-- 	local newCharacter = CharacterData.createCharacter(slotIndex, className)
-- 	characterSlots[slotIndex] = newCharacter
	
-- 	CharacterService.saveCharacterSlots(player, characterSlots)
-- 	print("Created", className, "in slot", slotIndex, "for", player.Name)
	
-- 	return newCharacter
-- end

-- -- Delete character from slot
-- function CharacterService.deleteCharacterFromSlot(player, slotIndex)
-- 	local characterSlots = playerCharacters[player.UserId]
-- 	if not characterSlots then
-- 		characterSlots = CharacterService.loadCharacterSlots(player)
-- 	end
	
-- 	-- Check if slot is valid
-- 	if slotIndex < 1 or slotIndex > 3 then
-- 		error("Invalid slot index: " .. tostring(slotIndex))
-- 	end
	
-- 	-- Clear slot
-- 	characterSlots[slotIndex] = CharacterData.createEmptySlot(slotIndex)
	
-- 	CharacterService.saveCharacterSlots(player, characterSlots)
-- 	print("Deleted character from slot", slotIndex, "for", player.Name)
	
-- 	return characterSlots[slotIndex]
-- end

-- -- Handle player joining
-- local function onPlayerAdded(player)
-- 	-- Load character slots when player joins
-- 	CharacterService.loadCharacterSlots(player)
-- end

-- -- Handle player leaving
-- local function onPlayerRemoving(player)
-- 	-- Save character slots when player leaves
-- 	local characterSlots = playerCharacters[player.UserId]
-- 	if characterSlots then
-- 		CharacterService.saveCharacterSlots(player, characterSlots)
-- 		playerCharacters[player.UserId] = nil
-- 	end
-- end

-- -- Remote event handlers
-- loadCharacterEvent.OnServerEvent:Connect(function(player)
-- 	local characterSlots = CharacterService.loadCharacterSlots(player)
-- 	loadCharacterEvent:FireClient(player, characterSlots)
-- end)

-- saveCharacterEvent.OnServerEvent:Connect(function(player, characterSlots)
-- 	CharacterService.saveCharacterSlots(player, characterSlots)
-- end)

-- getCharacterDataEvent.OnServerEvent:Connect(function(player)
-- 	local characterSlots = CharacterService.getCharacterSlots(player)
-- 	getCharacterDataEvent:FireClient(player, characterSlots)
-- end)

-- -- Connect events
-- Players.PlayerAdded:Connect(onPlayerAdded)
-- Players.PlayerRemoving:Connect(onPlayerRemoving)

-- -- Auto-save every 30 seconds
-- RunService.Heartbeat:Connect(function()
-- 	local currentTime = tick()
-- 	if not CharacterService.lastSaveTime then
-- 		CharacterService.lastSaveTime = currentTime
-- 	end
	
-- 	if currentTime - CharacterService.lastSaveTime >= 30 then
-- 		for _, player in pairs(Players:GetPlayers()) do
-- 			local characterSlots = playerCharacters[player.UserId]
-- 			if characterSlots then
-- 				CharacterService.saveCharacterSlots(player, characterSlots)
-- 			end
-- 		end
-- 		CharacterService.lastSaveTime = currentTime
-- 	end
-- end)

-- return CharacterService
