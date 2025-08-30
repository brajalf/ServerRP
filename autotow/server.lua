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

-- Broadcast NUI alert a todos
local function broadcastAlert(duration)
  TriggerClientEvent('invictus_tow:client:showAlert', -1, {
    title = Config.AlertTitle,
    text = Config.AlertText,
    duration = duration or Config.AlertDuration,
    sound = Config.SoundEnabled,
    soundFile = Config.SoundFile
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

  broadcastAlert(Config.AlertDuration)

  SetTimeout(Config.AlertDuration * 1000, function()
    -- Si fue cancelado, notificar y salir
    if cleanupState.cancelled or token ~= cleanupState.token then
      print(('^2[%s]^7 Ciclo %s cancelado. No se realizará limpieza.'):format(Config.ResourceName, token))
      cleanupState.active = false
      return
    end

    -- Enviar a clientes a limpiar (lado cliente filtra y borra solo si son owners de la entidad)
    TriggerClientEvent('invictus_tow:client:doCleanup', -1, {
      minDist = Config.MinDistanceFromAnyPlayer,
      skipEmergency = Config.SkipEmergencyVehicles,
      skipBA = Config.SkipBoatsAndAircraft,
      blModels = Config.BlacklistedModels,
      blClasses = Config.BlacklistedClasses,
      debug = Config.Debug
    }, token)

    -- Por seguridad, cerrar el ciclo tras unos segundos (los clientes reportan conteo)
    SetTimeout(8000, function()
      cleanupState.active = false
      print(('^2[%s]^7 Ciclo %s terminado.'):format(Config.ResourceName, token))
    end)
  end)
end

-- Recibir reporte de limpieza desde clientes
RegisterNetEvent('invictus_tow:server:report', function(token, deletedCount)
  if token ~= cleanupState.token then return end
  local src = source
  debugPrint(('Reporte de %s: borrados=%s'):format(src, deletedCount))
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
