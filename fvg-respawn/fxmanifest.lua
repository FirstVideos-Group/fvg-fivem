fx_version 'cerulean'
game 'gta5'

name        'fvg-respawn'
author      'FirstVideos Group'
version     '1.0.0'
description 'Halálkezelés, respawn és karakter modell megőrzés'

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
}
