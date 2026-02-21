fx_version 'cerulean'
game 'gta5'

name        'fvg-traffipax'
author      'FirstVideos Group'
version     '1.0.0'
description 'Automatikus traffipax rendszer – sebességmérés, büntets, BOLO integráció'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'docs/index.html',
}
