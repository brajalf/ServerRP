QBCore = exports['qb-core']:GetCoreObject()
Inventories = Inventories or {}
Inventories['drop'] = Inventories['drop'] or {}
local Drops = Drops or {}
RegisteredShops = {}

local currentDrop = 0

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return (dx * dx + dy * dy + dz * dz) ^ 0.5
end

local function getNearestDrop(coords, radius)
    local best, bestDist
    for name, d in pairs(Drops) do
        if d and d.coords then
            local dist = distance(coords, d.coords)
            if not bestDist or dist < bestDist then
                best, bestDist = name, dist
            end
        end
    end
    if best and bestDist and bestDist <= (radius or 2.0) then return best end
end

local function CreateDrop(coords)
    currentDrop = currentDrop + 1
    local name = 'drop-' .. currentDrop
    Inventories['drop'][name] = {
        name = name,
        label = 'Drop',
        items = {},
        createdTime = os.time(),
        maxweight = Config.DropSize.maxweight,
        slots = Config.DropSize.slots,
        isOpen = false
    }
    Drops[name] = { coords = coords }
    return name
end

local function removeDropIfEmpty(name)
    local inv = Inventories['drop'] and Inventories['drop'][name]
    if inv and (not inv.items or next(inv.items) == nil) then
        Inventories['drop'][name] = nil
        Drops[name] = nil
        TriggerClientEvent('qb-inventory:client:RemoveDropProp', -1, name)
    end
end

-- loads stash inventory from the database using a stable name
local function loadStash(name)
    if Inventories[name] then return end
    local result = MySQL.prepare.await('SELECT items FROM stashitems WHERE stash = ?', { name })
    Inventories[name] = {
        items = result and json.decode(result) or {},
        label = name,
        maxweight = Config.StashSize.maxweight,
        slots = Config.StashSize.slots,
        isOpen = false
    }
end

-- saves stash inventory back to the database without duplicating rows
local function saveStash(name)
    local inv = Inventories[name]
    if not inv then return end
    local jsonItems = json.encode(inv.items)
    MySQL.prepare('INSERT INTO stashitems (stash, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = ?', {
        name,
        jsonItems,
        jsonItems
    })
end

local function canFrisk(src, target)
    local tstate = (type(Player) == 'function' and Player(target).state or nil)
    if not tstate then return false end
    if tstate.isDead then return true end
    if tstate.handcuffed then return true end
    if tstate.handsup then return true end
    local QBPlayer = QBCore.Functions.GetPlayer(src)
    if QBPlayer and QBPlayer.PlayerData.job and QBPlayer.PlayerData.job.name == 'police' then return true end
    return false
end

CreateThread(function()
    local total = 0

    local stashResult = MySQL.query.await('SELECT * FROM stashitems') or {}
    for i = 1, #stashResult do
        local inv = stashResult[i]
        Inventories[inv.stash] = {
            items = json.decode(inv.items) or {},
            isOpen = false
        }
        total = total + 1
    end

    local gloveResult = MySQL.query.await('SELECT * FROM gloveboxitems') or {}
    for i = 1, #gloveResult do
        local inv = gloveResult[i]
        Inventories['glovebox-' .. inv.plate] = {
            items = json.decode(inv.items) or {},
            isOpen = false
        }
        total = total + 1
    end

    local trunkResult = MySQL.query.await('SELECT * FROM trunkitems') or {}
    for i = 1, #trunkResult do
        local inv = trunkResult[i]
        Inventories['trunk-' .. inv.plate] = {
            items = json.decode(inv.items) or {},
            isOpen = false
        }
        total = total + 1
    end

    if total > 0 then
        print(total .. ' inventories successfully loaded')
    end
end)

CreateThread(function()
    while true do
        local dropInventories = Inventories['drop'] or {}
        for k, v in pairs(dropInventories) do
            if v and (v.createdTime + (Config.CleanupDropTime * 60) < os.time()) and not v.isOpen then
                TriggerClientEvent('qb-inventory:client:RemoveDropProp', -1, k)
                Inventories['drop'][k] = nil
                Drops[k] = nil
            end
        end
        Wait(Config.CleanupDropInterval * 60000)
    end
end)

-- Handlers

AddEventHandler('playerDropped', function()
    for name, inv in pairs(Inventories) do
        if name ~= 'drop' and inv.isOpen == source then
            inv.isOpen = false
        end
    end
    for _, inv in pairs(Inventories['drop']) do
        if inv.isOpen == source then
            inv.isOpen = false
        end
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    for inventory, data in pairs(Inventories) do
        if inventory ~= 'drop' and data.isOpen then
            SaveInventoryData(inventory, data.items)
        end
    end
end)

RegisterNetEvent('QBCore:Server:UpdateObject', function()
    if source ~= '' then return end
    QBCore = exports['qb-core']:GetCoreObject()
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(QBPlayer)
    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'AddItem', function(item, amount, slot, info, reason)
        return AddItem(QBPlayer.PlayerData.source, item, amount, slot, info, reason)
    end)

    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'RemoveItem', function(item, amount, slot, reason)
        return RemoveItem(QBPlayer.PlayerData.source, item, amount, slot, reason)
    end)

    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'GetItemBySlot', function(slot)
        return GetItemBySlot(QBPlayer.PlayerData.source, slot)
    end)

    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'GetItemByName', function(item)
        return GetItemByName(QBPlayer.PlayerData.source, item)
    end)

    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'GetItemsByName', function(item)
        return GetItemsByName(QBPlayer.PlayerData.source, item)
    end)

    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'ClearInventory', function(filterItems)
        ClearInventory(QBPlayer.PlayerData.source, filterItems)
    end)

    QBCore.Functions.AddPlayerMethod(QBPlayer.PlayerData.source, 'SetInventory', function(items)
        SetInventory(QBPlayer.PlayerData.source, items)
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local Players = QBCore.Functions.GetQBPlayers()
    for k in pairs(Players) do
        QBCore.Functions.AddPlayerMethod(k, 'AddItem', function(item, amount, slot, info)
            return AddItem(k, item, amount, slot, info)
        end)

        QBCore.Functions.AddPlayerMethod(k, 'RemoveItem', function(item, amount, slot)
            return RemoveItem(k, item, amount, slot)
        end)

        QBCore.Functions.AddPlayerMethod(k, 'GetItemBySlot', function(slot)
            return GetItemBySlot(k, slot)
        end)

        QBCore.Functions.AddPlayerMethod(k, 'GetItemByName', function(item)
            return GetItemByName(k, item)
        end)

        QBCore.Functions.AddPlayerMethod(k, 'GetItemsByName', function(item)
            return GetItemsByName(k, item)
        end)

        QBCore.Functions.AddPlayerMethod(k, 'ClearInventory', function(filterItems)
            ClearInventory(k, filterItems)
        end)

        QBCore.Functions.AddPlayerMethod(k, 'SetInventory', function(items)
            SetInventory(k, items)
        end)

        Player(k).state.inv_busy = false
    end
end)

-- Functions

local function checkWeapon(source, item)
    local currentWeapon = type(item) == 'table' and item.name or item
    local ped = GetPlayerPed(source)
    local weapon = GetSelectedPedWeapon(ped)
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    if weaponInfo and weaponInfo.name == currentWeapon then
        RemoveWeaponFromPed(ped, weapon)
        TriggerClientEvent('qb-weapons:client:UseWeapon', source, { name = currentWeapon }, false)
    end
end

-- Events

RegisterNetEvent('qb-inventory:server:openVending', function(data)
    local src = source
    local QBPlayer = QBCore.Functions.GetPlayer(src)
    if not QBPlayer then return end
    CreateShop({
        name = 'vending',
        label = 'Vending Machine',
        coords = data.coords,
        slots = #Config.VendingItems,
        items = Config.VendingItems
    })
    OpenShop(src, 'vending')
end)

-- Compatibility event for resources using legacy inventory triggers
RegisterNetEvent('inventory:server:OpenInventory', function(invType, id, data)
    local src = source
    if invType == 'shop' then
        if type(data) == 'table' then
            CreateShop({ name = id, label = id, items = data })
        end
        OpenShop(src, id)
    elseif invType == 'otherplayer' then
        if not canFrisk(src, id) then return end
        OpenInventoryById(src, id)
    elseif invType == 'drop' then
        openDrop(src, id)
    else
        if invType == 'stash' then
            loadStash(id)
        end
        OpenInventory(src, id, data)
    end
end)

RegisterNetEvent('qb-inventory:server:OpenInventory', function(invType, id, data)
    local src = source
    if invType == 'shop' then
        if type(data) == 'table' then
            CreateShop({ name = id, label = id, items = data })
        end
        OpenShop(src, id)
    elseif invType == 'otherplayer' then
        if not canFrisk(src, id) then return end
        OpenInventoryById(src, id)
    elseif invType == 'drop' then
        openDrop(src, id)
    else
        if invType == 'stash' then
            loadStash(id)
        end
        OpenInventory(src, id, data)
    end
end)

RegisterNetEvent('qb-inventory:server:closeInventory', function(inventory)
    local src = source
    local QBPlayer = QBCore.Functions.GetPlayer(src)
    if not QBPlayer then return end
    Player(source).state.inv_busy = false
    if inventory:find('shop%-') then return end
    if inventory:find('otherplayer%-') then
        local targetId = tonumber(inventory:match('otherplayer%-(.+)'))
        Player(targetId).state.inv_busy = false
        return
    end
    if Inventories['drop'] and Inventories['drop'][inventory] then
        Inventories['drop'][inventory].isOpen = false
        removeDropIfEmpty(inventory)
        return
    end
    if not Inventories[inventory] then return end
    Inventories[inventory].isOpen = false
    SaveInventoryData(inventory, Inventories[inventory].items)
end)

RegisterNetEvent('qb-inventory:server:useItem', function(item)
    local src = source
    local itemData = GetItemBySlot(src, item.slot)
    if not itemData then return end
    local itemInfo = QBCore.Shared.Items[itemData.name]
    if itemData.type == 'weapon' then
        TriggerClientEvent('qb-weapons:client:UseWeapon', src, itemData, itemData.info.quality and itemData.info.quality > 0)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, itemInfo, 'use')
    elseif itemData.name == 'id_card' then
        UseItem(itemData.name, src, itemData)
        TriggerClientEvent('qb-inventory:client:ItemBox', source, itemInfo, 'use')
        local playerPed = GetPlayerPed(src)
        local playerCoords = GetEntityCoords(playerPed)
        local players = QBCore.Functions.GetPlayers()
        local gender = item.info.gender == 0 and 'Male' or 'Female'
        for _, v in pairs(players) do
            local targetPed = GetPlayerPed(v)
            local dist = #(playerCoords - GetEntityCoords(targetPed))
            if dist < 3.0 then
                TriggerClientEvent('chat:addMessage', v, {
                    template = '<div class="chat-message advert" style="background: linear-gradient(to right, rgba(5, 5, 5, 0.6), #74807c); display: flex;"><div style="margin-right: 10px;"><i class="far fa-id-card" style="height: 100%;"></i><strong> {0}</strong><br> <strong>Civ ID:</strong> {1} <br><strong>First Name:</strong> {2} <br><strong>Last Name:</strong> {3} <br><strong>Birthdate:</strong> {4} <br><strong>Gender:</strong> {5} <br><strong>Nationality:</strong> {6}</div></div>',
                    args = {
                        'ID Card',
                        item.info.citizenid,
                        item.info.firstname,
                        item.info.lastname,
                        item.info.birthdate,
                        gender,
                        item.info.nationality
                    }
                })
            end
        end
    elseif itemData.name == 'driver_license' then
        UseItem(itemData.name, src, itemData)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, itemInfo, 'use')
        local playerPed = GetPlayerPed(src)
        local playerCoords = GetEntityCoords(playerPed)
        local players = QBCore.Functions.GetPlayers()
        for _, v in pairs(players) do
            local targetPed = GetPlayerPed(v)
            local dist = #(playerCoords - GetEntityCoords(targetPed))
            if dist < 3.0 then
                TriggerClientEvent('chat:addMessage', v, {
                    template = '<div class="chat-message advert" style="background: linear-gradient(to right, rgba(5, 5, 5, 0.6), #657175); display: flex;"><div style="margin-right: 10px;"><i class="far fa-id-card" style="height: 100%;"></i><strong> {0}</strong><br> <strong>First Name:</strong> {1} <br><strong>Last Name:</strong> {2} <br><strong>Birth Date:</strong> {3} <br><strong>Licenses:</strong> {4}</div></div>',
                    args = {
                        'Drivers License',
                        item.info.firstname,
                        item.info.lastname,
                        item.info.birthdate,
                        item.info.type
                    }
                }
                )
            end
        end
    else
        UseItem(itemData.name, src, itemData)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, itemInfo, 'use')
    end
end)

local function openDrop(src, dropId)
    local QBPlayer = QBCore.Functions.GetPlayer(src)
    if not QBPlayer then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local inv = Inventories['drop'] and Inventories['drop'][dropId]
    local drop = Drops[dropId]
    if not inv or not drop or inv.isOpen then return end
    local distance = #(playerCoords - drop.coords)
    if distance > 2.5 then return end
    local formattedInventory = {
        name = dropId,
        label = dropId,
        maxweight = inv.maxweight,
        slots = inv.slots,
        inventory = inv.items
    }
    inv.isOpen = true
    TriggerClientEvent('qb-inventory:client:openInventory', src, QBPlayer.PlayerData.items, formattedInventory)
end

RegisterNetEvent('qb-inventory:server:openDrop', function(dropId)
    openDrop(source, dropId)
end)

RegisterNetEvent('qb-inventory:server:updateDrop', function(dropId, coords)
    if Drops[dropId] then
        Drops[dropId].coords = coords
    end
end)

RegisterNetEvent('qb-inventory:server:snowball', function(action)
    if action == 'add' then
        AddItem(source, 'weapon_snowball', 1, false, false, 'qb-inventory:server:snowball')
    elseif action == 'remove' then
        RemoveItem(source, 'weapon_snowball', 1, false, 'qb-inventory:server:snowball')
    end
end)

-- Callbacks

QBCore.Functions.CreateCallback('qb-inventory:server:GetCurrentDrops', function(_, cb)
    cb(Drops)
end)

QBCore.Functions.CreateCallback('qb-inventory:server:createOrReuseDrop', function(src, cb, coords, radius)
    coords = coords or GetEntityCoords(GetPlayerPed(src))
    local reuse = getNearestDrop(coords, radius)
    if reuse then
        cb(reuse)
        return
    end
    local newName = CreateDrop(coords)
    TriggerClientEvent('qb-inventory:client:CreateDropProp', -1, newName, coords)
    cb(newName)
end)

QBCore.Functions.CreateCallback('qb-inventory:server:attemptPurchase', function(source, cb, data)
    local itemInfo = data.item
    local amount = data.amount
    local shop = string.gsub(data.shop, 'shop%-', '')
    local QBPlayer = QBCore.Functions.GetPlayer(source)

    if not QBPlayer then
        cb(false)
        return
    end

    local shopInfo = RegisteredShops[shop]
    if not shopInfo then
        cb(false)
        return
    end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if shopInfo.coords then
        local shopCoords = vector3(shopInfo.coords.x, shopInfo.coords.y, shopInfo.coords.z)
        if #(playerCoords - shopCoords) > 10 then
            cb(false)
            return
        end
    end

    if shopInfo.items[itemInfo.slot].name ~= itemInfo.name then
        cb(false)
        return
    end

    if amount > shopInfo.items[itemInfo.slot].amount then
        TriggerClientEvent('QBCore:Notify', source, 'Cannot purchase larger quantity than currently in stock', 'error')
        cb(false)
        return
    end

    if not CanAddItem(source, itemInfo.name, amount) then
        TriggerClientEvent('QBCore:Notify', source, 'Cannot hold item', 'error')
        cb(false)
        return
    end

    local price = shopInfo.items[itemInfo.slot].price * amount
    local account = 'cash'
    if QBPlayer.PlayerData.money.cash < price then
        account = 'bank'
        if QBPlayer.PlayerData.money.bank < price then
            TriggerClientEvent('QBCore:Notify', source, 'You do not have enough money', 'error')
            cb(false)
            return
        end
    end

    if account ~= 'cash' and account ~= 'bank' then
        cb(false)
        return
    end

    local removed = QBPlayer.Functions.RemoveMoney(account, price, 'shop-purchase')
    if not removed then
        cb(false)
        return
    end

    QBPlayer.Functions.AddItem(itemInfo.name, amount, false, itemInfo.info)
    TriggerClientEvent('qb-inventory:client:updateInventory', source)
    TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[itemInfo.name], 'add', amount)
    TriggerEvent('qb-shops:server:UpdateShopItems', shop, itemInfo, amount)
    cb(true)
end)

RegisterNetEvent('qb-inventory:server:AttemptPurchase', function(itemName, amount, price, info, payWithBank)
    local src = source
    if not itemName or not amount or not price then return end
    local QBPlayer = QBCore.Functions.GetPlayer(src)
    if not QBPlayer then return end
    local account = (payWithBank and 'bank' or 'cash')
    if account ~= 'cash' and account ~= 'bank' then return end
    if not QBPlayer.Functions.RemoveMoney(account, price * amount, 'shop-purchase') then return end
    QBPlayer.Functions.AddItem(itemName, amount, false, info)
    TriggerClientEvent('qb-inventory:client:updateInventory', src)
end)

QBCore.Functions.CreateCallback('qb-inventory:server:giveItem', function(source, cb, target, item, amount, slot, info)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or player.PlayerData.metadata['isdead'] or player.PlayerData.metadata['inlaststand'] or player.PlayerData.metadata['ishandcuffed'] then
        cb(false)
        return
    end
    local Target = QBCore.Functions.GetPlayer(target)
    if not Target or Target.PlayerData.metadata['isdead'] or Target.PlayerData.metadata['inlaststand'] or Target.PlayerData.metadata['ishandcuffed'] then
        cb(false)
        return
    end

    local itemInfo = QBCore.Shared.Items[item:lower()]
    if not itemInfo then
        cb(false)
        return
    end

    local hasItem = HasItem(source, item)
    if not hasItem then
        cb(false)
        return
    end

    local itemAmount = GetItemByName(source, item).amount
    if itemAmount <= 0 then
        cb(false)
        return
    end

    local giveAmount = tonumber(amount)
    if giveAmount > itemAmount then
        cb(false)
        return
    end

    local removeItem = RemoveItem(source, item, giveAmount, slot, 'Item given to ID #' .. target)
    if not removeItem then
        cb(false)
        return
    end

    local giveItem = AddItem(target, item, giveAmount, false, info, 'Item given from ID #' .. source)
    if not giveItem then
        cb(false)
        return
    end

    if itemInfo.type == 'weapon' then checkWeapon(source, item) end
    TriggerClientEvent('qb-inventory:client:giveAnim', source)
    TriggerClientEvent('qb-inventory:client:ItemBox', source, itemInfo, 'remove', giveAmount)
    TriggerClientEvent('qb-inventory:client:giveAnim', target)
    TriggerClientEvent('qb-inventory:client:ItemBox', target, itemInfo, 'add', giveAmount)
    SaveInventory(source)
    SaveInventory(target)
    if Player(source).state.inv_busy then TriggerClientEvent('qb-inventory:client:updateInventory', source) end
    if Player(target).state.inv_busy then TriggerClientEvent('qb-inventory:client:updateInventory', target) end
    cb(true)
end)

-- Item move logic

local function getItem(inventoryId, src, slot)
    local items = {}
    if inventoryId == 'player' then
        local QBPlayer = QBCore.Functions.GetPlayer(src)
        if QBPlayer and QBPlayer.PlayerData.items then
            items = QBPlayer.PlayerData.items
        end
    elseif inventoryId:find('otherplayer-') then
        local targetId = tonumber(inventoryId:match('otherplayer%-(.+)'))
        local targetPlayer = QBCore.Functions.GetPlayer(targetId)
        if targetPlayer and targetPlayer.PlayerData.items then
            items = targetPlayer.PlayerData.items
        end
    elseif inventoryId:find('drop-') == 1 then
        if Inventories['drop'][inventoryId] and Inventories['drop'][inventoryId].items then
            items = Inventories['drop'][inventoryId].items
        end
    else
        if Inventories[inventoryId] and Inventories[inventoryId]['items'] then
            items = Inventories[inventoryId]['items']
        end
    end

    for _, item in pairs(items) do
        if item.slot == slot then
            return item
        end
    end
    return nil
end

local function getIdentifier(inventoryId, src)
    if inventoryId == 'player' then
        return src
    elseif inventoryId:find('otherplayer-') then
        return tonumber(inventoryId:match('otherplayer%-(.+)'))
    else
        return inventoryId
    end
end

RegisterNetEvent('qb-inventory:server:SetInventoryData', function(fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
    fromSlot = tonumber(fromSlot)
    toSlot = tonumber(toSlot)
    fromAmount = tonumber(fromAmount) or 0
    toAmount = tonumber(toAmount)
    if not fromInventory or not toInventory or not fromSlot or not toSlot or not toAmount then return end
    if toInventory:find('shop%-') then return end
    local src = source
    local QBPlayer = QBCore.Functions.GetPlayer(src)
    if not QBPlayer then return end

    if fromInventory == 'player' and toInventory == 'player' then
        local items = QBPlayer.PlayerData.items
        local a, b = items[fromSlot], items[toSlot]
        if a then
            items[fromSlot], items[toSlot] = b, a
            if items[fromSlot] then items[fromSlot].slot = fromSlot end
            if items[toSlot]   then items[toSlot].slot   = toSlot   end
            QBPlayer.Functions.SetPlayerData('items', items)
            TriggerClientEvent('qb-inventory:client:updateInventory', src)
            return
        end
    end

    local fromItem = getItem(fromInventory, src, fromSlot)
    local toItem = getItem(toInventory, src, toSlot)

    local function removeItem(identifier, itemName, amount, slot, reason)
        if type(itemName) ~= 'string' then return false end
        if type(identifier) == 'number' then
            local player = identifier == src and QBPlayer or QBCore.Functions.GetPlayer(identifier)
            if player then
                return player.Functions.RemoveItem(itemName, amount, slot, reason)
            end
        end
        return RemoveItem(identifier, itemName, amount, slot, reason)
    end

    if fromItem then
        if not toItem and toAmount > fromItem.amount then return end
        if fromInventory == 'player' and toInventory ~= 'player' then checkWeapon(src, fromItem) end

        local fromId = getIdentifier(fromInventory, src)
        local toId = getIdentifier(toInventory, src)

        if toItem and fromItem.name == toItem.name then
            if removeItem(fromId, fromItem.name, toAmount, fromSlot, 'stacked item') then
                AddItem(toId, toItem.name, toAmount, toSlot, toItem.info, 'stacked item')
            end
        elseif not toItem and toAmount < fromAmount then
            if removeItem(fromId, fromItem.name, toAmount, fromSlot, 'split item') then
                AddItem(toId, fromItem.name, toAmount, toSlot, fromItem.info, 'split item')
            end
        else
            if toItem then
                local fromItemAmount = fromItem.amount
                local toItemAmount = toItem.amount

                if removeItem(fromId, fromItem.name, fromItemAmount, fromSlot, 'swapped item') and removeItem(toId, toItem.name, toItemAmount, toSlot, 'swapped item') then
                    AddItem(toId, fromItem.name, fromItemAmount, toSlot, fromItem.info, 'swapped item')
                    AddItem(fromId, toItem.name, toItemAmount, fromSlot, toItem.info, 'swapped item')
                end
            else
                if removeItem(fromId, fromItem.name, toAmount, fromSlot, 'moved item') then
                    AddItem(toId, fromItem.name, toAmount, toSlot, fromItem.info, 'moved item')
                end
            end
        end
        -- update client inventory after moving items
        TriggerClientEvent('qb-inventory:client:updateInventory', src)

        -- persist inventory changes
        if type(fromId) == 'number' then
            SaveInventory(fromId)
        elseif Inventories[fromId] then
            saveStash(fromId)
        end
        if type(toId) == 'number' then
            SaveInventory(toId)
        elseif Inventories[toId] then
            saveStash(toId)
        end
        if type(fromId) == 'string' and fromId:find('drop%-') then
            removeDropIfEmpty(fromId)
        end
        if type(toId) == 'string' and toId:find('drop%-') then
            removeDropIfEmpty(toId)
        end
    end
end)
