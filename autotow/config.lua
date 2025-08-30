Config = {}

-- Nombre del recurso (para logs y mensajes)
Config.ResourceName = 'LATINLIFE RP'

-- Intervalo de ejecución automática (en minutos).
-- Si lo pones en 0, desactiva la ejecución automática.
Config.IntervalMinutes = 30

-- Duración del aviso en pantalla antes de limpiar (en segundos)
Config.AlertDuration = 20

-- Distancia mínima a cualquier jugador para poder borrar un vehículo
Config.MinDistanceFromAnyPlayer = 10.0

-- Exclusiones / filtros
Config.SkipEmergencyVehicles = true      -- Clase 18
Config.SkipBoatsAndAircraft = true       -- 14=boats, 15=heli, 16=planes, 21=trains

-- Lista de modelos prohibidos para borrar
Config.BlacklistedModels = {
  `police`, `police2`, `police3`, `police4`, `policeb`, `policet`, `sheriff`, `sheriff2`,
}

-- Clases a omitir además de las de arriba (puedes añadir más)
Config.BlacklistedClasses = { 18 } -- emergencia

-- Comandos
Config.CommandCancel = 'towcancel'
Config.CommandTrigger = 'towtrigger' -- disparo manual

-- Permisos ACE (usa add_ace en server.cfg)
Config.AceCancel  = 'invictus.tow.cancel'
Config.AceTrigger = 'invictus.tow.trigger'

-- Mensajes de alerta
Config.AlertTitle  = 'LIMPIEZA DE VEHÍCULOS'
Config.AlertText   = 'Se eliminarán vehículos desocupados en breve.'
Config.CancelTitle = 'LIMPIEZA CANCELADA'
Config.CancelText  = 'Un administrador canceló la limpieza.'

-- Debug (muestra mensajes y toasts)
Config.Debug = false
