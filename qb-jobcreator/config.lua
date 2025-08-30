Config = Config or {}

-- Inventario y notificaciones
Config.InventoryType = Config.InventoryType or 'qb'        -- 'qb', 'ox', 'tgiann', 'custom'
Config.InventoryImagePath = Config.InventoryImagePath or 'nui://qb-inventory/html/images/'
Config.NotifySystem = Config.NotifySystem or 'qb'          -- 'qb', 'ox', 'custom'
Config.NotifyTitle = Config.NotifyTitle or 'Job Creator'

-- ===== GENERAL CONFIGURATION / CONFIGURACIÓN GENERAL =====
Config.General = Config.General or {
  MaxQueueSize      = 25,  -- Longitud máxima de la cola de crafteo / Maximum crafting queue length
  MaxItemsPerPlayer = 5,   -- Máx. ítems en cola por jugador / Max items in queue per player
  Language          = 'es' -- Idioma del sistema ('es','en',...) / System language
}

-- ===== INTERFACE CONFIGURATION / CONFIGURACIÓN DE INTERFAZ =====
Config.Interface = Config.Interface or {
  InventoryImagePath = 'html/images', -- Ruta a imágenes del inventario / Path to inventory images
}

-- ===== INVENTORY SYSTEM CONFIGURATION / CONFIGURACIÓN DEL SISTEMA DE INVENTARIO =====
Config.InventorySystem = Config.InventorySystem or {
  InventoryType = 'qb', -- Tipo de inventario usado ('qb','ox','custom') / Inventory type in use
}

-- ===== SKILL SYSTEM / SISTEMA DE HABILIDADES =====
Config.SkillSystem = Config.SkillSystem or {
  DevSkillTree = false, -- Habilitar árbol de habilidades de desarrollo / Enable development skill tree
  SkillCategories = {   -- Categorías base de habilidades / Base skill categories
    crafting = { label = 'Crafting' }, -- Habilidad de fabricación / Crafting skill
    medical  = { label = 'Medical' }   -- Habilidad médica / Medical skill
  }
}

-- ===== LOCKED ITEMS DISPLAY / VISUALIZACIÓN DE ÍTEMS BLOQUEADOS =====
Config.LockedItemsDisplay = Config.LockedItemsDisplay or {
  showLocked   = true,       -- Mostrar ítems bloqueados / Show locked items
  showLockIcon = true,       -- Mostrar icono de candado / Display lock icon
  lockIcon     = 'lock.png', -- Ruta del icono de candado / Lock icon path
  lockColor    = '#FF0000',  -- Color del icono / Lock icon color
  lockLabel    = 'Bloqueado' -- Texto de bloqueo / Locked label
}

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
  Debug = false,
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

-- ===== JOB COLORS / COLORES DE TRABAJO =====
Config.JobColors = Config.JobColors or {
  police    = { r = 0,   g = 0,   b = 255 }, -- Policía en azul / Police shown as blue
  ambulance = { r = 255, g = 0,   b = 0   }, -- Ambulancia en rojo / Ambulance shown as red
  mechanic  = { r = 255, g = 165, b = 0   }  -- Mecánico en naranja / Mechanic shown as orange
}

-- ===== CRAFTING TABLES / MESAS DE FABRICACIÓN =====
Config.CraftingTables = Config.CraftingTables or {
  workshop = {                                  -- ID de la mesa / Table ID
    coords = vector3(0.0, 0.0, 0.0),            -- Coordenadas / Coordinates
    jobs   = { 'mechanic' },                    -- Trabajos permitidos / Allowed jobs
    radius = 2.0                                -- Radio de interacción / Interaction radius
  }
}

-- ===== CRAFTABLE ITEMS / OBJETOS CRAFTEABLES =====
Config.CraftableItems = Config.CraftableItems or {
  bandage = {
    table  = 'workshop',                         -- Mesa requerida / Required table
    time   = 3000,                               -- Tiempo en ms / Time in ms
    inputs = { { item = 'cloth', amount = 2 } }, -- Materiales necesarios / Required materials
    output = { item = 'bandage', amount = 1 }    -- Resultado / Result item
  },
  repairkit = {
    table  = 'workshop',
    time   = 8000,
    inputs = {
      { item = 'metalscrap', amount = 4 },
      { item = 'steel',      amount = 2 },
      { item = 'plastic',    amount = 1 }
    },
    output = { item = 'repairkit', amount = 1 }
  }
}
Config.CraftingRecipes = Config.CraftableItems -- Compatibilidad / Compatibility

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
