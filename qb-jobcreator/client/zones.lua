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

-- =====================================
-- Helpers vehículo (llaves, asiento, guardar)
-- =====================================
local function GiveKeysByPlate(plate)
  plate = tostring(plate or ''):gsub('%s',''); if plate=='' then return end
  if GetResourceState('qb-vehiclekeys')=='started' then
    TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
  end
  if GetResourceState('qs-vehiclekeys')=='started' then
    TriggerServerEvent('qs-vehiclekeys:server:AcquireVehicleKeys', plate)
  end
end

local function PutPlayerInDriver(veh)
  local ped = PlayerPedId()
  TaskWarpPedIntoVehicle(ped, veh, -1)
  SetVehicleEngineOn(veh, true, true)
end

local function DeleteVehSafe(veh)
  if veh == 0 then return end
  NetworkRequestControlOfEntity(veh)
  local t = GetGameTimer() + 2000
  while not NetworkHasControlOfEntity(veh) and GetGameTimer() < t do Wait(0) end
  SetEntityAsMissionEntity(veh, true, true)
  DeleteVehicle(veh)
  if DoesEntityExist(veh) then DeleteEntity(veh) end
end

local function StoreVehicleSmart()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then return end

  if GetResourceState('qb-garages') == 'started' then
    -- probar nombres usados por forks
    TriggerEvent('qb-garages:client:storeVehicle')
    TriggerEvent('qb-garages:client:StoreVehicle')
    TriggerEvent('garages:client:StoreVehicle')
    -- si a los 800ms el coche sigue existiendo, hacemos fallback (borra)
    SetTimeout(800, function()
      if DoesEntityExist(veh) then
        TaskLeaveVehicle(ped, veh, 0); Wait(350)
        DeleteVehSafe(veh)
        QBCore.Functions.Notify('Vehículo guardado.', 'success')
      end
    end)
    return
  end

  -- sin qb-garages: lo eliminamos limpiamente
  TaskLeaveVehicle(ped, veh, 0); Wait(350)
  DeleteVehSafe(veh)
  QBCore.Functions.Notify('Vehículo guardado.', 'success')
end

-- parser de vehículos por rango: "0=police,2=police2" o tabla { [0]="police" }
local function pickVehicleForGrade(data, myGrade)
  if type(data) ~= 'table' then return nil end
  if data.vehicle and data.vehicle ~= '' then return tostring(data.vehicle) end
  local map = data.vehicles; if not map then return nil end
  local m = {}
  if type(map) == 'string' then
    for part in map:gmatch('[^,]+') do
      local g, model = part:match('^%s*(%d+)%s*=%s*([%w_%-]+)%s*$')
      if g and model then m[tonumber(g)] = model end
    end
  elseif type(map) == 'table' then
    for k, v in pairs(map) do
      local g = tonumber(k); if g and type(v)=='string' and v ~= '' then m[g] = v end
    end
  end
  if m[myGrade] then return m[myGrade] end
  local bestG, bestM
  for g, model in pairs(m) do
    if (not bestG or g > bestG) and g <= myGrade then bestG, bestM = g, model end
  end
  if bestM then return bestM end
  for _, model in pairs(m) do return model end
  return nil
end

-- util: barra de progreso simple
local function Progress(label, ms)
  ms = tonumber(ms) or 3500
  if QBCore.Functions.Progressbar then
    local ok = true; QBCore.Functions.Progressbar('jc_prog', label, ms, false, true, {
      disableMovement=true, disableCarMovement=true, disableMouse=false, disableCombat=true
    }, {}, {}, {}, function() ok=true end, function() ok=false end)
    while ok==true and ms>0 do Wait(50); ms = ms - 50 end
    return ok
  else
    Wait(ms); return true
  end
end

-- util: anima o scenario
local function Play(dict, anim, dur)
  if anim and dict then
    RequestAnimDict(dict); while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(PlayerPedId(), dict, anim, 3.0, 3.0, dur or -1, 1, 0, false, false, false)
  end
end

-- util: jugador cercano
local function GetClosestPlayerToMe(radius)
  local me = PlayerId(); radius = radius or 3.0
  local myPed = PlayerPedId(); local myCoords = GetEntityCoords(myPed)
  local best, dist = -1, radius
  for _, pid in ipairs(GetActivePlayers()) do
    if pid ~= me then
      local ped = GetPlayerPed(pid)
      local d = #(GetEntityCoords(ped) - myCoords)
      if d < dist then best, dist = pid, d end
    end
  end
  if best ~= -1 then return GetPlayerServerId(best) end
  return nil
end

local currentCraftZone

local function openCraftMenu(z)
  currentCraftZone = z.id
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = 'openCraft',
    payload = { zone = z.id, recipes = Config.CraftingRecipes or {} }
  })
end

RegisterNUICallback('craftSelect', function(data, cb)
  currentCraftZone = data and data.zone or currentCraftZone
  cb({ ok = true })
end)

RegisterNUICallback('craft', function(data, cb)
  local zone = data and data.zone or currentCraftZone
  local recipe = data and data.recipe
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'hide' })
  if zone and recipe then
    TriggerServerEvent('qb-jobcreator:server:craft', zone, recipe)
  end
  cb({ ok = true })
end)

RegisterNetEvent('qb-jobcreator:client:craftProgress', function(time)
  QBCore.Functions.Progressbar('jc_craft', 'Crafteando...', time or 3000, false, true, {
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true,
  }, {}, {}, {}, function() end, function() end)
end)

-- =====================================
-- Targets por zona
-- =====================================
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

  elseif z.ztype == 'stash' then
    table.insert(opts, {
      label = 'Abrir Almacén', icon = 'fa-solid fa-box',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        TriggerServerEvent('qb-jobcreator:server:openStash', z.id, Config.Integrations.UseQbInventory and 'qb' or 'ox')
      end
    })

  elseif z.ztype == 'garage' then
    table.insert(opts, {
      label = 'Sacar vehículo de trabajo', icon = 'fa-solid fa-car',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local _, myGrade = playerJobData()
        local model = pickVehicleForGrade(z.data or {}, myGrade) or 'adder'
        QBCore.Functions.SpawnVehicle(model, function(veh)
          local plate = ('%s%03d'):format(string.upper(string.sub(z.job,1,3)), math.random(0,999))
          SetVehicleNumberPlateText(veh, plate)
          SetEntityHeading(veh, z.coords.w or 0.0)
          PutPlayerInDriver(veh)
          GiveKeysByPlate(plate)
        end, vector3(z.coords.x, z.coords.y, z.coords.z), true)
      end
    })

    table.insert(opts, {
      label = 'Guardar vehículo', icon = 'fa-solid fa-warehouse',
      canInteract = function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        return canUseZone(z, false) and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped
      end,
      action = function() StoreVehicleSmart() end
    })

  elseif z.ztype == 'cloakroom' then
    table.insert(opts, {
      label = 'Vestuario', icon = 'fa-solid fa-shirt',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local data = z.data or {}
        local mode = data.mode
        if mode == 'illenium' then
          TriggerEvent('illenium-appearance:client:openWardrobe', {customization = {components = true, props = true}})
        elseif mode == 'qb-clothing' then
          TriggerEvent('qb-clothing:client:openMenu', true) -- true = shop mode
        elseif GetResourceState('illenium-appearance')=='started' then
          -- tienda de ropa / vestuario
          TriggerEvent('illenium-appearance:client:openWardrobe', {customization = {components = true, props = true}})
        elseif GetResourceState('qb-clothing')=='started' then
          TriggerEvent('qb-clothing:client:openMenu', true) -- true = shop mode
        else
          QBCore.Functions.Notify('No hay sistema de vestuario disponible.', 'error')
        end
      end
    })

  elseif z.ztype == 'shop' then
    table.insert(opts, {
      label = 'Abrir tienda', icon = 'fa-solid fa-store',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        TriggerServerEvent('qb-jobcreator:server:openShop', z.id, Config.Integrations.UseQbInventory and 'qb' or 'ox')
      end
    })

  elseif z.ztype == 'collect' then
    table.insert(opts, {
      label = 'Recolectar', icon = 'fa-solid fa-box-open',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local data = z.data or {}
        local time   = tonumber(data.time) or 3000
        if data.dict and data.anim then Play(data.dict, data.anim, time) end
        if Progress('Recolectando...', time) then
          TriggerServerEvent('qb-jobcreator:server:collect', z.id)
        end
      end
    })

  elseif z.ztype == 'spawner' then
    table.insert(opts, {
      label = 'Usar', icon = 'fa-solid fa-cubes',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local model = (z.data and z.data.prop) or 'prop_toolchest_05'
        local coords = vector3(z.coords.x, z.coords.y, z.coords.z)
        local h = (z.coords.w or 0.0)
        local m = joaat(model); RequestModel(m); while not HasModelLoaded(m) do Wait(0) end
        local obj = CreateObject(m, coords.x, coords.y, coords.z-1.0, true, false, false)
        SetEntityHeading(obj, h); FreezeEntityPosition(obj, true)
        QBCore.Functions.Notify('Objeto desplegado.', 'success')
      end
    })

  elseif z.ztype == 'sell' then
    table.insert(opts, {
      label = 'Vender material', icon = 'fa-solid fa-sack-dollar',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        TriggerServerEvent('qb-jobcreator:server:sell', z.id)
      end
    })

  elseif z.ztype == 'register' then
    table.insert(opts, {
      label = 'Cobrar a cercano', icon = 'fa-solid fa-cash-register',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local sid = GetClosestPlayerToMe(3.0)
        if not sid then QBCore.Functions.Notify('No hay clientes cerca.', 'error'); return end
        TriggerServerEvent('qb-jobcreator:server:charge', z.id, sid)
      end
    })

  elseif z.ztype == 'alarm' then
    table.insert(opts, {
      label = 'Activar alarma', icon = 'fa-solid fa-bell',
      canInteract = function() return canUseZone(z, true) end,
      action = function()
        TriggerServerEvent('qb-jobcreator:server:alarm', z.job, (z.data and z.data.code) or 'panic')
      end
    })

  elseif z.ztype == 'anim' then
    table.insert(opts, {
      label = z.label or 'Usar animación', icon = 'fa-solid fa-person',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local d = z.data or {}
        if d.scenario then
          TaskStartScenarioInPlace(PlayerPedId(), d.scenario, 0, true)
        elseif d.dict and d.anim then
          Play(d.dict, d.anim, tonumber(d.time) or 5000)
        else
          QBCore.Functions.Notify('Animación no configurada.', 'error')
        end
      end
    })

  elseif z.ztype == 'music' then
    table.insert(opts, {
      label = 'Reproducir música', icon = 'fa-solid fa-music',
      canInteract = function() return canUseZone(z, false) and GetResourceState('myDj')=='started' end,
      action = function()
        local d = z.data or {}
        local name = d.name or ('jc_ms_%s_%s'):format(z.job, z.id)
        local dist = tonumber(d.range or d.distance) or 20.0
        local pos  = vector3(z.coords.x, z.coords.y, z.coords.z)
        TriggerEvent('myDj:client:openMenu', name, pos, dist)
      end
    })

  elseif z.ztype == 'teleport' then
    table.insert(opts, {
      label = 'Teletransportar', icon = 'fa-solid fa-person-arrow-up-from-line',
      canInteract = function() return canUseZone(z, false) end,
      action = function()
        local d = z.data or {}
        local to = d.to
        if type(to) ~= 'table' then
          QBCore.Functions.Notify('Destino no configurado.', 'error')
          return
        end

        if to.x then
          TriggerServerEvent('qb-jobcreator:server:teleport', z.id, 1)
          return
        end

        if not to[1] then
          QBCore.Functions.Notify('Destino no configurado.', 'error')
          return
        end

        if GetResourceState('qb-menu') == 'started' then
          local menu = { { header = 'Selecciona destino', isMenuHeader = true } }
          for i, dest in ipairs(to) do
            menu[#menu+1] = {
              header = dest.label or ('Destino '..i),
              params = { event = 'qb-jobcreator:client:teleportSelect', args = { zone = z.id, index = i } }
            }
          end
          exports['qb-menu']:openMenu(menu)
        else
          TriggerServerEvent('qb-jobcreator:server:teleport', z.id, 1)
        end
      end
    })

  elseif z.ztype == 'crafting' then
    table.insert(opts, {
      label = 'Craftear', icon = 'fa-solid fa-hammer',
      canInteract = function() return canUseZone(z, false) end,
      action = function() openCraftMenu(z) end
    })
  end

  exports['qb-target']:AddBoxZone(name, vector3(z.coords.x, z.coords.y, z.coords.z), size, size, {
    name = name, heading = 0.0, minZ = z.coords.z-1.0, maxZ = z.coords.z+2.0
  }, { options = opts, distance = radius + 0.5 })

  z._zoneName = name
end

RegisterNetEvent('qb-jobcreator:client:teleportSelect', function(data)
  if not data or not data.zone or not data.index then return end
  TriggerServerEvent('qb-jobcreator:server:teleport', data.zone, data.index)
end)

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

-- =============================
-- TARGETS GLOBALES (jugador/vehículo) por trabajo
-- =============================
local globalsAdded = false

local function isJob(job)
  local name = playerJobData()
  return (name == job) or hasMultiJob(job)
end

local function addGlobalTargetsOnce()
  if globalsAdded or not Config.Integrations.UseQbTarget then return end
  globalsAdded = true

  -- ----- EMS: Revivir / Curar -----
  exports['qb-target']:AddGlobalPlayer({
    options = {
      {
        label = 'Reanimar',
        icon  = 'fa-solid fa-kit-medical',
        canInteract = function(entity, distance)
          return isJob('ambulance') and distance <= 2.2 and IsPedDeadOrDying(entity, true)
        end,
        action = function(entity)
          if GetResourceState('qb-ambulancejob')=='started' then
            TriggerEvent('qb-ambulancejob:client:RevivePlayer', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
          elseif GetResourceState('hospital')=='started' then
            TriggerEvent('hospital:client:RevivePlayer', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
          else
            -- fallback: set health
            SetEntityHealth(entity, 200)
            QBCore.Functions.Notify('Paciente reanimado (fallback).', 'success')
          end
        end
      },
      {
        label = 'Curar heridas',
        icon  = 'fa-solid fa-bandage',
        canInteract = function(entity, distance)
          return isJob('ambulance') and distance <= 2.2 and not IsPedDeadOrDying(entity, true)
        end,
        action = function(entity)
          if GetResourceState('qb-ambulancejob')=='started' then
            TriggerEvent('qb-ambulancejob:client:TreatWounds', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
          elseif GetResourceState('hospital')=='started' then
            TriggerEvent('hospital:client:TreatWounds')
          else
            QBCore.Functions.Notify('Curación básica aplicada (fallback).', 'primary')
          end
        end
      },
    },
    distance = 2.2
  })

  -- ----- POLICÍA: Esposar / Escoltar / Meter/Sacar vehículo -----
  exports['qb-target']:AddGlobalPlayer({
    options = {
      {
        label = 'Esposar / Quitar esposas',
        icon  = 'fa-solid fa-handcuffs',
        canInteract = function(_, distance) return isJob('police') and distance <= 2.0 end,
        action = function(entity)
          if GetResourceState('qb-policejob')=='started' then
            TriggerServerEvent('police:server:CuffPlayer', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
          else
            TriggerEvent('police:client:CuffPlayer') -- muchos forks escuchan este
          end
        end
      },
      {
        label = 'Escoltar',
        icon  = 'fa-solid fa-person-walking',
        canInteract = function(_, distance) return isJob('police') and distance <= 2.0 end,
        action = function(entity)
          if GetResourceState('qb-policejob')=='started' then
            TriggerEvent('police:client:EscortPlayer', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
          else
            TriggerEvent('police:client:Escort') -- fallback común
          end
        end
      },
      {
        label = 'Meter al vehículo',
        icon  = 'fa-solid fa-car-side',
        canInteract = function(_, distance) return isJob('police') and distance <= 2.0 end,
        action = function(entity)
          TriggerEvent('police:client:PutInVehicle', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
        end
      },
      {
        label = 'Sacar del vehículo',
        icon  = 'fa-solid fa-person-through-window',
        canInteract = function(_, distance) return isJob('police') and distance <= 2.0 end,
        action = function(entity)
          TriggerEvent('police:client:SetOutVehicle', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
        end
      },
    },
    distance = 2.0
  })

  -- ----- MECÁNICO: Reparar / Limpiar / Incautar -----
  exports['qb-target']:AddGlobalVehicle({
    options = {
      {
        label = 'Reparar vehículo',
        icon  = 'fa-solid fa-screwdriver-wrench',
        canInteract = function(_, distance) return isJob('mechanic') and distance <= 2.8 end,
        action = function(entity)
          SetVehicleFixed(entity); SetVehicleDeformationFixed(entity); SetVehicleEngineOn(entity, true, true)
        end
      },
      {
        label = 'Limpiar vehículo',
        icon  = 'fa-solid fa-broom',
        canInteract = function(_, distance) return (isJob('mechanic') or isJob('police') or isJob('ambulance')) and distance <= 2.8 end,
        action = function(entity) SetVehicleDirtLevel(entity, 0.0) end
      },
      {
        label = 'Incautar',
        icon  = 'fa-solid fa-truck-ramp-box',
        canInteract = function(_, distance) return isJob('police') and distance <= 2.8 end,
        action = function(entity)
          DeleteEntity(entity)
          QBCore.Functions.Notify('Vehículo incautado.', 'success')
        end
      },
    },
    distance = 2.8
  })
end

-- Al cargar zonas o cambiar de trabajo añadimos los globales (una vez)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() addGlobalTargetsOnce() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate',  function() addGlobalTargetsOnce() end)
CreateThread(function() Wait(1000); addGlobalTargetsOnce() end)
