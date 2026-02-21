-- ╔══════════════════════════════════════════════╗
-- ║      fvg-database :: migrations              ║
-- ╚══════════════════════════════════════════════╝

-- Regisztrált migrációk listája: { name, query }
local _migrations = {}

-- FIX: _dbReady flag – jelzi hogy a DB már connected és az
-- alap migrációk lefutottak. Ha true, a RegisterMigration
-- azonnal futtatja a queryt ahelyett, hogy csak listaba tenni.
local _dbReady = false

-- ── Egy migráció futtatása (közös segédfüggvény) ──────────────
local function RunOne(m)
    local ok, err = pcall(function()
        MySQL.query.await(m.query)
    end)
    if ok then
        DB_Log('info', 'Migráció OK: %s', m.name)
    else
        DB_Log('error', 'Migráció HIBA [%s]: %s', m.name, tostring(err))
    end
end

-- ── Migráció regisztrálása ─────────────────────────────────────
-- FIX: Ha a DB már kész (általában később induló resource-ok
-- hívják, pl. fvg-police, fvg-courier stb.), a lekérdezést
-- azonnal futtatjuk – nem várjuk a következő RunMigrations()-t.
-- Ha még nem kész, berakjuk a listába (normál indulási sorrend).
function RegisterMigration(name, query)
    if type(name) ~= 'string' or type(query) ~= 'string' then
        DB_Log('error', 'RegisterMigration: érvénytelen paraméter (%s)', tostring(name))
        return
    end

    if _dbReady then
        -- DB már elérhető: azonnal futtatjuk
        DB_Log('info', 'Migráció azonnali futtatás (DB kész): %s', name)
        RunOne({ name = name, query = query })
    else
        -- DB még nem kész: listába tesszük
        table.insert(_migrations, { name = name, query = query })
        DB_Log('info', 'Migráció regisztrálva (futásra vár): %s', name)
    end
end

-- Export: más scriptek is regisztrálhatnak migrációt
exports('RegisterMigration', RegisterMigration)

-- ── Tábla létezés ellenőrzés ──────────────────────────────────
exports('TableExists', function(tableName)
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?',
        { tableName }
    )
    return (result or 0) > 0
end)

-- ── Alap táblák ────────────────────────────────────────────────
local function CreateCoreTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `fvg_players` (
            `id`           INT          NOT NULL AUTO_INCREMENT,
            `identifier`   VARCHAR(60)  NOT NULL,
            `name`         VARCHAR(60)  NOT NULL DEFAULT 'Unknown',
            `firstname`    VARCHAR(50)  NOT NULL DEFAULT '',
            `lastname`     VARCHAR(50)  NOT NULL DEFAULT '',
            `sex`          TINYINT(1)   NOT NULL DEFAULT 0,
            `dob`          VARCHAR(20)  NOT NULL DEFAULT '',
            `phone`        VARCHAR(20)           DEFAULT NULL,
            `metadata`     LONGTEXT              DEFAULT NULL,
            `last_seen`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `fvg_player_metadata` (
            `player_id`  INT          NOT NULL,
            `key`        VARCHAR(60)  NOT NULL,
            `value`      LONGTEXT     NOT NULL,
            `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`, `key`),
            CONSTRAINT `fk_meta_player` FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `fvg_logs` (
            `id`         BIGINT       NOT NULL AUTO_INCREMENT,
            `resource`   VARCHAR(60)  NOT NULL,
            `event`      VARCHAR(100) NOT NULL,
            `player_id`  INT                   DEFAULT NULL,
            `data`       LONGTEXT              DEFAULT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_resource` (`resource`),
            KEY `idx_player`   (`player_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    DB_Log('info', 'Alap táblák létrehozva / ellenőrizve.')
end

-- ── Összes migráció futtatása ──────────────────────────────────
local function RunMigrations()
    if not Config.AutoMigrate then return end

    if Config.CoreTables then
        CreateCoreTables()
    end

    for _, m in ipairs(_migrations) do
        RunOne(m)
    end

    -- FIX: migrációs ablak bezárása: innentől minden
    -- RegisterMigration hívás azonnal lefut
    _dbReady = true

    DB_Log('info', 'Összes migráció lefutott. DB kész.')

    -- Tájékoztatjuk a többi resource-t hogy a DB kész
    -- (opcionális: há bárki hallgatni akar rá)
    TriggerEvent('fvg-database:ready')
end

-- Induláskor futtatjuk
CreateThread(function()
    local ready = false
    AddEventHandler('onDatabaseConnected', function()
        ready = true
    end)

    -- Fallback: max 10 másodpercet várunk
    local timeout = 0
    while not ready and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    RunMigrations()
end)
