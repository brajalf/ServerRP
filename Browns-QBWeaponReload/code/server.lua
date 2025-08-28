local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('browns_reload:GetAmount', function(source, cb, types) -- Passing the amount of ammo the player has to the client
    local src = source 
    local Player = QBCore.Functions.GetPlayer(src)
    local ammo_type
    local ammo_amounts
    if types == 'AMMO_PISTOL' then 
        ammo_type = 'pistol_ammo'
    elseif types == 'AMMO_SMG' then 
        ammo_type = 'smg_ammo'
    elseif types == 'AMMO_SHOTGUN' then 
        ammo_type = 'shotgun_ammo'
    elseif types == 'AMMO_RIFLE' then 
        ammo_type = 'rifle_ammo'
    elseif types == 'AMMO_MG' then 
        ammo_type = 'mg_ammo'
    elseif types == 'AMMO_SNIPER' then 
        ammo_type = 'snp_ammo'
    elseif types == 'AMMO_EMPLAUNCHER' then 
        ammo_type = 'emp_ammo'
    end

    if ammo_type then
        if config.inventory == 'ox_inventory' then
            ammo_amounts = exports.ox_inventory:Search(src, 'count', ammo_type)
            if ammo_amounts <= 0 then ammo_amounts = nil end
        elseif config.inventory == 'ps-inventory' then
            local item = exports['ps-inventory']:GetItemByName(src, ammo_type)
            ammo_amounts = item and item.amount or nil
        else -- qb-inventory and similar
            local item = Player and Player.Functions.GetItemByName(ammo_type)
            ammo_amounts = item and item.amount or nil
        end
    end

    cb(ammo_amounts, ammo_type)
end)

RegisterNetEvent('browns_reload:RemoveAmmoItem', function(ammo, counts) -- Removing reloaded ammo items from the player
    local src = source
    counts = tonumber(counts)
    local Player = QBCore.Functions.GetPlayer(src)

    if config.inventory == 'ox_inventory' then
        exports.ox_inventory:RemoveItem(src, ammo, counts)
    elseif config.inventory == 'ps-inventory' then
        local item = exports['ps-inventory']:GetItemByName(src, ammo)
        if item and item.amount >= counts then
            exports['ps-inventory']:RemoveItem(src, ammo, counts)
        end
    else
        local item = Player and Player.Functions.GetItemByName(ammo)
        if item and item.amount >= counts then
            Player.Functions.RemoveItem(ammo, counts)
        end
    end
end)
