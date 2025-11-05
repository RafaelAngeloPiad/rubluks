-- Wraith AI Module
-- Simple: Just looks at player, stays in place, shoots homing projectiles with burn

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- Import global exclusions
local HitboxExclusions = require(script.Parent.HitboxExclusions)
local MobStatsConfig = require(script.Parent.MobStatsConfig)

-- Try to require MobStatsDisplay module
local MobStatsDisplay = nil
local success, displayModule = pcall(function()
	return require(game.ReplicatedStorage.MobStatsDisplay)
end)
if success then
	MobStatsDisplay = displayModule
end

-- === CONFIG ===
local DETECTION_RANGE = 20
local ATTACK_COOLDOWN = 2  -- Seconds between attacks
local MISSILE_SPEED = 20   -- Speed of the homing projectile
local MISSILE_LIFETIME = 1 -- Seconds before missile despawns
local FLOAT_HEIGHT = 5  -- Height in studs to float above ground
local FLOAT_SPEED = 0.08  -- Lerp speed (0.08 = smooth, low performance)

-- === HELPERS ===
local function HasAnyExcludedTag(model)
	return HitboxExclusions.hasExcludedTag(model)
end

-- === WRAITH INITIALIZATION ===
local function initializeWraith(wraith, variantName)
	-- Default variant if not provided
	variantName = variantName or "Wraith_Sand"
	
	-- Apply stats to the wraith
	local statsApplied = MobStatsConfig.applyStats(wraith, variantName)
	if not statsApplied then
		warn("Wraith: Failed to apply stats for variant:", variantName)
	end
	
	local humanoid = wraith:WaitForChild("Humanoid")
	local root = wraith:FindFirstChild("HumanoidRootPart") or wraith.PrimaryPart
	
	if not root then
		warn("Wraith missing HumanoidRootPart:", wraith.Name)
		return
	end
	
	-- Ensure root is set as PrimaryPart
	wraith.PrimaryPart = root
	
	-- Find Head and Fire parts
	local head = wraith:FindFirstChild("Head")
	local fire = head and head:FindFirstChild("Fire") or head and head:FindFirstChildOfClass("Fire")
	
	if not head then
		warn("Wraith missing Head part:", wraith.Name)
		return
	end
	
	if not fire then
		warn("Wraith missing Fire in Head:", wraith.Name)
	end
	
	-- Add exclusion tag so wraiths don't damage each other
	CollectionService:AddTag(wraith, "wraith_entity")
	
	-- Create floating stats display GUI
	if MobStatsDisplay and MobStatsDisplay.createMobStatsDisplay then
		MobStatsDisplay.createMobStatsDisplay(wraith)
	end
	
	-- Store original ground Y position
	local groundY = root.Position.Y
	local currentY = groundY
	local targetY = groundY
	
	-- Initialize fire as off
	if fire then
		fire.Enabled = false
	end
	
	-- Get stats for damage and status ailment
	local stats = MobStatsConfig[variantName] or MobStatsConfig.Wraith_Sand
	if not stats then
		warn("Wraith: Invalid variant name, using default:", variantName)
		stats = MobStatsConfig.Wraith_Sand
	end
	local damage = stats.Damage or 25
	local statusAilment = stats.StatusAilment
	
	-- Wait for hitbox functions to be available
	while not _G.createTravelingHitbox do
		task.wait(0.1)
	end
	
	-- Attack tracking
	local lastAttack = 0
	local currentTarget = nil
	
	-- Function to shoot homing projectile
	local function shootHomingProjectile(target)
		if not target or not target.Parent then return end
		
		-- Create missile part
		local missile = Instance.new("Part")
		missile.Name = "WraithHomingMissile"
		missile.Size = Vector3.new(1, 1, 1)
		missile.CFrame = root.CFrame * CFrame.new(0, 1, -2)
		missile.Anchored = false
		missile.CanCollide = false
		missile.Material = Enum.Material.Neon
		missile.Color = Color3.new(1, 0.5, 0) -- Orange color for burn
		missile.Transparency = 0.3
		missile.Parent = workspace
		
		-- Add body velocity to missile
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		bodyVelocity.Velocity = root.CFrame.LookVector * MISSILE_SPEED
		bodyVelocity.Parent = missile
		
		-- Create traveling hitbox with burn status ailment
		_G.createTravelingHitbox({
			attachTo = missile,
			offset = CFrame.new(0, 0, 0),
			size = Vector3.new(6, 6, 6),
			damage = damage,
			character = wraith,
			name = "WraithHomingMissile",
			showVisual = true,
			visualColor = Color3.new(1, 0.5, 0), -- Orange color
			delay = 0,
			actionType = nil, -- Mobs don't have animation speeds
			classType = nil, -- Mobs don't have classes
			statusAilment = statusAilment -- Add burn status ailment from stats
		})
		
		-- Homing behavior - update direction towards target
		local homingConnection
		local startTime = tick()
		homingConnection = RunService.Heartbeat:Connect(function()
			if not missile or not missile.Parent then
				homingConnection:Disconnect()
				return
			end
			
			-- Check lifetime
			if tick() - startTime >= MISSILE_LIFETIME then
				homingConnection:Disconnect()
				missile:Destroy()
				return
			end
			
			-- Find current target (may have moved)
			local currentTargetPart = nil
			local nearestDist = 100
			for _, player in pairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local targetModel = player.Character
					-- Exclude the wraith itself and any excluded tags
					if targetModel ~= wraith and not HasAnyExcludedTag(targetModel) then
						local dist = (player.Character.HumanoidRootPart.Position - missile.Position).Magnitude
						if dist < nearestDist then
							nearestDist = dist
							currentTargetPart = player.Character.HumanoidRootPart
						end
					end
				end
			end
			
			if currentTargetPart then
				-- Update direction towards target
				local direction = (currentTargetPart.Position - missile.Position).Unit
				bodyVelocity.Velocity = direction * MISSILE_SPEED
			end
		end)
	end
	
	-- Rotation and attack loop - always face nearest player
	task.spawn(function()
		while task.wait(0.1) do
			if not wraith or not wraith.Parent or not humanoid or humanoid.Health <= 0 then
				break
			end
			
			local position = root.Position
			local nearest = nil
			local nearestDist = DETECTION_RANGE
			
			-- Find nearest player
			for _, player in pairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local targetModel = player.Character
					-- Exclude the wraith itself and any excluded tags
					if targetModel ~= wraith and not HasAnyExcludedTag(targetModel) then
						local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
						if dist < nearestDist then
							nearestDist = dist
							nearest = player.Character.HumanoidRootPart
						end
					end
				end
			end
			
			-- Face nearest player if found and control fire/attacks
			if nearest then
				-- Turn fire on when player detected
				if fire then
					fire.Enabled = true
				end
				
				-- Disable collision when floating
				root.CanCollide = false
				
				-- Float up
				targetY = groundY + FLOAT_HEIGHT
				
				currentTarget = nearest
				
				-- Attack if cooldown is ready
				if tick() - lastAttack >= ATTACK_COOLDOWN then
					lastAttack = tick()
					shootHomingProjectile(nearest)
				end
				
				local lookDirection = (nearest.Position - position).Unit
				if lookDirection.Magnitude > 0.1 then
					-- Only rotate on Y axis (horizontal rotation)
					local lookDirection2D = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
					local lookCFrame = CFrame.lookAt(root.Position, root.Position + lookDirection2D)
					root.CFrame = root.CFrame:Lerp(lookCFrame, 0.3)
				end
			else
				-- No player detected, turn fire off
				if fire then
					fire.Enabled = false
				end
				
				-- Enable collision before falling back down
				root.CanCollide = true
				
				-- Fall back down
				targetY = groundY
				
				currentTarget = nil
			end
			
			-- Simple lerp float - only affects Y position
			currentY = currentY + (targetY - currentY) * FLOAT_SPEED
			root.Position = Vector3.new(position.X, currentY, position.Z)
		end
	end)
end

-- === MODULE EXPORTS ===
local WraithAIModule = {}

function WraithAIModule.initializeWraith(model, variantName)
	initializeWraith(model, variantName)
end

function WraithAIModule.isInitialized(model)
	return false
end

return WraithAIModule
