-- ========================================
-- KEYBIND DISPLAY GUI
-- Shows current weapon keybinds in bottom-left corner
-- Supports Archer and Samurai weapons
-- ========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI Elements
local keybindGui = nil
local keybindFrame = nil
local currentWeapon = nil

-- Weapon configurations (copied from each weapon's CONFIG)
local WEAPON_CONFIGS = {
	archer_wpn = {
		name = "Archer",
		actions = {
			[Enum.KeyCode.Q] = "Piercing Shot",
			[Enum.KeyCode.E] = "Power Shot",
			[Enum.KeyCode.X] = "Hunter Instinct",
			[Enum.KeyCode.C] = "Hunter Mark",
			[Enum.KeyCode.Z] = "Starfall",
		},
		keybinds = {
			attack = {key = "Left Click", name = "Attack"},
			block = {key = "V", name = "Block"},
			jump = {key = "Space", name = "Jump"},
			wave = {key = "L", name = "Wave (Global)"},
			aimLockToggle = {key = "T", name = "Aim Toggle"},
			dynamicAim = {key = "F", name = "Aim"},
		}
	},
	samurai_wpn = {
		name = "Samurai",
		actions = {
			[Enum.KeyCode.E] = "Kozuki",
			[Enum.KeyCode.Q] = "Wakizashi",
			[Enum.KeyCode.X] = "Banzai",
			[Enum.KeyCode.Z] = "Bushido",
			[Enum.KeyCode.C] = "Zantetsuken",
		},
		keybinds = {
			attack = {key = "Left Click", name = "Attack"},
			block = {key = "V", name = "Block"},
			jump = {key = "Space", name = "Jump"},
			wave = {key = "L", name = "Wave (Global)"},
		}
	}
}

-- Create the keybind display GUI
local function createKeybindGui()
	if keybindGui then
		keybindGui:Destroy()
	end
	
	keybindGui = Instance.new("ScreenGui")
	keybindGui.Name = "KeybindDisplay"
	keybindGui.ResetOnSpawn = false
	keybindGui.Parent = playerGui
	
	-- Main frame (much smaller)
	keybindFrame = Instance.new("Frame")
	keybindFrame.Name = "KeybindFrame"
	keybindFrame.Size = UDim2.new(0, 180, 0, 120)
	keybindFrame.Position = UDim2.new(0, 10, 1, -130) -- Bottom left
	keybindFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	keybindFrame.BackgroundTransparency = 0.3
	keybindFrame.BorderSizePixel = 0
	keybindFrame.Parent = keybindGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = keybindFrame
	
	-- Add stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = keybindFrame
	
	-- Title (smaller)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Keybinds"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = keybindFrame
	
	-- Scrolling frame for keybinds (smaller)
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Size = UDim2.new(1, -10, 1, -30)
	scrollingFrame.Position = UDim2.new(0, 5, 0, 25)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.ScrollBarThickness = 2
	scrollingFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
	scrollingFrame.ScrollBarImageTransparency = 0.7
	scrollingFrame.Parent = keybindFrame
	
	-- List layout for keybinds
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = scrollingFrame
	
	-- Scrolling frame is stored as a child of keybindFrame
end

-- Update keybind display with current weapon
local function updateKeybindDisplay(weaponTag)
	print("KeybindDisplay: Updating display for weapon:", weaponTag)
	
	if not keybindGui or not keybindFrame then 
		print("KeybindDisplay: GUI not created yet")
		return 
	end
	
	local config = WEAPON_CONFIGS[weaponTag]
	if not config then
		print("KeybindDisplay: No config found for weapon:", weaponTag)
		-- Hide GUI if weapon not supported
		keybindGui.Enabled = false
		return
	end
	
	print("KeybindDisplay: Found config for", config.name)
	-- Show GUI
	keybindGui.Enabled = true
	
	-- Update title
	local titleLabel = keybindFrame:FindFirstChild("TitleLabel")
	if titleLabel then
		titleLabel.Text = config.name .. " Keybinds"
	end
	
	-- Clear existing keybinds
	local scrollingFrame = keybindFrame:FindFirstChild("ScrollingFrame")
	if not scrollingFrame then
		print("KeybindDisplay: ScrollingFrame not found!")
		return
	end
	
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Add skills section (smaller)
	local skillsFrame = Instance.new("Frame")
	skillsFrame.Name = "SkillsFrame"
	skillsFrame.Size = UDim2.new(1, 0, 0, 15)
	skillsFrame.BackgroundTransparency = 1
	skillsFrame.LayoutOrder = 1
	skillsFrame.Parent = scrollingFrame
	
	local skillsLabel = Instance.new("TextLabel")
	skillsLabel.Size = UDim2.new(1, 0, 1, 0)
	skillsLabel.BackgroundTransparency = 1
	skillsLabel.Text = "Skills:"
	skillsLabel.TextColor3 = Color3.new(0.7, 0.7, 1)
	skillsLabel.TextScaled = true
	skillsLabel.Font = Enum.Font.Gotham
	skillsLabel.TextXAlignment = Enum.TextXAlignment.Left
	skillsLabel.Parent = skillsFrame
	
	-- Add skills (smaller)
	local skillOrder = 2
	for keyCode, skillName in pairs(config.actions) do
		local keybindFrame = Instance.new("Frame")
		keybindFrame.Name = "KeybindFrame"
		keybindFrame.Size = UDim2.new(1, 0, 0, 12)
		keybindFrame.BackgroundTransparency = 1
		keybindFrame.LayoutOrder = skillOrder
		keybindFrame.Parent = scrollingFrame
		
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Size = UDim2.new(0, 25, 1, 0)
		keyLabel.Position = UDim2.new(0, 0, 0, 0)
		keyLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		keyLabel.BackgroundTransparency = 0.3
		keyLabel.Text = tostring(keyCode):gsub("Enum.KeyCode.", "")
		keyLabel.TextColor3 = Color3.new(1, 1, 1)
		keyLabel.TextScaled = true
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.Parent = keybindFrame
		
		local keyCorner = Instance.new("UICorner")
		keyCorner.CornerRadius = UDim.new(0, 4)
		keyCorner.Parent = keyLabel
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -30, 1, 0)
		nameLabel.Position = UDim2.new(0, 30, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = skillName
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = keybindFrame
		
		skillOrder = skillOrder + 1
	end
	
	-- Add basic actions section (smaller)
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "ActionsFrame"
	actionsFrame.Size = UDim2.new(1, 0, 0, 15)
	actionsFrame.BackgroundTransparency = 1
	actionsFrame.LayoutOrder = skillOrder
	actionsFrame.Parent = scrollingFrame
	
	local actionsLabel = Instance.new("TextLabel")
	actionsLabel.Size = UDim2.new(1, 0, 1, 0)
	actionsLabel.BackgroundTransparency = 1
	actionsLabel.Text = "Actions:"
	actionsLabel.TextColor3 = Color3.new(0.7, 1, 0.7)
	actionsLabel.TextScaled = true
	actionsLabel.Font = Enum.Font.Gotham
	actionsLabel.TextXAlignment = Enum.TextXAlignment.Left
	actionsLabel.Parent = actionsFrame
	
	-- Add basic actions (smaller)
	local actionOrder = skillOrder + 1
	for keyName, keyData in pairs(config.keybinds) do
		local keybindFrame = Instance.new("Frame")
		keybindFrame.Name = "KeybindFrame"
		keybindFrame.Size = UDim2.new(1, 0, 0, 12)
		keybindFrame.BackgroundTransparency = 1
		keybindFrame.LayoutOrder = actionOrder
		keybindFrame.Parent = scrollingFrame
		
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Size = UDim2.new(0, 25, 1, 0)
		keyLabel.Position = UDim2.new(0, 0, 0, 0)
		keyLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		keyLabel.BackgroundTransparency = 0.3
		keyLabel.Text = keyData.key
		keyLabel.TextColor3 = Color3.new(1, 1, 1)
		keyLabel.TextScaled = true
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.Parent = keybindFrame
		
		local keyCorner = Instance.new("UICorner")
		keyCorner.CornerRadius = UDim.new(0, 4)
		keyCorner.Parent = keyLabel
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -30, 1, 0)
		nameLabel.Position = UDim2.new(0, 30, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = keyData.name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = keybindFrame
		
		actionOrder = actionOrder + 1
	end
	
	-- Update canvas size
	local listLayout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end

end

-- Detect weapon changes (same pattern as archer/samurai)
local function onCharacterAdded(character)
	print("KeybindDisplay: Character added, checking for weapons...")
	-- Check for existing weapons
	for _, weaponTool in character:GetChildren() do
		if weaponTool:IsA("Tool") then
			print("KeybindDisplay: Found tool:", weaponTool.Name)
			-- Check archer weapon
			if CollectionService:HasTag(weaponTool, "archer_wpn") then
				print("KeybindDisplay: Found archer weapon!")
				currentWeapon = "archer_wpn"
				updateKeybindDisplay("archer_wpn")
				return
			end
			-- Check samurai weapon
			if CollectionService:HasTag(weaponTool, "samurai_wpn") then
				print("KeybindDisplay: Found samurai weapon!")
				currentWeapon = "samurai_wpn"
				updateKeybindDisplay("samurai_wpn")
				return
			end
		end
	end
	print("KeybindDisplay: No weapons found on character")
	
	-- Listen for weapon equipped
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("Tool") then
			print("KeybindDisplay: Tool equipped:", desc.Name)
			-- Check archer weapon
			if CollectionService:HasTag(desc, "archer_wpn") then
				print("KeybindDisplay: Archer weapon equipped!")
				currentWeapon = "archer_wpn"
				updateKeybindDisplay("archer_wpn")
			-- Check samurai weapon
			elseif CollectionService:HasTag(desc, "samurai_wpn") then
				print("KeybindDisplay: Samurai weapon equipped!")
				currentWeapon = "samurai_wpn"
				updateKeybindDisplay("samurai_wpn")
			end
		end
	end)
	
	-- Listen for weapon unequipped
	character.DescendantRemoving:Connect(function(desc)
		if desc:IsA("Tool") and currentWeapon then
			if CollectionService:HasTag(desc, "archer_wpn") or CollectionService:HasTag(desc, "samurai_wpn") then
				currentWeapon = nil
				keybindGui.Enabled = false
			end
		end
	end)
end

-- Initialize
createKeybindGui()

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
