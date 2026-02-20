Config = {}

-- ── Naplózás ─────────────────────────────────────────────────
-- 'none'    = nincs napló
-- 'error'   = csak hibák
-- 'warn'    = hibák + figyelmeztetések
-- 'info'    = minden lekérdezés (fejlesztéshez)
Config.LogLevel = 'warn'

-- Lassú lekérdezés küszöb milliszekundumban (0 = kikapcsolt)
Config.SlowQueryThreshold = 200

-- ── Játékos azonosító mező ────────────────────────────────────
-- Ezzel azonosítja a játékosokat az adatbázisban
-- 'license' | 'steam' | 'discord'
Config.PlayerIdentifierType = 'license'

-- ── Migrációk ─────────────────────────────────────────────────
-- Ha true, az összes RegisterMigration automatikusan lefut induláskor
Config.AutoMigrate = true

-- ── Alap táblák ───────────────────────────────────────────────
-- Ezek mindig létrejönnek a fvg-database indulásakor
Config.CoreTables = true

-- ── Cache ─────────────────────────────────────────────────────
-- Játékos adatok memóriában tárolása (ms) – 0 = nincs cache
Config.PlayerCacheTTL = 5000