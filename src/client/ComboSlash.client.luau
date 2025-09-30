local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local tool = script.Parent
local player = Players.LocalPlayer

tool.Equipped:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	local root = character:WaitForChild("HumanoidRootPart")

	-- Normal Attack Animations
	local anim1 = Instance.new("Animation")
	anim1.AnimationId = "rbxassetid://106425822034811"
	local animTrack1 = animator:LoadAnimation(anim1)

	local anim2 = Instance.new("Animation")
	anim2.AnimationId = "rbxassetid://82347640503852"
	local animTrack2 = animator:LoadAnimation(anim2)

	local anim3 = Instance.new("Animation")
	anim3.AnimationId = "rbxassetid://138494804545108"
	local animTrack3 = animator:LoadAnimation(anim3)

	-- Jump Attack Animation
	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = "rbxassetid://92927046911901"
	local jumpTrack = animator:LoadAnimation(jumpAnim)
	jumpTrack.Priority = Enum.AnimationPriority.Action

	-- Move Attack Anim
	local moveSlashAnim = Instance.new("Animation")
	moveSlashAnim.AnimationId = "rbxassetid://106133804561379"
	local moveSlashTrack = animator:LoadAnimation(moveSlashAnim)

	-- RightClick Idle Anim
	local rightClickIdleAnim = Instance.new("Animation")
	rightClickIdleAnim.AnimationId = "rbxassetid://116101111905611"
	local rightClickIdleTrack = animator:LoadAnimation(rightClickIdleAnim)
	rightClickIdleTrack.Priority = Enum.AnimationPriority.Action

	--[[ RightClick Run Anim
	local rightClickRunAnim = Instance.new("Animation")
	rightClickRunAnim.AnimationId = "rbxassetid://85196909321083"
	local rightClickRunTrack = animator:LoadAnimation(rightClickRunAnim)
	rightClickRunTrack.Priority = Enum.AnimationPriority.Action]]

	-- Click Counter
	local clickCount = 0
	local isJumping = false -- flag kapag nasa hangin
	local currentRCTrack = nil -- para ma-stop kung anong tumatakbo

	-- ?? New flags
	local isAttacking = false
	local isRightClicking = false

	-- Detect Jump state
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			isJumping = true
		elseif newState == Enum.HumanoidStateType.Landed then
			isJumping = false
			if jumpTrack.IsPlaying then
				jumpTrack:Stop()
				print("Jump attack ended")
			end
		end
	end)

	-- Left click attacks
	tool.Activated:Connect(function()
		if isRightClicking then return end -- block kapag naka-hold RightClick
		if isAttacking then return end -- para hindi mag-overlap

		local speed = humanoid.MoveDirection.Magnitude

		if isJumping then
			-- Jump + Left click = Jump attack anim
			if not jumpTrack.IsPlaying then
				isAttacking = true
				jumpTrack:Play()
				print("Jump attack triggered!")
				jumpTrack.Stopped:Once(function()
					isAttacking = false
				end)
			end
			return
		end

		if speed > 0 then
			-- Move attack kapag naglalakad
			isAttacking = true
			moveSlashTrack:Play()

			moveSlashTrack:GetMarkerReachedSignal("DashAttack"):Connect(function()
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(200000, 0, 200000)
				bodyVelocity.Velocity = root.CFrame.LookVector * 50
				bodyVelocity.Parent = root
				game.Debris:AddItem(bodyVelocity, 0.2)
			end)

			moveSlashTrack.Stopped:Once(function()
				isAttacking = false
			end)
			return -- ?? important para hindi sabay sa combo
		end

		-- Normal ground combo (standing still)
		clickCount += 1
		isAttacking = true

		if clickCount == 1 then
			animTrack1:Play()
			animTrack1.Stopped:Once(function() isAttacking = false end)
		elseif clickCount == 2 then
			animTrack2:Play()
			animTrack2.Stopped:Once(function() isAttacking = false end)
		elseif clickCount == 3 then
			animTrack3:Play()
			animTrack3.Stopped:Once(function() isAttacking = false end)
			clickCount = 0 -- reset
		end
	end)

	-- Right click logic (hold)
	local holdingRightClick = false
	local connection

	local function updateMovement()
		if not holdingRightClick then return end
		if humanoid.MoveDirection.Magnitude > 0 then
			if not rightClickIdleTrack.IsPlaying then
				rightClickIdleTrack:Stop()
				rightClickIdleTrack:Play()
			end
		else
			if not rightClickIdleTrack.IsPlaying then
				rightClickIdleTrack:Stop()
				rightClickIdleTrack:Play()
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if isAttacking then return end -- block kapag may active attack
			holdingRightClick = true
			isRightClicking = true
			rightClickIdleTrack:Play()

			-- Lock movement (set walkspeed to 0 while idle)
			humanoid.WalkSpeed = 0

			connection = game:GetService("RunService").Heartbeat:Connect(function()
				updateMovement()
			end)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			holdingRightClick = false
			isRightClicking = false

			-- Reset walkspeed
			humanoid.WalkSpeed = 16 -- default

			-- Stop animations
			rightClickIdleTrack:Stop()
			rightClickIdleTrack:Stop()

			-- Disconnect update loop
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end
	end)
	
	
end)
