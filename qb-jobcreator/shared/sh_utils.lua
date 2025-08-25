QBCore = exports['qb-core']:GetCoreObject()
local locale = 'es'
function _L(key) return (Locales[locale] and Locales[locale][key]) or key end

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

function UseTarget()
  return Config.InteractionMode == 'target' and (Config.Integrations.UseQbTarget or Config.Integrations.UseOxTarget)
end