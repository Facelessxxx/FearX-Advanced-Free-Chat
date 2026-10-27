# Common Issues & Solutions

This will show all known issues that some people have faced and how to fix them these are not bugs but just problem some people may face

## Common Issues & Solutions

### Startup

#### Two chats showing, or chat not opening

The default `chat` resource is still running. Remove `ensure chat` from `server.cfg`, or delete the `chat` folder from `resources/[cfx-default]`, then restart.

#### `[fearx_chat] config: ...` in red on start

The config check found a problem. The message says which key is wrong. Most common:

* `Config.Chat.legacyChannel` points at a channel id that doesn't exist in `Config.Channels`
* A command's `channel` points at a channel id that doesn't exist
* `Config.Locale` has no matching file in `locales/`

#### `OneSync is off, proximity channels reach every player`

Turn on OneSync in txAdmin settings or add `set onesync on` to `server.cfg`.

### Names and tags

#### Players show their FiveM name instead of character name

1. `Config.Chat.nameSource` must be `'character'`
2. Your framework must be started **before** `fearx_chat`
3. The player must have a character loaded. On multicharacter servers the name appears once they pick a character

#### LSPD / EMS tag not showing

1. The key in `Config.JobTags` must match the framework job name exactly (`police`, `ambulance`)
2. With `requireDuty = true` the player must be on duty
3. For ESX, your job script must set `job.onDuty`. If it doesn't, set `requireDuty = false`

#### Bought cosmetics aren't unlocked

Check the ACE with:

```
test_ace player.<id> fearx.chat.pack.neon
```

If it says denied, your Tebex command didn't add the player to the group. If it says allowed, have the player rejoin.

### Discord avatars

#### Avatars not showing

1. `set fearx_chat_discord_token` is in `server.cfg` (the console warns you if it isn't)
2. The token is a **bot** token, not a user token or client secret
3. `Config.Discord.avatars = true`
4. The player has Discord running and linked when they join FiveM

### Moderation

#### A normal word is being blocked

Add it to `Config.Moderation.slurs.allowWords` in `config_moderation.lua`.

#### Players can't post YouTube / clip links

Discord invites, IP addresses and IP loggers are always checked. For everything else, add the domain to `links.allowedDomains`. If `links.blockAllLinks = true`, only `allowedDomains` work.

#### Changes to `config_moderation.lua` aren't applying

Settings changed live in the staff panel override the file and are saved. Change them in the staff panel instead.

#### Player is stuck muted

Mutes are saved across restarts. Unmute with:

```
/chatunmute <id>
```

or from the staff panel.

### Staff panel

#### Staff panel / Staff channel not showing

The player needs `fearx.chat.staff`:

```cfg
add_ace group.admin fearx.chat.staff allow
add_principal identifier.license:xxxxxxxx group.admin
```

Moderation settings in the panel also need `fearx.chat.admin`.

#### "You cannot mute a staff member"

By design. Staff can't mute other staff.

### Other scripts

#### A script's messages don't show

Messages sent with `chat:addMessage` or `exports.chat:addMessage` always show. If the script sends to a channel id that doesn't exist, it falls back to `Config.Chat.legacyChannel`.

#### A script's command isn't in autocomplete

Suggestions refresh shortly after a resource starts. If the script adds them with `chat:addSuggestion` before the player joins, they still appear. Restart the script once to resend.

***

*Need help? Open a ticket in `discord.gg/fearxscripts`.*
