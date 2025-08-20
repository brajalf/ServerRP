local QBCore = exports['qb-core']:GetCoreObject()

-- Utilidades internas
local function _player(src) return QBCore.Functions.GetPlayer(src) end
local function _sum(t) local s=0; for _,v in ipairs(t or {}) do s=s+ (tonumber(v.amount) or v.count or 0) end; return s end
local function _matchesMeta(itemMeta, meta)
  if not meta or not itemMeta then return true end
  for k,v in pairs(meta) do if itemMeta[k] ~= v then return false end end
  return true
end

-- 1) AddItem
exports('AddItem', function(source, name, count, metadata, slot)
  local p = _player(source); if not p then return false end
  return p.Functions.AddItem(name, tonumber(count) or 1, slot or false, metadata or nil) == true
end)

-- 2) RemoveItem
exports('RemoveItem', function(source, name, count, metadata, slot)
  local p = _player(source); if not p then return false end
  return p.Functions.RemoveItem(name, tonumber(count) or 1, slot or slot, metadata or nil) == true
end)

-- 3) CanCarryItem (peso/slots básico con MaxWeight/MaxSlots del qb-inventory)
exports('CanCarryItem', function(source, name, count, metadata)
  local p = _player(source); if not p then return false end
  -- Si tu qb-inventory expone un helper mejor, úsalo aquí.
  return true
end)

-- 4) GetItemCount (con filtro metadata opcional)
exports('GetItemCount', function(source, name, metadata)
  local p = _player(source); if not p then return 0 end
  local items = p.Functions.GetItemsByName(name) or {}
  if metadata then
    local cnt = 0
    for _,it in pairs(items) do if _matchesMeta(it.info, metadata) then cnt = cnt + (it.amount or it.count or 1) end end
    return cnt
  end
  return _sum(items)
end)

-- 5) GetItem (primer item que coincida; opcional slot)
exports('GetItem', function(source, name, metadata, slot)
  local p = _player(source); if not p then return nil end
  if slot then
    local it = p.PlayerData.items[tonumber(slot)]
    if it and it.name == name and _matchesMeta(it.info, metadata) then return it end
    return nil
  end
  local items = p.Functions.GetItemsByName(name) or {}
  for _,it in pairs(items) do if _matchesMeta(it.info, metadata) then return it end end
  return nil
end)

-- 6) SetMetadata (actualiza info del item, similar a OX SetItemMetadata)
exports('SetMetadata', function(source, slot, newmeta)
  local p = _player(source); if not p then return false end
  local s = tonumber(slot); if not s then return false end
  local it = p.PlayerData.items[s]; if not it then return false end
  it.info = newmeta or {}
  p.Functions.SetPlayerData('items', p.PlayerData.items)
  TriggerClientEvent('qb-inventory:client:updateInventory', source)
  return true
end)

-- 7) OpenInventory (mapear contenedores OX a QB)
-- types: 'player','stash','drop','trunk','glovebox','shop','otherplayer'
exports('OpenInventory', function(source, invType, name, data)
  if invType == 'stash' then
    exports['qb-inventory']:OpenInventory(source, name, {
      label = data and data.label or name,
      maxweight = data and (data.maxweight or data.weight) or 50000,
      slots = data and data.slots or 30
    })
  elseif invType == 'shop' then
    if exports['qb-inventory'].CreateShop then
      exports['qb-inventory']:CreateShop({
        name = name, label = data and data.label or name, items = data and data.items or {}
      })
    end
    exports['qb-inventory']:OpenInventory(source, name)
  elseif invType == 'drop' then
    exports['qb-inventory']:OpenInventory(source, 'drop', name) -- o la firma que uses
  elseif invType == 'otherplayer' then
    TriggerClientEvent('qb-inventory:client:openOtherPlayer', source, name) -- crea este evento si no existe
  else
    -- player por defecto
    TriggerClientEvent('qb-inventory:client:openInventory', source)
  end
end)

-- 8) GetInventory / GetInventoryItems (para leer contenedores desde otros recursos)
exports('GetInventory', function(invType, name)
  -- Devuelve la tabla interna del contenedor si está cargada (ajusta a tu estructura)
  local invs = Inventories and Inventories[invType]
  return invs and invs[name] or nil
end)

exports('GetInventoryItems', function(invType, name)
  local inv = exports['qb-inventory']:GetInventory(invType, name) -- si no tienes este export, devuelve inv.items
  return inv and inv.items or {}
end)

-- 9) Hooks mínimos (opcionales) para compatibilidad:
exports('RegisterHook', function(event, handler) end)

