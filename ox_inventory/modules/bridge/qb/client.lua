--This file has been modified from the current version to return older functionality that allows for the use of qb-core.

local QBCore = exports['qb-core']:GetCoreObject()
local Inventory = require 'modules.inventory.client'
local Weapon = require 'modules.weapon.client'

local function normalize(items)
    if not items then return {} end
    local out = {}
    if type(items) == 'string' then
        out[#out+1] = { name = items, amount = 1 }
        return out
    end
    if items.name then
        out[#out+1] = { name = items.name, amount = items.amount or 1, metadata = items.info or items.metadata }
        return out
    end
    for _, it in pairs(items) do
        if type(it) == 'string' then
            out[#out+1] = { name = it, amount = 1 }
        elseif type(it) == 'table' then
            out[#out+1] = { name = it.name or it[1], amount = it.amount or 1, metadata = it.info or it.metadata }
        end
    end
    return out
end

local currentStash

RegisterNetEvent('QBCore:Client:OnPlayerUnload', client.onLogout)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if source == '' or not PlayerData.loaded then return end

    if (data.metadata.isdead or data.metadata.inlaststand) ~= PlayerData.dead then
        PlayerData.dead = data.metadata.isdead or data.metadata.inlaststand
        OnPlayerData('dead', PlayerData.dead)
    end

    local groups = PlayerData.groups

    if not groups[data.job.name] or not groups[data.gang.name] or groups[data.job.name] ~= data.job.grade.level or groups[data.gang.name] ~= data.gang.grade.level then
        PlayerData.groups = {
            [data.job.name] = data.job.grade.level,
            [data.gang.name] = data.gang.grade.level,
        }

        OnPlayerData('groups', PlayerData.groups)
    end

    if data.metadata.ishandcuffed then
        PlayerData.cuffed = true
        LocalPlayer.state:set('invBusy', true, false)
        Weapon.Disarm()
    elseif PlayerData.cuffed then
        PlayerData.cuffed = false
        LocalPlayer.state:set('invBusy', false, false)
    end
end)

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    for name, value in pairs(values) do
        -- compatibility for ESX style values
        if value > 100 or value < -100 then
            value = value * 0.0001
        end

        if name == "hunger" then
            TriggerServerEvent('consumables:server:addHunger', QBCore.Functions.GetPlayerData().metadata.hunger + value)
        elseif name == "thirst" then
            TriggerServerEvent('consumables:server:addThirst', QBCore.Functions.GetPlayerData().metadata.thirst + value)
        elseif name == "stress" then
            if value > 0 then
                TriggerServerEvent('hud:server:GainStress', value)
            else
                value = math.abs(value)
                TriggerServerEvent('hud:server:RelieveStress', value)
            end
        end
    end
end

AddStateBagChangeHandler('inv_busy', ('player:%s'):format(cache.serverId), function(_, _, value)
    LocalPlayer.state:set('invBusy', value, false)
end)

local function export(exportName, func)
    AddEventHandler(('__cfx_export_%s_%s'):format(string.strsplit('.', exportName, 2)), function(setCB)
        setCB(func or function()
            error(("export '%s' is not supported when using ox_inventory"):format(exportName))
        end)
    end)
end

export('qb-inventory.HasItem', function(items, amount, metadata)
    local list = normalize(items)
    local needed = amount or 1
    for _, it in ipairs(list) do
        local cnt = exports.ox_inventory:Search('count', string.lower(it.name), metadata or it.metadata)
        if cnt >= (it.amount or needed) then return true end
    end
    return false
end)

local function ItemBox(items, type, amount)
    for _, item in ipairs(normalize(items)) do
        local info = exports.ox_inventory:Items(item.name)
        TriggerEvent('ox_inventory:itemNotify', { info, type, amount or item.amount })
    end
end
export('qb-inventory.ItemBox', ItemBox)

export('qb-inventory.ShowHotbar', function()
    SendNUIMessage({ action = 'toggleHotbar', state = true })
end)

export('qb-inventory.HideHotbar', function()
    SendNUIMessage({ action = 'toggleHotbar', state = false })
end)

export('qb-inventory.CloseInventory', function()
    TriggerEvent('ox_inventory:closeInventory')
    currentStash = nil
end)

RegisterNetEvent('qb-inventory:client:OpenShop', function(id)
    exports.ox_inventory:openInventory('shop', id)
end)

RegisterNetEvent('inventory:client:SetCurrentStash', function(name)
    currentStash = name
end)

RegisterNetEvent('qb-inventory:client:openInventory', function(items, other)
    local invType = 'player'
    local invId

    if type(other) == 'table' then
        invType = other.type or invType
        invId = other.name or other.id

        if invId and not other.type then
            if invId:find('stash%-') then
                invType = 'stash'
            elseif invId:find('shop%-') then
                invType = 'shop'
            elseif invId:find('trunk%-') then
                invType = 'trunk'
            elseif invId:find('glovebox%-') then
                invType = 'glovebox'
            end
        end
    end

    exports.ox_inventory:openInventory(invType, invId)
end)
