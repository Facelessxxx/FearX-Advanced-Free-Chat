Bridge = {}

local framework

local function detectFramework()
  if framework then return framework end
  if GetResourceState('qbx_core') == 'started' then
    framework = 'qbx'
  elseif GetResourceState('qb-core') == 'started' then
    framework = 'qb'
  elseif GetResourceState('es_extended') == 'started' then
    framework = 'esx'
  end
  return framework
end

local ESX, QBCore
local function esx()
  ESX = ESX or exports.es_extended:getSharedObject()
  return ESX
end
local function qb()
  QBCore = QBCore or exports['qb-core']:GetCoreObject()
  return QBCore
end

local function playerData(src)
  local kind = detectFramework()
  if kind == 'qbx' then
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData
  end
  if kind == 'qb' then
    local player = qb().Functions.GetPlayer(src)
    return player and player.PlayerData
  end
  return nil
end

function Bridge.framework()
  return detectFramework() or nil
end

function Bridge.characterName(src)
  if Config.Chat.nameSource ~= 'character' then return nil end
  local kind = detectFramework()
  if not kind then return nil end
  local ok, name = pcall(function()
    if kind == 'esx' then
      local xPlayer = esx().GetPlayerFromId(src)
      return xPlayer and xPlayer.getName()
    end
    local data = playerData(src)
    local info = data and data.charinfo
    return info and ('%s %s'):format(info.firstname or '', info.lastname or '')
  end)
  if not ok or type(name) ~= 'string' then return nil end
  name = name:gsub('^%s+', ''):gsub('%s+$', '')
  return name ~= '' and name or nil
end

function Bridge.job(src)
  local kind = detectFramework()
  if not kind then return nil end
  local ok, name, onDuty = pcall(function()
    if kind == 'esx' then
      local xPlayer = esx().GetPlayerFromId(src)
      local job = xPlayer and xPlayer.job
      if not job then return nil end
      return job.name, job.onDuty ~= false
    end
    local data = playerData(src)
    local job = data and data.job
    if not job then return nil end
    return job.name, job.onduty == true
  end)
  if not ok then return nil end
  return name, onDuty
end
