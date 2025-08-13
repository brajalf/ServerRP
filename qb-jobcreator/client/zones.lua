QBCore = exports['qb-core']:GetCoreObject()

local Active = {}

-- =============================
-- Utils
-- =============================
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
  return job.name or 'unemployed', tonumber(gradeLevel) or 0, isboss, (pd.citizenid or pd.citizen)
end

local function hasMultiJob(job)
  if not (Config.MultiJob and Config.MultiJob.Enabled and Config.MultiJob.Resource) then return false end
  if GetResourceState(Config.MultiJob.Resource) ~= 'started' then return false end
  local ok, has = pcall(function()
    local r = exports[Config.MultiJob.Resource]
    if r.HasJobClient then return r.HasJobClient(job) end
    return false
  end)
  return ok and has or false
end

local function Tnum(v)
  -- conversión robusta a número: solo primeros dígitos, sin base
  if type(v) == 'number' then return v end
  if type(v) == 'string' then
    local d = v:match('^-?%d+')
    return tonumber(d) or 0
  end
  return 0
end

local function canUseZone(z, requireBoss)
  local name, grade, isboss = playerJobData()
  local inJob = (name == z.job) or hasMultiJob(z.job)
  if not inJob then return false end
  if requireBoss and not isboss then return false end
  local minG = 0
  if z and z.data and (z.data.gradeMin or z.data.minGrade) then
    minG = Tnum(z.data.gradeMin or z.data.minGrade)
  end
  if grade < minG then return false end
  return true
end

-- =============================
-- Spawner unificado + parser de vehículos
-- =============================
local function spawnFromConfig(model, coords, heading)
  model = tostring(model or 'adder')

  if Config.Garages and Config.Garages.Command then
    ExecuteCommand(('%s %s'):format(Config.Garages.Command, model))
    return
  end

  if Config.Garages and Config.Garages.UseQbGarages and GetResourceState(Config.Garages.QbResource or 'qb-garages') == 'started' then
    if Config.Garages.SpawnEvent and type(Config.Garages.SpawnEvent) == 'string' then
      TriggerServerEvent(Config.Garages.SpawnEvent, model, coords, heading or 0.0)
      return
    end
  end

  QBCore.Functions.SpawnVehicle(model, function(veh)
    SetVehicleNumberPlateText(veh, ('%s%03d'):format(string.upper(string.sub((coords.job or 'JOB'),1,3)), math.random(0,999)))
    SetEntityHeading(veh, heading or 0.0)
    SetVehicleEngineOn(veh, true, true)
  end, vector3(coords.x, coords.y, coords.z), true)
end

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
      local g  = Tnum(kv[1])
      local m  = (kv[2] or ''):gsub('%s','')
      if m ~= '' then list[#list+1] = { model = m, label = m, minGrade = g } end
    end
  elseif type(vdata) == 'table' then
    for _, v in ipairs(vdata) do
      if type(v) == 'table' and v.model then
        list[#list+1] = { model = tostring(v.model), label = v.label or tostring(v.model), minGrade = Tnum(v.minGrade or v.grade or 0) }
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

-- =============================
-- Targets por zona
-- =============================
local function addTargetForZone(z)
  if not Config.Integrations.UseQbTarget then return end
  local name = ('jc_%s_%s_%s'):format(z.ztype, z.job, z.id)
  local radius = tonumber(z.radius) or Config.Zone.DefaultRadius or 2.0
  local size = radius * 2.0
  local opts = {}

  if z.ztype == 'boss' then
    table.insert(opts, {
      label = 'Abrir gestión del trabajo', icon = 'fa-solid fa-briefcase',
      canInteract = function() return canUseZone(z, true) end,
      action = function() TriggerServerEvent('qb-jobcreator:server:openBossPanel', z.job) end
    })

  elseif z.ztype == 'stash' and Config.Integrations.UseQbInventory then
    table.insert(opts, {
      label = 'Abrir Almacén', icon = 'fa-solid fa-box',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local stashId = ('jc_%s_%s'):format(z.job, z.id)
        local slots = Tnum(z.data and z.data.slots or 50)
        local weight = Tnum(z.data and z.data.weight or 400000)
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId, { maxweight = weight, slots = slots })
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
      end
    })

  elseif z.ztype == 'garage' then
    local list = vehiclesForMyGrade(z)
    for _, v in ipairs(list) do
      table.insert(opts, {
        label = v.label or v.model, icon = 'fa-solid fa-car',
        canInteract = function() return canUseZone(z, false) end,
        action = function() spawnFromConfig(v.model, z.coords, z.coords.w or 0.0) end
      })
    end

  elseif z.ztype == 'crafting' then
    table.insert(opts, {
      label = 'Craftear', icon = 'fa-solid fa-hammer',
      canInteract = function() return canUseZone(z, false) end,
      action = function() QBCore.Functions.Notify('Abrir crafteo (placeholder). Integra tu UI preferida.', 'primary') end
    })
  end

  if z.ztype == 'actions' then
    local myJob = (QBCore.Functions.GetPlayerData().job or {}).name
    local allowed = (Config.PlayerActions or {})[myJob] or {}
    for _, act in ipairs(allowed) do
      table.insert(opts, {
        label = ('Acción: %s'):format(act),
        icon  = 'fa-solid fa-person',
        canInteract = function() return canUseZone(z, false) end,
        action = function() TriggerEvent('qb-jobcreator:client:doAction', act) end
      })
    end
  end

  exports['qb-target']:AddBoxZone(name, vector3(z.coords.x, z.coords.y, z.coords.z), size, size, {
    name = name, heading = 0.0, minZ = z.coords.z-1.0, maxZ = z.coords.z+2.0
  }, { options = opts, distance = radius + 0.5 })

  z._zoneName = name
end

-- =============================
-- Sync
-- =============================
RegisterNetEvent('qb-jobcreator:client:rebuildZones', function(zones)
  removeAll()
  for _, z in ipairs(zones or {}) do
    Active[#Active+1] = z
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
