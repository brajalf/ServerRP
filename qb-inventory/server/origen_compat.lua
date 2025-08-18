-- Origen UI compatibility for server-side helpers
local QBCore = exports['qb-core']:GetCoreObject()

local function RemoveItemSafe(src, item, amount, slot)
    if type(item) == 'table' then
        item = item.name
    end
    amount = tonumber(amount) or 1
    if slot == 0 or slot == '0' then slot = nil end
    return exports['qb-inventory']:RemoveItem(src, item, amount, slot, 'origen_ui_delete')
end

RegisterNetEvent('qb-inventory:server:DeleteItemDirect', function(item, amount, slot)
    local src = source
    RemoveItemSafe(src, item, amount, slot)
end)
