local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowButtonPrompt = ReplicatedStorage:WaitForChild("ShowButtonPromptSamurai")
local EquipSamuraiClass = ReplicatedStorage:WaitForChild("EquipSamuraiClass")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Utility function to check if Archer tool is present in Backpack or Character
local function hasSamuraiTool()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, tool in backpack:GetChildren() do
			if tool:IsA("Tool") and string.find(tool.Name, "Samurai") then
				return true
			end
		end
	end
	local character = LocalPlayer.Character
	if character then
		for _, tool in character:GetChildren() do
			if tool:IsA("Tool") and string.find(tool.Name, "Samurai") then
				return true
			end
		end
	end
	return false
end

-- State flag to prevent repeated prompts
local samuraiToolEquipped = false

-- Function to update the flag when tool is added/removed
local function updateSamuraiToolFlag()
	samuraiToolEquipped = hasSamuraiTool()
end

-- Listen for Backpack and Character changes
local function setupToolListeners()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(updateSamuraiToolFlag)
		backpack.ChildRemoved:Connect(updateSamuraiToolFlag)
	end
	LocalPlayer.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(updateSamuraiToolFlag)
		character.ChildRemoved:Connect(updateSamuraiToolFlag)
		-- Initial check when character spawns
		updateSamuraiToolFlag()
	end)
	-- Initial check for current character
	if LocalPlayer.Character then
		LocalPlayer.Character.ChildAdded:Connect(updateSamuraiToolFlag)
		LocalPlayer.Character.ChildRemoved:Connect(updateSamuraiToolFlag)
	end
end

setupToolListeners()
updateSamuraiToolFlag()

ShowButtonPrompt.OnClientEvent:Connect(function()
	updateSamuraiToolFlag()
	if samuraiToolEquipped then
		-- Don't show prompt if Archer tool is equipped
		return
	end

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	-- Remove any existing ButtonPromptGui1 before creating a new one
	local oldGui = playerGui:FindFirstChild("ButtonPromptGui1")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ButtonPromptGui1"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.Position = UDim2.new(0.5, -150, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 2
	frame.Parent = screenGui

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 0.5, 0)
	textLabel.Position = UDim2.new(0, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "Do you want to become an Samurai?"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Parent = frame

	local yesButton = Instance.new("TextButton")
	yesButton.Size = UDim2.new(0.4, 0, 0.3, 0)
	yesButton.Position = UDim2.new(0.1, 0, 0.6, 0)
	yesButton.Text = "Yes"
	yesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	yesButton.TextColor3 = Color3.new(1, 1, 1)
	yesButton.TextScaled = true
	yesButton.Parent = frame

	local noButton = Instance.new("TextButton")
	noButton.Size = UDim2.new(0.4, 0, 0.3, 0)
	noButton.Position = UDim2.new(0.5, 0, 0.6, 0)
	noButton.Text = "No"
	noButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	noButton.TextColor3 = Color3.new(1, 1, 1)
	noButton.TextScaled = true
	noButton.Parent = frame

	local function removePromptGui()
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end
		-- Extra safety: remove any lingering ButtonPromptGui1
		local lingeringGui = playerGui:FindFirstChild("ButtonPromptGui1")
		if lingeringGui then
			lingeringGui:Destroy()
		end
	end

	yesButton.MouseButton1Click:Connect(function()
		removePromptGui()
		EquipSamuraiClass:FireServer()
		-- Set flag so prompt won't show again until tool is removed
		samuraiToolEquipped = true
	end)

	noButton.MouseButton1Click:Connect(function()
		removePromptGui()
		-- No logic for No yet, but can be added here if needed
	end)

	screenGui.Parent = playerGui
end)

-- Listen for tool removal to allow prompt again
local function monitorToolRemoval()
	local function checkToolRemoved()
		if not hasSamuraiTool() then
			samuraiToolEquipped = false
		end
	end
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildRemoved:Connect(checkToolRemoved)
	end
	LocalPlayer.CharacterAdded:Connect(function(character)
		character.ChildRemoved:Connect(checkToolRemoved)
	end)
	if LocalPlayer.Character then
		LocalPlayer.Character.ChildRemoved:Connect(checkToolRemoved)
	end
end

monitorToolRemoval()

