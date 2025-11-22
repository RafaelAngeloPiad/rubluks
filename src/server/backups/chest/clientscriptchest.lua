local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local chestValue = script:WaitForChild("Chest")

local function onMouseButtonDown()
	local chest = chestValue.Value
	if not chest then
		return
	end

	local target = mouse.Target
	if not target then
		return
	end

	if target.Name == "Lock" and target:IsDescendantOf(chest) then
		chest.LidToggle:FireServer()
	end
end

mouse.Button1Down:Connect(onMouseButtonDown)