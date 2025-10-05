-- LocalScript (inside the Tool)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tool = script.Parent
local remote = ReplicatedStorage:WaitForChild("AttackEvent")
local UserInputService = game:GetService("UserInputService")

tool.Activated:Connect(function()
	-- Sabihin sa server na nag attack
	UserInputService.InputBegan:Connect(function(input, isProcessed)
		if isProcessed then return end -- wag i-trigger pag may UI
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			print("?? Sending attack to server") -- debug log
			remote:FireServer()
		end
	end)
end)
