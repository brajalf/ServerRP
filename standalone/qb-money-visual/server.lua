local QBCore = exports['qb-core']:GetCoreObject()

local function syncCashItem(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local cash = math.floor(Player.PlayerData.money.cash or 0)

    -- Limpia el ítem visual previo
    exports.ox_inventory:RemoveItem(src, 'cash', 100000000, nil, nil, true) -- ignoreItemChecks=true (no falla por bloqueos)

    if cash > 0 then
        -- Ítem visual (debe existir en QBCore.Shared.Items con weight=0 e imagen)
        exports.ox_inventory:AddItem(src, 'cash', cash, { __visual = true, __locked = true })
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    syncCashItem(Player.PlayerData.source)
end)

RegisterNetEvent('QBCore:Server:OnMoneyChange', function(src, account, amount, isAdd)
    if account ~= 'cash' then return end
    syncCashItem(src)
end)

-- Bloquear intentos de eliminar/mover el ítem 'cash' visual (seguro)
AddEventHandler('ox_inventory:removeItem', function(payload, cb)
    local src = payload and payload.source
    if payload and payload.name == 'cash' and payload.metadata and payload.metadata.__visual then
        cb(false) -- Denegar
        return
    end
end)

AddEventHandler('ox_inventory:swapItems', function(payload, cb)
    local a = payload and payload.from
    local b = payload and payload.to
    local function isCash(slot)
        return slot and slot.name == 'cash' and slot.metadata and slot.metadata.__visual
    end
    if isCash(a) or isCash(b) then
        cb(false)
        return
    end
end)

AddEventHandler('ox_inventory:dropItem', function(payload, cb)
    if payload and payload.name == 'cash' and payload.metadata and payload.metadata.__visual then
        cb(false)
        return
    end
end)

