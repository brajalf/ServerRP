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
        categories = Config.Categories,
        recipes = FilterRecipesForJob(Config.Recipes, job)
    }
end

local function AddZoneFn(src, zone)
    if not QBCore.Functions.HasPermission(src, 'admin') then return nil end
    zone.name = zone.name or ('jc_%s_%d'):format(zone.requiredJob or 'job', os.time())
    local id = MySQL.insert.await('INSERT INTO crafting_zones (name, coords, distance, allowed_categories, required_job, required_items, use_zone, radius, min_z, max_z, length, width, heading, spawn_object, model) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        zone.name,
        json.encode(zone.coords),
        zone.distance or 2.5,
        json.encode(zone.allowedCategories or {}),
        zone.requiredJob,
        json.encode(zone.requiredItems or {}),
        zone.useZone and 1 or 0,
        zone.radius,
        zone.minZ,
        zone.maxZ,
        zone.length,
        zone.width,
        zone.heading,
        zone.spawnObject == false and 0 or 1,
        zone.model
    })
    if not id then return nil end
    zone.id = id
    table.insert(CraftingData.zones, zone)
    Config.CraftingTables = CraftingData.zones
    TriggerClientEvent('RaySist-Crafting:client:SyncZones', -1, CraftingData.zones)
    return id
end

local function DeleteZoneFn(src, id)
    if not QBCore.Functions.HasPermission(src, 'admin') then return false end
    MySQL.query.await('DELETE FROM crafting_zones WHERE id = ?', { id })
    for i, z in ipairs(CraftingData.zones) do
        if z.id == id then
            table.remove(CraftingData.zones, i)
            break
        end
    end
    Config.CraftingTables = CraftingData.zones
    TriggerClientEvent('RaySist-Crafting:client:RemoveTable', -1, id)
    return true
end

local function CreateCategoryFn(src, cat)
    if not QBCore.Functions.HasPermission(src, 'admin') then return nil end
    local id = MySQL.insert.await('INSERT INTO crafting_categories (name, label, icon) VALUES (?, ?, ?)', {
        cat.name,
        cat.label,
        cat.icon
    })
    if not id then return nil end
    cat.id = id
    table.insert(CraftingData.categories, cat)
    Config.Categories = CraftingData.categories
    return id
end

local function RenameCategoryFn(src, data)
    if not QBCore.Functions.HasPermission(src, 'admin') then return false end
    MySQL.update.await('UPDATE crafting_categories SET name = ?, label = ? WHERE name = ?', {
        data.new,
        data.label,
        data.old
    })
    for _, c in pairs(CraftingData.categories) do
        if c.name == data.old then
            c.name = data.new
            c.label = data.label
            break
        end
    end
    for _, r in pairs(CraftingData.recipes) do
        if r.category == data.old then r.category = data.new end
    end
    Config.Categories = CraftingData.categories
    Config.Recipes = CraftingData.recipes
    return true
end

local function SaveRecipeFn(src, recipe)
    if not QBCore.Functions.HasPermission(src, 'admin') then return false end
    local ingredients = json.encode(recipe.ingredients or {})
    local requireBlueprint = recipe.requireBlueprint and 1 or 0
    local exists = MySQL.scalar.await('SELECT id FROM crafting_recipes WHERE name = ?', { recipe.name })
    if exists then
        MySQL.update.await('UPDATE crafting_recipes SET label = ?, category = ?, time = ?, ingredients = ?, require_blueprint = ?, blueprint_item = ?, job = ? WHERE name = ?', {
            recipe.label,
            recipe.category,
            recipe.time or 0,
            ingredients,
            requireBlueprint,
            recipe.blueprintItem,
            recipe.job,
            recipe.name
        })
    else
        MySQL.insert.await('INSERT INTO crafting_recipes (name, label, category, time, ingredients, require_blueprint, blueprint_item, job) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            recipe.name,
            recipe.label,
            recipe.category,
            recipe.time or 0,
            ingredients,
            requireBlueprint,
            recipe.blueprintItem,
            recipe.job
        })
    end
    local found = false
    for i, r in ipairs(CraftingData.recipes) do
        if r.name == recipe.name then
            CraftingData.recipes[i] = recipe
            found = true
            break
        end
    end
    if not found then
        CraftingData.recipes[#CraftingData.recipes+1] = recipe
    end
    Config.Recipes = CraftingData.recipes
    return true
end

local function DeleteRecipeFn(src, name)
    if not QBCore.Functions.HasPermission(src, 'admin') then return false end
    MySQL.query.await('DELETE FROM crafting_recipes WHERE name = ?', { name })
    for i, r in ipairs(CraftingData.recipes) do
        if r.name == name then
            table.remove(CraftingData.recipes, i)
            break
        end
    end
    Config.Recipes = CraftingData.recipes
    return true
end

local function EnsureCraftingTables()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/crafting.sql')
    if not sql then
        print('^1[RaySist-Crafting]^0 Unable to load crafting.sql')
        return
    end

    for query in sql:gmatch('CREATE TABLE IF NOT EXISTS[^;]+;') do
        MySQL.query.await(query)
        local tableName = query:match('CREATE TABLE IF NOT EXISTS%s+`?(%w+)`?')
        print(('[RaySist-Crafting] Ensured table %s'):format(tableName or 'unknown'))
    end

    MySQL.query.await(
        [[ALTER TABLE crafting_zones ADD COLUMN IF NOT EXISTS name VARCHAR(50) UNIQUE]]
    )
end

local function LoadCraftingData()
    local categories = MySQL.query.await('SELECT * FROM crafting_categories') or {}
    local recipes = MySQL.query.await('SELECT * FROM crafting_recipes') or {}
    local zones = MySQL.query.await('SELECT * FROM crafting_zones') or {}

    for _, z in pairs(zones) do
        z.coords = json.decode(z.coords or '{}')
        z.allowedCategories = json.decode(z.allowed_categories or '[]')
        z.requiredItems = json.decode(z.required_items or '[]')
        z.useZone = z.use_zone == 1
        z.radius = tonumber(z.radius)
        z.minZ = tonumber(z.min_z)
        z.maxZ = tonumber(z.max_z)
        z.length = tonumber(z.length)
        z.width = tonumber(z.width)
        z.heading = tonumber(z.heading)
        z.spawnObject = z.spawn_object == 1
    end

    for _, r in pairs(recipes) do
        r.ingredients = json.decode(r.ingredients or '[]')
        r.requireBlueprint = r.require_blueprint == 1
    end

    CraftingData.zones = zones

    if next(categories) then
        CraftingData.categories = categories
        Config.Categories = categories
    else
        CraftingData.categories = Config.Categories
    end

    if next(recipes) then
        CraftingData.recipes = recipes
        Config.Recipes = recipes
    else
        CraftingData.recipes = Config.Recipes
    end

    Config.CraftingTables = CraftingData.zones
end

CreateThread(function()
    EnsureCraftingTables()
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
    local id = AddZoneFn(source, zone)
    cb(id ~= nil, id)
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:DeleteZone', function(source, cb, id)
    cb(DeleteZoneFn(source, id))
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:CreateCategory', function(source, cb, cat)
    cb(CreateCategoryFn(source, cat) ~= nil)
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:RenameCategory', function(source, cb, data)
    cb(RenameCategoryFn(source, data))
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:SaveRecipe', function(source, cb, recipe)
    cb(SaveRecipeFn(source, recipe))
end)

QBCore.Functions.CreateCallback('RaySist-Crafting:server:DeleteRecipe', function(source, cb, name)
    cb(DeleteRecipeFn(source, name))
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

exports('GetCraftingData', GetCraftingDataForJob)
exports('AddZone', AddZoneFn)
exports('DeleteZone', DeleteZoneFn)
exports('CreateCategory', CreateCategoryFn)
exports('RenameCategory', RenameCategoryFn)
exports('SaveRecipe', SaveRecipeFn)
exports('DeleteRecipe', DeleteRecipeFn)
