local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Create RemoteEvents for client-server communication
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

local dropItemRemote = remoteEvents:FindFirstChild("DropItemRemote")
if not dropItemRemote then
    dropItemRemote = Instance.new("RemoteEvent")
    dropItemRemote.Name = "DropItemRemote"
    dropItemRemote.Parent = remoteEvents
end

-- Configuration
local DROP_CONFIG = {
    DROP_DISTANCE = 5, -- Distance in front of player to drop item
    DROP_HEIGHT_OFFSET = 2, -- Height above ground to drop item
    DESPAWN_TIME = 300, -- 5 minutes before dropped items despawn
    MAX_DROPS_PER_PLAYER = 50, -- Prevent spam dropping
}

-- Track dropped items for cleanup
local droppedItems = {}
local playerDropCounts = {}

-- Utility function to get safe drop position
local function getDropPosition(player)
    local character = player.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    -- Calculate position in front of player
    local lookDirection = humanoidRootPart.CFrame.LookVector
    local dropPosition = humanoidRootPart.Position + (lookDirection * DROP_CONFIG.DROP_DISTANCE)
    
    -- Add height offset
    dropPosition = dropPosition + Vector3.new(0, DROP_CONFIG.DROP_HEIGHT_OFFSET, 0)
    
    -- Raycast to find ground level
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(dropPosition, Vector3.new(0, -50, 0), raycastParams)
    if raycastResult then
        dropPosition = raycastResult.Position + Vector3.new(0, 1, 0) -- 1 stud above ground
    end
    
    return dropPosition
end

-- Create a dropped item with physics
local function createDroppedItem(tool, dropPosition, player)
    local droppedTool = tool:Clone()
    
    -- Set up the dropped tool
    droppedTool.Parent = workspace
    droppedTool.Handle.Position = dropPosition
    droppedTool.Handle.CanCollide = true
    
    -- Add some random velocity for realistic drop effect
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(
        math.random(-5, 5), -- Random X velocity
        math.random(2, 8),  -- Upward Y velocity
        math.random(-5, 5)  -- Random Z velocity
    )
    bodyVelocity.Parent = droppedTool.Handle
    
    -- Remove velocity after a short time
    game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
    
    -- Add pickup detection
    local connection
    connection = droppedTool.Activated:Connect(function()
        local touchingParts = workspace:GetPartBoundsInBox(droppedTool.Handle.CFrame, droppedTool.Handle.Size)
        for _, part in touchingParts do
            local character = part.Parent
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local player = Players:GetPlayerFromCharacter(character)
                if player then
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        -- Get fresh copy from ReplicatedStorage.assets (same as InventoryManager)
                        local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
                        if assetsFolder then
                            local originalAsset = assetsFolder:FindFirstChild(droppedTool.Name)
                            if originalAsset and originalAsset:IsA("Tool") then
                                -- Clone fresh tool to backpack
                                local freshTool = originalAsset:Clone()
                                freshTool.Parent = backpack
                                print("[InventoryDropManager] Player", player.Name, "picked up", droppedTool.Name)
                                
                                -- Remove the dropped tool from world
                                droppedTool:Destroy()
                                
                                -- Clean up tracking
                                for i, item in ipairs(droppedItems) do
                                    if item.tool == droppedTool then
                                        table.remove(droppedItems, i)
                                        break
                                    end
                                end
                                
                                connection:Disconnect()
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- Track for cleanup
    local dropData = {
        tool = droppedTool,
        dropTime = os.time(),
        connection = connection,
        owner = player.Name
    }
    table.insert(droppedItems, dropData)
    
    -- Schedule despawn
    game:GetService("Debris"):AddItem(droppedTool, DROP_CONFIG.DESPAWN_TIME)
    
    print("[InventoryDropManager] Dropped", tool.Name, "for player", player.Name, "at position", dropPosition)
    return droppedTool
end

-- Main drop function
local function dropItem(player, toolName)
    -- Validate player
    if not player or not player.Parent then
        return false, "Invalid player"
    end
    
    -- Check drop limit
    local playerId = player.UserId
    playerDropCounts[playerId] = playerDropCounts[playerId] or 0
    if playerDropCounts[playerId] >= DROP_CONFIG.MAX_DROPS_PER_PLAYER then
        return false, "Drop limit reached. Pick up some items first."
    end
    
    -- Find the tool in backpack OR character (equipped)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    local tool = nil
    local toolLocation = nil
    
    -- Check backpack first
    if backpack then
        tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            toolLocation = "backpack"
        end
    end
    
    -- If not in backpack, check character (equipped)
    if not tool and character then
        tool = character:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            toolLocation = "character"
        end
    end
    
    if not tool then
        return false, "Tool not found in backpack or equipped"
    end
    
    -- Get the original asset from ReplicatedStorage.assets (same as InventoryManager)
    local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
    if not assetsFolder then
        return false, "Assets folder not found in ReplicatedStorage"
    end
    
    local originalAsset = assetsFolder:FindFirstChild(toolName)
    if not originalAsset or not originalAsset:IsA("Tool") then
        return false, "Original tool asset not found in ReplicatedStorage.assets"
    end
    
    -- Get drop position
    local dropPosition = getDropPosition(player)
    if not dropPosition then
        return false, "Cannot determine drop position"
    end
    
    -- Create dropped item using the original asset
    local droppedTool = createDroppedItem(originalAsset, dropPosition, player)
    if droppedTool then
        -- Remove the tool from player's inventory
        tool:Destroy()
        print("[InventoryDropManager] Removed", toolName, "from player's", toolLocation)
        
        -- Update drop count
        playerDropCounts[playerId] = playerDropCounts[playerId] + 1
        
        return true, "Item dropped successfully"
    else
        return false, "Failed to create dropped item"
    end
end

-- Handle drop requests from client
dropItemRemote.OnServerEvent:Connect(function(player, toolName)
    if not player or not toolName or type(toolName) ~= "string" then
        warn("[InventoryDropManager] Invalid drop request from", player and player.Name or "unknown player")
        return
    end
    
    print("[InventoryDropManager] Processing drop request for", player.Name, "- Tool:", toolName)
    local success, message = dropItem(player, toolName)
    if not success then
        warn("[InventoryDropManager] Drop failed for", player.Name, ":", message)
        -- Could send error message back to client here if needed
    else
        print("[InventoryDropManager] Drop successful for", player.Name, ":", message)
    end
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
    playerDropCounts[player.UserId] = nil
    
    -- Clean up dropped items by this player (optional - items could persist)
    -- Uncomment the following if you want items to disappear when player leaves:
    --[[
    for i = #droppedItems, 1, -1 do
        local item = droppedItems[i]
        if item.owner == player.Name then
            if item.tool and item.tool.Parent then
                item.tool:Destroy()
            end
            if item.connection then
                item.connection:Disconnect()
            end
            table.remove(droppedItems, i)
        end
    end
    --]]
end)

-- Periodic cleanup of expired items
spawn(function()
    while true do
        wait(30) -- Check every 30 seconds
        local currentTime = os.time()
        
        for i = #droppedItems, 1, -1 do
            local item = droppedItems[i]
            if not item.tool or not item.tool.Parent then
                -- Item was destroyed, remove from tracking
                if item.connection then
                    item.connection:Disconnect()
                end
                table.remove(droppedItems, i)
            elseif currentTime - item.dropTime >= DROP_CONFIG.DESPAWN_TIME then
                -- Item expired, clean up
                if item.tool and item.tool.Parent then
                    item.tool:Destroy()
                end
                if item.connection then
                    item.connection:Disconnect()
                end
                table.remove(droppedItems, i)
            end
        end
        
        -- Reset drop counts periodically to prevent permanent lockout
        for playerId, count in pairs(playerDropCounts) do
            if count > 0 then
                playerDropCounts[playerId] = math.max(0, count - 5) -- Slowly reduce count
            end
        end
    end
end)

print("[InventoryDropManager] Server initialized with configuration:", DROP_CONFIG)
