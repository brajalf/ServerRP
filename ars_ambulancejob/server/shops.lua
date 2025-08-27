

-- codex/replace-openinventory-with-custom-event

local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil
local ESX = GetResourceState('es_extended'):find('start') and exports['es_extended']:getSharedObject() or nil

local function registerPharmacies()
    local useOx = GetResourceState('ox_inventory') == 'started'
    local useQb = GetResourceState('qb-inventory') == 'started'

    if not useOx and not useQb then return end

    for _, hospital in pairs(Config.Hospitals) do
        if hospital.pharmacy then
            for name, pharmacy in pairs(hospital.pharmacy) do
                if useOx then
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

                if useQb then
                    exports['qb-inventory']:CreateShop({
                        name = name,
                        label = pharmacy.label,
                        coords = pharmacy.pos,
                        items = pharmacy.items,
                    })
                end
            end
        end
    end
end



-- codex/replace-openinventory-with-custom-event

local function OpenShop(src, shopId, items)
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:forceOpenInventory(src, 'shop', { id = shopId, items = items })
    else
        exports['qb-inventory']:OpenShop(src, shopId)
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
        if not hasJob(src, Config.EmsJobs) then
            if QBCore then
                TriggerClientEvent('QBCore:Notify', src, 'No tienes el trabajo requerido', 'error')
            elseif ESX then
                TriggerClientEvent('esx:showNotification', src, 'No tienes el trabajo requerido')
            end
            print(('[ars_ambulancejob] %s tried to open pharmacy "%s" without required job'):format(GetPlayerName(src) or src, name))
            return
        end

        local grade = 0
        if QBCore then
            local player = QBCore.Functions.GetPlayer(src)
            grade = player and player.PlayerData.job.grade.level or 0
        elseif ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            grade = xPlayer and xPlayer.job.grade or 0
        end

        local minGrade = pharmacy.grade or 0
        if grade < minGrade then
            if QBCore then
                TriggerClientEvent('QBCore:Notify', src, 'Tu grado es insuficiente', 'error')
            elseif ESX then
                TriggerClientEvent('esx:showNotification', src, 'Tu grado es insuficiente')
            end
            print(('[ars_ambulancejob] %s tried to open pharmacy "%s" with grade %s (required %s)'):format(GetPlayerName(src) or src, name, grade, minGrade))
            return
        end
    end

    OpenShop(src, name, pharmacy.items)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if GetResourceState('ox_inventory') == 'started' or GetResourceState('qb-inventory') == 'started' then
        registerPharmacies()
    end
end)


