local QBCore = exports['qb-core']:GetCoreObject()

local adapters = {}

adapters['qb-inventory'] = {
    HasItem = function(src, item, amount)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        local data = Player.Functions.GetItemByName(item)
        if not data then return false end
        return data.amount >= (amount or 1)
    end,
    GetItemAmount = function(src, item)
        local Player = QBCore.Functions.GetPlayer(src)
        local data = Player and Player.Functions.GetItemByName(item)
        return data and data.amount or nil
    end,
    RemoveItem = function(src, item, amount)
        local Player = QBCore.Functions.GetPlayer(src)
        local data = Player and Player.Functions.GetItemByName(item)
        if data and data.amount >= amount then
            Player.Functions.RemoveItem(item, amount)
            return true
        end
        return false
    end
}

adapters['lj-inventory'] = {
    HasItem = function(src, item, amount)
        local data = exports['lj-inventory']:GetItemByName(src, item)
        return data and data.amount >= (amount or 1)
    end,
    GetItemAmount = function(src, item)
        local data = exports['lj-inventory']:GetItemByName(src, item)
        return data and data.amount or nil
    end,
    RemoveItem = function(src, item, amount)
        local data = exports['lj-inventory']:GetItemByName(src, item)
        if data and data.amount >= amount then
            exports['lj-inventory']:RemoveItem(src, item, amount)
            return true
        end
        return false
    end
}

adapters['ps-inventory'] = {
    HasItem = function(src, item, amount)
        local data = exports['ps-inventory']:GetItemByName(src, item)
        return data and data.amount >= (amount or 1)
    end,
    GetItemAmount = function(src, item)
        local data = exports['ps-inventory']:GetItemByName(src, item)
        return data and data.amount or nil
    end,
    RemoveItem = function(src, item, amount)
        local data = exports['ps-inventory']:GetItemByName(src, item)
        if data and data.amount >= amount then
            exports['ps-inventory']:RemoveItem(src, item, amount)
            return true
        end
        return false
    end
}

adapters['ox_inventory'] = {
    HasItem = function(src, item, amount)
        local count = exports.ox_inventory:Search(src, 'count', item)
        return count >= (amount or 1)
    end,
    GetItemAmount = function(src, item)
        local count = exports.ox_inventory:Search(src, 'count', item)
        return count > 0 and count or nil
    end,
    RemoveItem = function(src, item, amount)
        return exports.ox_inventory:RemoveItem(src, item, amount) > 0
    end
}

local adapter = adapters[config.inventory] or adapters['qb-inventory']

local InventoryBridge = {}

function InventoryBridge.HasItem(src, item, amount)
    return adapter.HasItem(src, item, amount)
end

function InventoryBridge.GetItemAmount(src, item)
    return adapter.GetItemAmount(src, item)
end

function InventoryBridge.RemoveItem(src, item, amount)
    return adapter.RemoveItem(src, item, amount)
end

return InventoryBridge
