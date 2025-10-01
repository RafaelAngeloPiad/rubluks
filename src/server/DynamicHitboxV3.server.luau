-- ========================================
-- DYNAMIC HITBOX V3 - FULLY SERVER SIDE
-- Modular hitbox system with part attachment
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ========================================
-- GLOBAL FUNCTIONS
-- ========================================

-- Static hitbox at a fixed position
function _G.createStaticHitbox(config)
	-- config: cframe OR attachTo, size, damage, duration, character, name, showVisual, visualColor, offset
	local cframe = config.cframe
	local attachTo = config.attachTo
	local offset = config.offset or CFrame.new(0, 0, 0)
	local size = config.size or Vector3.new(8, 8, 8)
	local damage = config.damage or 25
	local duration = config.duration or 0.5
	local character = config.character
	local name = config.name or "Static"
	local showVisual = config.showVisual ~= false
	local visualColor = config.visualColor or Color3.new(1, 0, 0)
	
	-- If attachTo is provided, use its CFrame with offset
	if attachTo and not cframe then
		cframe = attachTo.CFrame * offset
	elseif not cframe then
		warn("[HITBOX V3] Static hitbox needs either cframe or attachTo")
		return
	end
	
	-- Create visual
	local visual = nil
	if showVisual then
		visual = Instance.new("Part")
		visual.Size = size
		visual.CFrame = cframe
		visual.Anchored = true
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.Material = Enum.Material.Neon
		visual.Transparency = 0.6
		visual.Color = visualColor
		visual.Name = name .. "HitboxVisual"
		visual.Parent = workspace
		
		game:GetService("Debris"):AddItem(visual, duration)
	end
	
	-- Check for hits once
	local regionParts = workspace:GetPartBoundsInBox(cframe, size)
	
	for _, part in regionParts do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model ~= character then
			local humanoid = model:FindFirstChild("Humanoid")
			
			if humanoid then
				humanoid:TakeDamage(damage)
				
				-- Flash visual
				if visual then
					visual.Color = Color3.new(1, 1, 1)
					task.delay(0.05, function()
						if visual and visual.Parent then
							visual.Color = visualColor
						end
					end)
				end
			end
		end
	end
end

-- Traveling hitbox attached to a moving part
function _G.createTravelingHitbox(config)
	-- config: attachTo (BasePart), size, damage, duration, character, name, showVisual, visualColor
	local attachTo = config.attachTo
	local size = config.size or Vector3.new(8, 8, 8)
	local damage = config.damage or 25
	local duration = config.duration or 2
	local character = config.character
	local name = config.name or "Traveling"
	local showVisual = config.showVisual ~= false
	local visualColor = config.visualColor or Color3.new(0, 0.5, 1)
	
	if not attachTo then
		warn("[HITBOX V3] No attachTo part provided for traveling hitbox")
		return
	end
	
	local hitTargets = {}
	local startTime = tick()
	
	-- Create visual
	local visual = nil
	if showVisual then
		visual = Instance.new("Part")
		visual.Size = size
		visual.Anchored = true
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.Material = Enum.Material.Neon
		visual.Transparency = 0.6
		visual.Color = visualColor
		visual.Name = name .. "HitboxVisual"
		visual.Parent = workspace
	end
	
	-- Track hitbox with part
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		
		-- Stop if duration expired or part destroyed
		if elapsed >= duration or not attachTo or not attachTo.Parent then
			connection:Disconnect()
			if visual then
				visual:Destroy()
			end
			return
		end
		
		-- Update visual position to match attached part
		if visual then
			visual.CFrame = attachTo.CFrame
		end
		
		-- Check for hits at current position
		local regionParts = workspace:GetPartBoundsInBox(attachTo.CFrame, size)
		
		for _, part in regionParts do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and model ~= character then
				local humanoid = model:FindFirstChild("Humanoid")
				
				if humanoid and not hitTargets[humanoid] then
					hitTargets[humanoid] = true
					humanoid:TakeDamage(damage)
					
					-- Flash visual on hit
					if visual then
						visual.Color = Color3.new(1, 0, 0)
						task.delay(0.1, function()
							if visual and visual.Parent then
								visual.Color = visualColor
							end
						end)
					end
				end
			end
		end
	end)
end

-- Projectile hitbox that travels in a direction
function _G.createProjectileHitbox(config)
	-- config: startCFrame, size, damage, speed, maxDistance, character, name, showVisual, visualColor, projectileSize
	local startCFrame = config.startCFrame
	local size = config.size or Vector3.new(8, 8, 8)
	local damage = config.damage or 50
	local speed = config.speed or 150
	local maxDistance = config.maxDistance or 100
	local character = config.character
	local name = config.name or "Projectile"
	local showVisual = config.showVisual ~= false
	local visualColor = config.visualColor or Color3.new(1, 1, 0)
	local projectileSize = config.projectileSize or Vector3.new(1, 1, 3)
	
	local startPos = startCFrame.Position
	local direction = startCFrame.LookVector
	
	-- Create projectile visual
	local projectile = nil
	if showVisual then
		projectile = Instance.new("Part")
		projectile.Size = projectileSize
		projectile.CFrame = startCFrame
		projectile.Anchored = true
		projectile.CanCollide = false
		projectile.CanQuery = false
		projectile.CanTouch = false
		projectile.Material = Enum.Material.Neon
		projectile.Transparency = 0.3
		projectile.Color = visualColor
		projectile.Name = name .. "Projectile"
		projectile.Parent = workspace
	end
	
	local startTime = tick()
	local hit = false
	
	-- Move projectile
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if hit then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		local distanceTraveled = speed * elapsed
		
		-- Stop if max distance reached
		if distanceTraveled >= maxDistance then
			connection:Disconnect()
			if projectile then
				projectile:Destroy()
			end
			return
		end
		
		-- Update position
		local currentPos = startPos + (direction * distanceTraveled)
		local currentCFrame = CFrame.new(currentPos, currentPos + direction)
		
		if projectile then
			projectile.CFrame = currentCFrame
		end
		
		-- Check for hits
		local regionParts = workspace:GetPartBoundsInBox(currentCFrame, size)
		
		for _, part in regionParts do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and model ~= character then
				local humanoid = model:FindFirstChild("Humanoid")
				
				if humanoid then
					hit = true
					humanoid:TakeDamage(damage)
					
					-- Create hit visual
					local hitVisual = Instance.new("Part")
					hitVisual.Size = size
					hitVisual.CFrame = currentCFrame
					hitVisual.Anchored = true
					hitVisual.CanCollide = false
					hitVisual.Material = Enum.Material.Neon
					hitVisual.Transparency = 0.5
					hitVisual.Color = Color3.new(1, 0, 0)
					hitVisual.Name = name .. "HitEffect"
					hitVisual.Parent = workspace
					
					game:GetService("Debris"):AddItem(hitVisual, 0.3)
					
					if projectile then
						projectile:Destroy()
					end
					
					connection:Disconnect()
					return
				end
			end
		end
	end)
end

print("[HITBOX V3] Server-side hitbox system loaded")
print("[HITBOX V3] Available functions: _G.createStaticHitbox, _G.createTravelingHitbox, _G.createProjectileHitbox")

