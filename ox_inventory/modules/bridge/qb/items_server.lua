local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('ox_inventory:itemList', function(ItemList)
    local qbItems = QBCore.Shared and QBCore.Shared.Items or {}
    if not qbItems then return end

    for name, v in pairs(qbItems) do
        local lower = string.lower(name)
        -- respeta armas de ox
        if lower:sub(1,7) ~= 'weapon_' then
            ItemList[lower] = {
                label       = v.label or lower,
                weight      = tonumber(v.weight) or 0,
                stack       = (v.unique == nil) and true or (not v.unique),
                close       = true,
                description = v.description
            }
        end
    end
end)
