-- ╔══════════════════════════════════════════════╗
-- ║        fvg-database :: core                  ║
-- ╚══════════════════════════════════════════════╝

-- ── Belső cache ───────────────────────────────────────────────
local _playerCache = {}
-- [identifier] = { data={...}, expires=gameTimer }

local function CacheGet(identifier)
    local entry = _playerCache[identifier]
    if not entry then return nil end
    if Config.PlayerCacheTTL > 0 and GetGameTimer() > entry.expires then
        _playerCache[identifier] = nil
        return nil
    end
    return entry.data
end

local function CacheSet(identifier, data)
    if Config.PlayerCacheTTL <= 0 then return end
    _playerCache[identifier] = {
        data    = data,
        expires = GetGameTimer() + Config.PlayerCacheTTL
    }
end

local function CacheInvalidate(identifier)
    _playerCache[identifier] = nil
end

-- Cache tisztítás 60 másodpercenként
CreateThread(function()
    while true do
        Wait(60000)
        local now = GetGameTimer()
        for k, v in pairs(_playerCache) do
            if now > v.expires then
                _playerCache[k] = nil
            end
        end
    end
end)

-- ── Játékos azonosító lekérdezése ─────────────────────────────
local function GetIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, Config.PlayerIdentifierType .. ':', 1, true) then
            return id
        end
    end
    -- Fallback: license
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, 'license:', 1, true) then
            return id
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
--  ALAP LEKÉRDEZŐK
-- ══════════════════════════════════════════════════════════════

-- ── Több sor visszaadása ──────────────────────────────────────
exports('Query', function(query, params)
    local t = GetGameTimer()
    local ok, result = pcall(MySQL.query.await, query, params or {})
    DB_TrackTime(query, t)
    if not ok then
        DB_Log('error', 'Query hiba: %s | %s', tostring(result), query)
        return nil
    end
    return result
end)

-- ── Egy sor visszaadása ───────────────────────────────────────
exports('QuerySingle', function(query, params)
    local t = GetGameTimer()
    local ok, result = pcall(MySQL.single.await, query, params or {})
    DB_TrackTime(query, t)
    if not ok then
        DB_Log('error', 'QuerySingle hiba: %s | %s', tostring(result), query)
        return nil
    end
    return result
end)

-- ── INSERT / UPDATE / DELETE (érintett sorok száma) ───────────
exports('Execute', function(query, params)
    local t = GetGameTimer()
    local ok, result = pcall(MySQL.update.await, query, params or {})
    DB_TrackTime(query, t)
    if not ok then
        DB_Log('error', 'Execute hiba: %s | %s', tostring(result), query)
        return 0
    end
    return result or 0
end)

-- ── INSERT (visszaadja az új sort ID-ját) ─────────────────────
exports('Insert', function(query, params)
    local t = GetGameTimer()
    local ok, result = pcall(MySQL.insert.await, query, params or {})
    DB_TrackTime(query, t)
    if not ok then
        DB_Log('error', 'Insert hiba: %s | %s', tostring(result), query)
        return nil
    end
    return result
end)

-- ── UPDATE (érintett sorok) ───────────────────────────────────
exports('Update', function(query, params)
    local t = GetGameTimer()
    local ok, result = pcall(MySQL.update.await, query, params or {})
    DB_TrackTime(query, t)
    if not ok then
        DB_Log('error', 'Update hiba: %s | %s', tostring(result), query)
        return 0
    end
    return result or 0
end)

-- ── Egyetlen skaláris érték lekérdezése ───────────────────────
exports('Scalar', function(query, params)
    local t = GetGameTimer()
    local ok, result = pcall(MySQL.scalar.await, query, params or {})
    DB_TrackTime(query, t)
    if not ok then
        DB_Log('error', 'Scalar hiba: %s | %s', tostring(result), query)
        return nil
    end
    return result
end)

-- ── Tranzakció ────────────────────────────────────────────────
-- queries = { { query='...', values={} }, ... }
exports('Transaction', function(queries)
    local t  = GetGameTimer()
    local ok, result = pcall(MySQL.transaction.await, queries)
    DB_TrackTime('TRANSACTION(' .. #queries .. ' queries)', t)
    if not ok then
        DB_Log('error', 'Transaction hiba: %s', tostring(result))
        return false
    end
    return result == true
end)

-- ══════════════════════════════════════════════════════════════
--  JÁTÉKOS HELPERS
-- ══════════════════════════════════════════════════════════════

-- ── Játékos adatok lekérdezése ────────────────────────────────
exports('GetPlayer', function(source)
    local identifier = GetIdentifier(source)
    if not identifier then
        DB_Log('warn', 'GetPlayer: nincs azonosító (src: %d)', source)
        return nil
    end

    -- Cache ellenőrzés
    local cached = CacheGet(identifier)
    if cached then return cached end

    local row = MySQL.single.await(
        'SELECT * FROM `fvg_players` WHERE `identifier` = ?',
        { identifier }
    )

    if row and row.metadata then
        local ok, decoded = pcall(json.decode, row.metadata)
        row.metadata = ok and decoded or {}
    end

    if row then
        CacheSet(identifier, row)
    end

    return row
end)

-- ── Játékos lekérdezése, ha nincs – létrehozás ────────────────
exports('GetOrCreatePlayer', function(source, defaultData)
    local identifier = GetIdentifier(source)
    if not identifier then return nil end

    local ok, existing = pcall(MySQL.single.await,
        'SELECT * FROM `fvg_players` WHERE `identifier` = ?',
        { identifier }
    )

    if not ok then
        DB_Log('error', 'GetOrCreatePlayer SELECT hiba: %s', tostring(existing))
        return nil
    end

    if existing then
        if existing.metadata then
            local dok, decoded = pcall(json.decode, existing.metadata)
            existing.metadata = dok and decoded or {}
        end
        existing.isNew = false
        CacheSet(identifier, existing)
        return existing
    end

    -- Új játékos létrehozása
    local data     = defaultData or {}
    local name     = GetPlayerName(source) or 'Unknown'
    local metadata = json.encode(data.metadata or {})
    local now      = os.date('%Y-%m-%d %H:%M:%S')

    local insOk, newId = pcall(MySQL.insert.await,
        'INSERT INTO `fvg_players` (`identifier`, `name`, `firstname`, `lastname`, `sex`, `dob`, `metadata`, `created_at`, `last_seen`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { identifier, name, data.firstname or '', data.lastname or '', data.sex or 0, data.dob or '', metadata, now, now }
    )

    if not insOk or not newId then
        DB_Log('error', 'GetOrCreatePlayer INSERT hiba: %s', tostring(newId))
        return nil
    end

    local selOk, newRow = pcall(MySQL.single.await,
        'SELECT * FROM `fvg_players` WHERE `id` = ?',
        { newId }
    )

    if not selOk or not newRow then
        DB_Log('error', 'GetOrCreatePlayer post-INSERT SELECT hiba: %s', tostring(newRow))
        return nil
    end

    if newRow.metadata then
        local dok, decoded = pcall(json.decode, newRow.metadata)
        newRow.metadata = dok and decoded or {}
    end

    newRow.isNew = true
    CacheSet(identifier, newRow)
    DB_Log('info', 'Új játékos létrehozva: %s (ID: %d)', identifier, newId)
    return newRow
end)

-- ── Játékos mentése ───────────────────────────────────────────
exports('SavePlayer', function(source, data)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    -- Metadata encode ha table
    if type(data.metadata) == 'table' then
        data.metadata = json.encode(data.metadata)
    end

    local updated = MySQL.update.await(
        [[UPDATE `fvg_players` SET
            `name`      = COALESCE(?, `name`),
            `firstname` = COALESCE(?, `firstname`),
            `lastname`  = COALESCE(?, `lastname`),
            `sex`       = COALESCE(?, `sex`),
            `dob`       = COALESCE(?, `dob`),
            `phone`     = COALESCE(?, `phone`),
            `metadata`  = COALESCE(?, `metadata`)
        WHERE `identifier` = ?]],
        {
            data.name      or nil,
            data.firstname or nil,
            data.lastname  or nil,
            data.sex       or nil,
            data.dob       or nil,
            data.phone     or nil,
            data.metadata  or nil,
            identifier
        }
    )

    -- Cache invalidálás
    CacheInvalidate(identifier)
    return (updated or 0) > 0
end)

-- ── Log bejegyzés írása ───────────────────────────────────────
local function WriteLog(resource, event, playerId, data)
    MySQL.insert.await(
        'INSERT INTO `fvg_logs` (`resource`, `event`, `player_id`, `data`) VALUES (?, ?, ?, ?)',
        {
            resource,
            event,
            playerId or nil,
            data and json.encode(data) or nil
        }
    )
end

-- ── Játékos kilépésekor cache tisztítás ───────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    local identifier = GetIdentifier(src)
    if identifier then
        CacheInvalidate(identifier)
    end
end)

DB_Log('info', 'fvg-database core betöltve.')