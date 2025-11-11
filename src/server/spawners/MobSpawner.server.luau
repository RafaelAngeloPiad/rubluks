-- MobSpawner.server.luau
-- Drop this Script inside a Part (the spawner) in Workspace.
-- Configure the spawner through attributes or by editing the defaults below.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local spawner = script.Parent
if not spawner or not spawner:IsA("BasePart") then
	error("[MobSpawner] Script must be parented to a BasePart in workspace.")
end

--[[ Configuration

	Set these as attributes on the spawner part to override the defaults:
	- MobModelPath (string)   -> e.g. "Mobs/Arawizard"
	- SpawnCount (number)
	- SpawnRadius (number)
	- DetectionRadius (number)
	- RespawnDelay (number)   -> seconds to wait before re-spawning after the last mob dies
	- CheckInterval (number)  -> how often the spawner evaluates its state

	If MobModelPath is not provided, the script expects a child named "MobTemplate"
	under ReplicatedStorage.
]]

local DEFAULTS = {
	MobModelPath = "Mobs/Arawizard",
	SpawnCount = 5,
	SpawnRadius = 25,
	DetectionRadius = 120,
	RespawnDelay = 5,
	CheckInterval = 1,
}

local function getAttribute(name, default)
	local value = spawner:GetAttribute(name)
	if value ~= nil then
		return value
	end
	return default
end

local function resolveMobTemplate(path)
	if not path or path == "" then
		path = DEFAULTS.MobModelPath
	end

	local segments = {}
	for segment in string.gmatch(path, "[^/]+") do
		table.insert(segments, segment)
	end

	local current = ReplicatedStorage
	for _, segment in ipairs(segments) do
		current = current:FindFirstChild(segment)
		if not current then
			error(("[MobSpawner] Unable to resolve mob model path '%s'"):format(path))
		end
	end

	if not current:IsA("Model") then
		error(("[MobSpawner] Path '%s' did not resolve to a Model"):format(path))
	end

	current.Archivable = true
	return current
end

local CONFIG = {
	MobTemplate = resolveMobTemplate(getAttribute("MobModelPath", DEFAULTS.MobModelPath)),
	SpawnCount = getAttribute("SpawnCount", DEFAULTS.SpawnCount),
	SpawnRadius = getAttribute("SpawnRadius", DEFAULTS.SpawnRadius),
	DetectionRadius = getAttribute("DetectionRadius", DEFAULTS.DetectionRadius),
	RespawnDelay = getAttribute("RespawnDelay", DEFAULTS.RespawnDelay),
	CheckInterval = getAttribute("CheckInterval", DEFAULTS.CheckInterval),
}

local activeMobs = {}
local spawnId = ("%s_%d"):format(spawner:GetFullName(), os.clock())
local spawnFolder = workspace:FindFirstChild("MobSpawns")
if not spawnFolder then
	spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "MobSpawns"
	spawnFolder.Parent = workspace
end

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

local function removeInactive()
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
	local angle = math.random() * math.pi * 2
	local radius = math.sqrt(math.random()) * CONFIG.SpawnRadius
	local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local baseCFrame = spawner.CFrame
	local spawnPosition = baseCFrame.Position + offset
	return CFrame.new(spawnPosition)
end

local function spawnOne()
	local mobModel = CONFIG.MobTemplate:Clone()
	mobModel.Parent = spawnFolder

	local primary = getPrimaryPart(mobModel)
	if not primary then
		warn("[MobSpawner] Spawned mob does not have a PrimaryPart:", mobModel:GetFullName())
		return nil
	end

	local pivot = mobModel:GetPivot()
	local spawnCFrame = randomSpawnPosition()
	mobModel:PivotTo(CFrame.new(spawnCFrame.Position, spawnCFrame.Position + pivot.LookVector))

	bindMob(mobModel)
	table.insert(activeMobs, mobModel)
	return mobModel
end

local function spawnGroup()
	for _ = 1, CONFIG.SpawnCount do
		spawnOne()
	end
end

local function despawnAll()
	for _, mob in ipairs(activeMobs) do
		if mob and mob.Parent then
			mob:Destroy()
		end
	end
	table.clear(activeMobs)
end

local lastSpawnTime = 0

local function runSpawner()
	while true do
		removeInactive()
		local playerNearby = playersInRange()

		if not playerNearby then
			if #activeMobs > 0 then
				despawnAll()
			end
		else
			if #activeMobs == 0 and (os.clock() - lastSpawnTime) >= CONFIG.RespawnDelay then
				spawnGroup()
				lastSpawnTime = os.clock()
			end
		end

		task.wait(CONFIG.CheckInterval)
	end
end

-- Initial spawn check (immediate if a player is already nearby).
if playersInRange() then
	spawnGroup()
	lastSpawnTime = os.clock()
end

task.spawn(runSpawner)

