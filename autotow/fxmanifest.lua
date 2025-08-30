fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'

game 'gta5'

name 'invictus_autotow'
author 'INVICTUS TECHNOLOGY TIC S.A.S.'
description 'Automated Tow Script for FiveM — QBCore compatible. Removes unoccupied vehicles with animated NUI alert, countdown, sound, ACE permissions, and cancel command.'
version '1.0.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/script.js',
  --'html/alert.ogg'
}

shared_scripts {
  'config.lua'
}

client_scripts {
  'client.lua'
}

server_scripts {
  'server.lua'
}
