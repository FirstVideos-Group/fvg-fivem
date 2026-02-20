-- ╔══════════════════════════════════════════════╗
-- ║          fvg-idcard :: server                ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    -- Engedélyek tábla
    exports['fvg-database']:RegisterMigration('fvg_licenses', [[
        CREATE TABLE IF NOT EXISTS `fvg_licenses` (
            `id`          INT          NOT NULL AUTO_INCREMENT,
            `player_id`   INT          NOT NULL,
            `license_type`VARCHAR(40)  NOT NULL,
            `categories`  VARCHAR(100)          DEFAULT NULL,
            `issued_by`   VARCHAR(60)           DEFAULT 'Los Santos Önkormányzat',
            `issued_at`   TIMESTAMP    NOT NULL  DEFAULT CURRENT_TIMESTAMP,
            `expires_at`  TIMESTAMP             DEFAULT NULL,
            `suspended`   TINYINT(1)   NOT NULL  DEFAULT 0,
            PRIMARY KEY (`id`),
            KEY `idx_player`  (`player_id`),
            KEY `idx_type`    (`license_type`),
            CONSTRAINT `fk_lic_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Körözések tábla
    exports['fvg-database']:RegisterMigration('fvg_wanted', [[
        CREATE TABLE IF NOT EXISTS `fvg_wanted` (
            `player_id`   INT          NOT NULL,
            `level`       TINYINT      NOT NULL DEFAULT 0,
            `reason`      TEXT                  DEFAULT NULL,
            `issued_by`   VARCHAR(60)           DEFAULT NULL,
            `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`),
            CONSTRAINT `fk_wanted_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Szerver cache ─────────────────────────────────────────────
-- [src] = { licenses = { [type] = { ... } }, wanted = { level, reason } }
local playerCards = {}

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local licenses = exports['fvg-database']:Query(
        'SELECT * FROM `fvg_licenses` WHERE `player_id` = ?',
        { player.id }
    )
    local wanted = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_wanted` WHERE `player_id` = ?',
        { player.id }
    )

    playerCards[src] = {
        player_id = player.id,
        licenses  = {},
        wanted    = wanted and { level = wanted.level, reason = wanted.reason } or { level = 0, reason = nil },
    }

    if licenses then
        for _, row in ipairs(licenses) do
            playerCards[src].licenses[row.license_type] = {
                issued_by  = row.issued_by,
                issued_at  = tostring(row.issued_at),
                expires_at = row.expires_at and tostring(row.expires_at) or nil,
                suspended  = row.suspended == 1,
                categories = row.categories,
            }
        end
    end

    -- Alapértelmezett engedélyek (ha még nincs)
    for _, defaultLic in ipairs(Config.DefaultLicenses) do
        if not playerCards[src].licenses[defaultLic] then
            exports['fvg-idcard']:AddLicense(src, defaultLic, nil, Config.IssuedBy)
        end
    end

    TriggerClientEvent('fvg-idcard:client:SyncCard', src, playerCards[src])
end)

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    playerCards[src] = nil
end)

-- ── Segédfüggvények ───────────────────────────────────────────
local function GetCardData(src)
    if not playerCards[src] then return nil end
    local identity = exports['fvg-identity']:GetPlayerIdentity(src)
    return {
        identity  = identity,
        licenses  = playerCards[src].licenses,
        wanted    = playerCards[src].wanted,
        player_id = playerCards[src].player_id,
    }
end

local function HasAdminPerm(src)
    if not Config.UseAdminIntegration then return false end
    return exports['fvg-admin']:IsAdmin(src)
end

-- ═══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('GetPlayerCard', function(src)
    return GetCardData(tonumber(src))
end)

exports('HasLicense', function(src, licenseType)
    local s = tonumber(src)
    if not playerCards[s] then return false end
    local lic = playerCards[s].licenses[licenseType]
    if not lic then return false end
    if lic.suspended then return false end
    if lic.expires_at then
        -- egyszerű string összehasonlítás – YYYY-MM-DD HH:MM:SS formátum
        if lic.expires_at < os.date('%Y-%m-%d %H:%M:%S') then return false end
    end
    return true
end)

exports('AddLicense', function(src, licenseType, categories, issuedBy, expiresAt)
    local s      = tonumber(src)
    local player = exports['fvg-playercore']:GetPlayer(s)
    if not player or not playerCards[s] then return false end

    issuedBy = issuedBy or Config.IssuedBy
    local catStr = type(categories) == 'table' and table.concat(categories, ',') or categories

    -- DB insert vagy update
    local existing = exports['fvg-database']:QuerySingle(
        'SELECT `id` FROM `fvg_licenses` WHERE `player_id`=? AND `license_type`=?',
        { player.id, licenseType }
    )
    if existing then
        exports['fvg-database']:Execute(
            'UPDATE `fvg_licenses` SET `categories`=?,`issued_by`=?,`expires_at`=?,`suspended`=0,`issued_at`=NOW() WHERE `id`=?',
            { catStr, issuedBy, expiresAt or nil, existing.id }
        )
    else
        exports['fvg-database']:Insert(
            'INSERT INTO `fvg_licenses` (`player_id`,`license_type`,`categories`,`issued_by`,`expires_at`) VALUES (?,?,?,?,?)',
            { player.id, licenseType, catStr, issuedBy, expiresAt or nil }
        )
    end

    -- Cache frissítés
    playerCards[s].licenses[licenseType] = {
        issued_by  = issuedBy,
        issued_at  = os.date('%Y-%m-%d %H:%M:%S'),
        expires_at = expiresAt,
        suspended  = false,
        categories = catStr,
    }

    TriggerClientEvent('fvg-idcard:client:SyncCard', s, playerCards[s])
    TriggerEvent('fvg-idcard:server:LicenseAdded', s, licenseType)
    return true
end)

exports('RemoveLicense', function(src, licenseType)
    local s      = tonumber(src)
    local player = exports['fvg-playercore']:GetPlayer(s)
    if not player or not playerCards[s] then return false end

    exports['fvg-database']:Execute(
        'DELETE FROM `fvg_licenses` WHERE `player_id`=? AND `license_type`=?',
        { player.id, licenseType }
    )
    playerCards[s].licenses[licenseType] = nil
    TriggerClientEvent('fvg-idcard:client:SyncCard', s, playerCards[s])
    TriggerEvent('fvg-idcard:server:LicenseRemoved', s, licenseType)
    return true
end)

exports('GetAllLicenses', function(src)
    local s = tonumber(src)
    if not playerCards[s] then return {} end
    return playerCards[s].licenses
end)

exports('IsWanted', function(src)
    local s = tonumber(src)
    if not playerCards[s] then return false end
    return (playerCards[s].wanted.level or 0) > 0
end)

exports('GetWantedLevel', function(src)
    local s = tonumber(src)
    if not playerCards[s] then return 0 end
    return playerCards[s].wanted.level or 0
end)

exports('SetWanted', function(src, level, reason, issuedBy)
    local s      = tonumber(src)
    local player = exports['fvg-playercore']:GetPlayer(s)
    if not player or not playerCards[s] then return false end

    level  = math.max(0, math.min(5, tonumber(level) or 0))
    reason = reason or nil

    -- DB upsert
    exports['fvg-database']:Execute(
        [[INSERT INTO `fvg_wanted` (`player_id`,`level`,`reason`,`issued_by`)
          VALUES (?,?,?,?)
          ON DUPLICATE KEY UPDATE `level`=VALUES(`level`),`reason`=VALUES(`reason`),`issued_by`=VALUES(`issued_by`)]],
        { player.id, level, reason, issuedBy or 'System' }
    )

    playerCards[s].wanted = { level = level, reason = reason }
    TriggerClientEvent('fvg-idcard:client:SyncCard', s, playerCards[s])
    TriggerEvent('fvg-idcard:server:WantedChanged', s, level, reason)

    -- fvg-notify értesítés a játékosnak
    if level > 0 then
        TriggerClientEvent('fvg-notify:client:Notify', s, {
            type    = 'error',
            message = 'Körözés ellenőd ellen! (' .. Config.WantedLevels[level + 1].label .. ')'
        })
    end
    return true
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Saját igazolvány megnyitása
RegisterNetEvent('fvg-idcard:server:OpenOwnCard', function()
    local src  = source
    local data = GetCardData(src)
    if not data then return end
    TriggerClientEvent('fvg-idcard:client:OpenCard', src, {
        data     = data,
        owner    = true,
        cardTypes= Config.CardTypes,
        wantedLvls=Config.WantedLevels,
    })
end)

-- Igazolvány felmutatás másiknak
RegisterNetEvent('fvg-idcard:server:ShowCardTo', function(targetSrc)
    local src  = source
    local data = GetCardData(src)
    if not data then return end

    TriggerClientEvent('fvg-idcard:client:OpenCard', targetSrc, {
        data      = data,
        owner     = false,
        shownBy   = GetPlayerName(src),
        cardTypes = Config.CardTypes,
        wantedLvls= Config.WantedLevels,
    })

    -- Küldőt is értesítjük
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = 'success',
        message = 'Igazolvány felmutatva: ' .. GetPlayerName(targetSrc)
    })

    TriggerEvent('fvg-idcard:server:CardShown', src, targetSrc)
end)

-- Legközelebbi játékosnak mutatás
RegisterNetEvent('fvg-idcard:server:ShowToNearest', function()
    local src    = source
    local data   = GetCardData(src)
    if not data then return end

    TriggerClientEvent('fvg-idcard:client:FindNearestAndShow', src, Config.ShowDistance)
end)

-- Igazolvány ellenőrzés (rendőrség)
RegisterNetEvent('fvg-idcard:server:CheckPlayerCard', function(targetSrc)
    local src = source
    if not HasAdminPerm(src) then
        -- Normál játékosok is ellenőrizhetnek (pl. rendőr job)
        local job = exports['fvg-playercore']:GetPlayer(src)
        if not job then return end
    end

    local targetData = GetCardData(targetSrc)
    if not targetData then return end

    TriggerClientEvent('fvg-idcard:client:OpenCard', src, {
        data      = targetData,
        owner     = false,
        isCheck   = true,
        shownBy   = GetPlayerName(targetSrc),
        cardTypes = Config.CardTypes,
        wantedLvls= Config.WantedLevels,
    })
end)

-- Engedély felfüggesztés (rendőrség/admin)
RegisterNetEvent('fvg-idcard:server:SuspendLicense', function(targetSrc, licenseType, state)
    local src = source
    if not HasAdminPerm(src) then return end

    local player = exports['fvg-playercore']:GetPlayer(targetSrc)
    if not player or not playerCards[targetSrc] then return end
    if not playerCards[targetSrc].licenses[licenseType] then return end

    exports['fvg-database']:Execute(
        'UPDATE `fvg_licenses` SET `suspended`=? WHERE `player_id`=? AND `license_type`=?',
        { state and 1 or 0, player.id, licenseType }
    )
    playerCards[targetSrc].licenses[licenseType].suspended = state
    TriggerClientEvent('fvg-idcard:client:SyncCard', targetSrc, playerCards[targetSrc])

    local msg = state and 'Engedély felfüggesztve.' or 'Engedély visszaállítva.'
    TriggerClientEvent('fvg-notify:client:Notify', targetSrc, { type = state and 'error' or 'success', message = msg })
    TriggerClientEvent('fvg-notify:client:Notify', src, { type = 'success', message = msg })
end)

-- Körözés beállítás (admin)
RegisterNetEvent('fvg-idcard:server:SetWantedFromClient', function(targetSrc, level, reason)
    local src = source
    if not HasAdminPerm(src) then return end
    exports['fvg-idcard']:SetWanted(targetSrc, level, reason, GetPlayerName(src))
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = 'success',
        message = 'Körözés beállítva: ' .. GetPlayerName(targetSrc)
    })
end)