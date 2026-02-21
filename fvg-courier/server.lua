-- ╔══════════════════════════════════════════════╗
-- ║         fvg-courier :: server                ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ───────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    exports['fvg-database']:RegisterMigration('fvg_courier_stats', [[
        CREATE TABLE IF NOT EXISTS `fvg_courier_stats` (
            `player_id`          INT       NOT NULL,
            `xp`                 INT       NOT NULL DEFAULT 0,
            `level`              TINYINT   NOT NULL DEFAULT 1,
            `total_deliveries`   INT       NOT NULL DEFAULT 0,
            `total_runs`         INT       NOT NULL DEFAULT 0,
            `perfect_runs`       INT       NOT NULL DEFAULT 0,
            `streak`             TINYINT   NOT NULL DEFAULT 0,
            `total_earned`       INT       NOT NULL DEFAULT 0,
            `updated_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                    ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`),
            CONSTRAINT `fk_courier_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports['fvg-database']:RegisterMigration('fvg_courier_deliveries', [[
        CREATE TABLE IF NOT EXISTS `fvg_courier_deliveries` (
            `id`           INT          NOT NULL AUTO_INCREMENT,
            `player_id`    INT          NOT NULL,
            `run_id`       VARCHAR(20)  NOT NULL,
            `spots_total`  TINYINT      NOT NULL DEFAULT 5,
            `spots_done`   TINYINT      NOT NULL DEFAULT 0,
            `reward`       INT          NOT NULL DEFAULT 0,
            `started_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `finished_at`  TIMESTAMP             DEFAULT NULL,
            `perfect`      TINYINT(1)   NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            KEY `idx_player` (`player_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Cache ──────────────────────────────────────────────────
local playerStats = {}
local activeRuns  = {}

-- ── Segédfüggvények ─────────────────────────────────────────────

local function Notify(src, msg, ntype, title)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'info',
        title   = title,
        message = msg,
    })
end

-- FIX: metadata.job használata player.job helyett
local function HasJob(src)
    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player then return false end
    local job = player.metadata and player.metadata.job or player.job
    return job == Config.RequiredJob
end

local function GenRunId()
    return 'RUN-' .. string.format('%06d', math.random(100000, 999999))
end

local function GetLevelData(xp)
    local current = Config.Levels[1]
    for _, lvl in ipairs(Config.Levels) do
        if xp >= lvl.xpRequired then current = lvl end
    end
    return current
end

local function GetNextLevel(xp)
    for _, lvl in ipairs(Config.Levels) do
        if xp < lvl.xpRequired then return lvl end
    end
    return nil
end

local function PickRandomSpots(n)
    local pool   = {}
    local result = {}
    for _, s in ipairs(Config.DeliverySpots) do table.insert(pool, s) end
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    for i = 1, math.min(n, #pool) do
        table.insert(result, { label = pool[i].label, coords = pool[i].coords, done = false })
    end
    return result
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_courier_stats` WHERE `player_id` = ?',
        { player.id }
    )
    if row then
        playerStats[src] = {
            player_id        = player.id,
            xp               = row.xp,
            level            = row.level,
            total_deliveries = row.total_deliveries,
            total_runs       = row.total_runs,
            perfect_runs     = row.perfect_runs,
            streak           = row.streak,
            total_earned     = row.total_earned,
        }
    else
        exports['fvg-database']:Insert(
            'INSERT INTO `fvg_courier_stats` (`player_id`) VALUES (?)',
            { player.id }
        )
        playerStats[src] = {
            player_id=player.id, xp=0, level=1,
            total_deliveries=0, total_runs=0, perfect_runs=0,
            streak=0, total_earned=0,
        }
    end
end)

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    if activeRuns[src] then
        TriggerClientEvent('fvg-courier:client:RunCancelled', src, { reason = 'disconnect' })
        activeRuns[src] = nil
    end
    playerStats[src] = nil
end)

-- ── XP + Szint mentés ───────────────────────────────────────────
local function SaveStats(src)
    local s = playerStats[src]
    if not s then return end
    exports['fvg-database']:Execute(
        [[UPDATE `fvg_courier_stats`
          SET `xp`=?,`level`=?,`total_deliveries`=?,`total_runs`=?,
              `perfect_runs`=?,`streak`=?,`total_earned`=?
          WHERE `player_id`=?]],
        { s.xp, s.level, s.total_deliveries, s.total_runs,
          s.perfect_runs, s.streak, s.total_earned, s.player_id }
    )
end

local function AddXP(src, amount)
    local s = playerStats[src]
    if not s then return end
    s.xp = s.xp + amount
    local newLevel = GetLevelData(s.xp)
    if newLevel.level > s.level then
        s.level = newLevel.level
        TriggerClientEvent('fvg-courier:client:LevelUp', src, newLevel)
    end
end

-- ══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ══════════════════════════════════════════════════════════════

exports('GetActiveDelivery', function(src)
    return activeRuns[tonumber(src)]
end)

exports('GetPlayerStats', function(src)
    return playerStats[tonumber(src)]
end)

exports('GetLeaderboard', function(limit)
    limit = math.min(tonumber(limit) or 10, 50)
    local rows = exports['fvg-database']:Query(
        [[SELECT cs.player_id, cs.xp, cs.level, cs.total_deliveries, cs.total_earned,
                 p.firstname, p.lastname
          FROM `fvg_courier_stats` cs
          LEFT JOIN `fvg_players` p ON p.id = cs.player_id
          ORDER BY cs.total_deliveries DESC
          LIMIT ?]],
        { limit }
    )
    return rows or {}
end)

exports('ForceStartDelivery', function(src)
    TriggerEvent('fvg-courier:server:StartRun', tonumber(src))
end)

exports('CancelDelivery', function(src)
    local s = tonumber(src)
    if activeRuns[s] then
        activeRuns[s] = nil
        TriggerClientEvent('fvg-courier:client:RunCancelled', s, { reason = 'admin' })
    end
end)

-- ══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-courier:server:ToggleDuty', function()
    local src = source
    if not HasJob(src) then
        Notify(src, 'Futár munkához kell a pozíció.', 'error')
        return
    end
    if activeRuns[src] then
        Notify(src, 'Előbb fejezd be az aktív kört!', 'warning')
        return
    end
    TriggerClientEvent('fvg-courier:client:ToggleDuty', src, playerStats[src])
end)

RegisterNetEvent('fvg-courier:server:RequestPanel', function()
    local src = source
    if not HasJob(src) then return end
    local stats     = playerStats[src]
    local levelData = GetLevelData(stats and stats.xp or 0)
    local nextLevel = GetNextLevel(stats and stats.xp or 0)
    local lb        = exports['fvg-courier']:GetLeaderboard(10)
    TriggerClientEvent('fvg-courier:client:OpenPanel', src, {
        stats              = stats,
        levelData          = levelData,
        nextLevel          = nextLevel,
        leaderboard        = lb,
        levels             = Config.Levels,
        activeRun          = activeRuns[src],
        baseReward         = Config.BaseReward,
        timeBonus          = Config.TimeBonus,
        timeBonusThreshold = Config.TimeBonusThreshold,
    })
end)

AddEventHandler('fvg-courier:server:StartRun', function(srcOverride)
    local src = srcOverride or source
    if not HasJob(src) then return end
    if activeRuns[src] then
        Notify(src, 'Már van aktív köröd!', 'warning'); return
    end

    local spots   = PickRandomSpots(Config.PackagesPerRun)
    local runId   = GenRunId()
    local stats   = playerStats[src]
    local lvlData = GetLevelData(stats and stats.xp or 0)

    local dbId = exports['fvg-database']:Insert(
        'INSERT INTO `fvg_courier_deliveries` (`player_id`,`run_id`,`spots_total`) VALUES (?,?,?)',
        { stats.player_id, runId, #spots }
    )

    activeRuns[src] = {
        runId      = runId,
        dbId       = dbId,
        spots      = spots,
        currentIdx = 1,
        totalReward= 0,
        isPerfect  = true,
        rewardMult = lvlData.rewardMult,
        startedAt  = os.time(),
    }

    if Config.UseInventoryPackages then
        for i = 1, #spots do
            exports['fvg-inventory']:AddItem(src, Config.PackageItem, 1)
        end
    end

    TriggerClientEvent('fvg-courier:client:RunStarted', src, {
        runId      = runId,
        spots      = spots,
        currentIdx = 1,
        timeLimit  = Config.DeliveryTimeLimit,
        totalReward= 0,
    })

    if Config.UseDispatch then
        TriggerClientEvent('fvg-dispatch:client:GetCoordsAndCreate', src, {
            type     = 'all',
            priority = 1,
            title    = 'Futár kör indult',
            message  = GetPlayerName(src) .. ' kézbesítési kört kezdett (' .. #spots .. ' csomag)',
        })
    end

    Notify(src, 'Kör indítva! ' .. #spots .. ' csomag vár kézbesítésre.', 'success', '📦 Futár kör')
end)

RegisterNetEvent('fvg-courier:server:StartRun', function()
    TriggerEvent('fvg-courier:server:StartRun', source)
end)

RegisterNetEvent('fvg-courier:server:DeliverPackage', function(spotIdx, deliveryTime)
    local src = source
    local run = activeRuns[src]
    if not run then return end
    if run.currentIdx ~= spotIdx then return end

    local spot = run.spots[spotIdx]
    if not spot or spot.done then return end

    local stats   = playerStats[src]
    local lvlData = GetLevelData(stats and stats.xp or 0)
    local reward  = math.floor(Config.BaseReward * (run.rewardMult or 1.0))
    local bonuses = {}

    if deliveryTime and deliveryTime <= Config.TimeBonusThreshold then
        local timeB = math.floor(Config.TimeBonus * (run.rewardMult or 1.0))
        reward      = reward + timeB
        table.insert(bonuses, { label = '⚡ Gyors kézbesítés', amount = timeB })
    else
        run.isPerfect = false
    end

    if stats.streak > 0 and stats.streak % 5 == 0 then
        local streakB = Config.StreakBonus * math.floor(stats.streak / 5)
        reward        = reward + streakB
        table.insert(bonuses, { label = '🔥 Sorozat x' .. stats.streak, amount = streakB })
    end

    run.totalReward         = run.totalReward + reward
    run.spots[spotIdx].done = true

    if Config.UseInventoryPackages then
        exports['fvg-inventory']:RemoveItem(src, Config.PackageItem, 1)
    end

    local nextIdx = spotIdx + 1
    local hasNext = nextIdx <= #run.spots

    if hasNext then
        run.currentIdx = nextIdx
        TriggerClientEvent('fvg-courier:client:PackageDelivered', src, {
            spotIdx    = spotIdx,
            reward     = reward,
            bonuses    = bonuses,
            nextIdx    = nextIdx,
            nextSpot   = run.spots[nextIdx],
            totalReward= run.totalReward,
        })
    else
        local totalReward = run.totalReward
        if run.isPerfect then
            local perfB = math.floor(Config.PerfectRunBonus * (run.rewardMult or 1.0))
            totalReward = totalReward + perfB
            table.insert(bonuses, { label = '⭐ Tökéletes kör', amount = perfB })
        end

        local xpGained = Config.XPPerDelivery * #run.spots
        if run.isPerfect then xpGained = xpGained + (Config.XPStreak * #run.spots) end
        AddXP(src, xpGained)

        stats.total_deliveries = stats.total_deliveries + #run.spots
        stats.total_runs       = stats.total_runs + 1
        stats.total_earned     = stats.total_earned + totalReward
        stats.streak           = stats.streak + 1
        if run.isPerfect then stats.perfect_runs = stats.perfect_runs + 1 end

        if Config.UseBanking then
            exports['fvg-banking']:AddBalance(src, totalReward)
        else
            exports['fvg-playercore']:AddCash(src, totalReward)
        end

        exports['fvg-database']:Execute(
            'UPDATE `fvg_courier_deliveries` SET `spots_done`=?,`reward`=?,`finished_at`=NOW(),`perfect`=? WHERE `id`=?',
            { #run.spots, totalReward, run.isPerfect and 1 or 0, run.dbId }
        )
        SaveStats(src)

        TriggerClientEvent('fvg-courier:client:RunCompleted', src, {
            totalReward = totalReward,
            bonuses     = bonuses,
            xpGained    = xpGained,
            isPerfect   = run.isPerfect,
            stats       = stats,
            levelData   = GetLevelData(stats.xp),
        })

        TriggerEvent('fvg-courier:server:RunCompleted', src, totalReward, run.isPerfect)
        activeRuns[src] = nil
    end

    SaveStats(src)
end)

RegisterNetEvent('fvg-courier:server:RunTimeout', function()
    local src = source
    local run = activeRuns[src]
    if not run then return end

    if Config.UseInventoryPackages then
        local remaining = 0
        for _, s in ipairs(run.spots) do if not s.done then remaining = remaining + 1 end end
        if remaining > 0 then
            exports['fvg-inventory']:RemoveItem(src, Config.PackageItem, remaining)
        end
    end

    if run.totalReward > 0 then
        if Config.UseBanking then
            exports['fvg-banking']:AddBalance(src, run.totalReward)
        else
            exports['fvg-playercore']:AddCash(src, run.totalReward)
        end
    end

    local stats = playerStats[src]
    if stats then
        stats.streak = 0
        SaveStats(src)
    end

    activeRuns[src] = nil
    Notify(src, 'Kör lejárt! Részleges jutalom: $' .. run.totalReward, 'error', '⏱️ Időtúllépés')
    TriggerEvent('fvg-courier:server:RunTimedOut', src)
end)

RegisterNetEvent('fvg-courier:server:CancelRun', function()
    local src = source
    local run = activeRuns[src]
    if not run then return end

    if Config.UseInventoryPackages then
        local remaining = 0
        for _, s in ipairs(run.spots) do if not s.done then remaining = remaining + 1 end end
        if remaining > 0 then
            exports['fvg-inventory']:RemoveItem(src, Config.PackageItem, remaining)
        end
    end

    local stats = playerStats[src]
    if stats then stats.streak = 0; SaveStats(src) end

    activeRuns[src] = nil
    Notify(src, 'Kör lemondása. Sorozat nullázva.', 'warning')
end)
