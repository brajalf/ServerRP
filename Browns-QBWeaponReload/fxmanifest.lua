fx_version 'bodacious'
lua54 'yes'
author 'Brown Development'
description 'QB Reload Weapon'
game 'gta5'
client_scripts {
    'config.lua',
    'code/client.lua'
}

server_scripts {
    'config.lua',
    'code/inventory_bridge.lua',
    'code/server.lua'
}
dependencies {
    'qb-weapons'
}
