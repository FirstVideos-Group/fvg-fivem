-- ╔══════════════════════════════════════════════╗
-- ║          fvg-admin :: server                 ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció – ban tábla ─────────────────────────────────────
CreateThread(function()
    Wait(200)
    exports['fvg-database']:RegisterMigration('fvg_bans', [[
        CREATE TABLE IF NOT EXISTS `fvg_bans` (
            `id`          INT          NOT NULL AUTO_INCREMENT,
            `identifier`  VARCHAR(60)  NOT NULL,
            `name`        VARCHAR(60)  NOT NULL DEFAULT 'Unknown',
            `reason`      TEXT         NOT NULL,
            `banned_by`   VARCHAR(60)  NOT NULL,
            `expires_at`  DATETIME              DEFAULT NULL,
            `permanent`   TINYINT(1)   NOT NULL DEFAULT 0,
            `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Segédfüggvények ───────────────────────────────────────────

local function GetAdminRole(src)
    if IsPlayerAceAllowed(src, Config.Permissions.superadmin) then return 'superadmin' end
    if IsPlayerAceAllowed(src, Config.Permissions.admin)      then return 'admin'      end
    if IsPlayerAceAllowed(src, Config.Permissions.moderator)  then return 'moderator'  end
    return nil
end

local function HasPerm(src, action)
    local role = GetAdminRole(src)
    if not role then return false end
    local allowed = Config.FunctionPerms[action] or {}
    for _, r in ipairs(allowed) do
        if r == role then return true end
    end
    return false
end

local function GetIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, 'license:', 1, true) then return id end
    end
    return nil
end

local function AdminLog(admin, action, target, detail)
    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_logs` (`resource`, `event`, `player_id`, `data`) VALUES (?, ?, ?, ?)',
        { 'fvg-admin', action,
          target and exports['fvg-playercore']:GetPlayer(target) and exports['fvg-playercore']:GetPlayer(target).id or nil,
          json.encode({ admin = GetPlayerName(admin), detail = detail })
        }
    )
end

local function Notify(src, msg, ntype)
    if not Config.NotifyIntegration then return end
    TriggerClientEvent('fvg-notify:client:Notify', src, { type = ntype or 'info', message = msg })
end

-- ── Ban csatlakozáskor ellenőrzés ─────────────────────────────
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src        = source
    deferrals.defer()
    Wait(0)

    local identifier = GetIdentifier(src)
    if not identifier then deferrals.done() return end

    local ban = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_bans` WHERE `identifier` = ? AND (`permanent` = 1 OR `expires_at` > NOW()) ORDER BY `created_at` DESC LIMIT 1',
        { identifier }
    )

    if ban then
        local expiry = ban.permanent == 1 and 'Örökre' or tostring(ban.expires_at)
        deferrals.done(string.format(
            'Ki vagy tiltva a szerverről.\nOk: %s\nLejár: %s',
            ban.reason, expiry
        ))
        return
    end

    deferrals.done()
end)

-- ── Admin menü megnyitás ─────────────────────────────────────
RegisterNetEvent('fvg-admin:server:OpenMenu', function()
    local src  = source
    local role = GetAdminRole(src)
    if not role then
        Notify(src, 'Nincs jogosultságod az admin menühöz.', 'error')
        return
    end

    local playerList = {}
    for _, pid in ipairs(GetPlayers()) do
        local pidNum = tonumber(pid)
        local p      = exports['fvg-playercore']:GetPlayer(pidNum)
        local ping   = GetPlayerPing(pidNum)
        table.insert(playerList, {
            source    = pidNum,
            name      = GetPlayerName(pidNum) or 'Unknown',
            firstname = p and p.firstname or '',
            lastname  = p and p.lastname  or '',
            identifier= p and p.identifier or '',
            ping      = ping,
            role      = GetAdminRole(pidNum) or 'player',
            job       = p and p.metadata and p.metadata.job or 'unemployed',
            stress    = exports['fvg-stress']:GetPlayerStress(pidNum),
            needs     = exports['fvg-needs']:GetPlayerNeeds(pidNum),
        })
    end

    TriggerClientEvent('fvg-admin:client:OpenMenu', src, {
        role        = role,
        playerList  = playerList,
        weathers    = Config.Weathers,
        vehicles    = Config.VehicleCategories,
        banDurations= Config.BanDurations,
        permissions = Config.FunctionPerms,
        jobs        = Config.Jobs,
    })
end)

-- ── Online játékosok frissítése ───────────────────────────────
RegisterNetEvent('fvg-admin:server:RefreshPlayers', function()
    local src  = source
    if not GetAdminRole(src) then return end

    local playerList = {}
    for _, pid in ipairs(GetPlayers()) do
        local pidNum = tonumber(pid)
        local p      = exports['fvg-playercore']:GetPlayer(pidNum)
        table.insert(playerList, {
            source    = pidNum,
            name      = GetPlayerName(pidNum) or 'Unknown',
            firstname = p and p.firstname or '',
            lastname  = p and p.lastname  or '',
            identifier= p and p.identifier or '',
            ping      = GetPlayerPing(pidNum),
            role      = GetAdminRole(pidNum) or 'player',
            job       = p and p.metadata and p.metadata.job or 'unemployed',
            stress    = exports['fvg-stress']:GetPlayerStress(pidNum),
            needs     = exports['fvg-needs']:GetPlayerNeeds(pidNum),
        })
    end

    TriggerClientEvent('fvg-admin:client:UpdatePlayers', src, playerList)
end)

-- ══════════════════════════════════════════════════════════════
--  JÁTÉKOS AKCIÓK
-- ══════════════════════════════════════════════════════════════

-- Kick
RegisterNetEvent('fvg-admin:server:KickPlayer', function(targetSrc, reason)
    local src = source
    if not HasPerm(src, 'kick') then return end
    reason = reason or 'Admin által kirúgva'
    DropPlayer(targetSrc, reason)
    AdminLog(src, 'kick', targetSrc, reason)
    Notify(src, GetPlayerName(targetSrc) .. ' kirúgva: ' .. reason, 'success')
end)

-- Ban
RegisterNetEvent('fvg-admin:server:BanPlayer', function(targetSrc, reason, minutes)
    local src = source
    if not HasPerm(src, 'ban') then return end

    local identifier = GetIdentifier(targetSrc)
    local name       = GetPlayerName(targetSrc) or 'Unknown'
    local adminId    = GetIdentifier(src) or 'console'
    local permanent  = (minutes == -1)
    local expiresAt  = nil

    if not permanent then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + minutes * 60)
    end

    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_bans` (`identifier`, `name`, `reason`, `banned_by`, `expires_at`, `permanent`) VALUES (?, ?, ?, ?, ?, ?)',
        { identifier, name, reason, adminId, expiresAt, permanent and 1 or 0 }
    )

    DropPlayer(targetSrc, 'Ki vagy tiltva. Ok: ' .. reason)
    AdminLog(src, 'ban', targetSrc, { reason = reason, minutes = minutes })
    Notify(src, name .. ' kitiltva.', 'success')
end)

-- Unban
RegisterNetEvent('fvg-admin:server:UnbanPlayer', function(identifier)
    local src = source
    if not HasPerm(src, 'ban') then return end
    exports['fvg-database']:Execute(
        'DELETE FROM `fvg_bans` WHERE `identifier` = ?',
        { identifier }
    )
    AdminLog(src, 'unban', nil, identifier)
    Notify(src, 'Ban feloldva: ' .. identifier, 'success')
end)

-- Revive
RegisterNetEvent('fvg-admin:server:RevivePlayer', function(targetSrc)
    local src = source
    if not HasPerm(src, 'revive') then return end
    TriggerClientEvent('fvg-admin:client:Revive', targetSrc)
    AdminLog(src, 'revive', targetSrc, nil)
end)

-- Freeze
RegisterNetEvent('fvg-admin:server:FreezePlayer', function(targetSrc, state)
    local src = source
    if not HasPerm(src, 'freeze') then return end
    TriggerClientEvent('fvg-admin:client:SetFreeze', targetSrc, state)
    AdminLog(src, state and 'freeze' or 'unfreeze', targetSrc, nil)
end)

-- Teleport to player
RegisterNetEvent('fvg-admin:server:TeleportTo', function(targetSrc)
    local src = source
    if not HasPerm(src, 'teleport') then return end
    TriggerClientEvent('fvg-admin:client:TeleportToPlayer', src, targetSrc)
end)

-- Teleport player to me
RegisterNetEvent('fvg-admin:server:TeleportToMe', function(targetSrc)
    local src = source
    if not HasPerm(src, 'teleport') then return end
    TriggerClientEvent('fvg-admin:client:TeleportToMe', targetSrc, src)
end)

-- Spectate
RegisterNetEvent('fvg-admin:server:SpectatePlayer', function(targetSrc)
    local src = source
    if not HasPerm(src, 'spectate') then return end
    TriggerClientEvent('fvg-admin:client:StartSpectate', src, targetSrc)
end)

-- Godmode
RegisterNetEvent('fvg-admin:server:SetGodmode', function(targetSrc, state)
    local src = source
    if not HasPerm(src, 'godmode') then return end
    TriggerClientEvent('fvg-admin:client:SetGodmode', targetSrc, state)
    AdminLog(src, state and 'godmode_on' or 'godmode_off', targetSrc, nil)
end)

-- Needs beállítás
RegisterNetEvent('fvg-admin:server:SetNeeds', function(targetSrc, food, water)
    local src = source
    if not HasPerm(src, 'setneeds') then return end
    exports['fvg-needs']:SetPlayerNeed(targetSrc, 'food',  food)
    exports['fvg-needs']:SetPlayerNeed(targetSrc, 'water', water)
    AdminLog(src, 'set_needs', targetSrc, { food = food, water = water })
    Notify(src, 'Needs beállítva.', 'success')
end)

-- Stressz beállítás
RegisterNetEvent('fvg-admin:server:SetStress', function(targetSrc, value)
    local src = source
    if not HasPerm(src, 'setstress') then return end
    exports['fvg-stress']:SetPlayerStress(targetSrc, value)
    AdminLog(src, 'set_stress', targetSrc, { stress = value })
    Notify(src, 'Stressz beállítva: ' .. value .. '%', 'success')
end)

-- Karakter adatok módosítása
RegisterNetEvent('fvg-admin:server:SetPlayerInfo', function(targetSrc, data)
    local src = source
    if not HasPerm(src, 'admin') then return end
    local p = exports['fvg-playercore']:GetPlayer(targetSrc)
    if not p then return end
    if data.firstname then p.firstname = data.firstname end
    if data.lastname  then p.lastname  = data.lastname  end
    exports['fvg-database']:SavePlayer(targetSrc, data)
    Notify(src, 'Játékos adatai frissítve.', 'success')
    Notify(targetSrc, 'Admin módosította az adataidat.', 'warning')
end)

-- ── Job váltás ────────────────────────────────────────────────
-- SetPlayerData-t használ (playercore export) – metadata.job frissítés + kliens sync
RegisterNetEvent('fvg-admin:server:SetJob', function(targetSrc, job)
    local src = source
    if not HasPerm(src, 'setjob') then
        Notify(src, 'Nincs jogosultságod job váltáshoz.', 'error')
        return
    end

    -- Job validáció – csak Config.Jobs-ban szereplő job engedélyezett
    local valid = false
    local jobLabel = job
    for _, j in ipairs(Config.Jobs) do
        if j.job == job then
            valid    = true
            jobLabel = j.label
            break
        end
    end

    if not valid then
        Notify(src, 'Érvénytelen job: ' .. tostring(job), 'error')
        return
    end

    local p = exports['fvg-playercore']:GetPlayer(targetSrc)
    if not p then
        Notify(src, 'Játékos nem található.', 'error')
        return
    end

    -- metadata.job frissítés + kliens szinkron a SetPlayerData exporton át
    exports['fvg-playercore']:SetPlayerData(targetSrc, 'job', job)
    -- Mentés DB-be
    exports['fvg-playercore']:SavePlayerNow(targetSrc)

    AdminLog(src, 'set_job', targetSrc, { job = job })
    Notify(src, (p.firstname .. ' ' .. p.lastname) .. ' munkája módosítva: ' .. jobLabel, 'success')
    Notify(targetSrc, 'Az admin megváltoztatta a munkádat: ' .. jobLabel, 'info')
end)

-- ══════════════════════════════════════════════════════════════
--  JÁRMŰ AKCIÓK
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-admin:server:SpawnVehicle', function(model)
    local src = source
    if not HasPerm(src, 'spawnveh') then return end
    TriggerClientEvent('fvg-admin:client:SpawnVehicle', src, model)
    AdminLog(src, 'spawn_vehicle', nil, model)
end)

RegisterNetEvent('fvg-admin:server:DeleteVehicle', function()
    local src = source
    if not HasPerm(src, 'deleteveh') then return end
    TriggerClientEvent('fvg-admin:client:DeleteVehicle', src)
end)

RegisterNetEvent('fvg-admin:server:FixVehicle', function()
    local src = source
    if not HasPerm(src, 'spawnveh') then return end
    TriggerClientEvent('fvg-admin:client:FixVehicle', src)
end)

-- ══════════════════════════════════════════════════════════════
--  SZERVER AKCIÓK
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-admin:server:SetWeather', function(weather)
    local src = source
    if not HasPerm(src, 'setweather') then return end
    TriggerClientEvent('fvg-admin:client:SetWeather', -1, weather)
    AdminLog(src, 'set_weather', nil, weather)
end)

RegisterNetEvent('fvg-admin:server:SetTime', function(hour, minute)
    local src = source
    if not HasPerm(src, 'settime') then return end
    TriggerClientEvent('fvg-admin:client:SetTime', -1, hour, minute)
    AdminLog(src, 'set_time', nil, { hour = hour, minute = minute })
end)

RegisterNetEvent('fvg-admin:server:Announce', function(message)
    local src = source
    if not HasPerm(src, 'announce') then return end
    local fullMsg = Config.AnnouncePrefix .. message
    TriggerClientEvent('fvg-notify:client:Notify', -1, { type = 'warning', message = fullMsg, duration = 8000 })
    AdminLog(src, 'announce', nil, message)
end)

RegisterNetEvent('fvg-admin:server:SetNoclip', function(state)
    local src = source
    if not HasPerm(src, 'noclip') then return end
    TriggerClientEvent('fvg-admin:client:SetNoclip', src, state)
end)

RegisterNetEvent('fvg-admin:server:GetBanList', function()
    local src = source
    if not HasPerm(src, 'ban') then return end
    local bans = exports['fvg-database']:Query(
        'SELECT * FROM `fvg_bans` WHERE `permanent` = 1 OR `expires_at` > NOW() ORDER BY `created_at` DESC LIMIT 100',
        {}
    )
    TriggerClientEvent('fvg-admin:client:ReceiveBanList', src, bans or {})
end)
