local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local chest = script.Parent
script.ChestLocalScript.Chest.Value = chest -- setting a value

local chestSpawnFolder = ReplicatedStorage:FindFirstChild("chestSpawn")

local mobTemplates = {}

local chestAnchored = false

local VALID_MOB_CLASSES = {
	Model = true,
}

local function populateMobTemplates()
	mobTemplates = {}

	if not chestSpawnFolder then
		return
	end

	for _, descendant in ipairs(chestSpawnFolder:GetDescendants()) do
		if VALID_MOB_CLASSES[descendant.ClassName] then
			local parent = descendant.Parent
			if parent and not parent:IsA("Model") then
				table.insert(mobTemplates, descendant)
			end
		end
	end
end

populateMobTemplates()

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

	-- Only spawn Models for mobs
	if clone:IsA("Model") then
		clone.Parent = Workspace
		local primary = ensurePrimaryPart(clone)
		local forwardUnit = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
		if primary then
			clone:PivotTo(CFrame.new(position, position + forwardUnit))
		else
			clone:MoveTo(position)
		end
	else
		warn("[ChestMobReward] Template is not a Model, skipping spawn.")
		return nil
	end

	return clone
end

local function spawnRandomMob(player)
	if not chestSpawnFolder then
		warn("[ChestMobReward] No chestSpawn folder found in ReplicatedStorage.")
		return
	end

	populateMobTemplates()

	if #mobTemplates == 0 then
		warn("[ChestMobReward] No templates were found in ReplicatedStorage.chestSpawn.")
		return
	end

	local selectedTemplate = mobTemplates[math.random(1, #mobTemplates)]
	if not selectedTemplate or not selectedTemplate.Parent then
		warn("[ChestMobReward] Selected mob template is no longer available.")
		return
	end

	local primaryPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		warn("[ChestMobReward] Chest has no PrimaryPart to determine spawn position.")
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
		print(("[ChestMobReward] Spawned '%s' for %s"):format(selectedTemplate.Name, player.Name))
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
			spawnRandomMob(player)
		end)
		task.delay(3, anchorChestParts)
	end
end

chest.LidToggle.OnServerEvent:Connect(OnLidToggle)