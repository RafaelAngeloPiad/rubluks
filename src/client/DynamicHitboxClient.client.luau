-- DynamicHitboxClient: Unified hitbox system for weapons and skills
-- Handles hitbox generation for any equipped Tool with "has_damage" tag and skill requests

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("HitRequest")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

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

-- Default hitbox values (fallback if config system fails)
local HITBOX_SIZE = Vector3.new(6, 6, 6) -- width, height, depth of the hitbox
local HITBOX_OFFSET = Vector3.new(0, 0, 4) -- (x, y, z) offset from HumanoidRootPart; z is forward
local DEFAULT_DAMAGE = 25

-- Visual hitbox preview toggle - ENABLED for demo particle effects
local SHOW_HITBOX_VISUALS = true -- Set to false to disable hitbox previews

-- =====================================================================================
-- CENTRALIZED ANNOUNCEMENT SYSTEM
-- =====================================================================================

-- Announcement system to prevent overlapping attack/skill name displays
local AnnouncementSystem = {}

-- Track current announcement to prevent overlaps
local currentAnnouncement = nil
local announcementQueue = {}

-- Show announcement with overlap prevention
function AnnouncementSystem.showAnnouncement(text, color, duration, priority)
    duration = duration or 1.0
    priority = priority or 1 -- Higher number = higher priority
    
    -- If there's already an announcement and this one has lower priority, queue it
    if currentAnnouncement and priority < currentAnnouncement.priority then
        table.insert(announcementQueue, {
            text = text,
            color = color,
            duration = duration,
            priority = priority
        })
        return
    end
    
    -- If there's a current announcement, remove it
    if currentAnnouncement and currentAnnouncement.gui then
        currentAnnouncement.gui:Destroy()
    end
    
    -- Create new announcement
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then
        return
    end
    
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 120, 0, 60)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Parent = character.Head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = gui
    
    -- Store current announcement
    currentAnnouncement = {
        gui = gui,
        priority = priority,
        startTime = tick()
    }
    
    -- Remove after duration
    task.delay(duration, function()
        if currentAnnouncement and currentAnnouncement.gui == gui then
            gui:Destroy()
            currentAnnouncement = nil
            
            -- Process next announcement in queue
            if #announcementQueue > 0 then
                local nextAnnouncement = table.remove(announcementQueue, 1)
                AnnouncementSystem.showAnnouncement(
                    nextAnnouncement.text,
                    nextAnnouncement.color,
                    nextAnnouncement.duration,
                    nextAnnouncement.priority
                )
            end
        end
    end)
end

-- Convenience functions for different announcement types
function AnnouncementSystem.showComboAttack(attackNumber, attackName, weaponType)
    local colors = {
        berserker = Color3.new(1, 0, 0), -- Red
        archer = Color3.new(0, 1, 1),   -- Cyan
        knight = Color3.new(0, 1, 0),   -- Green
        samurai = Color3.new(0, 0, 1),  -- Blue
        gladiator = Color3.new(1, 1, 0) -- Yellow
    }
    
    local color = colors[weaponType] or Color3.new(1, 1, 1)
    local text = string.format("COMBO %d!\n%s", attackNumber, attackName)
    
    AnnouncementSystem.showAnnouncement(text, color, 1.0, 2) -- Priority 2 for combos
end

function AnnouncementSystem.showSkill(skillName, weaponType)
    local colors = {
        berserker = Color3.new(1, 0, 0), -- Red
        archer = Color3.new(0, 1, 1),   -- Cyan
        knight = Color3.new(0, 1, 0),   -- Green
        samurai = Color3.new(0, 0, 1),  -- Blue
        gladiator = Color3.new(1, 1, 0) -- Yellow
    }
    
    local color = colors[weaponType] or Color3.new(1, 1, 1)
    local text = string.format("%s!", skillName:upper())
    
    AnnouncementSystem.showAnnouncement(text, color, 1.0, 3) -- Priority 3 for skills
end

function AnnouncementSystem.showCooldown(remainingTime)
    local text = string.format("COOLDOWN %.1fs", remainingTime)
    AnnouncementSystem.showAnnouncement(text, Color3.new(0.8, 0.8, 0.8), 1.0, 1) -- Priority 1 for cooldowns
end

-- Clear all announcements (useful for testing)
function AnnouncementSystem.clearAll()
    if currentAnnouncement and currentAnnouncement.gui then
        currentAnnouncement.gui:Destroy()
        currentAnnouncement = nil
    end
    announcementQueue = {}
end

-- =====================================================================================
-- UNIFIED HITBOX GENERATION SYSTEM
-- =====================================================================================

local DynamicHitboxClient = {}

-- Helper function to get weapon hitbox configuration for a tool
local function getHitboxConfig(tool)
    -- If config system is not available, use defaults
    if not HitboxConfig then
        return HITBOX_SIZE, HITBOX_OFFSET, DEFAULT_DAMAGE, nil
    end
    
    -- Check for weapon-specific tags
    local weaponTags = HitboxConfig.getAllWeaponTags()
    for _, weaponTag in ipairs(weaponTags) do
        if CollectionService:HasTag(tool, weaponTag) then
            local config = HitboxConfig.getWeaponConfig(weaponTag)
            return config.size, config.offset, config.baseDamage, weaponTag
        end
    end
    
    -- No specific weapon tag found, use defaults
    return HITBOX_SIZE, HITBOX_OFFSET, DEFAULT_DAMAGE, nil
end

-- Helper function to get skill hitbox configuration
local function getSkillHitboxConfig(skillKey)
    if HitboxConfig then
        local config = HitboxConfig.getSkillConfig(skillKey)
        return config -- Return full config object with timing info
    else
        -- Fallback values if config system isn't available
        return {
            size = Vector3.new(8, 6, 8),
            offset = Vector3.new(0, 0, 5),
            baseDamage = 40,
            name = "Unknown Skill",
            cooldownTime = 2.0,
            castTime = 0.8,
            hitboxDelay = 0.3,
        }
    end
end

-- Create visual hitbox (unified for weapons and skills with custom duration)
local function createVisualHitbox(hitboxCFrame, size, hitboxType, customDuration, weaponTag)
    -- Check if visual hitboxes are enabled
    if not SHOW_HITBOX_VISUALS then
        return -- Skip creating visual if disabled
    end
    
    -- Create particle effect container
    local effectContainer = Instance.new("Part")
    effectContainer.Size = Vector3.new(1, 1, 1) -- Small container
    effectContainer.CFrame = hitboxCFrame
    effectContainer.Anchored = true
    effectContainer.CanCollide = false
    effectContainer.CanQuery = false
    effectContainer.CanTouch = false
    effectContainer.Transparency = 1 -- Invisible container
    effectContainer.Parent = Workspace
    
    -- Determine duration and visual properties
    local duration, color, name
    if hitboxType == "weapon" then
        duration = customDuration or 0.3 -- Use custom duration or default 0.3s
        color = Color3.new(1, 0.2, 0.2) -- Bright red for weapons
        name = "WeaponHitboxEffect"
    elseif hitboxType == "skill" then
        duration = customDuration or 0.5 -- Use custom duration or default 0.5s
        color = Color3.new(0.2, 0.5, 1) -- Bright blue for skills
        name = "SkillHitboxEffect"
    else
        duration = customDuration or 0.3
        color = Color3.new(1, 1, 0.5) -- Bright yellow for unknown
        name = "HitboxEffect"
    end
    
    effectContainer.Name = name
    
    -- Create multiple particle effects for different visual layers
    local function createParticleEffect(part, particleColor, particleSize, particleSpeed, particleLifetime, particleRate)
        local attachment = Instance.new("Attachment")
        attachment.Parent = part
        
        local particles = Instance.new("ParticleEmitter")
        particles.Parent = attachment
        particles.Color = ColorSequence.new(particleColor)
        particles.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, particleSize * 0.5),
            NumberSequenceKeypoint.new(0.5, particleSize),
            NumberSequenceKeypoint.new(1, particleSize * 0.1)
        }
        particles.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.7, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        particles.Lifetime = NumberRange.new(particleLifetime, particleLifetime * 1.5)
        particles.Rate = particleRate
        particles.SpreadAngle = Vector2.new(45, 45)
        particles.Speed = NumberRange.new(particleSpeed * 0.5, particleSpeed)
        particles.VelocityInheritance = 0
        particles.Acceleration = Vector3.new(0, -10, 0) -- Gravity effect
        particles.Drag = 2
        
        return particles
    end
    
    -- Create main impact particles (explosion effect)
    local mainParticles = createParticleEffect(effectContainer, color, 2, 15, 0.8, 200)
    
    -- Create spark particles (smaller, faster)
    local sparkParticles = createParticleEffect(effectContainer, Color3.new(1, 1, 0.8), 0.5, 25, 0.4, 150)
    
    -- Create energy ring particles (outward expanding)
    local ringParticles = createParticleEffect(effectContainer, color, 1.5, 8, 1.2, 100)
    ringParticles.SpreadAngle = Vector2.new(360, 360) -- Full circle
    ringParticles.Speed = NumberRange.new(5, 12)
    
    -- Add weapon-specific effects
    if hitboxType == "weapon" then
        -- Create slash effect particles (for melee weapons)
        local slashParticles = createParticleEffect(effectContainer, Color3.new(1, 0.8, 0.2), 1, 20, 0.6, 80)
        slashParticles.SpreadAngle = Vector2.new(30, 30) -- Narrower spread for slash effect
        slashParticles.Speed = NumberRange.new(10, 20)
        
        -- Add weapon-type specific effects
        if weaponTag then
            if weaponTag == "berserker_weapon" then
                -- Berserker: Red, aggressive particles
                local berserkerParticles = createParticleEffect(effectContainer, Color3.new(1, 0.2, 0.2), 1.5, 25, 0.5, 150)
                berserkerParticles.SpreadAngle = Vector2.new(25, 25)
                berserkerParticles.Speed = NumberRange.new(15, 30)
            elseif weaponTag == "samurai_weapon" then
                -- Samurai: Blue, precise particles
                local samuraiParticles = createParticleEffect(effectContainer, Color3.new(0.2, 0.5, 1), 1.2, 18, 0.7, 100)
                samuraiParticles.SpreadAngle = Vector2.new(20, 20)
                samuraiParticles.Speed = NumberRange.new(12, 25)
            elseif weaponTag == "knight_weapon" then
                -- Knight: Gold, noble particles
                local knightParticles = createParticleEffect(effectContainer, Color3.new(1, 0.8, 0.2), 1.3, 15, 0.8, 120)
                knightParticles.SpreadAngle = Vector2.new(35, 35)
                knightParticles.Speed = NumberRange.new(10, 20)
            elseif weaponTag == "gladiator_weapon" then
                -- Gladiator: Purple, arena particles
                local gladiatorParticles = createParticleEffect(effectContainer, Color3.new(0.8, 0.2, 0.8), 1.8, 22, 0.6, 180)
                gladiatorParticles.SpreadAngle = Vector2.new(40, 40)
                gladiatorParticles.Speed = NumberRange.new(15, 28)
            elseif weaponTag == "archer_weapon" then
                -- Archer: Green, nature particles
                local archerParticles = createParticleEffect(effectContainer, Color3.new(0.2, 1, 0.3), 1.1, 20, 0.5, 130)
                archerParticles.SpreadAngle = Vector2.new(30, 30)
                archerParticles.Speed = NumberRange.new(12, 22)
            end
        end
        
        -- Add combo-specific effects (if this is a combo attack)
        if name and name:find("Combo") then
            -- Create combo burst effect
            local comboParticles = createParticleEffect(effectContainer, Color3.new(1, 0.5, 0), 2.5, 30, 0.4, 300)
            comboParticles.SpreadAngle = Vector2.new(20, 20) -- Tight burst
            comboParticles.Speed = NumberRange.new(15, 30)
        end
    elseif hitboxType == "skill" then
        -- Create magical energy particles (for skills)
        local magicParticles = createParticleEffect(effectContainer, Color3.new(0.8, 0.2, 1), 1.5, 12, 1.0, 120)
        magicParticles.SpreadAngle = Vector2.new(60, 60) -- Wider spread for magic
        magicParticles.Acceleration = Vector3.new(0, 5, 0) -- Upward float effect
        
        -- Add skill-specific effects
        if name and name:find("Storm") then
            -- Create storm effect (lightning-like)
            local stormParticles = createParticleEffect(effectContainer, Color3.new(0.5, 0.8, 1), 1, 35, 0.3, 250)
            stormParticles.SpreadAngle = Vector2.new(15, 15) -- Lightning-like
            stormParticles.Speed = NumberRange.new(20, 40)
        end
    end
    
    -- Square hitbox outline removed - only particles now!
    
    -- Stop particles and clean up after duration
    task.delay(duration, function()
        if mainParticles then mainParticles.Enabled = false end
        if sparkParticles then sparkParticles.Enabled = false end
        if ringParticles then ringParticles.Enabled = false end
        
        -- Wait a bit for particles to finish, then destroy
        task.wait(1.5)
        if effectContainer then
            effectContainer:Destroy()
        end
    end)
end

-- Generate hitbox for weapon attacks
function DynamicHitboxClient.generateWeaponHitbox(tool)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Get weapon-specific hitbox configuration
    local hitboxSize, hitboxOffset, weaponDamage, weaponTag = getHitboxConfig(tool)

    -- Generate hitbox position in front of the player using LookVector
    local rootCFrame = humanoidRootPart.CFrame
    local forwardOffset = rootCFrame.LookVector * hitboxOffset.Z
    local rightOffset = rootCFrame.RightVector * hitboxOffset.X
    local upOffset = rootCFrame.UpVector * hitboxOffset.Y
    local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset

    -- Align the generated hitbox with the player's facing direction
    local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

    print("[CLIENT DEBUG] Sending weapon hitbox request - damage:", weaponDamage)
    remote:FireServer(hitboxCFrame, hitboxSize, weaponDamage)

    -- Create visual hitbox
    createVisualHitbox(hitboxCFrame, hitboxSize, "weapon", nil, weaponTag)
end

-- =====================================================================================
-- GLOBAL ATTACK COOLDOWN SYSTEM
-- =====================================================================================

-- Global cooldown to prevent rapid weapon switching exploits
local GlobalAttackCooldown = {}

-- Global cooldown settings
-- Global cooldown will be set dynamically based on archer config
local GLOBAL_COOLDOWN_TIME = 0.1 -- Default fallback

-- Initialize global cooldown in _G to persist across weapon switches
if not _G.lastGlobalAttackEndTime then
    _G.lastGlobalAttackEndTime = 0
end

function GlobalAttackCooldown.isOnGlobalCooldown()
    local timeSinceLastAttack = tick() - _G.lastGlobalAttackEndTime
    
    -- Use archer config if available, otherwise use default
    local cooldownTime = GLOBAL_COOLDOWN_TIME
    if HitboxConfig and HitboxConfig.getArcherSetting then
        cooldownTime = HitboxConfig.getArcherSetting("globalCooldownOverride") or GLOBAL_COOLDOWN_TIME
    end
    
    return timeSinceLastAttack < cooldownTime
end

function GlobalAttackCooldown.getGlobalCooldownRemaining()
    local timeSinceLastAttack = tick() - _G.lastGlobalAttackEndTime
    
    -- Use archer config if available, otherwise use default
    local cooldownTime = GLOBAL_COOLDOWN_TIME
    if HitboxConfig and HitboxConfig.getArcherSetting then
        cooldownTime = HitboxConfig.getArcherSetting("globalCooldownOverride") or GLOBAL_COOLDOWN_TIME
    end
    
    return math.max(0, cooldownTime - timeSinceLastAttack)
end

function GlobalAttackCooldown.setGlobalCooldown()
    _G.lastGlobalAttackEndTime = tick()
end

function GlobalAttackCooldown.canStartNewAttack()
    if GlobalAttackCooldown.isOnGlobalCooldown() then
        local remaining = GlobalAttackCooldown.getGlobalCooldownRemaining()
        return false, remaining
    end
    return true, 0
end

-- =====================================================================================
-- SKILL COOLDOWN SYSTEM
-- =====================================================================================

-- Skill cooldown management functions
local SkillCooldownSystem = {}

function SkillCooldownSystem.isSkillOnCooldown(skillKey, cooldownTime)
    local lastUseTime = _G.skillCooldowns[skillKey] or 0
    local timeSinceLastUse = tick() - lastUseTime
    return timeSinceLastUse < cooldownTime
end

function SkillCooldownSystem.isSkillCasting(skillKey)
    return _G.skillCasting[skillKey] == true
end

function SkillCooldownSystem.setSkillCooldown(skillKey)
    _G.skillCooldowns[skillKey] = tick()
end

function SkillCooldownSystem.setSkillCasting(skillKey, isCasting)
    _G.skillCasting[skillKey] = isCasting
    
    -- Set global cooldown when skill casting ends
    if not isCasting then
        GlobalAttackCooldown.setGlobalCooldown()
    end
end

function SkillCooldownSystem.getSkillCooldownRemaining(skillKey, cooldownTime)
    local lastUseTime = _G.skillCooldowns[skillKey] or 0
    local timeSinceLastUse = tick() - lastUseTime
    return math.max(0, cooldownTime - timeSinceLastUse)
end

-- Generate hitbox for skill attacks (with cooldown and casting management)
function DynamicHitboxClient.generateSkillHitbox(skillKey)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Get skill-specific configuration including timing
    local skillConfig = getSkillHitboxConfig(skillKey)
    local size, offset, damage = skillConfig.size, skillConfig.offset, skillConfig.baseDamage
    local cooldownTime = skillConfig.cooldownTime or 2.0
    local castTime = skillConfig.castTime or 0.8
    local hitboxDelay = skillConfig.hitboxDelay or 0.3
    local hitboxDuration = skillConfig.hitboxDuration or 0.5

    -- Check if skill is on cooldown
    if SkillCooldownSystem.isSkillOnCooldown(skillKey, cooldownTime) then
        local remainingTime = SkillCooldownSystem.getSkillCooldownRemaining(skillKey, cooldownTime)
        return
    end

    -- Check if skill is already casting
    if SkillCooldownSystem.isSkillCasting(skillKey) then
        return
    end


    -- Start casting
    SkillCooldownSystem.setSkillCasting(skillKey, true)
    SkillCooldownSystem.setSkillCooldown(skillKey) -- Set cooldown immediately when cast starts

    -- Schedule hitbox generation after delay
    task.delay(hitboxDelay, function()
        if SkillCooldownSystem.isSkillCasting(skillKey) then -- Only generate if still casting
    -- Calculate hitbox position
    local rootCFrame = humanoidRootPart.CFrame
    local forwardOffset = rootCFrame.LookVector * offset.Z
    local rightOffset = rootCFrame.RightVector * offset.X
    local upOffset = rootCFrame.UpVector * offset.Y
    local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
    local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

            -- Get damage interval configuration
            local damageIntervalConfig = HitboxConfig.getDamageIntervalConfig()
            local damageInterval = damageIntervalConfig.hitboxDamageInterval
            
            -- Check if this should be a DOT hitbox (duration > damage interval)
            if hitboxDuration > damageInterval then
                -- Create DOT hitbox
                local damageInfo = HitboxConfig.calculateDamagePerTick(damage, hitboxDuration)
                local hitboxId = DOTSystem.generateUniqueHitboxId(skillKey, "skill")
                
                
                DOTSystem.createDOTHitbox(hitboxId, hitboxCFrame, size, damage, hitboxDuration, damageInterval, "skill")
            else
            -- Single-hit hitbox (traditional)
            print("[CLIENT DEBUG] Sending skill hitbox request - damage:", damage)
            remote:FireServer(hitboxCFrame, size, damage)
            end

            -- Create visual hitbox with custom duration
            createVisualHitbox(hitboxCFrame, size, "skill", hitboxDuration, nil)
            
        end
    end)

    -- End casting after cast time
    task.delay(castTime, function()
        SkillCooldownSystem.setSkillCasting(skillKey, false)
    end)
end

-- Generate arrow projectile hitbox (raycast-based for precise arrow hits)
function DynamicHitboxClient.generateArrowProjectile(tool, customSize, customOffset, customDamage, customDelay, customDuration, customAimAngleOffset)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Use custom values if provided, otherwise get weapon config
    local hitboxSize, hitboxOffset, weaponDamage, hitboxDelay, hitboxDuration
    if customSize and customOffset and customDamage then
        hitboxSize = customSize
        hitboxOffset = customOffset
        weaponDamage = customDamage
        hitboxDelay = customDelay or 0.0
        hitboxDuration = customDuration or 0.3
    else
        hitboxSize, hitboxOffset, weaponDamage = getHitboxConfig(tool)
        hitboxDelay = 0.0
        hitboxDuration = 0.3
    end

    -- Get projectile configuration for this weapon type
    local projectileConfig = nil
    if HitboxConfig then
        -- Find the weapon tag for this tool
        local weaponTags = HitboxConfig.getAllProjectileWeaponTags()
        for _, weaponTag in ipairs(weaponTags) do
            if CollectionService:HasTag(tool, weaponTag) then
                projectileConfig = HitboxConfig.getProjectileConfig(weaponTag)
                break
            end
        end
    end
    
    -- Use default projectile config if none found
    if not projectileConfig then
        projectileConfig = HitboxConfig and HitboxConfig.getDefaultProjectileConfig() or {
            projectileType = "arrow",
            speed = 200,
            range = 100,
            size = Vector3.new(0.5, 0.5, 3),
            color = Color3.new(1, 1, 0),
            transparency = 0.3,
            material = Enum.Material.Neon,
            hitboxSize = Vector3.new(2, 2, 2),
            hitboxDuration = 0.2,
            trailEffect = false,
            trailLength = 3,
            trailTransparency = 0.8,
        }
    end

    -- Apply hitbox delay
    local function fireProjectile()
        -- Get starting position from player's hand/bow position
        local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- Get configuration settings
        local spawnOffset = HitboxConfig and HitboxConfig.getArcherSpawnOffset() or Vector3.new(0, 2, 1)
        local aimAngleOffset = customAimAngleOffset or (HitboxConfig and HitboxConfig.getArcherAimAngleOffset() or Vector3.new(0, 0, 0))
        
        
        -- Start projectile from player's position with configurable offset
        local playerPosition = humanoidRootPart.Position
        local playerCFrame = humanoidRootPart.CFrame
        
        -- Apply spawn offset to player position
        local startPosition = playerPosition + (playerCFrame.RightVector * spawnOffset.X) + 
                             (playerCFrame.UpVector * spawnOffset.Y) + 
                             (playerCFrame.LookVector * spawnOffset.Z)
        
        -- Get camera's aim direction
        local camera = workspace.CurrentCamera
        local cameraDirection = camera.CFrame.LookVector
        
        -- Apply aim angle offset to camera direction
        local angleOffsetCFrame = CFrame.Angles(
            math.rad(aimAngleOffset.X), -- pitch
            math.rad(aimAngleOffset.Y), -- yaw
            math.rad(aimAngleOffset.Z)  -- roll
        )
        local adjustedDirection = angleOffsetCFrame * cameraDirection
        
        -- Calculate target position with adjusted direction
        local targetPosition = startPosition + (adjustedDirection * projectileConfig.range)
        local direction = adjustedDirection
        local endPosition = targetPosition
        
        -- Perform raycast for hit detection
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {player.Character} -- Don't hit self
        
        
        local raycastResult = workspace:Raycast(startPosition, direction * projectileConfig.range, raycastParams)
        
        -- Calculate hit position
        local hitPosition = raycastResult and raycastResult.Position or endPosition
        local actualRange = (hitPosition - startPosition).Magnitude
        
        
        -- Create projectile visual
        local projectile = Instance.new("Part")
        projectile.Name = projectileConfig.projectileType:gsub("^%l", string.upper) .. "Projectile"
        projectile.Size = projectileConfig.size
        projectile.Material = projectileConfig.material
        projectile.Color = projectileConfig.color
        projectile.Transparency = projectileConfig.transparency
        projectile.CanCollide = false
        projectile.Anchored = true
        projectile.Parent = workspace
        
        -- Position projectile at start
        local projectileCFrame = CFrame.lookAt(startPosition, hitPosition)
        projectile.CFrame = projectileCFrame
        
        -- Calculate travel time
        local travelTime = actualRange / projectileConfig.speed
        
        -- Animate projectile movement
        local startTime = tick()
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local progress = math.min(elapsed / travelTime, 1)
            
                    if progress >= 1 then
                        -- Projectile reached target
                        connection:Disconnect()
                        projectile:Destroy()
                        
                        -- Simple damage logic: if raycast hits a humanoid within range, damage them
                        if raycastResult then
                            local hitInstance = raycastResult.Instance
                            local hitCharacter = hitInstance.Parent
                            
                            -- Check if we hit a humanoid
                            if hitCharacter and hitCharacter:FindFirstChild("Humanoid") then
                                -- Calculate distance from player to hit target
                                local distanceToTarget = (hitPosition - startPosition).Magnitude
                                
                                -- Only damage if within range
                                if distanceToTarget <= projectileConfig.range then
                                    -- Create damage hitbox at the hit position
                                    local hitCFrame = CFrame.new(hitPosition, hitPosition + direction)
                                    remote:FireServer(hitCFrame, projectileConfig.hitboxSize, weaponDamage)
                                    
                                    -- Create visual hit effect
                                    createVisualHitbox(hitCFrame, projectileConfig.hitboxSize, "weapon", projectileConfig.hitboxDuration, "archer_weapon")
                                end
                            end
                        end
            else
                -- Move projectile along path
                local currentPosition = startPosition + (direction * actualRange * progress)
                projectile.CFrame = CFrame.lookAt(currentPosition, hitPosition)
            end
        end)
        
        -- Safety cleanup after maximum time
        task.delay(travelTime + 1, function()
            if projectile and projectile.Parent then
                projectile:Destroy()
            end
            if connection then
                connection:Disconnect()
            end
        end)
    end

    -- Fire projectile immediately or after delay
    if hitboxDelay > 0 then
        task.delay(hitboxDelay, fireProjectile)
    else
        fireProjectile()
    end
end

-- Generate hitbox for combo attacks (uses weapon config but allows custom override with optional delay and duration)
function DynamicHitboxClient.generateComboHitbox(tool, customSize, customOffset, customDamage, customDelay, customDuration)
    if not player.Character then return end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Use custom values if provided, otherwise get weapon config
    local hitboxSize, hitboxOffset, weaponDamage, hitboxDelay, hitboxDuration, weaponTag
    if customSize and customOffset and customDamage then
        hitboxSize = customSize
        hitboxOffset = customOffset
        weaponDamage = customDamage
        hitboxDelay = customDelay or 0.0 -- Default to immediate if no delay specified
        hitboxDuration = customDuration or 0.3 -- Default to 0.3s if no duration specified
        weaponTag = nil -- No weapon tag for custom hitboxes
    else
        hitboxSize, hitboxOffset, weaponDamage, weaponTag = getHitboxConfig(tool)
        hitboxDelay = 0.0 -- Default weapon hitboxes have no delay
        hitboxDuration = 0.3 -- Default weapon hitboxes last 0.3s
    end

    -- Apply hitbox delay (like skills)
    local function generateActualHitbox()
        -- Calculate hitbox position
        local rootCFrame = humanoidRootPart.CFrame
        local forwardOffset = rootCFrame.LookVector * hitboxOffset.Z
        local rightOffset = rootCFrame.RightVector * hitboxOffset.X
        local upOffset = rootCFrame.UpVector * hitboxOffset.Y
        local hitboxPosition = rootCFrame.Position + forwardOffset + rightOffset + upOffset
        local hitboxCFrame = CFrame.new(hitboxPosition, hitboxPosition + rootCFrame.LookVector)

        -- Get damage interval configuration
        local damageIntervalConfig = HitboxConfig.getDamageIntervalConfig()
        local damageInterval = damageIntervalConfig.hitboxDamageInterval
        
        -- Check if this should be a DOT hitbox (duration > damage interval)
        if hitboxDuration > damageInterval then
            -- Create DOT hitbox
            local damageInfo = HitboxConfig.calculateDamagePerTick(weaponDamage, hitboxDuration)
            local hitboxId = DOTSystem.generateUniqueHitboxId("combo", "attack")
            
            
            DOTSystem.createDOTHitbox(hitboxId, hitboxCFrame, hitboxSize, weaponDamage, hitboxDuration, damageInterval, "weapon")
        else
            -- Single-hit hitbox (traditional)
            print("[CLIENT DEBUG] Sending combo hitbox request - damage:", weaponDamage)
            remote:FireServer(hitboxCFrame, hitboxSize, weaponDamage)
        end

        -- Create visual hitbox (red like weapon attacks) with custom duration
        createVisualHitbox(hitboxCFrame, hitboxSize, "weapon", hitboxDuration, weaponTag)
        
    end

    -- Generate hitbox immediately or after delay
    if hitboxDelay > 0 then
        task.delay(hitboxDelay, generateActualHitbox)
    else
        generateActualHitbox()
    end
end

-- =====================================================================================
-- COMBO STATE TRACKING (to disable tool activation during combos)
-- =====================================================================================

-- Global combo state tracking
_G.comboSystemActive = false -- Set to true when any combo system is running
_G.lastComboTime = 0 -- Track when last combo attack happened

-- Global skill cooldown tracking
_G.skillCooldowns = {} -- Track last use time for each skill
_G.skillCasting = {} -- Track if skills are currently casting

-- Global damage over time tracking
_G.activeDOTHitboxes = {} -- Track active DOT hitboxes
_G.playerDamageImmunity = {} -- Track player immunity to specific hitboxes

-- DOT Hitbox Management System
DOTSystem = {}

function DOTSystem.createDOTHitbox(hitboxId, hitboxCFrame, size, damagePerTick, duration, interval, hitboxType)
    local dotHitbox = {
        id = hitboxId,
        cframe = hitboxCFrame,
        size = size,
        damagePerTick = damagePerTick, -- Full base damage every tick
        duration = duration,
        interval = interval,
        startTime = tick(),
        hitboxType = hitboxType,
        nextTickTime = tick() + interval, -- When next damage tick should happen
        isActive = true
    }
    
    _G.activeDOTHitboxes[hitboxId] = dotHitbox
    
    
    -- Apply first damage immediately
    remote:FireServer(hitboxCFrame, size, damagePerTick, hitboxId, 1)
    
    -- Start the DOT damage loop for subsequent ticks
    DOTSystem.startDamageLoop(hitboxId)
    
    -- Auto-cleanup after duration
    task.delay(duration, function()
        DOTSystem.removeDOTHitbox(hitboxId)
    end)
    
    return dotHitbox
end

function DOTSystem.startDamageLoop(hitboxId)
    local dotHitbox = _G.activeDOTHitboxes[hitboxId]
    if not dotHitbox then return end
    
    local tickNumber = 1 -- First tick already applied
    
    local function applyNextTick()
        dotHitbox = _G.activeDOTHitboxes[hitboxId] -- Refresh reference
        if not dotHitbox or not dotHitbox.isActive then return end -- Hitbox was removed or expired
        
        local currentTime = tick()
        local elapsedTime = currentTime - dotHitbox.startTime
        
        -- Check if hitbox duration has expired
        if elapsedTime >= dotHitbox.duration then
            DOTSystem.removeDOTHitbox(hitboxId)
            return
        end
        
        -- Apply damage for this tick
        tickNumber = tickNumber + 1
        
        -- Send damage to server
        remote:FireServer(dotHitbox.cframe, dotHitbox.size, dotHitbox.damagePerTick, hitboxId, tickNumber)
        
        -- Schedule next tick if there's still time
        local timeUntilExpiry = dotHitbox.duration - elapsedTime
        if timeUntilExpiry > dotHitbox.interval then
            task.delay(dotHitbox.interval, applyNextTick)
        else
        end
    end
    
    -- Schedule first interval tick
    task.delay(dotHitbox.interval, applyNextTick)
end

function DOTSystem.removeDOTHitbox(hitboxId)
    if _G.activeDOTHitboxes[hitboxId] then
        _G.activeDOTHitboxes[hitboxId] = nil
    end
end

function DOTSystem.generateUniqueHitboxId(skillKey, attackType)
    local timestamp = tostring(tick()):gsub("%.", "_")
    return string.format("%s_%s_%s_%s", player.Name, skillKey or "weapon", attackType or "attack", timestamp)
end

-- Function to check if we should allow tool activation
local function shouldAllowToolActivation(tool)
    -- Check if this is a weapon with combo system
    local weaponTags = {"berserker_weapon", "archer_weapon", "gladiator_weapon", "knight_weapon", "samurai_weapon"}
    
    for _, weaponTag in ipairs(weaponTags) do
        if CollectionService:HasTag(tool, weaponTag) then
            -- For all class weapons, ALWAYS block tool activation
            -- The combo system should handle ALL weapon attacks
            return false
        end
    end
    
    return true
end

-- =====================================================================================
-- WEAPON TOOL INTEGRATION (existing functionality)
-- =====================================================================================

local function setupHitboxGeneration(tool)
    if not tool:IsA("Tool") then return end
    if not CollectionService:HasTag(tool, "has_damage") then return end

    local function generateHitbox()
        -- Check if we should allow tool activation
        if not shouldAllowToolActivation(tool) then
            return
        end
        
        DynamicHitboxClient.generateWeaponHitbox(tool)
    end

    tool.Activated:Connect(generateHitbox)
end

-- Listen for tools equipped by the player
local function onCharacterAdded(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            setupHitboxGeneration(child)
        end
    end)
    -- Setup hitbox generation for already equipped tools
    for i, child in character:GetChildren() do
        if child:IsA("Tool") and CollectionService:HasTag(child, "has_damage") then
            setupHitboxGeneration(child)
        end
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

-- =====================================================================================
-- GLOBAL ACCESS (so other scripts can use skill and combo hitbox generation)
-- =====================================================================================

-- Make skill hitbox generation available globally
_G.generateSkillHitbox = DynamicHitboxClient.generateSkillHitbox

-- Make combo hitbox generation available globally
_G.generateComboHitbox = DynamicHitboxClient.generateComboHitbox

-- Make arrow projectile generation available globally
_G.generateArrowProjectile = DynamicHitboxClient.generateArrowProjectile

-- Generate burst shot (multiple arrows with spread)
function DynamicHitboxClient.generateBurstShot(weapon, skillConfig)
    if not weapon or not skillConfig then return end
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Get projectile configuration
    local projectileConfig = HitboxConfig and HitboxConfig.getProjectileConfig("archer_weapon") or {}
    local weaponConfig = HitboxConfig and HitboxConfig.getWeaponConfig("archer_weapon") or {}
    local weaponDamage = weaponConfig.baseDamage or 5
    
    -- Get burst shot configuration
    local projectileCount = skillConfig.projectileCount or 5
    local spreadAngle = skillConfig.spreadAngle or 30
    local fireDelay = skillConfig.fireDelay or 0.1
    
    print("[ARCHER BURST SHOT] Firing", projectileCount, "arrows with", spreadAngle, "degree spread")
    
    -- Get spawn offset and aim angle offset
    local spawnOffset = HitboxConfig and HitboxConfig.getArcherSpawnOffset() or Vector3.new(0, 0, 1)
    local baseAimAngleOffset = HitboxConfig and HitboxConfig.getArcherAimAngleOffset() or Vector3.new(0, 0, 0)
    
    -- Calculate spread angles
    local angleStep = spreadAngle / (projectileCount - 1)
    local startAngle = -spreadAngle / 2
    
    -- Fire arrows with delay
    for i = 1, projectileCount do
        task.delay((i - 1) * fireDelay, function()
            -- Calculate this arrow's angle offset
            local currentAngle = startAngle + (i - 1) * angleStep
            local aimAngleOffset = Vector3.new(
                baseAimAngleOffset.X,
                baseAimAngleOffset.Y + currentAngle, -- Add spread to yaw
                baseAimAngleOffset.Z
            )
            
            -- Generate single arrow with custom aim offset
            DynamicHitboxClient.generateArrowProjectile(weapon, projectileConfig.size, spawnOffset, weaponDamage, 0, projectileConfig.hitboxDuration, aimAngleOffset)
        end)
    end
end

-- Make burst shot generation available globally
_G.generateBurstShot = DynamicHitboxClient.generateBurstShot

-- Force reload HitboxConfig (for testing configuration changes)
_G.reloadHitboxConfig = function()
    local success, newConfig = pcall(function()
        return require(script.Parent.Parent.shared.HitboxConfig)
    end)
    if success then
        HitboxConfig = newConfig
        print("[ARCHER PROJECTILE] HitboxConfig reloaded successfully")
        return true
    else
        print("[ARCHER PROJECTILE] Failed to reload HitboxConfig:", newConfig)
        return false
    end
end

-- Quick configuration test functions
_G.testArcherConfig = function()
    if HitboxConfig then
        local config = HitboxConfig.getProjectileConfig("archer_weapon")
        print("[ARCHER PROJECTILE] Current spawnOffset:", config.spawnOffset)
        print("[ARCHER PROJECTILE] Current aimAngleOffset:", config.aimAngleOffset)
        print("[ARCHER PROJECTILE] Current crosshairOffset:", config.crosshairOffset)
    else
        print("[ARCHER PROJECTILE] HitboxConfig not available")
    end
end

_G.setArcherSpawnOffset = function(x, y, z)
    if HitboxConfig and HitboxConfig.setArcherSpawnOffset then
        return HitboxConfig.setArcherSpawnOffset(x, y, z)
    else
        print("[ARCHER PROJECTILE] HitboxConfig not available or function not found")
        return false
    end
end

_G.setArcherAimAngleOffset = function(x, y, z)
    if HitboxConfig and HitboxConfig.setArcherAimAngleOffset then
        return HitboxConfig.setArcherAimAngleOffset(x, y, z)
    else
        print("[ARCHER PROJECTILE] HitboxConfig not available or function not found")
        return false
    end
end

-- Make skill cooldown functions available globally for debugging
_G.getSkillCooldown = function(skillKey, cooldownTime)
    return SkillCooldownSystem.getSkillCooldownRemaining(skillKey, cooldownTime or 2.0)
end

_G.resetSkillCooldown = function(skillKey)
    _G.skillCooldowns[skillKey] = 0
    _G.skillCasting[skillKey] = false
end

_G.resetAllSkillCooldowns = function()
    _G.skillCooldowns = {}
    _G.skillCasting = {}
end

-- Expose global cooldown system
_G.canStartNewAttack = GlobalAttackCooldown.canStartNewAttack
_G.setGlobalCooldown = GlobalAttackCooldown.setGlobalCooldown
_G.getGlobalCooldownRemaining = GlobalAttackCooldown.getGlobalCooldownRemaining

_G.debugSkillCooldowns = function()
    for skillKey, lastUse in pairs(_G.skillCooldowns) do
        local isCasting = _G.skillCasting[skillKey] or false
        local timeSinceUse = tick() - lastUse
    end
end

-- Make DOT system functions available globally for debugging
_G.debugDOTHitboxes = function()
    for hitboxId, dotHitbox in pairs(_G.activeDOTHitboxes) do
        local elapsed = tick() - dotHitbox.startTime
    end
end

_G.clearAllDOTHitboxes = function()
    local count = 0
    for hitboxId, _ in pairs(_G.activeDOTHitboxes) do
        _G.activeDOTHitboxes[hitboxId] = nil
        count = count + 1
    end
end

_G.getDamageInterval = function()
    if HitboxConfig then
        return HitboxConfig.getDamageInterval()
    end
    return 0.5
end

_G.testDOTCalculations = function()
    if HitboxConfig then
        return HitboxConfig.testDOTCalculations()
    else
    end
end

-- =====================================================================================
-- HITBOX VISUAL CONTROL FUNCTIONS
-- =====================================================================================

-- Toggle hitbox visual previews on/off
_G.setHitboxVisualsEnabled = function(enabled)
    SHOW_HITBOX_VISUALS = enabled
    print("[HITBOX VISUALS] Visual previews", enabled and "ENABLED" or "DISABLED")
end

-- Get current hitbox visual state
_G.getHitboxVisualsEnabled = function()
    return SHOW_HITBOX_VISUALS
end

-- Toggle hitbox visuals on/off
_G.toggleHitboxVisuals = function()
    SHOW_HITBOX_VISUALS = not SHOW_HITBOX_VISUALS
    print("[HITBOX VISUALS] Particle effects", SHOW_HITBOX_VISUALS and "ENABLED" or "DISABLED")
    return SHOW_HITBOX_VISUALS
end

-- Demo-specific functions for easy testing
_G.enableParticleEffects = function()
    SHOW_HITBOX_VISUALS = true
    print("[DEMO] ✨ Particle effects ENABLED - Hitboxes now show cool particle effects!")
    return true
end

_G.disableParticleEffects = function()
    SHOW_HITBOX_VISUALS = false
    print("[DEMO] 🚫 Particle effects DISABLED - Hitboxes are invisible")
    return false
end

-- Quick demo commands
print("[DEMO] 🎮 Particle Effects Demo Commands:")
print("  _G.enableParticleEffects()  - Enable cool particle effects")
print("  _G.disableParticleEffects() - Disable particle effects")
print("  _G.toggleHitboxVisuals()    - Toggle particle effects on/off")

-- =====================================================================================
-- ANNOUNCEMENT SYSTEM EXPORTS
-- =====================================================================================

-- Expose announcement system globally for use by other scripts
_G.showComboAttack = AnnouncementSystem.showComboAttack
_G.showSkill = AnnouncementSystem.showSkill
_G.showCooldown = AnnouncementSystem.showCooldown
_G.clearAllAnnouncements = AnnouncementSystem.clearAll

-- =====================================================================================
-- EXPORT MODULE
-- =====================================================================================

return DynamicHitboxClient
