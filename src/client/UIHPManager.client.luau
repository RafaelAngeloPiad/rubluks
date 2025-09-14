local TS = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local PlrGUI = player.PlayerGui
local Health = PlrGUI:WaitForChild("HealthGUI")

local function updateHealthBarAndLabels()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local currHealth = leaderstats:FindFirstChild("CurrentHealth")
    local maxHealth = leaderstats:FindFirstChild("MaxHealth")
    if currHealth and maxHealth then
        local healthProgress = currHealth.Value / maxHealth.Value
        TS:Create(Health.healthBackground.bar, TweenInfo.new(0.2), {Size = UDim2.new(healthProgress,0,1,0)}):Play()
        Health.CurrentHealthValue.Text = tostring(currHealth.Value)
        Health.MaxHealthValue.Text = tostring(maxHealth.Value)
    end
end

local function setupHealthListeners()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local currHealth = leaderstats:FindFirstChild("CurrentHealth")
    local maxHealth = leaderstats:FindFirstChild("MaxHealth")
    if currHealth and maxHealth then
        currHealth.Changed:Connect(function()
            updateHealthBarAndLabels()
        end)
        maxHealth.Changed:Connect(function()
            updateHealthBarAndLabels()
        end)
        -- Initial update
        updateHealthBarAndLabels()
    end
end

-- Listen for respawn and reset health bar and labels to full
player.CharacterAdded:Connect(function(character)
    -- Wait for leaderstats to be available after respawn
    local leaderstats = player:WaitForChild("leaderstats")
    local currHealth = leaderstats:WaitForChild("CurrentHealth")
    local maxHealth = leaderstats:WaitForChild("MaxHealth")
    -- Reset health bar to full size and update labels
    TS:Create(Health.healthBackground.bar, TweenInfo.new(0.2), {Size = UDim2.new(1,0,1,0)}):Play()
    Health.CurrentHealthValue.Text = tostring(currHealth.Value)
    Health.MaxHealthValue.Text = tostring(maxHealth.Value)
    setupHealthListeners()
end)

-- Setup listeners for initial spawn
setupHealthListeners()

