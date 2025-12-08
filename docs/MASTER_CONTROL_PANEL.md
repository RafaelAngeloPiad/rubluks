# Master Control Panel - Detailed Guide

## Overview
The Master Control Panel is an admin-only feature that provides game-wide toggles for testing and gameplay customization. Admins must type `/slavko` each time they join a place to access it.

---

## Accessing the Panel

### Command
```
/slavko
```

**Requirements:**
- Must have admin access
- Must type the command **every time** you join a place
- Command is case-insensitive

**After typing /slavko:**
1. Click the **"Show Controls"** button
2. The Master Control Panel will appear
3. Use the toggles to customize gameplay

---

## Available Toggles

### 1. PVP (Player vs Player)
**Default**: OFF

**Description**: Controls whether players can fight each other

**When ON:**
- Players can damage other players
- Useful for testing combat strength
- Great for PvP tournaments or duels

**When OFF:**
- Players cannot hurt each other
- Normal PvE gameplay

---

### 2. Mob Mode
**Default**: Excluded (Normal Mode)

**Description**: Controls how enemies (mobs) behave toward each other

**Options:**

#### Excluded (Normal)
- Enemies only react to and attack players
- Standard gameplay mode
- Mobs ignore other mobs

#### Versus
- Enemies attack those who are not their kind
- Example: Zombies will fight Spiders
- Creates faction warfare between mob types

#### Frenzy
- Enemies attack everything, including their own kind
- Total chaos mode
- All mobs are hostile to all other mobs

#### Peaceful
- Enemies don't hurt players OR each other
- Safe exploration mode
- Mobs are completely passive

---

### 3. Mob FF (Mob Friendly Fire)
**Default**: OFF

**Description**: Controls whether mobs can damage each other with their attacks

**When OFF (Default):**
- Mob attacks that overlap don't hurt other mobs
- Prevents accidental mob-on-mob damage

**When ON:**
- Mobs can hurt each other when attacks overlap
- More realistic combat

**Note**: This is mostly handled by Mob Mode settings. If you switch Mob Mode to Versus or Frenzy, this becomes less relevant.

---

### 4. God Mode
**Default**: OFF

**Description**: Makes players invincible

**When ON:**
- Players cannot die
- Health doesn't decrease
- Perfect for testing without interruption
- Useful for exploring dangerous areas

**When OFF:**
- Normal gameplay
- Players can take damage and die

---

### 5. Status Immunity
**Default**: OFF

**Description**: Protects players from status effects

**Status Effects Bypassed:**
- **Stun** - Cannot be stunned
- **Slow** - Movement speed not reduced
- **Frozen** - Cannot be frozen in place
- **Burn** - Fire damage ignored

**When ON:**
- Complete immunity to all status effects
- Useful for testing without interruptions
- Great for boss fights with heavy CC

**When OFF:**
- Normal status effect behavior
- Enemies can apply debuffs

---

## Usage Tips

### For Testing
1. Enable **God Mode** + **Status Immunity** for safe testing
2. Use **Mob Mode: Peaceful** to test without combat
3. Enable **PVP** to test player combat mechanics

### For Fun Gameplay
1. **Mob Mode: Versus** - Watch different mob types fight
2. **Mob Mode: Frenzy** - Total chaos with all mobs fighting
3. **PVP ON** - Player tournaments and duels

### For Exploration
1. **God Mode ON** - Explore dangerous areas safely
2. **Mob Mode: Peaceful** - No combat while exploring
3. **Status Immunity ON** - No annoying debuffs

---

## Important Notes

⚠️ **Must Re-type /slavko Each Place**
- The command must be entered every time you join a new place
- This is a security feature
- Prevents accidental admin access

🔒 **Admin Only**
- Only players with admin access can use `/slavko`
- Non-admins typing `/slavko` get a hint to use `/commands`

🎮 **Affects All Players**
- These toggles affect the entire server
- Use responsibly when other players are present

---

## Quick Reference

| Toggle | Default | Purpose |
|--------|---------|---------|
| PVP | OFF | Player vs Player combat |
| Mob Mode | Excluded | How mobs behave |
| Mob FF | OFF | Mob friendly fire |
| God Mode | OFF | Player invincibility |
| Status Immunity | OFF | Bypass status effects |

---

## Mob Mode Quick Reference

| Mode | Players | Same Mobs | Different Mobs |
|------|---------|-----------|----------------|
| Excluded | Attacked | Ignored | Ignored |
| Versus | Attacked | Ignored | Attacked |
| Frenzy | Attacked | Attacked | Attacked |
| Peaceful | Ignored | Ignored | Ignored |

---

## Related Commands

- `/slavko` - Access Master Control Panel (admin)
- `/admin` - Access Admin Panel (super admin)
- `/commands` - View all commands (everyone)

---

## Troubleshooting

**Panel doesn't appear after /slavko:**
- Make sure you have admin access
- Check that you clicked "Show Controls" button
- Try typing `/slavko` again

**Toggles don't work:**
- Verify you're an admin
- Check console for errors
- Make sure the panel is properly unlocked

**Lost access after changing places:**
- This is normal - type `/slavko` again
- Security feature to prevent accidental access

---

**File**: `src/client/masterControl.client.luau`  
**Access**: Admin only  
**Command**: `/slavko`  
**Status**: ✅ Active
