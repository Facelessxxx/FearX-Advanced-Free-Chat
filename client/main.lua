local STAFF_TIMEOUT_MS = 10000
local QUEUE_LIMIT = 100
local SUGGESTION_DELAY_MS = 200
local REFRESH_AFTER_MS = 30000
local VISIBILITY_POLL_MS = 250
local HIDDEN_COMMANDS = {
  ['fearx_chat_open'] = true,
  ['fearx_chat_command'] = true
}

local isOpen = false
local nuiReady = false
local queue = {}
local myServerId = GetPlayerServerId(PlayerId())
local serverSuggestions = {}
local addedSuggestions = {}
local removedSuggestions = {}
local templates = {}
local suggestionsQueued = false
local staffRequests = {}
local nextRequestId = 0
local lastInitAt = 0

local function send(action, data)
  if nuiReady then
    SendNUIMessage({ action = action, data = data })
  elseif #queue < QUEUE_LIMIT then
    queue[#queue + 1] = { action = action, data = data }
  end
end

local function flushQueue()
  for _, entry in ipairs(queue) do SendNUIMessage(entry) end
  queue = {}
end

local function setOpen(open)
  isOpen = open
  SetNuiFocus(open, open)
end

local function requestInit()
  TriggerServerEvent('fearx_chat:ready')
end

local function openChat(text)
  if isOpen or not nuiReady or IsPauseMenuActive() or IsNuiFocused() then return end
  setOpen(true)
  send('open', { text = text })
  if GetGameTimer() - lastInitAt > REFRESH_AFTER_MS then requestInit() end
end

local function pushMessage(message)
  if type(message) ~= 'table' or type(message.text) ~= 'string' then return end
  message.own = type(message.author) == 'table' and message.author.serverId == myServerId or nil
  send('message', message)
end

local function clientCommands()
  local list = {}
  for _, command in ipairs(GetRegisteredCommands()) do
    local name = command.name
    if not HIDDEN_COMMANDS[name] and IsResourceCommand(command) then list[#list + 1] = name end
  end
  return list
end

local function buildSuggestions()
  local byName, order = {}, {}
  local function add(entry)
    if type(entry) ~= 'table' or type(entry.name) ~= 'string' or entry.name == '' or removedSuggestions[entry.name] then return end
    if not byName[entry.name] then order[#order + 1] = entry.name end
    local current = byName[entry.name] or {}
    byName[entry.name] = {
      name = entry.name,
      help = entry.help or current.help,
      params = entry.params or current.params
    }
  end
  for _, name in ipairs(clientCommands()) do add({ name = name }) end
  for _, entry in ipairs(serverSuggestions) do add(entry) end
  for _, entry in pairs(addedSuggestions) do add(entry) end
  table.sort(order)
  local list = {}
  for _, name in ipairs(order) do list[#list + 1] = byName[name] end
  return list
end

local function queueSuggestions()
  if suggestionsQueued then return end
  suggestionsQueued = true
  SetTimeout(SUGGESTION_DELAY_MS, function()
    suggestionsQueued = false
    send('suggestions', buildSuggestions())
  end)
end

local function hexColor(color)
  if type(color) ~= 'table' then return nil end
  local r, g, b = tonumber(color[1]), tonumber(color[2]), tonumber(color[3])
  if not r or not g or not b then return nil end
  return ('#%02x%02x%02x'):format(math.floor(r) & 255, math.floor(g) & 255, math.floor(b) & 255)
end

local function stripCodes(text)
  return (tostring(text):gsub('%^%d', ''))
end

local BLOCK_TAGS = {
  br = true,
  p = true,
  div = true,
  li = true,
  tr = true,
  h1 = true,
  h2 = true,
  h3 = true
}

local function stripHtml(text)
  text = text:gsub('<[Ss][Tt][Yy][Ll][Ee].-</[Ss][Tt][Yy][Ll][Ee]>', ''):gsub('<[Ss][Cc][Rr][Ii][Pp][Tt].-</[Ss][Cc][Rr][Ii][Pp][Tt]>', '')
  text = text:gsub('<%s*/?%s*(%w+)[^>]*>', function(name)
    return BLOCK_TAGS[name:lower()] and ' ' or ''
  end)
  text = text:gsub('&nbsp;', ' '):gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&amp;', '&')
  return (text:gsub('%s+', ' '):gsub('^ ', ''):gsub(' $', ''))
end

local function fillTemplate(template, args, params)
  return stripHtml(template:gsub('{([%w_]+)}', function(key)
    local index = tonumber(key)
    local value
    if index then
      value = args[index + 1]
    elseif type(params) == 'table' then
      value = params[key]
    end
    return value ~= nil and tostring(value) or ''
  end))
end

local function legacyMessage(input)
  if type(input) == 'string' then input = { args = { input } } end
  if type(input) ~= 'table' then return nil end
  local args = type(input.args) == 'table' and input.args or {}
  local template = type(input.template) == 'string' and input.template or templates[input.templateId]
  local authorName, text
  if template then
    text = fillTemplate(template, args, input.params)
  elseif #args >= 2 then
    authorName = stripCodes(args[1])
    local parts = {}
    for index = 2, #args do parts[#parts + 1] = tostring(args[index]) end
    text = table.concat(parts, ' ')
  elseif #args == 1 then
    text = tostring(args[1])
  end
  if not text or not text:find('%S') then return nil end
  local named = authorName and authorName ~= ''
  return {
    kind = named and 'chat' or 'system',
    channel = type(input.channel) == 'string' and input.channel or Config.Chat.legacyChannel,
    text = text,
    author = named and {
      name = authorName,
      color = hexColor(input.color)
    } or nil
  }
end

local function addMessage(message)
  pushMessage(legacyMessage(message))
end

local function addSuggestion(name, help, params)
  if type(name) ~= 'string' then return end
  name = name:gsub('^/', '')
  if name == '' then return end
  local list = {}
  if type(params) == 'table' then
    for _, param in ipairs(params) do
      if type(param) == 'table' and type(param.name) == 'string' then
        list[#list + 1] = {
          name = param.name,
          help = type(param.help) == 'string' and param.help or nil
        }
      end
    end
  end
  removedSuggestions[name] = nil
  addedSuggestions[name] = {
    name = name,
    help = type(help) == 'string' and help ~= '' and help or nil,
    params = #list > 0 and list or nil
  }
  queueSuggestions()
end

local function provideExport(name, fn)
  exports(name, fn)
  AddEventHandler(('__cfx_export_chat_%s'):format(name), function(setCallback)
    setCallback(fn)
  end)
end

provideExport('addMessage', addMessage)
provideExport('addSuggestion', addSuggestion)

RegisterNUICallback('ready', function(_, cb)
  nuiReady = true
  flushQueue()
  requestInit()
  cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
  setOpen(false)
  cb({ ok = true })
end)

RegisterNUICallback('chatResult', function(data, cb)
  setOpen(false)
  cb({ ok = true })
  if type(data) ~= 'table' or type(data.message) ~= 'string' then return end
  local message = TruncateText(data.message, Config.Chat.maxLength)
  if not message then return end
  if message:sub(1, 1) == '/' then
    local command = message:sub(2)
    if command:find('%S') then ExecuteCommand(command) end
    return
  end
  if type(data.channel) ~= 'string' then return end
  TriggerServerEvent('fearx_chat:send', data.channel, message)
end)

RegisterNUICallback('setProfile', function(data, cb)
  cb({ ok = true })
  if type(data) ~= 'table' then return end
  TriggerServerEvent('fearx_chat:setProfile', {
    tags = data.tags,
    decoration = data.decoration
  })
end)

RegisterNUICallback('staffAction', function(data, cb)
  if type(data) ~= 'table' then
    cb({ ok = false })
    return
  end
  nextRequestId = nextRequestId + 1
  local requestId = nextRequestId
  staffRequests[requestId] = cb
  TriggerServerEvent('fearx_chat:staffAction', requestId, data)
  SetTimeout(STAFF_TIMEOUT_MS, function()
    local pending = staffRequests[requestId]
    if not pending then return end
    staffRequests[requestId] = nil
    pending({ ok = false })
  end)
end)

RegisterNetEvent('fearx_chat:staffResult', function(requestId, ok, problem)
  local pending = staffRequests[requestId]
  if not pending then return end
  staffRequests[requestId] = nil
  pending({ ok = ok == true, error = problem })
end)

RegisterNetEvent('fearx_chat:init', function(data)
  if type(data) ~= 'table' then return end
  lastInitAt = GetGameTimer()
  send('config', {
    channels = data.channels,
    maxLength = Config.Chat.maxLength,
    logo = Config.Ui.logo,
    logoImage = Config.Ui.logoImage,
    styles = Config.Ui.styles,
    locked = Config.Ui.locked,
    defaults = Config.Ui.defaults
  })
  send('cosmetics', data.cosmetics)
  send('profile', data.profile)
  send('channelControls', data.controls)
  if type(data.moderation) == 'table' then send('moderation', data.moderation) end
  serverSuggestions = type(data.suggestions) == 'table' and data.suggestions or {}
  queueSuggestions()
end)

RegisterNetEvent('fearx_chat:message', pushMessage)

RegisterNetEvent('fearx_chat:profile', function(profile)
  send('profile', profile)
end)

RegisterNetEvent('fearx_chat:moderation', function(settings)
  send('moderation', settings)
end)

RegisterNetEvent('fearx_chat:channelControls', function(controls)
  send('channelControls', controls)
end)

RegisterNetEvent('fearx_chat:serverSuggestions', function(list)
  serverSuggestions = type(list) == 'table' and list or {}
  queueSuggestions()
end)

RegisterNetEvent('chatMessage', function(author, color, text)
  local hasAuthor = type(author) == 'string' and author ~= ''
  addMessage({
    color = color,
    args = hasAuthor and { author, text } or { text }
  })
end)

RegisterNetEvent('chat:addMessage', addMessage)

RegisterNetEvent('__cfx_internal:serverPrint', function(text)
  if type(text) ~= 'string' then return end
  addMessage(text:gsub('%s+$', ''))
end)

RegisterNetEvent('chat:addTemplate', function(id, html)
  if type(id) == 'string' and type(html) == 'string' then templates[id] = html end
end)

RegisterNetEvent('chat:clear', function()
  send('clear')
end)

RegisterNetEvent('chat:addSuggestion', addSuggestion)

RegisterNetEvent('chat:addSuggestions', function(list)
  if type(list) ~= 'table' then return end
  for _, suggestion in ipairs(list) do
    if type(suggestion) == 'table' then addSuggestion(suggestion.name, suggestion.help, suggestion.params) end
  end
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
  if type(name) ~= 'string' then return end
  name = name:gsub('^/', '')
  addedSuggestions[name] = nil
  removedSuggestions[name] = true
  queueSuggestions()
end)

AddEventHandler('onClientResourceStart', queueSuggestions)
AddEventHandler('onClientResourceStop', queueSuggestions)

RegisterCommand('fearx_chat_open', function()
  openChat('')
end, false)
RegisterKeyMapping('fearx_chat_open', L('key.open'), 'keyboard', Config.Keys.open)

RegisterCommand('fearx_chat_command', function()
  openChat('/')
end, false)
RegisterKeyMapping('fearx_chat_command', L('key.command'), 'keyboard', Config.Keys.command)

if Config.Commands.clear and Config.Commands.clear.enabled then
  RegisterCommand(Config.Commands.clear.name, function()
    send('clear')
  end, false)
  addSuggestion('/' .. Config.Commands.clear.name, L('help.clear'))
end

if Config.Commands.settings and Config.Commands.settings.enabled then
  RegisterCommand(Config.Commands.settings.name, function()
    if not nuiReady then return end
    setOpen(true)
    send('settings')
  end, false)
  addSuggestion('/' .. Config.Commands.settings.name, L('help.settings'))
end

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then return end
  if isOpen then SetNuiFocus(false, false) end
end)

CreateThread(function()
  local visible = true
  while true do
    local shouldShow = not IsPauseMenuActive() and not IsScreenFadedOut()
    if shouldShow ~= visible and nuiReady then
      visible = shouldShow
      send('visible', visible)
    end
    Wait(VISIBILITY_POLL_MS)
  end
end)

SetTextChatEnabled(false)
