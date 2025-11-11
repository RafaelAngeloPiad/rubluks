-- MobDeathHandler.lua
-- Makes any mob fall apart on death and then completely removes it after a few seconds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mob = script.Parent

local MobStatsConfig
do
	local ok, moduleOrErr = pcall(function()
		return require(ReplicatedStorage:WaitForChild("mobs"):WaitForChild("MobStatsConfig"))
	end)
	if ok then
		MobStatsConfig = moduleOrErr
	else
		warn("[MobDeathHandler] Failed to load MobStatsConfig:", moduleOrErr)
	end
end

-- Function to break Motor6Ds so the rig collapses
local function BreakJoints(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("Motor6D") then
			obj:Destroy()
		end
	end
end

local function getMobXP()
	local xp = Mob:GetAttribute("XPGain")
	if xp and xp > 0 then
		return xp
	end

	if MobStatsConfig then
		local variant = Mob:GetAttribute("MobVariant")
		if variant then
			local stats = MobStatsConfig.getStats and MobStatsConfig.getStats(variant)
			if stats and stats.XPGain then
				return stats.XPGain
			end
		end
	end

	return nil
end

local function awardXPToLastDamager()
	local killerUserId = Mob:GetAttribute("LastDamagePlayerId")
	if not killerUserId then
		return
	end

	local player = Players:GetPlayerByUserId(killerUserId)
	if not player then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local currentXP = leaderstats:FindFirstChild("CurrentXP")
	if not currentXP then
		return
	end

	local xpReward = getMobXP()
	if not xpReward or xpReward <= 0 then
		return
	end

	currentXP.Value = currentXP.Value + xpReward
end

-- Death trigger
local function OnDeath()

	awardXPToLastDamager()

	-- Disable movement/AI scripts
	for _, child in ipairs(Mob:GetChildren()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child.Disabled = true
		end
	end

	-- Make all parts fall naturally and be collidable
	for _, part in ipairs(Mob:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true -- ensure collision so it doesn't fall through map
		end
	end

	-- Detach limbs
	BreakJoints(Mob)

	-- Wait a few seconds then completely remove from map
	task.wait(3) -- Wait 3 seconds

	Mob:Destroy() -- Completely removes the mob from the game
end

-- Hook to Humanoid death if it exists
local Humanoid = Mob:FindFirstChildOfClass("Humanoid")
if Humanoid then
	Humanoid.Died:Connect(OnDeath)
else
	-- Optional: if you use a custom event
	local deathEvent = Mob:FindFirstChild("DeathEvent")
	if deathEvent and deathEvent:IsA("BindableEvent") then
		deathEvent.Event:Connect(OnDeath)
	end
end
