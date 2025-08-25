----------------------------------------------------------------
-- qb-inventory (compat for ox) - SERVER
----------------------------------------------------------------
local QBCore = exports['qb-core']:GetCoreObject()

-- =============== Utils ===============
local normalize = require 'qb-inventory.shared.normalize'

-- =============== Exports qb → ox ===============
exports('AddItem', function(source, name, amount, metadata, slot)
    return exports.ox_inventory:AddItem(source, string.lower(name), amount or 1, metadata, slot)
end)

exports('RemoveItem', function(source, name, amount, metadata, slot)
    return exports.ox_inventory:RemoveItem(source, string.lower(name), amount or 1, metadata, slot)
end)

exports('HasItem', function(source, items, amount, metadata)
    local list = normalize(items)
    local needed = amount or 1
    for _, it in ipairs(list) do
        local cnt = exports.ox_inventory:Search(source, 'count', string.lower(it.name), metadata or it.metadata)
        if cnt >= (it.amount or needed) then return true end
    end
    return false
end)

exports('GetItem', function(source, name, metadata)
    local slots = exports.ox_inventory:Search(source, 'slots', string.lower(name), metadata)
    if slots and #slots > 0 then return slots[1] end
    return nil
end)

exports('GetItemsByName', function(source, name, metadata)
    return exports.ox_inventory:Search(source, 'slots', string.lower(name), metadata)
end)

exports('CanCarryItem', function(source, name, amount, metadata)
    return exports.ox_inventory:CanCarryItem(source, string.lower(name), amount or 1, metadata)
end)

exports('SetMetadata', function(source, name, metadata, amount, slot)
    return exports.ox_inventory:SetMetadata(source, string.lower(name), metadata, amount, slot)
end)

-- =============== Helper apertura server ===============
local function openInvServer(src, invType, identifier)
    -- Nunca uses OpenInventory (ya no existe).
    if invType == 'stash' then
        return exports.ox_inventory:forceOpenInventory(src, 'stash', identifier)
    elseif invType == 'trunk' then
        return exports.ox_inventory:forceOpenInventory(src, 'trunk', identifier)
    elseif invType == 'glovebox' then
        return exports.ox_inventory:forceOpenInventory(src, 'glovebox', identifier)
    elseif invType == 'shop' then
        TriggerClientEvent('qb-inventory:client:OpenShop', src, identifier)
        return true
    else
        print(('[qb-inv compat] invType no manejado: %s'):format(tostring(invType)))
        return false
    end
end

-- =============== STASHES ===============
local RegisteredStashes = {}

exports('CreateStash', function(id, label, slots, weight, owner, groups)
    if RegisteredStashes[id] then return true end
    RegisteredStashes[id] = true
    return exports.ox_inventory:RegisterStash(id, label or id, slots or 50, weight or 400000, owner, groups)
end)

exports('OpenStash', function(source, id)
    if not RegisteredStashes[id] then
        exports.ox_inventory:RegisterStash(id, id, 50, 400000, true)
        RegisteredStashes[id] = true
    end
    return openInvServer(source, 'stash', id)
end)

-- Handler clásico (muchos scripts QB lo llaman)
RegisterNetEvent('inventory:server:OpenInventory', function(inventoryType, identifier, extraData)
    local src = source
    if inventoryType == 'shop' then
        TriggerClientEvent('qb-inventory:client:OpenShop', src, identifier)
        return
    elseif inventoryType == 'stash' then
        local stashId = identifier or ('stash_' .. src)
        if not RegisteredStashes[stashId] then
            exports.ox_inventory:RegisterStash(
                stashId, stashId,
                (extraData and extraData.slots) or 50,
                (extraData and extraData.weight) or 400000,
                extraData and extraData.owner,
                extraData and extraData.groups
            )
            RegisteredStashes[stashId] = true
        end
        openInvServer(src, 'stash', stashId)
    elseif inventoryType == 'trunk' then
        openInvServer(src, 'trunk', identifier)
    elseif inventoryType == 'glovebox' then
        openInvServer(src, 'glovebox', identifier)
    else
        print(('[qb-inv compat] OpenInventory tipo no manejado: %s'):format(tostring(inventoryType)))
    end
end)

-- =========================
-- SHOPS  (QB → OX con cuentas de QBCore)
-- =========================
local Shops = {}

local function qbProductsToOx(products)
    local inv = {}
    for _, p in pairs(products or {}) do
        if p.name then
            inv[#inv+1] = {
                name     = string.lower(p.name),
                price    = tonumber(p.price) or 0,
                metadata = p.info,
                count    = p.amount -- stock opcional (si tu Config lo usa)
            }
        end
    end
    return inv
end

-- Registra una tienda en OX pero guardamos el "account" para cobro
exports('RegisterShop', function(id, label, account, products, locations, groups)
    Shops[id] = {
        account = account or 'cash' -- 'cash' o 'bank'
    }

    -- NOTA: ox_inventory usará su lógica, pero nos aseguramos de pasar inventario y props.
    -- El 'account' lo guardamos aparte y lo usamos al comprar (ver handler más abajo).
    exports.ox_inventory:RegisterShop(id, {
        name      = label or id,
        inventory = qbProductsToOx(products),
        locations = locations,
        groups    = groups
    })

    return true
end)

-- Abrir shop (server -> client)
exports('OpenShop', function(source, id)
    if not Shops[id] then
        print(('[qb-inventory compat] OpenShop no registrado: %s'):format(tostring(id)))
        return false
    end
    TriggerClientEvent('qb-inventory:client:OpenShop', source, id)
    return true
end)

RegisterNetEvent('qb-inventory:server:OpenShop', function(id)
    local src = source
    if not Shops[id] then return end
    TriggerClientEvent('qb-inventory:client:OpenShop', src, id)
end)

-- ============== Cobro manual seguro (cash/bank de QBCore) ==============
-- Este handler intercepta la compra y realiza el cobro con dinero de QBCore,
-- luego entrega el ítem usando ox_inventory.
-- Llama a este evento desde tus scripts de shop si no ves que cobre bien por defecto.
-- Ejemplo de uso en cliente: TriggerServerEvent('qb-inventory:server:BuyItem', shopId, itemName, price, count, metadata)
RegisterNetEvent('qb-inventory:server:BuyItem', function(shopId, itemName, price, count, metadata)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local shop = Shops[shopId]
    if not Player or not shop then return end

    itemName = string.lower(itemName)
    price    = tonumber(price) or 0
    count    = tonumber(count) or 1
    if price <= 0 or count <= 0 then return end

    -- Verificar saldo
    local acc = shop.account == 'bank' and 'bank' or 'cash'
    local bal = Player.PlayerData.money[acc] or 0
    local total = price * count
    if bal < total then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes suficiente dinero', 'error')
        return
    end

    -- Cobrar
    Player.Functions.RemoveMoney(acc, total, ('Shop purchase %s x%s'):format(itemName, count))

    -- Entregar
    local ok = exports.ox_inventory:AddItem(src, itemName, count, metadata)
    if not ok then
        -- Reembolsar si no cabe
        Player.Functions.AddMoney(acc, total, ('Refund %s x%s'):format(itemName, count))
        TriggerClientEvent('QBCore:Notify', src, 'No tienes espacio en el inventario', 'error')
        return
    end

    TriggerClientEvent('QBCore:Notify', src, ('Compraste %s x%s'):format(itemName, count), 'success')
end)
-- Comando simple: /qbgiveitem [id] [item] [count]
QBCore.Commands.Add('qbgiveitem', 'Dar ítem (wrapper ox)', {
    {name='id', help='Player ID'},
    {name='item', help='Item name'},
    {name='count', help='Cantidad'}
}, false, function(source, args)
    local target = tonumber(args[1] or '')
    local item   = args[2]
    local count  = tonumber(args[3] or '1')
    if not target or not item then
        if source then
            TriggerClientEvent('QBCore:Notify', source, 'Uso: /qbgiveitem [id] [item] [count]', 'error')
        end
        return
    end
    exports.ox_inventory:AddItem(target, string.lower(item), count or 1)
    if source then
        TriggerClientEvent('QBCore:Notify', source, ('Dado %s x%s a %s'):format(item, count or 1, target), 'success')
    end
end, 'admin')
