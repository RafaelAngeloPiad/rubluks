# Roblox Ban API Integration - Documentation

## Overview
This admin panel now includes full integration with Roblox's Ban API, allowing you to ban and unban players directly from the in-game UI. The system supports:

- **Permanent Bans**: Ban players indefinitely
- **Timed Bans**: Ban players for a specific duration (hours, days, or weeks)
- **Alt Account Detection**: Automatically ban suspected alternate accounts
- **Public & Private Ban Reasons**: Provide reasons visible to users and internal notes
- **Unban Functionality**: Remove bans from players
- **Ban History Tracking**: Track who banned whom and when

## Setup Instructions

### 1. Enable Ban API in Roblox Studio
Before the ban system will work, you **MUST** enable the Ban API in your game settings:

1. Open your game in Roblox Studio
2. Go to **Home** → **Game Settings** (or press Alt+S)
3. Navigate to **Security** tab
4. Find **Enable Studio Access to API Services**
5. Check the box to enable it
6. Click **Save**

Alternatively, you can enable it via the Creator Dashboard:
1. Go to https://create.roblox.com/dashboard/creations
2. Select your experience
3. Go to **Settings** → **Security**
4. Enable **Allow Third Party Sales** and **Enable Studio Access to API Services**

### 2. Required Files
The ban system consists of the following files:

**Client-Side:**
- `src/client/adminPanel.client.luau` - Admin panel UI with ban dialog

**Server-Side:**
- `src/server/admin_panel_server.server.luau` - Handles ban/unban requests
- `src/server/ban_check.server.luau` - Fallback ban checking on player join

**Shared:**
- `src/shared/AdminDataStore.luau` - Manages ban data persistence
- `src/shared/ChatAccessControl.luau` - Admin permission system

## How to Use

### Accessing the Admin Panel
1. Only **Super Admins** can access the admin panel
2. Use the `/admin` chat command to open the panel
3. The panel displays all players currently in the game

### Banning a Player

1. Click the **BAN** button next to the player you want to ban
2. A dialog will appear with the following options:

   **Ban Type:**
   - **PERMANENT**: Ban the player indefinitely
   - **TIMED**: Ban for a specific duration
   - **UNBAN**: Remove an existing ban

   **Duration** (for Timed Bans):
   - Enter a number (e.g., 1, 7, 30)
   - Select unit: Hours, Days, or Weeks

   **Alt Accounts:**
   - ✓ Checked: Ban will apply to all known alternate accounts
   - ☐ Unchecked: Ban only the specific user

   **Public Ban Reason:**
   - This message is shown to the banned player
   - Should follow Roblox Community Standards
   - Max 400 characters
   - Example: "Violation of experience rules"

   **Private Ban Reason:**
   - Internal notes visible only to admins
   - Not shown to the player
   - Max 1000 characters
   - Example: "Repeated griefing after warnings"

3. Click **CONFIRM** to apply the ban
4. The player will be immediately removed from the game

### Unbanning a Player

1. Click the **BAN** button next to the player (or any player if they're offline)
2. Select **UNBAN** as the ban type
3. Click **CONFIRM**
4. The player will be able to rejoin the game

**Note:** To unban offline players, you can use the Roblox Creator Dashboard:
- Go to https://create.roblox.com/dashboard/creations/experiences/[YOUR_GAME_ID]/safety/bans
- Find the player in the ban list
- Click the checkbox next to their name
- Click "Unban user"

## Technical Details

### Ban API Configuration
When you ban a player, the system calls `Players:BanAsync()` with the following configuration:

```lua
{
    UserIds = {targetUserId},
    Duration = -1 or seconds,  -- -1 for permanent, or seconds for timed
    DisplayReason = "Your public reason",
    PrivateReason = "Your private notes",
    ExcludeAltAccounts = false,  -- true to exclude alts
    ApplyToUniverse = true  -- Applies to all places in your game
}
```

### Duration Calculations
- **Hours**: `amount * 3600 seconds`
- **Days**: `amount * 86400 seconds`
- **Weeks**: `amount * 604800 seconds`
- **Permanent**: `-1`

### Data Storage
Ban information is stored in two places:

1. **Roblox Ban System**: The official ban is managed by Roblox
2. **DataStore**: Additional tracking data is saved:
   ```lua
   {
       IsBanned = true,
       Duration = seconds,
       DisplayReason = "reason",
       PrivateReason = "notes",
       BannedAt = timestamp,
       BannedBy = adminUserId
   }
   ```

### Fallback System
The `ban_check.server.luau` script provides a fallback in case:
- The Ban API is not enabled in Studio
- There are issues with the Roblox Ban API
- You need custom ban expiration logic

## Viewing Ban History

### In-Game
Ban history is tracked in the DataStore and includes:
- Who was banned
- When they were banned
- Who banned them
- Ban duration and reasons

### Creator Dashboard
You can view comprehensive ban history at:
https://create.roblox.com/dashboard/creations/experiences/[YOUR_GAME_ID]/safety/bans

This dashboard shows:
- List of all banned users
- Ban status (active/expired)
- Ban duration and reasons
- Ban history for each user
- Ability to search for specific users

## Important Notes

### Permissions
- Only **Super Admins** can ban/unban players
- Super Admins cannot be banned
- The super admin list is defined in `ChatAccessControl.luau`

### Roblox Guidelines
All bans must comply with:
- [Roblox Community Standards](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Community-Standards)
- [Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)

**Public ban reasons must be appropriate and follow these guidelines.**

### Limitations
- Maximum 50 users can be banned at once via the API
- Bans are universe-level (apply to all places in your game)
- Alt account detection is automatic and managed by Roblox

### Testing
When testing in Studio:
- Bans will not apply to production
- You can test the UI and logic
- Use Team Create to test with multiple accounts
- Check the Output window for ban success/error messages

## Troubleshooting

### "Ban API is not available" Warning
**Solution**: Enable API Services in Game Settings (see Setup Instructions above)

### Player Not Getting Banned
**Possible causes:**
1. Ban API not enabled in settings
2. Player is a Super Admin
3. Network/API error (check Output window)

**Solutions:**
- Verify API Services are enabled
- Check Output window for error messages
- Ensure you're not in Studio test mode
- Try using the Creator Dashboard as an alternative

### Ban Not Showing in Creator Dashboard
**Possible causes:**
1. Using place-level bans instead of universe-level
2. Ban was applied in Studio test mode

**Solution:**
- Ensure `ApplyToUniverse = true` (default in our implementation)
- Apply bans in published game, not Studio test mode

### Timed Ban Not Expiring
**Note**: Roblox automatically handles ban expiration. The fallback system in `ban_check.server.luau` also checks for expired bans.

## API Reference

### Client → Server Events

**BanPlayer**
```lua
AdminPanelRequest:FireServer("BanPlayer", {
    UserId = number,
    Duration = number,  -- -1 for permanent
    DisplayReason = string,
    PrivateReason = string,
    ExcludeAltAccounts = boolean
})
```

**UnbanPlayer**
```lua
AdminPanelRequest:FireServer("UnbanPlayer", userId)
```

### DataStore Functions

**Save Ban Data**
```lua
AdminDataStore.SaveBanData(userId, banData)
```

**Load Ban Data**
```lua
local banData = AdminDataStore.LoadBanData(userId)
```

## Support

For issues with:
- **This implementation**: Check the code comments and Output window
- **Roblox Ban API**: See [Official Documentation](https://create.roblox.com/docs/reference/engine/classes/Players#BanAsync)
- **Creator Dashboard**: Visit [Roblox Creator Hub](https://create.roblox.com/dashboard)

## Version History

### v1.0 (Current)
- Initial implementation of Roblox Ban API
- Permanent and timed bans
- Alt account detection
- Public and private ban reasons
- Unban functionality
- Ban data tracking in DataStore
- Fallback ban checking system
