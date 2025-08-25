----------------------------------------------------------------
-- qb-inventory (compat for ox) - CLIENT
----------------------------------------------------------------
local normalize = require 'qb-inventory.shared.normalize'

exports('HasItem', function(items, amount, metadata)
    local list = normalize(items)
    local needed = amount or 1
    for _, it in ipairs(list) do
        local cnt = exports.ox_inventory:Search('count', string.lower(it.name), metadata or it.metadata)
        if cnt >= (it.amount or needed) then return true end
    end
    return false
end)

exports('GetItem', function(name, metadata, returnSlots)
    if returnSlots then
        return exports.ox_inventory:Search('slots', string.lower(name), metadata)
    end
    return exports.ox_inventory:Search('count', string.lower(name), metadata)
end)

exports('ItemBox', function(...) end)
exports('ShowHotbar', function(...) end)
exports('HideHotbar', function(...) end)
exports('CloseInventory', function()
    TriggerEvent('ox_inventory:closeInventory')
end)

-- Abrir shop en cliente
RegisterNetEvent('qb-inventory:client:OpenShop', function(id)
    exports.ox_inventory:openInventory('shop', id)
end)
----------------------------------------------------------------
