-- Gladiator Skill Script: Handles gladiator-specific skills (K and L keys)
-- This script runs independently and only activates when gladiator weapons are equipped

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local HitRequest = ReplicatedStorage:WaitForChild("HitRequest")

-- Import hitbox configuration (with safe fallback)
local HitboxConfig
local configLoadSuccess, configError = pcall(function()
    HitboxConfig = require(script.Parent.Parent.shared.HitboxConfig)
end)
if not configLoadSuccess then
    -- Try alternative path
    local success2, error2 = pcall(function()
        HitboxConfig = require(game.ReplicatedStorage:WaitForChild("HitboxConfig"))
    end)
    if not success2 then
        HitboxConfig = nil
    end
end

-- Get gladiator skills from centralized config
local function getGladiatorSkills()
    local skills = {}
    if HitboxConfig then
        -- Get gladiator skills from HitboxConfig
        local skill1Config = HitboxConfig.getSkillConfig("gladiator_skill_1")
        local skill2Config = HitboxConfig.getSkillConfig("gladiator_skill_2")
        
        skills[skill1Config.keyCode] = {
            skillKey = "gladiator_skill_1",
            animationId = skill1Config.animationId,
            name = skill1Config.name
        }
        skills[skill2Config.keyCode] = {
            skillKey = "gladiator_skill_2",
            animationId = skill2Config.animationId,
            name = skill2Config.name
        }
        
    else
        -- Fallback if config not available
        skills[Enum.KeyCode.K] = {
            skillKey = "gladiator_skill_1",
            animationId = "rbxassetid://116519685012277",
            name = "Spear Thrust"
        }
        skills[Enum.KeyCode.L] = {
            skillKey = "gladiator_skill_2",
            animationId = "rbxassetid://116519685012277",
            name = "Arena Sweep"
        }
    end
    return skills
end

local GLADIATOR_SKILLS = getGladiatorSkills()

-- Track current state
local currentCharacter = nil
local currentGladiatorTool = nil
local skillConnections = {}
local skillAnimationTracks = {} -- Store loaded animation tracks

-- Generate skill hitbox using unified system
local function generateSkillHitbox(skillKey)
    -- Wait for the global function to be available
    if _G.generateSkillHitbox then
        _G.generateSkillHitbox(skillKey)
    else
    end
end

-- Setup skill animation tracks (like WeaponUtils.setupTracks)
local function setupSkillAnimationTracks()
    if not currentCharacter then 
        return 
    end
    
    local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid then 
        return 
    end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    else
    end
    
    -- Clear existing tracks
    skillAnimationTracks = {}
    
    -- Load skill animations
    for keyCode, skillData in pairs(GLADIATOR_SKILLS) do
        
        local animationObject = Instance.new("Animation")
        animationObject.AnimationId = skillData.animationId
        
        local success, track = pcall(function()
            return animator:LoadAnimation(animationObject)
        end)
        
        if success and track then
            track.Priority = Enum.AnimationPriority.Action4 -- Highest priority to override everything
            track.Looped = false -- Ensure skill animation only plays once per cast (like attack)
            skillAnimationTracks[skillData.skillKey] = track
        else
        end
    end
    
    -- Count the actual tracks
    local trackCount = 0
    for key, track in pairs(skillAnimationTracks) do
        trackCount = trackCount + 1
    end
end

-- Play skill animation (like WeaponUtils.playAttackAnimation)
local function playSkillAnimation(skillKey)
    
    local track = skillAnimationTracks[skillKey]
    if not track then
        return
    end
    
    
    -- Stop ALL currently playing animations (like WeaponUtils.stopAllTracks but more aggressive)
    if currentCharacter then
        local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:FindFirstChildOfClass("Animator") then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            local stoppedCount = 0
            
            -- Stop ALL animation tracks (not just Action priority)
            for _, playingTrack in pairs(animator:GetPlayingAnimationTracks()) do
                playingTrack:Stop()
                stoppedCount = stoppedCount + 1
            end
            
            -- Give a small delay to ensure animations stop
            wait(0.1)
        end
    end
    
    -- Play the skill animation
    track:Play()
    
    -- When skill animation finishes, let weapon system resume control
    local connection
    connection = track.Stopped:Connect(function()
        connection:Disconnect()
        
        -- Let the weapon system take back control of animations
        -- The weapon system will automatically resume idle/movement animations
    end)
    
    -- Add a brief feedback to show the skill activated
    if currentCharacter and currentCharacter:FindFirstChild("Head") then
        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.new(0, 100, 0, 50)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.Parent = currentCharacter.Head
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = GLADIATOR_SKILLS[Enum.KeyCode.K].skillKey == skillKey and "SPEAR THRUST!" or "ARENA SWEEP!"
        label.TextColor3 = Color3.new(1, 1, 0)
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = gui
        
        -- Remove after 1 second
        task.delay(1, function()
            if gui then gui:Destroy() end
        end)
    end
    
    return track
end

-- Handle skill input
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if not currentGladiatorTool then return end
    
    local skill = GLADIATOR_SKILLS[input.KeyCode]
    if skill then
        print("[GLADIATOR SKILLS] Casting:", skill.name)
        -- Play animation
        playSkillAnimation(skill.skillKey)
        -- Generate hitbox
        generateSkillHitbox(skill.skillKey)
    end
end

-- Activate gladiator skills
local function activateSkills()
    if skillConnections.inputConn then return end -- Already active
    
    skillConnections.inputConn = UserInputService.InputBegan:Connect(onInputBegan)
end

-- Deactivate gladiator skills
local function deactivateSkills()
    for _, connection in pairs(skillConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    skillConnections = {}
end

-- Check if tool is a gladiator weapon
local function isGladiatorWeapon(tool)
    if not tool:IsA("Tool") then return false end
    
    
    local hasDamage = CollectionService:HasTag(tool, "has_damage")
    local isGladiator = CollectionService:HasTag(tool, "gladiator_weapon")
    
    
    return hasDamage and isGladiator
end

-- Handle tool equipped
local function onChildAdded(child)
    if isGladiatorWeapon(child) then
        currentGladiatorTool = child
        setupSkillAnimationTracks() -- Setup animation tracks like weapon system
        activateSkills()
    end
end

-- Handle tool unequipped
local function onChildRemoved(child)
    if child == currentGladiatorTool then
        currentGladiatorTool = nil
        deactivateSkills()
    end
end

-- Handle character added
local function onCharacterAdded(character)
    currentCharacter = character
    
    -- Connect to tool equip/unequip
    character.ChildAdded:Connect(onChildAdded)
    character.ChildRemoved:Connect(onChildRemoved)
    
    -- Check for already equipped gladiator weapons
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            isGladiatorWeapon(child) -- This will print debug info
            if isGladiatorWeapon(child) then
                onChildAdded(child)
            end
        end
    end
end

-- Handle character removed
local function onCharacterRemoving()
    currentCharacter = nil
    currentGladiatorTool = nil
    deactivateSkills()
end

-- Initialize

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)

if player.Character then
    onCharacterAdded(player.Character)
else
end
