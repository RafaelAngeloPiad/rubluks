-- Human Wizard Initializer - Server Script
-- Place this script inside each human wizard mob model
-- This script calls the centralized HumanWizardAIModule

if not script.Parent or not script.Parent:IsA("Model") then
	script:Destroy()
	return
end

task.wait(1)

local success, err = pcall(function()
	local HumanWizardAIModule = require(game.ReplicatedStorage.mobs.HumanWizardAIModule)

	local variantName = script.Parent:GetAttribute("Variant")

	HumanWizardAIModule.initializeHumanWizard(script.Parent, variantName)
end)

if not success then
	warn("[HumanWizardInitializer] Failed to initialize:", err)
end


