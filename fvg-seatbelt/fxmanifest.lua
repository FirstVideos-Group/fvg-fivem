fx_version 'cerulean'
game 'gta5'

name        'fvg-seatbelt'
description 'FVG Seatbelt System - FirstVideos Group'
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
    'IsBelted',
    'SetBelted',
    'GetBeltState'
}