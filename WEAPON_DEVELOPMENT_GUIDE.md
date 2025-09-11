# Weapon Development Guide

This guide explains how to modify and extend the weapon system for your Roblox game.

## 📁 File Structure

```
src/client/
├── weapon_utils.luau              # Common functions (don't edit unless adding new common features)
├── berserker_weapon_script.client.luau
├── gladiator_weapon_script.client.luau
├── knight_weapon_script.client.luau
├── samurai_weapon_script.client.luau
└── scan_for_weapon_tag.luau       # Tool detection system
```

## 🎯 How to Add New Animations

### Step 1: Add Animation ID to Weapon Script

In your weapon script (e.g., `berserker_weapon_script.client.luau`):

```lua
-- Add your new animation ID
local attackAnimId = "rbxassetid://YOUR_ATTACK_ANIMATION_ID"

-- Add it to the animations table
local animations = {
    idle = idleAnimId,
    run = runAnimId,
    jump = jumpAnimId,
    climb = climbAnimId,
    attack = attackAnimId,  -- Add your new animation here
}
```

### Step 2: Add Animation Track to State

In the `onCharacterAdded` function, add the new track:

```lua
local function onCharacterAdded(state, char)
    state.character = char
    state.humanoid = char:FindFirstChildOfClass("Humanoid")
    if not state.humanoid then return end
    state.animator = state.humanoid:FindFirstChildOfClass("Animator")
    if not state.animator then
        state.animator = Instance.new("Animator")
        state.animator.Parent = state.humanoid
    end

    WeaponUtils.setupTracks(state, animations)
    -- Add your custom track setup here
    local attackAnim = Instance.new("Animation")
    attackAnim.AnimationId = attackAnimId
    state.attackTrack = state.animator:LoadAnimation(attackAnim)
    
    disconnectAll(state)
    -- ... rest of function
end
```

### Step 3: Update weapon_utils.luau

Add the new track to the utility functions:

```lua
-- In stopAllTracks function
function WeaponUtils.stopAllTracks(state)
    if state.idleTrack then state.idleTrack:Stop() end
    if state.runTrack then state.runTrack:Stop() end
    if state.jumpTrack then state.jumpTrack:Stop() end
    if state.climbTrack then state.climbTrack:Stop() end
    if state.attackTrack then state.attackTrack:Stop() end  -- Add this line
end

-- In setupTracks function
function WeaponUtils.setupTracks(state, animations)
    -- ... existing code ...
    
    -- Add attack animation if it exists
    if animations.attack then
        local attackAnim = Instance.new("Animation")
        attackAnim.AnimationId = animations.attack
        state.attackTrack = state.animator:LoadAnimation(attackAnim)
    end
end
```

### Step 4: Add Attack Logic

In your weapon script, add attack handling:

```lua
-- Add attack function
local function onAttack(state)
    if not state.toolEquipped or not state.attackTrack then return end
    
    -- Stop other animations and play attack
    WeaponUtils.stopAllTracks(state)
    state.attackTrack:Play()
    
    -- Optional: Reset to idle after attack finishes
    state.attackTrack.Ended:Connect(function()
        if state.toolEquipped then
            WeaponUtils.playInstantAnimation(state, movementKeys)
        end
    end)
end

-- Add input handling for attack (e.g., Left Mouse Button)
local function onInputBegan(state, input, gameProcessed)
    WeaponUtils.onInputBegan(state, input, gameProcessed, movementKeys)
    
    -- Add attack input
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onAttack(state)
    end
end
```

## 🛡️ How to Modify Shield Offsets

### For Weapons with Shields (Berserker, Gladiator, Knight):

In your weapon script, modify the shield offset:

```lua
-- Berserker: No forward offset
local shieldForwardOffset = CFrame.new(0, 0, 0)

-- Gladiator: Moved forward by 0.5 studs
local shieldForwardOffset = CFrame.new(-0.5, 0, 0)

-- Knight: Moved forward by 0.5 studs  
local shieldForwardOffset = CFrame.new(-0.5, 0, 0)

-- Custom offset example:
local shieldForwardOffset = CFrame.new(-0.3, 0.2, 0.1)  -- X, Y, Z adjustments
```

### For Weapons without Shields (Samurai):

Samurai doesn't have shield handling, so no changes needed.

## 🎮 How to Add New Input Handling

### Add Custom Input Detection:

```lua
local function onInputBegan(state, input, gameProcessed)
    -- Use existing utility for WASD movement
    WeaponUtils.onInputBegan(state, input, gameProcessed, movementKeys)
    
    -- Add your custom inputs
    if input.KeyCode == Enum.KeyCode.Q then
        -- Handle Q key press
        print("Q pressed!")
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Handle left mouse click
        print("Left mouse clicked!")
    end
end
```

## 🔧 How to Add New Weapon Types

### Step 1: Create New Weapon Script

Copy an existing weapon script and modify:

```lua
-- new_weapon_script.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local WeaponScanner = require(script.Parent.scan_for_weapon_tag)
local WeaponUtils = require(script.Parent.weapon_utils)

-- Your weapon's animation IDs
local idleAnimId = "rbxassetid://YOUR_IDLE_ANIMATION_ID"
local runAnimId = "rbxassetid://YOUR_RUN_ANIMATION_ID"
-- ... etc

-- Your weapon's specific settings
local shieldForwardOffset = CFrame.new(0, 0, 0)  -- Adjust as needed

-- Animation configuration
local animations = {
    idle = idleAnimId,
    run = runAnimId,
    jump = jumpAnimId,
    climb = climbAnimId,
}

-- ... rest of the script (copy from existing weapon)
```

### Step 2: Update Tool Tags

Make sure your tool in Roblox Studio has the correct CollectionService tag:
- `berserker_weapon`
- `gladiator_weapon` 
- `knight_weapon`
- `samurai_weapon`
- `your_new_weapon` (for your new weapon)

## 🐛 Common Issues & Solutions

### Animation Not Playing
- Check that the Animation ID is correct
- Ensure the animation is uploaded to Roblox
- Verify the animation is loaded in `setupTracks`

### Shield Not Attaching
- Check that your tool has both "Handle" and "Shield" parts
- Verify the shield offset is correct
- Make sure the tool has the right CollectionService tag

### Input Not Working
- Check that `gameProcessed` is false for your input
- Ensure the input handling is in the right function
- Verify the input type matches what you're checking for

## 📝 Best Practices

1. **Keep weapon-specific logic in weapon scripts** - Don't put weapon-specific code in `weapon_utils.luau`
2. **Use the utility functions** - Don't duplicate animation management code
3. **Test each weapon individually** - Make sure changes don't break other weapons
4. **Use descriptive variable names** - Makes the code easier to understand
5. **Add comments** - Explain complex logic for future reference

## 🔄 Making Changes to Common Functions

If you need to modify `weapon_utils.luau`:

1. **Think carefully** - Changes affect ALL weapons
2. **Test thoroughly** - Make sure all weapons still work
3. **Add parameters** - Use parameters to make functions flexible
4. **Document changes** - Update this guide if you add new features

## 📋 Quick Reference

### Animation States Available:
- `idle` - Standing still
- `run` - Moving with WASD
- `jump` - Jumping or falling
- `climb` - Climbing ladders

### Input Types Available:
- `Enum.KeyCode.W/A/S/D` - Movement keys
- `Enum.UserInputType.MouseButton1` - Left mouse click
- `Enum.UserInputType.MouseButton2` - Right mouse click
- `Enum.KeyCode.Space` - Space bar
- Any other `Enum.KeyCode` values

### Shield Offsets:
- `CFrame.new(0, 0, 0)` - No offset
- `CFrame.new(-0.5, 0, 0)` - Move forward 0.5 studs
- `CFrame.new(0, 0.2, 0)` - Move up 0.2 studs
- `CFrame.new(0, 0, 0.3)` - Move right 0.3 studs

This system is designed to be simple and maintainable while giving you full control over each weapon's behavior!
