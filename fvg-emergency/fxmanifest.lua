fx_version 'cerulean'
game 'gta5'

name        'fvg-emergency'
author      'FirstVideos Group'
version     '1.0.0'
description 'Közszolgálati hívókód rendszer – Code 1–4, BOLO, Signal 100'

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
