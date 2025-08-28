QBCore = exports['qb-core']:GetCoreObject()

local Jobs, Zones = {}, {}
local uiOpen = false

RegisterNetEvent('qb-jobcreator:client:syncAll', function(jobs, zones)
  Jobs, Zones = jobs or {}, zones or {}
end)

local function ForceClose()
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  uiOpen = false
  SendNUIMessage({ action = 'hide' })
end

AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  ForceClose()
end)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function() ForceClose() end)

-- ===== Aperturas =====
RegisterNetEvent('qb-jobcreator:client:openUI', function()
  if uiOpen then ForceClose(); return end
  SetNuiFocus(true, true); SetNuiFocusKeepInput(false); uiOpen = true
  SendNUIMessage({ action = 'open', payload = { ok = true, jobs = Jobs or {}, zones = Zones or {}, totals = { jobs = 0, employees = 0, money = 0 }, popular = {}, branding = Config and Config.Branding or nil, scope = { mode = 'admin' } } })
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(data)
    if type(data) == 'table' and data.ok then
      data.scope = { mode = 'admin' }
      SendNUIMessage({ action = 'update', payload = data })
    else
      print('[qb-jobcreator] Dashboard vacío o inválido (fallback mostrado).')
    end
  end)
end)

RegisterNetEvent('qb-jobcreator:client:openBossUI', function(job)
  if uiOpen then ForceClose() end
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  uiOpen = true
  SendNUIMessage({
    action = 'open',
    payload = {
      ok = true,
      jobs = Jobs or {},
      zones = Zones or {},
      totals = { jobs = 0, employees = 0, money = 0 },
      popular = {},
      branding = Config and Config.Branding or nil,
      scope = { mode = 'boss', job = job }
    }
  })
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(data)
    if type(data) == 'table' and data.ok then
      data.scope = { mode = 'boss', job = job }
      SendNUIMessage({ action = 'update', payload = data })
    end
  end)
end)

-- Abre una tienda registrada en qb-inventory u ox_inventory
RegisterNetEvent('qb-jobcreator:client:openInvShop', function(id, useServerEvent)
  local oxStarted = GetResourceState('ox_inventory') == 'started'
  if oxStarted then
    exports.ox_inventory:openInventory('shop', id)
  else
    if useServerEvent then
      TriggerServerEvent('qb-inventory:server:OpenShop', id)
    else
      TriggerEvent('qb-inventory:client:OpenShop', id)
    end
  end
end)

RegisterNUICallback('close', function(_, cb) ForceClose(); cb(true) end)

-- ===== CRUD Trabajos =====
RegisterNUICallback('createJob', function(data, cb) TriggerServerEvent('qb-jobcreator:server:createJob', data or {}); cb({ ok = true }) end)
RegisterNUICallback('deleteJob', function(data, cb) TriggerServerEvent('qb-jobcreator:server:deleteJob', data and data.name); cb({ ok = true }) end)
RegisterNUICallback('duplicateJob', function(data, cb) TriggerServerEvent('qb-jobcreator:server:duplicateJob', data and data.name, data and data.newName); cb({ ok = true }) end)
RegisterNUICallback('addGrade', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:addGrade', data.job, data.grade, data.data)
  cb({ ok = true })
end)
RegisterNUICallback('updateGrade', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:updateGrade', data.job, data.grade, data.data)
  cb({ ok = true })
end)
RegisterNUICallback('deleteGrade', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:deleteGrade', data.job, data.grade)
  cb({ ok = true })
end)

-- ===== Empleados =====
RegisterNUICallback('getEmployees', function(data, cb) QBCore.Functions.TriggerCallback('qb-jobcreator:server:getEmployees', function(list) cb(list or {}) end, data.job) end)
RegisterNUICallback('fire', function(data, cb) TriggerServerEvent('qb-jobcreator:server:fire', data.job, data.citizenid); cb({ ok = true }) end)
RegisterNUICallback('setGrade', function(data, cb) TriggerServerEvent('qb-jobcreator:server:setGrade', data.job, data.citizenid, data.grade); cb({ ok = true }) end)

-- ===== Reclutamiento =====
local function NearbyFallback(jobName, radius)
  local out = {}
  local me = PlayerId()
  local mySid = GetPlayerServerId(me)
  local coords = GetEntityCoords(PlayerPedId())
  local players = QBCore.Functions.GetPlayersFromCoords(coords, radius or 3.0)
  for _, pid in ipairs(players) do
    local sid = GetPlayerServerId(pid)
    if sid ~= mySid then out[#out+1] = { id = sid, sid = sid, name = ('ID %s'):format(sid) } end
  end
  local pd = QBCore.Functions.GetPlayerData()
  if pd and pd.job and pd.job.name ~= jobName then
    table.insert(out, 1, { id = mySid, sid = mySid, name = ('%s %s (tú)'):format(pd.charinfo and pd.charinfo.firstname or 'ID', pd.charinfo and pd.charinfo.lastname or mySid) })
  end
  return out
end
RegisterNUICallback('getNearby', function(data, cb)
  local jobName = data and data.job or 'unemployed'
  local radius = (data and data.radius) or 3.0
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getNearbyPlayers', function(list)
    if list and type(list) == 'table' and #list > 0 then cb(list) else cb(NearbyFallback(jobName, radius)) end
  end, jobName, radius)
end)
RegisterNUICallback('recruit', function(data, cb)
  local jobName = data and data.job
  local grade = tonumber(data and data.grade) or 0
  local targetId = tonumber(data and (data.target or data.sid or data.targetId)) or -1
  if jobName and targetId ~= -1 then
    TriggerServerEvent('qb-jobcreator:server:recruit', jobName, grade, targetId)
  end
  cb({ ok = true })
end)

-- ===== Cuentas =====
RegisterNUICallback('getAccount', function(data, cb) QBCore.Functions.TriggerCallback('qb-jobcreator:server:getAccount', function(bal) cb(bal or 0) end, data.job) end)
RegisterNUICallback('deposit', function(data, cb) TriggerServerEvent('qb-jobcreator:server:deposit', data.job, data.amount, data.from); cb({ ok = true }) end)
RegisterNUICallback('withdraw', function(data, cb) TriggerServerEvent('qb-jobcreator:server:withdraw', data.job, data.amount, data.to); cb({ ok = true }) end)
RegisterNUICallback('wash', function(data, cb) TriggerServerEvent('qb-jobcreator:server:wash', data.job, data.amount); cb({ ok = true }) end)

-- ===== Zonas =====
RegisterNUICallback('getZones', function(data, cb) QBCore.Functions.TriggerCallback('qb-jobcreator:server:getZones', function(list) cb(list or {}) end, data.job) end)
RegisterNUICallback('createZone', function(data, cb) TriggerServerEvent('qb-jobcreator:server:createZone', data); cb({ ok = true }) end)
RegisterNUICallback('deleteZone', function(data, cb) TriggerServerEvent('qb-jobcreator:server:deleteZone', data.id); cb({ ok = true }) end)
RegisterNUICallback('getCoords', function(_, cb) local p = GetEntityCoords(PlayerPedId()); cb({ x = p.x, y = p.y, z = p.z }) end)

-- Lista de cercanos (por si la UI lo usa)
RegisterNUICallback('nearbyPlayers', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getNearbyPlayers', function(list)
    cb(list or {})
  end, data.job, data.radius or 3.5)
end)

-- Guardar data de una zona (para “vehículos por rango”)
RegisterNUICallback('updateZone', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:updateZone', tonumber(data.id), data.data, data.label, data.radius, data.coords)
  cb({ ok = true })
end)

-- ===== Recetas =====
RegisterNUICallback('getRecipes', function(_, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getRecipes', function(list) cb(list or {}) end)
end)
RegisterNUICallback('saveRecipes', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:saveRecipes', data.recipes or {})
  cb({ ok = true })
end)
