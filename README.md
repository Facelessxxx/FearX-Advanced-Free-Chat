# FearX Chat

A full replacement for the default FiveM chat, with channels, RP commands, cosmetic name tags, a staff panel and built-in auto-moderation.

FearX Chat `provide`s `chat`, so any resource built on the default chat events and exports keeps working without changes.

## Features

### Channels
| Channel | Behaviour |
| --- | --- |
| Local | Proximity chat, 25m range by default |
| OOC | Server-wide out-of-character chat |
| Advertise | Has its own cooldown per player (60s by default) |
| Staff | Only staff can see or post in it |
| Announcements | Read-only, used for server broadcasts |

You can add, rename, recolour or remove channels in `config.lua`.

### Commands
| Command | Description |
| --- | --- |
| `/me [action]` | Describe an action |
| `/do [description]` | Describe the scene |
| `/ooc [message]` | Out-of-character chat |
| `/w [id] [message]` | Whisper to a player |
| `/ad [text]` | Post an advertisement |
| `/clear` | Clear your own chat |
| `/chatsettings` | Open chat settings |
| `/chatunmute [id]` | Staff only: unmute a player |

You can rename or turn off each command, and choose which channel it posts to.

### Customisation
- 5 chat styles: Cards, Bubbles, Minimal, Compact and Feed. Each player picks their own.
- Name tags with shine, glow, pulse, flow and ring effects. A player can wear up to 3 at once.
- Avatar decorations.
- Cosmetic packs unlocked through ACE permissions.
- Discord avatars, cached for performance.
- Job tags (for example LSPD and EMS) that only show while the player is on duty.
- Character names pulled from ESX, QBCore or Qbox.

### Auto-Moderation
- Slur filter with an allow-list for innocent words that contain a slur.
- Blocks IP-logger links (domain list plus keyword matching).
- Blocks Discord invites. Specific invite codes can be allowed.
- Blocks raw IP addresses.
- Optional block on all links, with a list of allowed domains.
- Spam protection that catches message bursts and duplicate messages.
- Auto-mute after repeated filter violations.
- Staff get a notification whenever a message is blocked.

### Staff Panel
- Send announcements, events and alerts.
- Lock a channel or turn on slow mode.
- Clear chat for every player at once.
- Timed or permanent mutes with a reason. Mutes are saved across restarts.
- Admins can change moderation settings live, without a restart.

## Requirements
- FXServer with OneSync. Without OneSync, the Local channel reaches every player instead of just nearby ones.
- Optional: ESX Legacy, QBCore or Qbox, for character names and job tags.

## Installation
1. Stop or remove the default `chat` resource.
2. Put `fearx_chat` in your `resources` folder.
3. Add the following to `server.cfg`:

```cfg
ensure fearx_chat

set fearx_chat_discord_token "YOUR_BOT_TOKEN"

add_ace group.admin fearx.chat.staff allow
add_ace group.admin fearx.chat.admin allow
add_ace group.admin fearx.chat.level.owner allow
```

The Discord token is optional. Without it the chat works normally but doesn't show Discord avatars.

## Permissions
| ACE | Grants |
| --- | --- |
| `fearx.chat.staff` | Staff channel, staff panel, mutes, filter bypass, staff level 20 |
| `fearx.chat.admin` | Change moderation settings live |
| `fearx.chat.level.owner` | Staff level 50, which unlocks the Owner tag |
| `fearx.chat.pack.<id>` | Every item in a cosmetic pack |
| `fearx.chat.tag.<id>` | A single name tag |
| `fearx.chat.decoration.<id>` | A single avatar decoration |

Example, granting the Neon pack to a Tebex package group:

```cfg
add_ace group.neon fearx.chat.pack.neon allow
```

## Configuration
| File | Purpose |
| --- | --- |
| `config.lua` | Channels, commands, keybinds, UI, Discord, job tags, cosmetics |
| `config_moderation.lua` | Slur filter, link rules, spam limits, auto-mute |
| `locales/en.lua` | Every player-facing string |

The config is checked when the resource starts, and any problems are printed to the server console.

## Exports

### Server
```lua
exports.fearx_chat:sendMessage(target, {
  kind = 'system',
  channel = 'ooc',
  text = 'Hello',
  label = 'Optional label',
  author = { name = 'Server' }
})

exports.fearx_chat:broadcast('announce', 'Title', 'Message text', 'Optional label')

local muted = exports.fearx_chat:isMuted(source)

exports.fearx_chat:registerMessageHook(function(source, outMessage, hookRef)
  if outMessage.args[2]:find('badword') then hookRef.cancel() end
end)
```

Message hooks run on messages sent in the legacy channel (`Config.Chat.legacyChannel`). The `hookRef` argument supports `cancel`, `updateMessage`, `setRouting` and `setSeObject`.

`broadcast` accepts `announce`, `event` or `alert` as its first argument.

### Default chat compatibility
These all work exactly as they do with the default `chat` resource:

- `exports.chat:addMessage`
- `exports.chat:addSuggestion`
- `chat:addMessage`
- `chat:addSuggestion` and `chat:addSuggestions`
- `chat:removeSuggestion`
- `chat:clear`
- `chatMessage`

## License
All rights reserved. Redistribution or resale is not permitted.
