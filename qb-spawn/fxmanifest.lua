fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    'shared/settings.lua',
    'shared/locale.lua',
    'shared/notify.lua'
}

client_scripts {
    'client/no_escrow.lua',
    'client/cl_functions.lua',
    'client/cl_main.lua',
}

server_scripts {
    'server/no_escrow.lua',
    'server/sv_functions.lua',
    'server/sv_main.lua',
}

ui_page 'html/index.html'

files {
    'html/map.js',
    'html/mapStyles/styleAtlas/**/**/*.*',
    'html/index.html',
    'html/main.css',
    'html/script.js',
    'html/img/*.*',
    'html/blips/*.*',
	'html/font/*.ttf',
	'html/font/*.TTF',
}

escrow_ignore {
    'shared/settings.lua',
    'shared/locale.lua',
    'shared/notify.lua',
    'client/no_escrow.lua',
    'client/cl_functions.lua',
    'server/no_escrow.lua',
    'server/sv_functions.lua',
}
dependency '/assetpacks'