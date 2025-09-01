Config = {}

-- Nombre del recurso (para logs y mensajes)
Config.ResourceName = 'LATINLIFE RP'

-- Intervalo de ejecución automática (en minutos).
-- Si lo pones en 0, desactiva la ejecución automática.
Config.IntervalMinutes = 30

-- Duración del aviso en pantalla antes de limpiar (en segundos)
Config.AlertDuration = 20

-- Distancia mínima a cualquier jugador para poder borrar un vehículo
Config.MinDistanceFromAnyPlayer = 0

-- Distancia máxima para notificar a jugadores cercanos cuando el servidor elimina un vehículo
Config.RemoveNotifyRange = 300.0

-- Exclusiones / filtros
Config.SkipEmergencyVehicles = false     -- Clase 18
Config.SkipBoatsAndAircraft = false      -- 14=boats, 15=heli, 16=planes, 21=trains

-- Lista de modelos prohibidos para borrar
Config.BlacklistedModels = {}

-- Clases a omitir además de las de arriba (puedes añadir más)
Config.BlacklistedClasses = {}

-- Comandos
Config.CommandCancel = 'towcancel'
Config.CommandTrigger = 'towtrigger' -- disparo manual
Config.CommandImmediate = 'towclean' -- limpieza inmediata

-- Permisos ACE (usa add_ace en server.cfg)
Config.AceCancel  = 'invictus.tow.cancel'
Config.AceTrigger = 'invictus.tow.trigger'
Config.AceImmediate = 'invictus.tow.immediate'

-- Mensajes de alerta
Config.AlertTitle  = 'LIMPIEZA DE VEHÍCULOS'
Config.AlertText   = 'Se eliminarán vehículos desocupados en breve.'
Config.CancelTitle = 'LIMPIEZA CANCELADA'
Config.CancelText  = 'Un administrador canceló la limpieza.'

-- Mensaje al completar la limpieza
Config.CleanupCompleteTitle = 'LIMPIEZA COMPLETA'
Config.CleanupCompleteText  = 'La grúa pasó y las calles fueron limpiadas.'

-- Mensajes escalonados de advertencia antes de la limpieza
Config.CountdownMessages = {
  ['10m'] = 'Se eliminarán vehículos desocupados en 10 minutos.',
  ['5m']  = 'Se eliminarán vehículos desocupados en 5 minutos.',
  ['1m']  = 'Se eliminarán vehículos desocupados en 1 minuto.',
  ['40s'] = 'Se eliminarán vehículos desocupados en 40 segundos.',
  ['20s'] = 'Se eliminarán vehículos desocupados en 20 segundos.'
}

-- Debug (muestra mensajes y toasts)
Config.Debug = false
