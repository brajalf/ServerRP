Config = {}

Config.Debug = false

-- Crafting tables are registered dynamically via qb-jobcreator
Config.CraftingTables = {}

-- Crafting Categories
Config.Categories = {
    {
        name = "police_weapons",
        label = "Armas Policiales",
        icon = "gun",
    },
    {
        name = "ammo",
        label = "Ammunition",
        icon = "bomb",
    },
    {
        name = "ems",
        label = "EMS",
        icon = "first-aid",
    },
    {
        name = "restaurant",
        label = "Restaurante",
        icon = "utensils",
    },
    {
        name = "bar",
        label = "Bar",
        icon = "beer",
    },
    {
        name = "illegal",
        label = "Ilegal",
        icon = "mask",
    }
}

-- Crafting Recipes
-- Optional field `job` restricts recipes to players with that job
Config.Recipes = {
    -- Police Weapons
    {
        name = "weapon_pistol",
        label = "Pistol",
        category = "police_weapons",
        time = 60,
        ingredients = {
            { item = "metalscrap", amount = 30, label = "Metal Scrap" },
            { item = "steel", amount = 45, label = "Steel" },
            { item = "rubber", amount = 20, label = "Rubber" }
        },
        requireBlueprint = false,
        blueprintItem = "pistol_blueprint",
        job = "police"
    },
    {
        name = "weapon_smg",
        label = "SMG",
        category = "police_weapons",
        time = 90,
        ingredients = {
            { item = "metalscrap", amount = 50, label = "Metal Scrap" },
            { item = "steel", amount = 60, label = "Steel" },
            { item = "rubber", amount = 30, label = "Rubber" }
        },
        requireBlueprint = true,
        blueprintItem = "smg_blueprint",
        job = "police"
    },

    -- Ammo
    {
        name = "pistol_ammo",
        label = "Pistol Ammo",
        category = "ammo",
        time = 10,
        ingredients = {
            { item = "metalscrap", amount = 10, label = "Metal Scrap" },
            { item = "steel", amount = 10, label = "Steel" },
            { item = "copper", amount = 10, label = "Copper" }
        },
        requireBlueprint = false
    },
    {
        name = "smg_ammo",
        label = "SMG Ammo",
        category = "ammo",
        time = 15,
        ingredients = {
            { item = "metalscrap", amount = 15, label = "Metal Scrap" },
            { item = "steel", amount = 15, label = "Steel" },
            { item = "copper", amount = 15, label = "Copper" }
        },
        requireBlueprint = false
    },
    {
        name = "shotgun_ammo",
        label = "Shotgun Ammo",
        category = "ammo",
        time = 17,
        ingredients = {
            { item = "metalscrap", amount = 17, label = "Metal Scrap" },
            { item = "steel", amount = 17, label = "Steel" },
            { item = "copper", amount = 17, label = "Copper" }
        },
        requireBlueprint = false
    },
    {
        name = "rifle_ammo",
        label = "Rifle Ammo",
        category = "ammo",
        time = 20,
        ingredients = {
            { item = "metalscrap", amount = 20, label = "Metal Scrap" },
            { item = "steel", amount = 20, label = "Steel" },
            { item = "copper", amount = 20, label = "Copper" }
        },
        requireBlueprint = false
    },

    -- Restaurant
    {
        name = "burger-bleeder",
        label = "Burger Bleeder",
        category = "restaurant",
        time = 10,
        ingredients = {
            { item = "bread", amount = 1, label = "Bread" },
            { item = "meat", amount = 1, label = "Meat" },
            { item = "lettuce", amount = 1, label = "Lettuce" }
        },
        requireBlueprint = false,
        job = "burgershot"
    },

    -- Bar
    {
        name = "beer",
        label = "Beer",
        category = "bar",
        time = 5,
        ingredients = {
            { item = "hops", amount = 2, label = "Hops" },
            { item = "water_bottle", amount = 1, label = "Water" }
        },
        requireBlueprint = false,
        job = "bartender"
    },

    -- EMS
    {
        name = "bandage",
        label = "Bandage",
        category = "ems",
        time = 15,
        ingredients = {
            { item = "cloth", amount = 3, label = "Cloth" },
            { item = "alcohol", amount = 1, label = "Alcohol" }
        },
        requireBlueprint = false,
        job = "ambulance"
    },
    {
        name = "painkillers",
        label = "Painkillers",
        category = "ems",
        time = 18,
        ingredients = {
            { item = "chemicals", amount = 2, label = "Chemicals" },
            { item = "plastic", amount = 1, label = "Plastic" }
        },
        requireBlueprint = false,
        job = "ambulance"
    },
    {
        name = "firstaid",
        label = "First Aid Kit",
        category = "ems",
        time = 30,
        ingredients = {
            { item = "cloth", amount = 5, label = "Cloth" },
            { item = "alcohol", amount = 3, label = "Alcohol" },
            { item = "painkillers", amount = 2, label = "Painkillers" }
        },
        requireBlueprint = false,
        job = "ambulance"
    },

    -- Illegal
    {
        name = "lockpick",
        label = "Lockpick",
        category = "illegal",
        time = 20,
        ingredients = {
            { item = "metalscrap", amount = 5, label = "Metal Scrap" },
            { item = "plastic", amount = 5, label = "Plastic" }
        },
        requireBlueprint = false
    },
    {
        name = "advancedlockpick",
        label = "Advanced Lockpick",
        category = "illegal",
        time = 33,
        ingredients = {
            { item = "metalscrap", amount = 13, label = "Metal Scrap" },
            { item = "plastic", amount = 13, label = "Plastic" }
        },
        requireBlueprint = false
    },
    {
        name = "screwdriverset",
        label = "Screwdriver Set",
        category = "illegal",
        time = 15,
        ingredients = {
            { item = "metalscrap", amount = 8, label = "Metal Scrap" },
            { item = "plastic", amount = 3, label = "Plastic" },
            { item = "rubber", amount = 2, label = "Rubber" }
        },
        requireBlueprint = false
    },
    {
        name = "drill",
        label = "Drill",
        category = "illegal",
        time = 40,
        ingredients = {
            { item = "metalscrap", amount = 20, label = "Metal Scrap" },
            { item = "steel", amount = 10, label = "Steel" },
            { item = "electronics", amount = 5, label = "Electronics" }
        },
        requireBlueprint = true,
        blueprintItem = "drill_blueprint"
    }
}

-- Skills
Config.UseSkills = false -- Set to false if you don't want to use skills
Config.SkillName = "crafting" -- Skill name in your skills system
Config.SkillIncreaseAmount = 0.1 -- How much skill increases per craft
