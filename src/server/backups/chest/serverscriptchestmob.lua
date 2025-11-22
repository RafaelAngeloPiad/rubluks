local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local chest = script.Parent
script.ChestLocalScript.Chest.Value = chest -- setting a value

local assetsFolder = ReplicatedStorage:FindFirstChild("Mobs")

local DEFAULT_REWARD_ASSET_PATH = "Sand Golem"
local rewardAssetPath = DEFAULT_REWARD_ASSET_PATH

local rewardAssetPathValue = chest:FindFirstChild("RewardAssetPath")
if not rewardAssetPathValue and chest:FindFirstChild("Configurations") then
	rewardAssetPathValue = chest.Configurations:FindFirstChild("RewardAssetPath")
end

if rewardAssetPathValue and rewardAssetPathValue:IsA("StringValue") then
	local trimmed = string.gsub(rewardAssetPathValue.Value or "", "^%s*(.-)%s*$", "%1")
	if trimmed ~= "" then
		rewardAssetPath = trimmed
	end
end

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

local function resolveFromFolder(root, path)
	if not root or not path or path == "" then
		return nil
	end

	local current = root
	for segment in string.gmatch(path, "[^/]+") do
		if not current then
			return nil
		end
		current = current:FindFirstChild(segment)
	end

	return current
end

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

local function spawnConfiguredReward(player)
	if not rewardAssetPath or rewardAssetPath == "" then
		return
	end

	if not assetsFolder then
		warn("[ChestReward] No assets folder found in ReplicatedStorage.")
		return
	end

	local template = resolveFromFolder(assetsFolder, rewardAssetPath)
	if not template then
		warn(("[ChestReward] Asset '%s' was not found in ReplicatedStorage.assets."):format(rewardAssetPath))
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

	local spawned = spawnTemplateAtPosition(template, spawnPosition, forwardUnit)

	if spawned and RunService:IsStudio() then
		print(("[ChestReward] Spawned '%s' for %s"):format(template.Name, player.Name))
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
		task.delay(2, function()
			spawnConfiguredReward(player)
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