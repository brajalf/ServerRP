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