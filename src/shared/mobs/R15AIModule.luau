-- R15 AI Module
-- Handles R15-style animations for transformed characters with r15_entity tag

local CollectionService = game:GetService("CollectionService")

-- R15 Animation asset IDs (from standard Roblox R15 animations)
local ANIMATION_IDS = {
	idle = {
		"507766666",
		"507766951",
		"507766388"
	},
	walk = {
		"507777826"
	},
	run = {
		"507767714"
	},
	swim = {
		"507784897"
	},
	swimidle = {
		"507785072"
	},
	jump = {
		"507765000"
	},
	fall = {
		"507767968"
	},
	climb = {
		"507765644"
	},
	sit = {
		"2506281703"
	},
	toolnone = {
		"507768375"
	},
	toolslash = {
		"522635514"
	},
	toollunge = {
		"522638767"
	},
	wave = {
		"507770239"
	},
	point = {
		"507770453"
	},
	dance = {
		"507771019",
		"507771955",
		"507772104"
	},
	dance2 = {
		"507776043",
		"507776720",
		"507776879"
	},
	dance3 = {
		"507777268",
		"507777451",
		"507777623"
	},
	laugh = {
		"507770818"
	},
	cheer = {
		"507770677"
	},
}

-- Core behaviour tuning
local R15_TAG = "r15_entity"

local PLAYER_CONTROL_TAG = "player_transformed"
local PLAYER_ATTACK_ATTRIBUTE = "PlayerAttackRequest"

local function isPlayerControlled(character)
	return CollectionService:HasTag(character, PLAYER_CONTROL_TAG)
end

local function toAssetId(id)
	if type(id) == "number" then
		return "rbxassetid://" .. tostring(id)
	end

	if type(id) == "string" then
		if string.find(id, "rbxassetid://") then
			return id
		end
		return "rbxassetid://" .. id
	end

	return ""
end

local function loadTrack(animator, id, looped, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = toAssetId(id)

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not success or not track then
		warn("[R15] Failed to load animation", id)
		return nil
	end

	track.Looped = looped
	track.Priority = priority

	return track
end

local function createAnimationSet(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	
	local animSet = {}
	
	-- Load idle animations (multiple with weights)
	for _, idleId in ipairs(ANIMATION_IDS.idle) do
		local track = loadTrack(animator, idleId, true, Enum.AnimationPriority.Core)
		if track then
			if not animSet.idle then
				animSet.idle = {}
			end
			table.insert(animSet.idle, track)
		end
	end
	
	-- Load walk animation
	if ANIMATION_IDS.walk and #ANIMATION_IDS.walk > 0 then
		animSet.walk = loadTrack(animator, ANIMATION_IDS.walk[1], true, Enum.AnimationPriority.Core)
	end
	
	-- Load run animation
	if ANIMATION_IDS.run and #ANIMATION_IDS.run > 0 then
		animSet.run = loadTrack(animator, ANIMATION_IDS.run[1], true, Enum.AnimationPriority.Core)
	end
	
	-- Load other animations
	for animName, animIds in pairs(ANIMATION_IDS) do
		if animName ~= "idle" and animName ~= "walk" and animName ~= "run" then
			local isLooped = animName == "swim" or animName == "swimidle" or animName == "fall" or animName == "climb" or animName == "sit" or animName == "toolnone"
			local track = loadTrack(animator, animIds[1], isLooped, Enum.AnimationPriority.Movement)
			if track then
				animSet[animName] = track
			end
		end
	end
	
	return animSet
end

local function playTrack(track, fade)
	if not track then
		return
	end

	local success, err = pcall(function()
		track:Play(fade or 0.1)
	end)

	if not success then
		warn("[R15] Failed to play animation:", err)
	end
end

local function stopTrack(track, fade)
	if not track then
		return
	end

	local success, err = pcall(function()
		track:Stop(fade or 0.1)
	end)

	if not success then
		warn("[R15] Failed to stop animation:", err)
	end
end

local function initializeR15(character, variantName)
	-- variantName parameter kept for compatibility but not used

	if not character or not character:IsA("Model") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

	if not humanoid or not root then
		warn("[R15] Missing humanoid or root part for", character.Name)
		return
	end

	CollectionService:AddTag(character, R15_TAG)

	local animations = createAnimationSet(humanoid)

	local currentMovementTrack = nil
	local movementLocked = false

	local function setMovementTrack(track, fade)
		if movementLocked then
			return
		end

		if currentMovementTrack == track then
			return
		end

		if currentMovementTrack then
			stopTrack(currentMovementTrack, fade or 0.15)
		end

		currentMovementTrack = track

		if currentMovementTrack then
			playTrack(currentMovementTrack, fade or 0.15)
		end
	end

	local function stopMovement()
		if currentMovementTrack then
			stopTrack(currentMovementTrack, 0.1)
			currentMovementTrack = nil
		end
	end

	-- Start with idle
	if animations.idle and #animations.idle > 0 then
		local idleTrack = animations.idle[math.random(1, #animations.idle)]
		setMovementTrack(idleTrack, 0)
	end

	-- Animation state handlers - simple state-based switching
	humanoid.Running:Connect(function(speed)
		if movementLocked then
			return
		end

		if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			return
		end

		-- Simple: if moving, play walk animation
		if speed > 0.1 then
			if animations.walk then
				setMovementTrack(animations.walk, 0.2)
			elseif animations.run then
				setMovementTrack(animations.run, 0.2)
			end
		else
			if animations.idle and #animations.idle > 0 then
				local idleTrack = animations.idle[math.random(1, #animations.idle)]
				setMovementTrack(idleTrack, 0.2)
			end
		end
	end)

	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if movementLocked then
			return
		end

		if humanoid.MoveDirection.Magnitude < 0.05 and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
			if animations.idle and #animations.idle > 0 then
				local idleTrack = animations.idle[math.random(1, #animations.idle)]
				setMovementTrack(idleTrack, 0.2)
			end
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		if movementLocked and newState ~= Enum.HumanoidStateType.Dead then
			return
		end

		if newState == Enum.HumanoidStateType.Jumping then
			if animations.jump then
				setMovementTrack(animations.jump, 0.05)
			end
		elseif newState == Enum.HumanoidStateType.Freefall then
			if animations.fall then
				setMovementTrack(animations.fall, 0.1)
			end
		elseif newState == Enum.HumanoidStateType.Climbing then
			if animations.climb then
				setMovementTrack(animations.climb, 0.1)
			end
		elseif newState == Enum.HumanoidStateType.Swimming then
			if animations.swim then
				setMovementTrack(animations.swim, 0.4)
			elseif animations.swimidle then
				setMovementTrack(animations.swimidle, 0.4)
			end
		elseif newState == Enum.HumanoidStateType.Seated then
			if animations.sit then
				setMovementTrack(animations.sit, 0.5)
			end
		elseif newState == Enum.HumanoidStateType.Landed then
			if animations.idle and #animations.idle > 0 then
				local idleTrack = animations.idle[math.random(1, #animations.idle)]
				setMovementTrack(idleTrack, 0.15)
			end
		elseif newState == Enum.HumanoidStateType.Dead then
			movementLocked = true
			stopMovement()
		end
	end)

	-- For player-controlled characters, just handle animations
	if isPlayerControlled(character) then
		return
	end
end

local R15AIModule = {}

function R15AIModule.initializeR15(model, variantName)
	initializeR15(model, variantName)
end

function R15AIModule.isInitialized(_model)
	return false
end

return R15AIModule

