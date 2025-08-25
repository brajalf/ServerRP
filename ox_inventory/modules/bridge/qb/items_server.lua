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
                close       = v.shouldClose ~= false,
                description = v.description,
                image       = v.image,
                client      = v.client,
                server      = v.server,
                consume     = v.consume,
                unique      = v.unique,
                useable     = v.useable,
                combinable  = v.combinable,
                type        = v.type
            }
        end
    end
end)
