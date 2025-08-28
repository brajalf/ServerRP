local QBCore = exports['qb-core']:GetCoreObject()
local craftingPlayers = {}
local CraftingData = {
    zones = {},
    categories = {},
    recipes = {}
}

local function FilterRecipesForJob(recipes, job)
    local filtered = {}
    for _, r in pairs(recipes or {}) do
        if not r.job or r.job == job then
            filtered[#filtered+1] = r
        end
    end
    return filtered
end

local function GetCraftingDataForJob(job)
    return {
        zones = CraftingData.zones,
        categories = CraftingData.categories,
        recipes = FilterRecipesForJob(CraftingData.recipes, job)
    }
end

local function LoadCraftingData()
    local categories = MySQL.query.await('SELECT * FROM crafting_categories') or {}
    local recipes = MySQL.query.await('SELECT * FROM crafting_recipes') or {}
    local zones = MySQL.query.await('SELECT * FROM crafting_zones') or {}

    for _, z in pairs(zones) do
        z.coords = json.decode(z.coords or '{}')
        z.allowedCategories = json.decode(z.allowed_categories or '[]')
        z.requiredItems = json.decode(z.required_items or '[]')
    end

    for _, r in pairs(recipes) do
        r.ingredients = json.decode(r.ingredients or '[]')
        r.requireBlueprint = r.require_blueprint == 1
    end

    CraftingData.zones = zones
    CraftingData.categories = categories
    CraftingData.recipes = recipes

    Config.CraftingTables = CraftingData.zones
    Config.Categories = CraftingData.categories
    Config.Recipes = CraftingData.recipes
end

CreateThread(function()
    LoadCraftingData()
    Wait(100)
    local players = QBCore.Functions.GetQBPlayers()
    for _, Player in pairs(players) do
        local job = Player.PlayerData.job.name
        TriggerClientEvent('RaySist-Crafting:client:SyncData', Player.PlayerData.source, GetCraftingDataForJob(job))
    end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local job = Player.PlayerData.job.name
    TriggerClientEvent('RaySist-Crafting:client:SyncData', Player.PlayerData.source, GetCraftingDataForJob(job))
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:GetCraftingData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local job = Player and Player.PlayerData.job.name or nil
    cb(GetCraftingDataForJob(job))
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:AddZone', function(source, cb, zone)
    if not QBCore.Functions.HasPermission(source, 'admin') then return cb(false) end
    local id = MySQL.insert.await('INSERT INTO crafting_zones (name, model, coords, distance, allowed_categories, required_job, required_items) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        zone.name,
        zone.model,
        json.encode(zone.coords),
        zone.distance or 2.5,
        json.encode(zone.allowedCategories or {}),
        zone.requiredJob,
        json.encode(zone.requiredItems or {})
    })
    zone.id = id
    table.insert(CraftingData.zones, zone)
    Config.CraftingTables = CraftingData.zones
    TriggerClientEvent('RaySist-Crafting:client:SyncZones', -1, CraftingData.zones)
    cb(true, id)
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:DeleteZone', function(source, cb, id)
    if not QBCore.Functions.HasPermission(source, 'admin') then return cb(false) end
    MySQL.query.await('DELETE FROM crafting_zones WHERE id = ?', { id })
    for i, z in ipairs(CraftingData.zones) do
        if z.id == id then
            table.remove(CraftingData.zones, i)
            break
        end
    end
    Config.CraftingTables = CraftingData.zones
    TriggerClientEvent('RaySist-Crafting:client:RemoveTable', -1, id)
    cb(true)
end)

-- Get player inventory
QBCore.Functions.CreateCallback('RaySist-Crafting:server:GetPlayerInventory', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    local inventory = {}
    for _, item in pairs(Player.PlayerData.items) do
        if item then
            inventory[item.name] = {
                name = item.name,
                amount = item.amount,
                label = QBCore.Shared.Items[item.name].label
            }
        end
    end

    -- Get player skill if enabled
    if Config.UseSkills then
        local skill = exports['qb-skillz']:GetSkillLevel(source, Config.SkillName)
        inventory.skill = skill or 0
    end

    cb(inventory)
end)

-- Check if player has blueprint
QBCore.Functions.CreateCallback('RaySist-Crafting:server:HasBlueprint', function(source, cb, blueprint)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end

    local hasBlueprint = Player.Functions.GetItemByName(blueprint)
    cb(hasBlueprint ~= nil)
end)

-- Check if player has required items
QBCore.Functions.CreateCallback('RaySist-Crafting:server:HasRequiredItems', function(source, cb, requiredItems)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, "Player not found") end

    local hasAllItems = true
    local missingItems = ""

    for _, itemData in pairs(requiredItems) do
        local item = Player.Functions.GetItemByName(itemData.item)
        if not item then
            hasAllItems = false
            if missingItems ~= "" then missingItems = missingItems .. ", " end
            missingItems = missingItems .. itemData.label
        end
    end

    cb(hasAllItems, missingItems)
end)

-- Start crafting process
RegisterNetEvent('RaySist-Crafting:server:CraftItem', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Find the recipe
    local recipe = nil
    for _, r in pairs(Config.Recipes) do
        if r.name == item then
            recipe = r
            break
        end
    end

    if not recipe then
        TriggerClientEvent('QBCore:Notify', src, "Recipe not found", "error")
        return
    end

    -- Check if player has all ingredients
    local hasAllIngredients = true
    for _, ingredient in pairs(recipe.ingredients) do
        local playerItem = Player.Functions.GetItemByName(ingredient.item)
        if not playerItem or playerItem.amount < ingredient.amount then
            hasAllIngredients = false
            break
        end
    end

    if not hasAllIngredients then
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_enough_materials"), "error")
        return
    end

    -- Remove ingredients
    for _, ingredient in pairs(recipe.ingredients) do
        Player.Functions.RemoveItem(ingredient.item, ingredient.amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[ingredient.item], "remove", ingredient.amount)
    end

    -- Calculate crafting time based on skill if enabled
    local craftTime = recipe.time
    if Config.UseSkills then
        local skill = exports['qb-skillz']:GetSkillLevel(src, Config.SkillName) or 0
        -- Reduce crafting time based on skill (max 50% reduction)
        craftTime = math.max(craftTime * (1 - (skill / 200)), craftTime * 0.5)
    end

    -- Start crafting process
    craftingPlayers[src] = {
        item = item,
        time = craftTime
    }

    TriggerClientEvent('RaySist-Crafting:client:CraftingProgress', src, item, craftTime)

    -- Crafting timer
    SetTimeout(craftTime * 1000, function()
        if not craftingPlayers[src] then return end

        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        -- Calculate success chance based on skill if enabled
        local success = true
        if Config.UseSkills then
            local skill = exports['qb-skillz']:GetSkillLevel(src, Config.SkillName) or 0
            local successChance = 70 + (skill / 2) -- Base 70% + up to 30% from skill
            success = math.random(1, 100) <= successChance

            -- Increase skill
            if success then
                exports['qb-skillz']:UpdateSkill(src, Config.SkillName, Config.SkillIncreaseAmount)
            end
        end

        if success then
            -- Determine amount to give based on category
            local amount = 1
            if recipe.category == "ammo" then
                amount = 10 -- Give 10 ammo at a time
            end

            -- Give crafted item
            Player.Functions.AddItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add", amount)
        end

        -- Send result to client
        TriggerClientEvent('RaySist-Crafting:client:CraftingResult', src, success, item)

        -- Update inventory
        TriggerClientEvent('RaySist-Crafting:client:UpdateInventory', src)

        -- Clear crafting state
        craftingPlayers[src] = nil
    end)
end)

-- Cancel crafting
RegisterNetEvent('RaySist-Crafting:server:CancelCrafting', function()
    local src = source
    if not craftingPlayers[src] then return end

    -- Return ingredients
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local recipe = nil
    for _, r in pairs(Config.Recipes) do
        if r.name == craftingPlayers[src].item then
            recipe = r
            break
        end
    end

    if recipe then
        for _, ingredient in pairs(recipe.ingredients) do
            Player.Functions.AddItem(ingredient.item, ingredient.amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[ingredient.item], "add", ingredient.amount)
        end
    end

    -- Clear crafting state
    craftingPlayers[src] = nil
end)

-- Clear crafting state on player drop
AddEventHandler('playerDropped', function()
    local src = source
    if craftingPlayers[src] then
        craftingPlayers[src] = nil
    end
end)
