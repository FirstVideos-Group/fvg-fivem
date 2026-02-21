-- ╔══════════════════════════════════════════════╗
-- ║       fvg-unemployment :: server             ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    -- JAVÍTÁS: TIMESTAMP DEFAULT NULL → DATETIME (MySQL strict mód kompatibilitás)
    exports['fvg-database']:RegisterMigration('fvg_unemployment', [[
        CREATE TABLE IF NOT EXISTS `fvg_unemployment` (
            `player_id`      INT        NOT NULL,
            `eligible`       TINYINT(1) NOT NULL DEFAULT 1,
            `claims_used`    TINYINT    NOT NULL DEFAULT 0,
            `last_claim`     DATETIME            DEFAULT NULL,
            `tasks_done`     LONGTEXT            DEFAULT NULL,
            `registered_at`  DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`     DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                 ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`),
            CONSTRAINT `fk_unemp_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports['fvg-database']:RegisterMigration('fvg_job_applications', [[
        CREATE TABLE IF NOT EXISTS `fvg_job_applications` (
            `id`          INT          NOT NULL AUTO_INCREMENT,
            `player_id`   INT          NOT NULL,
            `job_id`      VARCHAR(40)  NOT NULL,
            `applied_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `status`      ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
            PRIMARY KEY (`id`),
            KEY `idx_player` (`player_id`),
            KEY `idx_job`    (`job_id`),
            CONSTRAINT `fk_jobapp_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Cache ─────────────────────────────────────────────────────
-- [src] = { eligible, claims_used, last_claim, tasks_done={} }
local unemploymentData = {}

-- ── Segédfüggvények ───────────────────────────────────────────

local function Notify(src, msg, ntype)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'info',
        message = msg,
    })
end

-- JAVÍTÁS: player.job → player.metadata.job (job a metadata JSON-ben van)
local function IsUnemployedPlayer(src)
    local player = exports['fvg-playercore']:GetPlayer(src)
    return player and player.metadata and player.metadata.job == Config.BenefitEligibleJob
end

-- JAVÍTÁS: SQL-alapú lekérdezés helyett online játékos cache-ből számolunk
-- (a job a metadata JSON-ben van, nem önálló oszlopban az fvg_players táblában)
local function GetCurrentSlotCount(jobId)
    local count = 0
    for _, src in ipairs(GetPlayers()) do
        local p = exports['fvg-playercore']:GetPlayer(tonumber(src))
        if p and p.metadata and p.metadata.job == jobId then
            count = count + 1
        end
    end
    return count
end

local function GetPlayerTasksDone(src)
    if not unemploymentData[src] then return {} end
    return unemploymentData[src].tasks_done or {}
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    -- Csak munkanélkülieknek töltünk be adatot, de cachelünk mindenkinél
    local row = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_unemployment` WHERE `player_id` = ?',
        { player.id }
    )

    local tasksDone = {}
    if row and row.tasks_done then
        local ok, decoded = pcall(json.decode, row.tasks_done)
        tasksDone = ok and decoded or {}
    end

    if row then
        unemploymentData[src] = {
            player_id   = player.id,
            eligible    = row.eligible == 1,
            claims_used = row.claims_used,
            last_claim  = row.last_claim,
            tasks_done  = tasksDone,
        }
    else
        -- Első belépés: insertálás
        exports['fvg-database']:Insert(
            'INSERT INTO `fvg_unemployment` (`player_id`) VALUES (?)',
            { player.id }
        )
        unemploymentData[src] = {
            player_id   = player.id,
            eligible    = true,
            claims_used = 0,
            last_claim  = nil,
            tasks_done  = {},
        }
    end

    TriggerClientEvent('fvg-unemployment:client:SyncData', src, unemploymentData[src])
end)

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    unemploymentData[src] = nil
end)

-- ── Segély igénylés logika ────────────────────────────────────

local function CanClaim(src)
    local data = unemploymentData[src]
    if not data then return false, 'no_data' end
    if not data.eligible then return false, 'ineligible' end
    if not IsUnemployedPlayer(src) then return false, 'ineligible' end
    if data.claims_used >= Config.BenefitMaxClaims then return false, 'maxed' end

    -- Cooldown ellenőrzés
    if data.last_claim then
        local lastTs  = 0
        -- last_claim string 'YYYY-MM-DD HH:MM:SS' formátum
        local y, mo, d, h, mi, s = string.match(tostring(data.last_claim), '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
        if y then
            lastTs = os.time({ year=tonumber(y), month=tonumber(mo), day=tonumber(d),
                               hour=tonumber(h), min=tonumber(mi), sec=tonumber(s) })
        end
        local elapsed = os.time() - lastTs
        if elapsed < Config.BenefitCooldown then
            local remaining = Config.BenefitCooldown - elapsed
            local mins      = math.floor(remaining / 60)
            local secs      = remaining % 60
            return false, string.format('%d:%02d', mins, secs)
        end
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('GetUnemploymentData', function(src)
    return unemploymentData[tonumber(src)]
end)

exports('IsUnemployed', function(src)
    return IsUnemployedPlayer(tonumber(src))
end)

exports('SetBenefitEligible', function(src, state)
    local s    = tonumber(src)
    local data = unemploymentData[s]
    if not data then return false end
    data.eligible = state == true
    exports['fvg-database']:Execute(
        'UPDATE `fvg_unemployment` SET `eligible`=? WHERE `player_id`=?',
        { state and 1 or 0, data.player_id }
    )
    TriggerClientEvent('fvg-unemployment:client:SyncData', s, data)
    return true
end)

exports('ClaimBenefit', function(src)
    local s   = tonumber(src)
    local ok, err = CanClaim(s)
    if not ok then
        if err == 'ineligible' then
            Notify(s, Config.Notifications.benefit_ineligible, 'error')
        elseif err == 'maxed' then
            Notify(s, Config.Notifications.benefit_maxed, 'error')
        else
            Notify(s, Config.Notifications.benefit_cooldown .. err, 'warning')
        end
        return false
    end

    local data = unemploymentData[s]
    data.claims_used = data.claims_used + 1
    data.last_claim  = os.date('%Y-%m-%d %H:%M:%S')

    -- Pénz juttatás
    if Config.UseBankingForBenefit then
        exports['fvg-banking']:AddBalance(s, Config.BenefitAmount)
    else
        exports['fvg-playercore']:AddCash(s, Config.BenefitAmount)
    end

    -- DB frissítés
    exports['fvg-database']:Execute(
        'UPDATE `fvg_unemployment` SET `claims_used`=?, `last_claim`=NOW() WHERE `player_id`=?',
        { data.claims_used, data.player_id }
    )

    TriggerClientEvent('fvg-unemployment:client:SyncData', s, data)
    Notify(s, Config.Notifications.benefit_claimed .. Config.BenefitAmount, 'success')
    TriggerEvent('fvg-unemployment:server:BenefitClaimed', s, Config.BenefitAmount)
    return true
end)

exports('GetAvailableJobs', function(src)
    local s       = tonumber(src)
    local result  = {}
    local identity= exports['fvg-identity']:GetPlayerIdentity(s)
    local age     = identity and identity.age or 0

    for _, job in ipairs(Config.Jobs) do
        if job.open then
            local currentSlots = job.slots > 0 and GetCurrentSlotCount(job.id) or 0
            local isFull       = job.slots > 0 and currentSlots >= job.slots

            -- Követelmény ellenőrzés
            local meetsReqs  = true
            local reqDetails = {}
            if job.requirements then
                if job.requirements.minAge and age < job.requirements.minAge then
                    meetsReqs = false
                end
                if job.requirements.license and Config.UseIdCardLicenseCheck then
                    if not exports['fvg-idcard']:HasLicense(s, job.requirements.license) then
                        meetsReqs = false
                        table.insert(reqDetails, 'Szükséges: ' .. job.requirements.license .. ' jogosítvány')
                    end
                end
            end

            table.insert(result, {
                id           = job.id,
                label        = job.label,
                description  = job.description,
                salary       = job.salary,
                icon         = job.icon,
                color        = job.color,
                requirements = job.requirements,
                reqDetails   = reqDetails,
                slots        = job.slots,
                currentSlots = currentSlots,
                isFull       = isFull,
                meetsReqs    = meetsReqs,
                open         = job.open,
            })
        end
    end
    return result
end)

exports('ApplyForJob', function(src, jobId)
    local s      = tonumber(src)
    local player = exports['fvg-playercore']:GetPlayer(s)
    if not player then return false end

    -- JAVÍTÁS: player.job → player.metadata.job
    if player.metadata and player.metadata.job ~= Config.BenefitEligibleJob then
        Notify(s, Config.Notifications.job_already, 'warning')
        return false
    end

    -- Job megkeresése
    local jobDef = nil
    for _, j in ipairs(Config.Jobs) do
        if j.id == jobId then jobDef = j; break end
    end
    if not jobDef or not jobDef.open then return false end

    -- Slot ellenőrzés
    if jobDef.slots > 0 and GetCurrentSlotCount(jobId) >= jobDef.slots then
        Notify(s, Config.Notifications.job_no_slots, 'error')
        return false
    end

    -- Követelmény ellenőrzés
    local identity = exports['fvg-identity']:GetPlayerIdentity(s)
    local age      = identity and identity.age or 0
    if jobDef.requirements then
        if jobDef.requirements.minAge and age < jobDef.requirements.minAge then
            Notify(s, Config.Notifications.job_requirements, 'error')
            return false
        end
        if jobDef.requirements.license and Config.UseIdCardLicenseCheck then
            if not exports['fvg-idcard']:HasLicense(s, jobDef.requirements.license) then
                Notify(s, Config.Notifications.job_requirements, 'error')
                return false
            end
        end
    end

    -- Job váltás az fvg-playercore-on keresztül
    exports['fvg-playercore']:SetJob(s, jobId, 0)

    -- Segély adatok reset
    local data = unemploymentData[s]
    if data then
        data.claims_used = 0
        data.eligible    = false
        data.tasks_done  = {}
        exports['fvg-database']:Execute(
            'UPDATE `fvg_unemployment` SET `claims_used`=0, `eligible`=0, `tasks_done`=NULL WHERE `player_id`=?',
            { data.player_id }
        )
        TriggerClientEvent('fvg-unemployment:client:SyncData', s, data)
    end

    -- Jelentkezés logolása
    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_job_applications` (`player_id`,`job_id`,`status`) VALUES (?,?,?)',
        { player.id, jobId, 'accepted' }
    )

    Notify(s, Config.Notifications.job_applied .. jobDef.label, 'success')
    TriggerEvent('fvg-unemployment:server:JobApplied', s, jobId)
    return true
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Panel megnyitás kérés
RegisterNetEvent('fvg-unemployment:server:RequestOpen', function()
    local src  = source
    local data = unemploymentData[src]
    if not data then return end

    local jobs          = exports['fvg-unemployment']:GetAvailableJobs(src)
    local canClaim, err = CanClaim(src)

    -- Cooldown másodperc visszaadása
    local cooldownLeft = 0
    if data.last_claim then
        local y, mo, d, h, mi, s = string.match(tostring(data.last_claim), '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
        if y then
            local lastTs  = os.time({ year=tonumber(y), month=tonumber(mo), day=tonumber(d),
                                      hour=tonumber(h), min=tonumber(mi), sec=tonumber(s) })
            local elapsed = os.time() - lastTs
            cooldownLeft  = math.max(0, Config.BenefitCooldown - elapsed)
        end
    end

    TriggerClientEvent('fvg-unemployment:client:OpenPanel', src, {
        data          = data,
        jobs          = jobs,
        tasks         = Config.DailyTasks,
        benefitAmount = Config.BenefitAmount,
        maxClaims     = Config.BenefitMaxClaims,
        cooldown      = Config.BenefitCooldown,
        cooldownLeft  = cooldownLeft,
        canClaim      = canClaim,
        isUnemployed  = IsUnemployedPlayer(src),
    })
end)

-- Segély igénylés
RegisterNetEvent('fvg-unemployment:server:ClaimBenefit', function()
    exports['fvg-unemployment']:ClaimBenefit(source)
end)

-- Állásra jelentkezés
RegisterNetEvent('fvg-unemployment:server:ApplyForJob', function(jobId)
    exports['fvg-unemployment']:ApplyForJob(source, jobId)
end)

-- Napi feladat ellenőrzés
RegisterNetEvent('fvg-unemployment:server:CheckTask', function(taskId)
    local src  = source
    local data = unemploymentData[src]
    if not data then return end

    local taskDef = nil
    for _, t in ipairs(Config.DailyTasks) do
        if t.id == taskId then taskDef = t; break end
    end
    if not taskDef then return end

    local tasks = data.tasks_done or {}
    if tasks[taskId] then return end -- már megcsinálta

    local completed = false

    if taskDef.type == 'inventory' and Config.UseInventoryTasks then
        local count = exports['fvg-inventory']:GetItemCount(src, taskDef.item)
        completed   = count >= taskDef.amount

    elseif taskDef.type == 'location' then
        completed = true -- kliens oldalon triggerelve, ha ott van

    elseif taskDef.type == 'cash' then
        local player = exports['fvg-playercore']:GetPlayer(src)
        -- JAVÍTÁS: player.cash → player.metadata.cash
        completed    = player and (player.metadata and player.metadata.cash or 0) >= taskDef.amount
    end

    if completed then
        tasks[taskId] = true
        data.tasks_done = tasks

        exports['fvg-database']:Execute(
            'UPDATE `fvg_unemployment` SET `tasks_done`=? WHERE `player_id`=?',
            { json.encode(tasks), data.player_id }
        )

        -- Jutalom
        if Config.UseBankingForBenefit then
            exports['fvg-banking']:AddBalance(src, taskDef.reward)
        else
            exports['fvg-playercore']:AddCash(src, taskDef.reward)
        end

        TriggerClientEvent('fvg-unemployment:client:SyncData', src, data)
        Notify(src, Config.Notifications.task_completed .. taskDef.reward, 'success')
        TriggerEvent('fvg-unemployment:server:TaskCompleted', src, taskId, taskDef.reward)
    else
        Notify(src, 'A feltétel még nem teljesült.', 'warning')
    end
end)

-- Munkanélküliség visszaállítás (pl. kirúgáskor – más script hívja)
AddEventHandler('fvg-playercore:server:JobChanged', function(src, newJob, oldJob)
    local data = unemploymentData[src]
    if not data then return end

    if newJob == Config.BenefitEligibleJob then
        -- Kirúgták / visszaálltak munkanélkülinek
        data.eligible    = true
        data.claims_used = 0
        data.tasks_done  = {}
        exports['fvg-database']:Execute(
            'UPDATE `fvg_unemployment` SET `eligible`=1, `claims_used`=0, `tasks_done`=NULL WHERE `player_id`=?',
            { data.player_id }
        )
        TriggerClientEvent('fvg-unemployment:client:SyncData', src, data)
        Notify(src, 'Munkanélküli segélyre válsz jogosulttá.', 'info')
    end
end)
