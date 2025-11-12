-- ========================================
-- STATUS AILMENT HANDLER
-- Manages status ailments on characters (players and mobs)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Import configuration
local ServerConfigs = require(game.ReplicatedStorage:WaitForChild("SlavkosConfigs"))

-- Remote event for locking player actions (shared with action handlers)
local ActionEvent = ReplicatedStorage:WaitForChild("ActionEvent")

-- ========================================
-- STATUS AILMENT TRACKING
-- ========================================

-- Track active ailments per character
local activeAilments = {} -- {model: {[ailmentType]: {duration, startTime, config}}}

-- Store original stats to restore after ailments expire
local originalStats = {} -- {model: {walkSpeed, jumpPower, platformStand}}

-- Track status text displays per character
local statusTextDisplays = {} -- {model: {[textType]: billboardGui}}

-- ========================================
-- AILMENT TYPES
-- ========================================

local AilmentTypes = {
	STUN = "stun",           -- Stops all movement
	POISON = "poison",       -- DPS damage (purple highlight)
	BURN = "burn",           -- DPS damage (orange highlight)
	ICE = "ice",             -- Slow + Damage (blue highlight)
	SLOW = "slow"            -- Reduces movement speed
}

local AilmentDisplayInfo = {
	[AilmentTypes.STUN] = {text = "STUNNED", color = Color3.new(0.5, 0.5, 0.5)}, -- Gray
	[AilmentTypes.POISON] = {text = "POISONED", color = Color3.new(0.5, 0, 0.5)}, -- Purple
	[AilmentTypes.BURN] = {text = "BURNED", color = Color3.new(1, 0.5, 0)}, -- Orange
	[AilmentTypes.ICE] = {text = "FROZEN", color = Color3.new(0, 0.5, 1)}, -- Blue
	[AilmentTypes.SLOW] = {text = "SLOWED", color = Color3.new(0.5, 0.5, 1)} -- Light Blue
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function to get player from model
local function getPlayer(model)
	if not model then return nil end
	return Players:GetPlayerFromCharacter(model)
end

-- Function to get humanoid from model
local function getHumanoid(model)
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

-- Function to get HumanoidRootPart from model
local function getHumanoidRootPart(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart")
end

-- Function to restore original stats
local function restoreOriginalStats(model)
	if not model or not originalStats[model] then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid then return end

	local player = getPlayer(model)

	local player = getPlayer(model)
	local player = getPlayer(model)
	local player = getPlayer(model)
	
	local stats = originalStats[model]
	
	-- Restore walk speed
	if stats.walkSpeed then
		humanoid.WalkSpeed = stats.walkSpeed
	end
	
	-- Restore jump power
	if stats.jumpPower then
		humanoid.JumpPower = stats.jumpPower
	end
	
	-- Restore platform stand
	if stats.platformStand ~= nil then
		humanoid.PlatformStand = stats.platformStand
	end
	
	-- Restore HumanoidRootPart anchored state
	if stats.rootAnchored ~= nil then
		local rootPart = getHumanoidRootPart(model)
		if rootPart then
			rootPart.Anchored = stats.rootAnchored
		end
	end

	-- Restore Animate script state
	if stats.animateDisabled ~= nil then
		local animateScript = model:FindFirstChild("Animate")
		if animateScript then
			animateScript.Disabled = stats.animateDisabled
		end
	end

	-- Clean up stored stats
	originalStats[model] = nil
end

-- Function to save original stats
local function saveOriginalStats(model)
	if not model then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid then return end
	
	local rootPart = getHumanoidRootPart(model)
	local animateScript = model:FindFirstChild("Animate")
	
	-- Only save if not already saved
	if not originalStats[model] then
		originalStats[model] = {
			walkSpeed = humanoid.WalkSpeed,
			jumpPower = humanoid.JumpPower,
			platformStand = humanoid.PlatformStand,
			rootAnchored = rootPart and rootPart.Anchored or false,
			animateDisabled = animateScript and animateScript.Disabled or nil
		}
	end
end

-- Function to create or update status text above character head
local function createOrUpdateStatusText(model, ailmentType, text, textColor, startTime, duration)
	if not model or not model.Parent then return nil end
	
	-- Get character's head or HumanoidRootPart
	local head = model:FindFirstChild("Head")
	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
	
	if not head and not humanoidRootPart then
		return nil
	end
	
	-- Use head if available, otherwise use HumanoidRootPart
	local attachPart = head or humanoidRootPart
	if not attachPart then
		return nil
	end
	
	-- Check if status text already exists for this ailment type
	if statusTextDisplays[model] and statusTextDisplays[model][ailmentType] then
		local existingText = statusTextDisplays[model][ailmentType]
		if existingText and existingText.Parent then
			-- Text already exists, just return it (duration will be monitored by heartbeat loop)
			return existingText
		else
			-- Text exists but was destroyed, remove from tracking
			statusTextDisplays[model][ailmentType] = nil
		end
	end
	
	-- Create new BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "StatusText_" .. ailmentType .. "_" .. tostring(tick() * 1000)
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Above head
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboardGui.Parent = attachPart
	
	-- Create TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = textColor or Color3.new(1, 1, 1)
	textLabel.TextSize = 20
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = billboardGui
	
	-- Initialize status text tracking for this model
	if not statusTextDisplays[model] then
		statusTextDisplays[model] = {}
	end
	
	-- Store text display with start time and duration for monitoring
	statusTextDisplays[model][ailmentType] = {
		billboardGui = billboardGui,
		startTime = startTime,
		duration = duration
	}
	
	return billboardGui
end

-- Function to create ailment highlight
local function createAilmentHighlight(model, ailmentType)
	if not model or not model.Parent then return end
	
	local config = ServerConfigs.Hitbox.statusAilments[ailmentType]
	if not config then return end
	
	-- Remove existing highlight for this ailment type
	local existingHighlight = model:FindFirstChild("StatusAilment_" .. ailmentType)
	if existingHighlight then
		existingHighlight:Destroy()
	end
	
	-- Create new highlight
	local highlight = Instance.new("Highlight")
	highlight.Parent = model
	highlight.Name = "StatusAilment_" .. ailmentType
	
	-- Apply configuration
	highlight.FillColor = config.highlightColor.fillColor
	highlight.FillTransparency = config.highlightColor.fillTransparency
	highlight.OutlineColor = config.highlightColor.outlineColor
	highlight.OutlineTransparency = config.highlightColor.outlineTransparency
	
	return highlight
end

local function shouldDisplayStatusText(model)
	if not model then
		return false
	end

	local player = getPlayer(model)
	if player then
		if _G.hasStatusImmunity then
			local hasImmunity = _G.hasStatusImmunity(player)
			if hasImmunity then
				return false
			end
		end
	end

	return true
end

-- Function to apply ailment effects
local function applyAilmentEffects(model, ailmentType, config)
	if not model then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid then return end

	local player = getPlayer(model)

	-- Save original stats if not already saved
	saveOriginalStats(model)
	
	if ailmentType == AilmentTypes.STUN then
		-- Stun: Stop all movement and anchor in place
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.PlatformStand = true

		-- Stop any currently playing animations
		for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end

		-- Disable the default animation controller so new animations don't play
		local animateScript = model:FindFirstChild("Animate")
		if animateScript then
			if originalStats[model] and originalStats[model].animateDisabled == nil then
				originalStats[model].animateDisabled = animateScript.Disabled
			end
			animateScript.Disabled = true
		end

		-- Play the freeze animation while stunned
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local freezeAnimation = Instance.new("Animation")
		freezeAnimation.Name = "StatusAilment_Freeze"
		freezeAnimation.AnimationId = "rbxassetid://113085102503802"

		local freezeTrack = animator:LoadAnimation(freezeAnimation)
		freezeTrack.Priority = Enum.AnimationPriority.Action4
		freezeTrack.Looped = true
		freezeTrack:Play(0)

		local ailmentRecord = activeAilments[model] and activeAilments[model][ailmentType]
		if ailmentRecord then
			ailmentRecord.freezeTrack = freezeTrack
			ailmentRecord.freezeAnimation = freezeAnimation
		else
			freezeTrack:Stop()
			freezeTrack:Destroy()
			freezeAnimation:Destroy()
		end
		
		-- Anchor HumanoidRootPart to prevent sinking
		local rootPart = getHumanoidRootPart(model)
		if rootPart then
			rootPart.Anchored = true
		end

		-- Lock player input and movement via client controls
		if player then
			ActionEvent:FireClient(player, "lock_input")
			ActionEvent:FireClient(player, "lock_movement")
		end
		
	elseif ailmentType == AilmentTypes.SLOW then
		-- Slow: Reduce movement speed
		-- Get slow multiplier from config or default config
		local ailmentConfig = ServerConfigs.Hitbox.statusAilments[AilmentTypes.SLOW]
		local slowMultiplier = config.slowMultiplier or (ailmentConfig and ailmentConfig.slowMultiplier) or 0.5 -- Default 50% speed
		local currentSpeed = originalStats[model] and originalStats[model].walkSpeed or humanoid.WalkSpeed
		humanoid.WalkSpeed = currentSpeed * slowMultiplier
		
	elseif ailmentType == AilmentTypes.ICE then
		-- Ice: Slow + Damage
		-- Get slow multiplier from config or default config
		local ailmentConfig = ServerConfigs.Hitbox.statusAilments[AilmentTypes.ICE]
		local slowMultiplier = config.slowMultiplier or (ailmentConfig and ailmentConfig.slowMultiplier) or 0.3 -- Default 30% speed
		local currentSpeed = originalStats[model] and originalStats[model].walkSpeed or humanoid.WalkSpeed
		humanoid.WalkSpeed = currentSpeed * slowMultiplier
	end
	
	-- Create visual highlight
	createAilmentHighlight(model, ailmentType)
	
	-- Create status text above head for players and mobs when applicable
	if shouldDisplayStatusText(model) then
		local ailmentInfo = AilmentDisplayInfo[ailmentType]
		if ailmentInfo then
			local ailmentData = activeAilments[model] and activeAilments[model][ailmentType]
			if ailmentData then
				local startTime = ailmentData.startTime
				local duration = ailmentData.duration or config.duration or 5.0
				createOrUpdateStatusText(model, ailmentType, ailmentInfo.text, ailmentInfo.color, startTime, duration)
			end
		end
	end
end

-- Function to remove ailment effects
local function removeAilmentEffects(model, ailmentType)
	if not model then return end
	
	-- Remove highlight
	local highlight = model:FindFirstChild("StatusAilment_" .. ailmentType)
	if highlight then
		highlight:Destroy()
	end

	-- Handle stun animation cleanup
	if ailmentType == AilmentTypes.STUN then
		local ailmentsForModel = activeAilments[model]
		if ailmentsForModel and ailmentsForModel[ailmentType] then
			local ailmentData = ailmentsForModel[ailmentType]

			if ailmentData.freezeTrack then
				ailmentData.freezeTrack:Stop(0)
				ailmentData.freezeTrack:Destroy()
				ailmentData.freezeTrack = nil
			end

			if ailmentData.freezeAnimation then
				ailmentData.freezeAnimation:Destroy()
				ailmentData.freezeAnimation = nil
			end
		end

		local animateScript = model:FindFirstChild("Animate")
		if animateScript then
			local stats = originalStats[model]
			if stats and stats.animateDisabled ~= nil then
				animateScript.Disabled = stats.animateDisabled
			else
				animateScript.Disabled = false
			end
		end
	end

	-- Unlock player controls when stun ends
	if ailmentType == AilmentTypes.STUN then
		local player = getPlayer(model)
		if player then
			ActionEvent:FireClient(player, "unlock_input")
			ActionEvent:FireClient(player, "unlock_movement")
		end
	end
	
	-- Remove status text for this ailment
	if statusTextDisplays[model] and statusTextDisplays[model][ailmentType] then
		local statusTextData = statusTextDisplays[model][ailmentType]
		if statusTextData then
			-- Handle both old format (just billboardGui) and new format (table with billboardGui)
			local billboardGui = statusTextData.billboardGui or statusTextData
			if billboardGui and billboardGui.Parent then
				billboardGui:Destroy()
			end
		end
		statusTextDisplays[model][ailmentType] = nil
	end
	
	-- Check if there are other active ailments
	local ailments = activeAilments[model]
	if ailments then
		-- Remove this ailment from tracking
		ailments[ailmentType] = nil
		
		-- Check if any slow/stun ailments remain
		local hasSlowEffect = false
		local slowMultiplier = 1.0
		
		for type, ailmentData in pairs(ailments) do
			if type == AilmentTypes.STUN then
				hasSlowEffect = true
				slowMultiplier = 0 -- Stun overrides everything
				break
			elseif type == AilmentTypes.SLOW or type == AilmentTypes.ICE then
				hasSlowEffect = true
				-- Get slow multiplier from active ailment's config or default config
				local ailmentData = ailments[type]
				local ailmentConfig = ServerConfigs.Hitbox.statusAilments[type]
				local ailmentSlowMultiplier = nil
				
				if ailmentData and ailmentData.config and ailmentData.config.slowMultiplier then
					ailmentSlowMultiplier = ailmentData.config.slowMultiplier
				elseif ailmentConfig and ailmentConfig.slowMultiplier then
					ailmentSlowMultiplier = ailmentConfig.slowMultiplier
				end
				
				if ailmentSlowMultiplier then
					slowMultiplier = math.min(slowMultiplier, ailmentSlowMultiplier)
				end
			end
		end
		
		-- If no slow effects remain, restore original stats
		if not hasSlowEffect then
			restoreOriginalStats(model)
		else
			-- Reapply slow effects with the worst multiplier
			local humanoid = getHumanoid(model)
			if humanoid and originalStats[model] then
				if ailments[AilmentTypes.STUN] then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
					humanoid.PlatformStand = true
					-- Re-anchor HumanoidRootPart when stun is still active
					local rootPart = getHumanoidRootPart(model)
					if rootPart then
						rootPart.Anchored = true
					end
				else
					local currentSpeed = originalStats[model].walkSpeed
					humanoid.WalkSpeed = currentSpeed * slowMultiplier
				end
			end
		end
		
		-- Clean up if no ailments remain
		local hasAnyAilment = false
		for _ in pairs(ailments) do
			hasAnyAilment = true
			break
		end
		if not hasAnyAilment then
			activeAilments[model] = nil
			restoreOriginalStats(model)
		end
	else
		-- No ailments left, restore stats
		restoreOriginalStats(model)
	end
end

-- Function to apply DPS damage
local function applyDPSDamage(model, ailmentType, damage, tickInterval, skipDefense)
	if not model then return end
	
	local humanoid = getHumanoid(model)
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- If skipDefense is true, bypass all defense calculations and apply damage directly to health
	-- This works for all status ailments (POISON, BURN, ICE)
	if skipDefense then
		humanoid:TakeDamage(damage)
		-- Create damage number display
		if _G.createDamageNumber then
			_G.createDamageNumber(model, damage)
		end
		return
	end
	
	-- Get defense stats (from DynamicHitboxV3)
	local currentDefense, maxDefense = 0, 0
	local player = getPlayer(model)
	
	if player and player:FindFirstChild("leaderstats") then
		local leaderstats = player.leaderstats
		if leaderstats:FindFirstChild("MaxDefense") then
			maxDefense = leaderstats.MaxDefense.Value
		end
		if leaderstats:FindFirstChild("CurrentDefense") then
			currentDefense = leaderstats.CurrentDefense.Value
		else
			currentDefense = maxDefense
		end
	elseif model:IsA("Model") then
		currentDefense = model:GetAttribute("CurrentDefense") or 0
		maxDefense = model:GetAttribute("MaxDefense") or 0
	end
	
	-- Calculate damage with defense (simplified - no penetration for DPS)
	local damageToHealth = 0
	local damageToDefense = 0
	
	if currentDefense > 0 then
		if damage <= currentDefense then
			damageToDefense = damage
			damageToHealth = 0
		else
			damageToDefense = currentDefense
			damageToHealth = damage - currentDefense
		end
	else
		damageToHealth = damage
		damageToDefense = 0
	end
	
	-- Apply damage to health
	if damageToHealth > 0 then
		humanoid:TakeDamage(damageToHealth)
	end
	
	-- Apply damage to defense
	if damageToDefense > 0 then
		if player and player:FindFirstChild("leaderstats") then
			local leaderstats = player.leaderstats
			local currentDefStat = leaderstats:FindFirstChild("CurrentDefense")
			if currentDefStat then
				currentDefStat.Value = math.max(0, currentDefStat.Value - damageToDefense)
			end
		elseif model:IsA("Model") then
			model:SetAttribute("CurrentDefense", math.max(0, currentDefense - damageToDefense))
		end
	end
	
	-- Create damage number display (show total damage: health + defense)
	-- Only show if there's actual damage dealt
	if (damageToHealth + damageToDefense) > 0 then
		if _G.createDamageNumber then
			_G.createDamageNumber(model, damageToHealth + damageToDefense)
		end
	end
end

-- ========================================
-- MAIN AILMENT FUNCTIONS
-- ========================================

-- Function to apply a status ailment to a model
-- @param model: The character model
-- @param ailmentType: Type of ailment (AilmentTypes.STUN, etc.)
-- @param config: Configuration {duration, chance, dps, tickInterval, slowMultiplier}
function _G.applyStatusAilment(model, ailmentType, config)
	if not model or not model.Parent then return end
	if not ailmentType or not ServerConfigs.Hitbox.statusAilments[ailmentType] then return end
	
	-- Check for status immunity (LastChance buff) - only for players
	local player = getPlayer(model)
	if player then
		-- Check if function exists (defensive check)
		if _G.hasStatusImmunity then
			local hasImmunity = _G.hasStatusImmunity(player)
			if hasImmunity then
				-- Player has status immunity, don't apply ailment
				return
			end
		end
	end
	
	-- Validate config
	config = config or {}
	local duration = config.duration or ServerConfigs.Hitbox.statusAilments[ailmentType].defaultDuration
	local chance = config.chance or 100 -- Default 100% chance
	
	-- Roll for chance
	if chance < 100 then
		local roll = math.random() * 100
		if roll >= chance then
			return -- Failed chance roll
		end
	end
	
	-- Initialize ailments tracking for this model
	if not activeAilments[model] then
		activeAilments[model] = {}
	end
	
	-- Check if ailment already exists (refresh duration if it does)
	if activeAilments[model][ailmentType] then
		-- Refresh duration
		activeAilments[model][ailmentType].duration = duration
		activeAilments[model][ailmentType].startTime = tick()
		activeAilments[model][ailmentType].config = config
	else
		-- Create new ailment
		activeAilments[model][ailmentType] = {
			duration = duration,
			startTime = tick(),
			config = config
		}
		
		-- Apply effects immediately
		applyAilmentEffects(model, ailmentType, config)
	end
	
	-- Setup DPS for poison/burn/ice
	if ailmentType == AilmentTypes.POISON or ailmentType == AilmentTypes.BURN or ailmentType == AilmentTypes.ICE then
		local dps = config.dps or 0
		local tickInterval = config.tickInterval or 1.0
		
		if dps > 0 and tickInterval > 0 then
			-- Store DPS info
			activeAilments[model][ailmentType].dps = dps
			activeAilments[model][ailmentType].tickInterval = tickInterval
			activeAilments[model][ailmentType].lastDPS = tick()
		end
	end
end

-- Function to check if model has a specific ailment
function _G.hasStatusAilment(model, ailmentType)
	if not model or not activeAilments[model] then return false end
	return activeAilments[model][ailmentType] ~= nil
end

-- Function to remove a specific ailment from a model
function _G.removeStatusAilment(model, ailmentType)
	if not model or not activeAilments[model] then return end
	
	removeAilmentEffects(model, ailmentType)
end

-- Function to clear all ailments from a model
function _G.clearAllStatusAilments(model)
	if not model or not activeAilments[model] then return end
	
	-- Remove all ailments
	for ailmentType, _ in pairs(activeAilments[model]) do
		removeAilmentEffects(model, ailmentType)
	end
	
	activeAilments[model] = nil
	restoreOriginalStats(model)
end

-- ========================================
-- UPDATE LOOP
-- ========================================

-- Main update loop to process ailments
RunService.Heartbeat:Connect(function()
	for model, ailments in pairs(activeAilments) do
		-- Safety check: model still exists
		if not model or not model.Parent then
			-- Clean up
			activeAilments[model] = nil
			originalStats[model] = nil
			-- Clean up status text displays
			if statusTextDisplays[model] then
				for _, textData in pairs(statusTextDisplays[model]) do
					-- Handle both old format (just billboardGui) and new format (table with billboardGui)
					local billboardGui = textData.billboardGui or textData
					if billboardGui and billboardGui.Parent then
						billboardGui:Destroy()
					end
				end
				statusTextDisplays[model] = nil
			end
		else
			local humanoid = getHumanoid(model)
			if not humanoid or humanoid.Health <= 0 then
				-- Character is dead, clean up
				activeAilments[model] = nil
				restoreOriginalStats(model)
				-- Clean up status text displays
				if statusTextDisplays[model] then
					for _, textData in pairs(statusTextDisplays[model]) do
						-- Handle both old format (just billboardGui) and new format (table with billboardGui)
						local billboardGui = textData.billboardGui or textData
						if billboardGui and billboardGui.Parent then
							billboardGui:Destroy()
						end
					end
					statusTextDisplays[model] = nil
				end
			else
				-- Process each ailment
				for ailmentType, ailmentData in pairs(ailments) do
					local currentTime = tick()
					local elapsed = currentTime - ailmentData.startTime
					
					-- Check if ailment expired
					if elapsed >= ailmentData.duration then
						removeAilmentEffects(model, ailmentType)
					else
						-- Update status text if it exists (refresh duration)
						local displayText = shouldDisplayStatusText(model)
						if displayText then
							local ailmentInfo = AilmentDisplayInfo[ailmentType]
							if ailmentInfo then
								if statusTextDisplays[model] and statusTextDisplays[model][ailmentType] then
									local textData = statusTextDisplays[model][ailmentType]
									if textData and type(textData) == "table" and textData.billboardGui then
										textData.startTime = ailmentData.startTime
										textData.duration = ailmentData.duration
									end
								else
									createOrUpdateStatusText(model, ailmentType, ailmentInfo.text, ailmentInfo.color, ailmentData.startTime, ailmentData.duration)
								end
							else
								if statusTextDisplays[model] and statusTextDisplays[model][ailmentType] then
									local textData = statusTextDisplays[model][ailmentType]
									local billboardGui = textData.billboardGui or textData
									if billboardGui and billboardGui.Parent then
										billboardGui:Destroy()
									end
									statusTextDisplays[model][ailmentType] = nil
								end
							end
						end
						
						-- Remove text if it should no longer be displayed (e.g., immunity gained)
						if not displayText then
							if statusTextDisplays[model] and statusTextDisplays[model][ailmentType] then
								local textData = statusTextDisplays[model][ailmentType]
								local billboardGui = textData.billboardGui or textData
								if billboardGui and billboardGui.Parent then
									billboardGui:Destroy()
								end
								statusTextDisplays[model][ailmentType] = nil
							end
						end
						
						-- Process DPS ailments
						if ailmentType == AilmentTypes.POISON or ailmentType == AilmentTypes.BURN or ailmentType == AilmentTypes.ICE then
							local dps = ailmentData.dps or 0
							local tickInterval = ailmentData.tickInterval or 1.0
							local lastDPS = ailmentData.lastDPS or ailmentData.startTime
							-- Get skipDefense from config (if true, bypasses defense for DPS damage)
							local skipDefense = (ailmentData.config and ailmentData.config.skipDefense) or false
							
							if dps > 0 and (currentTime - lastDPS) >= tickInterval then
								-- Apply DPS damage (with skipDefense option)
								applyDPSDamage(model, ailmentType, dps, tickInterval, skipDefense)
								ailmentData.lastDPS = currentTime
							end
						end
						
						-- Check if status text should be removed (ailment expired)
						if statusTextDisplays[model] and statusTextDisplays[model][ailmentType] then
							local textData = statusTextDisplays[model][ailmentType]
							if textData then
								local billboardGui = textData.billboardGui or textData
								local textStartTime = (type(textData) == "table" and textData.startTime) or ailmentData.startTime
								local textDuration = (type(textData) == "table" and textData.duration) or ailmentData.duration
								
								if currentTime >= (textStartTime + textDuration) then
									-- Text should be removed (ailment expired)
									if billboardGui and billboardGui.Parent then
										billboardGui:Destroy()
									end
									statusTextDisplays[model][ailmentType] = nil
								end
							end
						end
					end
				end
			end
		end
	end
end)

-- Clean up when characters are removed
game.Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		_G.clearAllStatusAilments(player.Character)
	end
end)

-- ========================================
-- MODULE EXPORTS
-- ========================================

local StatusAilmentHandler = {}

StatusAilmentHandler.apply = _G.applyStatusAilment
StatusAilmentHandler.has = _G.hasStatusAilment
StatusAilmentHandler.remove = _G.removeStatusAilment
StatusAilmentHandler.clearAll = _G.clearAllStatusAilments
StatusAilmentHandler.AilmentTypes = AilmentTypes

return StatusAilmentHandler

