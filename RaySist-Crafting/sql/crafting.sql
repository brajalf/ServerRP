CREATE TABLE IF NOT EXISTS crafting_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    label VARCHAR(50) NOT NULL,
    icon VARCHAR(50) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS crafting_recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    label VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    time INT DEFAULT 0,
    ingredients LONGTEXT,
    require_blueprint TINYINT(1) DEFAULT 0,
    blueprint_item VARCHAR(50) DEFAULT NULL,
    job VARCHAR(50) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS crafting_zones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    coords LONGTEXT NOT NULL,
    distance FLOAT DEFAULT 2.5,
    allowed_categories LONGTEXT,
    required_job VARCHAR(50) DEFAULT NULL,
    required_items LONGTEXT DEFAULT NULL,
    use_zone TINYINT(1) DEFAULT 0,
    radius FLOAT DEFAULT NULL,
    min_z FLOAT DEFAULT NULL,
    max_z FLOAT DEFAULT NULL,
    length FLOAT DEFAULT NULL,
    width FLOAT DEFAULT NULL,
    heading FLOAT DEFAULT NULL,
    spawn_object TINYINT(1) DEFAULT 1,
    model VARCHAR(100) DEFAULT NULL
);

-- Initial categories
INSERT INTO crafting_categories (name, label, icon) VALUES
    ('police_weapons', 'Armas Policiales', 'gun'),
    ('ammo', 'Ammunition', 'bomb'),
    ('ems', 'EMS', 'first-aid'),
    ('restaurant', 'Restaurante', 'utensils'),
    ('bar', 'Bar', 'beer'),
    ('illegal', 'Ilegal', 'mask');

-- Initial recipes
INSERT INTO crafting_recipes (name, label, category, time, ingredients, require_blueprint, blueprint_item, job) VALUES
    ('weapon_pistol','Pistol','police_weapons',60,'[{"item":"metalscrap","amount":30,"label":"Metal Scrap"},{"item":"steel","amount":45,"label":"Steel"},{"item":"rubber","amount":20,"label":"Rubber"}]',0,'pistol_blueprint','police'),
    ('burger-bleeder','Burger Bleeder','restaurant',10,'[{"item":"bread","amount":1,"label":"Bread"},{"item":"meat","amount":1,"label":"Meat"},{"item":"lettuce","amount":1,"label":"Lettuce"}]',0,NULL,'burgershot'),
    ('beer','Beer','bar',5,'[{"item":"hops","amount":2,"label":"Hops"},{"item":"water_bottle","amount":1,"label":"Water"}]',0,NULL,'bartender'),
    ('bandage','Bandage','ems',15,'[{"item":"cloth","amount":3,"label":"Cloth"},{"item":"alcohol","amount":1,"label":"Alcohol"}]',0,NULL,'ambulance'),
    ('lockpick','Lockpick','illegal',20,'[{"item":"metalscrap","amount":5,"label":"Metal Scrap"},{"item":"plastic","amount":5,"label":"Plastic"}]',0,NULL,NULL);

-- Initial crafting zones
INSERT INTO crafting_zones (name, coords, distance, allowed_categories, required_job, required_items, use_zone, radius, min_z, max_z, length, width, heading, spawn_object, model) VALUES
    ('police_table','{"x":-968.11,"y":-3011.98,"z":13.95,"w":56.95}',2.5,'["police_weapons","ammo"]','police',NULL,0,2.5,NULL,NULL,NULL,NULL,NULL,1,'gr_prop_gr_bench_04b'),
    ('ems_table','{"x":-963.64,"y":-3004.74,"z":13.95,"w":62.79}',2.5,'["ems"]','ambulance',NULL,0,2.5,NULL,NULL,NULL,NULL,NULL,1,'prop_tool_bench01'),
    ('restaurant_table','{"x":-966.02,"y":-3008.91,"z":13.95,"w":63.94}',2.5,'["restaurant"]','burgershot',NULL,0,2.5,NULL,NULL,NULL,NULL,NULL,1,'prop_cooker_03'),
    ('bar_table','{"x":-960.0,"y":-3000.0,"z":13.95,"w":0.0}',2.5,'["bar"]','bartender',NULL,0,2.5,NULL,NULL,NULL,NULL,NULL,1,'prop_bar_fridge_01'),
    ('illegal_table','{"x":-955.0,"y":-2995.0,"z":13.95,"w":0.0}',2.5,'["illegal"]','criminal',NULL,0,2.5,NULL,NULL,NULL,NULL,NULL,1,'prop_tool_bench02');
