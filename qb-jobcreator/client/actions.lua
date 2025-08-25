QBCore = exports['qb-core']:GetCoreObject()
local function started(r) return GetResourceState(r) == 'started' end

local A = {}

-- EMS
A.revive = function()
  if started('qb-ambulancejob') or started('hospital') then
    TriggerEvent('hospital:client:Revive')
  else
    QBCore.Functions.Notify('Recurso de hospital/ambulancia no activo.', 'error')
  end
end
A.heal = function()
  if started('qb-ambulancejob') then
    TriggerEvent('hospital:client:TreatWounds')
  else
    QBCore.Functions.Notify('Recurso de hospital no activo.', 'error')
  end
end

-- POLICÍA
A.cuff      = function() TriggerServerEvent('police:server:CuffPlayer'); TriggerEvent('police:client:CuffPlayer') end
A.escort    = function() TriggerServerEvent('police:server:EscortPlayer'); TriggerEvent('police:client:EscortPlayer') end
A.putinveh  = function() TriggerEvent('police:client:PutPlayerInVehicle') end
A.takeout   = function() TriggerEvent('police:client:SetPlayerOutVehicle') end
A.bill      = function() TriggerEvent('qb-billing:client:CreateBill') end

-- MECÁNICO
A.repair    = function() TriggerEvent('qb-mechanicjob:client:RepairVehicle') end
A.clean     = function() TriggerEvent('qb-mechanicjob:client:CleanVehicle') end
A.impound   = function() TriggerEvent('police:client:ImpoundVehicle') end

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
  TriggerServerEvent('police:server:PutPlayerInVehicle', tgt)
end)

RegisterNetEvent('qb-jobcreator:client:act:outveh', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  TriggerServerEvent('police:server:TakeOutPlayerFromVehicle', tgt)
end)

RegisterNetEvent('qb-jobcreator:client:act:bill', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  -- Hook a tu sistema de facturas (ej. qb-banking / okokBilling)
  TriggerEvent('qb-billing:client:OpenBillMenu', tgt)
end)