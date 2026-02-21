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
    'modules/*/server.lua',
}

client_scripts {
    'client.lua',
    'modules/*/client.lua',
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