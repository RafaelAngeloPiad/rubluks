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
	anim1.AnimationId = "rbxassetid://70754044037236"

	-- Jump Attack Animation
	local jumpAnim = Instance.new("Animation")
	jumpAnim.AnimationId = "rbxassetid://73381106980733"
	local jumpTrack = animator:LoadAnimation(jumpAnim)
	jumpTrack.Priority = Enum.AnimationPriority.Action

	-- Move Attack Anim
	local moveSlashAnim = Instance.new("Animation")
	moveSlashAnim.AnimationId = "rbxassetid://92621939945348"
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
				
				jumpTrack:GetMarkerReachedSignal("Arrow"):Once(function()
					local vfx = ReplicatedStorage.ArcherArrow:WaitForChild("Arrow"):Clone()
					vfx.Parent = workspace

					local root = character:WaitForChild("HumanoidRootPart")

					-- Position sa harap ng player (independent, no weld)
					local forwardOffset = 4 -- gaano kalayo sa harap magsimula
					local rotationX = 0 -- ikot pataas/pababa
					local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
					local rotationZ = 0 -- ikot paikot

					local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

					vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -forwardOffset)* rotation)

					-- Ensure lahat ng parts ay hindi naka-anchor pero stable
					for _, part in ipairs(vfx:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Anchored = false
							part.CanCollide = false
						end
					end

					-- Kukunin natin yung main mesh (blade)
					local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

					-- Gagalaw forward gamit BodyVelocity
					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.Velocity = root.CFrame.LookVector * 120 -- adjust speed
					bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
					bodyVelocity.Parent = arrow

					-- Raycast params (para hindi tamaan ang sarili)
					local rayParams = RaycastParams.new()
					rayParams.FilterDescendantsInstances = {character}
					rayParams.FilterType = Enum.RaycastFilterType.Exclude

					-- Check collision bawat frame
					local connection
					connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
						local rayResult = workspace:Raycast(arrow.Position, arrow.CFrame.LookVector * (bodyVelocity.Velocity.Magnitude * dt), rayParams)
						if rayResult then
							-- Tumama ?
							bodyVelocity:Destroy()
							arrow.Anchored = true
							--arrow.CFrame = CFrame.new(rotation)
							connection:Disconnect()
						end
					end)

					-- Auto cleanup
					game:GetService("Debris"):AddItem(vfx, 3)
					game:GetService("Debris"):AddItem(bodyVelocity, 2)
				end)
				
				
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

			moveSlashTrack:GetMarkerReachedSignal("DashAttack"):Once(function()
				
				
				local vfx = ReplicatedStorage.ArcherArrow:WaitForChild("Arrow"):Clone()
				vfx.Parent = workspace

				local root = character:WaitForChild("HumanoidRootPart")

				-- Position sa harap ng player (independent, no weld)
				local forwardOffset = 4 -- gaano kalayo sa harap magsimula
				local rotationX = 0 -- ikot pataas/pababa
				local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
				local rotationZ = 0 -- ikot paikot

				local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

				vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -forwardOffset)* rotation)

				-- Ensure lahat ng parts ay hindi naka-anchor pero stable
				for _, part in ipairs(vfx:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
					end
				end

				-- Kukunin natin yung main mesh (blade)
				local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

				-- Gagalaw forward gamit BodyVelocity
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.Velocity = root.CFrame.LookVector * 120 -- adjust speed
				bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
				bodyVelocity.Parent = arrow

				-- Raycast params (para hindi tamaan ang sarili)
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {character}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude

				-- Check collision bawat frame
				local connection
				connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
					local rayResult = workspace:Raycast(arrow.Position, arrow.CFrame.LookVector * (bodyVelocity.Velocity.Magnitude * dt), rayParams)
					if rayResult then
						-- Tumama ?
						bodyVelocity:Destroy()
						arrow.Anchored = true
						--arrow.CFrame = CFrame.new(rotation)
						connection:Disconnect()
					end
				end)

				-- Auto cleanup
				game:GetService("Debris"):AddItem(vfx, 3)
				game:GetService("Debris"):AddItem(bodyVelocity, 2)
				
				
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(200000, 0, 200000)
				bodyVelocity.Velocity = -root.CFrame.LookVector * 50
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
			
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:WaitForChild("Humanoid")
			local root = character:WaitForChild("HumanoidRootPart")
			local animator = humanoid:WaitForChild("Animator")

			local animTrack = animator:LoadAnimation(anim1)
			animTrack:Play()
			
			-- ? AURA marker
			animTrack:GetMarkerReachedSignal("Arrow"):Once(function()
				local vfx = ReplicatedStorage.ArcherArrow:WaitForChild("Arrow"):Clone()
				vfx.Parent = workspace

				local root = character:WaitForChild("HumanoidRootPart")

				-- Position sa harap ng player (independent, no weld)
				local forwardOffset = 4 -- gaano kalayo sa harap magsimula
				local rotationX = 0 -- ikot pataas/pababa
				local rotationY = math.rad(-90) -- ikot pakaliwa/pakanan
				local rotationZ = 0 -- ikot paikot

				local rotation = CFrame.Angles(rotationX, rotationY, rotationZ)

				vfx:PivotTo(root.CFrame * CFrame.new(0, 1, -forwardOffset)* rotation)

				-- Ensure lahat ng parts ay hindi naka-anchor pero stable
				for _, part in ipairs(vfx:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
					end
				end

				-- Kukunin natin yung main mesh (blade)
				local arrow = vfx:FindFirstChildWhichIsA("BasePart") or vfx

				-- Gagalaw forward gamit BodyVelocity
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.Velocity = root.CFrame.LookVector * 120 -- adjust speed
				bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
				bodyVelocity.Parent = arrow
				
				-- Raycast params (para hindi tamaan ang sarili)
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {character}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude

				-- Check collision bawat frame
				local connection
				connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
					local rayResult = workspace:Raycast(arrow.Position, arrow.CFrame.LookVector * (bodyVelocity.Velocity.Magnitude * dt), rayParams)
					if rayResult then
						-- Tumama ?
						bodyVelocity:Destroy()
						arrow.Anchored = true
						--arrow.CFrame = CFrame.new(rotation)
						connection:Disconnect()
					end
				end)

				-- Auto cleanup
				game:GetService("Debris"):AddItem(vfx, 3)
				game:GetService("Debris"):AddItem(bodyVelocity, 2)
			end)
			
			
			animTrack.Stopped:Once(function() isAttacking = false end)
			clickCount = 0 -- reset
		--[[
		elseif clickCount == 2 then
			animTrack2:Play()
			animTrack2.Stopped:Once(function() isAttacking = false end)
		elseif clickCount == 3 then
			animTrack3:Play()
			animTrack3.Stopped:Once(function() isAttacking = false end)
			clickCount = 0 -- reset
		]]
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
