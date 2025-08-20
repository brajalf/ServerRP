fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Player inventory system providing a variety of features for storing and managing items'
version '2.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua',
    'shared/**/*.lua',
}

client_scripts {
    'client/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/ox_compat.lua',
    'server/commands.lua',
    'server/functions.lua',
    'server/main.lua',
    'server/origen_compat.lua',
    'server/ox_bridge.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/main.css',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/*.*',
    'html/sounds/*.*',
    'html/ammo_images/*.png',
    'html/images/*.png',
}

dependency 'qb-weapons'
