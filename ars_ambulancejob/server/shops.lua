local function registerPharmacies()
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

if GetResourceState('ox_inventory') == 'started' then
    registerPharmacies()
else
    AddEventHandler('onResourceStart', function(resource)
        if resource == 'ox_inventory' then
            registerPharmacies()
        end
    end)
end

