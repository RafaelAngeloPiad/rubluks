-- ========================================
-- HIGHLIGHT CLEANUP CLIENT
-- Cleans up stuck highlights on player every minute
-- ========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Function to clean up highlights on player
local function cleanupPlayerHighlights()
    local character = player.Character
    if not character then return end
    
    local highlight = character:FindFirstChildOfClass("Highlight")
    if highlight then
        highlight:Destroy()
    end
end

-- Clean up highlights every minute (60 seconds)
local cleanupTimer = 0
local cleanupInterval = 60 -- 60 seconds

-- Connect to Heartbeat for timer
RunService.Heartbeat:Connect(function(deltaTime)
    cleanupTimer = cleanupTimer + deltaTime
    
    if cleanupTimer >= cleanupInterval then
        cleanupTimer = 0 -- Reset timer
        cleanupPlayerHighlights()
    end
end)

-- Also clean up when character spawns
player.CharacterAdded:Connect(function()
    -- Wait a bit for character to fully load
    task.wait(1)
    cleanupPlayerHighlights()
end)