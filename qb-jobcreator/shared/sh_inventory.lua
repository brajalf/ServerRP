local QBCore = exports['qb-core']:GetCoreObject()

Inventory = {}

local function useOx()
  if Config and Config.Integrations then
    if Config.Integrations.UseOxInventory then return true end
    if Config.Integrations.UseQbInventory then return false end
  end
  return GetResourceState('ox_inventory') == 'started'
end

function Inventory.CheckItem(src, item, amount)
  local count = 0
  if useOx() then
    count = exports.ox_inventory:Search(src, 'count', item) or 0
  else
    local Player = QBCore.Functions.GetPlayer(src)
    local it = Player and Player.Functions.GetItemByName(item)
    count = it and (it.amount or it.count or 0) or 0
  end
  if amount then
    return count >= amount
  end
  return count
end

function Inventory.RemoveItem(src, item, amount, metadata, slot)
  if useOx() then
    return exports.ox_inventory:RemoveItem(src, item, amount or 1, metadata, slot)
  else
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.RemoveItem(item, amount or 1, slot)
  end
end

function Inventory.AddItem(src, item, amount, slot, metadata)
  if useOx() then
    return exports.ox_inventory:AddItem(src, item, amount or 1, metadata, slot)
  else
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.AddItem(item, amount or 1, slot, metadata)
  end
end

return Inventory

