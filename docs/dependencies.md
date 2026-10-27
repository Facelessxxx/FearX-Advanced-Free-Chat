# Dependencies

## Dependencies

### Required

None. FearX-Chat is fully self-contained. No ox\_lib, no oxmysql, no database.

### Optional framework

Auto-detected at boot in this priority order: **QBox → QBCore → ESX Legacy**.

| Framework      | Detected via  | Character name                     | Job + duty                         |
| -------------- | ------------- | ---------------------------------- | ---------------------------------- |
| **ESX Legacy** | `es_extended` | `xPlayer.getName()`                | `xPlayer.job.name`, `job.onDuty`   |
| **QBCore**     | `qb-core`     | `PlayerData.charinfo`              | `PlayerData.job.name`, `job.onduty` |
| **QBox**       | `qbx_core`    | `PlayerData.charinfo`              | `PlayerData.job.name`, `job.onduty` |
| None           | —             | FiveM player name                  | No job tags                         |

### Optional integrations

#### Discord avatars

Needs a Discord bot token:

```cfg
set fearx_chat_discord_token "YOUR_BOT_TOKEN"
```

Players must have Discord linked to FiveM. Without a token the chat works normally and shows no avatars.

#### OneSync

Needed for proximity channels. With OneSync off, the console warns you and the Local channel reaches every player.

### Conflicts

The default `chat` resource. FearX-Chat provides `chat`, so remove the default one.

### Version notes

No hard pinning. If you hit `attempt to call a nil value` errors on boot, see **Common Issues & Solutions**.
