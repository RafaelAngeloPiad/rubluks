-- Hitbox Exclusions Module
-- Centralized exclusion system for hitbox targeting

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HitboxExclusions = {}

-- Global exclusion tags - add any tags you want hitboxes to ignore
HitboxExclusions.EXCLUDE_TAGS = {
    "golem_entity",
    "spider_entity",
    "simple_entity",
    "wraith_entity",
    "zombie_entity",
	"human_melee_entity",
	"human_projectile_entity",
	"human_wizard_entity",
}

-- Function to check if a model has any excluded tags
function HitboxExclusions.hasExcludedTag(model)
    for _, tag in ipairs(HitboxExclusions.EXCLUDE_TAGS) do
        if CollectionService:HasTag(model, tag) then
            return true
        end
    end
    return false
end

-- Function to add a new exclusion tag
function HitboxExclusions.addExclusionTag(tag)
    table.insert(HitboxExclusions.EXCLUDE_TAGS, tag)
end

-- Function to remove an exclusion tag
function HitboxExclusions.removeExclusionTag(tag)
    for i, existingTag in ipairs(HitboxExclusions.EXCLUDE_TAGS) do
        if existingTag == tag then
            table.remove(HitboxExclusions.EXCLUDE_TAGS, i)
            break
        end
    end
end

-- Function to get all exclusion tags
function HitboxExclusions.getExclusionTags()
    return HitboxExclusions.EXCLUDE_TAGS
end

local FriendlyFireFolder
local function locateFriendlyFireFolder()
	if FriendlyFireFolder and FriendlyFireFolder.Parent then
		return FriendlyFireFolder
	end
	local devSettings = ReplicatedStorage:FindFirstChild("DevSettings")
	if not devSettings then
		return nil
	end
	FriendlyFireFolder = devSettings:FindFirstChild("FriendlyFire")
	return FriendlyFireFolder
end

local function locateValue(name)
	local folder = locateFriendlyFireFolder()
	if not folder then
		return nil
	end
	return folder:FindFirstChild(name)
end

local MobFriendlyFireValue = locateValue("Mobs")
local MobCombatModeValue = locateValue("MobCombatMode")
local mobFriendlyConn
local mobModeConn

local MOB_COMBAT_MODES = {
	EXCLUDED = "excluded",
	VERSUS = "versus",
	FRENZY = "frenzy",
}

local function normalizeMode(mode)
	if mode == MOB_COMBAT_MODES.VERSUS or mode == MOB_COMBAT_MODES.FRENZY then
		return mode
	end
	return MOB_COMBAT_MODES.EXCLUDED
end

local currentMobCombatMode = MOB_COMBAT_MODES.EXCLUDED
local currentMobFriendlyFire = false

local function bindMobFriendlyFire(valueObject)
	if not valueObject then
		return
	end
	MobFriendlyFireValue = valueObject
	currentMobFriendlyFire = valueObject.Value == true
	if mobFriendlyConn then
		mobFriendlyConn:Disconnect()
	end
	mobFriendlyConn = valueObject:GetPropertyChangedSignal("Value"):Connect(function()
		currentMobFriendlyFire = valueObject.Value == true
	end)
end

local function bindMobCombatMode(valueObject)
	if not valueObject then
		return
	end
	MobCombatModeValue = valueObject
	currentMobCombatMode = normalizeMode(valueObject.Value)
	if mobModeConn then
		mobModeConn:Disconnect()
	end
	mobModeConn = valueObject:GetPropertyChangedSignal("Value"):Connect(function()
		currentMobCombatMode = normalizeMode(valueObject.Value)
	end)
end

bindMobFriendlyFire(MobFriendlyFireValue)
bindMobCombatMode(MobCombatModeValue)

task.spawn(function()
	if MobFriendlyFireValue and MobCombatModeValue then
		return
	end
	local devSettings = ReplicatedStorage:WaitForChild("DevSettings", 10)
	if not devSettings then
		return
	end
	local friendlyFire = devSettings:WaitForChild("FriendlyFire", 10)
	if not friendlyFire then
		return
	end
	FriendlyFireFolder = friendlyFire
	if not MobFriendlyFireValue then
		local valueObject = friendlyFire:WaitForChild("Mobs", 10)
		if valueObject then
			bindMobFriendlyFire(valueObject)
		end
	end
	if not MobCombatModeValue then
		local valueObject = friendlyFire:WaitForChild("MobCombatMode", 10)
		if valueObject then
			bindMobCombatMode(valueObject)
		end
	end
end)

local function getPrimaryMobTag(model)
	if not model or not model:IsA("Model") then
		return nil
	end
	for _, tag in ipairs(HitboxExclusions.EXCLUDE_TAGS) do
		if CollectionService:HasTag(model, tag) then
			return tag
		end
	end
	return nil
end

local function isMob(model)
	return getPrimaryMobTag(model) ~= nil
end

local function shouldAllowMobVsMob(attacker, target)
	if currentMobCombatMode == MOB_COMBAT_MODES.FRENZY then
		return true
	elseif currentMobCombatMode == MOB_COMBAT_MODES.VERSUS then
		local attackerTag = getPrimaryMobTag(attacker)
		local targetTag = getPrimaryMobTag(target)
		if attackerTag and targetTag then
			if attackerTag ~= targetTag then
				return true
			end
			return currentMobFriendlyFire
		end
		return true
	else -- excluded
		return currentMobFriendlyFire
	end
end

function HitboxExclusions.getMobCombatMode()
	return currentMobCombatMode
end

function HitboxExclusions.getMobFriendlyFire()
	return currentMobFriendlyFire
end

function HitboxExclusions.getPrimaryMobTag(model)
	return getPrimaryMobTag(model)
end

function HitboxExclusions.shouldAttack(attacker, target)
	if not attacker or not target then
		return false
	end
	if attacker == target then
		return false
	end

	local attackerIsMob = isMob(attacker)
	local targetIsMob = isMob(target)

	if not attackerIsMob then
		return true
	end

	if not targetIsMob then
		return true
	end

	return shouldAllowMobVsMob(attacker, target)
end

function HitboxExclusions.shouldIgnoreTarget(attacker, target)
	return not HitboxExclusions.shouldAttack(attacker, target)
end

function HitboxExclusions.findClosestHostile(attacker, originPosition, maxDistance)
	if not attacker or not originPosition then
		return nil, nil, nil, nil
	end

	local maxRange = maxDistance or math.huge
	local bestModel, bestRoot, bestHumanoid, bestDistance = nil, nil, nil, maxRange

	for _, model in ipairs(Workspace:GetChildren()) do
		if model ~= attacker and model:IsA("Model") then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 then
				if HitboxExclusions.shouldAttack(attacker, model) then
					local distance = (root.Position - originPosition).Magnitude
					if distance < bestDistance then
						bestModel = model
						bestRoot = root
						bestHumanoid = humanoid
						bestDistance = distance
					end
				end
			end
		end
	end

	if bestModel then
		return bestModel, bestRoot, bestHumanoid, bestDistance
	end

	return nil, nil, nil, nil
end

return HitboxExclusions
