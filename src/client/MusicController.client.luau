-- ========================================
-- MUSIC CONTROLLER
-- Tag-based system to control BackgroundMusic volume
-- Tags: music_vol_up, music_vol_down, music_mute
-- ========================================

local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local TARGET_SOUND_NAME = "BackgroundMusic"
local DEFAULT_VOLUME = 0.5
local VOLUME_STEP = 0.1
local MAX_VOLUME = 1.0
local MIN_VOLUME = 0.0

-- Tags
local TAG_VOL_UP = "music_vol_up"
local TAG_VOL_DOWN = "music_vol_down"
local TAG_MUTE = "music_mute"

-- State
local lastVolume = DEFAULT_VOLUME
local isMuted = false

-- Track mute buttons for visual updates
local muteButtons = {}

-- Helper to find the music object
local function getMusicObject()
	return SoundService:FindFirstChild(TARGET_SOUND_NAME)
end

-- ========================================
-- VISUALS
-- ========================================

local function updateMuteButtonVisual(button)
	local text = isMuted and "Music Off" or "Music On"
	
	if button:IsA("TextButton") then
		button.Text = text
	end
	
	-- Also check for any TextLabel children (e.g. if using ImageButton)
	local textLabel = button:FindFirstChildWhichIsA("TextLabel")
	if textLabel then
		textLabel.Text = text
	end
end

local function updateAllMuteVisuals()
	for _, button in ipairs(muteButtons) do
		updateMuteButtonVisual(button)
	end
end

-- ========================================
-- LOGIC
-- ========================================

local function setVolume(newVolume)
	local music = getMusicObject()
	if not music then
		warn("[MusicController] Could not find sound: " .. TARGET_SOUND_NAME)
		return
	end

	-- Clamp volume
	newVolume = math.clamp(newVolume, MIN_VOLUME, MAX_VOLUME)
	
	music.Volume = newVolume
	
	-- Update mute state based on volume
	if newVolume > 0 then
		isMuted = false
		lastVolume = newVolume
	else
		isMuted = true
	end
	
	updateAllMuteVisuals()
end

local function toggleMute()
	local music = getMusicObject()
	if not music then return end

	if isMuted then
		-- Unmute: return to last volume
		setVolume(lastVolume > 0 and lastVolume or DEFAULT_VOLUME)
	else
		-- Mute: save current volume (if > 0) and set to 0
		if music.Volume > 0 then
			lastVolume = music.Volume
		end
		setVolume(0)
	end
end

local function volumeUp()
	local music = getMusicObject()
	if not music then return end
	
	if isMuted then
		-- Unmute and increment from 0 (or just unmute to last volume?)
		-- Standard behavior: Unmute restores volume, then we can add.
		-- OR: Unmute starts at 0 + Step. 
		-- Let's just unmute to last known volume first.
		toggleMute()
	else
		setVolume(music.Volume + VOLUME_STEP)
	end
end

local function volumeDown()
	local music = getMusicObject()
	if not music then return end
	
	setVolume(music.Volume - VOLUME_STEP)
end

-- ========================================
-- BUTTON SETUP
-- ========================================

local function registerMuteButton(button)
	table.insert(muteButtons, button)
	updateMuteButtonVisual(button)
	
	button.Destroying:Connect(function()
		for i = #muteButtons, 1, -1 do
			if muteButtons[i] == button then
				table.remove(muteButtons, i)
				break
			end
		end
	end)
end

local function setupButton(button, tag)
	if not button:IsA("GuiButton") then return end
	
	if tag == TAG_MUTE then
		registerMuteButton(button)
	end
	
	button.MouseButton1Click:Connect(function()
		if tag == TAG_VOL_UP then
			volumeUp()
		elseif tag == TAG_VOL_DOWN then
			volumeDown()
		elseif tag == TAG_MUTE then
			toggleMute()
		end
		
		-- Visual feedback (console)
		local music = getMusicObject()
		print("[MusicController] Action:", tag, "| Volume:", music and music.Volume or "N/A")
	end)
end

local function initializeTags()
	local tags = {TAG_VOL_UP, TAG_VOL_DOWN, TAG_MUTE}
	
	for _, tag in ipairs(tags) do
		-- Handle existing buttons
		for _, button in ipairs(CollectionService:GetTagged(tag)) do
			setupButton(button, tag)
		end
		
		-- Handle new buttons
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(button)
			setupButton(button, tag)
		end)
	end
end

-- ========================================
-- INIT
-- ========================================

task.spawn(function()
	-- Wait for music object to exist to initialize volume if needed, 
	-- but don't block the button setup
	local music = SoundService:WaitForChild(TARGET_SOUND_NAME, 10)
	if music then
		music.Volume = DEFAULT_VOLUME
		lastVolume = DEFAULT_VOLUME
		isMuted = false
		updateAllMuteVisuals()
		print("[MusicController] Found BackgroundMusic. Volume set to " .. DEFAULT_VOLUME)
	else
		warn("[MusicController] Waiting for " .. TARGET_SOUND_NAME .. "...")
	end
end)

initializeTags()
print("[MusicController] Initialized. Waiting for tagged buttons.")
