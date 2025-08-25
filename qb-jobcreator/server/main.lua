local DB = _G.DB
QBCore = exports['qb-core']:GetCoreObject()

local Runtime = { Jobs = {}, Zones = {} }
local _lastCreate = {}

-- ===== Helpers =====
local function InjectJobToCore(job)
  QBCore.Shared.Jobs[job.name] = { label = job.label, grades = job.grades }
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

-- ===== Permisos genéricos (admin/ACE) =====
local function HasOpenPermission(src)
  -- ACE (recomendado)
  if IsPlayerAceAllowed(src, 'qb-jobcreator.open') then return true end
  -- Grupo/perm de QBCore
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData then return false end
  local grp = P.PlayerData.group or P.PlayerData.permission
  return grp == 'admin' or grp == 'god'
end

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
    Runtime.Zones[#Runtime.Zones+1] = {
      id = z.id, job = z.job, ztype = z.ztype, label = z.label,
      coords = json.decode(z.coords or '{}') or {}, radius = z.radius or 2.0,
      data = json.decode(z.data or '{}') or {}
    }
  end
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
end

AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  DB.EnsureSchema(); LoadAll()
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

-- ===== Dashboard =====
QBCore.Functions.CreateCallback('qb-jobcreator:server:getDashboard', function(src, cb)
  local ok, result = pcall(function()
    local totals = { jobs = 0, employees = 0, money = 0 }
    local popular = {}
    for jobName, job in pairs(Runtime.Jobs or {}) do
      totals.jobs = totals.jobs + 1
      local count = 0
      for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
        local jd = Player.PlayerData.job
        if jd and jd.name == jobName then count = count + 1 end
      end
      popular[#popular+1] = { name = job.label or jobName, count = count }

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
    return { ok = true, branding = Config.Branding, jobs = Runtime.Jobs or {}, zones = Runtime.Zones or {}, totals = totals, popular = popular }
  end)
  if not ok then
    print('[qb-jobcreator] getDashboard error: '..tostring(result))
    cb({ ok = true, branding = Config.Branding, jobs = Runtime.Jobs or {}, zones = Runtime.Zones or {}, totals = { jobs = 0, employees = 0, money = 0 }, popular = {} })
  else cb(result) end
end)

-- ===== CRUD de trabajos =====
RegisterNetEvent('qb-jobcreator:server:createJob', function(data)
  local src = source; if not ensurePerm(src) then return end
  local name = string.lower((data.name or ''):gsub('%s+',''))
  local job = {
    name = name,
    label = data.label or 'Trabajo',
    type = data.type or 'generic',
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
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:deleteJob', function(name)
  local src = source; if not ensurePerm(src) then return end
  Runtime.Jobs[name] = nil
  QBCore.Shared.Jobs[name] = nil
  DB.DeleteJob(name)
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
  Runtime.Jobs[newName] = copy; DB.SaveJob(copy); InjectJobToCore(copy)
  TriggerClientEvent('qb-jobcreator:client:syncAll', -1, Runtime.Jobs, Runtime.Zones)
end)

RegisterNetEvent('qb-jobcreator:server:updateGradeSalary', function(jobName, gradeKey, salary)
  local src = source; if not ensurePerm(src) then return end
  local j = Runtime.Jobs[jobName]; if not j then return end
  if j.grades[tostring(gradeKey)] then
    j.grades[tostring(gradeKey)].payment = tonumber(salary) or 0
    DB.SaveJob(j); InjectJobToCore(j)
  end
end)

-- ===== Zonas =====
QBCore.Functions.CreateCallback('qb-jobcreator:server:getZones', function(src, cb, job)
  if not allowAdminOrBoss(src, job) then return cb({}) end
  local list = {}
  for _, z in ipairs(Runtime.Zones or {}) do if z.job == job then list[#list+1] = z end end
  cb(list)
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
  TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
  if dz and dz.ztype == 'music' then
    local name = (dz.data and (dz.data.name or dz.data.djName)) or ('jc_ms_'..dz.job..'_'..dz.id)
    TriggerEvent('myDj:removeZone', name)
  end
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
      end
      Multi_Remove(citizenid, jobName)
      return
    end
  end
  DB.UpdateOfflineJob(citizenid, 'unemployed', 0)
  Multi_Remove(citizenid, jobName)
end)

RegisterNetEvent('qb-jobcreator:server:setGrade', function(jobName, citizenid, newGrade)
  local src = source; if not allowAdminOrBoss(src, jobName) then return end
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
RegisterNetEvent('qb-jobcreator:server:updateZone', function(id, data, label, radius, coords)
  local src = source; local job
  for _, z in ipairs(Runtime.Zones) do if z.id == id then job = z.job break end end
  if not allowAdminOrBoss(src, job or '') then return end
  if DB.UpdateZone then DB.UpdateZone(id, { data = data, label = label, radius = radius, coords = coords }) end
  local row = MySQL.query.await('SELECT * FROM jobcreator_zones WHERE id = ?', { id })
  local r = row and row[1]
  if r then
    for idx, z in ipairs(Runtime.Zones) do
      if z.id == id then
        Runtime.Zones[idx] = {
          id = r.id, job = r.job, ztype = r.ztype, label = r.label,
          coords = json.decode(r.coords or '{}') or {}, radius = r.radius or 2.0,
          data = json.decode(r.data or '{}') or {}
        }
        break
      end
    end
    TriggerClientEvent('qb-jobcreator:client:rebuildZones', -1, Runtime.Zones)
  end
end)

-- ===== Acciones seguras de zonas =====
local function findZoneById(id)
  for _, z in ipairs(Runtime.Zones) do
    if z.id == id then return z end
  end
end

local function playerInJobZone(src, zone, ztype)
  if not zone or (ztype and zone.ztype ~= ztype) then return false end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData then return false end
  local jd = Player.PlayerData.job or {}
  local cid = Player.PlayerData.citizenid
  if jd.name ~= zone.job and not Multi_Has(cid, zone.job) then return false end
  local coords = GetEntityCoords(GetPlayerPed(src))
  local dist = #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
  if dist > (zone.radius or 2.0) + 0.1 then return false end
  return true, zone, Player
end

RegisterNetEvent('qb-jobcreator:server:openStash', function(zoneId)
  local src = source
  local ok, zone = playerInJobZone(src, findZoneById(zoneId), 'stash')
  if not ok then return end
  local stashId = ('jc_%s_%s'):format(zone.job, zone.id)
  local slots = tonumber(zone.data and zone.data.slots) or 50
  local weight = tonumber(zone.data and zone.data.weight) or 400000
  TriggerClientEvent('inventory:client:SetCurrentStash', src, stashId)
  pcall(function() exports['qb-inventory']:OpenStash(src, stashId, slots, weight, true) end)
end)

RegisterNetEvent('qb-jobcreator:server:openShop', function(zoneId)
  local src = source
  local ok, zone = playerInJobZone(src, findZoneById(zoneId), 'shop')
  if not ok then return end
  local sid = ('jc_shop_%s_%s'):format(zone.job, zone.id)
  local items = {}
  for _, p in pairs(zone.data and zone.data.items or {}) do
    if p.name then
      items[#items+1] = {
        name = string.lower(p.name),
        price = tonumber(p.price) or 0,
        metadata = p.info,
        count = p.count or p.amount
      }
    end
  end
  pcall(function() exports.ox_inventory:forceOpenInventory(src, 'shop', { id = sid, items = items }) end)
end)

RegisterNetEvent('qb-jobcreator:server:collect', function(zoneId)
  local src = source
  local ok, zone, Player = playerInJobZone(src, findZoneById(zoneId), 'collect')
  if not ok then return end
  local item = (zone.data and zone.data.item) or 'material'
  local amount = tonumber(zone.data and zone.data.amount) or 1
  Player.Functions.AddItem(item, amount)
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
  local invItem = Player.Functions.GetItemByName(item)
  local count = (invItem and invItem.amount) or 0
  local qty = math.min(count, max)
  if qty <= 0 then return end
  Player.Functions.RemoveItem(item, qty)
  local reward = price * qty
  if toSociety then
    SocietyAdd(zone.job, reward)
  else
    Player.Functions.AddMoney('cash', reward, 'jobcreator-sell')
  end
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

