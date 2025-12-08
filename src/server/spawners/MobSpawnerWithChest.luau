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
local mobsKilledCount = 0 -- Track how many mobs were actually killed (not just despawned)
local totalMobsSpawned = 0 -- Track total mobs spawned in current wave

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
	-- Start from very high above to ensure we catch ground even if spawner is deep underground
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {spawner} -- Don't hit the spawner itself

	-- Cast ray from very high above (500 studs) down to well below (1000 studs total)
	-- This ensures we find ground even if spawner is buried deep
	local rayOrigin = position + Vector3.new(0, 500, 0)
	local rayDirection = Vector3.new(0, -1000, 0)

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		return raycastResult.Position.Y
	end

	-- Fallback: try a second raycast from spawner's location upward first, then down
	rayOrigin = spawner.Position + Vector3.new(0, 500, 0)
	raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		return raycastResult.Position.Y
	end

	-- Last fallback: use a default offset above spawner
	return spawner.Position.Y + 10
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

local function markMobDead(mob, wasKilled)
	wasKilled = wasKilled or false -- Track if mob was actually killed (via Died event) vs just removed
	
	for index = #activeMobs, 1, -1 do
		if activeMobs[index] == mob then
			table.remove(activeMobs, index)
			if wasKilled then
				mobsKilledCount = mobsKilledCount + 1
			end
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
				markMobDead(mob, true) -- Mark as killed (died event)
				Debris:AddItem(mob, 5)
			end)
		end)
	end

	mob.AncestryChanged:Connect(function(_, parent)
		if not parent then
			-- If mob is removed/destroyed without dying, don't count as killed
			markMobDead(mob, false)
		end
	end)
end

-- Check if a position is safe for spawning (not inside terrain, not on cliff, has space above)
local function isSafeSpawnPosition(position, checkRadius)
	checkRadius = checkRadius or 4 -- Default check radius in studs
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {spawner}
	
	-- 1. Check there's no terrain/obstacle directly above the spawn point
	local upRayOrigin = position + Vector3.new(0, 5, 0) -- Start slightly above position
	local upRayDirection = Vector3.new(0, 10, 0) -- Check upward
	local upRaycast = workspace:Raycast(upRayOrigin, upRayDirection, raycastParams)
	if upRaycast then
		return false, "obstacle_above" -- Something is blocking above
	end
	
	-- 2. Check ground exists directly below and get its normal
	local downRayOrigin = position + Vector3.new(0, 5, 0)
	local downRayDirection = Vector3.new(0, -15, 0) -- Check downward
	local downRaycast = workspace:Raycast(downRayOrigin, downRayDirection, raycastParams)
	if not downRaycast then
		return false, "no_ground" -- No ground found below
	end
	
	-- 3. Check ground slope is not too steep (normal.Y should be close to 1 for flat ground)
	local groundNormal = downRaycast.Normal
	local slopeAngle = math.acos(math.clamp(groundNormal.Y, -1, 1))
	local maxSlopeAngle = math.rad(45) -- Max 45 degree slope
	if slopeAngle > maxSlopeAngle then
		return false, "too_steep" -- Ground is too steep
	end
	
	-- 4. Check for cliff edges by testing nearby positions
	-- Sample points in a circle around the spawn position
	local sampleAngles = {0, math.pi/2, math.pi, 3*math.pi/2, math.pi/4, 3*math.pi/4, 5*math.pi/4, 7*math.pi/4}
	local sampleDistance = checkRadius * 0.7 -- Check a bit closer than checkRadius
	
	for _, angle in ipairs(sampleAngles) do
		local sampleOffset = Vector3.new(math.cos(angle) * sampleDistance, 0, math.sin(angle) * sampleDistance)
		local samplePos = position + sampleOffset
		
		-- Raycast down from sample position
		local sampleRayOrigin = samplePos + Vector3.new(0, 10, 0)
		local sampleRaycast = workspace:Raycast(sampleRayOrigin, Vector3.new(0, -30, 0), raycastParams)
		
		if sampleRaycast then
			local heightDiff = math.abs(sampleRaycast.Position.Y - downRaycast.Position.Y)
			-- If there's a significant height difference nearby, might be a cliff
			if heightDiff > 5 then
				return false, "cliff_edge" -- Too close to a cliff edge
			end
		else
			-- No ground found nearby - likely a cliff edge
			return false, "cliff_edge"
		end
	end
	
	-- 5. Verify position isn't inside terrain by checking if we can raycast to it from above
	local verifyRayOrigin = position + Vector3.new(0, 20, 0)
	local verifyRaycast = workspace:Raycast(verifyRayOrigin, Vector3.new(0, -25, 0), raycastParams)
	if verifyRaycast then
		-- Make sure the ground hit is close to our expected position
		local distanceToGround = math.abs(verifyRaycast.Position.Y - position.Y)
		if distanceToGround > 2 then
			return false, "inside_terrain" -- Position might be inside terrain
		end
	end
	
	return true, "safe"
end

-- Try to find a safe random spawn position with multiple attempts
local function randomSpawnPosition()
	local maxAttempts = 50 -- Maximum attempts to find a safe position
	local attempt = 0
	
	repeat
		attempt = attempt + 1
		
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
		
		-- Validate this is a safe spawn position
		local isSafe, reason = isSafeSpawnPosition(spawnPosition, CONFIG.SpawnRadius * 0.3)
		
		if isSafe then
			return CFrame.new(spawnPosition)
		end
		
	until attempt >= maxAttempts
	
	-- If we couldn't find a safe position after many attempts, try using spawner position
	-- Find ground above spawner and use that as fallback
	local fallbackGroundLevel = findGroundLevel(spawner.Position)
	local fallbackY = fallbackGroundLevel + CONFIG.MobSpawnHeightOffset
	local fallbackPosition = Vector3.new(spawner.Position.X, fallbackY, spawner.Position.Z)
	
	warn(("[MobSpawnerWithChest] Could not find safe spawn position after %d attempts, using fallback position"):format(maxAttempts))
	return CFrame.new(fallbackPosition)
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
	-- Reset kill tracking when spawning new wave
	mobsKilledCount = 0
	totalMobsSpawned = 0
	
	for _ = 1, CONFIG.SpawnCount do
		local mob = spawnMob()
		if mob then
			totalMobsSpawned = totalMobsSpawned + 1
		end
	end
end

local function despawnAllMobs()
	for _, mob in ipairs(activeMobs) do
		if mob and mob.Parent then
			mob:Destroy()
		end
	end
	table.clear(activeMobs)
	-- Reset kill tracking when despawning (mobs weren't killed, just despawned)
	mobsKilledCount = 0
	totalMobsSpawned = 0
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

	-- Find actual ground level above the spawner (even if spawner is underground)
	local groundLevel = findGroundLevel(spawner.Position)
	
	-- Position chest above the ground level, not relative to spawner
	-- This ensures chest appears above ground even if spawner is buried
	local chestBottomY = groundLevel + CONFIG.ChestHeightOffset
	local chestCenterY = chestBottomY + chestHalfHeight
	
	-- Use spawner's X and Z position, but ground level Y
	local chestPosition = Vector3.new(spawner.Position.X, chestCenterY, spawner.Position.Z)
	local spawnCFrame = CFrame.new(chestPosition)

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
	-- Only spawn chest if ALL mobs were actually KILLED (not just despawned)
	local allMobsKilled = (#activeMobs == 0 and mobsKilledCount > 0 and mobsKilledCount >= totalMobsSpawned)
	
	if allMobsKilled and not activeChest and ensureChestTemplate() then
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
			-- This resets the kill tracking (mobs weren't killed, just despawned)
			if #activeMobs > 0 then
				despawnAllMobs()
			end
			if activeChest then
				removeChest()
			end
		else
			-- Players nearby: manage mobs and chest
			if #activeMobs == 0 then
				-- No active mobs: check if all were killed or just despawned
				local allMobsKilled = (totalMobsSpawned > 0 and mobsKilledCount > 0 and mobsKilledCount >= totalMobsSpawned)
				
				if allMobsKilled then
					-- All mobs were actually killed: spawn chest
					checkAndSpawnChest()
					
					-- Check if we should respawn mobs (after respawn delay)
					if (os.clock() - lastSpawnTime) >= CONFIG.RespawnDelay then
						checkAndRemoveChest() -- Remove chest before spawning mobs
						spawnMobGroup()
						lastSpawnTime = os.clock()
					end
				else
					-- Mobs were just despawned (not killed) OR no mobs spawned yet: respawn immediately, no chest
					if activeChest then
						removeChest() -- Ensure no chest if mobs weren't killed
					end
					
					-- Respawn mobs immediately (reset complete)
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

