# Admin Panel - Banned Players Feature

## Overview
Add a "Banned Players" tab to view and unban players from the admin panel.

## Implementation Plan

### 1. UI Changes (adminPanel.client.luau)
- Add tab buttons at top: "Active Players" | "Banned Players"
- Create separate ScrollingFrame for banned players
- Reuse existing ban dialog for unbanning

### 2. Server Changes (admin_panel_server.server.luau)
- Add "GetBannedPlayers" action
- Query AdminDataStore for all Ban_* keys
- Return list of banned players with:
  - UserId
  - Username (from UserId lookup)
  - BannedAt (timestamp)
  - Duration
  - DisplayReason
  - PrivateReason
  - BannedBy

### 3. Ban Row Display
- Show username, ban date, duration, reason
- "UNBAN" button (opens ban dialog in unban mode)
- Similar layout to player rows

### 4. Unban Flow
- Click UNBAN → Opens ban dialog
- Dialog shows ban info (read-only)
- "CONFIRM UNBAN" button
- Fires "UnbanPlayer" to server

## Data Structure
```lua
{
    UserId = 4492443366,
    Username = "PlayerName",
    BannedAt = "1765213987",
    Duration = "86400",
    DisplayReason = "Violation of experience rules",
    PrivateReason = "",
    BannedBy = "9774226514"
}
```

## Files to Modify
1. src/client/adminPanel.client.luau
2. src/server/admin_panel_server.server.luau
3. src/shared/AdminDataStore.luau (if needed)
