Chat = {}

local REQUEST_GAP_MS = 250
local MAX_BROADCAST_TITLE = 40
local SUGGESTION_REFRESH_MS = 500
local SUGGESTION_BATCH = 16
local KINDS = {
  chat = true,
  me = true,
  ['do'] = true,
  ooc = true,
  whisper = true,
  ad = true,
  staff = true,
  event = true,
  alert = true,
  system = true,
  announce = true,
  error = true
}

local channelsById = {}
local lastMessage = {}
local lastByChannel = {}
local pendingReady = {}
local pendingProfile = {}
local messageHooks = {}
local oneSync = GetConvar('onesync', 'off') ~= 'off'

for _, channel in ipairs(Config.Channels) do channelsById[channel.id] = channel end

local function now()
  return GetGameTimer()
end

local function exists(src)
  return type(src) == 'number' and src > 0 and GetPlayerName(src) ~= nil
end

local function playerIds()
  local ids = {}
  for _, id in ipairs(GetPlayers()) do ids[#ids + 1] = tonumber(id) end
  return ids
end

local function cleanText(value)
  if type(value) ~= 'string' then return nil end
  value = TruncateText((value:gsub('%c', ' ')), Config.Chat.maxLength)
  if not value then return nil end
  value = value:gsub('\xE2\x80[\x8B-\x8F\xAA-\xAE]', ''):gsub('\xE2\x81[\xA0-\xA4\xA6-\xA9]', ''):gsub('\xEF\xBB\xBF', '')
  value = value:gsub('^%s+', ''):gsub('%s+$', '')
  if value == '' then return nil end
  return value
end

function Chat.channel(id)
  return type(id) == 'string' and channelsById[id] or nil
end

local function deliver(target, message)
  TriggerClientEvent('fearx_chat:message', target, message)
end

function Chat.system(target, text, kind)
  deliver(target, {
    kind = kind or 'system',
    channel = Config.Chat.legacyChannel,
    text = text
  })
end

function Chat.error(target, text)
  Chat.system(target, text, 'error')
end

local function staffIds()
  local ids = {}
  for _, id in ipairs(playerIds()) do
    if Profiles.isStaff(id) then ids[#ids + 1] = id end
  end
  return ids
end

function Chat.staffNotice(text)
  local channel = Chat.channel('staff') and 'staff' or Config.Chat.legacyChannel
  for _, id in ipairs(staffIds()) do
    deliver(id, {
      kind = 'system',
      channel = channel,
      text = text
    })
  end
end

function Chat.broadcast(kind, title, text, label)
  deliver(-1, {
    kind = KINDS[kind] and kind or 'announce',
    channel = Chat.channel('announcements') and 'announcements' or Config.Chat.legacyChannel,
    text = text,
    label = label,
    author = {
      name = title ~= '' and title or 'Server'
    }
  })
end

local function nearby(src, range)
  if not oneSync then return playerIds() end
  local sender = GetPlayerPed(src)
  if sender == 0 then return { src } end
  local origin = GetEntityCoords(sender)
  local bucket = GetPlayerRoutingBucket(src)
  local ids = {}
  for _, id in ipairs(playerIds()) do
    local ped = GetPlayerPed(id)
    if ped ~= 0 and GetPlayerRoutingBucket(id) == bucket and #(GetEntityCoords(ped) - origin) <= range then
      ids[#ids + 1] = id
    end
  end
  return ids
end

local function recipients(src, channel)
  if channel.staffOnly then return staffIds() end
  if channel.range then return nearby(src, channel.range) end
  return { -1 }
end

local function blockReason(src, channel, staff)
  local t = now()
  if lastMessage[src] and t - lastMessage[src] < Config.Chat.minGapMs then return L('tooFast') end
  if channel.readOnly then return L('readOnly', channel.label) end
  if channel.staffOnly and not staff then return L('staffOnly', channel.label) end
  if staff then return nil end
  local mute = Staff.muteOf(src)
  if mute and mute.expires > 0 then
    return L('mutedUntil', math.max(1, math.ceil((mute.expires - os.time()) / 60)), mute.reason)
  end
  if mute then return L('muted', mute.reason) end
  local control = Staff.control(channel.id)
  if control.locked then return L('locked', channel.label) end
  local sent = lastByChannel[src] and lastByChannel[src][channel.id]
  local wait = sent and math.ceil((sent + control.slowmode * 1000 - t) / 1000) or 0
  if wait > 0 then return L('slowmode', wait) end
  local cooldown = channel.cooldownSeconds or 0
  wait = sent and math.ceil((sent + cooldown * 1000 - t) / 1000) or 0
  if wait > 0 then return L('adCooldown', wait) end
  return nil
end

local function markSent(src, channelId)
  local t = now()
  lastMessage[src] = t
  lastByChannel[src] = lastByChannel[src] or {}
  lastByChannel[src][channelId] = t
end

local function aceTargets(object)
  local ids = {}
  if type(object) ~= 'string' then return ids end
  for _, id in ipairs(playerIds()) do
    if IsPlayerAceAllowed(id, object) then ids[#ids + 1] = id end
  end
  return ids
end

local function runLegacyHooks(src, author, text)
  local outMessage = {
    color = { 255, 255, 255 },
    multiline = true,
    args = { author.name, text }
  }
  local cancelled, routing = false, nil
  local hookRef = {
    updateMessage = function(changes)
      if type(changes) ~= 'table' then return end
      for key, value in pairs(changes) do outMessage[key] = value end
    end,
    cancel = function() cancelled = true end,
    setSeObject = function(object) routing = aceTargets(object) end,
    setRouting = function(target) routing = target end
  }
  for _, hook in ipairs(messageHooks) do
    local ok, problem = pcall(hook.fn, src, outMessage, hookRef)
    if not ok then print(('^1[fearx_chat] message hook from %s failed: %s^0'):format(hook.resource, tostring(problem))) end
  end
  if cancelled then return nil end
  local args = type(outMessage.args) == 'table' and outMessage.args or {}
  text = cleanText(tostring(args[#args] or ''))
  if not text then return nil end
  TriggerEvent('chatMessage', src, author.name, text)
  if WasEventCanceled() then return nil end
  if type(routing) == 'number' then routing = { routing } end
  return text, type(routing) == 'table' and routing or nil
end

function Chat.say(src, channelId, rawText, options)
  options = options or {}
  local channel = Chat.channel(channelId)
  local text = cleanText(rawText)
  if not channel or not text then return false end
  local staff = Profiles.isStaff(src)
  local reason = blockReason(src, channel, staff)
  if reason then
    Chat.error(src, reason)
    return false
  end
  local allowed, filterReason = Moderation.check(src, text, staff)
  if not allowed then
    Chat.error(src, filterReason)
    return false
  end
  markSent(src, channel.id)
  local author = Profiles.author(src)
  local routing
  if not options.kind and channel.id == Config.Chat.legacyChannel then
    text, routing = runLegacyHooks(src, author, text)
    if not text then return true end
  end
  local message = {
    kind = options.kind or channel.kind or 'chat',
    channel = channel.id,
    text = text,
    author = author,
    label = options.label
  }
  local targets = options.targets or routing or recipients(src, channel)
  for _, target in ipairs(targets) do deliver(target, message) end
  if options.echo then
    message.label = options.echoLabel
    deliver(src, message)
  end
  return true
end

RegisterNetEvent('fearx_chat:send', function(channelId, text)
  local src = source
  if type(channelId) ~= 'string' or type(text) ~= 'string' then return end
  Chat.say(src, channelId, text)
end)

RegisterNetEvent('_chat:messageEntered', function(_, _, text)
  Chat.say(source, Config.Chat.legacyChannel, text)
end)

AddEventHandler('__cfx_internal:commandFallback', function(command)
  local src = source
  CancelEvent()
  if not exists(src) or type(command) ~= 'string' or command:find('^[%+%-]') then return end
  local name = GetPlayerName(src)
  TriggerEvent('chatMessage', src, name, '/' .. command)
  if WasEventCanceled() then return end
  Chat.error(src, L('unknownCommand', TruncateText(command:match('^(%S+)') or command, 32) or '?'))
end)

local function commandText(args, rawCommand)
  return rawCommand:match('^%S+%s+(.+)$') or table.concat(args, ' ')
end

RegisterCommand('say', function(src, _, rawCommand)
  local text = cleanText(rawCommand:match('^%S+%s+(.+)$'))
  if not text then return end
  if src ~= 0 then
    Chat.say(src, Config.Chat.legacyChannel, text)
    return
  end
  deliver(-1, {
    kind = 'chat',
    channel = Config.Chat.legacyChannel,
    text = text,
    author = {
      name = 'Console'
    }
  })
end, false)

local function registerTextCommand(key, kind)
  local command = Config.Commands[key]
  if not command or not command.enabled then return end
  RegisterCommand(command.name, function(src, args, rawCommand)
    if src == 0 then return end
    local text = cleanText(commandText(args, rawCommand))
    if not text then
      Chat.error(src, L('usageText', command.name))
      return
    end
    Chat.say(src, command.channel, text, {
      kind = kind
    })
  end, false)
end

registerTextCommand('me', 'me')
registerTextCommand('do', 'do')
registerTextCommand('ooc', 'ooc')
registerTextCommand('ad', 'ad')

if Config.Commands.whisper and Config.Commands.whisper.enabled then
  local command = Config.Commands.whisper
  RegisterCommand(command.name, function(src, args, rawCommand)
    if src == 0 then return end
    local target = tonumber(args[1])
    local text = cleanText(rawCommand:match('^%S+%s+%S+%s+(.+)$'))
    if not target or not text then
      Chat.error(src, L('usageWhisper', command.name))
      return
    end
    target = math.tointeger(target)
    if not exists(target) or target == src then
      Chat.error(src, L('playerNotFound', tostring(args[1])))
      return
    end
    Chat.say(src, command.channel, text, {
      kind = 'whisper',
      targets = { target },
      echo = true,
      echoLabel = TruncateText(L('whisperTo', GetPlayerName(target)), 24)
    })
  end, false)
end

local function commandHelp()
  local help = {}
  local function add(key, entry)
    local command = Config.Commands[key]
    if command and command.enabled then help[command.name] = entry end
  end
  add('me', { help = L('help.me'), params = { { name = 'action', help = L('help.meParam') } } })
  add('do', { help = L('help.do'), params = { { name = 'description', help = L('help.doParam') } } })
  add('ooc', { help = L('help.ooc'), params = { { name = 'message' } } })
  add('whisper', { help = L('help.whisper'), params = { { name = 'id', help = L('help.whisperId') }, { name = 'message' } } })
  add('ad', { help = L('help.ad'), params = { { name = 'text' } } })
  return help
end

local HELP = commandHelp()

local function resourceCommands()
  local list = {}
  for _, command in ipairs(GetRegisteredCommands()) do
    if IsResourceCommand(command) then list[#list + 1] = command.name end
  end
  return list
end

local function serverSuggestions(src, commands)
  local list = {}
  for _, name in ipairs(commands or resourceCommands()) do
    if IsPlayerAceAllowed(src, 'command.' .. name) then
      local help = HELP[name] or {}
      list[#list + 1] = {
        name = name,
        help = help.help,
        params = help.params
      }
    end
  end
  return list
end

local function channelsFor(staff)
  local list = {}
  for _, channel in ipairs(Config.Channels) do
    if staff or not channel.staffOnly then
      list[#list + 1] = {
        id = channel.id,
        label = channel.label,
        color = channel.color,
        icon = channel.icon,
        readOnly = channel.readOnly == true
      }
    end
  end
  return list
end

local function sendInit(src)
  local profile = Profiles.snapshot(src)
  TriggerClientEvent('fearx_chat:init', src, {
    channels = channelsFor(profile.staff),
    controls = Staff.controls(),
    cosmetics = Profiles.cosmetics(),
    profile = profile,
    moderation = profile.admin and Moderation.settings() or nil,
    suggestions = serverSuggestions(src)
  })
end

RegisterNetEvent('fearx_chat:ready', function()
  local src = source
  if pendingReady[src] then return end
  pendingReady[src] = true
  SetTimeout(REQUEST_GAP_MS, function()
    pendingReady[src] = nil
    if not exists(src) then return end
    Profiles.refresh(src)
    sendInit(src)
  end)
end)

local function applyProfile(src)
  local data = pendingProfile[src]
  pendingProfile[src] = nil
  if not exists(src) or type(data) ~= 'table' then return end
  Profiles.update(src, data)
  TriggerClientEvent('fearx_chat:profile', src, Profiles.snapshot(src))
end

RegisterNetEvent('fearx_chat:setProfile', function(data)
  local src = source
  if type(data) ~= 'table' then return end
  local scheduled = pendingProfile[src] ~= nil
  pendingProfile[src] = data
  if not scheduled then SetTimeout(REQUEST_GAP_MS, function() applyProfile(src) end) end
end)

local refreshPending = false

local function refreshSuggestions()
  if refreshPending then return end
  refreshPending = true
  SetTimeout(SUGGESTION_REFRESH_MS, function()
    refreshPending = false
    local commands = resourceCommands()
    for index, id in ipairs(playerIds()) do
      if exists(id) then TriggerClientEvent('fearx_chat:serverSuggestions', id, serverSuggestions(id, commands)) end
      if index % SUGGESTION_BATCH == 0 then Wait(0) end
    end
  end)
end

AddEventHandler('onServerResourceStart', refreshSuggestions)

AddEventHandler('onServerResourceStop', function(resource)
  for index = #messageHooks, 1, -1 do
    if messageHooks[index].resource == resource then table.remove(messageHooks, index) end
  end
  refreshSuggestions()
end)

AddEventHandler('playerDropped', function()
  local src = source
  lastMessage[src] = nil
  lastByChannel[src] = nil
  pendingReady[src] = nil
  pendingProfile[src] = nil
end)

local function provideExport(name, fn)
  exports(name, fn)
  AddEventHandler(('__cfx_export_chat_%s'):format(name), function(setCallback)
    setCallback(fn)
  end)
end

provideExport('addMessage', function(target, message)
  if message == nil then target, message = -1, target end
  if target == nil or message == nil then return end
  TriggerClientEvent('chat:addMessage', target, message)
end)

provideExport('registerMessageHook', function(hook)
  if type(hook) ~= 'function' and type(hook) ~= 'table' then return end
  messageHooks[#messageHooks + 1] = {
    fn = hook,
    resource = GetInvokingResource() or 'unknown'
  }
end)

provideExport('registerMode', function()
  return false
end)

exports('sendMessage', function(target, message)
  if type(message) ~= 'table' or type(message.text) ~= 'string' then return false end
  deliver(target, {
    kind = KINDS[message.kind] and message.kind or 'system',
    channel = Chat.channel(message.channel) and message.channel or Config.Chat.legacyChannel,
    text = message.text,
    label = message.label,
    author = message.author
  })
  return true
end)

exports('broadcast', function(kind, title, text, label)
  if type(text) ~= 'string' then return false end
  Chat.broadcast(kind, type(title) == 'string' and TruncateText(title, MAX_BROADCAST_TITLE) or '', text, label)
  return true
end)

exports('isMuted', function(src)
  return Staff.muteOf(tonumber(src)) ~= nil
end)

local function validateConfig()
  local problems = {}
  local function need(ok, message) if not ok then problems[#problems + 1] = message end end
  need(Locales[Config.Locale] ~= nil, ('Config.Locale %s has no locales file, using English'):format(tostring(Config.Locale)))
  need(Chat.channel(Config.Chat.legacyChannel) ~= nil, 'Config.Chat.legacyChannel must be the id of a channel in Config.Channels')
  need(type(Config.Chat.maxLength) == 'number' and Config.Chat.maxLength >= 1 and Config.Chat.maxLength <= 1000, 'Config.Chat.maxLength must be between 1 and 1000')
  for key, command in pairs(Config.Commands) do
    if command.enabled and command.channel then
      need(Chat.channel(command.channel) ~= nil, ('Config.Commands.%s.channel must be the id of a channel in Config.Channels'):format(key))
    end
  end
  for _, problem in ipairs(problems) do
    print(('^1[fearx_chat] config: %s^0'):format(problem))
  end
end

CreateThread(function()
  validateConfig()
  if not oneSync then print('^3[fearx_chat] OneSync is off, proximity channels reach every player^0') end
  if GetConvar('fearx_chat_discord_token', '') == '' and Config.Discord.avatars then
    print('^3[fearx_chat] set fearx_chat_discord_token in server.cfg to show Discord avatars^0')
  end
end)
