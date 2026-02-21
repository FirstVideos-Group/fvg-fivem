RegisterModule('fines', {
    checkAccess = function(off)
        return Config.HasPermission(off.grade, 'can_fine')
    end
})

-- DB migráció
CreateThread(function()
    Wait(300)
    exports['fvg-database']:RegisterMigration('fvg_fines', [[
        CREATE TABLE IF NOT EXISTS `fvg_fines` (
            `id`          INT         NOT NULL AUTO_INCREMENT,
            `identifier`  VARCHAR(60) NOT NULL,
            `officer_id`  INT         NOT NULL,
            `type_id`     VARCHAR(50) NOT NULL,
            `label`       VARCHAR(100)NOT NULL,
            `amount`      INT         NOT NULL DEFAULT 0,
            `jail_time`   INT         NOT NULL DEFAULT 0,
            `points`      TINYINT     NOT NULL DEFAULT 0,
            `note`        TEXT                 DEFAULT NULL,
            `paid`        TINYINT     NOT NULL DEFAULT 0,
            `created_at`  DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_ident`  (`identifier`),
            KEY `idx_officer`(`officer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- Exportok
exports('GetFinesByIdentifier', function(identifier)
    return exports['fvg-database']:Query(
        [[SELECT f.*, p.firstname, p.lastname
          FROM `fvg_fines` f
          LEFT JOIN `fvg_players` p
              ON p.identifier = f.identifier
          WHERE f.identifier = ?
          ORDER BY f.created_at DESC
          LIMIT 50]],
        { identifier }
    ) or {}
end)

exports('AddFine', function(officerSrc, targetIdentifier, typeId, amount, jailTime, note)
    local off = exports['fvg-police']:GetOfficer(tonumber(officerSrc))
    if not off then return false end

    local fineType = nil
    for _, ft in ipairs(Config.FineTypes) do
        if ft.id == typeId then fineType = ft; break end
    end
    if not fineType then return false end

    local finalAmount  = tonumber(amount)  or fineType.min
    local finalJail    = tonumber(jailTime)or fineType.jail

    exports['fvg-database']:Insert(
        [[INSERT INTO `fvg_fines`
          (`identifier`,`officer_id`,`type_id`,`label`,`amount`,`jail_time`,`points`,`note`)
          VALUES (?,?,?,?,?,?,?,?)]],
        { targetIdentifier, off.id, typeId, fineType.label,
          finalAmount, finalJail, fineType.points, note or '' }
    )

    -- Fizetés levonás
    if finalAmount > 0 then
        -- Megkeresük a játékost online-e
        for src, _ in pairs(exports['fvg-playercore']:GetOnlinePlayers() or {}) do
            local p = exports['fvg-playercore']:GetPlayer(src)
            if p and p.identifier == targetIdentifier then
                exports['fvg-banking']:RemoveBalance(src, finalAmount, 'checking',
                    'Bírság: ' .. fineType.label, 'fine')
                TriggerClientEvent('fvg-notify:client:Notify', src, {
                    type='error',
                    title='🚔 Bírság',
                    message=fineType.label .. ' – $' .. finalAmount,
                    duration=8000,
                })
                break
            end
        end
    end

    TriggerEvent('fvg-police:server:FineIssued', officerSrc, targetIdentifier, typeId, finalAmount, finalJail)
    return true
end)

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'fines' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end
    if not Config.HasPermission(off.grade, 'can_fine') then return end

    if action == 'issue' then
        local ok = exports['fvg-police']:AddFine(
            src,
            payload.identifier,
            payload.typeId,
            payload.amount,
            payload.jailTime,
            payload.note
        )
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type = ok and 'success' or 'error',
            message = ok and 'Bírság kiállítva.' or 'Hiba a bírság kiállításánál.',
        })
        if ok then
            TriggerClientEvent('fvg-police:client:FineIssued', src, payload)
        end

    elseif action == 'getFines' then
        local fines = exports['fvg-police']:GetFinesByIdentifier(payload.identifier)
        TriggerClientEvent('fvg-police:client:FinesResult', src, fines)
    end
end)