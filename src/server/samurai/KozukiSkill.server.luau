-- ========================================
-- KOZUKI SKILL SERVER
-- Ultra-simple Kozuki skill server implementation
-- Based on original Kozuki.client.luau
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- ========================================
-- KOZUKI SKILL VARIABLES
-- ========================================

local remote = nil

-- ========================================
-- KOZUKI SKILL FUNCTIONS
-- ========================================

local function createDashTeleport(character)
    print("KozukiSkill: Creating dash teleport")
    
    local char = character
    local root = char:WaitForChild("HumanoidRootPart")

    -- Default offset (gusto mo pababa -5 studs)
    local localOffset = CFrame.new(0, 0, -10) 

    -- Desired target position relative to player
    local targetCFrame = root.CFrame * localOffset
    local targetPos = targetCFrame.Position

    -- Raycast params (para makita kung may tatamaan)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char} -- huwag tamaan ang sarili
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Gumawa ng ray mula sa current pos papunta sa target
    local direction = targetPos - root.Position
    local rayResult = workspace:Raycast(root.Position, direction, rayParams)

    if rayResult then
        -- ? May na-hit na wall/floor bago makarating
        -- Gamitin yung position na malapit bago yung collision point
        root.CFrame = CFrame.new(rayResult.Position + rayResult.Normal * 2)
    else
        -- ? Walang sagabal, teleport direkta
        root.CFrame = targetCFrame
    end
    
    print("KozukiSkill: Dash teleport completed")
end

local function createSlashesVFX(character)
    print("KozukiSkill: Creating slashes VFX")
    
    local vfx = ReplicatedStorage.KozukiAura:WaitForChild("Slashes"):Clone()
    vfx.Parent = workspace

    local root = character:WaitForChild("HumanoidRootPart")
    
    -- Palitin yung buong VFX model
    if vfx:IsA("Model") then
        vfx:ScaleTo(0.1) -- kalahati ng original size (0.5 = 50%, 2 = 200%)
    else
        -- Palitin lahat ng parts, meshes, particles sa loob ng VFX
        for _, obj in ipairs(vfx:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Size = obj.Size * 0.5 -- liitan basepart size
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Size = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1), -- start size
                    NumberSequenceKeypoint.new(1, 10)  -- end size
                }
            elseif obj:IsA("Beam") then
                obj.Width0 = obj.Width0 * 10
                obj.Width1 = obj.Width1 * 10
            elseif obj:IsA("SpecialMesh") then
                obj.Scale = obj.Scale * 1
            end
        end
    end

    -- Position sa harap ng player (independent, no weld)
    --local forwardOffset = -10 -- gaano kalayo sa harap magsimula
    local rotationX = 0 -- ikot pataas/pababa
    local rotationY = math.rad(0) -- ikot pakaliwa/pakanan
    local rotationZ = 0 -- ikot paikot

    local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

    vfx:PivotTo(root.CFrame * CFrame.new(0, 0, 0)* rotation)
    
    -- Ensure lahat ng parts ay hindi naka-anchor pero stable
    for _, part in ipairs(vfx:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
        end
    end

    -- Auto cleanup
    Debris:AddItem(vfx, 3)
    
    print("KozukiSkill: Slashes VFX created and cleaned up")
end

local function createAuraStance(character)
    print("KozukiSkill: Creating aura stance VFX")
    
    local vfx = ReplicatedStorage.KozukiAura:WaitForChild("AuraStance"):Clone()
    vfx.Parent = workspace

    -- Anchor sa left foot
    local foot = character:FindFirstChild("LowerTorso") or character:WaitForChild("HumanoidRootPart")
    local offset = CFrame.new(-3, -3, 0)-- X = left/right, Y = up/down, Z = forward/back
    
    vfx:PivotTo(foot.CFrame * offset)

    -- Weld all BaseParts to foot
    for _, part in ipairs(vfx:GetDescendants()) do
        if part:IsA("BasePart") then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = foot
            weld.Part1 = part
            weld.Parent = part
            part.Anchored = false
        end
    end

    -- Auto cleanup
    Debris:AddItem(vfx, 2)
    
    print("KozukiSkill: Aura stance VFX created and cleaned up")
end

local function executeKozukiSkill(player)
    print("KozukiSkill: Starting skill execution for", player.Name)
    
    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")

    -- preload anim (server handles)
    local slashAnim = Instance.new("Animation")
    slashAnim.AnimationId = "rbxassetid://101344605319771"
    local animTrack = animator:LoadAnimation(slashAnim)
    animTrack:Play()
    
    print("KozukiSkill: Animation loaded and playing")

    -- ? DASH marker
    animTrack:GetMarkerReachedSignal("DashAttack"):Connect(function()
        print("KozukiSkill: DashAttack marker reached")
        createDashTeleport(character)
        createSlashesVFX(character)
    end)

    -- ? AURA marker (one-time connection lang)
    animTrack:GetMarkerReachedSignal("AuraStart"):Connect(function()
        print("KozukiSkill: AuraStart marker reached")
        createAuraStance(character)
    end)

    -- Clean up animation
    game:GetService("Debris"):AddItem(slashAnim, 10)
    
    print("KozukiSkill: Skill execution setup complete")
end

local function handleSkillRequest(player)
    -- Validate player
    if not player or not player.Character then
        warn("KozukiSkill: Invalid player or character")
        return
    end
    
    print("KozukiSkill: Executing skill for player:", player.Name)
    
    -- Execute the skill
    executeKozukiSkill(player)
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Find the Kozuki skill event in samurai/events folder
local samuraiFolder = ReplicatedStorage:WaitForChild("samurai")
local eventsFolder = samuraiFolder:WaitForChild("events")
remote = eventsFolder:WaitForChild("KozukiSkillEvent")

-- Connect to remote event
remote.OnServerEvent:Connect(function(player)
    handleSkillRequest(player)
end)
print("KozukiSkill: Server initialized with KozukiSkillEvent")
