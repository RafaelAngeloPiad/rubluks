local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local FloatingNumberEvent = ReplicatedStorage:WaitForChild("FloatingNumberEvent")
local ServerConfigs = require(ReplicatedStorage:WaitForChild("SlavkosConfigs"))

local EVENT_CONFIG_MAP = {
	damage = function()
		return ServerConfigs.Hitbox.damageNumbers
	end,
	xp = function()
		return ServerConfigs.Hitbox.xpNumbers
	end,
	slavkoin = function()
		return ServerConfigs.Hitbox.slavkoinNumbers or ServerConfigs.Hitbox.xpNumbers
	end,
}

local function getAttachPart(model, attachPreference)
	if not model then
		return nil
	end

	local head = model:FindFirstChild("Head")
	local root = model:FindFirstChild("HumanoidRootPart")

	if attachPreference == "Root" then
		return root or head
	elseif attachPreference == "Head" then
		return head or root
	end

	return head or root
end

local function getScaleFactors(config)
	local referenceDistance = config.scaleReferenceDistance or 30
	local minScale = config.minScale or 0.6
	local maxScale = config.maxScale or 1.1
	local falloff = config.scaleFalloff or 1

	return referenceDistance, minScale, maxScale, falloff
end

local function computeScale(distance, config)
	local referenceDistance, minScale, maxScale, falloff = getScaleFactors(config)
	distance = math.max(distance, 1)

	local scale = (referenceDistance / (distance ^ falloff))
	return math.clamp(scale, minScale, maxScale)
end

local function formatText(eventType, amount, config)
	if eventType == "damage" then
		return "-" .. tostring(amount)
	end

	local prefix = config.prefix or "+"
	local suffix = config.suffix

	if eventType == "xp" then
		suffix = suffix or " XP"
	elseif eventType == "slavkoin" then
		suffix = suffix or " Slavkoins"
	end

	return string.format("%s%s%s", prefix, tostring(amount), suffix or "")
end

local function createFloatingNumber(eventType, model, amount)
	if not model or not model.Parent then
		return
	end

	local configResolver = EVENT_CONFIG_MAP[eventType]
	if not configResolver then
		return
	end

	local config = configResolver()
	if not config or not config.enabled then
		return
	end

	local attachPart = getAttachPart(model, config.attachTo)
	if not attachPart then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = string.format("%sNumber_%s", eventType, tostring(os.clock()))
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboard.MaxDistance = config.maxDistance or 120

	local baseWidth = config.width or 200
	local baseHeight = config.height or 100
	billboard.Size = UDim2.new(0, baseWidth, 0, baseHeight)

	local baseOffsetX = config.offsetX or 0
	local randomOffsetRange = config.randomOffsetX or 0
	local offsetX = baseOffsetX
	if randomOffsetRange ~= 0 then
		offsetX += ((math.random() - 0.5) * 2 * randomOffsetRange)
	end

	local offsetY = config.offsetY or 2
	local offsetZ = config.offsetZ or 0
	billboard.StudsOffset = Vector3.new(offsetX, offsetY, offsetZ)

	billboard.Parent = attachPart

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = config.backgroundTransparency ~= nil and config.backgroundTransparency or 1
	if config.backgroundColor then
		textLabel.BackgroundColor3 = config.backgroundColor
	end
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Text = formatText(eventType, amount, config)
	textLabel.TextColor3 = config.textColor or Color3.new(1, 1, 1)
	textLabel.TextSize = config.textSize or 28
	textLabel.Font = config.font or Enum.Font.GothamBold
	textLabel.TextStrokeColor3 = config.strokeColor or config.textStrokeColor or Color3.new(0, 0, 0)
	textLabel.TextStrokeTransparency = config.strokeTransparency ~= nil and config.strokeTransparency or config.textStrokeTransparency or 0
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = billboard

	local startTime = tick()
	local duration = config.duration or 1
	local fadeStart = config.fadeStart or (duration * 0.5)
	local riseHeight = config.riseHeight or 3
	local initialOffset = billboard.StudsOffset

	local connection

	connection = RunService.RenderStepped:Connect(function()
		if not billboard or not billboard.Parent or not attachPart or not attachPart.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local now = tick()
		local elapsed = now - startTime
		if elapsed >= duration then
			if connection then
				connection:Disconnect()
			end
			billboard:Destroy()
			return
		end

		local progress = elapsed / duration
		billboard.StudsOffset = Vector3.new(
			initialOffset.X,
			initialOffset.Y + (riseHeight * progress),
			initialOffset.Z
		)

		local camera = workspace.CurrentCamera
		if camera and camera.CFrame then
			local cameraPosition = camera.CFrame.Position
			local distance = (cameraPosition - attachPart.Position).Magnitude
			local scale = computeScale(distance, config)
			billboard.Size = UDim2.new(0, math.floor(baseWidth * scale), 0, math.floor(baseHeight * scale))
			textLabel.TextSize = math.max(8, math.floor((config.textSize or 28) * scale))
		end

		if elapsed >= fadeStart then
			local fadeDuration = math.max(duration - fadeStart, 0.0001)
			local fadeProgress = math.clamp((elapsed - fadeStart) / fadeDuration, 0, 1)
			textLabel.TextTransparency = fadeProgress
			local baseStrokeTransparency = config.strokeTransparency ~= nil and config.strokeTransparency or config.textStrokeTransparency or 0
			textLabel.TextStrokeTransparency = math.min(baseStrokeTransparency + fadeProgress, 1)
		end
	end)

	Debris:AddItem(billboard, duration + 0.5)
end

FloatingNumberEvent.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local eventType = payload.type
	local model = payload.model
	local amount = payload.amount

	if not eventType or typeof(model) ~= "Instance" or typeof(amount) ~= "number" then
		return
	end

	createFloatingNumber(eventType, model, amount)
end)


