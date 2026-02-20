fx_version 'cerulean'
game 'gta5'

name        'fvg-database'
description 'FVG Database Core - FirstVideos Group'
version     '1.0.0'
author      'FirstVideos Group'

server_script '@oxmysql/lib/MySQL.lua'

server_scripts {
    'config.lua',
    'server/logger.lua',
    'server/migrations.lua',
    'server/core.lua',
}

server_exports {
    -- Alap lekérdezők
    'Query',
    'QuerySingle',
    'Execute',
    'Insert',
    'Update',
    'Scalar',
    -- Tranzakció
    'Transaction',
    -- Játékos helpers
    'GetPlayer',
    'GetOrCreatePlayer',
    'SavePlayer',
    -- Tábla helpers
    'RegisterMigration',
    'TableExists',
}