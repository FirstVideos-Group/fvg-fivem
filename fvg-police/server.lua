-- ╔══════════════════════════════════════════════╗
-- ║        fvg-police :: server (core)           ║
-- ╚══════════════════════════════════════════════╝

-- ── Cache ─────────────────────────────────────────────────────
-- [src] = { id, identifier, firstname, lastname, grade, rankName,
--           duty, unit, callsign, hireDate, totalSalary }
local officers      = {}
local onDutyCount   = 0
local moduleList    = {}

-- ── Modul betöltés (automatikus) ─────────────────────────────
-- A modules/*/server.lua-k betöltésekor regisztrálják magukat
function RegisterModule(id, def)
    if not Config.Modules[id] or not Config.Modules[id].enabled then return end
    moduleList[id] = def
    print(('[fvg-police] Modul betöltve: %s'):format(id))
end

-- ── DB migráció ───────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    exports['fvg-database']:RegisterMigration('fvg_officers', [[
        CREATE TABLE IF NOT EXISTS `fvg_officers` (
            `id`           INT         NOT NULL AUTO_INCREMENT,
            `player_id`    INT         NOT NULL,
            `identifier`   VARCHAR(60) NOT NULL,
            `grade`        TINYINT     NOT NULL DEFAULT 0,
            `callsign`     VARCHAR(10)          DEFAULT NULL,
            `hire_date`    DATE        NOT NULL DEFAULT (CURRENT_DATE),
            `total_salary` BIGINT      NOT NULL DEFAULT 0,
            `notes`        TEXT                 DEFAULT NULL,
            `status`       ENUM('active','suspended','fired') NOT NULL DEFAULT 'active',
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_player` (`player_id`),
            CONSTRAINT `fk_off_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports['fvg-database']:RegisterMigration('fvg_officer_logs', [[
        CREATE TABLE IF NOT EXISTS `fvg_officer_logs` (
            `id`         INT         NOT NULL AUTO_INCREMENT,
            `officer_id` INT         NOT NULL,
            `type`       VARCHAR(30) NOT NULL,
            `detail`     TEXT                 DEFAULT NULL,
            `created_at` DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_officer` (`officer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Segédfüggvények ───────────────────────────────────────────
local function Notify(src, msg, ntype, title)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type = ntype or 'info', title = title, message = msg,
    })
end

local function Log(officerId, logType, detail)
    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_officer_logs` (`officer_id`,`type`,`detail`) VALUES (?,?,?)',
        { officerId, logType, detail or '' }
    )
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_officers` WHERE `player_id`=? AND `status`=?',
        { player.id, 'active' }
    )
    if row then
        local rank = Config.GetRank(row.grade)
        officers[src] = {
            id           = row.id,
            identifier   = row.identifier,
            playerId     = player.id,
            firstname    = player.firstname,
            lastname     = player.lastname,
            grade        = row.grade,
            rankName     = rank and rank.name or 'recruit',
            rankLabel    = rank and rank.label or 'Újonc',
            callsign     = row.callsign,
            hireDate     = row.hire_date,
            totalSalary  = row.total_salary,
            duty         = false,
            unit         = nil,
        }
    end
end)

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    if officers[src] then
        -- Duty log
        if officers[src].duty then
            Log(officers[src].id, 'duty_end', 'disconnect')
        end
        officers[src] = nil
        onDutyCount   = math.max(0, onDutyCount - 1)
        TriggerClientEvent('fvg-police:client:OfficerLeft', -1, src)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  CORE EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('GetOfficer', function(src)
    return officers[tonumber(src)]
end)

exports('GetAllOfficers', function()
    return officers
end)

exports('GetOnDutyOfficers', function()
    local result = {}
    for src, off in pairs(officers) do
        if off.duty then
            result[src] = off
        end
    end
    return result
end)

exports('IsOnDuty', function(src)
    local off = officers[tonumber(src)]
    return off and off.duty or false
end)

exports('GetOfficerUnit', function(src)
    local off = officers[tonumber(src)]
    return off and off.unit or nil
end)

exports('SetOfficerRank', function(src, grade)
    src = tonumber(src)
    local off = officers[src]
    if not off then return false end
    local rank = Config.GetRank(grade)
    if not rank then return false end

    off.grade     = grade
    off.rankName  = rank.name
    off.rankLabel = rank.label

    exports['fvg-database']:Execute(
        'UPDATE `fvg_officers` SET `grade`=? WHERE `id`=?',
        { grade, off.id }
    )
    Log(off.id, 'rank_change', 'grade → ' .. grade)
    TriggerClientEvent('fvg-police:client:RankUpdate', src, { grade=grade, rankLabel=rank.label })
    Notify(src, 'Rang módosítva: ' .. rank.label, 'success')
    return true
end)

exports('AddSalary', function(src, amount)
    src = tonumber(src)
    local off = officers[src]
    if not off then return false end
    off.totalSalary = off.totalSalary + amount
    exports['fvg-database']:Execute(
        'UPDATE `fvg_officers` SET `total_salary`=`total_salary`+? WHERE `id`=?',
        { amount, off.id }
    )
    return true
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS – DUTY
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-police:server:ToggleDuty', function()
    local src = source
    local off = officers[src]
    if not off then Notify(src, 'Nem vagy rendőr.', 'error'); return end

    off.duty = not off.duty
    if off.duty then
        onDutyCount = onDutyCount + 1
        Log(off.id, 'duty_start', os.date('%Y-%m-%d %H:%M:%S'))
        Notify(src, 'Szolgálatba léptél. Üdv, ' .. off.rankLabel .. ' ' .. off.lastname .. '!', 'success', '🚔')
    else
        onDutyCount = math.max(0, onDutyCount - 1)
        -- Egység elhagyás
        if off.unit then
            TriggerEvent('fvg-police:server:LeaveUnit', src)
        end
        Log(off.id, 'duty_end', os.date('%Y-%m-%d %H:%M:%S'))
        Notify(src, 'Szolgálatból kiléptél.', 'info')
    end

    TriggerClientEvent('fvg-police:client:DutyChanged', src, off.duty)
    TriggerClientEvent('fvg-police:client:OfficerUpdate', -1, src, {
        duty     = off.duty,
        rankLabel= off.rankLabel,
        callsign = off.callsign,
        firstname= off.firstname,
        lastname = off.lastname,
    })
end)

-- ── Menü megnyitás kérés ──────────────────────────────────────
RegisterNetEvent('fvg-police:server:RequestMenu', function(stationId)
    local src = source
    local off = officers[src]
    if not off then Notify(src, 'Nem vagy rendőr.', 'error'); return end

    local rank      = Config.GetRank(off.grade)
    local modulesCfg= {}
    for id, mod in pairs(Config.Modules) do
        if mod.enabled then
            table.insert(modulesCfg, {
                id    = id,
                label = mod.label,
                icon  = mod.icon,
                -- Modul-specifikus jogosultság ellenőrzés
                allowed = (moduleList[id] and moduleList[id].checkAccess)
                    and moduleList[id].checkAccess(off)
                    or true,
            })
        end
    end
    -- Sorrendezés a Config.Modules megjelenési sorrendje szerint
    table.sort(modulesCfg, function(a, b) return a.id < b.id end)

    TriggerClientEvent('fvg-police:client:OpenMenu', src, {
        officer   = {
            grade     = off.grade,
            rankLabel = off.rankLabel,
            rankName  = off.rankName,
            callsign  = off.callsign,
            firstname = off.firstname,
            lastname  = off.lastname,
            duty      = off.duty,
            unit      = off.unit,
            hireDate  = off.hireDate,
        },
        modules   = modulesCfg,
        stationId = stationId,
        ranks     = Config.Ranks,
        onDuty    = onDutyCount,
        maxOfficers    = Config.MaxOfficers,
        vehicles       = Config.Vehicles,
        classLabels    = Config.VehicleClassLabels,
        fineTypes      = Config.FineTypes,
        fineCategories = Config.FineCategories,
        csLocations    = Config.Locations.community_service,
        maxPrison      = Config.Prison.maxTime,

    })
end)

-- ── Pánik gomb ─────────────────────────────────────────────────
RegisterNetEvent('fvg-police:server:Panic', function(coords)
    local src = source
    local off = officers[src]
    if not off or not off.duty then return end

    local msg = ('🚨 PÁNIK: %s %s [%s] – Koordináta: %.1f, %.1f, %.1f'):format(
        off.firstname, off.lastname, off.callsign or '??',
        coords.x, coords.y, coords.z
    )
    -- Értesítés összes on-duty rendőrnek
    for s, o in pairs(officers) do
        if o.duty and s ~= src then
            Notify(s, msg, 'error', '🚨 Pánik')
        end
    end
    Log(off.id, 'panic', ('%.1f,%.1f,%.1f'):format(coords.x, coords.y, coords.z))
end)

-- ── Fizetés ciklus ─────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.SalaryInterval * 1000)
        for src, off in pairs(officers) do
            if off.duty then
                local rank   = Config.GetRank(off.grade)
                local salary = rank and rank.salary or 0
                if salary > 0 then
                    if Config.SalaryMethod == 'bank' then
                        exports['fvg-banking']:AddBalance(src, salary, 'checking',
                            'Rendőrségi fizetés – ' .. off.rankLabel, 'salary')
                    else
                        exports['fvg-playercore']:AddCash(src, salary)
                    end
                    exports['fvg-police']:AddSalary(src, salary)
                    Notify(src, 'Fizetés érkezett: $' .. salary, 'success', '💰')
                end
            end
        end
    end
end)

-- ── Admin parancsok ────────────────────────────────────────────
RegisterCommand('police_hire', function(src, args)
    if not exports['fvg-admin']:IsAdmin(src) then return end
    local targetSrc = tonumber(args[1])
    local grade     = tonumber(args[2]) or 0
    if not targetSrc then return end

    local player = exports['fvg-playercore']:GetPlayer(targetSrc)
    if not player then Notify(src, 'Játékos nem found.', 'error'); return end

    -- Ellenőrzés: már rendőr-e?
    local existing = exports['fvg-database']:QuerySingle(
        'SELECT `id` FROM `fvg_officers` WHERE `player_id`=?', { player.id }
    )
    if existing then
        Notify(src, 'Már rendőr ez a játékos.', 'warning'); return
    end

    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_officers` (`player_id`,`identifier`,`grade`) VALUES (?,?,?)',
        { player.id, player.identifier, grade }
    )

    local rank = Config.GetRank(grade)
    officers[targetSrc] = {
        id        = exports['fvg-database']:QuerySingle('SELECT LAST_INSERT_ID() AS id', {}).id,
        identifier= player.identifier,
        playerId  = player.id,
        firstname = player.firstname,
        lastname  = player.lastname,
        grade     = grade,
        rankName  = rank.name,
        rankLabel = rank.label,
        duty      = false,
        unit      = nil,
    }
    Notify(src, player.firstname .. ' ' .. player.lastname .. ' felvéve rendőrnek (' .. rank.label .. ').', 'success')
    Notify(targetSrc, 'Rendőrnek felvettél! Rang: ' .. rank.label, 'success', '🚔')
end, true)

RegisterCommand('police_setrank', function(src, args)
    if not exports['fvg-admin']:IsAdmin(src) then return end
    local targetSrc = tonumber(args[1])
    local grade     = tonumber(args[2])
    if not targetSrc or not grade then return end
    exports['fvg-police']:SetOfficerRank(targetSrc, grade)
    Notify(src, 'Rang beállítva.', 'success')
end, true)

RegisterCommand('police_fire', function(src, args)
    if not exports['fvg-admin']:IsAdmin(src) then return end
    local targetSrc = tonumber(args[1])
    if not targetSrc then return end
    local off = officers[targetSrc]
    if not off then Notify(src, 'Nem rendőr.', 'error'); return end

    exports['fvg-database']:Execute(
        'UPDATE `fvg_officers` SET `status`=? WHERE `id`=?', { 'fired', off.id }
    )
    officers[targetSrc] = nil
    Notify(targetSrc, 'Eltávolítottak a rendőrségről.', 'error')
    Notify(src, 'Eltávolítva.', 'success')
end, true)