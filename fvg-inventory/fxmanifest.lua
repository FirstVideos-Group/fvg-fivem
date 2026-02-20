fx_version 'cerulean'
game 'gta5'

name        'fvg-inventory'
description 'FVG Inventory System - FirstVideos Group'
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
    'GetInventory',
    'GetItemCount',
    'AddItem',
    'RemoveItem',
    'HasItem',
    'ClearInventory',
    'GetStash',
    'AddToStash',
    'RemoveFromStash',
}

exports {
    'GetLocalInventory',
    'GetLocalItemCount',
    'HasLocalItem',
}