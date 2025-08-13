QBCore = exports['qb-core']:GetCoreObject()

-- NUI <-> Client bridge
-- Asegúrate de incluir este archivo en fxmanifest.lua (client_scripts)

local function ok(cb, data)
  if cb then cb(data ~= nil and data or { ok = true }) end
end

-- Cerrar NUI
RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  ok(cb)
end)

-- Dashboard completo
RegisterNUICallback('getDashboard', function(_, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getDashboard', function(data)
    ok(cb, data)
  end)
end)

-- ZONAS
RegisterNUICallback('getZones', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getZones', function(list)
    ok(cb, list)
  end, data and data.job or nil)
end)

RegisterNUICallback('createZone', function(zone, cb)
  TriggerServerEvent('qb-jobcreator:server:createZone', zone)
  ok(cb)
end)

RegisterNUICallback('deleteZone', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:deleteZone', data and data.id)
  ok(cb)
end)

-- EMPLEADOS
RegisterNUICallback('getEmployees', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getEmployees', function(list)
    ok(cb, list)
  end, data and data.job or nil)
end)

RegisterNUICallback('getNearby', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getNearbyPlayers', function(list)
    ok(cb, list)
  end, data and data.job or nil, data and data.radius or 3.0)
end)

RegisterNUICallback('recruit', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:recruit', data.job, data.grade, data.sid)
  ok(cb)
end)

RegisterNUICallback('fire', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:fire', data.job, data.citizenid)
  ok(cb)
end)

RegisterNUICallback('setGrade', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:setGrade', data.job, data.citizenid, data.grade)
  ok(cb)
end)

-- FINANZAS
RegisterNUICallback('getAccount', function(data, cb)
  QBCore.Functions.TriggerCallback('qb-jobcreator:server:getAccount', function(balance)
    ok(cb, { ok = true, balance = balance })
  end, data and data.job or nil)
end)

RegisterNUICallback('deposit', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:deposit', data.job, data.amount, data.from)
  ok(cb)
end)

RegisterNUICallback('withdraw', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:withdraw', data.job, data.amount, data.to)
  ok(cb)
end)

RegisterNUICallback('wash', function(data, cb)
  TriggerServerEvent('qb-jobcreator:server:wash', data.job, data.amount)
  ok(cb)
end)

-- Utilidad para el modal: coords actuales del jugador
RegisterNUICallback('getCoords', function(_, cb)
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local h = GetEntityHeading(ped)
  ok(cb, { x = p.x, y = p.y, z = p.z, w = h })
end)
