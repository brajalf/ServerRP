local DrawMarker            = DrawMarker
local IsControlJustReleased = IsControlJustReleased
local CreateThread          = CreateThread


local function OpenStash(id, data)
    if GetResourceState('ox_inventory') == 'started' then
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, data)
    else
        if GetResourceState('qb-inventory') == 'started' then
            TriggerServerEvent('qb-inventory:server:OpenInventory', 'stash', id, {maxweight = data.weight, slots = data.slots})
        else
            local inv = exports['qb-inventory']
            if inv and inv.OpenStash then
                inv:OpenStash(id, data.slots, data.weight)
            end
        end
        TriggerEvent('inventory:client:SetCurrentStash', id)
    end
end


local function createStashes()
    for index, hospital in pairs(Config.Hospitals) do
        for id, stash in pairs(hospital.stash) do
            lib.points.new({
                coords = stash.pos,
                distance = 3,
                onEnter = function(self)
                    if hasJob(Config.EmsJobs) then
                        lib.showTextUI(locale('control_to_open_stash'))
                    end
                end,
                onExit = function(self)
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    if hasJob(Config.EmsJobs) then
                        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.2, 0.2, 0.2, 199, 208, 209, 100, true, true, 2, nil, nil, false)

                        if IsControlJustReleased(0, 38) then
                            OpenStash(id, { slots = stash.slots, weight = stash.weight * 1000 })
                        end
                    end
                end,
            })
        end
    end
end
CreateThread(createStashes)

-- © 𝐴𝑟𝑖𝑢𝑠 𝐷𝑒𝑣𝑒𝑙𝑜𝑝𝑚𝑒𝑛𝑡
