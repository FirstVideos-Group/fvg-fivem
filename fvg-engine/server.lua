-- ╔══════════════════════════════════════════════╗
-- ║         fvg-engine :: server                 ║
-- ╚══════════════════════════════════════════════╝

local engineStates = {}

-- ── Szinkron állapot tárolás ─────────────────────────────────
RegisterServerEvent('fvg-engine:server:Sync', function(state)
    local src = source
    engineStates[src] = state
    -- Broadcast: többi játékos is tudja (pl. animáció, hangeffekt)
    TriggerClientEvent('fvg-engine:client:Sync', -1, src, state)
end)

-- ── Játékos kilépésekor töröljük az állapotát ────────────────
AddEventHandler('playerDropped', function()
    engineStates[source] = nil
end)

-- ── Szerver oldali lekérdezés ─────────────────────────────────
-- Pl. fvg-admin, fvg-mechanic használhatja
exports('GetPlayerEngineState', function(playerId)
    return engineStates[playerId] or false
end)

-- ── Szerver oldali motor parancs (pl. fvg-admin tiltja a motort) ─
RegisterServerEvent('fvg-engine:server:ForceEngine', function(targetId, state, silent)
    local src = source
    -- Itt lehet jogosultság ellenőrzést bővíteni
    TriggerClientEvent('fvg-engine:client:SetEngine', targetId, state, silent or false)
end)