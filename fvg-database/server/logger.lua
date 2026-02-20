-- ╔══════════════════════════════════════════════╗
-- ║       fvg-database :: logger                 ║
-- ╚══════════════════════════════════════════════╝

local levels = { none = 0, error = 1, warn = 2, info = 3 }

local function ShouldLog(level)
    return (levels[level] or 0) <= (levels[Config.LogLevel] or 1)
end

function DB_Log(level, message, ...)
    if not ShouldLog(level) then return end
    local prefix = {
        error = '^1[fvg-database][ERROR]^0',
        warn  = '^3[fvg-database][WARN]^0',
        info  = '^5[fvg-database][INFO]^0',
    }
    print(string.format((prefix[level] or '[fvg-database]') .. ' ' .. message, ...))
end

function DB_TrackTime(query, startTime)
    if Config.SlowQueryThreshold <= 0 then return end
    local elapsed = (GetGameTimer() - startTime)
    if elapsed >= Config.SlowQueryThreshold then
        DB_Log('warn', 'Lassú lekérdezés (%dms): %s', elapsed, query)
    end
end