local function dprint(msg)
  if Config.Debug then
    print(('[%s][CLIENT] %s'):format(Config.ResourceName, msg))
  end
end

-- Enumerador seguro de entidades
local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
  return coroutine.wrap(function()
    local iterator, id = initFunc()
    if not id or id == 0 then
      disposeFunc(iterator)
      return
    end
    local next = true
    repeat
      coroutine.yield(id)
      next, id = moveFunc(iterator)
    until not next
    disposeFunc(iterator)
  end)
end

local function EnumerateVehicles()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

local function isModelBlacklisted(model, list)
  if not list then return false end
  for i=1, #list do
    if model == list[i] then return true end
  end
  return false
end

local function isClassBlacklisted(class, list)
  if not list then return false end
  for i=1, #list do
    if class == list[i] then return true end
  end
  return false
end

local function isAnySeatOccupied(veh)
  local max = GetVehicleMaxNumberOfPassengers(veh)
  for seat = -1, max do
    if not IsVehicleSeatFree(veh, seat) then
      return true
    end
  end
  return false
end

local function tryDeleteVehicle(veh)
  if not DoesEntityExist(veh) then return false end

  -- Asegurar control de red
  if not NetworkHasControlOfEntity(veh) then
    local attempts = 0
    while attempts < 20 and not NetworkHasControlOfEntity(veh) do
      NetworkRequestControlOfEntity(veh)
      attempts = attempts + 1
      Wait(25)
    end
  end

  SetEntityAsMissionEntity(veh, true, true)
  DeleteVehicle(veh)
  if DoesEntityExist(veh) then
    DeleteEntity(veh)
  end
  return not DoesEntityExist(veh)
end

RegisterNetEvent('invictus_tow:client:showAlert', function(payload)
  lib.notify({
    title = payload.title or Config.AlertTitle,
    description = payload.text or Config.AlertText,
    position = 'top',
    duration = (payload.duration or Config.AlertDuration) * 1000,
    type = 'inform'
  })
end)

RegisterNetEvent('invictus_tow:client:showCancel', function(payload)
  lib.notify({
    title = payload.title or Config.CancelTitle,
    description = payload.text or Config.CancelText,
    position = 'top',
    duration = (payload.duration or 4) * 1000,
    type = 'error'
  })
end)

-- Ejecución de limpieza
RegisterNetEvent('invictus_tow:client:doCleanup', function(cfg, token)
  local removed = 0

  for veh in EnumerateVehicles() do
    if DoesEntityExist(veh) then
      local model = GetEntityModel(veh)
      local class = GetVehicleClass(veh)

      -- Filtros
      if cfg.skipEmergency and class == 18 then goto continue end
      if cfg.skipBA and (class == 14 or class == 15 or class == 16 or class == 21) then goto continue end
      if isModelBlacklisted(model, cfg.blModels) then goto continue end
      if isClassBlacklisted(class, cfg.blClasses) then goto continue end

      -- No borrar si hay alguien a bordo
      if isAnySeatOccupied(veh) then goto continue end

      -- Solo el owner de la entidad elimina para evitar duplicados
      local owner = NetworkGetEntityOwner(veh)
      if owner ~= PlayerId() then goto continue end

      -- Intentar borrar
      if tryDeleteVehicle(veh) then
        removed = removed + 1
      end
    end
    ::continue::
  end

  TriggerServerEvent('invictus_tow:server:report', token, removed)
  if Config.Debug then
    dprint(('Borrados: %s'):format(removed))
  end
end)
