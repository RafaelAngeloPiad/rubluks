-- Human Melee Initializer - Server Script
-- Place this script inside each human melee mob model
-- This script calls the centralized HumanMeleeAIModule

-- Ensure the script is parented to a model
if not script.Parent or not script.Parent:IsA("Model") then
	script:Destroy()
	return
end

-- Slight delay to guarantee child objects are present
task.wait(1)

local success, err = pcall(function()
	local HumanMeleeAIModule = require(game.ReplicatedStorage.mobs.HumanMeleeAIModule)

	-- Optional: read a pre-set Variant attribute (defaults handled in module)
	local variantName = script.Parent:GetAttribute("Variant")

	HumanMeleeAIModule.initializeHumanMelee(script.Parent, variantName)
end)

if not success then
	warn("[HumanMeleeInitializer] Failed to initialize:", err)
end


