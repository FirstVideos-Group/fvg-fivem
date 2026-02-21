RegisterModule('prison', {
    checkAccess = function(off)
        return Config.HasPermission(off.grade, 'can_prison')
    end
})

-- DB migráció
CreateThread(function()
    Wait(300)
    exports['fvg-database']:RegisterMigration('fvg_prison', [[
        CREATE TABLE IF NOT EXISTS `fvg_prison` (
            `id`             INT         NOT NULL AUTO_INCREMENT,
            `identifier`     VARCHAR(60) NOT NULL,
            `officer_id`     INT                  DEFAULT NULL,
            `time_minutes`   INT         NOT NULL DEFAULT 0,
            `time_served`    INT         NOT NULL DEFAULT 0,
            `cs_minutes`     INT         NOT NULL DEFAULT 0,
            `reason`         VARCHAR(200)         DEFAULT NULL,
            `released_at`    DATETIME            DEFAULT NULL,
            `status`         ENUM('active','released','escaped') NOT NULL DEFAULT 'active',
            `created_at`     DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_ident` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- Cache: [identifier] = { id, timeLeft, csMinutes }
local prisonersCache = {}

-- Export: lekérés
exports('GetPrisonTime', function(identifier)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_prison` WHERE `identifier`=? AND `status`=? ORDER BY `created_at` DESC LIMIT 1',
        { identifier, 'active' }
    )
    if not row then return nil end
    return {
        id          = row.id,
        timeMinutes = row.time_minutes,
        timeServed  = row.time_served,
        csMinutes   = row.cs_minutes,
        reason      = row.reason,
        timeLeft    = row.time_minutes - row.time_served - math.floor(row.cs_minutes * Config.Prison.csTimeReduction),
    }
end)

-- Export: börtönbe küldés
exports('SendToPrison', function(officerSrc, targetIdentifier, timeMinutes, reason)
    local off = officerSrc and exports['fvg-police']:GetOfficer(tonumber(officerSrc))

    local id = exports['fvg-database']:Insert(
        [[INSERT INTO `fvg_prison`
          (`identifier`,`officer_id`,`time_minutes`,`reason`)
          VALUES (?,?,?,?)]],
        { targetIdentifier, off and off.id or nil, timeMinutes, reason or '' }
    )

    prisonersCache[targetIdentifier] = {
        id        = id,
        timeLeft  = timeMinutes,
        csMinutes = 0,
    }

    -- Ha online van a célszemély
    local players = GetPlayers()
    for _, s in ipairs(players) do
        local p = exports['fvg-playercore']:GetPlayer(tonumber(s))
        if p and p.identifier == targetIdentifier then
            TriggerClientEvent('fvg-police:client:SendToPrison', tonumber(s), {
                timeMinutes = timeMinutes,
                reason      = reason,
            })
            break
        end
    end

    TriggerEvent('fvg-police:server:PlayerImprisoned', targetIdentifier, timeMinutes, reason)
    return true
end)

-- Export: szabadon engedés
exports('ReleasePrison', function(targetIdentifier)
    exports['fvg-database']:Execute(
        'UPDATE `fvg_prison` SET `status`=?, `released_at`=NOW() WHERE `identifier`=? AND `status`=?',
        { 'released', targetIdentifier, 'active' }
    )
    prisonersCache[targetIdentifier] = nil

    local players = GetPlayers()
    for _, s in ipairs(players) do
        local p = exports['fvg-playercore']:GetPlayer(tonumber(s))
        if p and p.identifier == targetIdentifier then
            TriggerClientEvent('fvg-police:client:ReleasedFromPrison', tonumber(s))
            break
        end
    end
    return true
end)

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'prison' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end

    if action == 'send' then
        if not Config.HasPermission(off.grade, 'can_prison') then return end
        exports['fvg-police']:SendToPrison(src, payload.identifier, payload.time, payload.reason)
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='success', message=payload.time .. ' perces börtönbüntetés kiállítva.', title='⛓️'
        })

    elseif action == 'release' then
        if not Config.HasPermission(off.grade, 'can_prison') then return end
        exports['fvg-police']:ReleasePrison(payload.identifier)
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='success', message='Fogoly szabadon engedve.'
        })

    elseif action == 'csProgress' then
        -- Közmunka előrehaladás
        local prison = exports['fvg-police']:GetPrisonTime(payload.identifier)
        if not prison then return end
        exports['fvg-database']:Execute(
            'UPDATE `fvg_prison` SET `cs_minutes`=`cs_minutes`+1 WHERE `id`=?',
            { prison.id }
        )
        local newLeft = prison.timeLeft - math.floor(Config.Prison.csTimeReduction)
        if newLeft <= 0 then
            exports['fvg-police']:ReleasePrison(payload.identifier)
        else
            TriggerClientEvent('fvg-police:client:PrisonTick', src, { timeLeft = newLeft })
        end
    end
end)