-- Zombie Initializer - Server Script
-- Place this script inside each zombie model
-- This script calls the centralized ZombieAI module

-- Safety check: Only run if parent is a valid model
if not script.Parent or not script.Parent:IsA("Model") then
    script:Destroy()
    return
end

-- Wait a moment to ensure everything is loaded
task.wait(1)

-- Call the centralized ZombieAI module
local success, error = pcall(function()
    -- Get the ZombieAI module from ReplicatedStorage/mobs folder
    local ZombieAIModule = require(game.ReplicatedStorage.mobs.ZombieAIModule)
    
    -- Get variant name from model's attribute (if set)
    local variantName = script.Parent:GetAttribute("Variant")
    if not variantName then
        variantName = "Zombie_Sand"
        script.Parent:SetAttribute("Variant", variantName)
    end
    
    -- Initialize the zombie with variant
    ZombieAIModule.initializeZombie(script.Parent, variantName)
end)

if not success then
    warn("[ZombieInitializer] Failed to initialize:", error)
end

