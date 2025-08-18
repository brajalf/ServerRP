-- Origen UI compatibility shims for qb-inventory
-- Registers extra NUI callbacks expected by the Origen frontend and maps them to QB-core behaviors.

local QBCore = exports['qb-core']:GetCoreObject()

local function safeCb(cb, ...)
    if cb then cb(...) end
end

-- Simple notification passthrough
RegisterNUICallback('Notify', function(data, cb)
    if data and data.message then
        QBCore.Functions.Notify(tostring(data.message), data.type or 'primary')
    end
    safeCb(cb, true)
end)

-- Execute client events/commands from UI (use with care)
RegisterNUICallback("ExecuteEvent", function(data, cb)
    if data and data.event then
        TriggerEvent(data.event, data.args or {})
    end
    safeCb(cb, true)
end)

RegisterNUICallback("ExecuteCommand", function(data, cb)
    if data and data.command then
        ExecuteCommand(tostring(data.command))
    end
    safeCb(cb, true)
end)

-- Wrapper to call server callbacks from UI
RegisterNUICallback('TriggerCallback', function(data, cb)
    if not data or not data.name then
        return safeCb(cb, false)
    end
    local args = data.args or {}
    QBCore.Functions.TriggerCallback(data.name, function(result)
        safeCb(cb, result)
    end, table.unpack(args))
end)

-- Abrir inventario de un jugador cercano (fallback para UI)
RegisterNUICallback('OpenNearPlayerInventory', function(data, cb)
    local target = tonumber(data and data.id)
    if target and target > 0 then
        TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', target)
    end
    if cb then cb(true) end
end)

-- Por si la UI usa este nombre
RegisterNUICallback('OpenOtherPlayer', function(data, cb)
    local target = tonumber(data and data.id)
    if target and target > 0 then
        TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', target)
    end
    if cb then cb(true) end
end)

-- (Ya lo tenías) Lista de cercanos para el menú “Give / Cachear”
RegisterNUICallback('GetNearPlayers', function(data, cb)
    local players = {}
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    for _, pid in ipairs(GetActivePlayers()) do
        local tgt = GetPlayerPed(pid)
        if tgt ~= ped then
            local dist = #(GetEntityCoords(tgt) - myCoords)
            if dist <= (data and data.radius or 3.0) then
                players[#players+1] = {
                    id = GetPlayerServerId(pid),
                    name = GetPlayerName(pid),
                    distance = dist
                }
            end
        end
    end
    if cb then cb(players) end
end)

-- Optional sounds
RegisterNUICallback("PlayDropSound", function(data, cb)
    PlaySound(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
    safeCb(cb, true)
end)

-- Rob cash helper (requiere que tu resource de policía tenga este evento)
RegisterNUICallback('RobMoney', function(data, cb)
    if data and data.TargetId then
        TriggerServerEvent("police:server:RobPlayer", data.TargetId)
    end
    safeCb(cb, true)
end)

-- Item combination helpers
RegisterNUICallback('getCombineItem', function(data, cb)
    QBCore.Functions.TriggerCallback('inventory:server:getCombineItem', function(result)
        safeCb(cb, result or false)
    end, data and data.item or nil)
end)

RegisterNUICallback('combineItem', function(data, cb)
    if not data then return safeCb(cb, false) end
    TriggerServerEvent('inventory:server:combineItem', data.reward, data.requiredItem, data.usedItem)
    safeCb(cb, true)
end)

RegisterNUICallback('combineWithAnim', function(data, cb)
    if not data then return safeCb(cb, false) end
    local ped = PlayerPedId()
    local aDict = data.animDict or 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    local aLib = data.anim or 'machinic_loop_mechandplayer'
    RequestAnimDict(aDict)
    while not HasAnimDictLoaded(aDict) do Wait(0) end
    TaskPlayAnim(ped, aDict, aLib, 8.0, 8.0, -1, 16, 0, false, false, false)
    Wait(1200)
    ClearPedTasks(ped)
    TriggerServerEvent('inventory:server:combineItem', data.reward, data.requiredItem, data.usedItem)
    safeCb(cb, true)
end)

-- Optional DeleteItem direct (server validará)
RegisterNUICallback('DeleteItem', function(data, cb)
    if not data or not data.item or not data.amount then
        return safeCb(cb, false)
    end
    TriggerServerEvent('qb-inventory:server:DeleteItemDirect', data.item, data.amount, data.slot)
    safeCb(cb, true)
end)

-- Opciones extra (stub)
RegisterNUICallback('inventory_options', function(data, cb)
    safeCb(cb, { enable_hotbar = true })
end)


-- Traducciones básicas para la UI Origen
RegisterNUICallback('GetTranslate', function(data, cb)
    cb({
        ["Man"] = "Hombre",
        ["Woman"] = "Mujer",
        ["FirstName"] = "Nombre",
        ["LastName"] = "Apellido",
        ["Birthday"] = "Fecha de nacimiento",
        ["Gender"] = "Género",
        ["Nacionality"] = "Nacionalidad",
        ["Citizenid"] = "Documento",
        ["SerialNumber"] = "N° de serie",
        ["Ammo"] = "Munición",
        ["Accesories"] = "Accesorios",
        ["RemaingNotes"] = "Notas restantes",
        ["EfectiveQuantity"] = "Cantidad de efectivo",
        ["MarkedMoney"] = "Dinero marcado"
    })
end)
