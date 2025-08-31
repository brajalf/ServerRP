local DB = _G.DB
QBCore = exports['qb-core']:GetCoreObject()
local JobsFile = _G.JobsFile

local Runtime = { Jobs = {}, Zones = {} }
local _lastCreate = {}
local CreatedStashes = {}
-- Crafting queues and ready outputs
local Queues, Ready = {}, {}
local findZoneById
local playerInJobZone

local function SanitizeShopItems(items)
  local list = {}
  if type(items) ~= 'table' then return list end
  for _, it in ipairs(items) do
    if type(it) == 'table' and type(it.name) == 'string' and it.name ~= '' then
      local name = it.name:lower()
      local price = math.floor(tonumber(it.price) or 0)
      local amount = math.floor(tonumber(it.amount or it.count or 1) or 1)
      price = math.max(price, 0)
      amount = math.max(amount, 1)
      if price > 0 and amount > 0 then
        local info = type(it.info) == 'table' and it.info or nil
        list[#list+1] = { name = name, price = price, amount = amount, info = info }
      end
    end
  end
  return list
end

local function SanitizeRecipeList(recipes)
  local list = {}
  if type(recipes) ~= 'table' then return list end
  for _, name in ipairs(recipes) do
    if type(name) == 'string' and Config.CraftingRecipes[name] then
      list[#list+1] = name
    end
  end
  return list
end

local function SanitizeCategoryList(categories)
  local list = {}
  if type(categories) ~= 'table' then return list end
  local valid = {}
  for _, r in pairs(Config.CraftingRecipes or {}) do
    if r.category then valid[r.category] = true end
  end
  for _, cat in ipairs(categories) do
    if type(cat) == 'string' and valid[cat] then
      list[#list+1] = cat
    end
  end
  return list
end

local function ApplyBlipInfo(data, zone)
  data = data or {}
  if zone then
    local s = tonumber(zone.sprite); if s then data.sprite = s end
    local c = tonumber(zone.color);  if c then data.color  = c end
    if type(zone.ytdDict) == 'string' and zone.ytdDict ~= '' then data.ytdDict = zone.ytdDict end
    if type(zone.ytdName) == 'string' and zone.ytdName ~= '' then data.ytdName = zone.ytdName end
  end
  return data
end

local function ExtractBlipInfo(data, zone)
  if type(data) ~= 'table' or type(zone) ~= 'table' then return end
  zone.sprite  = tonumber(data.sprite)
  zone.color   = tonumber(data.color)
  zone.ytdDict = (type(data.ytdDict) == 'string' and data.ytdDict ~= '') and data.ytdDict or nil
  zone.ytdName = (type(data.ytdName) == 'string' and data.ytdName ~= '') and data.ytdName or nil
  data.sprite, data.color, data.ytdDict, data.ytdName = nil, nil, nil, nil
end

-- ===== Validations =====
local function IsAlphaNum(str)
  return type(str) == 'string' and str:match('^%w+$') ~= nil
end

local function ValidateJobData(data)
  if type(data) ~= 'table' then return false, 'Datos inválidos' end
  local name = data.name or ''
  if not IsAlphaNum(name) then return false, 'Nombre de trabajo inválido' end
  return true
end

local function ValidateGradeData(gradeKey, data)
  if not tostring(gradeKey):match('^%w+$') then return false, 'Clave de rango inválida' end
  if type(data) == 'table' then
    if data.name and not IsAlphaNum(data.name) then return false, 'Nombre de rango inválido' end
    local pay = tonumber(data.payment) or 0
    if pay < 0 then return false, 'Pago inválido' end
  end
  return true
end

local function IsValidZoneType(ztype)
  if type(ztype) ~= 'string' then return false end
  for _, t in ipairs(Config.ZoneTypes or {}) do
    if t == ztype then return true end
  end
  return false
end

local function ValidateZoneData(zone)
  if type(zone) ~= 'table' then return false, 'Datos de zona inválidos' end
  if not IsAlphaNum(zone.job or '') then return false, 'Trabajo inválido' end
  if not IsValidZoneType(zone.ztype) then return false, 'Tipo de zona inválido' end
  local c = zone.coords or {}
  if tonumber(c.x) == nil or tonumber(c.y) == nil or tonumber(c.z) == nil then
    return false, 'Coordenadas inválidas'
  end
  local r = tonumber(zone.radius)
  if not r or r <= 0 then return false, 'Radio debe ser mayor a 0' end
  local i = zone.data and zone.data.interaction
  if i ~= nil then
    if type(i) ~= 'string' then return false, 'Interacción inválida' end
    if i ~= 'target' and i ~= 'textui' and i ~= '3dtext' then return false, 'Interacción inválida' end
  end
  return true
end

-- ===== Helpers =====
local function InjectJobToCore(job)
  QBCore.Shared.Jobs[job.name] = {
    label = job.label,
    type = job.type or 'generic',
    defaultDuty = job.defaultDuty ~= false,
    offDutyPay = job.offDutyPay == true,
    whitelisted = job.whitelisted or false,
    grades = job.grades or {}
  }
end

local function MultiAvailable()
  return Config.MultiJob and Config.MultiJob.Enabled and Config.MultiJob.Resource and GetResourceState(Config.MultiJob.Resource) == 'started'
end
local function Multi_Add(citizenid, job, grade)
  if MultiAvailable() then
    local ok = pcall(function()
      local r = exports[Config.MultiJob.Resource]
      if r.AddJob then r.AddJob(citizenid, job, grade) elseif r.addJob then r.addJob(citizenid, job, grade) end
    end)
    if ok then return end
  end
  if DB.UpsertMultiJob then DB.UpsertMultiJob(citizenid, job, grade) end
end
local function Multi_Remove(citizenid, job)
  if MultiAvailable() then
    local ok = pcall(function()
      local r = exports[Config.MultiJob.Resource]
      if r.RemoveJob then r.RemoveJob(citizenid, job) elseif r.removeJob then r.removeJob(citizenid, job) end
    end)
    if ok then return end
  end
  if DB.DeleteMultiJob then DB.DeleteMultiJob(citizenid, job) end
end
local function Multi_SetGrade(citizenid, job, grade)
  if MultiAvailable() then
    local ok = pcall(function()
      local r = exports[Config.MultiJob.Resource]
      if r.SetGrade then r.SetGrade(citizenid, job, grade) elseif r.UpdateJob then r.UpdateJob(citizenid, job, grade) end
    end)
    if ok then return end
  end
  if DB.UpdateMultiJobGrade then DB.UpdateMultiJobGrade(citizenid, job, grade) end
end
local function Multi_Has(citizenid, job)
  if MultiAvailable() then
    local ok, has = pcall(function()
      local r = exports[Config.MultiJob.Resource]
      if r.HasJob then return r.HasJob(citizenid, job) elseif r.hasJob then return r.hasJob(citizenid, job) end
      return false
    end)
    if ok then return has end
  end
  return false
end

local function jobMatches(spec, job)
  if not spec or not job then return false end
  if type(spec) == 'string' then
    return spec == job
  elseif type(spec) == 'table' then
    if spec[job] then return true end
    for _, j in ipairs(spec) do if j == job then return true end end
  end
  return false
end

local function checkRecipeJob(recipeJob, zoneJob, playerJob)
  if not recipeJob then return true, false end
  if jobMatches(recipeJob, zoneJob) or jobMatches(recipeJob, playerJob) then
    return true, false
  end
  return false, true
end

playerInJobZone = function(src, zone, ztype)
  if not zone or (ztype and zone.ztype ~= ztype) then return false end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData then return false end
  local jd = Player.PlayerData.job or {}
  local cid = Player.PlayerData.citizenid
  if jd.name ~= zone.job and not Multi_Has(cid, zone.job) then
    TriggerClientEvent('QBCore:Notify', src, 'No tienes acceso a esta tienda.', 'error')
    return false
  end
  local coords = GetEntityCoords(GetPlayerPed(src))
  local dist = #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
  if dist > (zone.radius or 2.0) + 0.1 then
    TriggerClientEvent('QBCore:Notify', src, 'Acércate más a la zona para abrir la tienda.', 'error')
    return false
  end
  return true, zone, Player
end

-- ===== Permisos genéricos (admin/ACE) =====
-- Usa la función HasOpenPermission global de shared/sh_utils.lua

-- ===== Permiso admin O boss del job =====
local function allowAdminOrBoss(src, job)
  if HasOpenPermission(src) then return true end
  local P = QBCore.Functions.GetPlayer(src); if not P or not P.PlayerData then return false end
  local jd = P.PlayerData.job or {}
  local isboss = (jd.isboss == true) or (jd.grade and jd.grade.isboss == true)
  return (jd.name == job) and isboss
end

-- ===== Carga =====
local function LoadAll()
  Runtime.Jobs, Runtime.Zones = {}, {}
  for _, r in ipairs(DB.GetJobs()) do
    local j = {
      name = r.name, label = r.label, type = r.type, whitelisted = r.whitelisted == 1,
      grades = json.decode(r.grades or '{}') or {},
      actions = json.decode(r.actions or '{}') or {}
    }
    Runtime.Jobs[j.name] = j
    InjectJobToCore(j)
  end
  for _, z in ipairs(DB.GetZones()) do
    local data = json.decode(z.data or '{}') or {}
    if z.ztype == 'shop' then data.items = SanitizeShopItems(data.items)
    elseif z.ztype == 'crafting' then
      data.allowedCategories = SanitizeCategoryList(data.allowedCategories)
      data.recipes = SanitizeRecipeList(data.recipes)
      if type(data.job) ~= 'string' and type(data.job) ~= 'table' then data.job = nil end
      data.icon = type(data.icon) == 'string' and data.icon or nil
      if type(data.theme) == 'table' then
        data.theme = {
          colorPrimario = type(data.theme.colorPrimario) == 'string' and data.theme.colorPrimario or nil,
          colorPrimarioAlt = type(data.theme.colorPrimarioAlt) == 'string' and data.theme.colorPrimarioAlt or nil,
          colorSecundario = type(data.theme.colorSecundario) == 'string' and data.theme.colorSecundario or nil,
          colorSecundarioAlt = type(data.theme.colorSecundarioAlt) == 'string' and data.theme.colorSecundarioAlt or nil,
          titulo = type(data.theme.titulo) == 'string' and data.theme.titulo or nil,
        }
      else
        data.theme = nil
      end
    end
    local coords = json.decode(z.coords or '{}') or {}
    local zone = {
      id = z.id, job = z.job, ztype = z.ztype, label = z.label,
      coords = coords, radius = z.radius or 2.0,
      data = data
    }
    ExtractBlipInfo(data, zone)
    Runtime.Zones[#Runtime.Zones+1] = zone
    print(('[qb-jobcreator] Loaded zone id=%s type=%s job=%s radius=%s'):format(
      tostring(zone.id), tostring(zone.ztype), tostring(zone.job), tostring(zone.radius)))
    if z.ztype == 'music' then
      local name = (data and (data.name or data.djName)) or ('jc_ms_'..z.job..'_'..z.id)
      local range = tonumber(data and (data.range or data.distance)) or 20.0
      TriggerEvent('myDj:addZone', {
        name = name,
        pos = vector3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0),
        range = range,
        requiredJob = z.job
      })
    end
  end
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
  print(('[qb-jobcreator] Enviando %d zonas al cliente'):format(#Runtime.Zones))
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
end

AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  DB.EnsureSchema()
  local existing = DB.GetJobs()
  if not existing or #existing == 0 then
    local jobs = JobsFile.Load()
    for name, job in pairs(jobs) do
      job.name = name
      DB.SaveJob(job)
      InjectJobToCore(job)
    end
  end
  LoadAll()
end)

exports('GetZones', function()
  return Runtime.Zones
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
  local src = Player and Player.PlayerData and Player.PlayerData.source
  if not src then return end
  TriggerClientEvent('qb-jobcreator:client:syncAll', src, Runtime.Jobs, Runtime.Zones)
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', src, Runtime.Zones)
end)

-- Verifica permisos de administrador o jefe del trabajo especificado
local function ensurePerm(src, job)
  -- primero, permisos globales
  if HasOpenPermission(src) then return true end
  -- si se proporciona job, verificar si el jugador es jefe de ese trabajo
  if job then
    local P = QBCore.Functions.GetPlayer(src)
    if P and P.PlayerData and P.PlayerData.job then
      local jd = P.PlayerData.job
      local isBoss = (jd.name == job) and (jd.isboss or (jd.grade and jd.grade.isboss))
      if isBoss then return true end
    end
  end
  TriggerClientEvent('QBCore:Notify', src, _L('not_allowed'), 'error')
  return false
end

-- util: normaliza nombre de trabajo
local function _job(n) return (tostring(n or '')):lower() end

-- util: ¿tiene acceso de boss a ese trabajo?
local function _isBossOf(job, P)
  if not P or not P.PlayerData then return false end
  local jd  = P.PlayerData.job or {}
  local jn  = _job(jd.name)
  local tgt = _job(job)

  -- admin/ACE: también dejar pasar
  if HasOpenPermission and HasOpenPermission(P.PlayerData.source) then return true end

  if jn ~= tgt then return false end

  -- formatos posibles de QBCore
  if jd.isboss == true then return true end
  if type(jd.grade) == 'table' then
    if jd.grade.isboss == true then return true end
  elseif tonumber(jd.grade) then
    -- si guardas grades en Runtime, mira bandera isboss ahí también
    local def = Runtime and Runtime.Jobs and Runtime.Jobs[tgt] and Runtime.Jobs[tgt].grades
    local g   = def and def[tostring(jd.grade)]
    if g and g.isboss then return true end
  end
  return false
end

-- Apertura del panel del jefe desde la zona boss
RegisterNetEvent('qb-jobcreator:server:openBossPanel', function(job)
  local src = source
  if not src or src <= 0 then
    -- si esto se dispara sin jugador (ej. desde consola), evita el crash de TriggerClientEvent
    print('[qb-jobcreator] openBossPanel ignorado: source inválido', src)
    return
  end

  local P = QBCore.Functions.GetPlayer(src)
  if not _isBossOf(job, P) then
    TriggerClientEvent('QBCore:Notify', src, 'No tienes acceso de jefe a este trabajo.', 'error')
    return
  end

  -- abre la UI del boss (el cliente pedirá el dashboard y aplicará scope= boss)
  TriggerClientEvent('qb-jobcreator:client:openBossUI', src, job)
end)


QBCore.Commands.Add('jobcreator', _L('open_creator'), {}, false, function(src)
  if not ensurePerm(src) then return end
  TriggerClientEvent('qb-jobcreator:client:openUI', src)
end)

-- ===== Exportar trabajos =====
QBCore.Functions.CreateCallback('qb-jobcreator:server:exportJobs', function(src, cb)
  if not ensurePerm(src) then return cb(false) end
  cb(JobsFile.Export())
end)

-- ===== Dashboard =====
QBCore.Functions.CreateCallback('qb-jobcreator:server:getDashboard', function(src, cb)
  local ok, result = pcall(function()
    local totals = { jobs = 0, employees = 0, money = 0 }
    local popular, types = {}, {}
    for jobName, job in pairs(Runtime.Jobs or {}) do
      totals.jobs = totals.jobs + 1
      local count = 0
      for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
        local jd = Player.PlayerData.job
        if jd and jd.name == jobName then count = count + 1 end
      end
      popular[#popular+1] = { name = job.label or jobName, count = count }
      local jt = job.type or 'generic'
      types[jt] = (types[jt] or 0) + count

      local bal = 0
      if Config.Integrations.UseQbManagement and GetResourceState('qb-management') == 'started' then
        local ok2, val = pcall(function() return exports['qb-management']:GetAccount(jobName) end)
        bal = (ok2 and type(val)=='number') and val or (DB.GetAccount(jobName) or 0)
      else
        bal = DB.GetAccount(jobName) or 0
      end
      totals.employees = totals.employees + count
      totals.money = totals.money + (bal or 0)
    end
    table.sort(popular, function(a,b) return (a.count or 0) > (b.count or 0) end)
    local top = {}
    for i=1, math.min(5, #popular) do top[#top+1] = popular[i] end
    local activity = DB.GetActivityCounts and DB.GetActivityCounts() or { day = 0, week = 0 }
    return { ok = true, branding = Config.Branding, jobs = Runtime.Jobs or {}, zones = Runtime.Zones or {}, totals = totals, popular = top, types = types, activity = activity }
  end)
  if not ok then
    print('[qb-jobcreator] getDashboard error: '..tostring(result))
    cb({ ok = true, branding = Config.Branding, jobs = Runtime.Jobs or {}, zones = Runtime.Zones or {}, totals = { jobs = 0, employees = 0, money = 0 }, popular = {}, types = {}, activity = { day = 0, week = 0 } })
  else cb(result) end
end)

-- ===== CRUD de trabajos =====
RegisterNetEvent('qb-jobcreator:server:createJob', function(data)
  local src = source; if not ensurePerm(src) then return end
  local ok, err = ValidateJobData(data)
  if not ok then TriggerClientEvent('QBCore:Notify', src, err, 'error'); return end
  local name = string.lower((data.name or ''):gsub('%s+',''))
  local job = {
    name = name,
    label = data.label or 'Trabajo',
    type = data.type or 'generic',
    defaultDuty = data.defaultDuty ~= false,
    offDutyPay = data.offDutyPay == true,
    whitelisted = data.whitelisted or false,
    grades = next(data.grades or {}) and data.grades or Config.DefaultGrades,
    actions = {
      defaults = Config.PlayerActionsDefaults,
      player   = Config.PlayerActionsByJob[name] or {},
      vehicle  = Config.VehicleActions
    }
  }
  if job.name == '' then return end
  Runtime.Jobs[job.name] = job
  DB.SaveJob(job)
  InjectJobToCore(job)
  JobsFile.Save()
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:deleteJob', function(name)
  local src = source; if not ensurePerm(src) then return end
  Runtime.Jobs[name] = nil
  QBCore.Shared.Jobs[name] = nil
  DB.DeleteJob(name)
  JobsFile.Save()
  local zones = {}
  for _, z in ipairs(Runtime.Zones) do
    if z.job ~= name then zones[#zones+1] = z end
  end
  Runtime.Zones = zones
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:duplicateJob', function(name, newName)
  local src = source; if not ensurePerm(src) then return end
  local j = Runtime.Jobs[name]; if not j then return end
  local copy = json.decode(json.encode(j)); copy.name = newName; copy.label = copy.label .. ' (Copia)'
  Runtime.Jobs[newName] = copy; DB.SaveJob(copy); InjectJobToCore(copy); JobsFile.Save()
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:addGrade', function(jobName, gradeKey, data)
  local src = source; if not ensurePerm(src) then return end
  local j = Runtime.Jobs[jobName]; if not j then return end
  local ok, err = ValidateGradeData(gradeKey, data)
  if not ok then TriggerClientEvent('QBCore:Notify', src, err, 'error'); return end
  j.grades = j.grades or {}
  local k = tostring(gradeKey)
  j.grades[k] = {
    name = data and data.name or k,
    label = data and data.label or (data and data.name) or k,
    payment = tonumber(data and data.payment) or 0,
    isboss = data and (data.isboss == true) or false
  }
  DB.SaveJob(j); InjectJobToCore(j); JobsFile.Save()
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:updateGrade', function(jobName, gradeKey, data)
  local src = source; if not ensurePerm(src) then return end
  local j = Runtime.Jobs[jobName]; if not j then return end
  local g = j.grades and j.grades[tostring(gradeKey)]; if not g then return end
  if data then
    if data.label ~= nil then g.label = data.label end
    if data.name  ~= nil then g.name  = data.name end
    if data.payment ~= nil then g.payment = tonumber(data.payment) or 0 end
    if data.isboss ~= nil then g.isboss = data.isboss == true end
  end
  DB.SaveJob(j); InjectJobToCore(j); JobsFile.Save()
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:deleteGrade', function(jobName, gradeKey)
  local src = source; if not ensurePerm(src) then return end
  local j = Runtime.Jobs[jobName]; if not j then return end
  if j.grades then j.grades[tostring(gradeKey)] = nil end
  DB.SaveJob(j); InjectJobToCore(j); JobsFile.Save()
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

-- ===== Zonas =====
QBCore.Functions.CreateCallback('qb-jobcreator:server:getZones', function(src, cb, job)
  if not allowAdminOrBoss(src, job) then return cb({}) end
  local list = {}
  for _, z in ipairs(Runtime.Zones or {}) do if z.job == job then list[#list+1] = z end end
  cb(list)
end)

local function CollectCraftingData(src, zoneId)
  local Player = QBCore.Functions.GetPlayer(src)
  local jobName = Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name
  local showLocked = Config.LockedItemsDisplay and Config.LockedItemsDisplay.showLocked

  local function fmt(name, recipe)
    return {
      name = name,
      inputs = recipe.inputs or {},
      time = recipe.time or 0,
      output = recipe.output,
      category = recipe.category,
      blueprint = recipe.blueprint,
      job = recipe.job
    }
  end

  if zoneId then
    local ok, zone = playerInJobZone(src, findZoneById(zoneId), 'crafting')
    if not ok then return {} end

    local list = {}
    local data = zone.data or {}
    local cats = data.allowedCategories
    local recs = data.recipes
    if cats and #cats > 0 then
      local set = {}
      for _, c in ipairs(cats) do set[c] = true end
      for name, r in pairs(Config.CraftingRecipes or {}) do
        if r.category and set[r.category] then
          local allow, locked = checkRecipeJob(r.job, zone.job, jobName)
          if allow or (locked and showLocked) then
            local t = fmt(name, r)
            if locked then t.lockedByJob = true end
            list[#list + 1] = t
          end
        end
      end
    else
      for _, name in ipairs(recs or {}) do
        local r = Config.CraftingRecipes[name]
        if r then
          local allow, locked = checkRecipeJob(r.job, zone.job, jobName)
          if allow or (locked and showLocked) then
            local t = fmt(name, r)
            if locked then t.lockedByJob = true end
            list[#list + 1] = t
          end
        end
      end
    end
    return list
  end

  local all = {}
  for name, r in pairs(Config.CraftingRecipes or {}) do
    local allow, locked = checkRecipeJob(r.job, nil, jobName)
    if allow or (locked and showLocked) then
      local t = fmt(name, r)
      if locked then t.lockedByJob = true end
      all[#all + 1] = t
    end
  end
  return all
end

QBCore.Functions.CreateCallback('qb-jobcreator:server:getCraftingData', function(src, cb, zoneId)
  cb(CollectCraftingData(src, zoneId))
end)

QBCore.Functions.CreateCallback('qb-jobcreator:server:getCraftingTable', function(src, cb, zoneId)
  cb(CollectCraftingData(src, zoneId))
end)

RegisterNetEvent('qb-jobcreator:server:createZone', function(zone)
  local src = source; if not ensurePerm(src) then return end
  -- firma simple para detectar doble envío
  local sig = string.format('%s|%s|%0.2f|%0.2f|%s',
    zone.job or '', zone.ztype or '',
    (zone.coords and zone.coords.x) or 0.0,
    (zone.coords and zone.coords.y) or 0.0,
    zone.label or '')
  local now = GetGameTimer()
  local prev = _lastCreate[src]
  if prev and prev.sig == sig and (now - prev.t) < 1200 then
    print('[qb-jobcreator] duplicate createZone ignored for '..src)
    return
  end
  _lastCreate[src] = { sig = sig, t = now }
  local ok, err = ValidateZoneData(zone)
  if not ok then TriggerClientEvent('QBCore:Notify', src, err, 'error'); return end
  zone.data = zone.data or {}
  if zone.data then
    zone.data.clearArea = zone.data.clearArea and true or false
    if zone.data.clearRadius ~= nil then
      zone.data.clearRadius = tonumber(zone.data.clearRadius) or Config.Zone.ClearRadius
    end
    local inter = zone.data.interaction
    if inter == 'target' or inter == 'textui' or inter == '3dtext' then
      zone.data.interaction = inter
    else
      zone.data.interaction = 'target'
    end
  end
  if zone.ztype == 'shop' then
    zone.data.items = SanitizeShopItems(zone.data.items)
  elseif zone.ztype == 'crafting' then
    zone.data.allowedCategories = SanitizeCategoryList(zone.data.allowedCategories)
    zone.data.recipes = SanitizeRecipeList(zone.data.recipes)
    if type(zone.data.job) == 'string' then
      zone.data.job = zone.data.job ~= '' and zone.data.job or nil
    elseif type(zone.data.job) == 'table' then
      local jobs = {}
      for _, j in ipairs(zone.data.job) do if type(j) == 'string' and j ~= '' then jobs[#jobs+1] = j end end
      zone.data.job = (#jobs > 0) and jobs or nil
    else
      zone.data.job = nil
    end
    zone.data.icon = type(zone.data.icon) == 'string' and zone.data.icon or nil
    if type(zone.data.theme) == 'table' then
      local th = zone.data.theme
      zone.data.theme = {
        colorPrimario = type(th.colorPrimario) == 'string' and th.colorPrimario or nil,
        colorPrimarioAlt = type(th.colorPrimarioAlt) == 'string' and th.colorPrimarioAlt or nil,
        colorSecundario = type(th.colorSecundario) == 'string' and th.colorSecundario or nil,
        colorSecundarioAlt = type(th.colorSecundarioAlt) == 'string' and th.colorSecundarioAlt or nil,
        titulo = type(th.titulo) == 'string' and th.titulo or nil,
      }
    else
      zone.data.theme = nil
    end
  end
  zone.data = ApplyBlipInfo(zone.data, zone)
  local id = MySQL.insert.await('INSERT INTO jobcreator_zones (job,ztype,label,coords,radius,data) VALUES (?,?,?,?,?,?)',
    { zone.job, zone.ztype, zone.label or zone.ztype, json.encode(zone.coords), zone.radius or 2.0, json.encode(zone.data or {}) })
  if not id then return end
  local row = MySQL.query.await('SELECT * FROM jobcreator_zones WHERE id = ?', { id })
  local r = row and row[1]
  if not r then return end
  local nz = {
    id = r.id, job = r.job, ztype = r.ztype, label = r.label,
    coords = json.decode(r.coords or '{}') or {}, radius = r.radius or 2.0,
    data = json.decode(r.data or '{}') or {}
  }
  local nzInter = nz.data.interaction
  if nzInter ~= 'target' and nzInter ~= 'textui' and nzInter ~= '3dtext' then
    nz.data.interaction = 'target'
  end
  ExtractBlipInfo(nz.data, nz)
  if nz.ztype == 'shop' then
    nz.data.items = SanitizeShopItems(nz.data.items)
  elseif nz.ztype == 'crafting' then
    nz.data.allowedCategories = SanitizeCategoryList(nz.data.allowedCategories)
    nz.data.recipes = SanitizeRecipeList(nz.data.recipes)
    if type(nz.data.job) ~= 'string' and type(nz.data.job) ~= 'table' then
      nz.data.job = nil
    end
    nz.data.icon = type(nz.data.icon) == 'string' and nz.data.icon or nil
    if type(nz.data.theme) == 'table' then
      nz.data.theme = {
        colorPrimario = type(nz.data.theme.colorPrimario) == 'string' and nz.data.theme.colorPrimario or nil,
        colorPrimarioAlt = type(nz.data.theme.colorPrimarioAlt) == 'string' and nz.data.theme.colorPrimarioAlt or nil,
        colorSecundario = type(nz.data.theme.colorSecundario) == 'string' and nz.data.theme.colorSecundario or nil,
        colorSecundarioAlt = type(nz.data.theme.colorSecundarioAlt) == 'string' and nz.data.theme.colorSecundarioAlt or nil,
        titulo = type(nz.data.theme.titulo) == 'string' and nz.data.theme.titulo or nil,
      }
    else
      nz.data.theme = nil
    end
  end
  Runtime.Zones[#Runtime.Zones+1] = nz
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
  if nz.ztype == 'music' then
    local name = (nz.data and (nz.data.name or nz.data.djName)) or ('jc_ms_'..nz.job..'_'..nz.id)
    local range = tonumber(nz.data and (nz.data.range or nz.data.distance)) or 20.0
    TriggerEvent('myDj:addZone', {
      name = name,
      pos = vector3(nz.coords.x or 0.0, nz.coords.y or 0.0, nz.coords.z or 0.0),
      range = range,
      requiredJob = nz.job
    })
  end
end)

RegisterNetEvent('qb-jobcreator:server:deleteZone', function(id)
  local src = source; local job; local dz
  for _, z in ipairs(Runtime.Zones) do if z.id == id then job = z.job dz = z break end end
  if not allowAdminOrBoss(src, job or '') then return end
  DB.DeleteZone(id)
  for i = #Runtime.Zones, 1, -1 do
    if Runtime.Zones[i].id == id then table.remove(Runtime.Zones, i) break end
  end
  if dz then
    if dz.ztype == 'music' then
      local name = (dz.data and (dz.data.name or dz.data.djName)) or ('jc_ms_'..dz.job..'_'..dz.id)
      TriggerEvent('myDj:removeZone', name)
    elseif dz.ztype == 'stash' then
      local stashId = ('jc_%s_%s'):format(dz.job, dz.id)
      CreatedStashes[stashId] = nil
      pcall(function()
        local ox = exports.ox_inventory
        if ox and ox.RemoveStash then ox:RemoveStash(stashId) end
      end)
    end
  end
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
end)

-- ===== Empleados =====
QBCore.Functions.CreateCallback('qb-jobcreator:server:getEmployees', function(src, cb, jobName)
  if not allowAdminOrBoss(src, jobName) then return cb({}) end
  local list, seen = {}, {}

  -- Online (incluye asignaciones de multitrabajo)
  for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
    local jd = Player.PlayerData.job or {}
    local cid = Player.PlayerData.citizenid
    local onThis = (jd.name == jobName) or Multi_Has(cid, jobName)
    if onThis and not seen[cid] then
      list[#list+1] = {
        citizenid = cid,
        name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname)) or GetPlayerName(Player.PlayerData.source) or 'N/A',
        online = true,
        grade  = jd.grade and (jd.grade.name or jd.grade.level or jd.grade) or 0
      }
      seen[cid] = true
    end
  end

  -- Offline desde players.job
  for _, r in ipairs(DB.GetOfflineEmployees(jobName)) do
    if not seen[r.citizenid] then
      local info = json.decode(r.charinfo or '{}') or {}
      local job  = json.decode(r.job or '{}') or {}
      local fullname = (info.firstname or 'N/A')..' '..(info.lastname or '')
      local grade = (type(job.grade)=='table' and (job.grade.level or job.grade.name)) or job.grade or 0
      list[#list+1] = { citizenid = r.citizenid, name = fullname, online = false, grade = grade }
      seen[r.citizenid] = true
    end
  end

  -- Offline desde tabla multitrabajo (si está configurada)
  if DB.GetOfflineEmployees_Multi then
    for _, r in ipairs(DB.GetOfflineEmployees_Multi(jobName)) do
      if not seen[r.citizenid] then
        local info = json.decode(r.charinfo or '{}') or {}
        local fullname = (info.firstname or 'N/A')..' '..(info.lastname or '')
        list[#list+1] = { citizenid = r.citizenid, name = fullname, online = false, grade = tonumber(r.grade) or 0 }
        seen[r.citizenid] = true
      end
    end
  end

  cb(list)
end)

-- Nearby para reclutar
QBCore.Functions.CreateCallback('qb-jobcreator:server:getNearbyPlayers', function(src, cb, jobName, radius)
  if not ensurePerm(src, jobName) then return cb({}) end
  radius = tonumber(radius) or 3.0
  local srcPed = GetPlayerPed(src)
  local srcCoords = GetEntityCoords(srcPed)
  local res = {}
  local function push(sid)
    local P = QBCore.Functions.GetPlayer(sid)
    if not P then return end
    local fullname = (P.PlayerData.charinfo and (P.PlayerData.charinfo.firstname..' '..P.PlayerData.charinfo.lastname)) or ('ID '..sid)
    res[#res+1] = { id = sid, sid = sid, name = fullname }
  end
  for _, pid in ipairs(GetPlayers()) do
    local sid = tonumber(pid)
    if sid ~= src then
      local ped = GetPlayerPed(sid)
      if #(GetEntityCoords(ped) - srcCoords) <= radius + 0.1 then push(sid) end
    end
  end
  local Me = QBCore.Functions.GetPlayer(src)
  if Me and Me.PlayerData and Me.PlayerData.job and Me.PlayerData.job.name ~= jobName then
    table.insert(res, 1, { id = src, sid = src, name = (Me.PlayerData.charinfo and (Me.PlayerData.charinfo.firstname..' '..Me.PlayerData.charinfo.lastname) or ('ID '..src))..' (tú)' })
  end
  cb(res)
end)

-- Reclutar / Despedir / Cambiar rango
local function DoSetGrade(jobName, citizenid, newGrade)
  newGrade = tonumber(newGrade) or 0
  for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
    if Player.PlayerData.citizenid == citizenid then
      if Player.PlayerData.job and Player.PlayerData.job.name == jobName then
        Player.Functions.SetJob(jobName, newGrade)
      end
      Multi_SetGrade(citizenid, jobName, newGrade)
      return
    end
  end
  Multi_SetGrade(citizenid, jobName, newGrade)
  local jobJson = json.encode({ name = jobName, label = jobName, grade = { name = tostring(newGrade), level = newGrade } })
  MySQL.update.await('UPDATE players SET job=? WHERE citizenid=? AND JSON_EXTRACT(job, "$..name") = ?', { jobJson, citizenid, jobName })
end

RegisterNetEvent('qb-jobcreator:server:recruit', function(jobName, grade, targetId)
  local src = source; if not allowAdminOrBoss(src, jobName) then return end
  local Target = QBCore.Functions.GetPlayer(tonumber(targetId) or -1)
  if not Target then return end
  local cid = Target.PlayerData.citizenid
  Multi_Add(cid, jobName, tonumber(grade) or 0)
  if Config.MultiJob and Config.MultiJob.AssignAsPrimary then
    Target.Functions.SetJob(jobName, tonumber(grade) or 0)
  end
end)

RegisterNetEvent('qb-jobcreator:server:fire', function(jobName, citizenid)
  local src = source; if not allowAdminOrBoss(src, jobName) then return end
  for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
    if Player.PlayerData.citizenid == citizenid then
      if Player.PlayerData.job and Player.PlayerData.job.name == jobName then
        Player.Functions.SetJob('unemployed', 0)
      elseif Config.MultiJob and Config.MultiJob.Enabled then
        -- despedir un trabajo secundario no debe afectar al principal
      end
      Multi_Remove(citizenid, jobName)
      return
    end
  end
  DB.UpdateOfflineJob(citizenid, 'unemployed', 0, jobName)
  Multi_Remove(citizenid, jobName)
end)

RegisterNetEvent('qb-jobcreator:server:setGrade', function(jobName, citizenid, newGrade)
  local src = source; if not allowAdminOrBoss(src, jobName) then return end
  DoSetGrade(jobName, citizenid, newGrade)
end)

RegisterNetEvent('qb-jobcreator:server:promote', function(jobName, citizenid, newGrade)
  local src = source; if not allowAdminOrBoss(src, jobName) then return end
  DoSetGrade(jobName, citizenid, newGrade)
end)

RegisterNetEvent('qb-jobcreator:server:transfer', function(fromJob, citizenid, toJob, grade)
  local src = source; if not allowAdminOrBoss(src, fromJob) then return end
  grade = tonumber(grade) or 0
  for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
    if Player.PlayerData.citizenid == citizenid then
      Player.Functions.SetJob(toJob, grade)
      Multi_Remove(citizenid, fromJob)
      Multi_Add(citizenid, toJob, grade)
      return
    end
  end
  DB.UpdateOfflineJob(citizenid, toJob, grade, fromJob)
  Multi_Remove(citizenid, fromJob)
  Multi_Add(citizenid, toJob, grade)
end)

-- ===== Cuentas =====
local function SocietyAdd(job, amount)
  if Config.Integrations.UseQbManagement and GetResourceState('qb-management')=='started' then
    TriggerEvent('qb-management:server:depositMoney', job, amount)
  else
    DB.AddAccount(job, amount)
  end
end
local function SocietyRemove(job, amount)
  if Config.Integrations.UseQbManagement and GetResourceState('qb-management')=='started' then
    TriggerEvent('qb-management:server:withdrawMoney', job, amount)
  else
    DB.RemoveAccount(job, amount)
  end
end
local function SocietyBalance(job)
  if Config.Integrations.UseQbManagement and GetResourceState('qb-management')=='started' then
    local ok, val = pcall(function() return exports['qb-management']:GetAccount(job) end)
    if ok and type(val) == 'number' then return val end
  end
  return DB.GetAccount(job)
end

QBCore.Functions.CreateCallback('qb-jobcreator:server:getAccount', function(src, cb, job)
  if not allowAdminOrBoss(src, job) then return cb(0) end
  cb(SocietyBalance(job))
end)

RegisterNetEvent('qb-jobcreator:server:deposit', function(job, amount, from)
  local src = source; if not allowAdminOrBoss(src, job) then return end
  local Player = QBCore.Functions.GetPlayer(src); amount = math.abs(tonumber(amount) or 0); if amount <= 0 then return end
  local acc = (from == 'bank') and 'bank' or 'cash'
  if Player.Functions.RemoveMoney(acc, amount, 'job-society-deposit') then
    SocietyAdd(job, amount)
    TriggerClientEvent('QBCore:Notify', src, 'Depositado '..amount..' desde '..acc, 'success')
  else
    TriggerClientEvent('QBCore:Notify', src, 'Fondos insuficientes en '..acc, 'error')
  end
end)

RegisterNetEvent('qb-jobcreator:server:withdraw', function(job, amount, to)
  local src = source; if not allowAdminOrBoss(src, job) then return end
  local Player = QBCore.Functions.GetPlayer(src); amount = math.abs(tonumber(amount) or 0); if amount <= 0 then return end
  local acc = (to == 'bank') and 'bank' or 'cash'
  SocietyRemove(job, amount)
  Player.Functions.AddMoney(acc, amount, 'job-society-withdraw')
end)

RegisterNetEvent('qb-jobcreator:server:wash', function(job, amount)
  local src = source; if not allowAdminOrBoss(src, job) then return end
  local amt = math.abs(tonumber(amount) or 0)
  SocietyAdd(job, math.floor(amt * 0.9))
end)

-- Actualizar zona (guardar 'data', label/radius/coords opcional)
RegisterNetEvent('qb-jobcreator:server:updateZone', function(id, data, label, radius, coords, sprite, color, ytdDict, ytdName)
  local src = source; local job; local ztype; local old
  for _, z in ipairs(Runtime.Zones) do if z.id == id then job = z.job ztype = z.ztype old = z break end end
  if not allowAdminOrBoss(src, job or '') then return end
  if type(data) == 'table' then
    if ztype == 'shop' then
      data.items = SanitizeShopItems(data.items)
    elseif ztype == 'crafting' then
      data.allowedCategories = SanitizeCategoryList(data.allowedCategories)
      data.recipes = SanitizeRecipeList(data.recipes)
      if type(data.job) == 'string' then
        data.job = data.job ~= '' and data.job or nil
      elseif type(data.job) == 'table' then
        local jobs = {}
        for _, j in ipairs(data.job) do if type(j) == 'string' and j ~= '' then jobs[#jobs+1] = j end end
        data.job = (#jobs > 0) and jobs or nil
      else
        data.job = nil
      end
      data.icon = type(data.icon) == 'string' and data.icon or nil
      if type(data.theme) == 'table' then
        data.theme = {
          colorPrimario = type(data.theme.colorPrimario) == 'string' and data.theme.colorPrimario or nil,
          colorPrimarioAlt = type(data.theme.colorPrimarioAlt) == 'string' and data.theme.colorPrimarioAlt or nil,
          colorSecundario = type(data.theme.colorSecundario) == 'string' and data.theme.colorSecundario or nil,
          colorSecundarioAlt = type(data.theme.colorSecundarioAlt) == 'string' and data.theme.colorSecundarioAlt or nil,
          titulo = type(data.theme.titulo) == 'string' and data.theme.titulo or nil,
        }
      else
        data.theme = nil
      end
    end
    local inter = data.interaction
    if inter == 'target' or inter == 'textui' or inter == '3dtext' then
      data.interaction = inter
    else
      data.interaction = 'target'
    end
    data.clearArea = data.clearArea and true or false
    if data.clearRadius ~= nil then data.clearRadius = tonumber(data.clearRadius) or Config.Zone.ClearRadius end
  end
  data = ApplyBlipInfo(data, { sprite = sprite, color = color, ytdDict = ytdDict, ytdName = ytdName })
  if DB.UpdateZone then DB.UpdateZone(id, { data = data, label = label, radius = radius, coords = coords }) end
  local row = MySQL.query.await('SELECT * FROM jobcreator_zones WHERE id = ?', { id })
  local r = row and row[1]
  if r then
    for idx, z in ipairs(Runtime.Zones) do
      if z.id == id then
        local nd = json.decode(r.data or '{}') or {}
        local inter = nd.interaction
        if inter ~= 'target' and inter ~= 'textui' and inter ~= '3dtext' then
          nd.interaction = 'target'
        end
        if ztype == 'shop' then
          nd.items = SanitizeShopItems(nd.items)
        elseif ztype == 'crafting' then
          nd.allowedCategories = SanitizeCategoryList(nd.allowedCategories)
          nd.recipes = SanitizeRecipeList(nd.recipes)
          if type(nd.job) ~= 'string' and type(nd.job) ~= 'table' then nd.job = nil end
          nd.icon = type(nd.icon) == 'string' and nd.icon or nil
          if type(nd.theme) == 'table' then
            nd.theme = {
              colorPrimario = type(nd.theme.colorPrimario) == 'string' and nd.theme.colorPrimario or nil,
              colorPrimarioAlt = type(nd.theme.colorPrimarioAlt) == 'string' and nd.theme.colorPrimarioAlt or nil,
              colorSecundario = type(nd.theme.colorSecundario) == 'string' and nd.theme.colorSecundario or nil,
              colorSecundarioAlt = type(nd.theme.colorSecundarioAlt) == 'string' and nd.theme.colorSecundarioAlt or nil,
              titulo = type(nd.theme.titulo) == 'string' and nd.theme.titulo or nil,
            }
          else
            nd.theme = nil
          end
        end
        local newZone = {
          id = r.id, job = r.job, ztype = r.ztype, label = r.label,
          coords = json.decode(r.coords or '{}') or {}, radius = r.radius or 2.0,
          data = nd
        }
        ExtractBlipInfo(nd, newZone)
        Runtime.Zones[idx] = newZone
        break
      end
    end
    TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
  end
end)

-- ===== Acciones seguras de zonas =====
function findZoneById(id)
  for _, z in ipairs(Runtime.Zones) do
    if z.id == id then return z end
  end
end

local function isPlayerInRange(src, zoneId, ztype)
  return playerInJobZone(src, findZoneById(zoneId), ztype)
end

RegisterNetEvent('qb-jobcreator:server:openStash', function(zoneId)
  local src = source
  local ok, zone = playerInJobZone(src, findZoneById(zoneId), 'stash')
  if not ok then return end
  local stashId = ('jc_%s_%s'):format(zone.job, zone.id)
  local slots = tonumber(zone.data and zone.data.slots) or 50
  local maxWeight = tonumber(zone.data and zone.data.weight) or 400000
  local qbStarted = GetResourceState('qb-inventory') == 'started'
  local oxStarted = GetResourceState('ox_inventory') == 'started'
  if qbStarted then
    TriggerClientEvent('inventory:client:SetCurrentStash', src, stashId)
    pcall(function() exports['qb-inventory']:OpenStash(src, stashId, slots, maxWeight, true) end)
  elseif oxStarted then
    if not CreatedStashes[stashId] then
      exports.ox_inventory:RegisterStash(stashId, zone.label or stashId, slots, maxWeight, true)
      CreatedStashes[stashId] = true
    end
    exports.ox_inventory:forceOpenInventory(src, 'stash', stashId)
  else
    TriggerClientEvent('QBCore:Notify', src, 'No hay inventario disponible.', 'error')
  end
end)

RegisterNetEvent('qb-jobcreator:server:getShopItems', function(zoneId)
  local src = source
  local ok, zone = playerInJobZone(src, findZoneById(zoneId), 'shop')
  if not ok then return end
  TriggerClientEvent('qb-jobcreator:client:openShopMenu', src, zone.id, zone.data and zone.data.items or {})
end)

RegisterNetEvent('qb-jobcreator:server:buyItem', function(zoneId, itemName)
  local src = source
  local ok, zone, Player = playerInJobZone(src, findZoneById(zoneId), 'shop')
  if not ok then return end
  itemName = type(itemName) == 'string' and itemName:lower() or ''
  local items = zone.data and zone.data.items or {}
  local item
  for _, it in ipairs(items) do
    if it.name == itemName then item = it break end
  end
  if not item or (item.amount or 0) <= 0 then
    TriggerClientEvent('QBCore:Notify', src, 'Sin stock', 'error')
    return
  end
  local price = item.price or 0
  if price <= 0 then return end
  if Player.Functions.GetMoney('cash') >= price then
    Player.Functions.RemoveMoney('cash', price, 'jobcreator-shop-buy')
  elseif Player.Functions.GetMoney('bank') >= price then
    Player.Functions.RemoveMoney('bank', price, 'jobcreator-shop-buy')
  else
    TriggerClientEvent('QBCore:Notify', src, 'Fondos insuficientes', 'error')
    return
  end
  local added = Inventory.AddItem(src, item.name, 1, false, item.info)
  if not added then
    TriggerClientEvent('QBCore:Notify', src, 'Inventario lleno', 'error')
    return
  end
  item.amount = (item.amount or 1) - 1
end)

local function kvKey(license) return ('qb_jobcreator_ready:%s'):format(license) end
local function loadReady(license)
  Ready[license] = Ready[license] or {}
  local raw = GetResourceKvpString(kvKey(license))
  if raw then
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then Ready[license] = data end
  end
  return Ready[license]
end
local function saveReady(license)
  SetResourceKvp(kvKey(license), json.encode(Ready[license] or {}))
end
local function getLicense(src)
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:find('license:') then return id end
  end
  return GetPlayerIdentifier(src, 0) or ('src:'..src)
end

local function scheduleFinish(zoneId, src, entry)
  SetTimeout(entry.time, function()
    local license = getLicense(src)
    local ready = loadReady(license)
    ready[#ready+1] = {
      id = entry.id,
      zoneId = zoneId,
      label = entry.label,
      outputs = entry.outputs,
      timestamp = os.time()
    }
    saveReady(license)
    local q = Queues[zoneId] and Queues[zoneId][src]
    if q then
      for i, e in ipairs(q.entries) do
        if e.id == entry.id then table.remove(q.entries, i) break end
      end
    end
    if GetPlayerName(src) then
      TriggerClientEvent('QBCore:Notify', src, (entry.label .. ' listo para recoger.'), 'success')
    end
  end)
end

RegisterNetEvent('qb-jobcreator:server:craft', function(zoneId, recipeKey, amount)
  local src = source
  local ok, zone, Player = playerInJobZone(src, findZoneById(zoneId), 'crafting')
  if not ok then return end
  recipeKey = type(recipeKey) == 'string' and recipeKey or ''
  amount = math.max(1, math.floor(tonumber(amount) or 1))

  local allowed = {}
  local data = zone.data or {}
  if data.allowedCategories and #data.allowedCategories > 0 then
    local set = {}
    for _, c in ipairs(data.allowedCategories) do set[c] = true end
    for name, r in pairs(Config.CraftingRecipes or {}) do
      if r.category and set[r.category] then allowed[name] = true end
    end
  else
    for _, n in ipairs(data.recipes or {}) do allowed[n] = true end
  end
  if not allowed[recipeKey] then
    TriggerClientEvent('QBCore:Notify', src, 'Receta no permitida', 'error')
    return
  end

  local recipe = Config.CraftingRecipes[recipeKey]
  if not recipe or not recipe.output then
    TriggerClientEvent('QBCore:Notify', src, 'Receta no válida', 'error')
    return
  end

  local jobName = Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name
  local allowed = checkRecipeJob(recipe.job, zone.job, jobName)
  if not allowed then
    TriggerClientEvent('QBCore:Notify', src, 'No tienes el trabajo requerido', 'error')
    return
  end

  if recipe.blueprint then
    local ok = Inventory.HasItem(src, recipe.blueprint, 1)
    if not ok then
      TriggerClientEvent('QBCore:Notify', src, 'Falta el plano requerido', 'error')
      return
    end
  end

  for _, inp in ipairs(recipe.inputs or {}) do
    local need = (inp.amount or 1) * amount
    local ok = Inventory.HasItem(src, inp.item, need)
    if not ok then
      TriggerClientEvent('QBCore:Notify', src, 'Materiales insuficientes', 'error')
      return
    end
  end
  for _, inp in ipairs(recipe.inputs or {}) do
    Inventory.RemoveItem(src, inp.item, (inp.amount or 1) * amount)
  end

  local craftTime = tonumber(recipe.time) or 0
  if recipe.skill and GetResourceState('qb-skillz') == 'started' then
    local skillLevel = exports['qb-skillz']:GetSkillLevel(src, recipe.skill) or 0
    if skillLevel <= 0 then
      TriggerClientEvent('QBCore:Notify', src, 'No tienes la habilidad requerida', 'error')
      return
    end
    craftTime = math.floor(math.max(craftTime * (1 - (skillLevel / 200)), craftTime * 0.5))
  end
  local totalTime = craftTime * amount
  local now = os.time() * 1000
  local out = recipe.output
  local label = recipe.label or out.label or out.item or recipeKey
  local outputs = { { item = out.item, amount = (out.amount or 1) * amount, info = out.info } }

  Queues[zoneId] = Queues[zoneId] or {}
  Queues[zoneId][src] = Queues[zoneId][src] or { entries = {} }
  local entries = Queues[zoneId][src].entries

  local entry = {
    id = math.random(100000, 999999),
    recipe = recipeKey,
    label = label,
    amount = amount,
    time = totalTime,
    finish = now + totalTime,
    outputs = outputs
  }

  entries[#entries+1] = entry
  scheduleFinish(zoneId, src, entry)
end)

QBCore.Functions.CreateCallback('qb-jobcreator:server:getQueue', function(src, cb, zoneId)
  local ok = playerInJobZone(src, findZoneById(zoneId), 'crafting')
  if not ok then cb({ queue = {}, inventory = {} }) return end
  local license = getLicense(src)
  local readyList = loadReady(license)
  local inv = {}
  for _, r in ipairs(readyList) do
    if not zoneId or r.zoneId == zoneId then
      for _, o in ipairs(r.outputs or {}) do
        inv[o.item] = (inv[o.item] or 0) + (o.amount or 1)
      end
    end
  end
  local q = Queues[zoneId] and Queues[zoneId][src] and Queues[zoneId][src].entries or {}
  cb({ queue = q, inventory = inv })
end)

RegisterNetEvent('qb-jobcreator:server:cancelCraft', function(zoneId, id)
  local src = source
  local ok = playerInJobZone(src, findZoneById(zoneId), 'crafting')
  if not ok then return end
  local q = Queues[zoneId] and Queues[zoneId][src]
  if not q then return end
  for i, e in ipairs(q.entries) do
    if e.id == id then
      table.remove(q.entries, i)
      TriggerClientEvent('QBCore:Notify', src, 'Crafteo cancelado', 'error')
      break
    end
  end
end)

RegisterNetEvent('qb-jobcreator:server:collectCrafted', function(zoneId)
  local src = source
  local ok = playerInJobZone(src, findZoneById(zoneId), 'crafting')
  if not ok then return end
  local license = getLicense(src)
  local readyList = loadReady(license)
  local remaining = {}
  for _, r in ipairs(readyList) do
    if r.zoneId == zoneId then
      local okAll = true
      for _, o in ipairs(r.outputs or {}) do
        if not Inventory.AddItem(src, o.item, o.amount, false, o.info) then
          okAll = false
          break
        end
      end
      if not okAll then
        remaining[#remaining+1] = r
        TriggerClientEvent('QBCore:Notify', src, 'Inventario lleno', 'error')
        break
      end
    else
      remaining[#remaining+1] = r
    end
  end
  Ready[license] = remaining
  saveReady(license)
end)

RegisterNetEvent('qb-jobcreator:server:collect', function(zoneId)
  local src = source
  local ok, zone, Player = playerInJobZone(src, findZoneById(zoneId), 'collect')
  if not ok then return end
  local item = (zone.data and zone.data.item) or 'material'
  local amount = tonumber(zone.data and zone.data.amount) or 1
  Inventory.AddItem(src, item, amount)
end)

RegisterNetEvent('qb-jobcreator:server:sell', function(zoneId)
  local src = source
  local ok, zone, Player = playerInJobZone(src, findZoneById(zoneId), 'sell')
  if not ok then return end
  local data = zone.data or {}
  local item   = data.item or 'material'
  local price  = tonumber(data.price) or 10
  local max    = tonumber(data.max) or 10
  local toSociety = data.toSociety ~= false
  local _, count = Inventory.HasItem(src, item)
  local qty = math.min(count, max)
  if qty <= 0 then return end
  Inventory.RemoveItem(src, item, qty)
  local reward = price * qty
  if toSociety then
    SocietyAdd(zone.job, reward)
  else
    Player.Functions.AddMoney('cash', reward, 'jobcreator-sell')
  end
end)

RegisterNetEvent('qb-jobcreator:server:teleport', function(zoneId, fromIdx, toIdx)
  local src = source
  local zone = findZoneById(zoneId)
  if not zone or zone.ztype ~= 'teleport' then return end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData then return end
  local jd = Player.PlayerData.job or {}
  local cid = Player.PlayerData.citizenid
  if jd.name ~= zone.job and not Multi_Has(cid, zone.job) then return end

  local d = zone.data or {}
  local to = d.to
  local dests = {}
  if type(to) == 'table' then
    if to[1] then dests = to elseif to.x then dests = { to } end
  end

  local function getPos(idx)
    if idx == 0 then return zone.coords end
    return dests[tonumber(idx) or 0]
  end

  fromIdx = tonumber(fromIdx) or 0
  toIdx   = tonumber(toIdx)   or 0
  local fromPos = getPos(fromIdx)
  local destPos = getPos(toIdx)
  if not (fromPos and destPos and destPos.x and destPos.y and destPos.z) then return end

  local coords = GetEntityCoords(GetPlayerPed(src))
  local radius = zone.radius or 2.0
  if #(coords - vector3(fromPos.x, fromPos.y, fromPos.z)) > radius + 0.1 then return end

  local ped = GetPlayerPed(src)
  SetEntityCoords(ped, destPos.x+0.0, destPos.y+0.0, destPos.z+0.0, false, false, false, true)
  if destPos.w then SetEntityHeading(ped, destPos.w+0.0) end
end)

RegisterNetEvent('qb-jobcreator:server:charge', function(zoneId, targetId)
  local src = source
  local ok, zone, Player = playerInJobZone(src, findZoneById(zoneId), 'register')
  if not ok then return end
  local Target = QBCore.Functions.GetPlayer(tonumber(targetId) or -1)
  if not Target then return end
  local amt = tonumber(zone.data and zone.data.amount) or 0
  if amt <= 0 then return end
  local method = (zone.data and zone.data.method) or 'bank'
  local toSociety = zone.data and zone.data.toSociety ~= false
  local account = method == 'cash' and 'cash' or 'bank'
  if not Target.Functions.RemoveMoney(account, amt, 'jobcreator-charge') then return end
  if toSociety then
    SocietyAdd(zone.job, amt)
  else
    Player.Functions.AddMoney('cash', amt, 'jobcreator-charge')
  end
end)

exports('GetZones', function()
  return Runtime.Zones
end)

