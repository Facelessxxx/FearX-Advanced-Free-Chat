Moderation = {}

local SETTINGS_KEY = 'moderation:settings'
local SHORT_WORD = 5
local LOG_PREVIEW = 80

local TOGGLES = {
  slurs = function() return Config.Moderation.slurs.enabled end,
  ipLoggers = function() return Config.Moderation.links.blockIpLoggers end,
  discordInvites = function() return Config.Moderation.links.blockDiscordInvites end,
  ipAddresses = function() return Config.Moderation.links.blockIpAddresses end,
  allLinks = function() return Config.Moderation.links.blockAllLinks end,
  spam = function() return Config.Moderation.spam.enabled end,
  autoMute = function() return Config.Moderation.autoMute.enabled end
}

local HOMOGLYPHS = {
  [0x430] = 'a', [0x410] = 'a', [0x3B1] = 'a', [0x391] = 'a',
  [0x432] = 'b', [0x412] = 'b', [0x392] = 'b',
  [0x441] = 'c', [0x421] = 'c', [0x3F2] = 'c',
  [0x501] = 'd',
  [0x435] = 'e', [0x415] = 'e', [0x3B5] = 'e', [0x395] = 'e', [0x451] = 'e',
  [0x261] = 'g',
  [0x43D] = 'h', [0x41D] = 'h', [0x397] = 'h',
  [0x456] = 'i', [0x406] = 'i', [0x3B9] = 'i', [0x399] = 'i', [0x131] = 'i',
  [0x458] = 'j', [0x408] = 'j',
  [0x43A] = 'k', [0x41A] = 'k', [0x3BA] = 'k', [0x39A] = 'k',
  [0x43C] = 'm', [0x41C] = 'm', [0x39C] = 'm',
  [0x3B7] = 'n', [0x39D] = 'n',
  [0x43E] = 'o', [0x41E] = 'o', [0x3BF] = 'o', [0x39F] = 'o',
  [0x440] = 'p', [0x420] = 'p', [0x3C1] = 'p', [0x3A1] = 'p',
  [0x455] = 's', [0x405] = 's',
  [0x442] = 't', [0x422] = 't', [0x3C4] = 't', [0x3A4] = 't',
  [0x3C5] = 'u',
  [0x3BD] = 'v',
  [0x445] = 'x', [0x425] = 'x', [0x3C7] = 'x', [0x3A7] = 'x',
  [0x443] = 'y', [0x423] = 'y', [0x3B3] = 'y',
  [0x396] = 'z'
}

local LEET = {
  ['0'] = 'o',
  ['1'] = 'i',
  ['3'] = 'e',
  ['4'] = 'a',
  ['5'] = 's',
  ['7'] = 't',
  ['8'] = 'b',
  ['9'] = 'g',
  ['@'] = 'a',
  ['$'] = 's',
  ['!'] = 'i',
  ['|'] = 'i',
  ['+'] = 't'
}

local INVITE_PATTERNS = {
  'discord%.gg/([%w%-]+)',
  'discord%.com/invite/([%w%-]+)',
  'discordapp%.com/invite/([%w%-]+)',
  'dsc%.gg/([%w%-]+)',
  'discord%.me/([%w%-]+)',
  'discord%.io/([%w%-]+)'
}

local TLDS = {}
for tld in ([[com net org io gg co me tv ru uk de fr xyz info biz link site club online store app dev tk ml ga cf gq us ca au eu ly to be gl cc ws pw top live shop fun icu monster best host life guru space world su cn in nl pl es it br]]):gmatch('%a+') do
  TLDS[tld] = true
end

local overrides = {}
local slurRules = {}
local allowedWords = {}
local loggerDomains = {}
local loggerKeywords = {}
local strikes = {}
local recentSends = {}
local lastSent = {}

local function codepointLetter(cp)
  if cp >= 0xFF01 and cp <= 0xFF5E then cp = cp - 0xFEE0 end
  if cp < 128 then return string.char(cp):lower() end
  return HOMOGLYPHS[cp]
end

local function isSpace(cp)
  return cp == 0x20 or cp == 0xA0 or cp == 0x3000 or (cp >= 0x09 and cp <= 0x0D) or (cp >= 0x2000 and cp <= 0x200A)
end

local function letterTokens(text)
  local tokens, current = {}, {}
  local function flush()
    if #current > 0 then tokens[#tokens + 1] = table.concat(current) end
    current = {}
  end
  for _, cp in utf8.codes(text) do
    if isSpace(cp) then
      flush()
    else
      local ch = codepointLetter(cp)
      if ch and ch:match('%a') then
        current[#current + 1] = ch
      elseif ch and LEET[ch] then
        current[#current + 1] = LEET[ch]
      end
    end
  end
  flush()
  return tokens
end

local function linkText(text)
  local out = {}
  for _, cp in utf8.codes(text) do
    local ch = codepointLetter(cp)
    if ch and ch:match('[%w%.:/%-]') then
      out[#out + 1] = ch
    elseif isSpace(cp) then
      out[#out + 1] = ' '
    end
  end
  return table.concat(out)
end

local function squash(text)
  return (text:gsub('[^%w]', ''))
end

local function letterPattern(word)
  local parts = {}
  local index = 1
  while index <= #word do
    local ch = word:sub(index, index)
    local run = index
    while word:sub(run + 1, run + 1) == ch do run = run + 1 end
    parts[#parts + 1] = ch:rep(run - index + 1) .. '+'
    index = run + 1
  end
  return table.concat(parts)
end

local function buildRules()
  slurRules, allowedWords, loggerDomains, loggerKeywords = {}, {}, {}, {}
  for _, word in ipairs(Config.Moderation.slurs.words or {}) do
    local letters = table.concat(letterTokens(tostring(word)))
    if letters ~= '' then
      local pattern = letterPattern(letters)
      slurRules[#slurRules + 1] = {
        pattern = #letters <= SHORT_WORD and ('^' .. pattern .. '[sz]?$') or pattern,
        short = #letters <= SHORT_WORD
      }
    end
  end
  for _, word in ipairs(Config.Moderation.slurs.allowWords or {}) do
    allowedWords[table.concat(letterTokens(tostring(word)))] = true
  end
  for _, domain in ipairs(Config.Moderation.links.ipLoggerDomains or {}) do
    loggerDomains[#loggerDomains + 1] = squash(tostring(domain):lower())
  end
  for _, keyword in ipairs(Config.Moderation.links.ipLoggerKeywords or {}) do
    loggerKeywords[#loggerKeywords + 1] = squash(tostring(keyword):lower())
  end
end

local function tokenHasSlur(token)
  if allowedWords[token] then return false end
  for _, rule in ipairs(slurRules) do
    if token:find(rule.pattern) then return true end
  end
  return false
end

local function pairHasSlur(first, second)
  if allowedWords[first] or allowedWords[second] then return false end
  local joined = first .. second
  for _, rule in ipairs(slurRules) do
    if not rule.short then
      local start, finish = joined:find(rule.pattern)
      if start and start <= #first and finish > #first then return true end
    end
  end
  return false
end

local function hasSlur(text)
  local tokens = letterTokens(text)
  local run = {}
  local function checkRun()
    if #run >= 3 and tokenHasSlur(table.concat(run)) then return true end
    run = {}
    return false
  end
  for index, token in ipairs(tokens) do
    if tokenHasSlur(token) then return true end
    local nextToken = tokens[index + 1]
    if nextToken and pairHasSlur(token, nextToken) then return true end
    if #token == 1 then
      run[#run + 1] = token
    elseif checkRun() then
      return true
    end
  end
  return checkRun()
end

local function hasIpLogger(text)
  local squashed = squash(linkText(text))
  for _, domain in ipairs(loggerDomains) do
    if squashed:find(domain, 1, true) then return true end
  end
  for _, keyword in ipairs(loggerKeywords) do
    if squashed:find(keyword, 1, true) then return true end
  end
  return false
end

local function allowedInvite(code)
  for _, allowed in ipairs(Config.Moderation.links.allowedInviteCodes or {}) do
    if tostring(allowed):lower() == code then return true end
  end
  return false
end

local function hasDiscordInvite(text)
  local links = linkText(text)
  local found = false
  for _, pattern in ipairs(INVITE_PATTERNS) do
    for code in links:gmatch(pattern) do
      if not allowedInvite(code) then return true end
      found = true
    end
  end
  return not found and squash(links):find('discordgg', 1, true) ~= nil
end

local function hasIpAddress(text)
  for a, b, c, d in linkText(text):gmatch('(%d+)%.(%d+)%.(%d+)%.(%d+)') do
    if tonumber(a) <= 255 and tonumber(b) <= 255 and tonumber(c) <= 255 and tonumber(d) <= 255 then return true end
  end
  return false
end

local function domainAllowed(host)
  for _, domain in ipairs(Config.Moderation.links.allowedDomains or {}) do
    domain = tostring(domain):lower()
    if host == domain or host:sub(-(#domain + 1)) == '.' .. domain then return true end
  end
  return false
end

local function hasBlockedLink(text)
  local links = linkText(text)
  for word in links:gmatch('%S+') do
    local host = word:gsub('^%a+://', ''):gsub('^www%.', ''):match('^([%w%.%-]+)')
    local tld = host and host:match('%.(%a+)$')
    local looksLikeLink = word:find('://', 1, true) or word:find('^www%.') or (tld and TLDS[tld] and host:find('%w%.%a'))
    if looksLikeLink and not (host and domainAllowed(host)) then return true end
  end
  return false
end

function Moderation.settings()
  local result = {}
  for key, default in pairs(TOGGLES) do
    if overrides[key] ~= nil then
      result[key] = overrides[key]
    else
      result[key] = default() == true
    end
  end
  return result
end

local function enabled(key)
  return Config.Moderation.enabled and Moderation.settings()[key]
end

function Moderation.set(key, value)
  if TOGGLES[key] == nil or type(value) ~= 'boolean' then return false end
  overrides[key] = value
  SetResourceKvp(SETTINGS_KEY, json.encode(overrides))
  return true
end

function Moderation.isAdmin(src)
  if src == 0 then return true end
  return IsPlayerAceAllowed(src, Config.Permissions.admin)
end

local function prune(list, cutoff)
  local kept = {}
  for _, at in ipairs(list or {}) do
    if at > cutoff then kept[#kept + 1] = at end
  end
  return kept
end

local function spamReason(src, text)
  local t = GetGameTimer()
  local spam = Config.Moderation.spam
  local sends = prune(recentSends[src], t - spam.burstSeconds * 1000)
  if #sends >= spam.burstMessages then
    recentSends[src] = sends
    return 'flood'
  end
  local fingerprint = table.concat(letterTokens(text), ' ')
  local last = lastSent[src]
  if fingerprint ~= '' and last and last.text == fingerprint and t - last.at < spam.duplicateSeconds * 1000 then
    recentSends[src] = sends
    return 'duplicate'
  end
  sends[#sends + 1] = t
  recentSends[src] = sends
  lastSent[src] = {
    text = fingerprint,
    at = t
  }
  return nil
end

local function contentReason(text, staff)
  if enabled('slurs') and hasSlur(text) then return 'slur' end
  if enabled('ipLoggers') and hasIpLogger(text) then return 'ipLogger' end
  if staff and Config.Moderation.staffBypassLinks then return nil end
  if enabled('ipAddresses') and hasIpAddress(text) then return 'ipAddress' end
  if enabled('discordInvites') and hasDiscordInvite(text) then return 'discordInvite' end
  if enabled('allLinks') and hasBlockedLink(text) then return 'link' end
  return nil
end

local function addStrike(src)
  local auto = Config.Moderation.autoMute
  local t = os.time()
  local list = prune(strikes[src], t - auto.windowMinutes * 60)
  list[#list + 1] = t
  strikes[src] = list
  if not enabled('autoMute') or #list < auto.strikes then return false end
  strikes[src] = nil
  return Staff.autoMute(src, auto.muteMinutes, L('filter.autoMuteReason'))
end

function Moderation.check(src, text, staff)
  if not Config.Moderation.enabled then return true end
  local reason = contentReason(text, staff)
  if not reason and enabled('spam') and not (staff and Config.Moderation.staffBypassSpam) then
    local spam = spamReason(src, text)
    if spam then return false, L('filter.' .. spam) end
  end
  if not reason then return true end
  local name = GetPlayerName(src) or tostring(src)
  if Config.Moderation.logToConsole then
    print(('^3[fearx_chat] filter blocked %s (%d) [%s]: %s^0'):format(name, src, reason, TruncateText(text, LOG_PREVIEW) or ''))
  end
  if Config.Moderation.notifyStaff then
    Chat.staffNotice(L('filter.staffNotice', name, src, L('filter.kind.' .. reason)))
  end
  if not staff and addStrike(src) then return false, L('filter.autoMuted', Config.Moderation.autoMute.muteMinutes) end
  return false, L('filter.' .. reason)
end

function Moderation.drop(src)
  strikes[src] = nil
  recentSends[src] = nil
  lastSent[src] = nil
end

local function loadOverrides()
  local raw = GetResourceKvpString(SETTINGS_KEY)
  local ok, data = pcall(json.decode, raw or '')
  if not ok or type(data) ~= 'table' then return end
  for key, value in pairs(data) do
    if TOGGLES[key] ~= nil and type(value) == 'boolean' then overrides[key] = value end
  end
end

buildRules()
loadOverrides()

AddEventHandler('playerDropped', function()
  Moderation.drop(source)
end)
