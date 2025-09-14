local TS = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local PlrGUI = player.PlayerGui
local ExpGUI = PlrGUI:WaitForChild("ExpGUI")

local function updateEXPBarAndLevel()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local currXP = leaderstats:FindFirstChild("CurrentXP")
    local maxXP = leaderstats:FindFirstChild("MaximumXP")
    local level = leaderstats:FindFirstChild("Level")
    if currXP and maxXP and level then
        ExpGUI.Level.Text = "Level: "..tostring(level.Value)
        local xpProgress = currXP.Value / maxXP.Value
        if level.Value == 50 then
            ExpGUI.expBackground.bar.Size = UDim2.new(1, 0, 1, 0)
        else
            TS:Create(ExpGUI.expBackground.bar, TweenInfo.new(0.2), {Size = UDim2.new(xpProgress,0,1,0)}):Play()
        end
    end
end

local function setupEXPListeners()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local currXP = leaderstats:FindFirstChild("CurrentXP")
    local maxXP = leaderstats:FindFirstChild("MaximumXP")
    local level = leaderstats:FindFirstChild("Level")
    if currXP and maxXP and level then
        currXP.Changed:Connect(function()
            updateEXPBarAndLevel()
        end)
        maxXP.Changed:Connect(function()
            updateEXPBarAndLevel()
        end)
        level.Changed:Connect(function()
            updateEXPBarAndLevel()
        end)
        -- Initial update
        updateEXPBarAndLevel()
    end
end

-- Listen for respawn and update EXP bar and level text
player.CharacterAdded:Connect(function(character)
    -- Wait for leaderstats to be available after respawn
    local leaderstats = player:WaitForChild("leaderstats")
    leaderstats:WaitForChild("CurrentXP")
    leaderstats:WaitForChild("MaximumXP")
    leaderstats:WaitForChild("Level")
    updateEXPBarAndLevel()
    setupEXPListeners()
end)

-- Setup listeners for initial spawn
setupEXPListeners()

