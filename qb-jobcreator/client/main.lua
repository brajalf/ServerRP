QBCore = exports['qb-core']:GetCoreObject()

local Jobs, Zones = {}, {}
local uiOpen = false
local craftZone = nil

-- Notification wrapper
local function Notify(msg, typ)
  typ = typ or 'primary'
  local system = (Config and Config.NotifySystem) or 'qb'
  local title = (Config and Config.NotifyTitle) or 'Job Creator'
  if system == 'ox' and lib and lib.notify then
    lib.notify({ title = title, description = msg, type = typ })
  elseif system == 'custom' and Config and type(Config.CustomNotify) == 'function' then
    Config.CustomNotify(msg, typ, title)
  else
    TriggerEvent('QBCore:Notify', msg, typ)
  end
end

RegisterNetEvent('qb-jobcreator:client:syncAll', function(jobs, zones)
  Jobs, Zones = jobs or {}, zones or {}
end)

local function findZoneById(id)
  for _, z in ipairs(Zones or {}) do
    if z.id == id then return z end
  end
end

local function ForceClose()
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  uiOpen = false
  craftZone = nil
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
  SendNUIMessage({ action = 'open', payload = { ok = true, jobs = Jobs or {}, zones = Zones or {}, totals = { jobs = 0, employees = 0, money = 0 }, popular = {}, branding = Config and Config.Branding or nil, scope = { mode = 'admin' }, inventory = Config and Config.InventoryType, imagePath = Config and Config.InventoryImagePath } })
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(data)
    if type(data) == 'table' and data.ok then
      data.scope = { mode = 'admin' }
      SendNUIMessage({ action = 'update', payload = data })
    else
      print('[qb-jobcreator] Dashboard vacío o inválido (fallback mostrado).')
    end
  end)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getCraftingData', function(data)
    SendNUIMessage({ action = 'craftingData', payload = { recipes = data or {} } })
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
      scope = { mode = 'boss', job = job },
      inventory = Config and Config.InventoryType,
      imagePath = Config and Config.InventoryImagePath
    }
  })
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(data)
    if type(data) == 'table' and data.ok then
      data.scope = { mode = 'boss', job = job }
      SendNUIMessage({ action = 'update', payload = data })
    end
  end)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getCraftingData', function(data)
    SendNUIMessage({ action = 'craftingData', payload = { recipes = data or {} } })
  end)
end)

-- Abre una tienda registrada en qb-inventory u ox_inventory
RegisterNetEvent('qb-jobcreator:client:openInvShop', function(id, useServerEvent)
  local invType = (Config and Config.InventoryType) or 'qb'
  if invType == 'ox' then
    if GetResourceState('ox_inventory') == 'started' then
      exports.ox_inventory:openInventory('shop', id)
    else
      Notify('Inventario OX no disponible.', 'error')
    end
  elseif invType == 'tgiann' then
    if GetResourceState('tgiann-inventory') == 'started' then
      TriggerServerEvent('inventory:server:OpenInventory', 'shop', id)
    else
      Notify('Inventario Tgiann no disponible.', 'error')
    end
  else
    if GetResourceState('qb-inventory') == 'started' then
      if useServerEvent then
        TriggerServerEvent('qb-inventory:server:OpenShop', id)
      else
        TriggerEvent('qb-inventory:client:OpenShop', id)
      end
    else
      Notify('No hay inventario disponible.', 'error')
    end
  end
end)

RegisterNetEvent('qb-jobcreator:client:openShopMenu', function(zoneId, items)
  if GetResourceState('qb-menu') ~= 'started' then
    Notify('Menú no disponible.', 'error')
    return
  end
  local menu = { { header = 'Tienda', isMenuHeader = true } }
  for _, it in ipairs(items or {}) do
    local info = QBCore.Shared.Items[it.name] or {}
    local label = info.label or it.name
    menu[#menu+1] = {
      header = string.format('%s - $%d', label, it.price or 0),
      txt = string.format('Stock: %d', it.amount or 0),
      params = { event = 'qb-jobcreator:client:selectShopItem', args = { zoneId = zoneId, item = it.name } }
    }
  end
  menu[#menu+1] = { header = 'Cerrar', params = { event = '' } }
  exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('qb-jobcreator:client:selectShopItem', function(data)
  if not data or not data.zoneId or not data.item then return end
  TriggerServerEvent('qb-jobcreator:server:buyItem', data.zoneId, data.item)
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

RegisterNUICallback('getCraftingTable', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getCraftingTable', function(list)
    cb(list or {})
  end, data and data.zoneId)
end)

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

-- ===== Crafteo =====

local function sendCraftUpdate()
  if not craftZone then return end
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getQueue', function(res)
    local ready = {}
    for item, amt in pairs(res and res.inventory or {}) do
      ready[#ready+1] = { id = item, label = item, outputs = { { item = item, amount = amt } }, timestamp = os.time() }
    end
    SendNUIMessage({ action = 'update', data = { queue = (res and res.queue) or {}, ready = ready } })
  end, craftZone)
end

RegisterNetEvent('qb-jobcreator:client:openCrafting', function(zoneId)
  craftZone = zoneId
  uiOpen = true
  SetNuiFocus(true, true)
  local imagePath = GetConvar('inventory:imagepath', Config and Config.InventoryImagePath or 'nui://ox_inventory/web/images/')
  if imagePath:sub(-1) ~= '/' then imagePath = imagePath .. '/' end
  local zone = findZoneById(zoneId)
  local theme = zone and zone.data and zone.data.theme or nil
  local title = (theme and theme.titulo) or (zone and zone.label) or nil
  local category = zone and zone.data and zone.data.category or nil
  SendNUIMessage({
    action = 'openCraft',
    locale = Locales and (Config and Locales[Config.language or Config.Language] or {}) or {},
    images = imagePath,
    theme = theme,
    title = title,
    category = category
  })
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getCraftingData', function(recipes)
    local function getItemCount(name)
      if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetItemCount(name) or 0
      end
      local pdata = QBCore.Functions.GetPlayerData()
      local items = pdata and pdata.items or {}
      local count = 0
      for _, it in pairs(items) do
        if it and it.name == name then
          count = count + (it.amount or it.count or 0)
        end
      end
      return count
    end

    local transformed = {}
    local oxItems = {}
    local showLocked = Config.LockedItemsDisplay and Config.LockedItemsDisplay.showLocked
    if GetResourceState('ox_inventory') == 'started' then
      oxItems = exports.ox_inventory:Items() or {}
    end
    for _, recipe in ipairs(recipes or {}) do
      if not recipe.lockedByJob or showLocked then
        local mats = {}
        local haveAny, haveAll = false, true
        for _, inp in ipairs(recipe.inputs or {}) do
          local need = tonumber(inp.amount) or 0
          local have = getItemCount(inp.item)
          mats[#mats+1] = { item = inp.item, need = need, have = have, noConsume = inp.noConsume }
          if have >= need and need > 0 then
            haveAny = true
          else
            if have > 0 then haveAny = true end
            haveAll = false
          end
        end
        local status = 'none'
        if haveAll and #mats > 0 then status = 'all' elseif haveAny then status = 'some' end
        local info = oxItems[recipe.output and recipe.output.item or recipe.name] or {}
        transformed[#transformed+1] = {
          item = recipe.output and recipe.output.item or recipe.name,
          label = (recipe.output and recipe.output.label) or recipe.name,
          materials = mats,
          outputs = { { item = recipe.output.item, amount = recipe.output.amount } },
          status = status,
          image = info.image or (recipe.output.item .. '.png'),
          lockedByJob = recipe.lockedByJob
        }
      end
    end

    QBCore.Functions.TriggerCallback('qb-jobcreator:server:getQueue', function(res)
      local ready = {}
      for item, amt in pairs(res and res.inventory or {}) do
        ready[#ready+1] = { id = item, label = item, outputs = { { item = item, amount = amt } }, timestamp = os.time() }
      end
      SendNUIMessage({ action = 'init', data = { recipes = transformed, queue = res and res.queue or {}, ready = ready } })
    end, zoneId)
  end, zoneId)
end)

RegisterNUICallback('craft', function(data, cb)
  if craftZone and data and data.item then
    TriggerServerEvent('qb-jobcreator:server:craft', craftZone, data.item, tonumber(data.amount) or 1)
    SetTimeout(200, sendCraftUpdate)
  end
  cb(true)
end)

RegisterNUICallback('collect', function(data, cb)
  if craftZone then
    TriggerServerEvent('qb-jobcreator:server:collectCrafted', craftZone)
    SetTimeout(200, sendCraftUpdate)
  end
  cb(true)
end)

RegisterNUICallback('leaveAll', function(_, cb)
  if craftZone then
    QBCore.Functions.TriggerCallback('qb-jobcreator:server:getQueue', function(res)
      for _, e in ipairs(res and res.queue or {}) do
        TriggerServerEvent('qb-jobcreator:server:cancelCraft', craftZone, e.id)
      end
      sendCraftUpdate()
    end, craftZone)
  end
  cb(true)
end)
