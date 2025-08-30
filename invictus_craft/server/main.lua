local QBCore = exports['qb-core']:GetCoreObject()
local Inventory = require '@qb-jobcreator/shared/sh_inventory.lua'
local Utils = require '@qb-jobcreator/shared/sh_utils.lua'

local function Notify(src, msg, typ)
  typ = typ or 'inform'
  if Config.NotifySystem == 'ox' then
    if src == 0 then
      if lib and lib.notify then lib.notify({ title = Config.NotifyTitle, description = msg, type = typ }) end
    else
      TriggerClientEvent('ox_lib:notify', src, { title = Config.NotifyTitle, description = msg, type = typ })
    end
  elseif Config.NotifySystem == 'qb' then
    if src == 0 then print(('[Notify:%s] %s'):format(typ, msg)) return end
    TriggerClientEvent('QBCore:Notify', src, msg, typ)
  else
    if src == 0 then print(('[Notify:%s] %s'):format(typ, msg)) return end
    TriggerClientEvent('chat:addMessage', src, { args = { '^2'..Config.NotifyTitle, msg } })
  end
end

local Queues = {}           -- [stationId] = { [src] = { entries = { {id, item, amount, endTime, label}, ... } } }
local Ready  = {}           -- [license] = { {id, stationId, label, outputs, timestamp}, ... }

local function kvKey(license) return ('invictus_craft_ready:%s'):format(license) end
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

local function fetchStations()
  local list = {}
  local zones = exports['qb-jobcreator']:GetZones() or {}
  for _, z in ipairs(zones) do
    if z.ztype == 'crafting' then
      list[#list+1] = {
        id = tostring(z.id),
        name = z.label or ('Craft '..z.id),
        category = z.data and z.data.category,
        job = z.data and z.data.job,
        icon = z.data and z.data.icon or 'fa-solid fa-hammer'
      }
    end
  end
  return list
end

local function findStation(id)
  for _, s in ipairs(fetchStations()) do
    if tostring(s.id) == tostring(id) then return s end
  end
end

local function arrayIncludes(arr, v)
  if type(arr) == 'table' then for _,x in ipairs(arr) do if x == v then return true end end
  else return arr == v end
  return false
end

local function getRecipeByItem(item)
  for _, r in ipairs(Config.Recipes) do if r.item == item then return r end end
end

local function canUseStation(src, station)
  if not station or not station.job then return true end
  local job = Utils.GetJob(src)
  return type(station.job) == 'table' and arrayIncludes(station.job, job) or station.job == job
end

local function matsStatusForPlayer(src, recipe)
  local hasAll, hasSome = true, false
  local mats = {}

  for _,m in ipairs(recipe.materials or {}) do
    local ok, count = Inventory.HasItem(src, m.item, m.amount)
    mats[#mats+1] = { item = m.item, need = m.amount, have = count, noConsume = m.noConsume or false }
    if not ok then hasAll = false end
    if count > 0 then hasSome = true end
  end
  local status = hasAll and 'all' or (hasSome and 'some' or 'none')
  return status, mats
end

local function buildStationPayload(src, stationId)
  local st = findStation(stationId)
  if not st then return { error = 'station not found' } end

  local license = Utils.GetLicense(src)
  local readyList = loadReady(license)

  local recipes = {}
  local jobName = Utils.GetJob(src)

  for _, r in ipairs(Config.Recipes) do
    if r.category == st.category then
      local jobAllowed = true
      if r.requiredJob then
        jobAllowed = type(r.requiredJob) == 'table' and arrayIncludes(r.requiredJob, jobName) or r.requiredJob == jobName
      end
      if jobAllowed then
        local skillLocked = not Utils.HasSkill(src, r.skillIID)
        local status, mats = matsStatusForPlayer(src, r)

        recipes[#recipes+1] = {
          item = r.item,
          label = r.label or r.item,
          time = r.time,
          status = status,
          materials = mats,
          outputs = r.outputs or { { item = r.item, amount = 1 } },
          lockedBySkill = skillLocked,
          category = r.category
        }
      end
    end
  end

  Queues[stationId] = Queues[stationId] or {}
  local q = Queues[stationId][src] and Queues[stationId][src].entries or {}

  return {
    station = { id = st.id, name = st.name, category = st.category, icon = st.icon },
    recipes = recipes,
    queue   = q,
    ready   = readyList
  }
end

QBCore.Functions.CreateCallback('invictus_craft:server:stationData', function(src, cb, stationId)
  if not canUseStation(src, findStation(stationId)) then
    Notify(src, 'No tienes acceso a esta estación', 'error')
    cb({}) return
  end
  cb(buildStationPayload(src, stationId))
end)

local function scheduleFinish(stationId, src, entry)
  local ms = math.floor((entry.time or 1) * 1000)
  SetTimeout(ms, function()
    local license = Utils.GetLicense(src)
    local ready = loadReady(license)

    ready[#ready+1] = {
      id = entry.id,
      stationId = stationId,
      label = entry.label,
      outputs = entry.outputs,
      timestamp = os.time()
    }
    saveReady(license)

    local q = Queues[stationId] and Queues[stationId][src]
    if q then
      for i, e in ipairs(q.entries) do
        if e.id == entry.id then table.remove(q.entries, i) break end
      end
    end

    TriggerClientEvent('invictus_craft:client:update', src, buildStationPayload(src, stationId))
    Notify(src, (entry.label .. ' listo para recoger.'), 'success')
  end)
end

RegisterNetEvent('invictus_craft:server:startCraft', function(stationId, item, amount)
  local src = source
  local st  = findStation(stationId)
  if not st then return end
  if not canUseStation(src, st) then Notify(src, 'No puedes usar esta estación', 'error') return end

  amount = math.max(1, math.floor(tonumber(amount or 1)))

  local recipe = getRecipeByItem(item)
  if not recipe or recipe.category ~= st.category then return end

  local job = Utils.GetJob(src)
  if recipe.requiredJob then
    local ok = type(recipe.requiredJob) == 'table' and arrayIncludes(recipe.requiredJob, job) or recipe.requiredJob == job
    if not ok then Notify(src, _L('job_locked'), 'error') return end
  end
  if not Utils.HasSkill(src, recipe.skillIID) then
    Notify(src, _L('skill_locked'), 'error')
    return
  end

  local totalQueued = 0
  for _, stationQueues in pairs(Queues) do
    if stationQueues[src] then totalQueued = totalQueued + (#stationQueues[src].entries) end
  end
  if totalQueued + 1 > Config.MaxItemsPerPlayer then
    Notify(src, _L('queue_limit'), 'error') return
  end

  Queues[stationId] = Queues[stationId] or {}
  local qByStation = Queues[stationId]
  qByStation[src]  = qByStation[src] or { entries = {} }
  local entries    = qByStation[src].entries

  if #entries >= Config.MaxQueueSize then
    Notify(src, _L('queue_full'), 'error') return
  end

  local requiredList = {}
  for _, m in ipairs(recipe.materials or {}) do
    if not m.noConsume then
      requiredList[#requiredList+1] = { item = m.item, amount = (m.amount or 1) * amount }
    end
  end

  for _, req in ipairs(requiredList) do
    local ok, have = Inventory.HasItem(src, req.item, req.amount)
    if not ok then
      Notify(src, _L('not_enough_mats') .. (' (%s %d/%d)'):format(req.item, have, req.amount), 'error')
      return
    end
  end
  for _, req in ipairs(requiredList) do
    Inventory.RemoveItem(src, req.item, req.amount)
  end

  local totalTime = (recipe.time or 1) * amount
  local entryId   = (('%s:%s:%d'):format(stationId, item, os.time() + math.random(999)))
  local label     = recipe.label or item
  local outputs   = recipe.outputs or { { item = recipe.item, amount = 1 } }

  local scaled = {}
  for _, o in ipairs(outputs) do
    scaled[#scaled+1] = { item = o.item, amount = (o.amount or 1) * amount }
  end

  local entry = {
    id = entryId,
    item = item,
    label = label,
    amount = amount,
    outputs = scaled,
    time = totalTime
  }

  entries[#entries+1] = entry
  scheduleFinish(stationId, src, entry)

  Notify(src, _L('queued') .. (' (%s x%d)'):format(label, amount), 'success')
  TriggerClientEvent('invictus_craft:client:update', src, buildStationPayload(src, stationId))
end)

RegisterNetEvent('invictus_craft:server:collectOutput', function(stationId, collectId)
  local src = source
  local license = Utils.GetLicense(src)
  local readyList = loadReady(license)

  local idx, data = nil, nil
  for i, r in ipairs(readyList) do
    if r.id == collectId then idx, data = i, r break end
  end
  if not data then return end

  local okAll = true
  for _, o in ipairs(data.outputs or {}) do
    local ok = Inventory.AddItem(src, o.item, o.amount)
    if not ok then okAll = false end
  end

  if okAll then
    table.remove(readyList, idx)
    saveReady(license)
    Notify(src, ('Recogiste %s'):format(data.label), 'success')
  else
    Notify(src, 'No tienes espacio suficiente', 'error')
  end

  TriggerClientEvent('invictus_craft:client:update', src, buildStationPayload(src, stationId))
end)

RegisterNetEvent('invictus_craft:server:leaveAllQueues', function(stationId)
  local src = source
  if Queues[stationId] and Queues[stationId][src] then
    Queues[stationId][src] = { entries = {} }
    TriggerClientEvent('invictus_craft:client:update', src, buildStationPayload(src, stationId))
    Notify(src, 'Has salido de la cola', 'inform')
  end
end)

  AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    local stations = fetchStations()
    local stationId = stations[1] and stations[1].id
    if stationId then
      TriggerClientEvent('invictus_craft:client:update', src, buildStationPayload(src, stationId))
    end
  end)
