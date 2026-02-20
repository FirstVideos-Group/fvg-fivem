fx_version 'cerulean'
game 'gta5'

name        'fvg-vehiclehud'
description 'FVG Vehicle HUD System - FirstVideos Group'
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
    'modules/*.lua',
    'client/client.lua'
}

exports {
    'SetModuleValue',
    'ToggleModule',
    'GetModuleState',
    'RegisterModule'
}