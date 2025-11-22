-- Wraith Initializer - Server Script
-- Place this script inside each wraith model
-- This script calls the centralized WraithAI module

-- Safety check: Only run if parent is a valid model
if not script.Parent or not script.Parent:IsA("Model") then
    script:Destroy()
    return
end

-- Wait a moment to ensure everything is loaded
task.wait(1)

-- Call the centralized WraithAI module
local success, error = pcall(function()
    -- Get the WraithAI module from ReplicatedStorage/mobs folder
    local WraithAIModule = require(game.ReplicatedStorage.mobs.WraithAIModule)
    
    -- Get variant name from model's attribute (if set)
    local variantName = script.Parent:GetAttribute("Variant")
    
    -- Initialize the wraith with variant
    WraithAIModule.initializeWraith(script.Parent, variantName)
end)

if not success then
    warn("[WraithInitializer] Failed to initialize:", error)
end

