-- Golem Initializer - Server Script
-- Place this script inside each golem model
-- This script calls the centralized GolemAI module

-- Safety check: Only run if parent is a valid model
if not script.Parent or not script.Parent:IsA("Model") then
    script:Destroy()
    return
end

-- Wait a moment to ensure everything is loaded
task.wait(1)

-- Call the centralized GolemAI module
local success, error = pcall(function()
    -- Get the GolemAI module from ReplicatedStorage/mobs folder
    local GolemAIModule = require(game.ReplicatedStorage.mobs.GolemAIModule)
    
    -- Get variant name from model's attribute (if set)
    local variantName = script.Parent:GetAttribute("Variant")
    
    -- Initialize the golem with variant
    GolemAIModule.initializeGolem(script.Parent, variantName)
end)

if not success then
    warn("[GolemInitializer] Failed to initialize:", error)
end
