fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-jobcreator'
author 'INVICTUS TECHNOLOGY TIC S.A.S.'
version '1.2.0'
description 'Jobs Creator con Dashboard NUI, zonas y acciones QBCore'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/style.css',
  'web/app.js',
  'web/logo.png',
}

dependencies {
  'qb-core',
  'qb-menu',      -- opcional (atajo F6)
  'qb-input'      -- opcional (atajos)
}

shared_scripts {
  '@qb-core/shared/locale.lua',
  'locales/en.lua',
  'locales/es.lua',
  'config.lua',
  'shared/sh_utils.lua',
  'shared/sh_inventory.lua'
}

client_scripts {
  'client/actions.lua',
  'client/zones.lua',
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db.lua',
  'server/jobsfile.lua',
  'server/main.lua',
}
