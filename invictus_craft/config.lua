Config = {}

-- ======================================
-- GENERAL
-- ======================================
Config.Debug                = false
Config.MaxQueueSize         = 6
Config.MaxItemsPerPlayer    = 20
Config.language             = 'es'   -- 'es','en','pt','fr','de','it'

-- ======================================
-- INVENTARIO + RUTAS DE IMÁGENES
-- ======================================
Config.InventoryType        = 'ox'   -- 'ox' o 'qb'
Config.InventoryImagePath   = 'nui://ox_inventory/web/images/'

-- ======================================
-- TARGET / INTERACCIÓN
-- ======================================
-- 'qb' => qb-target, 'ox' => ox_target, 'textui' => tecla E
Config.InteractionType      = 'qb'
Config.OpenKey              = 'E'

-- ======================================
-- NOTIFY
-- ======================================
Config.NotifySystem         = 'ox'   -- 'ox','qb','custom'
Config.NotifyTitle          = 'Invictus Craft'

-- ======================================
-- SKILL TREE (opcional)
-- ======================================
Config.DevSkillTree         = true
Config.SkillCategories      = { 'personal', 'items' }

Config.LockedItemsDisplay = {
  showLocked          = true,
  showLockIcon        = true,
  reducedOpacity      = 0.65,
  grayscale           = 100,
  disableCraftButton  = true
}

Config.JobColors = {
  ['ambulance'] = '#ff3b30',
  ['police']    = '#0a84ff',
  ['mechanic']  = '#ff9f0a',
  ['default']   = '#ffffff'
}

-- ======================================
-- ESTACIONES (ZONAS) DE CRAFTEO (solo zonas, sin props)
-- ======================================
-- Las estaciones se gestionan desde qb-jobcreator
Config.Stations = {}

-- ======================================
-- RECETAS
-- ======================================
Config.Recipes = {
  {
    item = 'armor_upgrade',
    label = 'Bulletproof Vest Upgrade',
    time = 15,
    category = 'weapons',
    requiredJob = 'mechanic',
    skillIID = 'armorer',
    materials = {
      { item = 'kevlar_fabric', amount = 5 },
      { item = 'metal_plate', amount = 2 },
      { item = 'crafting_tools', amount = 1, noConsume = true }
    },
    outputs = {
      { item = 'armor_upgrade', amount = 1 },
      { item = 'armor_scraps', amount = 3 }
    }
  },

  {
    item = 'carne_cocinada', label = 'Carne Cocinada', time = 5,
    category = 'food', requiredJob = nil,
    materials = { { item = 'carne_cruda', amount = 1 } },
    outputs   = { { item = 'carne_cocinada', amount = 1 } }
  },
  {
    item = 'queso', label = 'Queso', time = 5,
    category = 'food', requiredJob = nil,
    materials = { { item = 'leche', amount = 1 } },
    outputs   = { { item = 'queso', amount = 1 } }
  },
  {
    item = 'crema', label = 'Crema', time = 5,
    category = 'food', requiredJob = nil,
    materials = { { item = 'leche', amount = 2 } },
    outputs   = { { item = 'crema', amount = 1 } }
  },
  {
    item = 'agua_de_uva', label = 'Agua de Uva', time = 3,
    category = 'food', requiredJob = nil, skillIID = 'agua_de_uva',
    materials = {
      { item = 'clean_glass', amount = 1 },
      { item = 'botella_con_agua_hervida', amount = 1 },
      { item = 'green_grape', amount = 3 }
    },
    outputs = { { item = 'agua_de_uva', amount = 5 } }
  }
}
