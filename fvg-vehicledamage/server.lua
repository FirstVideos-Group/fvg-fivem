-- ╔══════════════════════════════════════════════╗
-- ║      fvg-vehicledamage :: server             ║
-- ╚══════════════════════════════════════════════╝

local damageStates = {}
-- [playerId] = { engineHealth, bodyHealth, lastUpdate }

-- ── Állapot szinkron fogadása ────────────────────────────────
RegisterServerEvent('fvg-vehicledamage:server:SyncState', function(engineHp, bodyHp)
    local src = source
    damageStates[src] = {
        engineHealth = engineHp,
        bodyHealth   = bodyHp,
        lastUpdate   = os.time()
    }
end)

-- ── Javítás naplózása ────────────────────────────────────────
RegisterServerEvent('fvg-vehicledamage:server:LogRepair', function(part)
    local src  = source
    local name = GetPlayerName(src) or 'Unknown'
    print(string.format('[fvg-vehicledamage] %s (ID: %d) javítás: %s', name, src, part))
    damageStates[src] = {
        engineHealth = 1000.0,
        bodyHealth   = 1000.0,
        lastUpdate   = os.time()
    }
end)

-- ── Szerver oldali kényszeres javítás ─────────────────────────
-- Pl. fvg-mechanic script hívja
RegisterServerEvent('fvg-vehicledamage:server:ForceRepair', function(targetId, part, silent)
    local src = source
    -- Jogosultság ellenőrzés helye (later: fvg-admin)
    TriggerClientEvent('fvg-vehicledamage:client:RepairVehicle', targetId, part or 'full', silent or false)
end)

-- ── Játékos kilép ────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    damageStates[source] = nil
end)

-- ── Szerver export: lekérdezés ───────────────────────────────
exports('GetPlayerVehicleDamage', function(playerId)
    return damageStates[playerId] or {
        engineHealth = 1000.0,
        bodyHealth   = 1000.0,
        lastUpdate   = 0
    }
end)