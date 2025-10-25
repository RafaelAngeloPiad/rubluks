-- -- Spider Initializer - Server Script
-- -- Place this script inside each spider model
-- -- This script calls the centralized SpiderAI module

-- -- Safety check: Only run if parent is a valid model
-- if not script.Parent or not script.Parent:IsA("Model") then
--     script:Destroy()
--     return
-- end

-- -- Wait a moment to ensure everything is loaded
-- task.wait(1)

-- -- Call the centralized SpiderAI module
-- local success, error = pcall(function()
--     -- Get the SpiderAI module from ReplicatedStorage/mobs folder
--     local SpiderAIModule = require(game.ReplicatedStorage.mobs.SpiderAIModule)
    
--     -- Initialize the spider
--     SpiderAIModule.initializeSpider(script.Parent)
-- end)

-- if not success then
--     warn("[SpiderInitializer] Failed to initialize:", error)
-- end
