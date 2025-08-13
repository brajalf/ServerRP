-- Desarrollado por HZ - CodigosParaJuegos - FivemSoluciones
fx_version 'cerulean'
game 'gta5'

description 'hz-multitrabajo - Gestión Avanzada de Múltiples Trabajos para QBCore y ESX'
author 'HZ - CodigosParaJuegos - FivemSoluciones'
version '1.0.2'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

lua54 'yes'
dependency '/assetpacks'