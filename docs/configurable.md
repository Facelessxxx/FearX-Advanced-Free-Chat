# Configurable

## Configurable

Three editable files plus the framework bridge. All of them are listed in `escrow_ignore`.

```
fearx_chat/
├── config.lua              ← channels, commands, keys, UI, Discord, job tags, cosmetics
├── config_moderation.lua   ← slur filter, links, spam, auto-mute
├── locales/en.lua          ← every player-facing string
└── bridge/server.lua       ← character names + jobs per framework
```

The config is checked on start. Problems are printed to the server console in red.

***

### `config.lua`

#### Chat

| Key                         | Default       | Purpose                                                       |
| --------------------------- | ------------- | ------------------------------------------------------------- |
| `Config.Locale`             | `'en'`        | Locale file name in `locales/`                                |
| `Config.Debug`              | `false`       | Extra console output                                          |
| `Config.Chat.maxLength`     | `256`         | Max characters per message (1 to 1000)                        |
| `Config.Chat.minGapMs`      | `750`         | Minimum gap between messages per player                       |
| `Config.Chat.legacyChannel` | `'local'`     | Channel for default chat messages, `/say` and message hooks   |
| `Config.Chat.nameSource`    | `'character'` | `'character'` uses framework names, anything else uses player names |

#### Channels

```lua
Config.Channels = {
  { id = 'local', label = 'Local', color = '#ffffff', kind = 'chat', range = 25.0 },
  { id = 'ooc', label = 'OOC', color = '#9e9e9e', kind = 'ooc' },
  { id = 'advertise', label = 'Advertise', color = '#a3e635', kind = 'ad', cooldownSeconds = 60 },
  { id = 'staff', label = 'Staff', color = '#c77dff', kind = 'staff', staffOnly = true },
  { id = 'announcements', label = 'Announcements', color = '#ffb020', readOnly = true }
}
```

| Field             | Type      | Purpose                                                    |
| ----------------- | --------- | ---------------------------------------------------------- |
| `id`              | `string`  | Unique channel id, used by commands and exports            |
| `label`           | `string`  | Tab name                                                   |
| `color`           | `string`  | Tab and message accent colour                              |
| `kind`            | `string`  | Message style: `chat`, `ooc`, `ad`, `staff`                |
| `range`           | `number`  | Proximity range in metres. Omit for server-wide            |
| `cooldownSeconds` | `number`  | Per-player cooldown for this channel                       |
| `staffOnly`       | `boolean` | Only staff can see and post                                |
| `readOnly`        | `boolean` | Nobody can post. Used for broadcasts                       |

#### Commands

| Key        | Default name    | Channel     |
| ---------- | --------------- | ----------- |
| `me`       | `me`            | `local`     |
| `do`       | `do`            | `local`     |
| `ooc`      | `ooc`           | `ooc`       |
| `whisper`  | `w`             | `local`     |
| `ad`       | `ad`            | `advertise` |
| `clear`    | `clear`         | none        |
| `settings` | `chatsettings`  | none        |

Each command has `enabled`, `name` and (where it posts) `channel`. Set `enabled = false` to remove it.

#### Permissions

| Key                                   | Default                    |
| ------------------------------------- | -------------------------- |
| `Config.Permissions.staff`            | `fearx.chat.staff`         |
| `Config.Permissions.admin`            | `fearx.chat.admin`         |
| `Config.Permissions.packPrefix`       | `fearx.chat.pack.`         |
| `Config.Permissions.tagPrefix`        | `fearx.chat.tag.`          |
| `Config.Permissions.decorationPrefix` | `fearx.chat.decoration.`   |

`Config.Levels` maps ACE permissions to a level number. Tags with `minLevel` need that level. Defaults: `fearx.chat.level.owner` = 50, `fearx.chat.staff` = 20.

#### Keys

| Key                  | Default   | Purpose                      |
| -------------------- | --------- | ---------------------------- |
| `Config.Keys.open`   | `'T'`     | Open chat                    |
| `Config.Keys.command`| `'SLASH'` | Open chat with `/` typed     |

Players can rebind both in GTA Settings → Key Bindings → FiveM.

#### UI

| Key                       | Default   | Purpose                                     |
| ------------------------- | --------- | ------------------------------------------- |
| `Config.Ui.logo`          | `'FX'`    | Text logo                                   |
| `Config.Ui.logoImage`     | `''`      | Image URL. Replaces the text logo when set  |
| `Config.Ui.styles`        | `{}`      | Style overrides                             |
| `Config.Ui.locked`        | `{}`      | Settings players cannot change              |
| `Config.Ui.defaults.style`| `'cards'` | Default chat style: `cards`, `bubbles`, `minimal`, `compact`, `feed` |

#### Discord

| Key                         | Default | Purpose                                   |
| --------------------------- | ------- | ----------------------------------------- |
| `Config.Discord.avatars`    | `true`  | Show Discord avatars                      |
| `Config.Discord.cacheMinutes` | `60`  | How long avatars are cached               |

Needs `set fearx_chat_discord_token` in `server.cfg`.

#### Job Tags

```lua
Config.JobTags = {
  police = { label = 'LSPD', color = '#7cb8ff', background = 'rgba(91, 167, 255, 0.14)', requireDuty = true },
  ambulance = { label = 'EMS', color = '#ff6b6b', background = 'rgba(255, 107, 107, 0.14)', requireDuty = true }
}
```

The key is the framework job name. `requireDuty = true` hides the tag while off duty.

#### Cosmetics

| Key                          | Purpose                                              |
| ---------------------------- | ---------------------------------------------------- |
| `Config.Cosmetics.maxTags`   | Max tags a player can wear at once (default `3`)     |
| `Config.Cosmetics.packs`     | Pack list: `id`, `label`, `color`, optional `permission` |
| `Config.Cosmetics.tags`      | Tag list: `id`, `pack`, optional `minLevel`, `tag`   |
| `Config.Cosmetics.decorations` | Decoration list: `id`, `label`, `pack`, `image`    |

**Tag fields**

| Field        | Purpose                                                   |
| ------------ | --------------------------------------------------------- |
| `label`      | Text shown on the tag                                     |
| `color`      | Text colour                                               |
| `background` | Background colour                                         |
| `gradient`   | CSS gradient for the text                                 |
| `effect`     | `shine`, `glow`, `pulse`, `flow` or `ring`                |
| `logo`       | `true` shows the server logo on the tag                   |

The `base` pack is free for everyone. Every other pack unlocks with `fearx.chat.pack.<id>`, or the pack's own `permission` if set. Single items unlock with `fearx.chat.tag.<id>` or `fearx.chat.decoration.<id>`.

**Selling a pack on Tebex**

```cfg
add_ace group.neon fearx.chat.pack.neon allow
```

Give the buyer's identifier the `group.neon` principal from your Tebex package command.

***

### `config_moderation.lua`

#### General

| Key                                    | Default | Purpose                                     |
| -------------------------------------- | ------- | ------------------------------------------- |
| `Config.Moderation.enabled`            | `true`  | Master switch                               |
| `Config.Moderation.notifyStaff`        | `true`  | Staff get a notice when a message is blocked |
| `Config.Moderation.logToConsole`       | `true`  | Print blocked messages to the console       |
| `Config.Moderation.staffBypassLinks`   | `true`  | Staff skip link rules                       |
| `Config.Moderation.staffBypassSpam`    | `true`  | Staff skip spam rules                       |

#### Slurs

| Key                  | Purpose                                                       |
| -------------------- | ------------------------------------------------------------- |
| `slurs.enabled`      | Turn the slur filter on or off                                |
| `slurs.words`        | Blocked words                                                 |
| `slurs.allowWords`   | Words that contain a blocked word but are allowed (`snigger`, `retardant`) |

#### Links

| Key                         | Default | Purpose                                          |
| --------------------------- | ------- | ------------------------------------------------ |
| `links.blockIpLoggers`      | `true`  | Block known IP logger domains and keywords       |
| `links.blockDiscordInvites` | `true`  | Block Discord invites                            |
| `links.blockIpAddresses`    | `true`  | Block raw IP addresses                           |
| `links.blockAllLinks`       | `false` | Block every link except `allowedDomains`         |
| `links.allowedDomains`      | YouTube, Twitch, Medal, Imgur | Always allowed             |
| `links.allowedInviteCodes`  | `{}`    | Discord invite codes that are allowed            |
| `links.ipLoggerDomains`     | 40+ domains | IP logger domain list                        |
| `links.ipLoggerKeywords`    | 5 keywords | Catches new IP logger domains by name        |

#### Spam

| Key                      | Default | Purpose                                        |
| ------------------------ | ------- | ---------------------------------------------- |
| `spam.enabled`           | `true`  | Turn spam checks on or off                     |
| `spam.burstMessages`     | `5`     | Messages allowed within `burstSeconds`         |
| `spam.burstSeconds`      | `8`     | Burst window                                   |
| `spam.duplicateSeconds`  | `20`    | Same message can't be sent again within this   |

#### Auto-Mute

| Key                       | Default | Purpose                                 |
| ------------------------- | ------- | --------------------------------------- |
| `autoMute.enabled`        | `true`  | Turn auto-mute on or off                |
| `autoMute.strikes`        | `3`     | Blocked messages before a mute          |
| `autoMute.windowMinutes`  | `10`    | Window strikes are counted in           |
| `autoMute.muteMinutes`    | `15`    | Mute length                             |

Players with `fearx.chat.admin` can change moderation settings live from the staff panel. Changes are saved and override the file.

***

### `locales/en.lua`

Every message, error and command help string. Copy it to `locales/de.lua` (for example), translate it, rename the table to `Locales.de` and set `Config.Locale = 'de'`.

***

### `bridge/server.lua`

Reads character names and jobs from ESX, QBCore or QBox. Edit this if you run a custom framework. Return `nil` from `Bridge.characterName` or `Bridge.job` to fall back to defaults.
