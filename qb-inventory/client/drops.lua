HoldingDrop = false
local bagObject = nil
local heldDrop = nil
CurrentDrop = nil
local ActiveDrops = {}

-- Functions

local function trackDrop(id, bag)
    if Config.UseTarget then
        exports['qb-target']:AddTargetEntity(bag, {
            options = {
                {
                    icon = 'fas fa-backpack',
                    label = Lang:t('menu.o_bag'),
                    action = function()
                        TriggerServerEvent('qb-inventory:server:OpenInventory', 'drop', id)
                        CurrentDrop = id
                    end,
                },
                {
                    icon = 'fas fa-hand-pointer',
                    label = 'Pick up bag',
                    action = function()
                        if IsPedArmed(PlayerPedId(), 4) then
                            return QBCore.Functions.Notify('You can not be holding a Gun and a Bag!', 'error', 5500)
                        end
                        if HoldingDrop then
                            return QBCore.Functions.Notify('Your already holding a bag, Go Drop it!', 'error', 5500)
                        end
                        AttachEntityToEntity(
                            bag,
                            PlayerPedId(),
                            GetPedBoneIndex(PlayerPedId(), Config.ItemDropObjectBone),
                            Config.ItemDropObjectOffset[1].x,
                            Config.ItemDropObjectOffset[1].y,
                            Config.ItemDropObjectOffset[1].z,
                            Config.ItemDropObjectOffset[2].x,
                            Config.ItemDropObjectOffset[2].y,
                            Config.ItemDropObjectOffset[2].z,
                            true, true, false, true, 1, true
                        )
                        bagObject = bag
                        HoldingDrop = true
                        heldDrop = id
                        exports['qb-core']:DrawText('Press [G] to drop the bag')
                    end,
                }
            },
            distance = 2.5,
        })
    else
        ActiveDrops[id] = bag
    end
end

function GetDrops()
    QBCore.Functions.TriggerCallback('qb-inventory:server:GetCurrentDrops', function(drops)
        if not drops then return end
        for k, v in pairs(drops) do
            local bag = NetworkGetEntityFromNetworkId(v.entityId)
            if DoesEntityExist(bag) then
                trackDrop(k, bag)
            end
        end
    end)
end

-- Events

RegisterNetEvent('qb-inventory:client:removeDropTarget', function(dropId)
    while not NetworkDoesNetworkIdExist(dropId) do Wait(10) end
    local bag = NetworkGetEntityFromNetworkId(dropId)
    while not DoesEntityExist(bag) do Wait(10) end
    if Config.UseTarget then
        exports['qb-target']:RemoveTargetEntity(bag)
    else
        ActiveDrops['drop-' .. dropId] = nil
    end
end)

RegisterNetEvent('qb-inventory:client:setupDropTarget', function(dropId)
    while not NetworkDoesNetworkIdExist(dropId) do Wait(10) end
    local bag = NetworkGetEntityFromNetworkId(dropId)
    while not DoesEntityExist(bag) do Wait(10) end
    local newDropId = 'drop-' .. dropId
    trackDrop(newDropId, bag)
end)

-- NUI Callbacks

RegisterNUICallback('DropItem', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = tonumber(data and data.radius) or 2.0
    QBCore.Functions.TriggerCallback('qb-inventory:server:createOrReuseDrop', function(dropName)
        cb(dropName)
    end, vector3(coords.x, coords.y, coords.z), radius)
end)

-- Thread

local function getClosestDrop()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    for id, bag in pairs(ActiveDrops) do
        if DoesEntityExist(bag) then
            local dist = #(pos - GetEntityCoords(bag))
            if dist <= 1.5 then
                return id, bag
            end
        else
            ActiveDrops[id] = nil
        end
    end
    return nil
end

CreateThread(function()
    while true do
        local idle = 1000
        if HoldingDrop then
            idle = 0
            if IsControlJustPressed(0, 47) then
                DetachEntity(bagObject, true, true)
                local coords = GetEntityCoords(PlayerPedId())
                local forward = GetEntityForwardVector(PlayerPedId())
                local x, y, z = table.unpack(coords + forward * 0.57)
                SetEntityCoords(bagObject, x, y, z - 0.9, false, false, false, false)
                FreezeEntityPosition(bagObject, true)
                exports['qb-core']:HideText()
                TriggerServerEvent('qb-inventory:server:updateDrop', heldDrop, coords)
                HoldingDrop = false
                bagObject = nil
                heldDrop = nil
            end
        elseif not Config.UseTarget then
            local id, bag = getClosestDrop()
            if id and bag then
                idle = 0
                exports['qb-core']:DrawText('[E] ' .. Lang:t('menu.o_bag') .. ' / [G] Pick up bag')
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('qb-inventory:server:OpenInventory', 'drop', id)
                    CurrentDrop = id
                    exports['qb-core']:HideText()
                elseif IsControlJustPressed(0, 47) then
                    if IsPedArmed(PlayerPedId(), 4) then
                        QBCore.Functions.Notify('You can not be holding a Gun and a Bag!', 'error', 5500)
                    elseif HoldingDrop then
                        QBCore.Functions.Notify('Your already holding a bag, Go Drop it!', 'error', 5500)
                    else
                        AttachEntityToEntity(
                            bag,
                            PlayerPedId(),
                            GetPedBoneIndex(PlayerPedId(), Config.ItemDropObjectBone),
                            Config.ItemDropObjectOffset[1].x,
                            Config.ItemDropObjectOffset[1].y,
                            Config.ItemDropObjectOffset[1].z,
                            Config.ItemDropObjectOffset[2].x,
                            Config.ItemDropObjectOffset[2].y,
                            Config.ItemDropObjectOffset[2].z,
                            true, true, false, true, 1, true
                        )
                        bagObject = bag
                        HoldingDrop = true
                        heldDrop = id
                        exports['qb-core']:DrawText('Press [G] to drop the bag')
                    end
                end
            else
                exports['qb-core']:HideText()
            end
        end
        Wait(idle)
    end
end)
