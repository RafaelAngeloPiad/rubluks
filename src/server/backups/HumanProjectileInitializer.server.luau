-- Human Projectile Initializer - Server Script
-- Place this script inside each human projectile mob model
-- This script calls the centralized HumanProjectileAIModule

if not script.Parent or not script.Parent:IsA("Model") then
	script:Destroy()
	return
end

task.wait(1)

local success, err = pcall(function()
	local HumanProjectileAIModule = require(game.ReplicatedStorage.mobs.HumanProjectileAIModule)

	local variantName = script.Parent:GetAttribute("Variant")

	HumanProjectileAIModule.initializeHumanProjectile(script.Parent, variantName)
end)

if not success then
	warn("[HumanProjectileInitializer] Failed to initialize:", err)
end


