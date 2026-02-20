fx_version 'cerulean'
game 'gta5'

name        'fvg-engine'
description 'FVG Engine Control System - FirstVideos Group'
version     '1.0.0'
author      'FirstVideos Group'

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}

exports {
    'IsEngineOn',
    'SetEngineOn',
    'GetEngineState'
}

server_exports {
    'GetPlayerEngineState'
}