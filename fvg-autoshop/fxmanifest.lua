fx_version 'cerulean'
game 'gta5'

name        'fvg-autoshop'
description 'FVG Autoshop System - FirstVideos Group'
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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

server_exports {
    'GetOwnedVehicles',
    'GetVehicleByPlate',
    'BuyVehicle',
    'SellVehicle',
    'GetInstalments',
    'PayInstalment',
    'IsVehicleOwned',
    'GetAllDealerships',
}

exports {
    'OpenDealership',
    'GetLocalOwnedVehicles',
    'IsTestDriving',
}