-- ╔══════════════════════════════════════════════╗
-- ║       fvg-playercore :: server               ║
-- ╚══════════════════════════════════════════════╝

-- ── Szerver oldali játékos objektum cache ─────────────────────
-- [serverId] = { id, identifier, name, firstname, lastname,
--                metadata, loaded, source }
local Players = {}

-- ── Segédfüggvények ──────────────────────────────────────────

local function GetIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, Config.PlayerIdentifierType or 'license', 1, true) then
            return id
        end
    end
    -- Fallback: bármilyen license
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, 'license:', 1, true) then
            return id
        end
    end
    return nil
end

local function DeepMerge(base, override)
    local result = {}
    for k, v in pairs(base) do result[k] = v end
    for k, v in pairs(override or {}) do result[k] = v end
    return result
end

local function Notify(src, msg, ntype)
    if not Config.NotifyIntegration then return end
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'info',
        message = msg
    })
end

-- ── Exportok ─────────────────────────────────────────────────

-- Szerver oldali játékos objektum lekérdezése
exports('GetPlayer', function(src)
    return Players[tonumber(src)]
end)

-- Összes betöltött játékos
exports('GetAllPlayers', function()
    local result = {}
    for _, p in pairs(Players) do
        if p.loaded then
            table.insert(result, p)
        end
    end
    return result
end)

-- Játékos keresése identifier alapján
exports('GetPlayerByIdentifier', function(identifier)
    for _, p in pairs(Players) do
        if p.identifier == identifier then
            return p
        end
    end
    return nil
end)

-- Egy mező beállítása a játékos metaadataiban
exports('SetPlayerData', function(src, key, value)
    local p = Players[tonumber(src)]
    if not p then return false end
    p.metadata[key] = value
    -- Kliens szinkronizálás
    TriggerClientEvent('fvg-playercore:client:SyncData', src, key, value)
    return true
end)

-- Egy mező lekérdezése
exports('GetPlayerData', function(src, key)
    local p = Players[tonumber(src)]
    if not p then return nil end
    if key then
        return p.metadata[key]
    end
    return p
end)

-- Betöltött-e a játékos
exports('IsPlayerLoaded', function(src)
    local p = Players[tonumber(src)]
    return p ~= nil and p.loaded == true
end)

-- Játékos kirúgása
exports('KickPlayer', function(src, reason)
    DropPlayer(tonumber(src), reason or 'Kirúgtak a szerverről.')
end)

-- Összes játékos mentése (pl. szerver leállításkor)
exports('SaveAllPlayers', function()
    local count = 0
    for src, p in pairs(Players) do
        if p.loaded then
            exports['fvg-database']:SavePlayer(src, {
                firstname = p.firstname,
                lastname  = p.lastname,
                metadata  = p.metadata
            })
            count = count + 1
        end
    end
    print(string.format('[fvg-playercore] %d játékos mentve.', count))
    return count
end)

-- ══════════════════════════════════════════════════════════════
--  CSATLAKOZÁS KEZELÉS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source

    deferrals.defer()
    Wait(0)

    -- ── 1. Azonosító ellenőrzés ────────────────────────────
    deferrals.update(Config.ConnectMessages.checking)

    local identifier = GetIdentifier(src)
    if not identifier then
        deferrals.done(Config.KickReasons.no_identifier)
        return
    end

    -- ── 2. Adatbázis lekérdezés / létrehozás ──────────────
    deferrals.update(Config.ConnectMessages.loading)
    Wait(0)

    local ok, result = pcall(function()
        return exports['fvg-database']:GetOrCreatePlayer(src, {
            metadata = Config.DefaultMetadata
        })
    end)

    if not ok or not result then
        deferrals.done(Config.KickReasons.db_error)
        print(string.format('[fvg-playercore] DB hiba csatlakozáskor: %s (src: %d)', tostring(result), src))
        return
    end

    -- ── 3. Átmeneti belépési adat tárolása ─────────────────
    -- A végleges Players bejegyzés csak spawn után jön létre
    Players[src] = {
        id          = result.id,
        identifier  = identifier,
        name        = name,
        firstname   = result.firstname or '',
        lastname    = result.lastname  or '',
        sex         = result.sex       or 0,
        dob         = result.dob       or '',
        phone       = result.phone,
        metadata    = DeepMerge(Config.DefaultMetadata, result.metadata or {}),
        loaded      = false,
        source      = src,
        isNew       = (result.created_at == result.last_seen)
    }

    deferrals.done()
end)

-- ══════════════════════════════════════════════════════════════
--  SPAWN KEZELÉS
-- ══════════════════════════════════════════════════════════════

-- Kliens jelzi hogy készen áll a spawn adatok fogadására
RegisterNetEvent('fvg-playercore:server:RequestSpawn', function()
    local src = source
    local p   = Players[src]

    if not p then
        DropPlayer(src, Config.KickReasons.db_error)
        return
    end

    -- Spawn pozíció: utolsó mentett vagy alapértelmezett
    local spawnPos = Config.DefaultSpawn
    if p.metadata.lastPos then
        spawnPos = p.metadata.lastPos
    end

    -- Kliens adatok küldése
    TriggerClientEvent('fvg-playercore:client:OnPlayerLoaded', src, {
        id        = p.id,
        firstname = p.firstname,
        lastname  = p.lastname,
        sex       = p.sex,
        dob       = p.dob,
        phone     = p.phone,
        metadata  = p.metadata,
        isNew     = p.isNew,
        spawnPos  = spawnPos,
        model     = Config.DefaultModel,
    })
end)

-- Kliens megerősíti a sikeres spawnot
RegisterNetEvent('fvg-playercore:server:PlayerReady', function()
    local src = source
    local p   = Players[src]
    if not p then return end

    p.loaded = true

    -- Üdvözlő értesítés
    local msg = p.isNew
        and Config.Locale.welcome_new
        or  Config.Locale.welcome_back

    Wait(1000)
    Notify(src, msg, p.isNew and 'success' or 'info')

    -- Más scriptek értesítése
    TriggerEvent('fvg-playercore:server:PlayerLoaded', src, p)
    print(string.format('[fvg-playercore] Játékos betöltve: %s %s (ID: %d, src: %d)',
        p.firstname, p.lastname, p.id, src))
end)

-- ══════════════════════════════════════════════════════════════
--  POZÍCIÓ MENTÉS
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-playercore:server:SavePosition', function(pos)
    local src = source
    local p   = Players[src]
    if not p then return end
    if type(pos) ~= 'table' then return end

    p.metadata.lastPos = {
        x       = pos.x,
        y       = pos.y,
        z       = pos.z,
        heading = pos.heading or 0.0
    }
end)

-- ══════════════════════════════════════════════════════════════
--  KILÉPÉS KEZELÉS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local src = source
    local p   = Players[src]
    if not p then return end

    -- Mentés ha már be volt töltve
    if p.loaded then
        exports['fvg-database']:SavePlayer(src, {
            firstname = p.firstname,
            lastname  = p.lastname,
            sex       = p.sex,
            dob       = p.dob,
            phone     = p.phone,
            metadata  = p.metadata
        })

        print(string.format('[fvg-playercore] Játékos kilépett és mentve: %s (src: %d) – %s',
            p.name, src, reason))
    end

    -- Más scriptek értesítése
    TriggerEvent('fvg-playercore:server:PlayerUnloaded', src, p)

    Players[src] = nil
end)

-- ══════════════════════════════════════════════════════════════
--  AUTOMATIKUS MENTÉS
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval)
        local count = 0
        for src, p in pairs(Players) do
            if p.loaded then
                exports['fvg-database']:SavePlayer(src, {
                    firstname = p.firstname,
                    lastname  = p.lastname,
                    metadata  = p.metadata
                })
                count = count + 1
            end
        end
        if count > 0 then
            print(string.format('[fvg-playercore] Auto-mentés: %d játékos.', count))
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  SZERVER LEÁLLÁS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    exports['fvg-playercore']:SaveAllPlayers()
end)