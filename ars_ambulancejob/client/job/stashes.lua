local DrawMarker            = DrawMarker
local IsControlJustReleased = IsControlJustReleased
local CreateThread          = CreateThread


local inventoryType = GetResourceState('ox_inventory') == 'started' and 'ox' or (GetResourceState('qb-inventory') == 'started' and 'qb' or nil)


function SetCurrentStash(id)
    if inventoryType == 'ox' then
        TriggerEvent('ox_inventory:client:SetCurrentStash', id)
    elseif inventoryType == 'qb' then
        TriggerEvent('qb-inventory:client:SetCurrentStash', id)
    else
        lib.notify({ type = 'error', description = 'No inventory resource started' })
    end
end

local function OpenStash(id, data)
    if inventoryType == 'ox' then
        TriggerServerEvent('ox_inventory:server:OpenInventory', 'stash', id, data)
    elseif inventoryType == 'qb' then
        TriggerServerEvent('qb-inventory:server:OpenInventory', 'stash', id, {maxweight = data.weight, slots = data.slots})
    else
        lib.notify({ type = 'error', description = 'No inventory resource started' })
        return
    end

    SetCurrentStash(id)
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
