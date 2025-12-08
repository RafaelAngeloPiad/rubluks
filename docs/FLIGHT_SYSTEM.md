# Flight System - Documentation

## Overview
A simple flight system that allows players to fly around the map using `/flight` and `/flightoff` commands.

---

## Commands

### `/flight`
- **Description**: Enables flight mode
- **Usage**: Type `/flight` in chat
- **Effect**: Player can fly using WASD controls
- **Speed**: 50 studs/second

### `/flightoff`
- **Description**: Disables flight mode
- **Usage**: Type `/flightoff` in chat
- **Effect**: Returns to normal movement

---

## How It Works

### Controls While Flying
- **W** - Fly forward (camera direction)
- **S** - Fly backward (camera direction)
- **A** - Fly left (camera direction)
- **D** - Fly right (camera direction)
- **Mouse** - Look around to change flight direction

### Technical Details
- Uses `BodyVelocity` for smooth flight
- Camera-relative movement (flies in the direction you're looking)
- Flight speed: 50 studs/second
- Auto-disables on character respawn
- Proper cleanup on disconnect

---

## Files

### Server Script
**File**: `src/server/flight_chat.server.luau`
- Listens for `/flight` and `/flightoff` commands
- Sends events to client to enable/disable flight

### Client Script
**File**: `src/client/flight_control.client.luau`
- Handles flight mechanics
- Creates BodyVelocity for movement
- Processes WASD input
- Camera-relative controls

### Commands UI
**File**: `src/client/displayCommands.client.luau`
- Updated to show `/flight` and `/flightoff` commands

---

## Usage Example

1. Type `/flight` in chat
2. Use WASD to fly around
3. Look with mouse to change direction
4. Type `/flightoff` to stop flying

---

## Notes

- Flight automatically disables when you respawn
- Flight is camera-relative (flies where you look)
- Speed is fixed at 50 studs/second
- Works with all characters

---

**Created**: December 8, 2025
**Status**: ✅ Ready to Use
