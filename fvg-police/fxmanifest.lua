fx_version 'cerulean'
game 'gta5'

name        'fvg-police'
description 'FVG Police System – Moduláris Emergency Job – FirstVideos Group'
version     '1.0.0'
author      'FirstVideos Group'

shared_scripts {
    'config.lua',
    'config_ranks.lua',
    'config_vehicles.lua',
    'config_fines.lua',
}

server_scripts {
    'server.lua',
    -- Modulok (explicit – glob nem megbízható FiveM-ben)
    'modules/clothing/server.lua',
    'modules/fines/server.lua',
    'modules/garage/server.lua',
    'modules/mdt/server.lua',
    'modules/prison/server.lua',
    'modules/storage/server.lua',
    'modules/unit/server.lua',
    'modules/weapons/server.lua',
}

client_scripts {
    'client.lua',
    -- Modulok (explicit – glob nem megbízható FiveM-ben)
    'modules/clothing/client.lua',
    'modules/fines/client.lua',
    'modules/garage/client.lua',
    'modules/mdt/client.lua',
    'modules/prison/client.lua',
    'modules/storage/client.lua',
    'modules/unit/client.lua',
    'modules/weapons/client.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

server_exports {
    -- Core
    'GetOfficer',
    'GetAllOfficers',
    'GetOnDutyOfficers',
    'SetOfficerRank',
    'AddSalary',
    -- Modulok exportjai
    'IsOnDuty',
    'GetOfficerUnit',
    'GetFinesByIdentifier',
    'AddFine',
    'GetPrisonTime',
    'SendToPrison',
    'ReleasePrison',
}

exports {
    'IsPlayerOnDuty',
    'GetLocalOfficer',
    'OpenPoliceMenu',
}
