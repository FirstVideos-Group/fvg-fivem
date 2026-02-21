-- ╔══════════════════════════════════════════════╗
-- ║       fvg-playercore :: server               ║
-- ╚══════════════════════════════════════════════╝

-- ── Szerver oldali játékos objektum cache ────────────────────
-- [serverId] = { id, identifier, name, firstname, lastname,
--                metadata, loaded, source }
local Players = {}
local _pending = {}

-- ── Segédfüggvények ──────────────────────────────────────────

local function GetIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, Config.PlayerIdentifierType or 'license', 1, true) then
            return id
        end
    end
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

-- ── Exportok ───────────────────────────────────────────────

exports('GetPlayer', function(src)
    return Players[tonumber(src)]
end)

exports('GetAllPlayers', function()
    local result = {}
    for _, p in pairs(Players) do
        if p.loaded then
            table.insert(result, p)
        end
    end
    return result
end)

exports('GetPlayerByIdentifier', function(identifier)
    for _, p in pairs(Players) do
        if p.identifier == identifier then
            return p
        end
    end
    return nil
end)

-- FIX: SetPlayerData most TriggerEvent-et is küld,
-- így más resource-ok (pl. fvg-police) reaglni tudnak a változásra
exports('SetPlayerData', function(src, key, value)
    src = tonumber(src)
    local p = Players[src]
    if not p then return false end
    p.metadata[key] = value
    -- Kliens szinkronizálás
    TriggerClientEvent('fvg-playercore:client:SyncData', src, key, value)
    -- Szerver oldali event: más resource-ok is reaglhatnak
    TriggerEvent('fvg-playercore:server:PlayerDataChanged', src, key, value)
    return true
end)

exports('GetPlayerData', function(src, key)
    local p = Players[tonumber(src)]
    if not p then return nil end
    if key then
        return p.metadata[key]
    end
    return p
end)

exports('IsPlayerLoaded', function(src)
    local p = Players[tonumber(src)]
    return p ~= nil and p.loaded == true
end)

exports('KickPlayer', function(src, reason)
    DropPlayer(tonumber(src), reason or 'Kirúgtk a szerverről.')
end)

exports('SavePlayerNow', function(src)
    local p = Players[tonumber(src)]
    if not p or not p.loaded then return false end
    exports['fvg-database']:SavePlayer(tonumber(src), {
        firstname = p.firstname,
        lastname  = p.lastname,
        sex       = p.sex,
        dob       = p.dob,
        phone     = p.phone,
        metadata  = p.metadata
    })
    return true
end)

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

-- ═══════════════════════════════════════════════════════════════
--  CSATLAKOZÁS KEZELÉS
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source

    deferrals.defer()
    Wait(0)

    deferrals.update(Config.ConnectMessages.checking)

    local identifier = GetIdentifier(src)
    if not identifier then
        deferrals.done(Config.KickReasons.no_identifier)
        return
    end

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

    _pending[identifier] = {
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
        isNew       = result.isNew or false,
    }

    deferrals.done()
end)

-- ═══════════════════════════════════════════════════════════════
--  SPAWN KEZELÉS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-playercore:server:RequestSpawn', function()
    local src        = source
    local identifier = GetIdentifier(src)

    if not identifier then
        DropPlayer(src, Config.KickReasons.db_error)
        return
    end

    local p = _pending[identifier]
    if not p then
        p = Players[src]
    end

    if not p then
        print(string.format('[fvg-playercore] RequestSpawn: nincs pending adat! identifier=%s src=%d', tostring(identifier), src))
        DropPlayer(src, Config.KickReasons.db_error)
        return
    end

    p.source = src
    Players[src] = p
    _pending[identifier] = nil

    local spawnPos = Config.DefaultSpawn
    if p.metadata and p.metadata.lastPos then
        spawnPos = p.metadata.lastPos
    end

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

RegisterNetEvent('fvg-playercore:server:PlayerReady', function()
    local src = source
    local p   = Players[src]
    if not p then return end

    p.loaded = true

    local msg = p.isNew
        and Config.Locale.welcome_new
        or  Config.Locale.welcome_back

    Wait(1000)
    Notify(src, msg, p.isNew and 'success' or 'info')

    TriggerEvent('fvg-playercore:server:PlayerLoaded', src, p)
    print(string.format('[fvg-playercore] Játékos betöltve: %s %s (ID: %d, src: %d)',
        p.firstname, p.lastname, p.id, src))
end)

-- ═══════════════════════════════════════════════════════════════
--  POZÍCIÓ MENTÉS
-- ═══════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════
--  KILÉPÉS KEZELÉS
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local src        = source
    local identifier = GetIdentifier(src)

    if identifier then _pending[identifier] = nil end

    local p = Players[src]
    if not p then return end

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

    TriggerEvent('fvg-playercore:server:PlayerUnloaded', src, p)

    Players[src] = nil
end)

-- ═══════════════════════════════════════════════════════════════
--  AUTOMATIKUS MENTÉS
-- ═══════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════
--  SZERVER LEÁLLÁS
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    exports['fvg-playercore']:SaveAllPlayers()
end)
