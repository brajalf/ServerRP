local QBCore = exports['qb-core']:GetCoreObject()

-- =========================
-- Utils
-- =========================
local function normalize(items)
    if not items then return {} end
    local out = {}
    if type(items) == 'string' then
        out[#out+1] = { name = items, amount = 1 }
        return out
    end
    if items.name then
        out[#out+1] = { name = items.name, amount = items.amount or 1, metadata = items.info or items.metadata }
        return out
    end
    for _, it in pairs(items) do
        if type(it) == 'string' then
            out[#out+1] = { name = it, amount = 1 }
        elseif type(it) == 'table' then
            out[#out+1] = { name = it.name or it[1], amount = it.amount or 1, metadata = it.info or it.metadata }
        end
    end
    return out
end

-- =========================
-- Exports básicos (qb → ox)
-- =========================
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
        if cnt >= (it.amount or needed) then
            return true
        end
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

-- =========================
-- STASHES
-- =========================
local RegisteredStashes = {}

exports('CreateStash', function(id, label, slots, weight, owner, groups)
    if RegisteredStashes[id] then return true end
    RegisteredStashes[id] = true
    return exports.ox_inventory:RegisterStash(
        id,
        label or id,
        slots or 50,
        weight or 400000,
        owner,
        groups
    )
end)

exports('OpenStash', function(source, id)
    if not RegisteredStashes[id] then
        exports.ox_inventory:RegisterStash(id, id, 50, 400000, true)
        RegisteredStashes[id] = true
    end
    return exports.ox_inventory:forceOpenInventory(source, 'stash', id)
end)

-- Handler genérico que muchos scripts QB llaman
RegisterNetEvent('inventory:server:OpenInventory', function(inventoryType, identifier, extraData)
    local src = source
    if inventoryType == 'stash' then
        local stashId = identifier or ('stash_' .. src)
        if not RegisteredStashes[stashId] then
            exports.ox_inventory:RegisterStash(stashId, stashId, (extraData and extraData.slots) or 50, (extraData and extraData.weight) or 400000, extraData and extraData.owner, extraData and extraData.groups)
            RegisteredStashes[stashId] = true
        end
        exports.ox_inventory:forceOpenInventory(src, 'stash', stashId)

    elseif inventoryType == 'trunk' then
        exports.ox_inventory:forceOpenInventory(src, 'trunk', identifier)

    elseif inventoryType == 'glovebox' then
        exports.ox_inventory:forceOpenInventory(src, 'glovebox', identifier)

    elseif inventoryType == 'shop' then
        TriggerClientEvent('qb-inventory:client:OpenShop', src, identifier)

    else
        print(('[qb-inventory compat] OpenInventory tipo no manejado: %s'):format(tostring(inventoryType)))
    end
end)

-- =========================
-- SHOPS
-- =========================
local Shops = {}

local function qbProductsToOxInventory(products)
    local inv = {}
    for _, p in pairs(products or {}) do
        if p.name then
            inv[#inv+1] = {
                name = string.lower(p.name),
                price = tonumber(p.price) or 0,
                metadata = p.info
            }
        end
    end
    return inv
end

exports('RegisterShop', function(id, label, account, products, locations, groups)
    Shops[id] = true
    return exports.ox_inventory:RegisterShop(id, {
        name = label or id,
        inventory = qbProductsToOxInventory(products),
        locations = locations,
        groups = groups
    })
end)

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
