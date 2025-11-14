-- ========================================
-- R15 ANIMATION SCRIPT
-- Standalone script for R15-style animations
-- Place this script inside your model to enable R15 animations
-- Customize the ANIMATION_IDS table below to change animations per mob
-- ========================================

local CollectionService = game:GetService("CollectionService")

-- ========================================
-- ANIMATION CONFIGURATION
-- Customize these animation IDs for your specific mob
-- ========================================
local ANIMATION_IDS = {
	idle = {
		"507766666"
	},
	walk = {
		"110963630289407"
	},
	run = {
		"110963630289407"
	},
	swim = {
		"110963630289407"
	},
	swimidle = {
		"110963630289407"
	},
	jump = {
		"110963630289407"
	},
	fall = {
		"110963630289407"
	},
	climb = {
		"110963630289407"
	},
	sit = {
		"110963630289407"
	},
	toolnone = {
		"110963630289407"
	},
	toolslash = {
		"110963630289407"
	},
	toollunge = {
		"110963630289407"
	},
	wave = {
		"110963630289407"
	},
	point = {
		"110963630289407"
	},
	dance = {
		"110963630289407",
		"110963630289407",
		"110963630289407"
	},
	dance2 = {
		"110963630289407",
		"110963630289407",
		"110963630289407"
	},
	dance3 = {
		"110963630289407",
		"110963630289407",
		"110963630289407"
	},
	laugh = {
		"110963630289407"
	},
	cheer = {
		"110963630289407"
	},
	combat1 = {
		"136019045506301"  -- Default R15 attack animation, customize as needed
	},
}

-- Core behaviour tuning
local R15_TAG = "r15_entity"
local PLAYER_CONTROL_TAG = "player_transformed"
local PLAYER_ATTACK_ATTRIBUTE = "PlayerAttackRequest"

-- Get model from script parent
local model = script.Parent
if not model or not model:IsA("Model") then
	warn("[R15AnimationScript] Script must be placed inside a Model")
	return
end

-- Automatically add r15_entity tag to the model
CollectionService:AddTag(model, R15_TAG)

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
		warn("[R15AnimationScript] Failed to load animation", id)
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
	
	-- Load attack animation with Action priority
	if ANIMATION_IDS.combat1 and #ANIMATION_IDS.combat1 > 0 then
		animSet.combat1 = loadTrack(animator, ANIMATION_IDS.combat1[1], false, Enum.AnimationPriority.Action)
	end
	
	-- Load jump animation
	if ANIMATION_IDS.jump and #ANIMATION_IDS.jump > 0 then
		animSet.jump = loadTrack(animator, ANIMATION_IDS.jump[1], false, Enum.AnimationPriority.Movement)
	end
	
	-- Load fall animation
	if ANIMATION_IDS.fall and #ANIMATION_IDS.fall > 0 then
		animSet.fall = loadTrack(animator, ANIMATION_IDS.fall[1], true, Enum.AnimationPriority.Movement)
	end
	
	-- Load climb animation
	if ANIMATION_IDS.climb and #ANIMATION_IDS.climb > 0 then
		animSet.climb = loadTrack(animator, ANIMATION_IDS.climb[1], true, Enum.AnimationPriority.Movement)
	end
	
	-- Load swim animation
	if ANIMATION_IDS.swim and #ANIMATION_IDS.swim > 0 then
		animSet.swim = loadTrack(animator, ANIMATION_IDS.swim[1], true, Enum.AnimationPriority.Movement)
	end
	
	-- Load swimidle animation
	if ANIMATION_IDS.swimidle and #ANIMATION_IDS.swimidle > 0 then
		animSet.swimidle = loadTrack(animator, ANIMATION_IDS.swimidle[1], true, Enum.AnimationPriority.Movement)
	end
	
	-- Load sit animation
	if ANIMATION_IDS.sit and #ANIMATION_IDS.sit > 0 then
		animSet.sit = loadTrack(animator, ANIMATION_IDS.sit[1], true, Enum.AnimationPriority.Movement)
	end
	
	-- Load other animations (tool animations, emotes, etc.)
	for animName, animIds in pairs(ANIMATION_IDS) do
		if animName ~= "idle" and animName ~= "walk" and animName ~= "run" and animName ~= "combat1" 
			and animName ~= "jump" and animName ~= "fall" and animName ~= "climb" 
			and animName ~= "swim" and animName ~= "swimidle" and animName ~= "sit" then
			local isLooped = animName == "toolnone"
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
		warn("[R15AnimationScript] Failed to play animation:", err)
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
		warn("[R15AnimationScript] Failed to stop animation:", err)
	end
end

-- Wait for model to be ready
local humanoid = model:WaitForChild("Humanoid", 10)
local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

if not humanoid then
	warn("[R15AnimationScript] Missing humanoid for", model.Name)
	return
end

if not root then
	warn("[R15AnimationScript] Missing root part (HumanoidRootPart) for", model.Name)
	return
end

-- Initialize animations
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
local playerControlled = bindPlayerControl(model, humanoid, playAttack)

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

-- For player-controlled characters, animations are already set up with attack binding
if playerControlled then
	-- Player control is already set up, animations will work automatically
	return
end

