-- R6 AI Module
-- Handles R6-style animations for transformed characters with r6_entity tag

local CollectionService = game:GetService("CollectionService")

-- R6 Animation asset IDs (from standard Roblox R6 animations)
local ANIMATION_IDS = {
	idle = {
		"180435571",
		"180435792"
	},
	walk = {
		"180426354"
	},
	jump = {
		"125750702"
	},
	fall = {
		"180436148"
	},
	climb = {
		"180436334"
	},
	sit = {
		"178130996"
	},
	toolnone = {
		"182393478"
	},
	toolslash = {
		"129967390"
	},
	toollunge = {
		"129967478"
	},
	wave = {
		"128777973"
	},
	point = {
		"128853357"
	},
	dance1 = {
		"182435998",
		"182491037",
		"182491065"
	},
	dance2 = {
		"182436842",
		"182491248",
		"182491277"
	},
	dance3 = {
		"182436935",
		"182491368",
		"182491423"
	},
	laugh = {
		"129423131"
	},
	cheer = {
		"129423030"
	},
    combat1 = {
        "111495946420514"
    }
}

-- Core behaviour tuning
local R6_TAG = "r6_entity"

local PLAYER_CONTROL_TAG = "player_transformed"
local PLAYER_ATTACK_ATTRIBUTE = "PlayerAttackRequest"

local function isPlayerControlled(character)
	return CollectionService:HasTag(character, PLAYER_CONTROL_TAG)
end

local function bindPlayerControl(character, humanoid, attackCallback)
	if not isPlayerControlled(character) then
		return false
	end

	humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)

	humanoid:GetAttributeChangedSignal(PLAYER_ATTACK_ATTRIBUTE):Connect(function()
		if not isPlayerControlled(character) then
			return
		end

		if humanoid:GetAttribute(PLAYER_ATTACK_ATTRIBUTE) then
			humanoid:SetAttribute(PLAYER_ATTACK_ATTRIBUTE, false)
			attackCallback()
		end
	end)

	return true
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
		warn("[R6] Failed to load animation", id)
		return nil
	end

	track.Looped = looped
	track.Priority = priority

	return track
end

local function createAnimationSet(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	
	local animSet = {}
	
	-- Load idle animations (multiple)
	for _, idleId in ipairs(ANIMATION_IDS.idle) do
		local track = loadTrack(animator, idleId, true, Enum.AnimationPriority.Core)
		if track then
			if not animSet.idle then
				animSet.idle = {}
			end
			table.insert(animSet.idle, track)
		end
	end
	
	-- Load attack animation with Action priority
	if ANIMATION_IDS.combat1 and #ANIMATION_IDS.combat1 > 0 then
		animSet.combat1 = loadTrack(animator, ANIMATION_IDS.combat1[1], false, Enum.AnimationPriority.Action)
	end
	
	-- Load other animations
	for animName, animIds in pairs(ANIMATION_IDS) do
		if animName ~= "idle" and animName ~= "combat1" then
			local isLooped = animName == "walk" or animName == "fall" or animName == "climb" or animName == "sit" or animName == "toolnone"
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
		warn("[R6] Failed to play animation:", err)
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
		warn("[R6] Failed to stop animation:", err)
	end
end

local function initializeR6(character, variantName)
	-- variantName parameter kept for compatibility but not used

	if not character or not character:IsA("Model") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	-- R6 models use Torso, R15 use HumanoidRootPart
	local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character.PrimaryPart

	if not humanoid then
		warn("[R6] Missing humanoid for", character.Name)
		return
	end
	
	-- R6 models might not have HumanoidRootPart, so Torso is fine
	if not root then
		warn("[R6] Missing root part (Torso or HumanoidRootPart) for", character.Name)
		return
	end

	CollectionService:AddTag(character, R6_TAG)

	local animations = createAnimationSet(humanoid)

	local currentMovementTrack = nil
	local movementLocked = false
	local attacking = false

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

	local function playAttack()
		if attacking or movementLocked then
			return
		end

		if not animations.combat1 then
			return
		end

		attacking = true
		movementLocked = true
		stopMovement()

		local attackTrack = animations.combat1
		playTrack(attackTrack, 0.1)

		local connection
		connection = attackTrack.Stopped:Connect(function()
			attacking = false
			movementLocked = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end)
	end

	-- Bind player control for attack
	local playerControlled = bindPlayerControl(character, humanoid, playAttack)

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
				setMovementTrack(animations.walk, 0.1)
			end
		else
			if animations.idle and #animations.idle > 0 then
				local idleTrack = animations.idle[math.random(1, #animations.idle)]
				setMovementTrack(idleTrack, 0.1)
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
				setMovementTrack(idleTrack, 0.1)
			end
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		if movementLocked and newState ~= Enum.HumanoidStateType.Dead then
			return
		end

		if newState == Enum.HumanoidStateType.Jumping then
			if animations.jump then
				setMovementTrack(animations.jump, 0.1)
			end
		elseif newState == Enum.HumanoidStateType.Freefall then
			if animations.fall then
				setMovementTrack(animations.fall, 0.3)
			end
		elseif newState == Enum.HumanoidStateType.Climbing then
			if animations.climb then
				setMovementTrack(animations.climb, 0.1)
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

	-- For player-controlled characters, animations are already set up with attack binding
	if playerControlled then
		return
	end
end

local R6AIModule = {}

function R6AIModule.initializeR6(model, variantName)
	initializeR6(model, variantName)
end

function R6AIModule.isInitialized(_model)
	return false
end

return R6AIModule

