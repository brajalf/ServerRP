local QBCore = exports['qb-core']:GetCoreObject()
local currentStation = nil

RegisterNetEvent('invictus_craft:client:openStation', function(stationId)
  currentStation = stationId
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'open', locale = Locales[Config.language], images = Config.InventoryImagePath })
  QBCore.Functions.TriggerCallback('invictus_craft:server:stationData', function(payload)
    SendNUIMessage({ action = 'init', data = payload })
  end, stationId)
end)

RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  currentStation = nil
  cb(true)
end)

RegisterNUICallback('craft', function(data, cb)
  local item = data.item
  local amount = math.max(1, tonumber(data.amount or 1))
  TriggerServerEvent('invictus_craft:server:startCraft', currentStation, item, amount)
  cb(true)
end)

RegisterNUICallback('leaveAll', function(_, cb)
  TriggerServerEvent('invictus_craft:server:leaveAllQueues', currentStation)
  cb(true)
end)

RegisterNUICallback('collect', function(data, cb)
  TriggerServerEvent('invictus_craft:server:collectOutput', currentStation, data.id)
  cb(true)
end)

RegisterNetEvent('invictus_craft:client:update', function(payload)
  SendNUIMessage({ action = 'update', data = payload })
end)

RegisterNetEvent('invictus_craft:client:notify', function(msg, typ)
  if Config.NotifySystem == 'ox' and lib and lib.notify then
    lib.notify({ title = Config.NotifyTitle, description = msg, type = typ or 'inform' })
  else
    QBCore.Functions.Notify(msg, typ or 'primary')
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  SetNuiFocus(false, false)
end)
