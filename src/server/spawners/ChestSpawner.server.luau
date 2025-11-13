-- ChestSpawner.server.luau
-- Parent this script to a BasePart in workspace to spawn and refresh chests.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spawner = script.Parent
if not spawner or not spawner:IsA("BasePart") then
	error("[ChestSpawner] Script must be parented to a BasePart in workspace.")
end

local DEFAULTS = {
	ChestModelPath = "chests/RedChest",
	ChestRespawnDelay = 60,
	CheckInterval = 1,
	ChestHeightOffset = 0,
	SpawnFolderName = "ChestSpawns",
}

local function getAttribute(name, default)
	local value = spawner:GetAttribute(name)
	if value ~= nil then
		return value
	end
	return default
end

local function resolveChestTemplate(path)
	if not path or path == "" then
		return nil
	end

	local segments = {}
	for segment in string.gmatch(path, "[^/]+") do
		table.insert(segments, segment)
	end

	local current = ReplicatedStorage
	for _, segment in ipairs(segments) do
		current = current:FindFirstChild(segment)
		if not current then
			warn(("[ChestSpawner] Unable to resolve chest model path '%s'"):format(path))
			return nil
		end
	end

	if not current:IsA("Model") then
		warn(("[ChestSpawner] Path '%s' did not resolve to a Model"):format(path))
		return nil
	end

	current.Archivable = true
	return current
end

local CONFIG = {
	ChestModelPath = getAttribute("ChestModelPath", DEFAULTS.ChestModelPath),
	ChestRespawnDelay = math.max(getAttribute("ChestRespawnDelay", DEFAULTS.ChestRespawnDelay), 0),
	CheckInterval = math.max(getAttribute("CheckInterval", DEFAULTS.CheckInterval), 0.1),
	ChestHeightOffset = getAttribute("ChestHeightOffset", DEFAULTS.ChestHeightOffset),
	SpawnFolderName = getAttribute("SpawnFolderName", DEFAULTS.SpawnFolderName),
}

local chestTemplate = resolveChestTemplate(CONFIG.ChestModelPath)

local chestSpawnFolder = workspace:FindFirstChild(CONFIG.SpawnFolderName)
if not chestSpawnFolder then
	chestSpawnFolder = Instance.new("Folder")
	chestSpawnFolder.Name = CONFIG.SpawnFolderName
	chestSpawnFolder.Parent = workspace
end

local activeChest: Model? = nil
local nextRefreshTime = 0

local function getPrimaryPart(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local primary = model:FindFirstChildWhichIsA("BasePart")
	if primary then
		model.PrimaryPart = primary
	end

	return primary
end

local function scheduleNextRefresh(delay)
	if delay <= 0 then
		nextRefreshTime = os.clock()
	else
		nextRefreshTime = os.clock() + delay
	end
end

local function ensureChestTemplate()
	if chestTemplate and chestTemplate.Parent then
		return chestTemplate
	end
	chestTemplate = resolveChestTemplate(CONFIG.ChestModelPath)
	return chestTemplate
end

local function removeChest()
	if activeChest and activeChest.Parent then
		activeChest:Destroy()
	end
	activeChest = nil
end

local function spawnChest()
	local template = ensureChestTemplate()
	if not template then
		return nil
	end

	local chestClone = template:Clone()
	chestClone.Parent = chestSpawnFolder

	local primary = getPrimaryPart(chestClone)
	local chestHalfHeight = 0

	if primary then
		if primary:IsA("BasePart") then
			chestHalfHeight = primary.Size.Y * 0.5
		end
	else
		local size = chestClone:GetExtentsSize()
		if size then
			chestHalfHeight = size.Y * 0.5
		end
	end

	local spawnOffsetY = (spawner.Size.Y * 0.5) + chestHalfHeight + CONFIG.ChestHeightOffset
	local spawnCFrame = spawner.CFrame * CFrame.new(0, spawnOffsetY, 0)

	if primary then
		chestClone:PivotTo(spawnCFrame)
	else
		chestClone:MoveTo(spawnCFrame.Position)
	end

	chestClone:SetAttribute("SpawnedBy", spawner:GetFullName())
	chestClone:SetAttribute("SpawnedAt", os.time())

	chestClone.AncestryChanged:Connect(function(_, parent)
		if not parent and activeChest == chestClone then
			activeChest = nil
			nextRefreshTime = os.clock()
		end
	end)

	activeChest = chestClone
	scheduleNextRefresh(CONFIG.ChestRespawnDelay)
	return chestClone
end

local function refreshChest()
	removeChest()
	return spawnChest()
end

local function runChestSpawner()
	if not ensureChestTemplate() then
		return
	end

	spawnChest()

	while true do
		local now = os.clock()

		if CONFIG.ChestRespawnDelay > 0 then
			if now >= nextRefreshTime then
				refreshChest()
			end
		else
			if not activeChest and now >= nextRefreshTime then
				spawnChest()
			end
		end

		if not activeChest then
			-- If the chest was removed externally and no respawn delay, try again soon.
			if CONFIG.ChestRespawnDelay <= 0 then
				nextRefreshTime = os.clock()
			elseif now >= nextRefreshTime then
				spawnChest()
			end
		end

		task.wait(CONFIG.CheckInterval)
	end
end

task.spawn(runChestSpawner)


