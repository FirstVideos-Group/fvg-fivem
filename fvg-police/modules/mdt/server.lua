RegisterModule('mdt', {
    checkAccess = function(off)
        return Config.HasPermission(off.grade, 'can_mdt')
    end
})

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'mdt' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end
    if not Config.HasPermission(off.grade, 'can_mdt') then return end

    if action == 'search' then
        local query   = payload.query or ''
        local results = {}

        -- Játékos keresés
        local players = exports['fvg-database']:Query(
            [[SELECT p.id, p.firstname, p.lastname, p.identifier, p.dob, p.phone
              FROM `fvg_players` p
              WHERE CONCAT(p.firstname,' ',p.lastname) LIKE ?
              LIMIT 20]],
            { '%' .. query .. '%' }
        )

        if players then
            for _, p in ipairs(players) do
                -- Bírságok
                local fines = exports['fvg-police']:GetFinesByIdentifier(p.identifier)
                -- Börtön
                local prison = exports['fvg-police']:GetPrisonTime(p.identifier)

                table.insert(results, {
                    id         = p.id,
                    firstname  = p.firstname,
                    lastname   = p.lastname,
                    identifier = p.identifier,
                    dob        = p.dob,
                    phone      = p.phone,
                    fines      = fines or {},
                    prisonTime = prison,
                })
            end
        end

        TriggerClientEvent('fvg-police:client:MDTResults', src, results)

    elseif action == 'addNote' then
        -- Megjegyzés hozzáadás játékoshoz
        local identifier = payload.identifier
        local note       = payload.note
        if not identifier or not note then return end
        exports['fvg-database']:Execute(
            [[INSERT INTO `fvg_mdt_notes` (`officer_id`,`identifier`,`note`)
              VALUES (?,?,?)
              ON DUPLICATE KEY UPDATE `note`=CONCAT(`note`,'\n',VALUES(`note`))]],
            { off.id, identifier, note }
        )
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='success', message='Megjegyzés hozzáadva.'
        })
    end
end)

-- MDT notes tábla migrálás
CreateThread(function()
    Wait(300)
    exports['fvg-database']:RegisterMigration('fvg_mdt_notes', [[
        CREATE TABLE IF NOT EXISTS `fvg_mdt_notes` (
            `id`         INT         NOT NULL AUTO_INCREMENT,
            `officer_id` INT         NOT NULL,
            `identifier` VARCHAR(60) NOT NULL,
            `note`       TEXT        NOT NULL,
            `created_at` DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_ident` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)