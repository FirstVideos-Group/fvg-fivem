fx_version 'cerulean'
game 'gta5'

name        'fvg-playercore'
description 'FVG Player Core - FirstVideos Group'
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

server_exports {
    'GetPlayer',
    'GetAllPlayers',
    'GetPlayerByIdentifier',
    'SetPlayerData',
    'GetPlayerData',
    'IsPlayerLoaded',
    'KickPlayer',
    'SaveAllPlayers',
}

exports {
    'GetLocalPlayerData',
    'IsLoaded',
}