fx_version 'cerulean'
game 'gta5'

name        'fvg-notify'
description 'FVG Notification System - FirstVideos Group'
version     '1.0.0'
author      'FirstVideos Group'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}

exports {
    'Notify'
}

server_exports {
    'NotifyPlayer',
    'NotifyAll'
}