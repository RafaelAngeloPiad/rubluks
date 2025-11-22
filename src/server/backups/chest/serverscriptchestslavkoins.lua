local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local chest = script.Parent
script.ChestLocalScript.Chest.Value = chest -- setting a value

local chestAnchored = false

local function anchorChestParts()
	if chestAnchored then
		return
	end

	for _, descendant in ipairs(chest:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end

	chestAnchored = true
end

local OnLidToggle

local function onChestTouched(obj)
	local player = Players:GetPlayerFromCharacter(obj.Parent)
	if player then
		OnLidToggle(player)
	end
end

local chestHitBox = Instance.new("Part")
chestHitBox.Size = Vector3.new(5, 3, 4)
chestHitBox.Anchored = true
chestHitBox.CanCollide = false
chestHitBox.Transparency = 1
chestHitBox.CFrame = (chest.PrimaryPart.CFrame + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, math.pi / 2, 0)
chestHitBox.Name = "ChestHitBox"
chestHitBox.Parent = chest

chestHitBox.Touched:Connect(onChestTouched)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if chest.Configurations.StaticObject.Value == false then
			local newScript = script.ChestLocalScript:Clone()
			newScript.Parent = player.PlayerGui
		end
	end)
end)

local hinge = chest.Lid.HingePart -- making it easier to access this part
local lidOpen = false -- so we know if the chest is open or closed

if chest.Configurations.StaticObject.Value == false then -- checking if this chest is supposed to open
	hinge.BodyPosition.position = Vector3.new(hinge.Position.X, hinge.Position.Y, hinge.Position.Z)
	hinge.BodyGyro.cframe = hinge.CFrame
	for _, v in pairs(chest.Lid:GetChildren()) do
		v.Anchored = false
	end
else
	chest.Lid.Lock.ClickDetector.MaxActivationDistance = 0
end

-- Function to grant slavkoins to player when chest opens
local function grantSlavkoins(player)
	if not player then
		return
	end

	-- Get slavkoin range from chest attributes or configuration
	local minSlavkoins = 5  -- Default minimum
	local maxSlavkoins = 500  -- Default maximum

	-- Check for attributes on the chest
	local minValue = chest:GetAttribute("SlavkoinMin")
	local maxValue = chest:GetAttribute("SlavkoinMax")

	-- Also check in Configurations folder if attributes don't exist
	if minValue == nil and chest:FindFirstChild("Configurations") then
		local minConfig = chest.Configurations:FindFirstChild("SlavkoinMin")
		if minConfig and minConfig:IsA("NumberValue") then
			minValue = minConfig.Value
		end
	end

	if maxValue == nil and chest:FindFirstChild("Configurations") then
		local maxConfig = chest.Configurations:FindFirstChild("SlavkoinMax")
		if maxConfig and maxConfig:IsA("NumberValue") then
			maxValue = maxConfig.Value
		end
	end

	-- Use configured values or defaults
	if minValue and minValue > 0 then
		minSlavkoins = minValue
	end
	if maxValue and maxValue > 0 then
		maxSlavkoins = maxValue
	end

	-- Ensure min is not greater than max
	if minSlavkoins > maxSlavkoins then
		minSlavkoins = maxSlavkoins
	end

	-- Calculate random slavkoin amount
	local slavkoinGain = math.random(minSlavkoins, maxSlavkoins)

	-- Get player's leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	-- Add slavkoins to player
	local slavkoins = leaderstats:FindFirstChild("Slavkoins")
	if slavkoins then
		slavkoins.Value = slavkoins.Value + slavkoinGain

		-- Show visual number (if function exists)
		task.spawn(function()
			local success, err = pcall(function()
				if _G.createSlavkoinGainNumber then
					_G.createSlavkoinGainNumber(player, slavkoinGain)
				end
			end)
			if not success then
				warn("[ChestSlavkoins] Error creating slavkoin gain number:", err)
			end
		end)

		if RunService:IsStudio() then
			print(("[ChestSlavkoins] Granted %d slavkoins to %s"):format(slavkoinGain, player.Name))
		end
	end
end

OnLidToggle = function(player)
	if lidOpen == false then
		hinge.BodyGyro.cframe = hinge.BodyGyro.cframe * CFrame.Angles(0, 0, math.rad(-170))
		lidOpen = true
		
		-- Grant slavkoins immediately when chest opens
		grantSlavkoins(player)
		
		-- Anchor chest parts after opening
		task.delay(3, anchorChestParts)
	end
end

chest.LidToggle.OnServerEvent:Connect(OnLidToggle)