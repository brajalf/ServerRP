fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'

game 'gta5'

name 'invictus_autotow'
author 'INVICTUS TECHNOLOGY TIC S.A.S.'
description 'Automated Tow Script for FiveM — QBCore compatible. Removes unoccupied vehicles with on-screen notifications, ACE permissions, and cancel command.'
version '1.0.0'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'seat_check.lua'
}

client_scripts {
  'client.lua'
}

server_scripts {
  'server.lua'
}

dependency 'ox_lib'
