local QBCore = exports['qb-core']:GetCoreObject()

player = {}
distressCalls = {}
RegisterNetEvent("ars_ambulancejob:updateDeathStatus", function(death)
    local data = {}
    data.target = source
    data.status = death.isDead
    data.killedBy = death?.weapon or false

    updateStatus(data)
end)

RegisterNetEvent("ars_ambulancejob:revivePlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end

    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        print(source .. ' probile modder')
    else
        local dataToSend = {}
        dataToSend.revive = true

        TriggerClientEvent('ars_ambulancejob:healPlayer', tonumber(data.targetServerId), dataToSend)
    end
end)

RegisterNetEvent("ars_ambulancejob:healPlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end


    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        return print(source .. ' probile modder')
    end


    if data.injury then
        TriggerClientEvent('ars_ambulancejob:healPlayer', tonumber(data.targetServerId), data)
    else
        data.anim = "medic"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", source, data)
        data.anim = "dead"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", data.targetServerId, data)
    end
end)

RegisterNetEvent("ars_ambulancejob:createDistressCall", function(data)
    if not source or source < 1 then return end
    distressCalls[#distressCalls + 1] = {
        msg = data.msg,
        gps = data.gps,
        location = data.location,
        name = getPlayerName(source)
    }

    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            TriggerClientEvent("ars_ambulancejob:createDistressCall", id, getPlayerName(source))
        end
    end
end)

RegisterNetEvent("ars_ambulancejob:callCompleted", function(call)
    for i = #distressCalls, 1, -1 do
        if distressCalls[i].gps == call.gps and distressCalls[i].msg == call.msg then
            table.remove(distressCalls, i)
            break
        end
    end
end)

RegisterNetEvent("ars_ambulancejob:removAddItem", function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    if data.toggle then
        Player.Functions.RemoveItem(data.item, data.quantity)
    else
        Player.Functions.AddItem(data.item, data.quantity)
    end
end)

RegisterNetEvent('ars_ambulancejob:addRemoveMoney', function(add, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    if add then
        Player.Functions.AddMoney('cash', amount)
    else
        Player.Functions.RemoveMoney('cash', amount)
    end
end)

RegisterNetEvent("ars_ambulancejob:useItem", function(data)
    if not hasJob(source, Config.EmsJobs) then return end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local item = Player.Functions.GetItemByName(data.item)
    if not item then return end

    local slot = item.slot
    local quality = item.info and item.info.quality or 100
    local newQuality = quality - data.value

    exports.ox_inventory:SetDurability(source, slot, newQuality)
end)

RegisterNetEvent("ars_ambulancejob:removeInventory", function()
    if player[source].isDead and Config.RemoveItemsOnRespawn then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.ClearInventory() end
    end
end)

RegisterNetEvent("ars_ambulancejob:putOnStretcher", function(data)
    if not player[data.target].isDead then return end
    TriggerClientEvent("ars_ambulancejob:putOnStretcher", data.target, data.toggle)
end)

RegisterNetEvent("ars_ambulancejob:togglePatientFromVehicle", function(data)
    print(data.target)
    if not player[data.target].isDead then return end

    TriggerClientEvent("ars_ambulancejob:togglePatientFromVehicle", data.target, data.vehicle)
end)

lib.callback.register('ars_ambulancejob:getDeathStatus', function(source, target)
    return player[target] and player[target] or getDeathStatus(target or source)
end)

lib.callback.register('ars_ambulancejob:getData', function(source, target)
    local data = {}
    data.injuries = Player(target).state.injuries or false
    data.status = getDeathStatus(target or source) or Player(target).state.dead
    data.killedBy = player[target]?.killedBy or false

    return data
end)

lib.callback.register('ars_ambulancejob:getDistressCalls', function(source)
    return distressCalls
end)

lib.callback.register('ars_ambulancejob:openMedicalBag', function(source)
    return "medicalBag_" .. source
end)
lib.callback.register('ars_ambulancejob:getItem', function(source, name)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    return Player.Functions.GetItemByName(name)
end)

lib.callback.register('ars_ambulancejob:getMedicsOniline', function(source)
    local count = 0
    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            count += 1
        end
    end
    return count
end)

lib.versionCheck('Arius-Development/ars_ambulancejob')
