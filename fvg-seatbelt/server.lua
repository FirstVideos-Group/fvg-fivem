-- ╔══════════════════════════════════════════════╗
-- ║        fvg-seatbelt :: server                ║
-- ╚══════════════════════════════════════════════╝

-- Szinkronizálja a többi játékosnak az öv állapotát
RegisterServerEvent('fvg-seatbelt:server:SyncBelt', function(state)
    local src = source
    TriggerClientEvent('fvg-seatbelt:client:SyncBelt', -1, src, state)
end)

-- Kiesés naplózása (opcionális, bővíthető adatbázis loghoz)
RegisterServerEvent('fvg-seatbelt:server:LogEject', function(serverId, speed)
    local src  = source
    local name = GetPlayerName(src) or 'Unknown'
    print(string.format('[fvg-seatbelt] %s (ID: %d) kiesett a járműből | Sebesség: %d km/h', name, src, speed))
end)

-- Export: szerver oldali lekérdezés (jövőbeli fvg-admin használatra)
local beltStates = {}

AddEventHandler('playerDropped', function()
    beltStates[source] = nil
end)

RegisterServerEvent('fvg-seatbelt:server:SyncBelt', function(state)
    local src = source
    beltStates[src] = state
    TriggerClientEvent('fvg-seatbelt:client:SyncBelt', -1, src, state)
end)

exports('GetPlayerBeltState', function(playerId)
    return beltStates[playerId] or false
end)