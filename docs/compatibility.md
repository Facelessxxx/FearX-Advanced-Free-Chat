# Compatibility

## Compatibility

### Frameworks

| Framework      | Support | Notes                                                  |
| -------------- | ------- | ------------------------------------------------------ |
| **ESX Legacy** | ✅       | Modern `exports.es_extended:getSharedObject()` only    |
| **QBCore**     | ✅       | `exports['qb-core']:GetCoreObject()`                   |
| **QBox**       | ✅       | `exports.qbx_core:GetPlayer(source)`                   |
| Standalone     | ✅       | Player names, no job tags                              |
| vRP            | ⚠️       | Works standalone. Add vRP to `bridge/server.lua` for character names |

### Default chat

Anything written for the default `chat` resource works without changes.

| API                                      | Status |
| ---------------------------------------- | ------ |
| `chat:addMessage`                        | ✅      |
| `chatMessage` (client and server)        | ✅      |
| `chat:addSuggestion` / `chat:addSuggestions` | ✅  |
| `chat:removeSuggestion`                  | ✅      |
| `chat:clear`                             | ✅      |
| `chat:addTemplate`                       | ✅      |
| `exports.chat:addMessage`                | ✅      |
| `exports.chat:addSuggestion`             | ✅      |
| `exports.chat:registerMessageHook`       | ✅      |
| `exports.chat:registerMode`              | ⚠️ no-op, returns `false` |

Resources that register commands with `RegisterCommand` show up in autocomplete automatically.

### OneSync

| Mode               | Status                                       |
| ------------------ | -------------------------------------------- |
| OneSync Infinity   | ✅                                            |
| OneSync Legacy     | ✅                                            |
| OneSync off        | ⚠️ Local channel becomes server-wide          |

### FiveM build

| Build              | Status                                      |
| ------------------ | ------------------------------------------- |
| Latest production  | ✅                                           |
| Latest recommended | ✅                                           |
| Old (no `lua54`)   | ❌ `fxmanifest.lua` declares `lua54 'yes'`   |

### Multi-character servers

Cosmetics and mutes are keyed on the player's `license`, so they follow the player across characters.
### Other FearX scripts

Fully self-contained. No `fearx_bridge` dependency. The only state it owns is the `fearx_chat:*` event namespace and its resource KVP.

### Performance

* No database queries, everything is in memory with KVP for persistence
* No `Wait(0)` loops
* Discord avatars are cached for `Config.Discord.cacheMinutes`
* Command suggestions are batched instead of sent one by one
