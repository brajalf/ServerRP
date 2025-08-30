Bridge = {}

function Bridge.Notify(src, msg, typ)
  typ = typ or 'inform'
  if Config.NotifySystem == 'ox' then
    if src == 0 then
      lib.notify({ title = Config.NotifyTitle, description = msg, type = typ })
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

function Bridge.HasItem(src, item, amount)
  amount = amount or 1
  if Config.InventoryType == 'ox' then
    local count = exports.ox_inventory:Search(src, 'count', item) or 0
    return count >= amount, count
  else
    local QBCore = exports['qb-core']:GetCoreObject()
    local Player = QBCore.Functions.GetPlayer(src)
    local itm = Player and Player.Functions.GetItemByName(item)
    local qty = itm and itm.amount or 0
    return qty >= amount, qty
  end
end

function Bridge.RemoveItem(src, item, amount)
  if Config.InventoryType == 'ox' then
    return exports.ox_inventory:RemoveItem(src, item, amount or 1)
  else
    local QBCore = exports['qb-core']:GetCoreObject()
    return QBCore.Functions.GetPlayer(src).Functions.RemoveItem(item, amount or 1)
  end
end

function Bridge.AddItem(src, item, amount, metadata)
  if Config.InventoryType == 'ox' then
    return exports.ox_inventory:AddItem(src, item, amount or 1, metadata)
  else
    local QBCore = exports['qb-core']:GetCoreObject()
    return QBCore.Functions.GetPlayer(src).Functions.AddItem(item, amount or 1, false, metadata)
  end
end

function Bridge.GetJob(src)
  local QBCore = exports['qb-core']:GetCoreObject()
  local Player = QBCore.Functions.GetPlayer(src)
  return Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name or 'unemployed'
end

function Bridge.HasSkill(src, skillIID)
  if not Config.DevSkillTree or not skillIID or skillIID == '' then return true end
  -- Integración real de skill aquí si la tienes:
  -- return exports['devhub_skillTree']:HasSkill(src, skillIID)
  return true
end

function Bridge.GetLicense(src)
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:find('license:') then return id end
  end
  return GetPlayerIdentifier(src, 0) or ('src:%s'):format(src)
end
