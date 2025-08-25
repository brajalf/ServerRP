local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil
local ESX = GetResourceState('es_extended'):find('start') and exports['es_extended']:getSharedObject() or nil

local function registerPharmacies()
    if GetResourceState('ox_inventory') ~= 'started' then return end

    for _, hospital in pairs(Config.Hospitals) do
        if hospital.pharmacy then
            for name, pharmacy in pairs(hospital.pharmacy) do
                local groups
                if pharmacy.job then
                    groups = {}
                    for _, job in pairs(Config.EmsJobs) do
                        groups[job] = pharmacy.grade or 0
                    end
                end

                exports.ox_inventory:RegisterShop(name, {
                    name = pharmacy.label,
                    groups = groups,
                    inventory = pharmacy.items,
                })
            end
        end
    end
end

RegisterNetEvent('ars_ambulancejob:openPharmacy', function(name)
    local src = source
    local pharmacy

    for _, hospital in pairs(Config.Hospitals) do
        if hospital.pharmacy and hospital.pharmacy[name] then
            pharmacy = hospital.pharmacy[name]
            break
        end
    end
    if not pharmacy then return end

    if pharmacy.job then
        if not hasJob(src, Config.EmsJobs) then return end

        local grade = 0
        if QBCore then
            local player = QBCore.Functions.GetPlayer(src)
            grade = player and player.PlayerData.job.grade.level or 0
        elseif ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            grade = xPlayer and xPlayer.job.grade or 0
        end
        if grade < (pharmacy.grade or 0) then return end
    end

    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:forceOpenInventory(src, 'shop', { id = name, items = pharmacy.items })
    else
        TriggerClientEvent('inventory:client:SetCurrentStash', src, name)
        TriggerEvent('inventory:server:OpenInventory', 'shop', name, pharmacy.items)
    end
end)

if GetResourceState('ox_inventory') == 'started' then
    registerPharmacies()
end

AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' then
        registerPharmacies()
    end
end)

