-- ox_inventory/modules/bridge/qb/items_server.lua
-- Inyecta items de QB en el ItemList de ox INVENTORY (lado servidor).
-- No toques weapons: ox trae definiciones más completas.

local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('ox_inventory:itemList', function(ItemList)
    local qbItems = QBCore.Shared and QBCore.Shared.Items or {}
    if not qbItems then return end

    for name, v in pairs(qbItems) do
        local lower = string.lower(name)

        -- Respeta armas de ox
        if lower:sub(1, 7) ~= 'weapon_' then
            ItemList[lower] = {
                label       = v.label or lower,
                weight      = tonumber(v.weight) or 0,
                stack       = (v.unique == nil) and true or (not v.unique),
                close       = true,
                description = v.description,
                -- ox resuelve la imagen en el UI usando imagepath + v.image
                -- y la cache de items que recibe desde servidor.
            }
        end
    end
end)
