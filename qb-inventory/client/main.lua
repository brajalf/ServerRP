----------------------------------------------------------------
-- qb-inventory (compat for ox) - CLIENT
----------------------------------------------------------------
local normalize = require 'shared.normalize'

local currentStash

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

local function ItemBox(items, type, amount)
    for _, item in ipairs(normalize(items)) do
        local info = exports.ox_inventory:Items(item.name)
        TriggerEvent('ox_inventory:itemNotify', { info, type, amount or item.amount })
    end
end

exports('ItemBox', ItemBox)

exports('ShowHotbar', function()
    SendNUIMessage({ action = 'toggleHotbar', state = true })
end)

exports('HideHotbar', function()
    SendNUIMessage({ action = 'toggleHotbar', state = false })
end)
exports('CloseInventory', function()
    TriggerEvent('ox_inventory:closeInventory')
    currentStash = nil
end)

-- Abrir shop en cliente
RegisterNetEvent('qb-inventory:client:OpenShop', function(id)
    exports.ox_inventory:openInventory('shop', id)
end)

RegisterNetEvent('inventory:client:SetCurrentStash', function(name)
    currentStash = name
end)
----------------------------------------------------------------
