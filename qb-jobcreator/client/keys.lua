-- F7 abre MULTIJOB (si existe), NO el jobcreator
local function openMultiJob()
  if Config.MultiJob and Config.MultiJob.Enabled and Config.MultiJob.Resource
     and GetResourceState(Config.MultiJob.Resource) == 'started' then
    -- intenta por export o comando configurable
    local ok = false
    if exports[Config.MultiJob.Resource] and exports[Config.MultiJob.Resource].OpenUI then
      ok = true
      exports[Config.MultiJob.Resource]:OpenUI()
    elseif Config.MultiJob.OpenCommand then
      ok = true
      ExecuteCommand(Config.MultiJob.OpenCommand) -- p.ej. 'multijob'
    end
    if not ok then QBCore.Functions.Notify('Recurso de Multitrabajo sin UI pública.', 'error') end
  else
    QBCore.Functions.Notify('Multitrabajo no disponible.', 'error')
  end
end

RegisterCommand('open-multijob', openMultiJob, false)
RegisterKeyMapping('open-multijob', 'Abrir Multitrabajo', 'keyboard', 'F7')
-- OJO: No registres ninguna keymapping para jobcreator. El creator solo por /jobcreator