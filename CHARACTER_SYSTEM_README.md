# Character Class Selection System

A comprehensive dev UI system for character class selection and management in Roblox using Rojo.

## Features

- **4 Character Classes**: Berserker, Knight, Gladiator, and Samurai
- **3 Presets per Class**: Each class has 3 unique character builds
- **Character Stats**: HP, Mana, Attack, Defense, Magic Resist, Status Ailments, Speed
- **DataStore Persistence**: Character data is automatically saved and loaded
- **Dev UI Interface**: Toggleable UI in bottom-right corner
- **Real-time Display**: Shows raw character data in text format

## File Structure

```
src/
├── shared/
│   └── character_data.luau          # Character definitions and presets
├── server/
│   └── character_service.luau       # DataStore service and server logic
└── client/
    └── dev_ui.luau                  # Client-side dev UI interface
```

## How to Use

1. **Build with Rojo**: Use `rojo build` to sync the project to Roblox Studio
2. **Open Dev UI**: Click the "DEV" button in the bottom-right corner of the screen
3. **Select Class**: Choose from Berserker, Knight, Gladiator, or Samurai
4. **Select Preset**: Pick from 3 different builds for each class
5. **View Data**: See all character stats and status ailments in real-time

## Character Classes & Presets

### Berserker
- **Rage Warrior**: High HP, moderate attack, berserker rage
- **Fury Berserker**: High attack, low defense, fury abilities
- **Bloodthirsty**: Highest HP, regeneration, bloodthirst

### Knight
- **Holy Knight**: Balanced stats, divine protection
- **Shield Guardian**: Highest defense, fortress abilities
- **Paladin**: High magic resist, healing abilities

### Gladiator
- **Arena Champion**: Balanced fighter, showmanship
- **Net Warrior**: High mana, entangle abilities
- **Trident Master**: High attack, piercing strikes

### Samurai
- **Honor Blade**: Balanced samurai, bushido code
- **Shadow Strike**: High speed, stealth abilities
- **Dragon Slayer**: Highest attack, elemental strikes

## Technical Details

- **DataStore**: Uses Roblox DataStoreService for persistence
- **Remote Events**: Client-server communication via RemoteEvents
- **Auto-save**: Character data saves every 30 seconds and on player leave
- **Memory Storage**: Character data cached in memory for quick access
- **Error Handling**: Graceful fallbacks for DataStore failures

## Adding New Classes

To add new character classes:

1. Edit `src/shared/character_data.luau`
2. Add new class to `CLASS_PRESETS` table
3. Define 3 presets with unique stats and abilities
4. The UI will automatically detect and display new classes

## Customization

- Modify character stats in `character_data.luau`
- Adjust UI appearance in `dev_ui.luau`
- Change auto-save interval in `character_service.luau`
- Add new status ailments or stats as needed

## Requirements

- Roblox Studio
- Rojo (for building)
- DataStore access enabled in game settings
