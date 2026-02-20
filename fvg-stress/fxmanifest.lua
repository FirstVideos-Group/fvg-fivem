fx_version 'cerulean'
game 'gta5'

name        'fvg-stress'
description 'FVG Stress System - FirstVideos Group'
version     '1.0.0'
author      'FirstVideos Group'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

exports {
    'GetStress',
    'SetStress',
    'AddStress',
    'RemoveStress',
    'GetStressLevel',
    'IsLoaded'
}

server_exports {
    'GetPlayerStress',
    'SetPlayerStress',
    'ModifyPlayerStress'
}