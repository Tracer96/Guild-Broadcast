# Guild Broadcast

A lightweight World of Warcraft 1.12 (Vanilla) addon that adds a **minimap broadcast icon** and a simple panel for auto-sending messages to guild chat on a repeating timer.

---

## Features

- **Minimap icon** — a draggable circular button positioned around the minimap edge.
- **Left-click** the icon to toggle the broadcast panel open or closed.
- **Broadcast panel** — type your message, set a repeat interval, and click **Start** to auto-broadcast to your guild every N seconds.
- **Auto-broadcast** — the minimap icon turns **green** while auto-broadcast is active. The first message is sent immediately when you click Start, then repeats every N seconds.
- **Slash command** — `/gb` toggles the panel open or closed.
- **SavedVariables** — your last message, interval, and minimap icon position are saved between sessions.

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

## Slash Command

| Command | Description |
|---|---|
| `/gb` | Toggle the broadcast panel open / closed |

---

## Using the Panel

1. Type `/gb` or **left-click** the minimap icon to open the panel.
2. Type your guild message in the large text box.
3. Enter the repeat interval in seconds (minimum **10**) in the **Interval (seconds)** field.
4. Click **Start** to begin auto-broadcasting. The first message is sent immediately, then repeated every N seconds.
5. Click **Stop** to halt auto-broadcast.
6. Click **X** or press **Escape** to close the panel. Auto-broadcast continues running in the background if active.

### Dragging the icon

Click and drag the minimap icon to reposition it anywhere around the minimap border. The position is saved automatically.

---

## Compatibility

- **WoW client**: 1.12.x (Vanilla / Classic-era private servers using Interface version `11200`)
- Uses only WoW 1.12 API functions (`SendChatMessage`, `GetGuildInfo`, `GameTooltip`, etc.)
- No external library dependencies

---

## Author

**Tracer96**