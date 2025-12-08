local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ActionEvent = ReplicatedStorage:WaitForChild("ActionEvent")

-- Simple "please wait" overlay while global input is locked
local PlayerGui = player:WaitForChild("PlayerGui")

local overlayGui: ScreenGui? = nil

local function ensureOverlay()
	if overlayGui and overlayGui.Parent then
		return overlayGui
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "GlobalInputLockOverlay"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	background.BackgroundTransparency = 0.35
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = gui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.new(0, 420, 0, 120)
	container.BackgroundTransparency = 1
	container.Parent = background

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(235, 235, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Preparing your hero..."
	title.Parent = container

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.BackgroundTransparency = 1
	message.Size = UDim2.new(1, -20, 0, 40)
	message.Position = UDim2.new(0, 10, 0, 52)
	message.Font = Enum.Font.Gotham
	message.TextSize = 20
	message.TextColor3 = Color3.fromRGB(210, 210, 230)
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextWrapped = true
	message.Text = "Please wait, your hero is equipping weapons, consumables and helmet..."
	message.Parent = container

	gui.Parent = PlayerGui
	overlayGui = gui

	return gui
end

local function showOverlay()
	local gui = ensureOverlay()
	gui.Enabled = true
end

local function hideOverlay()
	if overlayGui then
		overlayGui.Enabled = false
	end
end

-- Initialise PlayerModule and Controls once, globally.
local function getControls()
	local playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
	return playerModule:GetControls()
end

local controls = getControls()
local lockCount = 0
local wasLocked = false

local function applyLockState()
	if not controls then
		return
	end

	local isLocked = lockCount > 0
	
	if isLocked then
		showOverlay()
		controls:Disable()
		-- Notify server to enable invincibility (only if state changed)
		if not wasLocked then
			ActionEvent:FireServer("global_lock_input")
		end
	else
		hideOverlay()
		controls:Enable()
		-- Notify server to disable invincibility (only if state changed)
		if wasLocked then
			ActionEvent:FireServer("global_unlock_input")
		end
	end
	
	wasLocked = isLocked
end

-- Global input lock for systems like InventoryManager.
-- Uses its own message names so it doesn't interfere with
-- per-class action scripts that also listen for "lock_input".
ActionEvent.OnClientEvent:Connect(function(message)
	if message == "global_lock_input" then
		lockCount += 1
		applyLockState()
	elseif message == "global_unlock_input" then
		if lockCount > 0 then
			lockCount -= 1
			applyLockState()
		end
	end
end)


