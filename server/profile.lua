Profiles = {}

local DISCORD_API = 'https://discord.com/api/v10/users/%s'
local DISCORD_AVATAR = 'https://cdn.discordapp.com/avatars/%s/%s.png?size=128'
local MAX_DECORATION_ID = 64
local MAX_TAG_LIST = 32
local DISCORD_GAP_MS = 150
local RATE_LIMITED = 429

local records = {}
local avatarCache = {}
local nextDiscordSlot = 0
local tagsById, decorationsById = {}, {}

for _, entry in ipairs(Config.Cosmetics.tags) do tagsById[entry.id] = entry end
for _, entry in ipairs(Config.Cosmetics.decorations) do decorationsById[entry.id] = entry end

local function identifier(src, kind)
  local value = GetPlayerIdentifierByType(src, kind)
  if not value then return nil end
  return (value:gsub('^' .. kind .. ':', ''))
end

local function kvpKey(license)
  return 'profile:' .. license
end

local function readSaved(license)
  if not license then return {} end
  local raw = GetResourceKvpString(kvpKey(license))
  if not raw then return {} end
  local ok, data = pcall(json.decode, raw)
  if not ok or type(data) ~= 'table' then return {} end
  return data
end

local function save(record)
  if not record.license then return end
  SetResourceKvp(kvpKey(record.license), json.encode({
    tags = record.tags,
    decoration = record.decoration
  }))
end

function Profiles.isStaff(src)
  if src == 0 then return true end
  return IsPlayerAceAllowed(src, Config.Permissions.staff)
end

local function level(src)
  local best = 0
  for _, entry in ipairs(Config.Levels) do
    if entry.level > best and IsPlayerAceAllowed(src, entry.permission) then best = entry.level end
  end
  return best
end

local function collectUnlocks(src)
  local unlocks = {
    packs = {},
    tags = {},
    decorations = {}
  }
  for _, pack in ipairs(Config.Cosmetics.packs) do
    if pack.id ~= 'base' and IsPlayerAceAllowed(src, pack.permission or Config.Permissions.packPrefix .. pack.id) then
      unlocks.packs[#unlocks.packs + 1] = pack.id
    end
  end
  for _, entry in ipairs(Config.Cosmetics.tags) do
    if IsPlayerAceAllowed(src, Config.Permissions.tagPrefix .. entry.id) then unlocks.tags[#unlocks.tags + 1] = entry.id end
  end
  for _, entry in ipairs(Config.Cosmetics.decorations) do
    if IsPlayerAceAllowed(src, Config.Permissions.decorationPrefix .. entry.id) then
      unlocks.decorations[#unlocks.decorations + 1] = entry.id
    end
  end
  return unlocks
end

local function contains(list, value)
  for _, entry in ipairs(list) do
    if entry == value then return true end
  end
  return false
end

local function isUnlocked(record, item, kind)
  if contains(record.unlocks[kind], item.id) then return true end
  if record.level < (item.minLevel or 0) then return false end
  local pack = item.pack or 'base'
  return pack == 'base' or contains(record.unlocks.packs, pack)
end

local function validTags(record, list)
  local result, seen = {}, {}
  if type(list) ~= 'table' or #list > MAX_TAG_LIST then return result end
  for _, id in ipairs(list) do
    if #result >= Config.Cosmetics.maxTags then break end
    local entry = type(id) == 'string' and tagsById[id]
    if entry and not seen[id] and isUnlocked(record, entry, 'tags') then
      seen[id] = true
      result[#result + 1] = id
    end
  end
  return result
end

local function validDecoration(record, id)
  if type(id) ~= 'string' or #id > MAX_DECORATION_ID then return '' end
  local entry = decorationsById[id]
  if entry and isUnlocked(record, entry, 'decorations') then return id end
  return ''
end

local function refreshPermissions(record)
  record.level = level(record.src)
  record.unlocks = collectUnlocks(record.src)
  record.staff = Profiles.isStaff(record.src)
  record.tags = validTags(record, record.tags)
  record.decoration = validDecoration(record, record.decoration)
end

local function displayName(src)
  return Bridge.characterName(src) or GetPlayerName(src) or ('Player %d'):format(src)
end

local function fetchAvatar(record)
  local discordId = record.discordId
  local token = GetConvar('fearx_chat_discord_token', '')
  if not Config.Discord.avatars or not discordId or token == '' then return end
  local cached = avatarCache[discordId]
  if cached and os.time() < cached.expires then
    record.avatar = cached.url
    return
  end
  local t = GetGameTimer()
  nextDiscordSlot = math.max(nextDiscordSlot, t) + DISCORD_GAP_MS
  SetTimeout(nextDiscordSlot - t - DISCORD_GAP_MS, function()
    if records[record.src] ~= record then return end
    PerformHttpRequest(DISCORD_API:format(discordId), function(status, body)
      if status == RATE_LIMITED then return end
      local url = ''
      if status == 200 then
        local ok, data = pcall(json.decode, body or '')
        if ok and type(data) == 'table' and type(data.avatar) == 'string' then
          url = DISCORD_AVATAR:format(discordId, data.avatar)
        end
      elseif Config.Debug then
        print(('^3[fearx_chat] discord avatar lookup failed with status %s^0'):format(tostring(status)))
      end
      local minutes = status == 200 and Config.Discord.cacheMinutes or 5
      avatarCache[discordId] = {
        url = url,
        expires = os.time() + minutes * 60
      }
      if records[record.src] == record and url ~= '' then
        record.avatar = url
        TriggerClientEvent('fearx_chat:profile', record.src, Profiles.snapshot(record.src))
      end
    end, 'GET', '', {
      Authorization = 'Bot ' .. token
    })
  end)
end

function Profiles.load(src)
  local license = identifier(src, 'license')
  local saved = readSaved(license)
  local record = {
    src = src,
    license = license,
    discordId = identifier(src, 'discord'),
    avatar = '',
    tags = saved.tags,
    decoration = saved.decoration
  }
  records[src] = record
  refreshPermissions(record)
  fetchAvatar(record)
  return record
end

function Profiles.get(src)
  return records[src] or Profiles.load(src)
end

function Profiles.drop(src)
  records[src] = nil
  local t = os.time()
  for discordId, cached in pairs(avatarCache) do
    if t >= cached.expires then avatarCache[discordId] = nil end
  end
end

function Profiles.refresh(src)
  local record = Profiles.get(src)
  refreshPermissions(record)
  return record
end

function Profiles.snapshot(src)
  local record = Profiles.get(src)
  return {
    level = record.level,
    staff = record.staff,
    admin = Moderation.isAdmin(src),
    name = displayName(src),
    avatar = record.avatar,
    unlocks = record.unlocks,
    tags = record.tags,
    decoration = record.decoration
  }
end

function Profiles.cosmetics()
  return {
    maxTags = Config.Cosmetics.maxTags,
    packs = Config.Cosmetics.packs,
    tags = Config.Cosmetics.tags,
    decorations = Config.Cosmetics.decorations
  }
end

local function jobTag(src)
  local job, onDuty = Bridge.job(src)
  local tag = job and Config.JobTags[job]
  if not tag or (tag.requireDuty and not onDuty) then return nil end
  return {
    label = tag.label,
    color = tag.color,
    background = tag.background
  }
end

function Profiles.author(src)
  if src == 0 then return { name = 'Console' } end
  local record = Profiles.get(src)
  local tags = {}
  local job = jobTag(src)
  if job then tags[1] = job end
  for _, id in ipairs(record.tags) do tags[#tags + 1] = tagsById[id].tag end
  return {
    name = displayName(src),
    serverId = src,
    avatar = record.avatar ~= '' and record.avatar or nil,
    decoration = record.decoration ~= '' and record.decoration or nil,
    tags = tags
  }
end

function Profiles.update(src, data)
  if type(data) ~= 'table' then return end
  local record = Profiles.refresh(src)
  record.tags = validTags(record, data.tags)
  record.decoration = validDecoration(record, data.decoration)
  save(record)
end

AddEventHandler('playerDropped', function()
  Profiles.drop(source)
end)
