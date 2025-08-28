local QBCore = exports['qb-core']:GetCoreObject()
local Inventory = require 'code.inventory_bridge'

QBCore.Functions.CreateCallback('browns_reload:GetAmount', function(source, cb, types) -- Passing the amount of ammo the player has to the client
    local src = source
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
        ammo_amounts = Inventory.GetItemAmount(src, ammo_type)
    end

    cb(ammo_amounts, ammo_type)
end)

RegisterNetEvent('browns_reload:RemoveAmmoItem', function(ammo, counts) -- Removing reloaded ammo items from the player
    local src = source
    counts = tonumber(counts)
    Inventory.RemoveItem(src, ammo, counts)
end)
