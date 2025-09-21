# Hitbox System Architecture

This document explains how the weapon and skill hitbox systems work together, including the combo system and tool activation blocking logic.

## 🎯 Overview

The hitbox system has **three main types** of hitboxes:
1. **Weapon Hitboxes** (Red) - Regular weapon attacks
2. **Combo Hitboxes** (Red) - Custom combo attacks with timing
3. **Skill Hitboxes** (Blue) - Special abilities (K/L keys)

## 🏗️ System Architecture

### Core Components

| Component | File | Purpose |
|-----------|------|---------|
| `DynamicHitboxClient` | `DynamicHitboxClient.client.luau` | Central hitbox generation and blocking logic |
| `BerserkerCombo` | `weapon_script_berserker_combo.lua` | Combo system with custom timing |
| `WeaponScript` | `weapon_script_berserker.client.luau` | Weapon input handling |
| `SkillScript` | `skill_script_berserker.client.luau` | Skill input handling |
| `HitboxConfig` | `shared/HitboxConfig.luau` | Configuration for all hitbox types |

## 🔄 Input Flow Diagram

```
Left Mouse Click
├── UserInputService.InputBegan (WeaponScript)
│   ├── playAttack()
│   ├── BerserkerCombo.executeComboAttack()
│   ├── Sets _G.comboSystemActive = true
│   └── _G.generateComboHitbox() → Red Hitbox
│
└── tool.Activated (DynamicHitboxClient)
    ├── shouldAllowToolActivation()
    ├── if (_G.comboSystemActive) → BLOCKED
    └── else → generateWeaponHitbox() → Red Hitbox

K/L Key Press
└── UserInputService.InputBegan (SkillScript)
    ├── generateSkillHitbox()
    └── _G.generateSkillHitbox() → Blue Hitbox
```

## 🚫 Tool Activation Blocking System

### Global State Variables
Located in `DynamicHitboxClient.client.luau`:
```lua
_G.comboSystemActive = false  -- Combo system running status
_G.lastComboTime = 0         -- Timestamp of last combo activity
```

### Blocking Logic
```lua
local function shouldAllowToolActivation(tool)
    if CollectionService:HasTag(tool, "berserker_weapon") then
        local currentTime = tick()
        local timeSinceLastCombo = currentTime - _G.lastComboTime
        
        -- Block if combo system is active
        if _G.comboSystemActive then
            return false  -- ❌ BLOCKED
        end
        
        -- Block if recent combo activity (0.1s buffer)
        if timeSinceLastCombo < 0.1 then
            return false  -- ❌ BLOCKED
        end
    end
    
    return true  -- ✅ ALLOWED
end
```

### When Blocking Occurs
- **During combo attacks**: `_G.comboSystemActive = true`
- **Between combo attacks**: Within combo window (2.0s default)
- **After combo ends**: 0.1s buffer to prevent conflicts

## ⚙️ Combo System State Management

### State Transitions

| Event | `_G.comboSystemActive` | `_G.lastComboTime` | Tool Activation |
|-------|------------------------|-------------------|-----------------|
| Combo starts | `true` | `tick()` | ❌ BLOCKED |
| Attack finishes | `true` (if more attacks) | `tick()` | ❌ BLOCKED |
| Combo completes | `false` | `tick()` | ✅ ALLOWED (after 0.1s) |
| Combo times out | `false` | `tick()` | ✅ ALLOWED (after 0.1s) |
| Manual reset | `false` | `tick()` | ✅ ALLOWED (after 0.1s) |

### Combo Timing (from HitboxConfig.luau)
```lua
comboWindow = 2.0,  -- Time to continue combo (seconds)
resetTime = 3.0,    -- Time before combo auto-resets (seconds)
```

## 🎮 Hitbox Types & Functions

### 1. Regular Weapon Hitboxes
- **Trigger**: `tool.Activated` (when not blocked)
- **Function**: `DynamicHitboxClient.generateWeaponHitbox(tool)`
- **Color**: 🔴 Red
- **Config**: Uses weapon config from `HitboxConfig.luau`

### 2. Combo Hitboxes
- **Trigger**: Left click → Combo system
- **Function**: `_G.generateComboHitbox(tool, size, offset, damage)`
- **Color**: 🔴 Red (same as weapons)
- **Config**: Custom per attack from combo config

### 3. Skill Hitboxes
- **Trigger**: K/L keys
- **Function**: `_G.generateSkillHitbox(skillKey)`
- **Color**: 🔵 Blue
- **Config**: Uses skill config from `HitboxConfig.luau`

## 🔧 Configuration System

### HitboxConfig.luau Structure
```lua
WEAPON_CONFIGS = {
    ["berserker_weapon"] = {
        size = Vector3.new(5, 5, 3),
        offset = Vector3.new(0, 0, 1.5),
        baseDamage = 12,
    }
}

COMBO_CONFIGS = {
    ["berserker_combo"] = {
        comboWindow = 2.0,
        resetTime = 3.0,
        attack1 = { size, offset, baseDamage, duration, ... },
        attack2 = { size, offset, baseDamage, duration, ... },
        attack3 = { size, offset, baseDamage, duration, ... },
    }
}

SKILL_CONFIGS = {
    ["berserker_skill_1"] = {
        size = Vector3.new(6, 6, 5),
        offset = Vector3.new(0, 0, 2.5),
        baseDamage = 15,
        keyCode = Enum.KeyCode.K,
    }
}
```

## 🐛 Debugging Commands

### Available Global Functions
```lua
_G.debugCombo()              -- Show current combo state
_G.checkHitboxSystem()       -- Verify hitbox system availability
_G.resetCombo()              -- Manually reset combo
_G.setComboTimeout(seconds)  -- Adjust combo timeout
_G.getComboTimeout()         -- Get current timeout
_G.setAttackDuration(n, s)   -- Change attack duration
_G.getAttackDurations()      -- Get current durations
```

### Debug Output Examples
```
[BERSERKER COMBO] Executing attack 1: Berserker Strike 1 (Duration: 0.80s)
[DYNAMIC HITBOX] ❌ Tool activation blocked - combo system is active
[BERSERKER COMBO] Attack 1 duration completed (0.80s)
[BERSERKER COMBO] Still in combo window, waiting for next input...
```

## 🚨 Common Issues & Solutions

### Issue: Double Hitboxes
**Symptom**: Both combo and weapon hitboxes fire
**Cause**: Blocking logic not working
**Solution**: Check `_G.comboSystemActive` is being set properly

### Issue: Tool Activation Never Unblocks
**Symptom**: Regular attacks stop working
**Cause**: `_G.comboSystemActive` stuck at `true`
**Solution**: Call `_G.resetCombo()` or check combo reset logic

### Issue: Combo Timing Too Fast/Slow
**Symptom**: Combo feels wrong
**Solution**: Adjust `comboWindow` and `resetTime` in `HitboxConfig.luau`

## 📝 Development Notes

### Adding New Weapon Types
1. Add weapon config to `WEAPON_CONFIGS`
2. Add combo config to `COMBO_CONFIGS` 
3. Update blocking logic if needed (currently only blocks `berserker_weapon`)

### Adding New Skills
1. Add skill config to `SKILL_CONFIGS`
2. Skills automatically work with `_G.generateSkillHitbox()`

### Modifying Combo Logic
- Main combo logic in `weapon_script_berserker_combo.lua`
- Global state management in `DynamicHitboxClient.client.luau`
- Always update both when making changes

## 🎯 Key Design Principles

1. **Separation of Concerns**: Each system has a clear responsibility
2. **Global State Management**: Centralized combo state prevents conflicts
3. **Configuration-Driven**: Easy to adjust timing and damage without code changes
4. **Fail-Safe Design**: System falls back to basic weapon hitboxes if combo fails
5. **Visual Feedback**: Different colors help distinguish hitbox types during development
