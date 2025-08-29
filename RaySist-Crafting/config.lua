Config = {}

Config.Debug = false

-- Crafting Tables with specific item categories
Config.CraftingTables = {
    {
        name = "police_table",
        model = `gr_prop_gr_bench_04b`,
        coords = vector4(-968.11, -3011.98, 13.95, 56.95),
        length = 1.0,
        width = 1.0,
        heading = 85.0,
        minZ = 29.0,
        maxZ = 31.0,
        distance = 2.5,
        allowedCategories = {"police_weapons", "ammo"},
        tableLabel = "Police Workbench",
        requiredJob = "police"
    },
    {
        name = "ems_table",
        model = `prop_tool_bench01`,
        coords = vector4(-963.64, -3004.74, 13.95, 62.79),
        length = 1.0,
        width = 1.0,
        heading = 180.0,
        minZ = 29.0,
        maxZ = 31.0,
        distance = 2.5,
        allowedCategories = {"ems"},
        tableLabel = "Medical Station",
        requiredJob = "ambulance"
    },
    {
        name = "restaurant_table",
        model = `prop_cooker_03`,
        coords = vector4(-966.02, -3008.91, 13.95, 63.94),
        length = 1.0,
        width = 1.0,
        heading = 110.5,
        minZ = 29.0,
        maxZ = 31.0,
        distance = 2.5,
        allowedCategories = {"restaurant"},
        tableLabel = "Restaurant Kitchen",
        requiredJob = "burgershot"
    },
    {
        name = "bar_table",
        model = `prop_bar_fridge_01`,
        coords = vector4(-960.0, -3000.0, 13.95, 0.0),
        length = 1.0,
        width = 1.0,
        heading = 0.0,
        minZ = 29.0,
        maxZ = 31.0,
        distance = 2.5,
        allowedCategories = {"bar"},
        tableLabel = "Bar Counter",
        requiredJob = "bartender"
    },
    {
        name = "illegal_table",
        model = `prop_tool_bench02`,
        coords = vector4(-955.0, -2995.0, 13.95, 0.0),
        length = 1.0,
        width = 1.0,
        heading = 0.0,
        minZ = 29.0,
        maxZ = 31.0,
        distance = 2.5,
        allowedCategories = {"illegal"},
        tableLabel = "Illegal Workbench",
        requiredJob = "criminal"
    }
}

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
