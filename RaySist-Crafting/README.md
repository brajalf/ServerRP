# RaySist-Crafting

# Support https://discord.gg/pNvGMgQ2vZ


![craft](https://i.ibb.co/KzXCBqfV/Craft-removebg.png)
A modern crafting system for FiveM QBCore framework.

## Features

- Modern and responsive NUI interface
- Crafting of weapons, ammunition, tools, and medical items
- Blueprint system for advanced items
- Skill-based crafting with progression
- Configurable crafting tables with qb-target integration
- Multiple crafting locations support
- Category-based item organization
- Optional job-restricted recipes

## Installation

1. Ensure you have the latest version of QBCore framework installed
2. Place the `RaySist-Crafting` folder in your server's resources directory
3. Add `ensure RaySist-Crafting` to your server.cfg
4. Configure the `config.lua` file to your liking
5. Restart your server

## Dependencies

- QBCore Framework
- qb-target
- qb-skillz (optional, for skill-based crafting)
- oxmysql

## Configuration

The script is highly configurable through the `config.lua` file:

- Add or modify crafting tables and their locations
- Create custom crafting categories
- Define crafting recipes with ingredients, time, and blueprint requirements
- Enable/disable skill-based crafting
- Restrict recipes to specific jobs with the optional `job` field

## Usage

Players can interact with crafting tables using qb-target. The crafting menu allows them to:

1. Browse items by category
2. View required materials and crafting time
3. Craft items if they have the required materials
4. Track their crafting skill progress

## Exports

The resource exposes several server-side exports:

- `GetCraftingData(jobName)` → table with `zones`, `categories` and `recipes` filtered for the job.
- `CreateCategory(source, category)` → `id`
- `RenameCategory(source, data)` → `bool`
- `SaveRecipe(source, recipe)` → `bool`
- `DeleteRecipe(source, name)` → `bool`
- `AddZone(source, zone)` → `id`
- `DeleteZone(source, id)` → `bool`

Each function requires admin permissions on `source` when modifying data.

## Credits

Created by RaySist
