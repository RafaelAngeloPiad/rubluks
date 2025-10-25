-- -- Spider Initializer - Server Script
-- -- Place this script inside each spider model
-- -- This script calls the centralized SpiderAI module

-- -- Safety check: Only run if parent is a valid model
-- if not script.Parent or not script.Parent:IsA("Model") then
--     warn("[SpiderInitializer] Script must be placed inside a model! Parent:", script.Parent)
--     script:Destroy()
--     return
-- end

-- print("[SpiderInitializer] Starting initialization for:", script.Parent.Name)

-- -- Wait a moment to ensure everything is loaded
-- task.wait(1)

-- -- Call the centralized SpiderAI module
-- local success, error = pcall(function()
--     -- Get the SpiderAI module from ReplicatedStorage/mobs folder
--     local SpiderAIModule = require(game.ReplicatedStorage.mobs.SpiderAIModule)
    
--     -- Check if already initialized
--     if SpiderAIModule.isInitialized(script.Parent) then
--         print("[SpiderInitializer] Spider already initialized:", script.Parent.Name)
--         return
--     end
    
--     -- Initialize the spider
--     SpiderAIModule.initializeSpider(script.Parent)
--     print("[SpiderInitializer] Successfully initialized:", script.Parent.Name)
-- end)

-- if success then
--     print("[SpiderInitializer] Initialization complete.")
-- else
--     warn("[SpiderInitializer] Failed to initialize:", error)
-- end
