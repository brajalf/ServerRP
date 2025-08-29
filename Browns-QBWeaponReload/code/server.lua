local QBCore = exports['qb-core']:GetCoreObject()
local Inventory = require('code.inventory_bridge')

-- Ammo type to item mapping
local AmmoTypes = {
    AMMO_PISTOL = 'pistol_ammo',
    AMMO_SMG = 'smg_ammo',
    AMMO_SHOTGUN = 'shotgun_ammo',
    AMMO_RIFLE = 'rifle_ammo',
    AMMO_MG = 'mg_ammo',
    AMMO_SNIPER = 'snp_ammo',
    AMMO_EMPLAUNCHER = 'emp_ammo'
}

-- Register ammo items as usable and trigger client reload
for _, ammoItem in pairs(AmmoTypes) do
    QBCore.Functions.CreateUseableItem(ammoItem, function(source, item)
        TriggerClientEvent('inventory:client:UseAmmo', source)
    end)
end

QBCore.Functions.CreateCallback('browns_reload:GetAmount', function(source, cb, types) -- Passing the amount of ammo the player has to the client
    local src = source
    local ammo_type = AmmoTypes[types]
    local ammo_amounts
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

-- Update weapon ammo using weapon hash sent from client
RegisterNetEvent('qb-weapons:server:UpdateWeaponAmmo', function(weaponHash, ammo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local weaponInfo = QBCore.Shared.Weapons[weaponHash]
    if not weaponInfo then return end

    local weaponName = weaponInfo.name
    local weaponItem = Player.Functions.GetItemByName(weaponName)
    if not weaponItem then return end

    weaponItem.info = weaponItem.info or {}
    weaponItem.info.ammo = ammo

    if config.inventory == 'ox_inventory' then
        exports.ox_inventory:SetMetadata(src, weaponItem.slot, weaponItem.info)
    else
        Player.Functions.RemoveItem(weaponName, 1, weaponItem.slot)
        Player.Functions.AddItem(weaponName, 1, weaponItem.slot, weaponItem.info)
    end
end)
