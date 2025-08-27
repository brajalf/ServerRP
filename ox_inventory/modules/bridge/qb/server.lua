require 'modules.bridge.qb.items_server'
--This file has been modified from the current version to return older functionality that allows for the use of qb-core.

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'


local QBCore

AddEventHandler('QBCore:Server:OnPlayerUnload', server.playerDropped)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local inventory = Inventory(source)
    if not inventory then return end
    inventory.player.groups[inventory.player.job] = nil
    inventory.player.job = job.name
    inventory.player.groups[job.name] = job.grade.level
end)

AddEventHandler('QBCore:Server:OnGangUpdate', function(source, gang)
    local inventory = Inventory(source)
    if not inventory then return end
    inventory.player.groups[inventory.player.gang] = nil
    inventory.player.gang = gang.name
    inventory.player.groups[gang.name] = gang.grade.level
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'qb-weapons' and resource ~= 'qb-shops' then return end
    StopResource(resource)
end)

---@param item SlotWithItem?
---@return SlotWithItem?
local function setItemCompatibilityProps(item)
    if not item then return end

    item.info = item.metadata
    item.amount = item.count

    return item
end

local function setupPlayer(Player)
    Player.PlayerData.inventory = Player.PlayerData.items
    Player.PlayerData.identifier = Player.PlayerData.citizenid
    Player.PlayerData.name = ('%s %s'):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)
    server.setPlayerInventory(Player.PlayerData)

    Inventory.SetItem(Player.PlayerData.source, 'money', Player.PlayerData.money.cash)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "AddItem", function(item, amount, slot, info)
        return Inventory.AddItem(Player.PlayerData.source, item, amount, info, slot)
    end)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "RemoveItem", function(item, amount, slot)
        return Inventory.RemoveItem(Player.PlayerData.source, item, amount, nil, slot)
    end)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "GetItemBySlot", function(slot)
        return setItemCompatibilityProps(Inventory.GetSlot(Player.PlayerData.source, slot))
    end)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "GetItemByName", function(itemName)
        return setItemCompatibilityProps(Inventory.GetSlotWithItem(Player.PlayerData.source, itemName))
    end)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "GetItemsByName", function(itemName)
        return setItemCompatibilityProps(Inventory.GetSlotsWithItem(Player.PlayerData.source, itemName))
    end)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "ClearInventory", function(filterItems)
        Inventory.Clear(Player.PlayerData.source, filterItems)
    end)

    QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "SetInventory", function()
        -- ox_inventory's item structure is not compatible with qb-inventory's one so we don't support it
        error(
            'Player.Functions.SetInventory is unsupported for ox_inventory. Try ClearInventory, then add the desired items.')
    end)
end

AddEventHandler('QBCore:Server:PlayerLoaded', setupPlayer)

SetTimeout(500, function()
    QBCore = exports['qb-core']:GetCoreObject()
    server.GetPlayerFromId = QBCore.Functions.GetPlayer
    local weapState = GetResourceState('qb-weapons')

    if weapState ~= 'missing' and (weapState == 'started' or weapState == 'starting') then
        StopResource('qb-weapons')
    end

    local shopState = GetResourceState('qb-shops')

    if shopState ~= 'missing' and (shopState == 'started' or shopState == 'starting') then
        StopResource('qb-shops')
    end

    for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do setupPlayer(Player) end
end)

function server.UseItem(source, itemName, data)
    local itemData = QBCore.Functions.CanUseItem(itemName)
    if type(itemData) == "table" and itemData.func then
        itemData.func(source, data)
    end
end

AddEventHandler('QBCore:Server:OnMoneyChange', function(src, account, amount, changeType)
    if account ~= "cash" then return end

    local item = Inventory.GetItem(src, 'money', nil, false)

    if not item then return end

    Inventory.SetItem(src, 'money',
        changeType == "set" and amount or changeType == "remove" and item.count - amount or
        changeType == "add" and item.count + amount)
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
    local groups = {
        [player.job.name] = player.job.grade.level,
        [player.gang.name] = player.gang.grade.level
    }

    return {
        source = player.source,
        name = ('%s %s'):format(player.charinfo.firstname, player.charinfo.lastname),
        groups = groups,
        sex = player.charinfo.gender,
        dateofbirth = player.charinfo.birthdate,
        job = player.job.name,
        gang = player.gang.name,
    }
end

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
    local accounts = Inventory.GetAccountItemCounts(inv)

    if accounts then
        local player = server.GetPlayerFromId(inv.id)
        player.Functions.SetPlayerData('items', inv.items)

        if accounts.money and accounts.money ~= player.Functions.GetMoney('cash') then
            player.Functions.SetMoney('cash', accounts.money, "Sync money with inventory")
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, license)
    local player = server.GetPlayerFromId(inv.id)
    return player and player.PlayerData.metadata.licences[license]
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
    local player = server.GetPlayerFromId(inv.id)
    if not player then return end

    if player.PlayerData.metadata.licences[license.name] then
        return false, 'already_have'
    elseif Inventory.GetItemCount(inv, 'money') < license.price then
        return false, 'can_not_afford'
    end

    Inventory.RemoveItem(inv, 'money', license.price)
    player.PlayerData.metadata.licences[license.name] = true
    player.Functions.SetMetaData('licences', player.PlayerData.metadata.licences)

    return true, 'have_purchased'
end

--- Takes traditional item data and updates it to support ox_inventory, i.e.
--- ```
--- Old: {1:{"name": "cola", "amount": 1, "label": "Cola", "slot": 1}, 2:{"name": "burger", "amount": 3, "label": "Burger", "slot": 2}}
--- New: [{"slot":1,"name":"cola","count":1}, {"slot":2,"name":"burger","count":3}]
---```
---@diagnostic disable-next-line: duplicate-set-field
function server.convertInventory(playerId, items)
    if type(items) == 'table' then
        local player = server.GetPlayerFromId(playerId)
        local returnData, totalWeight = table.create(#items, 0), 0
        local slot = 0

        if player then
            for name in pairs(server.accounts) do
                local hasThis = false
                for _, data in pairs(items) do
                    if data.name == name then
                        hasThis = true
                    end
                end

                if not hasThis then
                    local amount = player.Functions.GetMoney(name == 'money' and 'cash' or name)

                    if amount then
                        items[#items + 1] = { name = name, amount = amount }
                    end
                end
            end
        end

        for _, data in pairs(items) do
            local item = Items(data.name)

            if item?.name then
                local metadata, count = Items.Metadata(playerId, item, data.info, data.amount or data.count or 1)
                local weight = Inventory.SlotWeight(item, { count = count, metadata = metadata })
                totalWeight += weight
                slot += 1
                returnData[slot] = {
                    name = item.name,
                    label = item.label,
                    weight = weight,
                    slot = slot,
                    count = count,
                    description =
                        item.description,
                    metadata = metadata,
                    stack = item.stack,
                    close = item.close
                }
            end
        end

        return returnData, totalWeight
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)

    return Player.PlayerData.job.isboss or Player.PlayerData.gang.isboss
end

local function export(exportName, func)
    AddEventHandler(('__cfx_export_%s_%s'):format(string.strsplit('.', exportName, 2)), function(setCB)
        setCB(func or function()
            error(("export '%s' is not supported when using ox_inventory"):format(exportName))
        end)
    end)
end

---Imagine if somebody who uses qb/qbox would PR these functions.
export('qb-inventory.LoadInventory', function(playerId)
    if Inventory(playerId) then return end

    local player = QBCore.Functions.GetPlayer(playerId)

    if player then
        setupPlayer(player)

        return Inventory(playerId).items
    end
end)

export('qb-inventory.SaveInventory', function(playerId)
    if type(playerId) ~= 'number' then
        TypeError('playerId', 'number', type(playerId))
    end

    Inventory.Save(playerId)
end)

export('ox_inventory.SaveInventory', function(playerId)
    if type(playerId) ~= 'number' then
        TypeError('playerId', 'number', type(playerId))
    end

    Inventory.Save(playerId)
end)

export('qb-inventory.SetInventory', function(invId, items)
    if type(invId) ~= 'number' or type(items) ~= 'table' then
        error("qb-inventory.SetInventory requiere un id de inventario y una tabla de items")
    end

    Inventory.Clear(invId)

    for _, v in pairs(items) do
        if v and v.name then
            Inventory.AddItem(invId, v.name, v.amount or v.count or 1, v.info or v.metadata, v.slot)
        end
    end

    return true
end)

export('qb-inventory.SetItemData', function(invId, itemName, key, value, slot)
    if not itemName or not key then return false end

    local slotId = slot or Inventory.GetSlotIdWithItem(invId, itemName)
    if not slotId then return false end

    if key == 'info' or key == 'metadata' then
        Inventory.SetMetadata(invId, slotId, value)
        return true
    elseif key == 'durability' then
        Inventory.SetDurability(invId, slotId, value)
        return true
    end

    error(("qb-inventory.SetItemData no es compatible con la clave '%s'"):format(key))
end)

export('qb-inventory.UseItem', function(itemName, ...)
    local itemData = QBCore.Functions.CanUseItem(itemName)
    if type(itemData) == 'table' and itemData.func then
        return itemData.func(...)
    end
end)

export('qb-inventory.GetSlotsByItem', function(invId, itemName, metadata)
    return Inventory.GetSlotIdsWithItem(invId, itemName, metadata)
end)

export('qb-inventory.GetFirstSlotByItem', function(invId, itemName, metadata)
    return Inventory.GetSlotIdWithItem(invId, itemName, metadata)
end)

export('qb-inventory.GetItemBySlot', function(playerId, slotId)
    return Inventory.GetSlot(playerId, slotId)
end)

export('qb-inventory.GetTotalWeight', function(inv)
    if type(inv) == 'table' then
        return Inventory.CalculateWeight(inv)
    end

    local inventory = Inventory(inv)
    return inventory and inventory.weight or 0
end)

export('qb-inventory.GetItemByName', function(playerId, itemName)
    return Inventory.GetSlotWithItem(playerId, itemName)
end)

export('qb-inventory.GetItemsByName', function(playerId, itemName)
    return Inventory.GetSlotsWithItem(playerId, itemName)
end)

export('qb-inventory.GetSlots', function(invId)
    local inv = Inventory(invId)
    if not inv then return 0, 0 end

    local used = 0
    for _, v in pairs(inv.items) do
        if v then used += 1 end
    end

    return used, inv.slots - used
end)

export('qb-inventory.GetItemCount', function(invId, items)
    if type(items) == 'table' then
        local count = 0
        for _, item in pairs(items) do
            count += Inventory.GetItemCount(invId, item)
        end
        return count
    end

    return Inventory.GetItemCount(invId, items)
end)

export('qb-inventory.CanAddItem', function(playerId, itemName, amount)
    return (Inventory.CanCarryAmount(playerId, itemName) or 0) >= amount
end)

export('qb-inventory.ClearInventory', function(playerId, filter)
    Inventory.Clear(playerId, filter)
end)

export('qb-inventory.CloseInventory', function(playerId, inventoryId)
    local playerInventory = Inventory(playerId)

    if not playerInventory then return end

    local inventory = Inventory(playerInventory.open)

    if inventory and (inventoryId == inventory.id or not inventoryId) then
        playerInventory:closeInventory()
    end
end)

export('qb-inventory.OpenInventory', function(playerId, invId, data)
    -- When no id is supplied open the players own inventory
    if not invId then
        return server.forceOpenInventory(playerId, 'player', playerId)
    end

    -- Create a stash when it does not yet exist so legacy qb callbacks work
    local inventory = Inventory(invId)

    if not inventory then
        data = data or {}
        inventory = Inventory.Create(invId, data.label or invId, 'stash', data.slots or shared.playerslots, 0,
            data.maxweight or shared.playerweight, data.owner, nil, data.groups)
    end

    if inventory then
        server.forceOpenInventory(playerId, inventory.type, inventory.id)
    end
end)

export('qb-inventory.OpenInventoryById', function(playerId, targetId)
    server.forceOpenInventory(playerId, 'player', targetId)
end)

-- compatibility shop exports implemented below

export('qb-inventory.AddItem', function(invId, itemName, amount, slot, metadata)
    return Inventory.AddItem(invId, itemName, amount, metadata, slot) and true
end)

export('qb-inventory.RemoveItem', function(invId, itemName, amount, slot)
    return Inventory.RemoveItem(invId, itemName, amount, nil, slot) and true
end)

export('qb-inventory.HasItem', function(source, items, amount)
    amount = amount or 1

    local count = Inventory.Search(source, 'count', items)

    if type(items) == 'table' and type(count) == 'table' then
        for _, v in pairs(count) do
            if v < amount then
                return false
            end
        end

        return true
    end

    return count >= amount
end)

-- qb-inventory compatibility helpers for creating and managing stashes
export('qb-inventory.CreateInventory', function(identifier, data)
    data = data or {}
    return Inventory.Create(identifier, data.label or identifier, 'stash', data.slots or shared.playerslots, 0,
        data.maxweight or shared.playerweight, data.owner, nil, data.groups) and true
end)

export('qb-inventory.RemoveInventory', function(identifier)
    return Inventory.Remove(identifier) and true
end)

export('qb-inventory.GetInventory', function(identifier)
    local inv = Inventory(identifier)
    if not inv then return nil end
    return {
        items = inv.items,
        isOpen = next(inv.openedBy) ~= nil,
        label = inv.label,
        maxweight = inv.maxWeight,
        slots = inv.slots
    }
end)

export('qb-inventory.ClearStash', function(identifier)
    local inv = Inventory(identifier)
    if not inv then return end
    inv.items = {}
    inv.weight = 0
    Inventory.Save(inv)
end)

-- qb-inventory additional compatibility for stashes, shops and metadata

-- helper to open inventories for various types
local function openInvServer(src, invType, identifier)
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

local RegisteredStashes = {}

export('qb-inventory.CreateStash', function(id, label, slots, weight, owner, groups)
    if not id then return false end
    if RegisteredStashes[id] then return true end
    RegisteredStashes[id] = true
    return exports.ox_inventory:RegisterStash(id, label or id, slots or 50, weight or 400000, owner, groups)
end)

export('qb-inventory.OpenStash', function(source, id, slots, weight, owner, groups)
    if not id then return false end
    if not RegisteredStashes[id] then
        slots = slots or 50
        weight = weight or 400000
        exports.ox_inventory:RegisterStash(id, id, slots, weight, owner or true, groups)
        RegisteredStashes[id] = true
    end
    return openInvServer(source, 'stash', id)
end)

-- shops
local Shops = {}

local function qbProductsToOx(products)
    local inv = {}
    for _, p in pairs(products or {}) do
        if p.name then
            inv[#inv+1] = {
                name     = string.lower(p.name),
                price    = tonumber(p.price) or 0,
                metadata = p.info,
                count    = p.count or p.amount
            }
        end
    end
    return inv
end

export('qb-inventory.RegisterShop', function(id, label, account, products, locations, groups)
    local inventory = qbProductsToOx(products)
    Shops[id] = {
        account   = account or 'cash',
        inventory = inventory
    }

    exports.ox_inventory:RegisterShop(id, {
        name      = label or id,
        inventory = inventory,
        locations = locations,
        groups    = groups
    })

    return true
end)

export('qb-inventory.OpenShop', function(source, id)
    if not Shops[id] then return false end
    TriggerClientEvent('qb-inventory:client:OpenShop', source, id)
    return true
end)

RegisterNetEvent('qb-inventory:server:OpenShop', function(id)
    local src = source
    if not Shops[id] then return end
    TriggerClientEvent('qb-inventory:client:OpenShop', src, id)
end)

-- classic inventory open handler
RegisterNetEvent('inventory:server:OpenInventory', function(inventoryType, identifier, extraData)
    local src = source
    if inventoryType == 'shop' then
        local items = qbProductsToOx(extraData)
        exports.ox_inventory:forceOpenInventory(src, 'shop', { id = identifier, items = items })
    elseif inventoryType == 'stash' then
        local stashId = identifier or ('stash_' .. src)
        if not RegisteredStashes[stashId] then
            exports.ox_inventory:RegisterStash(
                stashId, stashId,
                (extraData and extraData.slots) or 50,
                (extraData and (extraData.weight or extraData.maxweight)) or 400000,
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

-- qb-inventory shop purchase handler
RegisterNetEvent('qb-inventory:server:BuyItem', function(shopId, itemName, price, count, metadata)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local shop = Shops[shopId]
    if not Player or not shop then return end

    itemName = string.lower(itemName)
    price    = tonumber(price) or 0
    count    = tonumber(count) or 1
    if price <= 0 or count <= 0 then return end

    local product
    for _, it in pairs(shop.inventory or {}) do
        if it.name == itemName then
            product = it
            break
        end
    end
    if not product then
        TriggerClientEvent('QBCore:Notify', src, 'Artículo no disponible', 'error')
        return
    end
    if price ~= product.price then
        TriggerClientEvent('QBCore:Notify', src, 'Precio inválido', 'error')
        return
    end
    if product.count and product.count < count then
        TriggerClientEvent('QBCore:Notify', src, 'No hay suficiente stock', 'error')
        return
    end

    local acc = shop.account == 'bank' and 'bank' or 'cash'
    local bal = Player.PlayerData.money[acc] or 0
    local total = product.price * count
    if bal < total then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes suficiente dinero', 'error')
        return
    end

    Player.Functions.RemoveMoney(acc, total, ('Shop purchase %s x%s'):format(itemName, count))

    local ok = exports.ox_inventory:AddItem(src, itemName, count, metadata or product.metadata)
    if not ok then
        Player.Functions.AddMoney(acc, total, ('Refund %s x%s'):format(itemName, count))
        TriggerClientEvent('QBCore:Notify', src, 'No tienes espacio en el inventario', 'error')
        return
    end

    if product.count then
        product.count = product.count - count
    end

    TriggerClientEvent('QBCore:Notify', src, ('Compraste %s x%s'):format(itemName, count), 'success')
end)

-- update item metadata
export('qb-inventory.SetMetadata', function(source, name, metadata, amount, slot)
    if not name then return false end
    name = string.lower(name)

    if slot then
        Inventory.SetMetadata(source, slot, metadata)
        return true
    end

    local slots = Inventory.Search(source, 'slots', name, metadata)
    if slots and slots[1] then
        Inventory.SetMetadata(source, slots[1].slot, metadata)
        return true
    end

    return false
end)
