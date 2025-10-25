-- -- MobDeathHandler.lua
-- -- Makes any mob fall apart on death and then completely removes it after a few seconds

-- local Mob = script.Parent

-- -- Function to break Motor6Ds so the rig collapses
-- local function BreakJoints(model)
-- 	for _, obj in ipairs(model:GetDescendants()) do
-- 		if obj:IsA("Motor6D") then
-- 			obj:Destroy()
-- 		end
-- 	end
-- end

-- -- Death trigger
-- local function OnDeath()
-- 	print("[MobDeathHandler] Mob died:", Mob.Name)
	
-- 	-- Disable movement/AI scripts
-- 	for _, child in ipairs(Mob:GetChildren()) do
-- 		if child:IsA("Script") or child:IsA("LocalScript") then
-- 			child.Disabled = true
-- 		end
-- 	end

-- 	-- Make all parts fall naturally and be collidable
-- 	for _, part in ipairs(Mob:GetDescendants()) do
-- 		if part:IsA("BasePart") then
-- 			part.Anchored = false
-- 			part.CanCollide = true -- ensure collision so it doesn't fall through map
-- 		end
-- 	end

-- 	-- Detach limbs
-- 	BreakJoints(Mob)
	
-- 	-- Wait a few seconds then completely remove from map
-- 	task.wait(3) -- Wait 3 seconds
	
-- 	print("[MobDeathHandler] Removing mob from map:", Mob.Name)
-- 	Mob:Destroy() -- Completely removes the mob from the game
-- end

-- -- Hook to Humanoid death if it exists
-- local Humanoid = Mob:FindFirstChildOfClass("Humanoid")
-- if Humanoid then
-- 	Humanoid.Died:Connect(OnDeath)
-- else
-- 	-- Optional: if you use a custom event
-- 	local deathEvent = Mob:FindFirstChild("DeathEvent")
-- 	if deathEvent and deathEvent:IsA("BindableEvent") then
-- 		deathEvent.Event:Connect(OnDeath)
-- 	end
-- end
