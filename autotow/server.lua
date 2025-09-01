local cleanupState = {
  active = false,
  token = 0,      -- id de ciclo
  cancelled = false
}

local function debugPrint(msg)
  if Config.Debug then
    print(('^3[%s][DEBUG]^7 %s'):format(Config.ResourceName, msg))
  end
end

local function isModelBlacklisted(model, list)
  if not list then return false end
  for i = 1, #list do
    if model == list[i] then return true end
  end
  return false
end

local function isClassBlacklisted(class, list)
  if not list then return false end
  for i = 1, #list do
    if class == list[i] then return true end
  end
  return false
end

-- Safe native fallbacks
local GetEntityModel = GetEntityModel or function(entity)
  return Citizen.InvokeNative(0x9F47B058362C84B5, entity)
end

local GetVehicleClass = GetVehicleClass or function(vehicle)
  return Citizen.InvokeNative(0x29439776AAA00A62, vehicle)
end

local GetVehicleMaxNumberOfPassengers = GetVehicleMaxNumberOfPassengers or function(vehicle)
  return Citizen.InvokeNative(0xA7C4F2C6E744A1E8, vehicle)
end

local IsVehicleSeatFree = IsVehicleSeatFree or function(vehicle, seatIndex)
  return Citizen.InvokeNative(0x22AC59A870E6A669, vehicle, seatIndex)
end

local GetEntityCoords = GetEntityCoords or function(entity)
  return Citizen.InvokeNative(0x3FEF770D40960D5A, entity, false, false)
end

local DoesEntityExist = DoesEntityExist or function(entity)
  return Citizen.InvokeNative(0x7239B21A38F536BA, entity)
end

local SetEntityAsMissionEntity = SetEntityAsMissionEntity or function(entity, p1, p2)
  return Citizen.InvokeNative(0xAD738C3085FE7E11, entity, p1, p2)
end

local DeleteEntity = DeleteEntity or function(entity)
  return Citizen.InvokeNative(0x7D9EFB7AD0A3BED7, entity)
end

local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity or function(entity)
  return Citizen.InvokeNative(0xA11700682F3AD45C, entity)
end

local GetPlayerPed = GetPlayerPed or function(player)
  return Citizen.InvokeNative(0x6E31E99359A9B316, player)
end

local function isAnySeatOccupied(veh)
  local max = GetVehicleMaxNumberOfPassengers(veh)
  if type(max) ~= "number" then
    debugPrint(('Unexpected max passenger value %s for vehicle %s'):format(tostring(max), veh))
    return true
  end
  for seat = -1, max do
    if not IsVehicleSeatFree(veh, seat) then
      return true
    end
  end
  return false
end

-- Limpia vehículos no streameados en el servidor
local function cleanupServerVehicles(cfg)
  local removed = 0
  for _, veh in ipairs(GetAllVehicles()) do
    if DoesEntityExist(veh) then
      if isAnySeatOccupied(veh) then goto continue end
      local model = GetEntityModel(veh)

      if not model or model == 0 then
        SetEntityAsMissionEntity(veh, true, true)
        local vehCoords = GetEntityCoords(veh)
        local netId = NetworkGetNetworkIdFromEntity(veh)
        DeleteEntity(veh)
        if not DoesEntityExist(veh) then
          removed = removed + 1
          local range = Config.RemoveNotifyRange or 0
          if range > 0 then
            local players = GetPlayers()
            for i = 1, #players do
              local playerId = tonumber(players[i])
              local ped = GetPlayerPed(playerId)
              local pCoords = GetEntityCoords(ped)
              if #(vehCoords - pCoords) < range then
                TriggerClientEvent('invictus_tow:client:vehicleRemoved', playerId, netId)
              end
            end
          end
        end
        goto continue
      end

      -- local class = GetVehicleClass(veh)

      -- if cfg.skipEmergency and class == 18 then goto continue end
      -- if cfg.skipBA and (class == 14 or class == 15 or class == 16 or class == 21) then goto continue end
      -- if isModelBlacklisted(model, cfg.blModels) then goto continue end
      -- if isClassBlacklisted(class, cfg.blClasses) then goto continue end

      -- if cfg.minDist and cfg.minDist > 0 then
      --   local vehCoords = GetEntityCoords(veh)
      --   local players = GetPlayers()
      --   for i = 1, #players do
      --     local ped = GetPlayerPed(players[i])
      --     local pCoords = GetEntityCoords(ped)
      --     if #(vehCoords - pCoords) < cfg.minDist then
      --       goto continue
      --     end
      --   end
      -- end

      SetEntityAsMissionEntity(veh, true, true)
      local vehCoords = GetEntityCoords(veh)
      local netId = NetworkGetNetworkIdFromEntity(veh)
      DeleteEntity(veh)
      if not DoesEntityExist(veh) then
        removed = removed + 1
        local range = Config.RemoveNotifyRange or 0
        if range > 0 then
          local players = GetPlayers()
          for i = 1, #players do
            local playerId = tonumber(players[i])
            local ped = GetPlayerPed(playerId)
            local pCoords = GetEntityCoords(ped)
            if #(vehCoords - pCoords) < range then
              TriggerClientEvent('invictus_tow:client:vehicleRemoved', playerId, netId)
            end
          end
        end
      end
    end
    ::continue::
  end

  if Config.Debug then
    debugPrint(('Servidor eliminó %s vehículos no streameados'):format(removed))
  end
end

-- Broadcast alert a todos
local function broadcastAlert(text, duration, title)
  TriggerClientEvent('invictus_tow:client:showAlert', -1, {
    title = title or Config.AlertTitle,
    text = text or Config.AlertText,
    duration = duration or Config.AlertDuration
  })
end

-- Broadcast cancelación visual
local function broadcastCancel()
  TriggerClientEvent('invictus_tow:client:showCancel', -1, {
    title = Config.CancelTitle,
    text = Config.CancelText,
    duration = 4000
  })
end

-- Dispara un ciclo de alerta + limpieza
local function startCleanupCycle(manual)
  if cleanupState.active then
    debugPrint('Ya hay un ciclo activo; ignorando startCleanupCycle()')
    return
  end
  cleanupState.active = true
  cleanupState.cancelled = false
  cleanupState.token = cleanupState.token + 1
  local token = cleanupState.token

  print(('^2[%s]^7 Iniciando ciclo de limpieza (token=%s)%s'):format(
    Config.ResourceName, token, manual and ' [MANUAL]' or '')
  )

  local function schedule(delay, cb)
    SetTimeout(delay, function()
      if cleanupState.cancelled or token ~= cleanupState.token then
        if cleanupState.active then
          print(('^2[%s]^7 Ciclo %s cancelado. No se realizará limpieza.'):format(Config.ResourceName, token))
          cleanupState.active = false
        end
        return
      end
      cb()
    end)
  end

  schedule(0, function()
    broadcastAlert(Config.CountdownMessages['10m'])
  end)

  schedule(5 * 60 * 1000, function()
    broadcastAlert(Config.CountdownMessages['5m'])
  end)

  schedule(9 * 60 * 1000, function()
    broadcastAlert(Config.CountdownMessages['1m'])
  end)

  schedule(9 * 60 * 1000 + 20 * 1000, function()
    broadcastAlert(Config.CountdownMessages['40s'])
  end)

  schedule(9 * 60 * 1000 + 40 * 1000, function()
    broadcastAlert(Config.CountdownMessages['20s'])
  end)

  schedule(10 * 60 * 1000, function()
    broadcastAlert('Limpieza en curso...')

    cleanupState.expectedReports = #GetPlayers()
    cleanupState.reports = 0
    cleanupState.reportedPlayers = {}
    cleanupState.timerDone = false
    cleanupState.finalized = false

    local function finalize()
      if cleanupState.finalized then return end
      cleanupState.finalized = true
      cleanupState.active = false
      cleanupState.tryFinalize = nil
      cleanupServerVehicles({
        minDist = 0,
        skipEmergency = false,
        skipBA = false,
        blModels = {},
        blClasses = {}
      })
      print(('^2[%s]^7 Ciclo %s terminado.'):format(Config.ResourceName, token))
      broadcastAlert(Config.CleanupCompleteText, nil, Config.CleanupCompleteTitle)
    end

    cleanupState.tryFinalize = function()
      if cleanupState.timerDone and cleanupState.reports >= cleanupState.expectedReports then
        finalize()
      end
    end

    TriggerClientEvent('invictus_tow:client:doCleanup', -1, {
      minDist = 0,
      skipEmergency = false,
      skipBA = false,
      blModels = {},
      blClasses = {},
      debug = Config.Debug
    }, token)

    SetTimeout(Config.AlertDuration * 1000, function()
      cleanupState.timerDone = true
      if cleanupState.tryFinalize then cleanupState.tryFinalize() end
    end)
  end)
end

-- Recibir reporte de limpieza desde clientes
RegisterNetEvent('invictus_tow:server:report', function(token, deletedCount)
  if token ~= cleanupState.token then return end
  local src = source
  debugPrint(('Reporte de %s: borrados=%s'):format(src, deletedCount))
  if cleanupState.reportedPlayers and not cleanupState.reportedPlayers[src] then
    cleanupState.reportedPlayers[src] = true
    cleanupState.reports = (cleanupState.reports or 0) + 1
    if cleanupState.tryFinalize then cleanupState.tryFinalize() end
  end
end)

RegisterNetEvent('invictus_tow:server:deleteVehicle', function(netId, token)
  local src = source
  local veh = NetworkGetEntityFromNetworkId(netId)
  local success = false
  if DoesEntityExist(veh) then
    if isAnySeatOccupied(veh) then
      success = false
      if Config.Debug then
        debugPrint(('No se eliminó el vehículo %s: hay jugadores dentro'):format(netId))
      end
    else
      SetEntityAsMissionEntity(veh, true, true)
      DeleteEntity(veh)
      success = not DoesEntityExist(veh)
      if Config.Debug then
        debugPrint(('Vehículo %s eliminado por servidor'):format(netId))
      end
    end
  else
    if Config.Debug then
      debugPrint(('No se pudo eliminar el vehículo %s: no existe'):format(netId))
    end
  end
  TriggerClientEvent('invictus_tow:client:deleteResult', src, token, success)
end)

-- Cancelar ciclo
local function cancelCleanup(src)
  if not cleanupState.active then
    if src then TriggerClientEvent('chat:addMessage', src, { args = {'TOW', 'No hay una limpieza activa.'} }) end
    return
  end
  cleanupState.cancelled = true
  broadcastCancel()
  print(('^1[%s]^7 Limpieza CANCELADA por %s'):format(Config.ResourceName, src and ('player '..src) or 'server'))
end

-- Comando: cancelar
RegisterCommand(Config.CommandCancel, function(src)
  if src and src > 0 then
    if not IsPlayerAceAllowed(src, Config.AceCancel) then
      TriggerClientEvent('chat:addMessage', src, { args = {'TOW', '^1No tienes permiso para cancelar.'} })
      return
    end
  end
  cancelCleanup(src)
end)

-- Comando: disparar manualmente
RegisterCommand(Config.CommandTrigger, function(src)
  if src and src > 0 then
    if not IsPlayerAceAllowed(src, Config.AceTrigger) then
      TriggerClientEvent('chat:addMessage', src, { args = {'TOW', '^1No tienes permiso para ejecutar.'} })
      return
    end
  end
  startCleanupCycle(true)
end)

-- Limpieza inmediata sin avisos ni temporizadores
local function immediateCleanup()
  cleanupState.token = cleanupState.token + 1
  TriggerClientEvent('invictus_tow:client:doCleanup', -1, {
    minDist = 0,
    skipEmergency = false,
    skipBA = false,
    blModels = {},
    blClasses = {},
    debug = Config.Debug
  }, cleanupState.token)
  cleanupServerVehicles({
    minDist = 0,
    skipEmergency = false,
    skipBA = false,
    blModels = {},
    blClasses = {}
  })
  print(('^2[%s]^7 Limpieza inmediata ejecutada.'):format(Config.ResourceName))
end

-- Comando: limpieza inmediata
RegisterCommand(Config.CommandImmediate, function(src)
  if src and src > 0 then
    if not IsPlayerAceAllowed(src, Config.AceImmediate) then
      TriggerClientEvent('chat:addMessage', src, { args = {'TOW', '^1No tienes permiso para ejecutar.'} })
      return
    end
  end
  immediateCleanup()
end)

-- Bucle automático
CreateThread(function()
  Wait(2500)
  print(('^2[%s]^7 Cargado. Intervalo automático: %s min'):format(Config.ResourceName, tostring(Config.IntervalMinutes)))
  while true do
    local interval = tonumber(Config.IntervalMinutes) or 0
    if interval > 0 then
      startCleanupCycle(false)
      Wait(interval * 60 * 1000)
    else
      Wait(3000)
    end
  end
end)
