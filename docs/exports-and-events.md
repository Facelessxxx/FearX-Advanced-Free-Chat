# Exports And Events

A reference of all exports and events used by FearX-Chat for developers looking to integrate or extend functionality.

## Exports And Events

Public API for other resources. Because FearX-Chat provides `chat`, the default chat exports also work under `exports.chat`.

***

### Exports (server-side)

#### `sendMessage(target, message)`

Sends a styled message to one player, or everyone with `-1`. Returns `true` on success.

```lua
exports.fearx_chat:sendMessage(source, {
    kind = 'system',
    channel = 'ooc',
    text = 'Welcome to the server',
    label = 'Info',
    author = { name = 'Server' }
})
```

| Field     | Purpose                                                                 |
| --------- | ----------------------------------------------------------------------- |
| `kind`    | `chat`, `me`, `do`, `ooc`, `whisper`, `ad`, `staff`, `event`, `alert`, `system`, `announce`, `error` |
| `channel` | Channel id. Falls back to `Config.Chat.legacyChannel`                   |
| `text`    | Message text (required)                                                 |
| `label`   | Small label next to the message                                         |
| `author`  | `{ name = '...' }`                                                      |

#### `broadcast(kind, title, text, label)`

Posts to the Announcements channel for everyone.

```lua
exports.fearx_chat:broadcast('event', 'Redzone', 'Redzone opens in 5 minutes', 'Event')
```

`kind` is `announce`, `event` or `alert`.

#### `isMuted(source)`

Returns `true` if the player is muted.

```lua
if exports.fearx_chat:isMuted(source) then
    return
end
```

#### `registerMessageHook(fn)`

Runs on every message sent in `Config.Chat.legacyChannel`. Same as the default chat.

```lua
exports.chat:registerMessageHook(function(source, outMessage, hookRef)
    if outMessage.args[2]:find('badword') then
        hookRef.cancel()
    end
end)
```

| `hookRef`        | Effect                                        |
| ---------------- | --------------------------------------------- |
| `cancel()`       | Stop the message                              |
| `updateMessage(t)` | Change fields on the message                |
| `setRouting(t)`  | Send only to a player id or list of ids       |
| `setSeObject(o)` | Send only to players with this ACE            |

#### `addMessage(target, message)`

Default chat export. Same as `TriggerClientEvent('chat:addMessage', target, message)`.

***

### Exports (client-side)

#### `addMessage(message)`

```lua
exports.chat:addMessage({ args = { 'System', 'Hello' } })
```

#### `addSuggestion(name, help, params)`

```lua
exports.chat:addSuggestion('/report', 'Report a player', {
    { name = 'id', help = 'Server ID' },
    { name = 'reason' }
})
```

***

### Default chat events

| Event                    | Side   | Payload                    |
| ------------------------ | ------ | -------------------------- |
| `chat:addMessage`        | client | `(message)`                |
| `chatMessage`            | client | `(author, color, text)`    |
| `chat:addSuggestion`     | client | `(name, help, params)`     |
| `chat:addSuggestions`    | client | `(list)`                   |
| `chat:removeSuggestion`  | client | `(name)`                   |
| `chat:addTemplate`       | client | `(id, html)`               |
| `chat:clear`             | client | none                       |
| `chatMessage`            | server | `(source, name, text)`, cancel with `CancelEvent()` |

***

### Internal events

Used by the chat itself. **Don't trigger these from other resources.** The server validates source, permissions, cooldowns and the filter.

| Event                         | Direction       | Purpose                     |
| ----------------------------- | --------------- | --------------------------- |
| `fearx_chat:send`             | client → server | Send a message to a channel |
| `fearx_chat:setProfile`       | client → server | Save tags and decoration    |
| `fearx_chat:staffAction`      | client → server | Staff panel action          |
| `fearx_chat:ready`            | client → server | NUI loaded                  |
| `fearx_chat:init`             | server → client | Channels, profile, settings |
| `fearx_chat:message`          | server → client | Deliver a message           |
| `fearx_chat:channelControls`  | server → client | Lock / slow mode changes    |
| `fearx_chat:moderation`       | server → client | Live moderation settings    |
