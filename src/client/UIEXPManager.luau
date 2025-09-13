local TS = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local leaderstats = player:WaitForChild("leaderstats")

local PlrGUI = player.PlayerGui
local OnScreen = PlrGUI:WaitForChild("OnScreen")

OnScreen.Level.Text = "Level: "..tostring(leaderstats.Level.Value)
OnScreen.expBackground.bar.Size = UDim2.new(leaderstats.CurrentXP.Value / leaderstats.MaximumXP.Value, 0,1,0)

leaderstats.Level.Changed:Connect(function(newv)
	OnScreen.Level.Text = "Level: "..tostring(newv)
end)

leaderstats.CurrentXP.Changed:Connect(function(newv)
	local xpProgress = leaderstats.CurrentXP.Value / leaderstats.MaximumXP.Value
	print(xpProgress)
	TS:Create(OnScreen.expBackground.bar,TweenInfo.new(0.2), {Size = UDim2.new(xpProgress,0,1,0)}):Play()
end)