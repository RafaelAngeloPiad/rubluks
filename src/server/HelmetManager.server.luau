local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HelmetConfig = require(ReplicatedStorage:WaitForChild("HelmetConfig"))

local HELMET_TAG = "helmet_entity"

local HelmetEvent = ReplicatedStorage:FindFirstChild("HelmetEvent")
if not HelmetEvent then
	HelmetEvent = Instance.new("RemoteEvent")
	HelmetEvent.Name = "HelmetEvent"
	HelmetEvent.Parent = ReplicatedStorage
end

local HelmetEntries = HelmetConfig.Entries or {}
local HelmetAssetLookup = HelmetConfig.AssetLookup or {}
local HelmetCanonicalLookup = HelmetConfig.CanonicalLookup or {}

-- Runtime helmet slot storage: one slot per player (canonical helmet name or nil)
local playerHelmet: {[Player]: string?} = {}
-- Track the visual Accessory/Hat we attach to the character for helmets
local playerHelmetAccessory: {[Player]: Instance?} = {}

local function getHelmetEntryFromName(name: string)
	if not name then
		return nil, nil
	end

	local explicitEntry = HelmetAssetLookup[name]
	if explicitEntry then
		return explicitEntry, explicitEntry.canonicalName
	end

	local canonicalName = HelmetCanonicalLookup[name] or name
	local entry = HelmetEntries[canonicalName]
	return entry, canonicalName
end

local function ensurePlayerTable(player: Player)
	if playerHelmet[player] == nil then
		playerHelmet[player] = nil
	end
end

local function makeInstanceNonPhysical(root: Instance)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
end

local function makeInstancePhysical(root: Instance)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = true
			descendant.Massless = false
		end
	end
end

local function clearHelmetVisual(player: Player)
	local currentAccessory = playerHelmetAccessory[player]
	if currentAccessory and currentAccessory.Parent then
		currentAccessory:Destroy()
	end
	playerHelmetAccessory[player] = nil
end

local function attachHelmetVisual(player: Player, canonicalName: string, sourceTool: Tool?)
	clearHelmetVisual(player)

	local character = player.Character
	if not character then
		return
	end

	local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
	local entry = HelmetEntries[canonicalName]
	local accessory: Instance? = nil

	-- Preferred path: explicit accessory asset defined in HelmetConfig (and present in assets)
	if assetsFolder and entry and entry.accessoryAssetName then
		local asset = assetsFolder:FindFirstChild(entry.accessoryAssetName)
		if asset and (asset:IsA("Accessory") or asset:IsA("Hat")) then
			accessory = asset:Clone()
		end
	end

	-- Fallback: try to convert the source tool's handle into a simple Accessory
	if not accessory and sourceTool then
		local handle = sourceTool:FindFirstChild("Handle", true)
		if handle and handle:IsA("BasePart") then
			local acc = Instance.new("Accessory")
			acc.Name = canonicalName .. "_Helmet"

			local handleClone = handle:Clone()
			handleClone.Name = "Handle"
			handleClone.Parent = acc

			-- Small upward offset similar to old Hat.AttachmentPos example
			acc.AttachmentPoint = CFrame.new(0, 0.1, 0)

			accessory = acc
		end
	end

	if not accessory then
		return
	end

	-- Ensure all parts of the visual helmet are non-physical when equipped
	makeInstanceNonPhysical(accessory)

	accessory.Parent = character
	playerHelmetAccessory[player] = accessory
end

local function sendHelmetUpdate(player: Player)
	local canonicalName = playerHelmet[player]
	if not canonicalName then
		HelmetEvent:FireClient(player, "updateHelmet", nil)
		return
	end

	local entry = HelmetEntries[canonicalName]
	local payload = {
		canonicalName = canonicalName,
		displayName = (entry and (entry.displayName or canonicalName)) or canonicalName,
	}

	HelmetEvent:FireClient(player, "updateHelmet", payload)
end

local function setToolTouchEnabled(tool: Tool, enabled: boolean)
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanTouch = enabled
		end
	end
end

local function dropHelmetNearPlayer(player: Player, canonicalName: string)
	if not canonicalName then
		return
	end

	local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
	if not assetsFolder then
		return
	end

	local configEntry = HelmetEntries[canonicalName]
	local assetName = (configEntry and configEntry.assetName) or canonicalName
	local asset = assetsFolder:FindFirstChild(assetName)
	if not asset or not asset:IsA("Tool") then
		return
	end

	local tool = asset:Clone()
	tool.Parent = workspace
	-- Dropped helmets should behave like normal physical tools in the world
	makeInstancePhysical(tool)
	setToolTouchEnabled(tool, false)

	local pivotCFrame = nil
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			pivotCFrame = root.CFrame * CFrame.new(0, 2, -6)
		end
	end
	if pivotCFrame then
		pcall(function()
			tool:PivotTo(pivotCFrame)
		end)
	end

	task.delay(0.35, function()
		if tool.Parent == workspace then
			setToolTouchEnabled(tool, true)
		end
	end)
end

local function collectHelmet(player: Player, tool: Tool)
	if not player or not tool or not tool:IsA("Tool") then
		return
	end

	if tool:GetAttribute("HelmetCollected") then
		return
	end
	tool:SetAttribute("HelmetCollected", true)

	local entry, canonicalName = getHelmetEntryFromName(tool.Name)
	if not entry or not canonicalName then
		tool:SetAttribute("HelmetCollected", nil)
		return
	end

	ensurePlayerTable(player)

	-- Only one helmet slot; if already filled, ignore the new helmet (leave it in the world)
	if playerHelmet[player] ~= nil then
		tool:SetAttribute("HelmetCollected", nil)
		return
	end

	-- Ensure the tool's parts are non-physical as soon as it's treated as a helmet
	makeInstanceNonPhysical(tool)

	playerHelmet[player] = canonicalName

	-- Attach visual helmet on the character's head
	attachHelmetVisual(player, canonicalName, tool)

	tool:Destroy()

	sendHelmetUpdate(player)

	if typeof(_G.refreshEquipmentBonuses) == "function" then
		_G.refreshEquipmentBonuses(player)
	end
end

local function bindCharacter(player: Player, character: Model)
	ensurePlayerTable(player)

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and CollectionService:HasTag(child, HELMET_TAG) then
				task.defer(function()
					if child.Parent then
						collectHelmet(player, child)
					end
				end)
			end
		end)
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and CollectionService:HasTag(child, HELMET_TAG) then
			task.defer(function()
				if child.Parent then
					collectHelmet(player, child)
				end
			end)
		end
	end)

	-- Reattach visual if player already has a helmet slot when respawning
	if playerHelmet[player] then
		task.defer(function()
			if player.Character == character then
				attachHelmetVisual(player, playerHelmet[player] :: string, nil)
			end
		end)
	end
end

local function initialisePlayer(player: Player)
	ensurePlayerTable(player)
	sendHelmetUpdate(player)

	player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)

	if player.Character then
		bindCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(initialisePlayer)
for _, plr in ipairs(Players:GetPlayers()) do
	initialisePlayer(plr)
end

Players.PlayerRemoving:Connect(function(player)
	playerHelmet[player] = nil
	clearHelmetVisual(player)
end)

HelmetEvent.OnServerEvent:Connect(function(player, action)
	if action == "use" then
		local current = playerHelmet[player]
		if current then
			playerHelmet[player] = nil
			clearHelmetVisual(player)
			dropHelmetNearPlayer(player, current)
			sendHelmetUpdate(player)
			if typeof(_G.refreshEquipmentBonuses) == "function" then
				_G.refreshEquipmentBonuses(player)
			end
		end
	elseif action == "sync" then
		sendHelmetUpdate(player)
	end
end)

-- Expose helpers for other systems (InventoryManager, PlayerManager, etc.)
_G.getPlayerHelmet = function(player: Player)
	return playerHelmet[player]
end

_G.setPlayerHelmetFromData = function(player: Player, canonicalName: string?)
	if not player then
		return
	end
	if canonicalName ~= nil and HelmetEntries[canonicalName] == nil then
		-- Unknown helmet from data; ignore it.
		return
	end

	playerHelmet[player] = canonicalName

	-- If the player has a character, attach the visual now
	if player.Character and canonicalName then
		attachHelmetVisual(player, canonicalName, nil)
	end

	sendHelmetUpdate(player)
	if typeof(_G.refreshEquipmentBonuses) == "function" then
		_G.refreshEquipmentBonuses(player)
	end
end


