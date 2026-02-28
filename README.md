# Guild Broadcast

A lightweight World of Warcraft 1.12 (Vanilla) addon that adds a **minimap broadcast icon** for sending guild messages with a customizable cooldown.

---

## Features

- **Minimap icon** — a draggable circular button positioned around the minimap edge.
- **Left-click** the icon to open a small popup where you can type and send a guild broadcast.
- **Right-click** the icon to print slash-command help to chat.
- **Hover tooltip** showing the addon name and current cooldown status (ready or time remaining).
- **Cooldown system** — configurable cooldown between broadcasts (default: 5 minutes). The icon dims while on cooldown.
- **Slash commands** — send broadcasts and adjust settings directly from the chat box.
- **SavedVariables** — the cooldown duration and minimap icon position are saved between sessions.

---

## Installation

1. Download or clone this repository.
2. Copy the `GuildBroadcast` folder into your WoW addons directory:
   ```
   World of Warcraft\Interface\AddOns\GuildBroadcast\
   ```
   The folder should contain:
   - `GuildBroadcast.toc`
   - `GuildBroadcast.lua`
   - `GuildBroadcast.xml`
3. Launch WoW 1.12 and enable **Guild Broadcast** in the AddOns list at the character-select screen.

---

## Slash Commands

| Command | Description |
|---|---|
| `/gb` or `/guildbroadcast` | Show help and available commands |
| `/gb send <message>` | Send a guild broadcast directly from the command line |
| `/gb cd <minutes>` | Set the cooldown in minutes (e.g. `/gb cd 10`) |
| `/gb status` | Show the current cooldown status and configured duration |

---

## Usage

### Using the minimap icon
1. **Left-click** the scroll icon on your minimap to open the broadcast window.
2. Type your message in the text box.
3. Press **Enter** or click **Send** to broadcast to your guild.
4. Click **Cancel** or press **Escape** to close the window without sending.

### Dragging the icon
Click and drag the minimap icon to reposition it anywhere around the minimap border. The position is saved automatically.

### Adjusting the cooldown
```
/gb cd 10
```
Sets the cooldown to 10 minutes. The new value is persisted across sessions.

---

## Compatibility

- **WoW client**: 1.12.x (Vanilla / Classic-era private servers using Interface version `11200`)
- Uses only WoW 1.12 API functions (`SendChatMessage`, `GetGuildInfo`, `GameTooltip`, etc.)
- No external library dependencies

---

## Author

**Tracer96**