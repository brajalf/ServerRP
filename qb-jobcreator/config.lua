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
  UseQbManagement = false,   -- fondos de sociedad; si no, fallback propio en DB
  UseQbInventory  = false,
  UseOxInventory  = false,
  UseBossMenu     = true,
  -- Eventos de hospital. Ajusta los nombres según el script que uses
  -- qb-ambulancejob (por defecto):
  --   Revivir -> 'hospital:client:Revive'
  --   Curar   -> 'hospital:client:TreatWounds'
  -- esx_ambulancejob:
  --   Revivir -> 'esx_ambulancejob:revive'
  --   Curar   -> 'esx_ambulancejob:treat'
  HospitalReviveEvent = 'ars_ambulancejob:healPlayer',
  HospitalHealEvent   = 'ars_ambulancejob:healPlayer',
  -- Recursos a verificar antes de disparar los eventos
  HospitalResources   = { 'ars_ambulancejob' },
}

-- ===== Multi‑trabajo =====
-- Si usas un recurso de multitrabajo, activa esta sección para integrarlo.
Config.MultiJob = Config.MultiJob or {
  Enabled  = true,               -- ponlo en false si no usas multitrabajo
  Resource = 'ec-multijob',
  OpenCommand = 'multijob',-- nombre del recurso que expone exports (si aplica)
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
  ClearArea  = false,
  ClearRadius = 30.0,
}

-- Plantilla de rangos (puedes añadir más entradas si lo necesitas)
Config.DefaultGrades = Config.DefaultGrades or {}
Config.DefaultGrades['0'] = Config.DefaultGrades['0'] or { name = 'recluta',  label = 'Recluta',  payment = 0 }
Config.DefaultGrades['1'] = Config.DefaultGrades['1'] or { name = 'oficial',  label = 'Oficial',  payment = 0 }
Config.DefaultGrades['2'] = Config.DefaultGrades['2'] or { name = 'sargento', label = 'Sargento', payment = 0 }
Config.DefaultGrades['3'] = Config.DefaultGrades['3'] or { name = 'boss',     label = 'Jefe',     isboss = true, payment = 0 }

-- Acciones habilitables
Config.PlayerActionsDefaults = Config.PlayerActionsDefaults or {
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
  bandage = {
    inputs = { { item = 'cloth', amount = 2 } },
    time   = 3000,
    blueprint = nil,
    skill = nil,
    successChance = 100,
    output = { item = 'bandage', amount = 1 }
  },
  lockpick = {
    inputs = {
      { item = 'metalscrap', amount = 2 },
      { item = 'plastic',    amount = 1 }
    },
    time   = 5000,
    blueprint = nil,
    skill = nil,
    successChance = 100,
    output = { item = 'lockpick', amount = 1 }
  },
  repairkit = {
    inputs = {
      { item = 'metalscrap', amount = 4 },
      { item = 'steel',      amount = 2 },
      { item = 'plastic',    amount = 1 }
    },
    time   = 8000,
    blueprint = nil,
    skill = nil,
    successChance = 100,
    output = { item = 'repairkit', amount = 1 }
  },
}

-- Integración de garajes
Config.Garages = {
  Command       = nil,       -- usa /car <modelo> (pon nil si no quieres comando)
  UseQbGarages  = true,       -- true si prefieres qb-garages
  QbResource    = 'qb-garages',
  SpawnEvent    = nil,         -- si tu fork expone un evento de spawn (server)
}

Config.PlayerActionsByJob = Config.PlayerActionsByJob or {
  police    = { 'cuff', 'escort', 'putinveh', 'takeout', 'bill' },
  ambulance = { 'revive', 'heal' },
  mechanic  = { 'repair', 'clean', 'impound' },
}
