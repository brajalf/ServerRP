fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-inventory (compat for ox)'
description 'Compatibility layer: exposes qb-inventory API using ox_inventory backend'
version '1.0.0'

shared_scripts {
    '@qb-core/shared.lua',
    'shared/normalize.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
