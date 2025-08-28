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
    blueprint_item VARCHAR(50) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS crafting_zones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    model VARCHAR(100) NOT NULL,
    coords LONGTEXT NOT NULL,
    distance FLOAT DEFAULT 2.5,
    allowed_categories LONGTEXT,
    required_job VARCHAR(50) DEFAULT NULL,
    required_items LONGTEXT DEFAULT NULL
);
