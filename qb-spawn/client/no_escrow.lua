if Config.Settings['Framework'] == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Settings['Framework'] == "oldesx" then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
elseif Config.Settings['Framework'] == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Settings['Framework'] == "oldqb" then
    QBCore = nil
    Citizen.CreateThread(function()
        while QBCore == nil do
            TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
            Citizen.Wait(200)
        end
    end)
elseif Config.Settings['Framework'] == "qbx" then
    if GetResourceState("qbx_core") == "started" then
        QBCore = exports['qbx-core']:GetCoreObject()
    elseif GetResourceState("qbx-core") == "started" then
        QBCore = exports['qbx_core']:GetCoreObject()
    end
elseif Config.Settings['Framework'] == "custom" then
end

Is_Player_Death = function(Framework)
    local Death = false
    if Framework == "qbcore" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.metadata and PlayerData.metadata['isdead'] == true then
            Death = true
        end
    elseif Framework == "esx" then
        ESX.TriggerServerCallback('n-spawn-selector:server:isdead', function(isdead)
            if isdead == true then
                Death = true
            end
        end)
        -- ESX için callback sonucunu beklemek için kısa bir bekleme
        local attempts = 0
        while Death == false and attempts < 10 do
            Wait(100)
            attempts = attempts + 1
        end
    elseif Framework == "custom" then
    end
    return Death
end

Get_Last_Location = function(Framework)
    local Coords = nil
    if Framework == "qbcore" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.position then
            Coords = PlayerData.position
        end
    elseif Framework == "esx" then
        ESX.TriggerServerCallback('n-spawn-selector:server:getlastlocation', function(lastlocation)
            if lastlocation then
                Coords = lastlocation
            end
        end)
        -- ESX için callback sonucunu beklemek için kısa bir bekleme
        local attempts = 0
        while Coords == nil and attempts < 10 do
            Wait(100)
            attempts = attempts + 1
        end
    elseif Framework == "custom" then
    end
    return Coords
end

After_Spawn = function(Framework)
    if Framework == "qbcore" then
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    elseif Framework == "esx" then
    elseif Framework == "custom" then
    end
end