if GetResourceState('ox_inventory') == 'started' then
    for _, hospital in pairs(Config.Hospitals) do
        if hospital.pharmacy then
            for name, pharmacy in pairs(hospital.pharmacy) do
                exports.ox_inventory:RegisterShop(name, {
                    name = pharmacy.label,
                    groups = pharmacy.job and Config.EmsJobs or nil,
                    inventory = pharmacy.items,
                })
            end
        end
    end
end

