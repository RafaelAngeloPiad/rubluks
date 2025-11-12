local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function applyCamera(character: Model)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	else
		local primary = character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart")
		if primary then
			camera.CameraSubject = primary
		end
	end

	camera.CameraType = Enum.CameraType.Custom
end

local function onCharacterAdded(character: Model)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if humanoid then
		applyCamera(character)
	else
		task.delay(0, function()
			applyCamera(character)
		end)
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)


