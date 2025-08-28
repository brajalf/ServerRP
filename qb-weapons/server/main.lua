local QBCore = exports['qb-core']:GetCoreObject()

-- Register ammo items as usable and trigger client reload
for ammoItem, _ in pairs(Config.AmmoTypes or {}) do
    QBCore.Functions.CreateUseableItem(ammoItem, function(source, item)
        TriggerClientEvent('inventory:client:UseAmmo', source)
    end)
end

