local QBCore = exports['qb-core']:GetCoreObject() -- Import QBCore

local no_return = { -- List of weapons that dont take ammo (Cant Be Reloaded)
    {weapon = 'weapon_stickybomb'},
    {weapon = 'weapon_pipebomb'},
    {weapon = 'weapon_smokegrenade'},
    {weapon = 'weapon_flare'},
    {weapon = 'weapon_proxmine'},
    {weapon = 'weapon_ball'},
    {weapon = 'weapon_molotov'},
    {weapon = 'weapon_grenade'},
    {weapon = 'weapon_bzgas'},
    {weapon = 'weapon_snowball'},
    {weapon = 'weapon_unarmed'}
}

function ReloadWeapon() -- Creating the reloading functionality
    local ped = PlayerPedId()
    local weapons = GetSelectedPedWeapon(ped)
    if weapons ~= `WEAPON_UNARMED` then
        local weaponInfo = QBCore.Shared.Weapons[weapons]
        if weaponInfo then
            local weaponName = tostring(weaponInfo.name)
            for _, cant_reload in ipairs(no_return) do
                if weaponName == tostring(cant_reload.weapon) then
                    return
                end
            end

            local total = GetAmmoInPedWeapon(ped, weapons)
            local maxAmmo = GetMaxAmmoInClip(ped, weapons, 1)
            local sum = tonumber(maxAmmo) - tonumber(total)
            if total < maxAmmo then
                QBCore.Functions.TriggerCallback('browns_reload:GetAmount', function(count, item) -- Getting the Amount of ammo the player has from the server
                    if count ~= nil and item ~= nil then
                        sum = tonumber(sum)
                        item = tostring(item)
                        if count ~= nil and count ~= false then
                            count = tonumber(count)
                            if count > 0 then
                                if count > sum then
                                    local new_total = GetAmmoInPedWeapon(ped, weapons)
                                    SetAmmoInClip(ped, weapons, 0)
                                    AddAmmoToPed(ped, weapons, sum + new_total)
                                    TriggerServerEvent("qb-weapons:server:UpdateWeaponAmmo", weapons, sum + new_total)
                                    TriggerServerEvent('browns_reload:RemoveAmmoItem', item, sum)
                                    if config.inventory == 'ox_inventory' then
                                        -- ox_inventory handles item removal server-side; no ItemBox needed
                                    else
                                        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items[item], "remove")
                                    end
                                else
                                    local new_total = GetAmmoInPedWeapon(ped, weapons)
                                    SetAmmoInClip(ped, weapons, 0)
                                    AddAmmoToPed(ped, weapons, count + new_total)
                                    TriggerServerEvent("qb-weapons:server:UpdateWeaponAmmo", weapons, count + new_total)
                                    TriggerServerEvent('browns_reload:RemoveAmmoItem', item, count)
                                    if config.inventory == 'ox_inventory' then
                                        -- ox_inventory handles item removal server-side; no ItemBox needed
                                    else
                                        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items[item], "remove")
                                    end
                                end
                            end
                        end
                    end
                end, weaponInfo["ammotype"])
            end
        end
    end
end

RegisterNetEvent('inventory:client:UseAmmo', function()
    ReloadWeapon()
end)

RegisterCommand('browns_reload', function(source) -- the reload function to create an export
    ReloadWeapon()
end)

exports('ReloadWeapon', ReloadWeapon) -- export to use reload function in other scripts

RegisterKeyMapping('browns_reload', 'reload your weapon', 'keyboard', 'R')  -- Registering the 'R' key as the button to do reload functionality
