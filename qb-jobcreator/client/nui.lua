local QBCore = exports['qb-core']:GetCoreObject()

-- Abrir UI admin
RegisterNetEvent('qb-jobcreator:client:openUI', function()
  SetNuiFocus(true, true)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(payload)
    SendNUIMessage({ action = 'open', payload = payload })
  end)
end)

-- Abrir UI de jefe (sólo su trabajo)
RegisterNetEvent('qb-jobcreator:client:openBossUI', function(job)
  SetNuiFocus(true, true)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(payload)
    payload = payload or {}
    payload.scope = { mode = 'boss', job = job }
    SendNUIMessage({ action = 'open', payload = payload })
  end)
end)

RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  cb('ok')
end)

-- ===== NUI callbacks que pide tu app.js =====
RegisterNUICallback('getEmployees', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getEmployees', function(list) cb(list or {}) end, data.job)
end)

RegisterNUICallback('getZones', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getZones', function(list) cb(list or {}) end, data.job)
end)

local busyCreate = false
RegisterNUICallback('createZone', function(data, cb)
  if busyCreate then cb('busy'); return end
  busyCreate = true
  TriggerServerEvent('qb-jobcreator:server:createZone', data)
  SetTimeout(800, function() busyCreate = false end) -- anti doble click
  cb('ok')
end)

RegisterNUICallback('deleteZone', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:deleteZone', data.id)
  cb('ok')
end)

RegisterNUICallback('getCoords', function(_, cb)
  local ped = PlayerPedId()
  local c = GetEntityCoords(ped)
  cb({ x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0, w = GetEntityHeading(ped) + 0.0 })
end)

RegisterNUICallback('recruit', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:recruit', data.job, data.grade, data.sid)
  cb('ok')
end)

RegisterNUICallback('fire', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:fire', data.job, data.citizenid); cb('ok')
end)

RegisterNUICallback('setGrade', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:setGrade', data.job, data.citizenid, data.grade); cb('ok')
end)

RegisterNUICallback('getNearby', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getNearbyPlayers', function(list) cb(list or {}) end, data.job, data.radius or 3.0)
end)

RegisterNUICallback('getAccount', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getAccount', function(bal) cb(bal or 0) end, data.job)
end)

RegisterNUICallback('deposit',   function(data, cb) TriggerServerEvent('qb-jobcreator:server:deposit',   data.job, data.amount, data.from); cb('ok') end)
RegisterNUICallback('withdraw',  function(data, cb) TriggerServerEvent('qb-jobcreator:server:withdraw',  data.job, data.amount, data.to);   cb('ok') end)
RegisterNUICallback('wash',      function(data, cb) TriggerServerEvent('qb-jobcreator:server:wash',      data.job, data.amount);            cb('ok') end)
RegisterNUICallback('createJob', function(data, cb) TriggerServerEvent('qb-jobcreator:server:createJob', data);                              cb('ok') end)
RegisterNUICallback('deleteJob', function(data, cb) TriggerServerEvent('qb-jobcreator:server:deleteJob', data.name);                        cb('ok') end)
RegisterNUICallback('duplicateJob', function(data, cb) TriggerServerEvent('qb-jobcreator:server:duplicateJob', data.name, data.newName);   cb('ok') end)
RegisterNUICallback('updateGradeSalary', function(data, cb) TriggerServerEvent('qb-jobcreator:server:updateGradeSalary', data.job, data.grade, data.salary); cb('ok') end)
