# Command Help System - Documentation

## Overview
A user-friendly command help system that displays all available chat commands in an interactive UI. Players can type `/slavko` to get a hint about the commands system, and `/commands` to open a comprehensive commands list.

## Features

✅ **Quick Help**: Type `/slavko` to get a hint message  
✅ **Full Commands List**: Type `/commands` to open the commands UI  
✅ **Interactive UI**: Draggable, scrollable panel similar to the stats display  
✅ **Detailed Information**: Each command shows syntax, description, and example  
✅ **Responsive Design**: Scales properly on mobile devices  
✅ **Easy Access**: Available to all players

---

## How to Use

### Getting Help

**Step 1**: Type `/slavko` in the chat
- You'll receive a hint message: "Type /commands to see all available commands!"

**Step 2**: Type `/commands` in the chat
- A commands panel will appear on the right side of your screen

**Step 3**: Browse the commands
- Scroll through the list to see all available commands
- Each command shows:
  - **Command syntax** (in blue)
  - **Description** (what it does)
  - **Example** (how to use it)

**Step 4**: Close the panel
- Type `/commands` again to toggle the panel off
- Or drag it out of the way if you want to keep it open

---

## Available Commands

The system displays the following commands:

### 1. `/spawn [object]`
- **Description**: Spawn an object at your location. Use 'clear' to remove spawned objects.
- **Example**: `/spawn tree`

### 2. `/transform [class]`
- **Description**: Transform into a different class temporarily.
- **Example**: `/transform archer`

### 3. `/transform myself`
- **Description**: Return to your original class form.
- **Example**: `/transform myself`

### 4. `/slabura`
- **Description**: Spawn the Slabura boss at your location.
- **Example**: `/slabura`

### 5. `/slavko [password]`
- **Description**: Access special admin features with the correct password.
- **Example**: `/slavko [password]`

### 6. `/admin`
- **Description**: Open the admin panel (super admins only).
- **Example**: `/admin`

### 7. `/commands`
- **Description**: Toggle this commands help window.
- **Example**: `/commands`

### 8. `/secretRoom`
- **Description**: Teleport to the secret room (if you have access).
- **Example**: `/secretRoom`

### 9. `/teleport [location]`
- **Description**: Teleport to a specific location (admin only).
- **Example**: `/teleport spawn`

---

## Technical Details

### File Structure

**Server-Side:**
- `src/server/command_help_chat.server.luau` - Handles chat commands and sends events

**Client-Side:**
- `src/client/displayCommands.client.luau` - Displays the commands UI

### How It Works

1. **Player types `/slavko`**:
   - Server detects the command
   - Sends a "hint" event to the client
   - Client displays a chat message with instructions

2. **Player types `/commands`**:
   - Server detects the command
   - Sends a "toggle" event to the client
   - Client toggles the commands UI visibility

3. **Commands UI**:
   - Draggable panel (drag the title bar)
   - Scrollable list of commands
   - Auto-scales for different screen sizes
   - Positioned on the right side by default

### UI Specifications

- **Size**: 400x450 pixels (base size)
- **Position**: Right side of screen, vertically centered
- **Colors**:
  - Background: RGB(20, 20, 20) with 30% transparency
  - Title bar: RGB(40, 40, 40)
  - Command entries: RGB(30, 30, 30) with 50% transparency
  - Command text: RGB(100, 200, 255) - Blue
  - Description text: RGB(200, 200, 200) - Light gray
  - Example text: RGB(150, 150, 150) - Gray italic
- **Font**: Gotham (Bold for commands, Regular for descriptions)
- **Scaling**: Responsive for mobile devices (0.55x - 0.95x)

### Remote Events

**CommandHelpEvent** (ReplicatedStorage)
- **Direction**: Server → Client
- **Actions**:
  - `"hint"` - Display a hint message in chat
  - `"toggle"` - Toggle the commands UI visibility

---

## Customization

### Adding New Commands

To add a new command to the list, edit `src/client/displayCommands.client.luau`:

```lua
-- Find the commands table (around line 300)
local commands = {
    -- ... existing commands ...
    {
        command = "/yourcommand [parameter]",
        description = "What your command does",
        example = "/yourcommand example"
    }
}
```

### Changing UI Position

Edit `src/client/displayCommands.client.luau`:

```lua
-- Change BASE_POSITION to move the panel
local BASE_POSITION = UDim2.new(1, -BASE_MARGIN, 0.5, 0) -- Right side
-- Or
local BASE_POSITION = UDim2.new(0, BASE_MARGIN, 0.5, 0) -- Left side
```

### Changing UI Size

Edit `src/client/displayCommands.client.luau`:

```lua
-- Change BASE_FRAME_SIZE
local BASE_FRAME_SIZE = Vector2.new(400, 450) -- Width, Height
```

---

## Integration with Existing Systems

### Works With:
- ✅ Stats Display (`displayStats.client.luau`)
- ✅ Admin Panel (`adminPanel.client.luau`)
- ✅ All existing chat commands
- ✅ Mobile and desktop devices

### Does Not Conflict With:
- Chat system
- Other UI elements
- Game controls
- Existing commands

---

## Troubleshooting

### "Nothing happens when I type /slavko"
**Solution**: 
- Make sure you're typing it exactly: `/slavko` (lowercase)
- Check that the server script is running (check Output window)

### "Commands UI doesn't appear"
**Possible causes**:
1. CommandHelpEvent not created
2. Client script not running
3. UI is off-screen

**Solutions**:
- Check Output window for errors
- Verify both server and client scripts are in the correct folders
- Try typing `/commands` again to toggle

### "UI is too small/large on mobile"
**Solution**: The UI should auto-scale. If not, check:
- `determineUIScale()` function in the client script
- Viewport size detection

---

## Benefits

### For Players:
- 🎯 Easy to discover available commands
- 📖 Clear explanations and examples
- 🖱️ Interactive, draggable interface
- 📱 Works on mobile devices

### For Developers:
- 🔧 Easy to add new commands
- 🎨 Customizable appearance
- 📦 Modular design
- 🔄 Reusable code pattern

---

## Future Enhancements

Potential improvements for future versions:

- [ ] Search/filter commands
- [ ] Command categories (Admin, Player, Fun, etc.)
- [ ] Keyboard shortcut to open (e.g., F1)
- [ ] Command history
- [ ] Favorite commands
- [ ] Permission-based filtering (only show commands you can use)
- [ ] Tooltips on hover
- [ ] Copy command to clipboard button

---

## Version History

### v1.0 (Current)
- Initial implementation
- `/slavko` hint command
- `/commands` toggle command
- Draggable UI panel
- 9 commands documented
- Mobile responsive design
- Similar styling to displayStats

---

## Related Documentation

- [Ban System Guide](BAN_SYSTEM_GUIDE.md) - Admin panel and ban system
- [Ban System Changes](BAN_SYSTEM_CHANGES.md) - Recent updates to ban system

---

## Support

For issues or questions:
- Check the Output window in Roblox Studio for errors
- Verify both server and client scripts are present
- Ensure RemoteEvent is created in ReplicatedStorage
- Test in both Studio and published game

---

**Created**: December 8, 2025  
**Status**: ✅ Complete and Ready for Use
