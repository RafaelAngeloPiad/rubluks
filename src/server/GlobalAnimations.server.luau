-- ========================================
-- GLOBAL ANIMATIONS SERVER
-- Handles animations that work for ALL players
-- regardless of equipped weapon or class
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote setup
local remote = ReplicatedStorage:WaitForChild("ActionEvent")

-- Store player animation data
local playerAnimationData = {}

-- ========================================
-- GLOBAL ANIMATION CONFIGURATION
-- ========================================

_G.GLOBAL_ANIMATION_SPEEDS = {
	wave = 1.0, -- Wave emote speed
}

-- Function to apply animation speed
local function applyAnimationSpeed(animTrack, actionType)
	if not animTrack or not actionType then return end
	
	local speed = _G.GLOBAL_ANIMATION_SPEEDS[actionType] or 1.0
	animTrack:AdjustSpeed(speed)
end

-- Function to update animation speed at runtime
function _G.updateGlobalAnimationSpeed(actionType, newSpeed)
	if not actionType or not newSpeed then
		warn("Invalid parameters for updateGlobalAnimationSpeed")
		return
	end
	
	_G.GLOBAL_ANIMATION_SPEEDS[actionType] = newSpeed
	print("🌐 Updated global animation speed:", actionType, "=", newSpeed)
end

-- ========================================
-- ANIMATION SETUP
-- ========================================

local function setupPlayerAnimations(player)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	-- Initialize player data
	playerAnimationData[player.UserId] = {}
	local data = playerAnimationData[player.UserId]
	
	-- Wave Emote Animation (Roblox default wave)
	local waveAnim = Instance.new("Animation")
	waveAnim.AnimationId = "rbxassetid://507770239"
	local waveTrack = animator:LoadAnimation(waveAnim)
	waveTrack.Looped = false
	waveTrack.Priority = Enum.AnimationPriority.Action
	
	data.waveTrack = waveTrack
	data.character = character
	data.humanoid = humanoid
	data.animator = animator
	
	print("🌐 Setup global animations for player:", player.Name)
end

local function cleanupPlayerAnimations(player)
	local data = playerAnimationData[player.UserId]
	if data then
		-- Stop and cleanup animations
		if data.waveTrack then
			data.waveTrack:Stop()
			data.waveTrack:Destroy()
		end
		
		playerAnimationData[player.UserId] = nil
		print("🌐 Cleaned up global animations for player:", player.Name)
	end
end

-- ========================================
-- WAVE EMOTE HANDLER
-- ========================================

local function handleWave(player)
	local data = playerAnimationData[player.UserId]
	if not data then
		warn("No animation data for player:", player.Name)
		return
	end
	
	-- Check if character still exists
	if not data.character or not data.character.Parent then
		warn("Character not found for player:", player.Name)
		return
	end
	
	-- Play wave animation
	if data.waveTrack then
		data.waveTrack:Play()
		applyAnimationSpeed(data.waveTrack, "wave")
		print("🌊 Player waved:", player.Name)
	end
end

-- ========================================
-- REMOTE EVENT HANDLING
-- ========================================

remote.OnServerEvent:Connect(function(player, actionName, ...)
	-- Only handle global actions
	if actionName == "global_wave" then
		handleWave(player)
	end
end)

-- ========================================
-- PLAYER CONNECTION HANDLERS
-- ========================================

local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Setup animations when character loads
		task.wait(0.1) -- Small delay for animator to load
		setupPlayerAnimations(player)
	end
end

local function onPlayerAdded(player)
	-- Setup for current character
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	-- Setup for future characters
	player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemoving(player)
	cleanupPlayerAnimations(player)
end

-- ========================================
-- INITIALIZE
-- ========================================

-- Connect to existing players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Connect to new players
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("🌐 Global Animations Server initialized!")
print("  Wave emote works for all players without weapon")

