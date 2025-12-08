-- MobSpawnerWithChest.server.luau
-- Drop this Script inside a Part (the spawner) in Workspace.
-- Combines mob spawning with chest rewards that appear after all mobs are defeated.
-- Configure the spawner through attributes or by editing the defaults below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local spawner = script.Parent
if not spawner or not spawner:IsA("BasePart") then
	error("[MobSpawnerWithChest] Script must be parented to a BasePart in workspace.")
end

--[[ Configuration

	Set these as attributes on the spawner part to override the defaults:
	
	-- Mob Configuration
	- MobModelPath (string)      -> e.g. "Mobs/Arawizard"
	- SpawnCount (number)         -> Number of mobs to spawn
	- SpawnRadius (number)        -> Radius around spawner to spawn mobs
	- MobSpawnHeightOffset (number) -> Extra height above ground for mobs (default: 2)
	
	-- Chest Configuration
	- ChestModelPath (string)    -> e.g. "chests/Random Weapon Chest"
	- ChestHeightOffset (number)  -> Height offset above spawner for chest
	
	-- Shared Configuration
	- DetectionRadius (number)   -> How far players can be detected
	- RespawnDelay (number)      -> Seconds to wait before re-spawning after last mob dies
	- CheckInterval (number)     -> Optional: Override auto-calculated check interval (default: auto-calculated from RespawnDelay)
]]

local DEFAULTS = {
	-- Mob Configuration
	MobModelPath = "Mobs/Arabandit",
	SpawnCount = 1,
	SpawnRadius = 25,
	MobSpawnHeightOffset = 2, -- Extra height above ground to prevent underground spawning

	-- Chest Configuration
	ChestModelPath = "chests/Random Chest",
	ChestHeightOffset = 0,

	-- Shared Configuration
	DetectionRadius = 120,
	RespawnDelay = 100,
	CheckInterval = nil, -- nil = auto-calculate based on RespawnDelay
}

local function getAttribute(name, default)
	local value = spawner:GetAttribute(name)
	if value ~= nil then
		return value
	end
	return default
end

local function resolveModelTemplate(path, errorOnFail)
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
			if errorOnFail then
				error(("[MobSpawnerWithChest] Unable to resolve model path '%s'"):format(path))
			else
				warn(("[MobSpawnerWithChest] Unable to resolve model path '%s'"):format(path))
				return nil
			end
		end
	end

	if not current:IsA("Model") then
		if errorOnFail then
			error(("[MobSpawnerWithChest] Path '%s' did not resolve to a Model"):format(path))
		else
			warn(("[MobSpawnerWithChest] Path '%s' did not resolve to a Model"):format(path))
			return nil
		end
	end

	current.Archivable = true
	return current
end

local CONFIG = {
	-- Mob Configuration
	MobTemplate = resolveModelTemplate(getAttribute("MobModelPath", DEFAULTS.MobModelPath), true),
	SpawnCount = getAttribute("SpawnCount", DEFAULTS.SpawnCount),
	SpawnRadius = math.max(getAttribute("SpawnRadius", DEFAULTS.SpawnRadius), 0),
	MobSpawnHeightOffset = getAttribute("MobSpawnHeightOffset", DEFAULTS.MobSpawnHeightOffset),

	-- Chest Configuration
	ChestTemplate = resolveModelTemplate(getAttribute("ChestModelPath", DEFAULTS.ChestModelPath), false),
	ChestHeightOffset = getAttribute("ChestHeightOffset", DEFAULTS.ChestHeightOffset),

	-- Shared Configuration
	DetectionRadius = math.max(getAttribute("DetectionRadius", DEFAULTS.DetectionRadius), 0),
	RespawnDelay = math.max(getAttribute("RespawnDelay", DEFAULTS.RespawnDelay), 0),
	CheckInterval = getAttribute("CheckInterval", DEFAULTS.CheckInterval), -- nil = auto-calculate
}

-- Initialize spawn folders
local mobSpawnFolder = workspace:FindFirstChild("MobSpawns")
if not mobSpawnFolder then
	mobSpawnFolder = Instance.new("Folder")
	mobSpawnFolder.Name = "MobSpawns"
	mobSpawnFolder.Parent = workspace
end

local chestSpawnFolder = workspace:FindFirstChild("ChestSpawns")
if not chestSpawnFolder then
	chestSpawnFolder = Instance.new("Folder")
	chestSpawnFolder.Name = "ChestSpawns"
	chestSpawnFolder.Parent = workspace
end

-- State tracking
local activeMobs = {}
local activeChest = nil
local spawnId = ("%s_%d"):format(spawner:GetFullName(), os.clock())
local lastSpawnTime = 0

-- Helper Functions
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

local function findGroundLevel(position)
	-- Raycast downward to find the ground level
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {spawner} -- Don't hit the spawner itself

	-- Cast ray from high above down to well below
	local rayOrigin = position + Vector3.new(0, 100, 0)
	local rayDirection = Vector3.new(0, -200, 0)

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		return raycastResult.Position.Y
	end

	-- Fallback: use the spawner's Y position if raycast fails
	return spawner.Position.Y
end

local function removeInactiveMobs()
	for index = #activeMobs, 1, -1 do
		local mob = activeMobs[index]
		if not mob or not mob.Parent then
			table.remove(activeMobs, index)
		end
	end
end

local function playersInRange()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				if (root.Position - spawner.Position).Magnitude <= CONFIG.DetectionRadius then
					return true
				end
			end
		end
	end
	return false
end

local function markMobDead(mob)
	for index = #activeMobs, 1, -1 do
		if activeMobs[index] == mob then
			table.remove(activeMobs, index)
			break
		end
	end
end

local function bindMob(mob)
	mob:SetAttribute("SpawnedBy", spawnId)
	mob:SetAttribute("SpawnedAt", os.time())

	local humanoid = mob:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.defer(function()
				markMobDead(mob)
				Debris:AddItem(mob, 5)
			end)
		end)
	end

	mob.AncestryChanged:Connect(function(_, parent)
		if not parent then
			markMobDead(mob)
		end
	end)
end

local function randomSpawnPosition()
	-- Generate random position in circle
	local angle = math.random() * math.pi * 2
	local radius = math.sqrt(math.random()) * CONFIG.SpawnRadius
	local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)

	-- Calculate base position
	local basePosition = spawner.Position + offset

	-- Find ground level at this position
	local groundLevel = findGroundLevel(basePosition)

	-- Spawn above ground with offset
	local spawnY = groundLevel + CONFIG.MobSpawnHeightOffset
	local spawnPosition = Vector3.new(basePosition.X, spawnY, basePosition.Z)

	return CFrame.new(spawnPosition)
end

local function spawnMob()
	local mobModel = CONFIG.MobTemplate:Clone()
	mobModel.Parent = mobSpawnFolder

	local primary = getPrimaryPart(mobModel)
	if not primary then
		warn("[MobSpawnerWithChest] Spawned mob does not have a PrimaryPart:", mobModel:GetFullName())
		mobModel:Destroy()
		return nil
	end

	local pivot = mobModel:GetPivot()
	local spawnCFrame = randomSpawnPosition()

	-- Preserve the mob's rotation while positioning it
	mobModel:PivotTo(CFrame.new(spawnCFrame.Position, spawnCFrame.Position + pivot.LookVector))

	bindMob(mobModel)
	table.insert(activeMobs, mobModel)
	return mobModel
end

local function spawnMobGroup()
	for _ = 1, CONFIG.SpawnCount do
		spawnMob()
	end
end

local function despawnAllMobs()
	for _, mob in ipairs(activeMobs) do
		if mob and mob.Parent then
			mob:Destroy()
		end
	end
	table.clear(activeMobs)
end

local function ensureChestTemplate()
	if CONFIG.ChestTemplate and CONFIG.ChestTemplate.Parent then
		return CONFIG.ChestTemplate
	end
	CONFIG.ChestTemplate = resolveModelTemplate(getAttribute("ChestModelPath", DEFAULTS.ChestModelPath), false)
	return CONFIG.ChestTemplate
end

local function removeChest()
	if activeChest and activeChest.Parent then
		activeChest:Destroy()
	end
	activeChest = nil
end

local function spawnChest()
	-- Don't spawn chest if no template configured
	if not ensureChestTemplate() then
		return nil
	end

	local chestClone = CONFIG.ChestTemplate:Clone()
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

	-- Position chest on top of spawner
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
		end
	end)

	activeChest = chestClone
	return chestClone
end

local function checkAndSpawnChest()
	-- Spawn chest when all mobs are dead and no chest exists
	if #activeMobs == 0 and not activeChest and ensureChestTemplate() then
		spawnChest()
	end
end

local function checkAndRemoveChest()
	-- Remove chest when mobs spawn
	if activeChest then
		removeChest()
	end
end

-- Calculate optimal check interval based on current state
local function calculateCheckInterval()
	-- If CheckInterval is explicitly set, use it
	if CONFIG.CheckInterval ~= nil then
		return math.max(CONFIG.CheckInterval, 0.1)
	end

	-- Auto-calculate based on RespawnDelay and current state
	local baseInterval = math.min(CONFIG.RespawnDelay * 0.1, 10) -- 10% of respawn delay, max 10 seconds
	baseInterval = math.max(baseInterval, 1) -- Minimum 1 second

	-- If mobs are alive, check less frequently (just need to know if they're still alive)
	if #activeMobs > 0 then
		return math.min(baseInterval * 2, 5) -- Check every 2-5 seconds when mobs are alive
	end

	-- If mobs are dead, check more frequently as we approach respawn time
	if lastSpawnTime > 0 then
		local timeSinceLastSpawn = os.clock() - lastSpawnTime
		local timeUntilRespawn = CONFIG.RespawnDelay - timeSinceLastSpawn

		-- If close to respawn time (< 5 seconds), check more frequently
		if timeUntilRespawn > 0 and timeUntilRespawn <= 5 then
			return 1 -- Check every second when close to respawn
		end
	end

	-- Otherwise use base interval
	return baseInterval
end

-- Main spawner loop
local function runSpawner()
	while true do
		removeInactiveMobs()
		local playerNearby = playersInRange()

		if not playerNearby then
			-- No players nearby: despawn all mobs and chest
			if #activeMobs > 0 then
				despawnAllMobs()
			end
			if activeChest then
				removeChest()
			end
		else
			-- Players nearby: manage mobs and chest
			if #activeMobs == 0 then
				-- All mobs dead: spawn chest if not already spawned
				checkAndSpawnChest()

				-- Check if we should respawn mobs
				if (os.clock() - lastSpawnTime) >= CONFIG.RespawnDelay then
					checkAndRemoveChest() -- Remove chest before spawning mobs
					spawnMobGroup()
					lastSpawnTime = os.clock()
				end
			else
				-- Mobs are alive: ensure chest is removed
				if activeChest then
					removeChest()
				end
			end
		end

		-- Use dynamic check interval for optimal performance
		local checkInterval = calculateCheckInterval()
		task.wait(checkInterval)
	end
end

-- Initial spawn check (immediate if a player is already nearby)
if playersInRange() then
	spawnMobGroup()
	lastSpawnTime = os.clock()
end

task.spawn(runSpawner)

