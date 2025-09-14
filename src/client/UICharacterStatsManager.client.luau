local player = game.Players.LocalPlayer
local PlrGUI = player:WaitForChild("PlayerGui")
local CharacterStatsGUI = PlrGUI:WaitForChild("CharacterStatsGUI")

local function updateStatsLabels()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local maxHealth = leaderstats:FindFirstChild("MaxHealth")
    local maxAttack = leaderstats:FindFirstChild("MaxAttack")
    local maxDefense = leaderstats:FindFirstChild("MaxDefense")

    if maxHealth then
        CharacterStatsGUI.MainUI.MaxHealth.Text = "Max Health: " .. tostring(maxHealth.Value)
    end
    if maxAttack then
        CharacterStatsGUI.MainUI.MaxAttack.Text = "Max Attack: " .. tostring(maxAttack.Value)
    end
    if maxDefense then
        CharacterStatsGUI.MainUI.MaxDefense.Text = "Max Defense: " .. tostring(maxDefense.Value)
    end
end

local function setupStatListeners()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local statNames = {"MaxHealth", "MaxAttack", "MaxDefense"}
    for _, statName in statNames do
        local statObj = leaderstats:FindFirstChild(statName)
        if statObj then
            statObj.Changed:Connect(function()
                updateStatsLabels()
            end)
        end
    end
    -- Initial update
    updateStatsLabels()
end

-- Listen for respawn and update stats labels
player.CharacterAdded:Connect(function(character)
    local leaderstats = player:WaitForChild("leaderstats")
    for _, statName in {"MaxHealth", "MaxAttack", "MaxDefense"} do
        leaderstats:WaitForChild(statName)
    end
    updateStatsLabels()
    setupStatListeners()
end)

-- Setup listeners for initial spawn
setupStatListeners()

