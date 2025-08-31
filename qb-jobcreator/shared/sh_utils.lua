QBCore = exports['qb-core']:GetCoreObject()
local locale = 'es'
function _L(key) return (Locales[locale] and Locales[locale][key]) or key end

local Utils = {}

function HasOpenPermission(src)
  if Config.Permission.Mode == 'ACE' then
    return IsPlayerAceAllowed(src, Config.Permission.Ace)
  else
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local job = Player.PlayerData.job or {}
    if job.name ~= Config.Permission.Job.name then return false end
    local gname = job.grade and (job.grade.name or job.grade.level or job.grade) or nil
    return Config.Permission.Job.grades[tostring(gname)] or Config.Permission.Job.grades[gname] or false
  end
end
Utils.HasOpenPermission = HasOpenPermission

function UseTarget()
  if Config.Integrations.UseQbTarget and GetResourceState('qb-target') == 'started' then
    return 'qb-target'
  end
  return false
end
Utils.UseTarget = UseTarget

function Utils.GetJob(src)
  local Player = QBCore.Functions.GetPlayer(src)
  return Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name or 'unemployed'
end

function Utils.HasSkill(src, skillIID)
  if not Config.DevSkillTree or not skillIID or skillIID == '' then return true end
  return true
end

function Utils.GetLicense(src)
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:find('license:') then return id end
  end
  return GetPlayerIdentifier(src, 0) or ('src:%s'):format(src)
end

return Utils
