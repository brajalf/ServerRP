HoldingDrop = false
local bagObject = nil
local heldDrop = nil
CurrentDrop = nil
local ActiveDrops = {}
local dropProps = {}

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
        for name, data in pairs(drops) do
            if data.coords then
                TriggerEvent('qb-inventory:client:CreateDropProp', name, data.coords)
            end
        end
    end)
end

-- Events

RegisterNetEvent('qb-inventory:client:CreateDropProp', function(name, coords)
    if dropProps[name] then return end
    local model = joaat('prop_paper_bag_small')
    RequestModel(model) while not HasModelLoaded(model) do Wait(0) end
    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    dropProps[name] = obj
    trackDrop(name, obj)
end)

RegisterNetEvent('qb-inventory:client:RemoveDropProp', function(name)
    local obj = dropProps[name]
    if obj and DoesEntityExist(obj) then
        if Config.UseTarget then
            exports['qb-target']:RemoveTargetEntity(obj)
        else
            ActiveDrops[name] = nil
        end
        DeleteObject(obj)
    end
    dropProps[name] = nil
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
