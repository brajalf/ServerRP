QBCore = exports['qb-core']:GetCoreObject()

local Active = {}

local function removeAll()
  if Config.Integrations.UseQbTarget and next(Active) then
    for _, z in pairs(Active) do
      if z._zoneName then exports['qb-target']:RemoveZone(z._zoneName) end
    end
  end
  Active = {}
end

local function playerJobData()
  local pd = QBCore.Functions.GetPlayerData() or {}
  local job = pd.job or {}
  local gradeLevel = (type(job.grade)=='table' and job.grade.level) or job.grade or 0
  local isboss = job.isboss or (type(job.grade)=='table' and job.grade.isboss) or false
  return job.name or 'unemployed', gradeLevel, isboss, (pd.citizenid or pd.citizen)
end

-- ¿Tiene el job vía recurso de multi‑trabajo?
local function hasMultiJob(job)
  if not (Config.MultiJob and Config.MultiJob.Enabled and Config.MultiJob.Resource) then return false end
  if GetResourceState(Config.MultiJob.Resource) ~= 'started' then return false end
  local ok, has = pcall(function()
    local r = exports[Config.MultiJob.Resource]
    if r.HasJobClient then return r.HasJobClient(job) end -- prefer client export
    return false
  end)
  return ok and has or false
end

-- Regla de acceso por zona (mínimo de rango + pertenecer al job). Opcional: exigir boss.
local function canUseZone(z, requireBoss)
  local name, grade, isboss = playerJobData()
  local inJob = (name == z.job) or hasMultiJob(z.job)
  if not inJob then return false end
  if requireBoss and not isboss then return false end
  local minG = (z.data and (z.data.gradeMin or z.data.minGrade)) or 0
  if tonumber(minG) and grade < tonumber(minG) then return false end
  return true
end

-- ==== SPAWN UNIFICADO ====
local function spawnFromConfig(model, coords, heading)
  model = tostring(model or 'adder')

  -- 1) Comando (client): /car <modelo>
  if Config.Garages and Config.Garages.Command then
    ExecuteCommand(('%s %s'):format(Config.Garages.Command, model))
    return
  end

  -- 2) qb-garages (server event configurable)
  if Config.Garages and Config.Garages.UseQbGarages and GetResourceState(Config.Garages.QbResource or 'qb-garages') == 'started' then
    if Config.Garages.SpawnEvent and type(Config.Garages.SpawnEvent) == 'string' then
      TriggerServerEvent(Config.Garages.SpawnEvent, model, coords, heading or 0.0)
      return
    end
  end

  -- 3) Fallback QBCore
  QBCore.Functions.SpawnVehicle(model, function(veh)
    SetVehicleNumberPlateText(veh, ('%s%03d'):format(string.upper(string.sub((coords.job or 'JOB'),1,3)), math.random(0,999)))
    SetEntityHeading(veh, heading or 0.0)
    SetVehicleEngineOn(veh, true, true)
  end, vector3(coords.x, coords.y, coords.z), true)
end

-- ==== PARSER "rango=modelo" ====
local function _split(s, sep)
  local t = {}
  for p in string.gmatch(s or '', '([^'..sep..']+)') do t[#t+1] = p end
  return t
end
local function parseVehicles(vdata)
  -- Acepta "0=police,2=police2" o array { {model,label,minGrade} }
  local list = {}
  if type(vdata) == 'string' then
    for _, pair in ipairs(_split(vdata, ',')) do
      local kv = _split(pair, '=')
      local g  = tonumber((kv[1] or ''):gsub('%s','')) or 0
      local m  = (kv[2] or ''):gsub('%s','')
      if m ~= '' then list[#list+1] = { model = m, label = m, minGrade = g } end
    end
  elseif type(vdata) == 'table' then
    for _, v in ipairs(vdata) do
      if type(v) == 'table' and v.model then
        list[#list+1] = { model = tostring(v.model), label = v.label or tostring(v.model), minGrade = tonumber(v.minGrade or v.grade or 0) or 0 }
      end
    end
  end
  table.sort(list, function(a,b) return (a.minGrade or 0) < (b.minGrade or 0) end)
  return list
end
local function vehiclesForMyGrade(z)
  local _, grade = playerJobData()
  local list = parseVehicles(z.data and z.data.vehicles)
  local allowed = {}
  for _, v in ipairs(list) do if grade >= (v.minGrade or 0) then allowed[#allowed+1] = v end end
  if #allowed == 0 then
    local fallback = (z.data and (z.data.vehicle or z.data.default)) or 'adder'
    allowed = { { model = fallback, label = fallback, minGrade = 0 } }
  end
  return allowed
end

local function addTargetForZone(z)
  if not Config.Integrations.UseQbTarget then return end

  -- ✅ valida coords y radio
  if not z.coords or type(z.coords.x) ~= 'number' or type(z.coords.y) ~= 'number' or type(z.coords.z) ~= 'number' then
    return
  end
  z.radius = tonumber(z.radius) or (Config.Zone and Config.Zone.DefaultRadius) or 2.0
  local name = ('jc_%s_%s_%s'):format(z.ztype, z.job, z.id)
  local size = z.radius * 2.0
  local opts = {}

  -- boss
  if z.ztype == 'boss' then
    opts[#opts+1] = {
      label = 'Abrir gestión del trabajo',
      icon = 'fa-solid fa-briefcase',
      canInteract = function() return canUseZone(z, true) end,
      action = function() TriggerServerEvent('qb-jobcreator:server:openBossPanel', z.job) end
    }
  -- stash
  elseif z.ztype == 'stash' and Config.Integrations.UseQbInventory then
    opts[#opts+1] = {
      label = 'Abrir Almacén', icon = 'fa-solid fa-box',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local stashId = ('jc_%s_%s'):format(z.job, z.id)
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId, { maxweight = 400000, slots = 50 })
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
      end
    }
  -- garage  (ver §4 para modo avanzado)
  elseif z.ztype == 'garage' then
  -- crea una opción por cada vehículo permitido según tu rango
  for _, v in ipairs(vehiclesForMyGrade(z)) do
    table.insert(opts, {
      label = v.label or v.model,
      icon  = 'fa-solid fa-car',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        spawnFromConfig(v.model, z.coords, z.coords.w or 0.0)
      end
    })
  end
  -- crafting
  elseif z.ztype == 'crafting' then
    opts[#opts+1] = {
      label = 'Craftear', icon = 'fa-solid fa-hammer',
      canInteract = function() return canUseZone(z, false) end,
      action = function() QBCore.Functions.Notify('Abrir crafteo (placeholder).', 'primary') end
    }
  end

  -- ✅ no registres zonas sin opciones
  if #opts == 0 then return end

  exports['qb-target']:AddBoxZone(name, vector3(z.coords.x, z.coords.y, z.coords.z), size, size, {
    name = name, heading = 0.0, minZ = z.coords.z - 1.0, maxZ = z.coords.z + 2.0
  }, { options = opts, distance = z.radius + 0.5 })

  z._zoneName = name
end

local function spawnFromConfig(model, coords, heading)
  -- 1) qb-garages
  if Config.Garages and Config.Garages.UseQbGarages and GetResourceState(Config.Garages.QbResource or 'qb-garages') == 'started' then
    if Config.Garages.SpawnEvent and type(Config.Garages.SpawnEvent)=='string' then
      -- ajusta a tu evento real si es distinto
      TriggerServerEvent(Config.Garages.SpawnEvent, model, coords, heading)
      return true
    end
  end
  -- 2) comando (client)
  if Config.Garages and Config.Garages.Command then
    ExecuteCommand(('%s %s'):format(Config.Garages.Command, model))
    return true
  end
  -- 3) fallback QBCore (actual)
  QBCore.Functions.SpawnVehicle(model, function(veh)
    SetVehicleNumberPlateText(veh, ('%s%03d'):format(string.upper(string.sub((QBCore.Functions.GetPlayerData().job.name or 'JOB'),1,3)), math.random(0,999)))
    SetEntityHeading(veh, heading or 0.0)
    SetVehicleEngineOn(veh, true, true)
  end, vector3(coords.x, coords.y, coords.z), true)
  return true
end

-- Reconstrucción completa desde el servidor
RegisterNetEvent('qb-jobcreator:client:rebuildZones', function(zones)
  removeAll()
  for _, z in ipairs(zones or {}) do
    Active[#Active+1] = z
    -- Blip siempre disponible
    if z.ztype == 'blip' then
      local blip = AddBlipForCoord(z.coords.x, z.coords.y, z.coords.z)
      SetBlipSprite(blip, Config.Zone.BlipSprite); SetBlipColour(blip, Config.Zone.BlipColor)
      SetBlipScale(blip, 0.8); SetBlipAsShortRange(blip, true)
      BeginTextCommandSetBlipName('STRING'); AddTextComponentString(z.label or ('Punto '..z.job)); EndTextCommandSetBlipName(blip)
    else
      addTargetForZone(z)
    end
  end
end)
