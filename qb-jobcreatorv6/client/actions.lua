QBCore = exports['qb-core']:GetCoreObject()
local function started(r) return GetResourceState(r) == 'started' end

local A = {}

-- EMS
A.revive = function()
  if started('ars_ambulancejob') then
    TriggerServerEvent(Config.Integrations.HospitalReviveEvent, { revive = true })
  else
    QBCore.Functions.Notify('Recurso de hospital/ambulancia no activo.', 'error')
  end
end
A.heal = function()
  if started('ars_ambulancejob') then
    TriggerServerEvent(Config.Integrations.HospitalHealEvent, { heal = true })
  else
    QBCore.Functions.Notify('Recurso de hospital no activo.', 'error')
  end
end

-- POLICÍA
A.cuff = function()
  if started('police') then
    TriggerServerEvent('police:server:CuffPlayer')
    TriggerEvent('police:client:CuffPlayer')
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end
A.escort = function()
  if started('police') then
    TriggerServerEvent('police:server:EscortPlayer')
    TriggerEvent('police:client:EscortPlayer')
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end
A.putinveh = function()
  if started('police') then
    TriggerEvent('police:client:PutPlayerInVehicle')
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end
A.takeout = function()
  if started('police') then
    TriggerEvent('police:client:SetPlayerOutVehicle')
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end
A.bill = function()
  if started('qb-billing') then
    TriggerEvent('qb-billing:client:CreateBill')
  else
    QBCore.Functions.Notify('Recurso de facturación no activo.', 'error')
  end
end

-- MECÁNICO
A.repair = function()
  if started('qb-mechanicjob') then
    TriggerEvent('qb-mechanicjob:client:RepairVehicle')
  else
    QBCore.Functions.Notify('Recurso de mecánico no activo.', 'error')
  end
end
A.clean = function()
  if started('qb-mechanicjob') then
    TriggerEvent('qb-mechanicjob:client:CleanVehicle')
  else
    QBCore.Functions.Notify('Recurso de mecánico no activo.', 'error')
  end
end
A.impound = function()
  if started('police') then
    TriggerEvent('police:client:ImpoundVehicle')
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end

RegisterNetEvent('qb-jobcreator:client:doAction', function(action)
  local pd = QBCore.Functions.GetPlayerData() or {}
  local jobName = (pd.job and pd.job.name) or ''
  local byJob = (Config.PlayerActionsByJob or {})[jobName] or {}
  local allowed = false
  for _, v in ipairs(byJob) do if v == action then allowed = true break end end
  if allowed and ((Config.PlayerActionsDefaults or {})[action] ~= false) then
    local fn = A[action]
    if fn then
      fn()
    else
      QBCore.Functions.Notify('Acción no disponible: '..tostring(action), 'error')
    end
  else
    QBCore.Functions.Notify('Acción no disponible: '..tostring(action), 'error')
  end
end)

-- Helpers
local function GetClosestPlayer(radius)
  local players = QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), radius or 2.0)
  for _, pid in ipairs(players) do if pid ~= PlayerId() then return GetPlayerServerId(pid) end end
end

RegisterNetEvent('qb-jobcreator:client:act:putinveh', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  if started('police') then
    TriggerServerEvent('police:server:PutPlayerInVehicle', tgt)
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end)

RegisterNetEvent('qb-jobcreator:client:act:outveh', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  if started('police') then
    TriggerServerEvent('police:server:TakeOutPlayerFromVehicle', tgt)
  else
    QBCore.Functions.Notify('Recurso de policía no activo.', 'error')
  end
end)

RegisterNetEvent('qb-jobcreator:client:act:bill', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  -- Hook a tu sistema de facturas (ej. qb-banking / okokBilling)
  if started('qb-billing') then
    TriggerEvent('qb-billing:client:OpenBillMenu', tgt)
  else
    QBCore.Functions.Notify('Recurso de facturación no activo.', 'error')
  end
end)