# Archer Button System Guide

Complete guide for using the **tag-based button system** for Archer actions.

## 🏹 How It Works

Just like the Samurai system, you:
1. Tag your buttons with CollectionService tags
2. Use **one script** (`ArcherButtonManager.client.luau`) that finds all buttons
3. The script automatically connects buttons to actions

## 📋 Setup Instructions

### Step 1: Place the Manager Script

Put `ArcherButtonManager.client.luau` in:
- `StarterGui > ActionsGUI` (inside your ScreenGui), OR
- `StarterPlayerScripts`

### Step 2: Tag Your Buttons

Use CollectionService to tag each button:

#### Combat Actions
- **Attack Button** → Tag: `archer_attack_trigger`
- **Block Button** → Tag: `archer_block_trigger`
- **Wave Button** → Tag: `archer_wave_trigger`

#### Skills (Q & E)
- **Piercing Shot Button** → Tag: `archer_piercingshot_trigger`
- **Power Shot Button** → Tag: `archer_powershot_trigger`

#### Buffs (X & C)
- **Hunter Instinct Button** → Tag: `archer_hunterinstinct_trigger`
- **Hunter Mark Button** → Tag: `archer_huntermark_trigger`

#### Ultimate (Z)
- **Starfall Button** → Tag: `archer_starfall_trigger`

## 🎯 Available Button Tags

| Tag Name | Action | Key Binding |
|----------|--------|-------------|
| `archer_attack_trigger` | Basic Attack (auto-aims) | Left Click |
| `archer_piercingshot_trigger` | Piercing Shot Skill | Q |
| `archer_powershot_trigger` | Power Shot Skill | E |
| `archer_hunterinstinct_trigger` | Hunter Instinct Buff | X |
| `archer_huntermark_trigger` | Hunter Mark Buff | C |
| `archer_starfall_trigger` | Starfall Ultimate | Z |
| `archer_block_trigger` | Block (hold) | V |
| `archer_wave_trigger` | Wave Emote | L |

## ✅ Example Setup

```
StarterGui
└── ActionsGUI (ScreenGui)
    ├── ArcherButtonManager (LocalScript) ← The manager script
    ├── AttackButton (TextButton)
    │   └── Tags: archer_attack_trigger
    ├── PiercingShotButton (TextButton)
    │   └── Tags: archer_piercingshot_trigger
    ├── PowerShotButton (TextButton)
    │   └── Tags: archer_powershot_trigger
    ├── HunterInstinctButton (TextButton)
    │   └── Tags: archer_hunterinstinct_trigger
    ├── HunterMarkButton (TextButton)
    │   └── Tags: archer_huntermark_trigger
    ├── StarfallButton (TextButton)
    │   └── Tags: archer_starfall_trigger
    ├── BlockButton (TextButton)
    │   └── Tags: archer_block_trigger
    └── WaveButton (TextButton)
        └── Tags: archer_wave_trigger
```

## 🎮 What Happens Automatically

The manager script handles:
- ✅ Weapon equipped validation
- ✅ Input/movement lock checks
- ✅ Camera direction for aiming skills
- ✅ Aim lock state for precision
- ✅ First-person detection
- ✅ Transparency when weapon not equipped
- ✅ Block press/release detection

## 🏹 Archer-Specific Features

### Auto-Aiming System
The archer system automatically sends:
- **Camera direction** - for accurate projectile aiming
- **Aim lock state** - for precision shooting
- **First-person state** - for proper crosshair alignment

All buttons work seamlessly with the archer's aiming system!

### Skills with Camera Direction
Piercing Shot and Power Shot automatically use your camera's aim direction when fired from buttons. No extra code needed!

## 💡 Benefits

✅ **One script** for all buttons  
✅ **Auto-aiming** handled automatically  
✅ **Clean code** - no duplication  
✅ **Easy maintenance** - update once  
✅ **Scalable** - add buttons by tagging  

## 📝 Notes

- Server handles all cooldown logic
- Button text stays static (no cooldown feedback)
- Aiming system works automatically
- Camera direction sent with attack/skill buttons
- All validation handled by `ArcherActionModule`

