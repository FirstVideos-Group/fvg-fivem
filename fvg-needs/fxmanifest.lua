fx_version 'cerulean'
game 'gta5'

name        'fvg-needs'
description 'FVG Needs System - FirstVideos Group'
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
    'GetNeeds',
    'GetNeed',
    'SetNeed',
    'ModifyNeed',
    'IsLoaded'
}

server_exports {
    'GetPlayerNeeds',
    'SetPlayerNeed',
    'ModifyPlayerNeed'
}