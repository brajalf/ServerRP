QBCore = exports['qb-core']:GetCoreObject()

local function resStarted(r) return GetResourceState(r) == 'started' end

local Actions = {}

-- === EMS ===
Actions.revive = function()
  if resStarted('qb-ambulancejob') or resStarted('hospital') then
    -- la mayoría de forks aceptan este:
    TriggerEvent('hospital:client:Revive')
  else
    QBCore.Functions.Notify('No hay recurso de hospital/ambulancia activo.', 'error')
  end
end

Actions.heal = function()
  if resStarted('qb-ambulancejob') then
    TriggerEvent('hospital:client:TreatWounds')
  else
    QBCore.Functions.Notify('No hay recurso de hospital/ambulancia activo.', 'error')
  end
end

-- === POLICÍA ===
Actions.cuff = function()
  if resStarted('qb-policejob') then
    TriggerServerEvent('police:server:CuffPlayer')     -- fallback genérico
    TriggerEvent('police:client:CuffPlayer')           -- client event típico
  else
    QBCore.Functions.Notify('No hay recurso de policía activo.', 'error')
  end
end

Actions.escort = function()
  if resStarted('qb-policejob') then
    TriggerServerEvent('police:server:EscortPlayer')
    TriggerEvent('police:client:EscortPlayer')
  end
end

Actions.putinveh = function() TriggerEvent('police:client:PutPlayerInVehicle') end
Actions.takeoutveh = function() TriggerEvent('police:client:SetPlayerOutVehicle') end
Actions.bill = function() TriggerEvent('qb-billing:client:CreateBill') end

-- === MECÁNICO ===
Actions.repair = function() TriggerEvent('qb-mechanicjob:client:RepairVehicle') end
Actions.clean  = function() TriggerEvent('qb-mechanicjob:client:CleanVehicle') end
Actions.impound = function() TriggerEvent('police:client:ImpoundVehicle') end

RegisterNetEvent('qb-jobcreator:client:doAction', function(action)
  local fn = Actions[action]
  if fn then fn() else QBCore.Functions.Notify('Acción no disponible: '..tostring(action), 'error') end
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