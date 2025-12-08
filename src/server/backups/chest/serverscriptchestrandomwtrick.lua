local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local chest = script.Parent
script.ChestLocalScript.Chest.Value = chest -- setting a value

local chestSpawnFolder = ReplicatedStorage:FindFirstChild("chestSpawn")

local rewardTemplates = {}

local reward
if chest:FindFirstChild("Reward") then
	local rewardChildren = chest.Reward:GetChildren()
	if #rewardChildren > 0 then
		local originalReward = rewardChildren[1]
		reward = originalReward:Clone()
		local newModel = Instance.new("Model")
		newModel.Name = originalReward.Name
		newModel.Parent = chest.Reward
		for _, child in pairs(originalReward:GetChildren()) do
			if not (child:IsA("Script") or child:IsA("LocalScript")) then
				if child:IsA("BasePart") then
					child.Anchored = true
				end
				child.Parent = newModel
			else
				child:Destroy()
			end
		end
	end
end

local chestAnchored = false

local VALID_TEMPLATE_CLASSES = {
	Model = true,
	Tool = true,
	BasePart = true,
	Accessory = true,
}

local function populateRewardTemplates()
	rewardTemplates = {}

	if not chestSpawnFolder then
		return
	end

	for _, descendant in ipairs(chestSpawnFolder:GetDescendants()) do
		if VALID_TEMPLATE_CLASSES[descendant.ClassName] then
			local parent = descendant.Parent
			if parent and not parent:IsA("Model") and not parent:IsA("Tool") then
				table.insert(rewardTemplates, descendant)
			end
		end
	end
end

populateRewardTemplates()

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
local function ensurePrimaryPart(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local humanoidRoot = model:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and humanoidRoot:IsA("BasePart") then
		model.PrimaryPart = humanoidRoot
		return humanoidRoot
	end

	local basePart = model:FindFirstChildWhichIsA("BasePart")
	if basePart then
		model.PrimaryPart = basePart
		return basePart
	end

	return nil
end

local function spawnTemplateAtPosition(template, position, forward)
	local clone = template:Clone()
	clone.Name = template.Name

	if clone:IsA("Tool") then
		clone.Parent = Workspace
		local handle = clone:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local forwardUnit = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
			handle.CFrame = CFrame.new(position, position + forwardUnit)
		end
	elseif clone:IsA("Model") then
		clone.Parent = Workspace
		local primary = ensurePrimaryPart(clone)
		local forwardUnit = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
		if primary then
			clone:PivotTo(CFrame.new(position, position + forwardUnit))
		else
			clone:MoveTo(position)
		end
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new(position)
		clone.Parent = Workspace
	else
		clone.Parent = Workspace
	end

	return clone
end

local function spawnRandomReward(player)
	if not chestSpawnFolder then
		warn("[ChestReward] No chestSpawn folder found in ReplicatedStorage.")
		return
	end

	populateRewardTemplates()

	if #rewardTemplates == 0 then
		warn("[ChestReward] No templates were found in ReplicatedStorage.chestSpawn.")
		return
	end

	local selectedTemplate = rewardTemplates[math.random(1, #rewardTemplates)]
	if not selectedTemplate or not selectedTemplate.Parent then
		warn("[ChestReward] Selected reward template is no longer available.")
		return
	end

	local primaryPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		warn("[ChestReward] Chest has no PrimaryPart to determine spawn position.")
		return
	end

	local forward = primaryPart.CFrame.LookVector
	local forwardUnit = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)

	local chestHalfHeight = 0
	if primaryPart:IsA("BasePart") then
		chestHalfHeight = primaryPart.Size.Y * 0.5
	end

	local spawnOffset = Vector3.new(0, chestHalfHeight + 2, 0)
	local spawnPosition = primaryPart.Position + spawnOffset

	local spawned = spawnTemplateAtPosition(selectedTemplate, spawnPosition, forwardUnit)

	if spawned and RunService:IsStudio() then
		print(("[ChestReward] Spawned '%s' for %s"):format(selectedTemplate.Name, player.Name))
	end
end

local function spawnRandomMob(player)
	if not chestSpawnFolder then
		warn("[ChestReward] No chestSpawn folder found in ReplicatedStorage.")
		return
	end

	populateRewardTemplates()

	if #rewardTemplates == 0 then
		warn("[ChestReward] No templates were found in ReplicatedStorage.chestSpawn.")
		return
	end

	local selectedTemplate = rewardTemplates[math.random(1, #rewardTemplates)]
	if not selectedTemplate or not selectedTemplate.Parent then
		warn("[ChestReward] Selected mob template is no longer available.")
		return
	end

	local primaryPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		warn("[ChestReward] Chest has no PrimaryPart to determine spawn position.")
		return
	end

	local forward = primaryPart.CFrame.LookVector
	local forwardUnit = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)

	local chestHalfHeight = 0
	if primaryPart:IsA("BasePart") then
		chestHalfHeight = primaryPart.Size.Y * 0.5
	end

	local spawnOffset = Vector3.new(0, chestHalfHeight + 2, 0)
	local spawnPosition = primaryPart.Position + spawnOffset

	local spawned = spawnTemplateAtPosition(selectedTemplate, spawnPosition, forwardUnit)

	if spawned and RunService:IsStudio() then
		print(("[ChestReward] Spawned mob '%s' for %s"):format(selectedTemplate.Name, player.Name))
	end
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
				warn("[ChestRandom] Error creating slavkoin gain number:", err)
			end
		end)

		if RunService:IsStudio() then
			print(("[ChestRandom] Granted %d slavkoins to %s"):format(slavkoinGain, player.Name))
		end
	end
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

OnLidToggle = function(player)
	if lidOpen == false then
		hinge.BodyGyro.cframe = hinge.BodyGyro.cframe * CFrame.Angles(0, 0, math.rad(-170))
		lidOpen = true
		
		-- Randomly choose between spawning a reward item, mob, or giving slavkoins
		-- 33% chance for each (can be adjusted)
		local rewardType = math.random(1, 3)
		
		task.delay(2, function()
			if rewardType == 1 then
				-- Spawn random reward item
				spawnRandomReward(player)
			elseif rewardType == 2 then
				-- Spawn random mob
				spawnRandomMob(player)
			else
				-- Grant slavkoins
				grantSlavkoins(player)
			end
		end)
		task.delay(3, anchorChestParts)
	end

	if reward and player.Character and player.Character:FindFirstChild("Humanoid") then
		if not player.Backpack:FindFirstChild(reward.Name) and not player.Character:FindFirstChild(reward.Name) then
			local toGive = reward:Clone()
			for _, child in pairs(toGive:GetChildren()) do
				if child:IsA("BasePart") then
					child.Anchored = false
				end
			end

			if not game.StarterPack:FindFirstChild(reward.Name) then
				toGive:Clone().Parent = game.StarterPack
			end
			player.Character.Humanoid:UnequipTools()
			toGive.Parent = player.Backpack
			player.Character.Humanoid:EquipTool(toGive)
		end
	end


end

chest.LidToggle.OnServerEvent:Connect(OnLidToggle)