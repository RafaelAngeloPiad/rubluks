-- ========================================
-- WAKIZASHI SKILL SERVER
-- Ultra-simple Wakizashi skill server implementation
-- Based on original Wakizashi.server.luau
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- ========================================
-- WAKIZASHI SKILL VARIABLES
-- ========================================

local remote = nil

-- ========================================
-- WAKIZASHI SKILL FUNCTIONS
-- ========================================

local function createLightningAura(character)
    print("WakizashiSkill: Creating lightning aura VFX")
    
    local root = character:WaitForChild("HumanoidRootPart")
    local leftHand = character:FindFirstChild("LeftHand") or root
    local rightHand = character:FindFirstChild("RightHand") or root

    -- Create left hand lightning
    local vfxLeft = ReplicatedStorage.WakizashiAura:WaitForChild("lightningLeft"):Clone()
    vfxLeft.Parent = workspace

    local offsetLeft = CFrame.new(-3, 0, 0) -- X = left/right, Y = harap/likod, Z = taas/baba
    vfxLeft:PivotTo(leftHand.CFrame * offsetLeft)

    for _, part in ipairs(vfxLeft:GetDescendants()) do
        if part:IsA("BasePart") then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = leftHand
            weld.Part1 = part
            weld.Parent = part
            part.Anchored = false
        end
    end

    -- Create right hand lightning
    local vfxRight = ReplicatedStorage.WakizashiAura:WaitForChild("lightningRight"):Clone()
    vfxRight.Parent = workspace

    local offsetRight = CFrame.new(3, 0, 0) -- X = left/right, Y = harap/likod, Z = taas/baba
    vfxRight:PivotTo(rightHand.CFrame * offsetRight)

    for _, part in ipairs(vfxRight:GetDescendants()) do
        if part:IsA("BasePart") then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = rightHand
            weld.Part1 = part
            weld.Parent = part
            part.Anchored = false
        end
    end

    game:GetService("Debris"):AddItem(vfxLeft, 2)
    game:GetService("Debris"):AddItem(vfxRight, 2)
    
    print("WakizashiSkill: Lightning aura VFX created and cleaned up")
end

local function createBladeSlash(character)
    print("WakizashiSkill: Creating blade slash VFX")
    
    local vfx = ReplicatedStorage.WakizashiAura:WaitForChild("Slash"):Clone()
    vfx.Parent = workspace

    local root = character:WaitForChild("HumanoidRootPart")

    -- Position sa harap ng player (independent, no weld)
    local forwardOffset = 5 -- gaano kalayo sa harap magsimula
    local rotationX = 0 -- ikot pataas/pababa
    local rotationY = math.rad(90) -- ikot pakaliwa/pakanan
    local rotationZ = 0 -- ikot paikot

    local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

    vfx:PivotTo(root.CFrame * CFrame.new(0, 0, -forwardOffset) * rotation)

    -- Ensure lahat ng parts ay hindi naka-anchor pero stable
    for _, part in ipairs(vfx:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
        end
    end

    -- Kukunin natin yung main mesh (blade)
    local bladePart = vfx:FindFirstChildWhichIsA("BasePart") or vfx

    -- Gagalaw forward gamit BodyVelocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = root.CFrame.LookVector * 160 -- adjust speed
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Parent = bladePart

    -- Auto cleanup
    game:GetService("Debris"):AddItem(vfx, 2)
    game:GetService("Debris"):AddItem(bodyVelocity, 2)
    
    print("WakizashiSkill: Blade slash VFX created and cleaned up")
end

local function executeWakizashiSkill(player)
    print("WakizashiSkill: Starting skill execution for", player.Name)
    
    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")

    -- Load and play animation
    local slashAnim = Instance.new("Animation")
    slashAnim.AnimationId = "rbxassetid://121133581854383"
    local animTrack = animator:LoadAnimation(slashAnim)
    animTrack:Play()
    
    print("WakizashiSkill: Animation loaded and playing")

    -- Handle ElectricAura marker
    animTrack:GetMarkerReachedSignal("ElectricAura"):Connect(function()
        print("WakizashiSkill: ElectricAura marker reached")
        createLightningAura(character)
    end)

    -- Handle SonicBlade marker
    animTrack:GetMarkerReachedSignal("SonicBlade"):Connect(function()
        print("WakizashiSkill: SonicBlade marker reached")
        createBladeSlash(character)
    end)

    -- Clean up animation
    game:GetService("Debris"):AddItem(slashAnim, 10)
    
    print("WakizashiSkill: Skill execution setup complete")
end

local function handleSkillRequest(player)
    -- Validate player
    if not player or not player.Character then
        warn("WakizashiSkill: Invalid player or character")
        return
    end
    
    print("WakizashiSkill: Executing skill for player:", player.Name)
    
    -- Execute the skill
    executeWakizashiSkill(player)
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Set up remote event (use existing AttackEvent)
remote = ReplicatedStorage:FindFirstChild("AttackEvent")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "AttackEvent"
    remote.Parent = ReplicatedStorage
end

-- Connect to remote event
remote.OnServerEvent:Connect(function(player)
    handleSkillRequest(player)
end)

print("WakizashiSkill: Server initialized")