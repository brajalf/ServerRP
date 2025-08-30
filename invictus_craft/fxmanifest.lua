fx_version 'cerulean'
game 'gta5'

name 'invictus_craft'
author 'Invictus Technology TIC S.A.S.'
version '1.0.0'
description 'Sistema de crafteo por zonas para QBCore + ox_inventory (Invictus Craft)'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
  '@ox_lib/init.lua',      -- opcional (para notificaciones), quítalo si no usas ox_lib
  'config.lua',
  'locales.lua',
  'shared/bridge.lua'
}

client_scripts {
  'client/target.lua',
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua', -- opcional (no requerido, usamos KVP para persistencia)
  'server/main.lua'
}

files {
  'html/index.html',
  'html/style.css',
  'html/script.js'
}

dependencies {
  'qb-core',
  'ox_inventory'
  -- 'qb-target' u 'ox_target' (elige uno en config)
}
