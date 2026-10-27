Staff = {}

local ANNOUNCE_KINDS = {
  announce = true,
  event = true,
  alert = true
}
local MAX_TITLE = 40
local MAX_ANNOUNCEMENT = 300
local MAX_REASON = 80
local MAX_SLOWMODE = 600
local MAX_MUTE_MINUTES = 43200

local controls = {}
local mutes = {}

local function muteKey(license)
  return 'mute:' .. license
end

local function license(src)
  local value = GetPlayerIdentifierByType(src, 'license')
  return value and (value:gsub('^license:', ''))
end

local function readMute(id)
  if mutes[id] ~= nil then return mutes[id] or nil end
  local raw = GetResourceKvpString(muteKey(id))
  local ok, data = pcall(json.decode, raw or '')
  mutes[id] = ok and type(data) == 'table' and type(data.expires) == 'number' and data or false
  return mutes[id] or nil
end

local function writeMute(id, data)
  mutes[id] = data or false
  if data then
    SetResourceKvp(muteKey(id), json.encode(data))
  else
    DeleteResourceKvp(muteKey(id))
  end
end

function Staff.muteOf(src)
  local id = license(src)
  if not id then return nil end
  local mute = readMute(id)
  if not mute then return nil end
  if mute.expires > 0 and os.time() >= mute.expires then
    writeMute(id, nil)
    return nil
  end
  return mute
end

function Staff.control(channelId)
  return controls[channelId] or {
    locked = false,
    slowmode = 0
  }
end

function Staff.controls()
  return controls
end

local function exists(src)
  return type(src) == 'number' and src > 0 and GetPlayerName(src) ~= nil
end

local function cleanText(value, maxLength)
  if type(value) ~= 'string' then return nil end
  value = value:gsub('%c', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  local length = utf8.len(value)
  if not length or length > maxLength then return nil end
  return value
end

local function wholeNumber(value, min, max)
  value = tonumber(value)
  if not value or value ~= math.floor(value) or value < min or value > max then return nil end
  return math.tointeger(value)
end

local function audit(src, text)
  print(('[fearx_chat] staff %s (%d): %s'):format(GetPlayerName(src) or 'console', src, text))
end

local actions = {}

function actions.announce(src, data)
  local title = cleanText(data.title or '', MAX_TITLE)
  local message = cleanText(data.message, MAX_ANNOUNCEMENT)
  if not ANNOUNCE_KINDS[data.kind] or not title or not message or message == '' then return false, L('invalidRequest') end
  Chat.broadcast(data.kind, title, message)
  audit(src, ('%s "%s": %s'):format(data.kind, title, message))
  return true
end

function actions.channel(src, data)
  local channel = Chat.channel(data.channel)
  local slowmode = wholeNumber(data.slowmode, 0, MAX_SLOWMODE)
  if not channel or type(data.locked) ~= 'boolean' or not slowmode then return false, L('invalidRequest') end
  controls[channel.id] = {
    locked = data.locked,
    slowmode = slowmode
  }
  TriggerClientEvent('fearx_chat:channelControls', -1, {
    [channel.id] = controls[channel.id]
  })
  audit(src, ('channel %s locked=%s slowmode=%ds'):format(channel.id, tostring(data.locked), slowmode))
  return true
end

function actions.clearAll(src)
  TriggerClientEvent('chat:clear', -1)
  Chat.system(-1, L('chatCleared'))
  audit(src, 'cleared chat for everyone')
  return true
end

local function applyMute(target, minutes, reason, byName)
  local id = license(target)
  writeMute(id, {
    expires = minutes > 0 and os.time() + minutes * 60 or 0,
    reason = reason,
    by = byName
  })
  local span = minutes > 0 and L('mutedFor', minutes) or L('mutedForever')
  Chat.system(target, L('youWereMuted', span, reason))
  Chat.staffNotice(L('mutedTarget', GetPlayerName(target), span, byName, reason))
  return id, span
end

function actions.mute(src, data)
  local target = wholeNumber(data.target, 1, 65535)
  local minutes = wholeNumber(data.minutes, 0, MAX_MUTE_MINUTES)
  local reason = cleanText(data.reason or '', MAX_REASON)
  if not target or not minutes or not reason then return false, L('invalidRequest') end
  if not exists(target) then return false, L('playerNotFound', tostring(target)) end
  if target == src then return false, L('cannotMuteSelf') end
  if Profiles.isStaff(target) then return false, L('cannotMuteStaff') end
  if not license(target) then return false, L('playerNotFound', tostring(target)) end
  if reason == '' then reason = L('noReason') end
  local id, span = applyMute(target, minutes, reason, GetPlayerName(src) or 'console')
  audit(src, ('muted %d (license %s) %s: %s'):format(target, id, span, reason))
  return true
end

function Staff.autoMute(target, minutes, reason)
  if not exists(target) or Profiles.isStaff(target) or not license(target) then return false end
  local id, span = applyMute(target, minutes, reason, L('filter.autoModerator'))
  print(('[fearx_chat] auto-muted %d (license %s) %s: %s'):format(target, id, span, reason))
  return true
end

function actions.moderation(src, data)
  if not Moderation.isAdmin(src) then return false, L('noPermission') end
  if not Moderation.set(data.key, data.value) then return false, L('invalidRequest') end
  local settings = Moderation.settings()
  for _, id in ipairs(GetPlayers()) do
    local player = tonumber(id)
    if Moderation.isAdmin(player) then TriggerClientEvent('fearx_chat:moderation', player, settings) end
  end
  audit(src, ('moderation %s = %s'):format(data.key, tostring(data.value)))
  return true
end

function actions.unmute(src, data)
  local target = wholeNumber(data.target, 1, 65535)
  if not target then return false, L('invalidRequest') end
  if not exists(target) then return false, L('playerNotFound', tostring(target)) end
  if not Staff.muteOf(target) then return false, L('notMuted') end
  writeMute(license(target), nil)
  Chat.system(target, L('youWereUnmuted'))
  Chat.staffNotice(L('unmutedTarget', GetPlayerName(target), GetPlayerName(src) or 'console'))
  audit(src, ('unmuted %d'):format(target))
  return true
end

function Staff.run(src, data)
  if not Profiles.isStaff(src) then return false, L('noPermission') end
  if type(data) ~= 'table' or type(data.action) ~= 'string' then return false, L('invalidRequest') end
  local action = actions[data.action]
  if not action then return false, L('invalidRequest') end
  return action(src, data)
end

RegisterCommand('chatunmute', function(src, args)
  if src ~= 0 then return end
  local id = args[1] and args[1]:gsub('^license:', '')
  if not id or not readMute(id) then
    print('[fearx_chat] usage: chatunmute <license> (the license is printed when a player is muted)')
    return
  end
  writeMute(id, nil)
  print(('[fearx_chat] unmuted license %s'):format(id))
end, true)

AddEventHandler('playerDropped', function()
  local id = license(source)
  if id then mutes[id] = nil end
end)

RegisterNetEvent('fearx_chat:staffAction', function(requestId, data)
  local src = source
  if type(requestId) ~= 'number' then return end
  local ok, problem = Staff.run(src, data)
  TriggerClientEvent('fearx_chat:staffResult', src, requestId, ok == true, problem)
end)
