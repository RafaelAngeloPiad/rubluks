-- -- Golem Initializer - Server Script
-- -- Place this script inside each golem model
-- -- This script calls the centralized GolemAI module and then self-destructs

-- -- Safety check: Only run if parent is a valid model
-- if not script.Parent or not script.Parent:IsA("Model") then
--     warn("[GolemInitializer] Script must be placed inside a model! Parent:", script.Parent)
--     script:Destroy()
--     return
-- end

-- print("[GolemInitializer] Starting initialization for:", script.Parent.Name)

-- -- Wait a moment to ensure everything is loaded
-- task.wait(1)

-- -- Call the centralized GolemAI module
-- local success, error = pcall(function()
--     -- Get the GolemAI module from ReplicatedStorage/mobs folder
--     local GolemAIModule = require(game.ReplicatedStorage.mobs.GolemAIModule)
    
--     -- Check if already initialized
--     if GolemAIModule.isInitialized(script.Parent) then
--         print("[GolemInitializer] Golem already initialized:", script.Parent.Name)
--         return
--     end
    
--     -- Initialize the golem
--     GolemAIModule.initializeGolem(script.Parent)
--     print("[GolemInitializer] Successfully initialized:", script.Parent.Name)
-- end)

-- if success then
--     print("[GolemInitializer] Initialization complete.")
-- else
--     warn("[GolemInitializer] Failed to initialize:", error)
-- end
