# Installation Guide

### Requirements

* **FiveM server** with `lua54 'yes'` support (any recent build).
* **OneSync** enabled. Without it the Local channel reaches every player instead of nearby players.
* **Optional framework:** ESX Legacy, QBCore or QBox. Detected automatically. Without one, the chat still works but uses player names instead of character names and shows no job tags.

### Steps

#### 1. Remove the default chat

Stop or delete the default `chat` resource. FearX-Chat provides `chat`, so running both will conflict.

If you use the cfx default resources, remove `ensure chat` from `server.cfg`.

#### 2. Drop the resource

Place the `fearx_chat` folder into `resources/` (or a subfolder like `resources/[fearx]/`).

#### 3. Database: none

Nothing to import. Player profiles, mutes and moderation settings are stored with resource KVP and survive restarts.

#### 4. Configure the resource

Open **`config.lua`** and review the basics:

| Key                          | Default         | What it controls                                     |
| ---------------------------- | --------------- | ---------------------------------------------------- |
| `Config.Locale`              | `'en'`          | Locale file to use                                   |
| `Config.Chat.maxLength`      | `256`           | Max characters per message                           |
| `Config.Chat.minGapMs`       | `750`           | Minimum time between messages per player             |
| `Config.Chat.legacyChannel`  | `'local'`       | Channel used by default chat messages and `/say`     |
| `Config.Chat.nameSource`     | `'character'`   | `'character'` for framework names, anything else for player names |
| `Config.Keys.open`           | `'T'`           | Key to open chat                                     |
| `Config.Keys.command`        | `'SLASH'`       | Key to open chat with `/` typed                      |
| `Config.Channels`            | 5 channels      | Channel list                                         |

Then open **`config_moderation.lua`** for the filter:

| Key                               | Default | What it controls                         |
| --------------------------------- | ------- | ---------------------------------------- |
| `Config.Moderation.enabled`       | `true`  | Master switch                            |
| `Config.Moderation.slurs.enabled` | `true`  | Slur filter                              |
| `Config.Moderation.links.*`       | see file | IP loggers, invites, IPs, link allow-list |
| `Config.Moderation.spam.*`        | see file | Burst and duplicate limits              |
| `Config.Moderation.autoMute.*`    | 3 strikes / 10 min / 15 min mute | Auto-mute |

Full reference: see **Configurable**.

#### 5. Add to `server.cfg`

```
ensure es_extended            # or qb-core, or qbx_core (optional)
ensure fearx_chat

set fearx_chat_discord_token "YOUR_BOT_TOKEN"

add_ace group.admin fearx.chat.staff allow
add_ace group.admin fearx.chat.admin allow
add_ace group.admin fearx.chat.level.owner allow
```

The Discord token is optional. It only powers Discord avatars. Create a bot at the [Discord Developer Portal](https://discord.com/developers/applications), copy its token, and paste it here. The bot does not need to be in your server.

#### 6. Restart

Restart the server, or `refresh; ensure fearx_chat` from the console.

### Verifying it works

1. Join your server.
2. Press `T`. The FearX chat opens with the channel tabs along the top.
3. Type a message in Local. Players within 25m see it.
4. Type `/me waves`. It shows as an action message.
5. Run `/chatsettings`. Pick a chat style, a name tag and a decoration.
6. As staff, open the staff panel from the chat and send a test announcement.
7. Send a message containing `grabify.link`. It is blocked and staff get a notice.

If any step fails see **Common Issues & Solutions**.

***

*Need help? Open a ticket in `discord.gg/fearxscripts`.*
