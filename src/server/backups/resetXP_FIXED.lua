-- Fixed resetXP script that works with PlayerManager
script.Parent.ClickDetector.MouseClick:Connect(function(plr)
    local leaderstats = plr:FindFirstChild("leaderstats")
    
    if leaderstats then
        local currXP = leaderstats:FindFirstChild("CurrentXP")
        local level = leaderstats:FindFirstChild("Level")
        local maxXP = leaderstats:FindFirstChild("MaximumXP")
        local maxHealth = leaderstats:FindFirstChild("MaxHealth")
        local maxAttack = leaderstats:FindFirstChild("MaxAttack")
        local maxDefense = leaderstats:FindFirstChild("MaxDefense")
        local currentDefense = leaderstats:FindFirstChild("CurrentDefense")
        local defensePenetration = leaderstats:FindFirstChild("DefensePenetration")
        local critRate = leaderstats:FindFirstChild("CritRate")
        local critMultiplier = leaderstats:FindFirstChild("CritMultiplier")
        local healthRegen = leaderstats:FindFirstChild("HealthRegen")
        local movementSpeed = leaderstats:FindFirstChild("MovementSpeed")
        local attackSpeed = leaderstats:FindFirstChild("AttackSpeed")
        local class = leaderstats:FindFirstChild("Class")
        
        -- Reset XP/Level values
        if currXP then currXP.Value = 0 end
        if level then level.Value = 1 end
        if maxXP then maxXP.Value = 5 end
        
        -- IMPORTANT: If class is already "Slavkorian", we need to manually reset and apply stats
        -- because class.Changed event won't fire if value doesn't change
        local wasSlavkorian = (class and class.Value == "Slavkorian")
        
        if wasSlavkorian then
            -- Reset all stats to 0 first
            if maxHealth then maxHealth.Value = 0 end
            if maxAttack then maxAttack.Value = 0 end
            if maxDefense then maxDefense.Value = 0 end
            if currentDefense then currentDefense.Value = 0 end
            if defensePenetration then defensePenetration.Value = 0 end
            if critRate then critRate.Value = 0 end
            if critMultiplier then critMultiplier.Value = 0 end
            if healthRegen then healthRegen.Value = 0 end
            if movementSpeed then movementSpeed.Value = 0 end
            if attackSpeed then attackSpeed.Value = 0 end
            
            -- Now apply Slavkorian base stats manually
            if maxHealth then maxHealth.Value = 1000 end
            if maxAttack then maxAttack.Value = 100 end
            if maxDefense then maxDefense.Value = 0 end
            if currentDefense then currentDefense.Value = 0 end
            if defensePenetration then defensePenetration.Value = 0 end
            if critRate then critRate.Value = 5 end
            if critMultiplier then critMultiplier.Value = 150 end
            if healthRegen then healthRegen.Value = 0 end
            if movementSpeed then movementSpeed.Value = 18 end
            if attackSpeed then attackSpeed.Value = 1 end
        else
            -- If class is NOT Slavkorian, set it to Slavkorian
            -- This will trigger class.Changed event which will reset and apply base stats
            if class then
                class.Value = "Slavkorian"
            end
        end
    end
    
    -- Remove all items in the player's Backpack
    local backpack = plr:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            item:Destroy()
        end
    end
end)
