fx_version 'cerulean'
game 'gta5'

name        'fvg-banking'
description 'FVG Banking System - FirstVideos Group'
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
    'GetBalance',
    'AddBalance',
    'RemoveBalance',
    'Transfer',
    'GetTransactions',
    'HasSufficientFunds',
    'GetAccountByIdentifier',
    'CreateTransaction',
}

exports {
    'GetLocalBalance',
    'OpenBank',
}