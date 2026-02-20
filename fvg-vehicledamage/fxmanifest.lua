fx_version 'cerulean'
game 'gta5'

name        'fvg-vehicledamage'
description 'FVG Vehicle Damage System - FirstVideos Group'
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
    'GetDamageState',
    'RepairVehicle',
    'RepairEngine',
    'RepairBody',
    'RepairTires',
    'SetEngineHealth',
    'SetBodyHealth'
}

server_exports {
    'GetPlayerVehicleDamage'
}
