Config = Config or {}

-- Marca y UI
Config.Branding = Config.Branding or {
  Title = 'LatinLife RP',
  Logo = 'logo.png'
}

-- Permisos para abrir el panel/creador
Config.Permission = Config.Permission or {
  Mode = 'ACE', -- 'ACE' | 'JOB'
  Ace  = 'jobcreator.open',
  Job  = { name = 'god', grades = { ['boss'] = true } }
}

-- Interfaz/Interacciones in-world
Config.InteractionMode = Config.InteractionMode or 'target' -- 'target' | 'textui' | '3dtext'

Config.Integrations = Config.Integrations or {
  UseQbTarget     = true,
  UseOxTarget     = false,
  UseQbManagement = true,   -- fondos de sociedad; si no, fallback propio en DB
  UseQbInventory  = true,
  UseBossMenu     = true,
  HospitalReviveEvent = 'hospital:client:Revive',
}

-- ===== Multi‑trabajo =====
-- Si usas un recurso de multitrabajo, activa esta sección para integrarlo.
Config.MultiJob = Config.MultiJob or {
  Enabled  = true,               -- ponlo en false si no usas multitrabajo
  Resource = 'hz-multitrabajo',      -- nombre del recurso que expone exports (si aplica)
  -- Tabla OFFLINE opcional (si tu multitrabajo guarda asignaciones en BD)
  OfflineTable = {
    name = 'player_jobs',        -- tabla de tu recurso de multitrabajo
    columns = {                  -- mapea nombres de columnas
      citizen = 'citizenid',
      job     = 'name',
      grade   = 'grade'
    }
  },
  -- Patrones de nombres "fuera de servicio" para ignorar duplicados visuales
  OffDutyTags = { 'off', 'off_', 'off-' },
  -- Si quieres que al reclutar se ponga también como trabajo principal
  AssignAsPrimary = false
}

Config.JobActionsKey = Config.JobActionsKey or 'F6'

Config.Zone = Config.Zone or {
  DefaultRadius = 2.0,
  BlipSprite = 280,
  BlipColor  = 26,
  TextUIKey  = '[E]',
}

-- Plantilla de rangos
Config.DefaultGrades = Config.DefaultGrades or {
  ['0'] = { name = 'recluta',  label = 'Recluta',  payment = 0 },
  ['1'] = { name = 'oficial',  label = 'Oficial',  payment = 0 },
  ['2'] = { name = 'sargento', label = 'Sargento', payment = 0 },
  ['3'] = { name = 'boss',     label = 'Jefe',     isboss = true, payment = 0 },
}

-- Acciones habilitables
Config.PlayerActions = Config.PlayerActions or {
  search   = true,
  handcuff = true,
  drag     = true,
  carry    = true,
  tackle   = true,
  putinveh = true,
  outveh   = true,
  bill     = true,
  revive   = true,
  heal     = true,
}

Config.VehicleActions = Config.VehicleActions or {
  hijack  = true,
  repair  = true,
  clean   = true,
  impound = true,
}

Config.ZoneTypes = Config.ZoneTypes or {
  'blip','boss','stash','garage','crafting','cloakroom','shop','collect','spawner','sell','alarm','register','anim','music','teleport'
}

Config.CraftingRecipes = Config.CraftingRecipes or {
  bandage = { needs = { {item='cloth', qty=2} }, time = 3000 },
}
